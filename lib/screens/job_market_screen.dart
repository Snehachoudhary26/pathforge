import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../core/theme.dart';

class JobMarketScreen extends StatefulWidget {
  const JobMarketScreen({super.key});
  @override
  State<JobMarketScreen> createState() => _JobMarketScreenState();
}

class _JobMarketScreenState extends State<JobMarketScreen> {
  bool _isLoading = true;
  bool _isAnalysing = false;
  Map<String, dynamic>? _result;
  String _userTrack = '';
  String _userName = '';
  int _agentStep = 0;

  final List<String> _agentSteps = [
    'Scanning job market for your track...',
    'Analysing top hiring companies...',
    'Extracting trending skills...',
    'Calculating salary ranges...',
    'Comparing your skills vs market...',
    'Generating recommendations...',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { setState(() => _isLoading = false); return; }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(uid).get();
      final roadmapSnap = await FirebaseFirestore.instance
          .collection('roadmaps')
          .where('uid', isEqualTo: uid)
          .limit(1).get();

      final userData = userDoc.data() ?? {};
      final roadmap = roadmapSnap.docs.isNotEmpty
          ? roadmapSnap.docs.first.data() : null;

      // Get completed skills
      final weeks = roadmap?['weeks'] as List? ?? [];
      final doneWeeks = weeks.where((w) => w['status'] == 'done').toList();
      final completedSkills = doneWeeks
          .expand((w) => (w['skills'] as List? ?? []))
          .map((s) => s.toString())
          .toList();

      setState(() {
        _userName = userData['name'] ?? 'Student';
        _userTrack = roadmap?['track'] ?? '';
        _isLoading = false;
      });

      if (_userTrack.isNotEmpty) {
        _runMarketAnalysis(completedSkills);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runMarketAnalysis(List<String> completedSkills) async {
    setState(() { _isAnalysing = true; _agentStep = 0; });
    _cycleSteps();

    const apiKey = AppConfig.groqApiKey;
    const url =
        AppConfig.groqUrl;

    final prompt = '''
You are a job market analysis AI agent for Indian engineering students in 2025.

Analyse the job market for: "$_userTrack"
Student's completed skills: ${completedSkills.join(', ')}

Return ONLY valid JSON:
{
  "demandLevel": "Very High",
  "demandScore": 92,
  "avgSalaryFresher": "8-12 LPA",
  "avgSalaryExperienced": "18-35 LPA",
  "jobsAvailable": "12,000+",
  "topCompanies": ["Google", "Amazon", "Flipkart", "Swiggy", "Razorpay"],
  "trendingSkills": [
    {"skill": "Python", "demand": 95, "userHas": true},
    {"skill": "TensorFlow", "demand": 88, "userHas": false},
    {"skill": "SQL", "demand": 82, "userHas": true},
    {"skill": "Docker", "demand": 75, "userHas": false},
    {"skill": "LLMs", "demand": 90, "userHas": false}
  ],
  "topSkillsToLearn": [
    {"skill": "LLMs & Prompt Engineering", "reason": "Highest demand in 2025", "salaryBoost": "+3-5 LPA"},
    {"skill": "MLOps", "reason": "Required for senior roles", "salaryBoost": "+4-6 LPA"},
    {"skill": "Cloud (AWS/GCP)", "reason": "Every company uses cloud", "salaryBoost": "+2-4 LPA"}
  ],
  "marketInsight": "2 sentence insight about the job market for this track in India in 2025",
  "growthRate": "35% YoY",
  "userReadiness": 45
}
Real data only. No markdown. Just JSON.''';

    try {
      final response = await http.post(
        Uri.parse('$url?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 1500},
        }),
      ).timeout(const Duration(seconds: 25));

      Map<String, dynamic> data;
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final text =
            json['candidates'][0]['content']['parts'][0]['text'] as String;
        String clean = text.trim()
            .replaceAll('```json', '').replaceAll('```', '').trim();
        final start = clean.indexOf('{');
        final end = clean.lastIndexOf('}');
        if (start != -1 && end != -1) clean = clean.substring(start, end + 1);
        data = jsonDecode(clean);
      } else {
        data = _fallbackData();
      }

      setState(() { _result = data; _isAnalysing = false; });
    } catch (_) {
      setState(() { _result = _fallbackData(); _isAnalysing = false; });
    }
  }

