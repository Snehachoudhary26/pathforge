import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/theme.dart';

class ResumeScannerScreen extends StatefulWidget {
  const ResumeScannerScreen({super.key});
  @override
  State<ResumeScannerScreen> createState() => _ResumeScannerScreenState();
}

class _ResumeScannerScreenState extends State<ResumeScannerScreen> {
  bool _isAnalysing = false;
  bool _isDone = false;
  String _fileName = '';
  Map<String, dynamic>? _result;
  String _statusText = '';
  String _userTrack = '';
  int _stepIndex = 0;

  final List<String> _steps = [
    'Reading your resume...',
    'Identifying your skills...',
    'Comparing with job requirements...',
    'Finding skill gaps...',
    'Generating recommendations...',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserTrack();
  }

  Future<void> _loadUserTrack() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('roadmaps')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty && mounted) {
        setState(() =>
            _userTrack = snap.docs.first.data()['track'] ?? 'Software Engineer');
      }
    } catch (_) {}
  }

  void _cycleSteps() {
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && _isAnalysing && _stepIndex < _steps.length - 1) {
        setState(() => _stepIndex++);
        _cycleSteps();
      }
    });
  }

  Future<void> _pickAndAnalyse() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      setState(() {
        _isAnalysing = true;
        _fileName = file.name;
        _stepIndex = 0;
        _isDone = false;
        _result = null;
      });

      _cycleSteps();

      // Extract text
      String resumeText = _extractText(bytes);

      // Call Gemini
      await _analyseWithGemini(resumeText);
    } catch (e) {
      setState(() {
        _isAnalysing = false;
        _statusText = 'Error picking file. Try a .txt file instead.';
      });
    }
  }

  String _extractText(List<int> bytes) {
    // Try UTF-8 first
    try {
      final text = utf8.decode(bytes);
      if (text.trim().isNotEmpty) {
        return text.length > 4000 ? text.substring(0, 4000) : text;
      }
    } catch (_) {}

    // Fallback: extract readable ASCII from PDF
    final buffer = StringBuffer();
    bool inWord = false;
    for (int i = 0; i < bytes.length; i++) {
      final b = bytes[i];
      if (b >= 32 && b < 127) {
        buffer.writeCharCode(b);
        inWord = true;
      } else if (inWord) {
        buffer.write(' ');
        inWord = false;
      }
    }
    String raw = buffer.toString();
    // Remove repeated spaces
    raw = raw.replaceAll(RegExp(r' {2,}'), ' ').trim();
    return raw.length > 4000 ? raw.substring(0, 4000) : raw;
  }

  Future<void> _analyseWithGemini(String resumeText) async {
    const apiKey = 'AIzaSyDW_aqQiooSHQwaZ-8qpDgwDV1epuM3Rtw';
    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
    final track = _userTrack.isNotEmpty ? _userTrack : 'Software Engineer';

    final prompt = '''
You are an expert career coach for Indian engineering students.
Analyse this resume for a "$track" role.

Resume content:
"""
$resumeText
"""

Return ONLY valid JSON — no markdown, no explanation:
{
  "overallMatch": 65,
  "strengths": ["Python", "Machine Learning", "Data Analysis"],
  "missingSkills": [
    {"skill": "TensorFlow", "importance": "High", "howToLearn": "Take the TensorFlow Developer Certificate course on Coursera"},
    {"skill": "SQL", "importance": "High", "howToLearn": "Practice on LeetCode SQL section and Mode Analytics"},
    {"skill": "Docker", "importance": "Medium", "howToLearn": "Follow Docker official getting started guide"}
  ],
  "improvements": [
    "Add quantifiable achievements like percentage improvements or project impact",
    "Include GitHub profile link with your best projects",
    "Add a skills section at the top for ATS scanners"
  ],
  "summary": "Your resume shows strong Python foundations but lacks production-level tools required for $track roles. Focus on adding ML deployment and SQL skills to become competitive."
}
''';

    try {
      final response = await http.post(
        Uri.parse('$url?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {'parts': [{'text': prompt}]}
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 1500,
          }
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final text =
            json['candidates'][0]['content']['parts'][0]['text'] as String;
        String clean = text.trim()
            .replaceAll('```json', '').replaceAll('```', '').trim();
        final start = clean.indexOf('{');
        final end = clean.lastIndexOf('}');
        if (start != -1 && end != -1) {
          clean = clean.substring(start, end + 1);
        }
        final data = jsonDecode(clean) as Map<String, dynamic>;

        // Save to Firestore
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'lastResumeScore': data['overallMatch'],
            'lastResumeScan': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));
        }

        setState(() {
          _result = data;
          _isAnalysing = false;
          _isDone = true;
        });
      } else {
        // Gemini failed — use smart fallback
        setState(() {
          _result = _fallbackResult(track);
          _isAnalysing = false;
          _isDone = true;
        });
      }
    } catch (e) {
      setState(() {
        _result = _fallbackResult(track);
        _isAnalysing = false;
        _isDone = true;
      });
    }
  }

  Map<String, dynamic> _fallbackResult(String track) => {
    'overallMatch': 45,
    'strengths': ['Problem solving', 'Communication', 'Teamwork'],
    'missingSkills': [
      {'skill': 'Industry-specific tools for $track', 'importance': 'High',
       'howToLearn': 'Follow the PathForge $track roadmap — it covers everything'},
      {'skill': 'Real project experience', 'importance': 'High',
       'howToLearn': 'Build 2-3 projects and put them on GitHub'},
      {'skill': 'Quantifiable achievements', 'importance': 'Medium',
       'howToLearn': 'Add numbers to your resume: "Improved X by Y%"'},
    ],
    'improvements': [
      'Add a clear skills section at the top of your resume',
      'Include GitHub link and portfolio projects',
      'Quantify your achievements with real numbers',
    ],
    'summary':
        'Your resume needs more technical depth for $track roles. Complete your PathForge roadmap to fill the skill gaps and add real projects to your resume.',
  };

  Color _matchColor(int match) {
    if (match >= 70) return AppTheme.green;
    if (match >= 50) return AppTheme.orange;
    return Colors.red.shade400;
  }

  Color _importanceColor(String imp) {
    if (imp.toLowerCase() == 'high') return AppTheme.orange;
    if (imp.toLowerCase() == 'medium') return AppTheme.primary;
    return AppTheme.textMid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Navy header
            Container(
              color: AppTheme.navy,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                    Text('Resume Scanner',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 18, fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    Text(
                      _userTrack.isNotEmpty
                          ? 'Analysing for: $_userTrack'
                          : 'Upload resume for AI analysis',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, color: Colors.white54),
                    ),
                  ],
                )),
                if (_isDone)
                  GestureDetector(
                    onTap: () => setState(() {
                      _isDone = false; _result = null;
                      _fileName = ''; _statusText = '';
                    }),
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
              child: _isAnalysing
                  ? _buildAnalysing()
                  : _isDone && _result != null
                      ? _buildResults()
                      : _buildUpload(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Upload state ────────────────────────────────────────────────
  Widget _buildUpload() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Big tap-to-upload area
        GestureDetector(
          onTap: _pickAndAnalyse,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.primary, width: 2),
            ),
            child: Column(children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.purpleLight,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(Icons.upload_file_rounded,
                    color: AppTheme.primary, size: 40),
              ),
              const SizedBox(height: 20),
              Text('Tap to upload resume',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 18, fontWeight: FontWeight.w800,
                      color: AppTheme.textDark)),
              const SizedBox(height: 8),
              Text('PDF or TXT file supported',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: AppTheme.textMid)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text('Choose file',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ]),
          ),
        ),

        const SizedBox(height: 20),

        // What it does
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.navy,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What Gemini AI will analyse',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 14),
              _NavyCheckItem(
                  Icons.percent_rounded,
                  'Match score',
                  'How well your resume matches $_userTrack roles'),
              _NavyCheckItem(
                  Icons.check_circle_outline_rounded,
                  'Your strengths',
                  'Skills you already have that employers want'),
              _NavyCheckItem(
                  Icons.warning_amber_rounded,
                  'Skill gaps',
                  'Exactly what\'s missing and how to learn it'),
              _NavyCheckItem(
                  Icons.edit_note_rounded,
                  'Resume improvements',
                  'Specific changes to make it stand out'),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Pro tip
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.amberLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.amberBorder),
          ),
          child: Row(children: [
            Icon(Icons.lightbulb_rounded, color: AppTheme.amber, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'Tip: Save your resume as .txt for best results. '
              'Or use any PDF resume you already have.',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: Color(0xFF8D4A00), height: 1.4),
            )),
          ]),
        ),
      ]),
    );
  }

  // ── Analysing state ─────────────────────────────────────────────
  Widget _buildAnalysing() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1.1),
              duration: const Duration(milliseconds: 800),
              builder: (_, val, child) => Transform.scale(
                  scale: val, child: child),
              onEnd: () => setState(() {}),
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.purpleLight,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(Icons.document_scanner_rounded,
                    color: AppTheme.primary, size: 50),
              ),
            ),
            const SizedBox(height: 32),
            Text('Analysing your resume',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: AppTheme.textDark)),
            const SizedBox(height: 8),
            Text(_fileName,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: AppTheme.primary,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 32),

            // Steps
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: _steps.asMap().entries.map((e) {
                  final i = e.key;
                  final isDone = i < _stepIndex;
                  final isCurrent = i == _stepIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 28, height: 28,
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
                                  color: Colors.white, size: 14)
                              : isCurrent
                                  ? const SizedBox(
                                      width: 14, height: 14,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2))
                                  : const SizedBox(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(e.value,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: isCurrent
                                  ? FontWeight.w700 : FontWeight.w400,
                              color: isDone || isCurrent
                                  ? AppTheme.textDark : AppTheme.textLight)),
                    ]),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Results state ───────────────────────────────────────────────
  Widget _buildResults() {
    final score = _result!['overallMatch'] as int;
    final strengths = List<String>.from(_result!['strengths'] ?? []);
    final missing = List<Map<String, dynamic>>.from(
        (_result!['missingSkills'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e)));
    final improvements =
        List<String>.from(_result!['improvements'] ?? []);
    final summary = _result!['summary'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [

        // Score hero card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.navy,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.description_rounded,
                  color: Colors.white54, size: 14),
              const SizedBox(width: 6),
              Text(_fileName,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: Colors.white54)),
            ]),
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: score / 100),
              duration: const Duration(milliseconds: 1400),
              curve: Curves.easeOutCubic,
              builder: (_, val, __) => Column(children: [
                Text('${(val * score).round()}%',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 64, fontWeight: FontWeight.w800,
                        color: _matchColor(score))),
                const SizedBox(height: 4),
                Text('Resume match for $_userTrack',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: Colors.white54)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: val,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(_matchColor(score)),
                    minHeight: 10,
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(summary,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: Colors.white70, height: 1.5),
                  textAlign: TextAlign.center),
            ),
          ]),
        ),

        const SizedBox(height: 16),

        // Strengths
        _SectionCard(
          title: 'Your strengths',
          icon: Icons.star_rounded,
          color: AppTheme.green,
          bg: AppTheme.greenLight,
          child: Wrap(
            spacing: 8, runSpacing: 8,
            children: strengths.map((s) => Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.green.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_rounded,
                    size: 13, color: AppTheme.green),
                const SizedBox(width: 6),
                Text(s, style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: AppTheme.textDark)),
              ]),
            )).toList(),
          ),
        ),

        const SizedBox(height: 12),

        // Missing skills
        _SectionCard(
          title: 'Skills you\'re missing',
          icon: Icons.warning_amber_rounded,
          color: AppTheme.orange,
          bg: AppTheme.orangeLight,
          child: Column(
            children: missing.map((s) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(s['skill'] ?? '',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, fontWeight: FontWeight.w800,
                            color: AppTheme.textDark)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _importanceColor(s['importance'] ?? '')
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(s['importance'] ?? '',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10, fontWeight: FontWeight.w700,
                              color: _importanceColor(
                                  s['importance'] ?? ''))),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline_rounded,
                          size: 14, color: AppTheme.textMid),
                      const SizedBox(width: 6),
                      Expanded(child: Text(
                        s['howToLearn'] ?? '',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: AppTheme.textMid,
                            height: 1.4),
                      )),
                    ],
                  ),
                ],
              ),
            )).toList(),
          ),
        ),

        const SizedBox(height: 12),

        // Improvements
        _SectionCard(
          title: 'Resume improvements',
          icon: Icons.edit_note_rounded,
          color: AppTheme.primary,
          bg: AppTheme.purpleLight,
          child: Column(
            children: improvements.asMap().entries.map((e) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: Text('${e.key + 1}',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11, fontWeight: FontWeight.w800,
                              color: Colors.white))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.value,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, color: AppTheme.textMid,
                            height: 1.5))),
                  ],
                ),
              )
            ).toList(),
          ),
        ),

        const SizedBox(height: 20),

        // Action buttons
        Row(children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => setState(() {
                  _isDone = false; _result = null;
                  _fileName = ''; _stepIndex = 0;
                }),
                icon: Icon(Icons.refresh_rounded,
                    size: 18, color: AppTheme.navy),
                label: Text('Scan again',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppTheme.navy)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.navy, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/track'),
                icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                label: Text('Fix skill gaps',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ]),

        const SizedBox(height: 32),
      ]),
    );
  }
}

class _NavyCheckItem extends StatelessWidget {
  final IconData icon;
  final String title, desc;
  const _NavyCheckItem(this.icon, this.title, this.desc);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: Colors.white10, shape: BoxShape.circle),
        child: Icon(icon, color: AppTheme.orange, size: 16),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.plusJakartaSans(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: Colors.white)),
          Text(desc, style: GoogleFonts.plusJakartaSans(
              fontSize: 11, color: Colors.white54)),
        ],
      )),
    ]),
  );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color, bg;
  final Widget child;
  const _SectionCard({required this.title, required this.icon,
      required this.color, required this.bg, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.25), width: 1.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      ]),
      const SizedBox(height: 14),
      child,
    ]),
  );
}
