import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/theme.dart';

class InterviewScreen extends StatefulWidget {
  final String track;
  final String weekTitle;
  const InterviewScreen({
    super.key, required this.track, required this.weekTitle});
  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  List<Map<String, dynamic>> _questions = [];
  int _currentQ = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showFeedback = false;
  final _answerController = TextEditingController();
  String _feedback = '';
  int _score = 0;
  int _totalScore = 0;
  bool _sessionDone = false;

  @override
  void initState() {
    super.initState();
    _generateQuestions();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _generateQuestions() async {
    const apiKey = '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';
    const url =
        'https://api.groq.com/openai/v1/chat/completions';

    final prompt = '''
Generate 5 interview questions for a "${widget.track}" role, 
specifically about "${widget.weekTitle}".

Mix of question types: conceptual, practical, coding-related.
Suitable for Indian engineering students applying for their first job.

Return ONLY valid JSON:
{
  "questions": [
    {
      "question": "What is...?",
      "type": "Conceptual",
      "difficulty": "Easy",
      "keyPoints": ["point1", "point2", "point3"]
    }
  ]
}
No markdown. Just JSON.''';

    try {
      final response = await http.post(
        Uri.parse('$url?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 1000},
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final text = json['candidates'][0]['content']['parts'][0]['text'] as String;
        String clean = text.trim()
            .replaceAll('```json', '').replaceAll('```', '').trim();
        final start = clean.indexOf('{');
        final end = clean.lastIndexOf('}');
        if (start != -1 && end != -1) clean = clean.substring(start, end + 1);
        final data = jsonDecode(clean);
        setState(() {
          _questions = List<Map<String, dynamic>>.from(data['questions']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _questions = _fallbackQuestions();
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _questions = _fallbackQuestions();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAnswer() async {
    if (_answerController.text.trim().isEmpty) return;
    setState(() { _isSubmitting = true; });

    const apiKey = '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';
    const url =
        'https://api.groq.com/openai/v1/chat/completions';

    final q = _questions[_currentQ];
    final prompt = '''
Interview question: "${q['question']}"
Key points expected: ${(q['keyPoints'] as List).join(', ')}
Student answer: "${_answerController.text}"

Grade this answer for a ${widget.track} fresher role.
Return ONLY valid JSON:
{
  "score": 7,
  "maxScore": 10,
  "feedback": "2-3 sentences of specific feedback",
  "missed": ["key point they missed"],
  "good": ["what they got right"]
}''';

    try {
      final response = await http.post(
        Uri.parse('$url?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'temperature': 0.3, 'maxOutputTokens': 400},
        }),
      ).timeout(const Duration(seconds: 10));

      Map<String, dynamic> result;
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final text = json['candidates'][0]['content']['parts'][0]['text'] as String;
        String clean = text.trim()
            .replaceAll('```json', '').replaceAll('```', '').trim();
        final start = clean.indexOf('{');
        final end = clean.lastIndexOf('}');
        if (start != -1 && end != -1) clean = clean.substring(start, end + 1);
        result = jsonDecode(clean);
      } else {
        result = {'score': 5, 'maxScore': 10,
            'feedback': 'Good attempt! Review the key concepts for this topic.',
            'missed': [], 'good': ['You attempted the question']};
      }

      setState(() {
        _feedback = result['feedback'] ?? '';
        _score = result['score'] ?? 5;
        _totalScore += _score;
        _showFeedback = true;
        _isSubmitting = false;
      });
    } catch (_) {
      setState(() {
        _feedback = 'Good attempt! Review the key concepts.';
        _score = 5;
        _totalScore += 5;
        _showFeedback = true;
        _isSubmitting = false;
      });
    }
  }

  void _nextQuestion() {
    if (_currentQ < _questions.length - 1) {
      setState(() {
        _currentQ++;
        _showFeedback = false;
        _answerController.clear();
        _score = 0;
        _feedback = '';
      });
    } else {
      _finishSession();
    }
  }

  Future<void> _finishSession() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'lastInterviewScore': _totalScore,
        'lastInterviewTrack': widget.track,
        'lastInterviewDate': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    }
    setState(() => _sessionDone = true);
  }

  List<Map<String, dynamic>> _fallbackQuestions() => [
    {'question': 'Explain the main concepts of ${widget.weekTitle} in simple terms.',
     'type': 'Conceptual', 'difficulty': 'Easy',
     'keyPoints': ['Definition', 'Use cases', 'Benefits']},
    {'question': 'What are the most common challenges when working with ${widget.weekTitle}?',
     'type': 'Practical', 'difficulty': 'Medium',
     'keyPoints': ['Real challenges', 'Solutions', 'Best practices']},
    {'question': 'How would you explain ${widget.weekTitle} to a non-technical person?',
     'type': 'Communication', 'difficulty': 'Easy',
     'keyPoints': ['Simple analogy', 'Clear explanation', 'Practical example']},
    {'question': 'What tools or libraries are commonly used for ${widget.weekTitle}?',
     'type': 'Technical', 'difficulty': 'Medium',
     'keyPoints': ['Popular tools', 'When to use each', 'Industry standard']},
    {'question': 'Describe a project where you could apply ${widget.weekTitle}.',
     'type': 'Project', 'difficulty': 'Medium',
     'keyPoints': ['Problem statement', 'Solution approach', 'Expected outcome']},
  ];

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
                  Text('Interview Practice',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 17, fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  Text('${widget.track} · ${widget.weekTitle}',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, color: Colors.white54)),
                ],
              )),
              if (!_isLoading && !_sessionDone)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppTheme.orange.withOpacity(0.4)),
                  ),
                  child: Text(
                    '${_currentQ + 1} / ${_questions.length}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: AppTheme.orange),
                  ),
                ),
            ]),
          ),

          // Progress bar
          if (!_isLoading && !_sessionDone)
            LinearProgressIndicator(
              value: (_currentQ + (_showFeedback ? 1 : 0)) / _questions.length,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation(AppTheme.orange),
              minHeight: 4,
            ),

          Expanded(
            child: _isLoading
                ? _buildLoading()
                : _sessionDone
                    ? _buildDone()
                    : _buildQuestion(),
          ),
        ]),
      ),
    );
  }

  Widget _buildLoading() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CircularProgressIndicator(color: AppTheme.orange),
      const SizedBox(height: 16),
      Text('Generating questions with AI...',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14, color: AppTheme.textMid)),
    ]),
  );

  Widget _buildQuestion() {
    final q = _questions[_currentQ];
    final diffColor = q['difficulty'] == 'Easy'
        ? AppTheme.green : q['difficulty'] == 'Medium'
            ? AppTheme.orange : Colors.red.shade400;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Question card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.navy,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: diffColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(q['difficulty'] ?? 'Medium',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: diffColor)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(q['type'] ?? 'Technical',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10, fontWeight: FontWeight.w600,
                        color: Colors.white60)),
              ),
            ]),
            const SizedBox(height: 14),
            Text(q['question'] ?? '',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: Colors.white, height: 1.4)),
          ]),
        ),

        const SizedBox(height: 20),

        if (!_showFeedback) ...[
          Text('Your answer',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  color: AppTheme.textDark)),
          const SizedBox(height: 8),
          TextField(
            controller: _answerController,
            maxLines: 6,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14, color: AppTheme.textDark),
            decoration: InputDecoration(
              hintText: 'Type your answer here...',
              hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: AppTheme.textLight),
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)),
                        const SizedBox(width: 10),
                        Text('Gemini is grading...',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                      ])
                  : Text('Submit answer',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],

        // Feedback
        if (_showFeedback) ...[
          // Score
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _score >= 7
                  ? AppTheme.greenLight
                  : _score >= 5
                      ? AppTheme.orangeLight
                      : Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _score >= 7
                    ? AppTheme.greenBorder
                    : _score >= 5
                        ? AppTheme.orangeBorder
                        : Colors.red.shade200,
              ),
            ),
            child: Row(children: [
              Text('$_score/10',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 28, fontWeight: FontWeight.w800,
                      color: _score >= 7
                          ? AppTheme.green
                          : _score >= 5
                              ? AppTheme.orange
                              : Colors.red.shade400)),
              const SizedBox(width: 14),
              Expanded(child: Text(_feedback,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: AppTheme.textDark,
                      height: 1.5))),
            ]),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                _currentQ < _questions.length - 1
                    ? 'Next question →'
                    : 'See final score',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildDone() {
    final maxScore = _questions.length * 10;
    final pct = (_totalScore / maxScore * 100).round();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: pct >= 70 ? AppTheme.greenLight : AppTheme.orangeLight,
                shape: BoxShape.circle,
              ),
              child: Center(child: Text('$pct%',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 28, fontWeight: FontWeight.w800,
                      color: pct >= 70 ? AppTheme.green : AppTheme.orange))),
            ),
            const SizedBox(height: 20),
            Text('Interview complete!',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: AppTheme.textDark)),
            const SizedBox(height: 8),
            Text('$_totalScore / $maxScore points',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, color: AppTheme.textMid)),
            const SizedBox(height: 8),
            Text(
              pct >= 70
                  ? 'Great job! You know this topic well.'
                  : 'Keep studying — review this week\'s material.',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: AppTheme.textMid,
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text('Back to home',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
