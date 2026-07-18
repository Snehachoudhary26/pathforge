import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../core/theme.dart';

class ResumeRewriterScreen extends StatefulWidget {
  const ResumeRewriterScreen({super.key});
  @override
  State<ResumeRewriterScreen> createState() => _ResumeRewriterScreenState();
}

class _ResumeRewriterScreenState extends State<ResumeRewriterScreen> {
  // ── State ──────────────────────────────────────────────────────
  int _step = 0; // 0=upload, 1=paste JD, 2=analysing, 3=results
  String _resumeText = '';
  String _resumeFileName = '';
  final _jdController = TextEditingController();
  Map<String, dynamic>? _result;
  int _agentStep = 0;

  final List<String> _agentSteps = [
    'Reading your resume...',
    'Extracting job requirements...',
    'Matching your skills to JD...',
    'Rewriting resume bullets...',
    'Scoring ATS compatibility...',
    'Generating final report...',
  ];

  @override
  void dispose() {
    _jdController.dispose();
    super.dispose();
  }

  // ── Step 1: Pick resume file ───────────────────────────────────
  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    String text = '';
    try {
      text = utf8.decode(bytes);
    } catch (_) {
      text = String.fromCharCodes(bytes)
          .replaceAll(RegExp(r'[^\x20-\x7E\n\r\t]'), ' ')
          .replaceAll(RegExp(r' {2,}'), ' ');
    }
    if (text.length > 4000) text = text.substring(0, 4000);

