import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      'icon': Icons.school_rounded,
      'key': 'branch',
      'image': 'assets/images/STARTING-END.jpeg',
      'options': ['Computer Science', 'Information Technology',
          'Electronics', 'Mechanical', 'Other']
    },
    {
      'question': 'Which year are you in?',
      'icon': Icons.calendar_today_rounded,
      'key': 'year',
      'image': 'assets/images/Roadmap.jpeg',
      'options': ['1st Year', '2nd Year', '3rd Year', '4th Year', 'Graduated']
    },
    {
      'question': 'What is your coding experience?',
      'icon': Icons.laptop_mac_rounded,
      'key': 'experience',
      'image': 'assets/images/LearningProgress.jpeg',
      'options': ['Complete Beginner', 'Know basics', 'Intermediate', 'Advanced']
    },
    {
      'question': 'How many hours can you study per week?',
      'icon': Icons.access_time_rounded,
      'key': 'hours',
      'image': 'assets/images/GroupProgress.jpeg',
      'options': ['2-4 hours', '5-8 hours', '8-12 hours', '12+ hours']
    },
    {
      'question': 'What is your main goal?',
      'icon': Icons.flag_rounded,
      'key': 'goal',
      'image': 'assets/images/AGENT.jpeg',
      'options': ['Get a job', 'Crack FAANG', 'Build startup', 'Research & PhD']
    },
  ];

  void selectAnswer(String answer) async {
    setState(() => answers[questions[currentStep]['key']] = answer);
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    if (currentStep < questions.length - 1) {
      setState(() => currentStep++);
    } else {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .set(answers, SetOptions(merge: true));
        } catch (_) {}
      }
      if (mounted) context.go('/track');
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = questions[currentStep];
    final progress = (currentStep + 1) / questions.length;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Container(
              color: AppTheme.navy,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${currentStep + 1} of ${questions.length}',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, color: Colors.white54)),
                      Text('PathForge Setup',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: AppTheme.orange)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 400),
                    builder: (_, val, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: val,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation(AppTheme.orange),
                        minHeight: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    key: ValueKey(currentStep),
                    children: [
                      // Small blended image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          q['image'],
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: AppTheme.purpleLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(q['icon'] as IconData,
                                color: AppTheme.primary, size: 60),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Question
                      Text(
                        q['question'],
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 20, fontWeight: FontWeight.w800,
                            color: AppTheme.textDark, height: 1.3),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Choose one to continue',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, color: AppTheme.textMid),
                      ),

                      const SizedBox(height: 24),

                      // Options
                      ...(q['options'] as List<String>).map((option) =>
                        GestureDetector(
                          onTap: () => selectAnswer(option),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: answers[q['key']] == option
                                  ? AppTheme.navy
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: answers[q['key']] == option
                                    ? AppTheme.navy
                                    : AppTheme.border,
                                width: 1.5,
                              ),
                            ),
                            child: Row(children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: answers[q['key']] == option
                                      ? AppTheme.orange.withOpacity(0.2)
                                      : AppTheme.purpleLight,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  answers[q['key']] == option
                                      ? Icons.check_rounded
                                      : q['icon'] as IconData,
                                  color: answers[q['key']] == option
                                      ? AppTheme.orange
                                      : AppTheme.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(option,
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: answers[q['key']] == option
                                          ? Colors.white
                                          : AppTheme.textDark)),
                            ]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