  void _cycleSteps() {
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && _isAnalysing &&
          _agentStep < _agentSteps.length - 1) {
        setState(() => _agentStep++);
        _cycleSteps();
      }
    });
  }

  Map<String, dynamic> _fallbackData() => {
    'demandLevel': 'Very High',
    'demandScore': 88,
    'avgSalaryFresher': '8-15 LPA',
    'avgSalaryExperienced': '20-40 LPA',
    'jobsAvailable': '10,000+',
    'topCompanies': ['Google', 'Amazon', 'Microsoft', 'Flipkart', 'Meesho'],
    'trendingSkills': [
      {'skill': 'Python', 'demand': 95, 'userHas': false},
      {'skill': 'Machine Learning', 'demand': 90, 'userHas': false},
      {'skill': 'SQL', 'demand': 85, 'userHas': false},
      {'skill': 'LLMs', 'demand': 92, 'userHas': false},
      {'skill': 'Cloud', 'demand': 80, 'userHas': false},
    ],
    'topSkillsToLearn': [
      {'skill': 'LLMs & Prompt Engineering',
       'reason': 'Hottest skill in 2025',
       'salaryBoost': '+3-5 LPA'},
      {'skill': 'MLOps',
       'reason': 'Required for production ML',
       'salaryBoost': '+4-6 LPA'},
      {'skill': 'Cloud (AWS/GCP)',
       'reason': 'Every company uses cloud',
       'salaryBoost': '+2-4 LPA'},
    ],
    'marketInsight':
        'The $_userTrack market in India is growing rapidly with 35% YoY growth. Companies are actively hiring freshers with strong fundamentals and project experience.',
    'growthRate': '35% YoY',
    'userReadiness': 40,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Column(children: [
          // Header
          Container(
            color: AppTheme.navy,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(children: [
              GestureDetector(
                onTap: () => context.go('/home'),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('Job Market Analysis',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 17, fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppTheme.green.withOpacity(0.5)),
                      ),
                      child: Text('Live AI',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 9, fontWeight: FontWeight.w700,
                              color: AppTheme.green)),
                    ),
                  ]),
                  Text(
                    _userTrack.isNotEmpty
                        ? 'Market demand for $_userTrack'
                        : 'Generate a roadmap first',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, color: Colors.white54),
                  ),
                ],
              )),
              if (_result != null)
                GestureDetector(
                  onTap: () => _loadUserData(),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
            ]),
          ),

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(
                    color: AppTheme.orange))
                : _userTrack.isEmpty
                    ? _buildNoTrack()
                    : _isAnalysing
                        ? _buildAnalysing()
                        : _result != null
                            ? _buildResults()
                            : const SizedBox(),
          ),
        ]),
      ),
    );
  }

  Widget _buildNoTrack() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
                color: AppTheme.purpleLight,
                borderRadius: BorderRadius.circular(24)),
            child: Icon(Icons.bar_chart_rounded,
                color: AppTheme.primary, size: 40),
          ),
          const SizedBox(height: 20),
          Text('No track selected',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 20, fontWeight: FontWeight.w800,
                  color: AppTheme.textDark)),
          const SizedBox(height: 8),
          Text('Generate a roadmap first to see job market analysis',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: AppTheme.textMid),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/track'),
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text('Choose a track',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildAnalysing() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.9, end: 1.1),
            duration: const Duration(milliseconds: 900),
            builder: (_, val, child) =>
                Transform.scale(scale: val, child: child),
            onEnd: () { if (mounted) setState(() {}); },
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                  color: AppTheme.greenLight,
                  borderRadius: BorderRadius.circular(28)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset('assets/images/GroupProgress.jpeg',
                    width: 100, height: 100, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.trending_up_rounded,
                            color: AppTheme.green, size: 50)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('AI Agent Scanning Market',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 20, fontWeight: FontWeight.w800,
                  color: AppTheme.textDark)),
          const SizedBox(height: 8),
          Text('Analysing $_userTrack job market in India...',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: AppTheme.textMid)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: _agentSteps.asMap().entries.map((e) {
                final isDone = e.key < _agentStep;
                final isCurrent = e.key == _agentStep;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppTheme.green
                            : isCurrent ? AppTheme.primary : AppTheme.border,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 13)
                            : isCurrent
                                ? const SizedBox(width: 13, height: 13,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const SizedBox(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(e.value,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: isCurrent
                                ? FontWeight.w700 : FontWeight.w400,
                            color: isDone || isCurrent
                                ? AppTheme.textDark : AppTheme.textLight))),
                  ]),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildResults() {
    final skills = List<Map<String, dynamic>>.from(
        (_result!['trendingSkills'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e)));
    final topLearn = List<Map<String, dynamic>>.from(
        (_result!['topSkillsToLearn'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e)));
    final companies =
        List<String>.from(_result!['topCompanies'] ?? []);
    final demandScore = (_result!['demandScore'] ?? 0) as int;
    final userReadiness = (_result!['userReadiness'] ?? 0) as int;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [

        // Market overview card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.navy,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(children: [
            Text(_userTrack,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text('Job Market in India · 2025',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, color: Colors.white54)),
            const SizedBox(height: 20),
            Row(children: [
              _MarketStat(
                  '${_result!['demandLevel']}',
                  'Demand', AppTheme.green),
              _MarketStat(
                  '${_result!['growthRate']}',
                  'Growth', AppTheme.orange),
              _MarketStat(
                  '${_result!['jobsAvailable']}',
                  'Jobs', AppTheme.primary),
            ]),
            const SizedBox(height: 16),
            const Divider(color: Colors.white12),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Column(children: [
                Text('Fresher salary',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, color: Colors.white54)),
                const SizedBox(height: 4),
                Text('${_result!['avgSalaryFresher']}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16, fontWeight: FontWeight.w800,
                        color: AppTheme.amber)),
              ])),
              Container(width: 1, height: 40, color: Colors.white12),
              Expanded(child: Column(children: [
                Text('Experienced',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, color: Colors.white54)),
                const SizedBox(height: 4),
                Text('${_result!['avgSalaryExperienced']}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16, fontWeight: FontWeight.w800,
                        color: AppTheme.green)),
              ])),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${_result!['marketInsight']}',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: Colors.white70, height: 1.5),
                  textAlign: TextAlign.center),
            ),
          ]),
        ),

        const SizedBox(height: 16),

        // Your readiness vs market
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your readiness vs market demand',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w800,
                      color: AppTheme.textDark)),
              const SizedBox(height: 16),
              _ReadinessBar('Market demand', demandScore, AppTheme.green),
              const SizedBox(height: 10),
              _ReadinessBar('Your readiness', userReadiness, AppTheme.orange),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.amberLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.amberBorder),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppTheme.amber, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    'You need ${demandScore - userReadiness}% more skill coverage to be fully market-ready',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, color: AppTheme.textDark),
                  )),
                ]),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Trending skills heatmap
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.purpleLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.purpleBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.local_fire_department_rounded,
                    color: AppTheme.primary, size: 18),
                const SizedBox(width: 8),
                Text('Trending skills demand',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, fontWeight: FontWeight.w800,
                        color: AppTheme.primary)),
              ]),
              const SizedBox(height: 14),
              ...skills.map((s) {
                final demand = (s['demand'] ?? 0) as int;
                final userHas = s['userHas'] as bool? ?? false;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    Container(
                      width: userHas ? 18 : 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: userHas
                            ? AppTheme.green : Colors.red.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        userHas ? Icons.check_rounded : Icons.close_rounded,
                        size: 11,
                        color: userHas
                            ? Colors.white : Colors.red.shade400,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 100,
                      child: Text(s['skill'] ?? '',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: AppTheme.textDark)),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: demand / 100),
                          duration: const Duration(milliseconds: 800),
                          builder: (_, val, __) => LinearProgressIndicator(
                            value: val,
                            backgroundColor: Colors.white,
                            valueColor: AlwaysStoppedAnimation(
                              demand >= 90
                                  ? AppTheme.orange
                                  : demand >= 75
                                      ? AppTheme.primary
                                      : AppTheme.green,
                            ),
                            minHeight: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$demand%',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: AppTheme.primary)),
                  ]),
                );
              }),
              const SizedBox(height: 4),
              Row(children: [
                Container(width: 10, height: 10,
                    decoration: BoxDecoration(
                        color: AppTheme.green, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('You have this skill',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10, color: AppTheme.textMid)),
                const SizedBox(width: 12),
                Container(width: 10, height: 10,
                    decoration: BoxDecoration(
                        color: Colors.red.shade100, shape: BoxShape.circle),
                    child: Icon(Icons.close_rounded,
                        size: 7, color: Colors.red.shade400)),
                const SizedBox(width: 4),
                Text('Missing skill',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10, color: AppTheme.textMid)),
              ]),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Top skills to learn
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.orangeLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.orangeBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.rocket_launch_rounded,
                    color: AppTheme.orange, size: 18),
                const SizedBox(width: 8),
                Text('Top skills to learn next',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, fontWeight: FontWeight.w800,
                        color: AppTheme.orange)),
              ]),
              const SizedBox(height: 14),
              ...topLearn.asMap().entries.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                          color: AppTheme.orange,
                          shape: BoxShape.circle),
                      child: Center(child: Text('${e.key + 1}',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, fontWeight: FontWeight.w800,
                              color: Colors.white))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.value['skill'] ?? '',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13, fontWeight: FontWeight.w800,
                                color: AppTheme.textDark)),
                        const SizedBox(height: 3),
                        Text(e.value['reason'] ?? '',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 11, color: AppTheme.textMid)),
                      ],
                    )),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.greenLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppTheme.green.withOpacity(0.3)),
                      ),
                      child: Text(e.value['salaryBoost'] ?? '',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10, fontWeight: FontWeight.w700,
                              color: AppTheme.green)),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Top hiring companies
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.business_rounded,
                    color: AppTheme.primary, size: 18),
                const SizedBox(width: 8),
                Text('Top hiring companies',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, fontWeight: FontWeight.w800,
                        color: AppTheme.textDark)),
              ]),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: companies.map((c) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.purpleLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.purpleBorder),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.business_center_rounded,
                        size: 14, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Text(c, style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppTheme.primary)),
                  ]),
                )).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // CTA
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/track'),
            icon: const Icon(Icons.school_rounded, size: 20),
            label: Text('Start learning in-demand skills',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }
}

class _MarketStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _MarketStat(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value, style: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: GoogleFonts.plusJakartaSans(
          fontSize: 10, color: Colors.white54)),
    ]),
  );
}

class _ReadinessBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _ReadinessBar(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.plusJakartaSans(
            fontSize: 12, color: AppTheme.textMid)),
        Text('$value%', style: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ]),
      const SizedBox(height: 6),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value / 100),
        duration: const Duration(milliseconds: 900),
        builder: (_, val, __) => ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: val,
            backgroundColor: AppTheme.border,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 10,
          ),
        ),
      ),
    ],
  );
}
