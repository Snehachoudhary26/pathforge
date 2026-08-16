import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/theme.dart';
import '../core/config.dart';

class JobMarketScreen extends StatefulWidget {
  const JobMarketScreen({super.key});

  @override
  State<JobMarketScreen> createState() => _JobMarketScreenState();
}

class _JobMarketScreenState extends State<JobMarketScreen> {
  bool _isLoading = true;
  bool _isAnalysing = false;
  int _agentStep = 0;
  String _userTrack = '';
  Map<String, dynamic>? _result;

  final List<String> _agentSteps = [
    'Scanning job market for your track...',
    'Analysing top hiring companies...',
    'Extracting trending skills...',
    'Calculating salary benchmarks...',
    'Generating recommendations...',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final track = userDoc.data()?['track'] ?? 'Data Scientist';
      setState(() {
        _userTrack = track;
        _isLoading = false;
        _isAnalysing = true;
        _agentStep = 0;
      });

      _cycleAgentSteps();
      _fetchMarketData(track);
    } catch (_) {
      setState(() {
        _userTrack = 'Data Scientist';
        _isLoading = false;
        _isAnalysing = true;
        _agentStep = 0;
      });
      _cycleAgentSteps();
      _fetchMarketData('Data Scientist');
    }
  }

  void _cycleAgentSteps() {
    Future.delayed(const Duration(milliseconds: 750), () {
      if (mounted && _isAnalysing && _agentStep < _agentSteps.length - 1) {
        setState(() => _agentStep++);
        _cycleAgentSteps();
      }
    });
  }

  Future<void> _fetchMarketData(String track) async {
    const apiKey = AppConfig.groqApiKey;
    const url = AppConfig.groqUrl;

    final prompt = '''
You are a career intelligence agent analyzing the 2025 Indian tech job market for "$track".
Return ONLY a valid JSON object matching this schema:
{
  "demandLevel": "Very High",
  "growthRate": "35% YoY",
  "openRoles": "10,000+",
  "fresherSalary": "8–15 LPA",
  "seniorSalary": "20–40 LPA",
  "marketSummary": "2 short sentences describing industry demand for $track in India.",
  "topCompanies": ["Google", "Microsoft", "Amazon", "Flipkart", "Swiggy"],
  "trendingSkills": ["Python", "Docker", "System Design", "Cloud", "DSA"],
  "marketDemandScore": 88,
  "studentReadinessScore": 40,
  "gapAdvice": "You need 48% more skill coverage to be fully market-ready"
}
No markdown. No extra text. Just JSON.
''';

    final startTime = DateTime.now();

    try {
      final response = await http.post(
        Uri.parse('$url?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [{'text': prompt}]
            }
          ],
          'generationConfig': {'temperature': 0.3, 'maxOutputTokens': 1200},
        }),
      ).timeout(const Duration(seconds: 25));

      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      if (elapsed < 3200) {
        await Future.delayed(Duration(milliseconds: 3200 - elapsed));
      }

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final text =
            json['candidates'][0]['content']['parts'][0]['text'] as String;
        String clean = text
            .trim()
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final start = clean.indexOf('{');
        final end = clean.lastIndexOf('}');
        if (start != -1 && end != -1) clean = clean.substring(start, end + 1);

        if (mounted) {
          setState(() {
            _result = jsonDecode(clean);
            _isAnalysing = false;
          });
        }
      } else {
        _applyFallback();
      }
    } catch (_) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      if (elapsed < 3200) {
        await Future.delayed(Duration(milliseconds: 3200 - elapsed));
      }
      _applyFallback();
    }
  }

  void _applyFallback() {
    if (!mounted) return;
    setState(() {
      _result = {
        'demandLevel': 'Very High',
        'growthRate': '35% YoY',
        'openRoles': '10,000+',
        'fresherSalary': '8–15 LPA',
        'seniorSalary': '20–40 LPA',
        'marketSummary':
            'The $_userTrack market in India is growing rapidly with 35% YoY growth. Companies are actively hiring freshers with strong fundamentals and project experience.',
        'topCompanies': [
          'Google',
          'Microsoft',
          'Amazon',
          'Flipkart',
          'Swiggy',
          'Razorpay'
        ],
        'trendingSkills': [
          'Core Fundamentals',
          'Cloud & Docker',
          'System Design',
          'DSA & Problem Solving'
        ],
        'marketDemandScore': 88,
        'studentReadinessScore': 40,
        'gapAdvice': 'You need 48% more skill coverage to be fully market-ready',
      };
      _isAnalysing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top Navy Header
            Container(
              color: const Color(0xFF111322),
              padding: EdgeInsets.fromLTRB(
                12,
                topPadding > 0 ? topPadding + 6 : 18,
                12,
                10,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/home'),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Job Market Analysis',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00B894).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFF00B894)
                                      .withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                'Live AI',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF00B894),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _userTrack.isNotEmpty
                              ? 'Market demand for $_userTrack'
                              : 'Generate a roadmap first',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_result != null)
                    GestureDetector(
                      onTap: () => _loadUserData(),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFFF5722)),
                    )
                  : _userTrack.isEmpty
                      ? _buildNoTrack()
                      : _isAnalysing
                          ? _buildAnalysing()
                          : _result != null
                              ? _buildResults()
                              : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoTrack() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.purpleLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.bar_chart_rounded,
                    color: AppTheme.primary, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                'No track selected',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Generate a roadmap first to see job market analysis',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppTheme.textMid,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => context.go('/track'),
                icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                label: Text(
                  'Choose a track',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildAnalysing() => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppTheme.greenLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/GroupProgress.jpeg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.trending_up_rounded,
                    color: AppTheme.green,
                    size: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI Agent Scanning Market',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Analysing $_userTrack job market in India...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                color: AppTheme.textMid,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: _agentSteps.asMap().entries.map((e) {
                  final isDone = e.key < _agentStep;
                  final isCurrent = e.key == _agentStep;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.5),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: isDone
                                ? AppTheme.green
                                : isCurrent
                                    ? AppTheme.primary
                                    : AppTheme.border,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isDone
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 10)
                                : isCurrent
                                    ? const SizedBox(
                                        width: 8,
                                        height: 8,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 1.2,
                                        ),
                                      )
                                    : const SizedBox(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.value,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: isCurrent
                                  ? FontWeight.w700
                                  : isDone
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                              color: isCurrent
                                  ? AppTheme.primary
                                  : isDone
                                      ? AppTheme.textDark
                                      : AppTheme.textLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );

  Widget _buildResults() {
    final r = _result!;
    final demand = r['demandLevel'] ?? 'Very High';
    final growth = r['growthRate'] ?? '35% YoY';
    final jobs = r['openRoles'] ?? '10,000+';
    final fresherSalary = r['fresherSalary'] ?? '8–15 LPA';
    final seniorSalary = r['seniorSalary'] ?? '20–40 LPA';
    final summary = r['marketSummary'] ?? '';
    final companies = ((r['topCompanies'] as List?) ?? []).cast<String>();
    final skills = ((r['trendingSkills'] as List?) ?? []).cast<String>();
    final marketScore = (r['marketDemandScore'] ?? 88) as int;
    final studentScore = (r['studentReadinessScore'] ?? 40) as int;
    final gapAdvice = r['gapAdvice'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF111322),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userTrack,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Job Market in India · 2025',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _NavyStatItem(demand, 'Demand', const Color(0xFF00B894)),
                    _NavyStatItem(growth, 'Growth', const Color(0xFFFF5722)),
                    _NavyStatItem(jobs, 'Jobs', const Color(0xFF7C5CBF)),
                  ],
                ),
                const SizedBox(height: 10),

                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fresher salary',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                color: Colors.white54,
                              ),
                            ),
                            Text(
                              fresherSalary,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFFF5722),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: Colors.white12,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Experienced',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                color: Colors.white54,
                              ),
                            ),
                            Text(
                              seniorSalary,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF00B894),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    summary,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: Colors.white70,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your readiness vs market demand',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                _ProgressBarItem('Market demand', marketScore, const Color(0xFF00B894)),
                const SizedBox(height: 6),
                _ProgressBarItem('Your readiness', studentScore, const Color(0xFFFF5722)),
                if (gapAdvice.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9E6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFFE082),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 14, color: Color(0xFFE08D00)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            gapAdvice,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF7A4D00),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),

          if (companies.isNotEmpty)
            _ChipSection('Top Hiring Companies in India', Icons.business_rounded,
                const Color(0xFF7C5CBF), companies),

          const SizedBox(height: 10),

          if (skills.isNotEmpty)
            _ChipSection('Trending Skills Recruiters Look For',
                Icons.trending_up_rounded, const Color(0xFFFF5722), skills),
        ],
      ),
    );
  }
}

class _NavyStatItem extends StatelessWidget {
  final String val, label;
  final Color color;
  const _NavyStatItem(this.val, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9.5,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}

class _ProgressBarItem extends StatelessWidget {
  final String label;
  final int val;
  final Color color;
  const _ProgressBarItem(this.label, this.val, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                color: AppTheme.textMid,
              ),
            ),
            Text(
              '$val%',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: val / 100,
            backgroundColor: const Color(0xFFEEEEF5),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}

class _ChipSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;
  const _ChipSection(this.title, this.icon, this.color, this.items);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 5,
            runSpacing: 4,
            children: items
                .map((it) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        it,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
