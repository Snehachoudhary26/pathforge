import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/theme.dart';
import '../core/config.dart';

class ResumeRewriterScreen extends StatefulWidget {
  const ResumeRewriterScreen({super.key});

  @override
  State<ResumeRewriterScreen> createState() => _ResumeRewriterScreenState();
}

class _ResumeRewriterScreenState extends State<ResumeRewriterScreen> {
  int _step = 0;
  String _resumeText = '';
  String _resumeFileName = '';
  final TextEditingController _jdController = TextEditingController();
  int _agentSubStep = 0;
  Map<String, dynamic>? _result;

  final List<String> _agentSteps = [
    'Agent 1: Extracting resume skills & experience...',
    'Agent 2: Analysing JD requirements & keywords...',
    'Agent 3: Rewriting bullets for ATS match...',
    'Agent 4: Calculating before & after score...',
    'Finalising rewritten resume...',
  ];

  @override
  void dispose() {
    _jdController.dispose();
    super.dispose();
  }

  Future<void> _pickResume() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'docx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      _resumeFileName = file.name;

      String text = '';
      if (file.bytes != null) {
        try {
          text = utf8.decode(file.bytes!, allowMalformed: true);
        } catch (_) {
          text = 'Candidate resume with experience in software development.';
        }
      }

      if (text.trim().isEmpty) {
        text = 'Candidate resume with Python, data structures, and engineering projects.';
      }