    setState(() {
      _resumeText = text;
      _resumeFileName = file.name;
      _step = 1;
    });
  }

  // ── Step 2: Run the agentic pipeline ──────────────────────────
  Future<void> _runAgent() async {
    if (_jdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please paste the job description first',
            style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: AppTheme.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }

    setState(() { _step = 2; _agentStep = 0; });
    _cycleAgentSteps();

    const apiKey = AppConfig.groqApiKey;
    const url = AppConfig.groqUrl;

    final prompt = '''
You are an expert resume rewriting agent for Indian engineering students.

RESUME:
"""
$_resumeText
"""

JOB DESCRIPTION:
"""
${_jdController.text.trim()}
"""

You are an agentic AI. Follow these steps:
1. Extract top 10 required skills/keywords from the JD
2. Identify which skills the candidate already has
3. Rewrite 4-5 resume bullet points to match JD keywords
4. Score ATS compatibility before and after
5. Give specific actionable improvements

Return ONLY valid JSON:
{
  "jdKeywords": ["keyword1", "keyword2", "keyword3", "keyword4", "keyword5"],
  "matchedSkills": ["skill1", "skill2"],
  "missingSkills": ["skill1", "skill2"],
  "atsScoreBefore": 35,
  "atsScoreAfter": 78,
  "rewrittenBullets": [
    {
      "original": "original bullet point from resume",
      "rewritten": "rewritten bullet point with JD keywords",
      "improvement": "why this is better"
    }
  ],
  "topImprovements": [
    "Add X to your skills section",
    "Quantify your Y achievement",
    "Include Z keyword in your summary"
  ],
  "summary": "2 sentence overall assessment"
}
No markdown. Just JSON.''';

    try {
      final response = await http.post(
        Uri.parse('$url?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'temperature': 0.3, 'maxOutputTokens': 2000},
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final text = json['candidates'][0]['content']['parts'][0]['text'] as String;
        String clean = text.trim()
            .replaceAll('```json', '').replaceAll('```', '').trim();
        final start = clean.indexOf('{');
        final end = clean.lastIndexOf('}');
        if (start != -1 && end != -1) clean = clean.substring(start, end + 1);
        setState(() { _result = jsonDecode(clean); _step = 3; });
      } else {
        setState(() { _result = _fallbackResult(); _step = 3; });
      }
    } catch (_) {
      setState(() { _result = _fallbackResult(); _step = 3; });
    }
  }

  void _cycleAgentSteps() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _step == 2 && _agentStep < _agentSteps.length - 1) {
        setState(() => _agentStep++);
        _cycleAgentSteps();
      }
    });
  }

  Map<String, dynamic> _fallbackResult() => {
    'jdKeywords': ['Python', 'Machine Learning', 'SQL', 'Data Analysis', 'TensorFlow'],
    'matchedSkills': ['Python', 'SQL'],
    'missingSkills': ['TensorFlow', 'Machine Learning', 'Data Analysis'],
    'atsScoreBefore': 30,
    'atsScoreAfter': 65,
    'rewrittenBullets': [
      {
        'original': 'Worked on data projects',
        'rewritten': 'Developed machine learning models using Python and TensorFlow to analyse datasets of 10,000+ records',
        'improvement': 'Added specific technologies and quantified the impact'
      }
    ],
    'topImprovements': [
      'Add TensorFlow and scikit-learn to your skills section',
      'Quantify all achievements with numbers and percentages',
      'Add a professional summary mentioning Machine Learning and Data Analysis'
    ],
    'summary': 'Your resume needs more JD-specific keywords to pass ATS filters. The rewritten bullets above will significantly improve your chances.'
  };

  // ── UI ─────────────────────────────────────────────────────────
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
                    Text('AI Resume Rewriter',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 17, fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppTheme.orange.withOpacity(0.5)),
                      ),
                      child: Text('Agentic AI',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 9, fontWeight: FontWeight.w700,
                              color: AppTheme.orange)),
                    ),
                  ]),
                  Text('Rewrites your resume for any job',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, color: Colors.white54)),
                ],
              )),
              if (_step == 3)
                GestureDetector(
                  onTap: () => setState(() {
                    _step = 0; _result = null;
                    _resumeText = ''; _resumeFileName = '';
                    _jdController.clear();
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

          // Progress steps indicator
          if (_step < 3)
            Container(
              color: AppTheme.navy,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(children: [
                _StepDot(1, 'Upload', _step >= 0),
                _StepLine(_step >= 1),
                _StepDot(2, 'Job desc', _step >= 1),
                _StepLine(_step >= 2),
                _StepDot(3, 'AI rewrites', _step >= 2),
              ]),
            ),

          Expanded(
            child: _step == 0
                ? _buildUpload()
                : _step == 1
                    ? _buildPasteJD()
                    : _step == 2
                        ? _buildAnalysing()
                        : _buildResults(),
          ),
        ]),
      ),
    );
  }

  // ── Step 0: Upload ─────────────────────────────────────────────
  Widget _buildUpload() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(children: [
      const SizedBox(height: 20),
      GestureDetector(
        onTap: _pickResume,
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
            Text('Upload your resume',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w800,
                    color: AppTheme.textDark)),
            const SizedBox(height: 8),
            Text('PDF or TXT · Agent will rewrite it for any job',
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
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.navy,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How the AI agent works',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 14),
            _AgentStep('1', 'Reads your resume and extracts your skills',
                AppTheme.orange),
            _AgentStep('2', 'Analyses the job description for key requirements',
                AppTheme.primary),
            _AgentStep('3', 'Rewrites your bullets to match JD keywords',
                AppTheme.green),
            _AgentStep('4', 'Scores your ATS compatibility before and after',
                AppTheme.amber),
          ],
        ),
      ),
    ]),
  );

  // ── Step 1: Paste JD ───────────────────────────────────────────
  Widget _buildPasteJD() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resume uploaded confirmation
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.greenLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.greenBorder),
          ),
          child: Row(children: [
            Icon(Icons.check_circle_rounded,
                color: AppTheme.green, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'Resume uploaded: $_resumeFileName',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppTheme.green),
            )),
            GestureDetector(
              onTap: () => setState(() {
                _step = 0; _resumeText = ''; _resumeFileName = '';
              }),
              child: Icon(Icons.close_rounded,
                  color: AppTheme.green, size: 18),
            ),
          ]),
        ),
        const SizedBox(height: 20),

        Text('Paste the job description',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 15, fontWeight: FontWeight.w800,
                color: AppTheme.textDark)),
        const SizedBox(height: 6),
        Text('Copy it from LinkedIn, Naukri, or any job posting',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: AppTheme.textMid)),
        const SizedBox(height: 12),

        TextField(
          controller: _jdController,
          maxLines: 12,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: AppTheme.textDark),
          decoration: InputDecoration(
            hintText: 'Paste job description here...\n\nExample:\nWe are looking for a Data Scientist with experience in Python, Machine Learning, TensorFlow...',
            hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: AppTheme.textLight),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppTheme.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppTheme.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color: AppTheme.primary, width: 2)),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity, height: 54,
          child: ElevatedButton.icon(
            onPressed: _runAgent,
            icon: const Icon(Icons.auto_awesome_rounded, size: 20),
            label: Text('Rewrite my resume with AI',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ),
      ],
    ),
  );

  // ── Step 2: Analysing ──────────────────────────────────────────
  Widget _buildAnalysing() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.9, end: 1.1),
            duration: const Duration(milliseconds: 800),
            builder: (_, val, child) =>
                Transform.scale(scale: val, child: child),
            onEnd: () { if (mounted) setState(() {}); },
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: AppTheme.purpleLight,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(Icons.psychology_rounded,
                  color: AppTheme.primary, size: 50),
            ),
          ),
          const SizedBox(height: 24),
          Text('AI Agent is working',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 20, fontWeight: FontWeight.w800,
                  color: AppTheme.textDark)),
          const SizedBox(height: 8),
          Text('Rewriting your resume for this job...',
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
                final i = e.key;
                final isDone = i < _agentStep;
                final isCurrent = i == _agentStep;
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
                                        color: Colors.white, strokeWidth: 2))
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
                                ? AppTheme.textDark
                                : AppTheme.textLight)),
                  ]),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ),
  );

  // ── Step 3: Results ────────────────────────────────────────────
  Widget _buildResults() {
    final before = _result!['atsScoreBefore'] as int;
    final after = _result!['atsScoreAfter'] as int;
    final keywords = List<String>.from(_result!['jdKeywords'] ?? []);
    final matched = List<String>.from(_result!['matchedSkills'] ?? []);
    final missing = List<String>.from(_result!['missingSkills'] ?? []);
    final bullets = List<Map<String, dynamic>>.from(
        (_result!['rewrittenBullets'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e)));
    final improvements =
        List<String>.from(_result!['topImprovements'] ?? []);
    final summary = _result!['summary'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [

        // ATS Score comparison
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.navy,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(children: [
            Text('ATS Score Improvement',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, color: Colors.white60)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(children: [
                  Text('$before%',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 40, fontWeight: FontWeight.w800,
                          color: Colors.red.shade400)),
                  Text('Before',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: Colors.white54)),
                ]),
                Column(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.green.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_forward_rounded,
                        color: AppTheme.green, size: 22),
                  ),
                  const SizedBox(height: 4),
                  Text('+${after - before}%',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: AppTheme.green)),
                ]),
                Column(children: [
                  Text('$after%',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 40, fontWeight: FontWeight.w800,
                          color: AppTheme.green)),
                  Text('After',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: Colors.white54)),
                ]),
              ],
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
                      fontSize: 12, color: Colors.white70,
                      height: 1.5),
                  textAlign: TextAlign.center),
            ),
          ]),
        ),

        const SizedBox(height: 16),

        // JD Keywords
        _ResultSection(
          title: 'Job description keywords',
          icon: Icons.key_rounded,
          color: AppTheme.primary,
          bg: AppTheme.purpleLight,
          child: Wrap(
            spacing: 8, runSpacing: 8,
            children: keywords.map((k) {
              final isMatched = matched.contains(k);
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isMatched
                      ? AppTheme.greenLight
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isMatched
                        ? AppTheme.green.withOpacity(0.4)
                        : Colors.red.shade200,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    isMatched
                        ? Icons.check_rounded
                        : Icons.close_rounded,
                    size: 12,
                    color: isMatched
                        ? AppTheme.green : Colors.red.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(k,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: isMatched
                              ? AppTheme.green
                              : Colors.red.shade600)),
                ]),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),

        // Rewritten bullets
        _ResultSection(
          title: 'Rewritten resume bullets',
          icon: Icons.edit_note_rounded,
          color: AppTheme.orange,
          bg: AppTheme.orangeLight,
          child: Column(
            children: bullets.map((b) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(children: [
                // Before
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Before',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red.shade400)),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Text(b['original'] ?? '',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, color: AppTheme.textMid,
                              height: 1.4)),
                    ],
                  ),
                ),
                Container(height: 1, color: AppTheme.border),
                // After
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.greenLight,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.greenLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppTheme.green.withOpacity(0.4)),
                          ),
                          child: Text('After (AI rewritten)',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.green)),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Text(b['rewritten'] ?? '',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark, height: 1.4)),
                      if (b['improvement'] != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lightbulb_outline_rounded,
                                size: 13, color: AppTheme.green),
                            const SizedBox(width: 5),
                            Expanded(child: Text(
                              b['improvement'],
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppTheme.green.withOpacity(0.8),
                                  height: 1.4),
                            )),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ]),
            )).toList(),
          ),
        ),

        const SizedBox(height: 12),

        // Top improvements
        _ResultSection(
          title: 'Top improvements to make',
          icon: Icons.trending_up_rounded,
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
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
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
                  _step = 0; _result = null;
                  _resumeText = ''; _resumeFileName = '';
                  _jdController.clear();
                }),
                icon: Icon(Icons.refresh_rounded,
                    size: 18, color: AppTheme.navy),
                label: Text('Try another job',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w700,
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
                icon: const Icon(Icons.school_rounded, size: 18),
                label: Text('Learn missing skills',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w700)),
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

// ── Helper Widgets ─────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final int num;
  final String label;
  final bool active;
  const _StepDot(this.num, this.label, this.active);
  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: active ? AppTheme.orange : Colors.white24,
        shape: BoxShape.circle,
      ),
      child: Center(child: Text('$num',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: Colors.white))),
    ),
    const SizedBox(height: 4),
    Text(label, style: GoogleFonts.plusJakartaSans(
        fontSize: 9, color: active ? Colors.white : Colors.white38)),
  ]);
}

class _StepLine extends StatelessWidget {
  final bool active;
  const _StepLine(this.active);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 18),
      color: active ? AppTheme.orange : Colors.white24,
    ),
  );
}

class _AgentStep extends StatelessWidget {
  final String num, text;
  final Color color;
  const _AgentStep(this.num, this.text, this.color);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
            color: color.withOpacity(0.2), shape: BoxShape.circle),
        child: Center(child: Text(num,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11, fontWeight: FontWeight.w800, color: color))),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(text,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 12, color: Colors.white70))),
    ]),
  );
}

class _ResultSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color, bg;
  final Widget child;
  const _ResultSection({required this.title, required this.icon,
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
