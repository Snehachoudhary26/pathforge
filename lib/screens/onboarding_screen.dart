import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentStep = 0;
  final Map<String, String> answers = {};

  final List<Map<String, dynamic>> questions = [
    {
      'question': 'What is your engineering branch?',
      'emoji': '🎓',
      'key': 'branch',
      'options': ['Computer Science', 'Information Technology', 'Electronics', 'Mechanical', 'Other'],
    },
    {
      'question': 'Which year are you in?',
      'emoji': '📅',
      'key': 'year',
      'options': ['1st Year', '2nd Year', '3rd Year', '4th Year', 'Graduated'],
    },
    {
      'question': 'What is your coding experience?',
      'emoji': '💻',
      'key': 'experience',
      'options': ['Complete Beginner', 'Know basics', 'Intermediate', 'Advanced'],
    },
    {
      'question': 'How many hours can you study per week?',
      'emoji': '⏰',
      'key': 'hours',
      'options': ['2-4 hours', '5-8 hours', '8-12 hours', '12+ hours'],
    },
    {
      'question': 'What is your main goal?',
      'emoji': '🎯',
      'key': 'goal',
      'options': ['Get a job', 'Crack FAANG', 'Build startup', 'Research & PhD'],
    },
  ];

  void selectAnswer(String answer) {
    setState(() {
      answers[questions[currentStep]['key']] = answer;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (currentStep < questions.length - 1) {
        setState(() => currentStep++);
      } else {
        context.go('/track');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = questions[currentStep];
    final progress = (currentStep + 1) / questions.length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 18),
                color: AppTheme.textDark,
                onPressed: () => setState(() => currentStep--),
              )
            : null,
        title: Text('${currentStep + 1} of ${questions.length}',
          style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textMid),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.border,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 40),

            // Emoji
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppTheme.light,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border),
              ),
              child: Center(
                child: Text(q['emoji'], style: const TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(height: 20),

            // Question
            Text(q['question'],
              style: GoogleFonts.poppins(
                fontSize: 22, fontWeight: FontWeight.w700,
                color: AppTheme.textDark, height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text('Choose one option below',
              style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textLight),
            ),
            const SizedBox(height: 32),

            // Options
            Expanded(
              child: ListView.builder(
                itemCount: (q['options'] as List).length,
                itemBuilder: (context, i) {
                  final option = q['options'][i];
                  final isSelected = answers[q['key']] == option;
                  return GestureDetector(
                    onTap: () => selectAnswer(option),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : AppTheme.border,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.2),
                            blurRadius: 10, spreadRadius: 1,
                          )
                        ] : [],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(option,
                              style: GoogleFonts.poppins(
                                fontSize: 15, fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white : AppTheme.textDark,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