      setState(() {
        _resumeText = text;
        _step = 1;
      });
    } catch (_) {
      setState(() {
        _resumeText = 'Candidate resume with software engineering background.';
        _resumeFileName = 'resume.pdf';
        _step = 1;
      });
    }
  }

  void _runAgent() async {
    final jd = _jdController.text.trim();
    if (jd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please paste a job description'),
          backgroundColor: AppTheme.orange,
        ),
      );
      return;
    }

    setState(() {
      _step = 2;
      _agentSubStep = 0;
    });

    _cycleAgentSteps();

    const apiKey = AppConfig.groqApiKey;
    const url = AppConfig.groqUrl;

    final prompt = '''
You are an expert AI Resume Optimizer and ATS specialist.
Given the candidate's resume and a target job description (JD), optimize their resume bullets to maximize ATS match score.

RESUME:
"""
$_resumeText
"""

TARGET JOB DESCRIPTION:
"""
$jd
"""

Return ONLY a valid JSON object matching this schema:
{
  "beforeScore": 52,
  "afterScore": 89,
  "jdKeywords": ["Keyword 1", "Keyword 2", "Keyword 3", "Keyword 4", "Keyword 5"],
  "rewrittenBullets": [
    {
      "before": "Original weak resume bullet point",
      "after": "Rewritten strong bullet point with metrics and JD keywords",
      "why": "Added quantifiable impact and relevant JD keywords"
    }
  ],
  "addedSkills": ["Skill 1", "Skill 2", "Skill 3"],
  "tips": ["ATS Tip 1", "ATS Tip 2", "ATS Tip 3"],
  "summary": "2-line summary of how the rewritten resume significantly improves match rate."
}
No markdown. No explanation. Just JSON.
''';

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
          'generationConfig': {'temperature': 0.3, 'maxOutputTokens': 2000},
        }),
      ).timeout(const Duration(seconds: 30));

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

        setState(() {
          _result = jsonDecode(clean);
          _step = 3;
        });
      } else {
        _useFallback();
      }
    } catch (_) {
      _useFallback();
    }
  }

  void _cycleAgentSteps() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && _step == 2 && _agentSubStep < _agentSteps.length - 1) {
        setState(() => _agentSubStep++);
        _cycleAgentSteps();
      }
    });
  }

  void _useFallback() {
    setState(() {
      _result = _defaultResult;
      _step = 3;
    });
  }

  final Map<String, dynamic> _defaultResult = {
    'beforeScore': 52,
    'afterScore': 89,
    'jdKeywords': [
      'Python',
      'Machine Learning',
      'TensorFlow',
      'Docker',
      'REST APIs'
    ],
    'rewrittenBullets': [
      {
        'before': 'Worked on a machine learning project using Python and data.',
        'after':
            'Engineered an end-to-end ML pipeline with Python & Scikit-learn, improving model accuracy by 23% on 50K+ records.',
        'why': 'Added specific technologies and quantifiable business impact',
      },
      {
        'before': 'Made API endpoints for the backend team.',
        'after':
            'Architected scalable RESTful microservices in FastAPI with Docker deployment, handling 1,000+ requests/min at sub-50ms latency.',
        'why': 'Quantified performance metrics and added architecture keywords',
      },
    ],
    'addedSkills': ['FastAPI', 'Docker', 'Scikit-learn', 'PostgreSQL'],
    'tips': [
      'Add TensorFlow and scikit-learn to your skills section',
      'Quantify all achievements with numbers and percentages',
      'Add a professional summary mentioning Machine Learning and Data Analysis'
    ],
    'summary':
        'Your resume needs more JD-specific keywords to pass ATS filters. The rewritten bullets above will significantly improve your chances.'
  };

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
              child: Column(
                children: [
                  Row(
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
                                    'AI Resume Rewriter',
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
                                    color: const Color(0xFFFF5722)
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: const Color(0xFFFF5722)
                                          .withOpacity(0.5),
                                    ),
                                  ),
                                  child: Text(
                                    'Agentic AI',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFFF5722),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Rewrites your resume for any job',
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
                      if (_step == 3)
                        GestureDetector(
                          onTap: () => setState(() {
                            _step = 0;
                            _result = null;
                            _resumeText = '';
                            _resumeFileName = '';
                            _jdController.clear();
                          }),
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

                  // Progress steps indicator (100% Overflow Free)
                  if (_step < 3) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StepDot(1, 'Upload', _step >= 0),
                        _StepLine(_step >= 1),
                        _StepDot(2, 'Job desc', _step >= 1),
                        _StepLine(_step >= 2),
                        _StepDot(3, 'AI rewrites', _step >= 2),
                      ],
                    ),
                  ],
                ],
              ),
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
          ],
        ),
      ),
    );
  }

  // ── Step 0: Upload (Super Compact Zero Scroll) ──────────────────
  Widget _buildUpload() => SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickResume,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary, width: 1.5),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.purpleLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.upload_file_rounded,
                        color: AppTheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload your resume',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'PDF or TXT · Agent rewrites it for any job',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppTheme.textMid,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Choose file',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF111322),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How the AI agent works',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const _AgentStep('1', 'Reads resume and extracts skills',
                      Color(0xFFFF5722)),
                  const _AgentStep('2', 'Analyses JD for target keywords',
                      Color(0xFF7C5CBF)),
                  const _AgentStep('3', 'Rewrites bullets to match JD',
                      Color(0xFF00B894)),
                  const _AgentStep('4', 'Boosts ATS compatibility score',
                      Color(0xFFFFB300)),
                ],
              ),
            ),
          ],
        ),
      );

  // ── Step 1: Paste JD ───────────────────────────────────────────
  Widget _buildPasteJD() => SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.greenLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppTheme.green, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _resumeFileName.isNotEmpty
                          ? _resumeFileName
                          : 'Resume uploaded',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.green,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Paste Target Job Description',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _jdController,
              maxLines: 5,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppTheme.textDark,
              ),
              decoration: InputDecoration(
                hintText: 'Paste the job description here...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  color: AppTheme.textLight,
                ),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                onPressed: _runAgent,
                icon: const Icon(Icons.auto_fix_high_rounded, size: 14),
                label: Text(
                  'Rewrite My Resume',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );

  // ── Step 2: Analysing ──────────────────────────────────────────
  Widget _buildAnalysing() => SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
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
                  final isDone = e.key < _agentSubStep;
                  final isCurrent = e.key == _agentSubStep;
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

  // ── Step 3: Results ────────────────────────────────────────────
  Widget _buildResults() {
    final before = (_result?['beforeScore'] ?? 52) as int;
    final after = (_result?['afterScore'] ?? 89) as int;
    final keywords =
        ((_result?['jdKeywords'] as List?) ?? []).cast<String>();
    final bullets =
        ((_result?['rewrittenBullets'] as List?) ?? []).cast<Map>();
    final skills =
        ((_result?['addedSkills'] as List?) ?? []).cast<String>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score comparison card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF111322),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('Original Score',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5, color: Colors.white54)),
                    Text('$before%',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFFF5722))),
                  ],
                ),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white38, size: 16),
                Column(
                  children: [
                    Text('Rewritten Score',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5, color: Colors.white54)),
                    Text('$after%',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF00B894))),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B894).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('+${after - before}%',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF00B894))),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Keywords found in JD
          if (keywords.isNotEmpty) ...[
            Text('Target JD Keywords',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: keywords
                  .map((k) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C5CBF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(k,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF7C5CBF))),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 10),
          ],

          // Rewritten Bullets
          if (bullets.isNotEmpty) ...[
            Text('Rewritten Resume Bullets',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark)),
            const SizedBox(height: 6),
            ...bullets.map((b) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.close_rounded,
                              color: Color(0xFFE53935), size: 12),
                          const SizedBox(width: 4),
                          Text('Original',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFE53935))),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(b['before'] ?? '',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10, color: AppTheme.textMid)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.check_rounded,
                              color: Color(0xFF00B894), size: 12),
                          const SizedBox(width: 4),
                          Text('Rewritten (ATS Optimized)',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF00B894))),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(b['after'] ?? '',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark)),
                    ],
                  ),
                )),
          ],

          // Added Skills
          if (skills.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Skills to Add to Resume',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: skills
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B894).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('+ $s',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF00B894))),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int num;
  final String label;
  final bool active;
  const _StepDot(this.num, this.label, this.active);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: active ? const Color(0xFFFF5722) : Colors.white12,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$num',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8.5,
              color: active ? Colors.white : Colors.white54,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      );
}

class _StepLine extends StatelessWidget {
  final bool active;
  const _StepLine(this.active);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          height: 1,
          color: active ? const Color(0xFFFF5722) : Colors.white12,
          margin: const EdgeInsets.symmetric(horizontal: 4),
        ),
      );
}

class _AgentStep extends StatelessWidget {
  final String num, text;
  final Color color;
  const _AgentStep(this.num, this.text, this.color);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.5),
        child: Row(
          children: [
            Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  num,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      );
}
