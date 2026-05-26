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
    {'question': 'What is your engineering branch?', 'icon': Icons.school_rounded, 'key': 'branch',
      'options': ['Computer Science', 'Information Technology', 'Electronics', 'Mechanical', 'Other']},
    {'question': 'Which year are you in?', 'icon': Icons.calendar_today_rounded, 'key': 'year',
      'options': ['1st Year', '2nd Year', '3rd Year', '4th Year', 'Graduated']},
    {'question': 'What is your coding experience?', 'icon': Icons.laptop_mac_rounded, 'key': 'experience',
      'options': ['Complete Beginner', 'Know basics', 'Intermediate', 'Advanced']},
    {'question': 'How many hours can you study per week?', 'icon': Icons.access_time_rounded, 'key': 'hours',
      'options': ['2-4 hours', '5-8 hours', '8-12 hours', '12+ hours']},
    {'question': 'What is your main goal?', 'icon': Icons.flag_rounded, 'key': 'goal',
      'options': ['Get a job', 'Crack FAANG', 'Build startup', 'Research & PhD']},
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
          await FirebaseFirestore.instance.collection('users').doc(uid)
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
            // Navy top bar
            Container(
              color: AppTheme.navy,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (currentStep > 0)
                        GestureDetector(
                          onTap: () => setState(() => currentStep--),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white, size: 16),
                          ),
                        )
                      else
                        const SizedBox(width: 36),
                      const Spacer(),
                      Text('${currentStep + 1} of ${questions.length}',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: Colors.white60)),
                      const Spacer(),
                      const SizedBox(width: 36),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation(AppTheme.orange),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.orangeLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.orangeBorder),
                      ),
                      child: Icon(q['icon'] as IconData,
                          color: AppTheme.orange, size: 28),
                    ),
                    const SizedBox(height: 20),
                    Text(q['question'],
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 22, fontWeight: FontWeight.w800,
                            color: AppTheme.textDark, height: 1.3)),
                    const SizedBox(height: 6),
                    Text('Choose one option below',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, color: AppTheme.textLight)),
                    const SizedBox(height: 28),
                    Expanded(
                      child: ListView.builder(
                        itemCount: (q['options'] as List).length,
                        itemBuilder: (context, i) {
                          final option = q['options'][i] as String;
                          final isSelected = answers[q['key']] == option;
                          return GestureDetector(
                            onTap: () => selectAnswer(option),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.navy : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? AppTheme.navy : AppTheme.border,
                                  width: isSelected ? 2 : 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(child: Text(option,
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15, fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white : AppTheme.textDark))),
                                  if (isSelected)
                                    Container(
                                      width: 22, height: 22,
                                      decoration: BoxDecoration(
                                        color: AppTheme.orange,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check_rounded,
                                          color: Colors.white, size: 13),
                                    ),
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
            ),
          ],
        ),
      ),
    );
  }
}
