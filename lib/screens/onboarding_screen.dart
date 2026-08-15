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
      'subtitle': 'AI adapts your roadmap foundation to your degree',
      'icon': Icons.school_rounded,
      'key': 'branch',
      'options': [
        {'title': 'Computer Science', 'desc': 'Software, Algorithms & Systems', 'icon': Icons.computer_rounded},
        {'title': 'Information Technology', 'desc': 'Cloud, Web & Database Systems', 'icon': Icons.lan_rounded},
        {'title': 'Electronics', 'desc': 'Embedded, VLSI & IoT Systems', 'icon': Icons.memory_rounded},
        {'title': 'Mechanical', 'desc': 'Automation, Robotics & CAD', 'icon': Icons.precision_manufacturing_rounded},
        {'title': 'Other', 'desc': 'Other branches & disciplines', 'icon': Icons.auto_awesome_rounded},
      ],
    },
    {
      'question': 'Which year are you in?',
      'subtitle': 'Helps set the right pace and timeline for placements',
      'icon': Icons.calendar_today_rounded,
      'key': 'year',
      'options': [
        {'title': '1st Year', 'desc': 'Building fundamentals & basics', 'icon': Icons.looks_one_rounded},
        {'title': '2nd Year', 'desc': 'Core skills & mini projects', 'icon': Icons.looks_two_rounded},
        {'title': '3rd Year', 'desc': 'Internship prep & major projects', 'icon': Icons.looks_3_rounded, 'badge': 'Peak Prep 🔥'},
        {'title': '4th Year', 'desc': 'Placements & full-time job hunt', 'icon': Icons.looks_4_rounded, 'badge': 'Job Ready ⚡'},
        {'title': 'Graduated', 'desc': 'Immediate hiring & career switch', 'icon': Icons.workspace_premium_rounded},
      ],
    },
    {
      'question': 'What is your coding experience?',
      'subtitle': 'Calibrates starting difficulty so you never feel stuck',
      'icon': Icons.code_rounded,
      'key': 'experience',
      'options': [
        {'title': 'Complete Beginner', 'desc': 'Never written a line of code', 'icon': Icons.sentiment_satisfied_alt_rounded},
        {'title': 'Know basics', 'desc': 'Syntax, loops, basic conditions', 'icon': Icons.trending_up_rounded},
        {'title': 'Intermediate', 'desc': 'Built small apps, know DSA basics', 'icon': Icons.star_rounded, 'badge': 'Popular 🌟'},
        {'title': 'Advanced', 'desc': 'Proficient with frameworks & APIs', 'icon': Icons.rocket_launch_rounded},
      ],
    },
    {
      'question': 'How many hours can you study per week?',
      'subtitle': 'AI calibrates your weekly roadmap milestones',
      'icon': Icons.access_time_rounded,
      'key': 'hours',
      'options': [
        {'title': '2-4 hours', 'desc': 'Casual • 20-30 mins/day', 'icon': Icons.bolt_rounded},
        {'title': '5-8 hours', 'desc': 'Steady Pace • 1 hr/day', 'icon': Icons.local_fire_department_rounded, 'badge': 'Recommended 🌟'},
        {'title': '8-12 hours', 'desc': 'Accelerated Track • 1.5-2 hrs/day', 'icon': Icons.rocket_launch_rounded, 'badge': 'Popular'},
        {'title': '12+ hours', 'desc': 'Bootcamp Mode • 2+ hrs/day', 'icon': Icons.whatshot_rounded},
      ],
    },
    {
      'question': 'What is your main goal?',
      'subtitle': 'We customize interview questions & projects for this',
      'icon': Icons.flag_rounded,
      'key': 'goal',
      'options': [
        {'title': 'Get a job', 'desc': 'Target tech & software companies', 'icon': Icons.work_outline_rounded},
        {'title': 'Crack FAANG', 'desc': 'Top-tier product MNCs (Google/Amazon)', 'icon': Icons.military_tech_rounded, 'badge': 'Top Choice 🏆'},
        {'title': 'Build startup', 'desc': 'Launch your own tech products', 'icon': Icons.rocket_rounded},
        {'title': 'Research & PhD', 'desc': 'Academic research & higher studies', 'icon': Icons.science_rounded},
      ],
    },
  ];

  void selectAnswer(String answer) async {
    setState(() => answers[questions[currentStep]['key']] = answer);
    await Future.delayed(const Duration(milliseconds: 220));
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
    final currentOptions = q['options'] as List<Map<String, dynamic>>;

    return Scaffold(
      backgroundColor: const Color(0xFF111322),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Container(
              color: const Color(0xFFF8F9FE),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF111322),
                          Color(0xFF1B1D36),
                        ],
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      MediaQuery.of(context).padding.top + 16,
                      20,
                      20,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            if (currentStep > 0)
                              GestureDetector(
                                onTap: () => setState(() => currentStep--),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              )
                            else
                              const SizedBox(width: 32),
                            const SizedBox(width: 12),
                            Text(
                              'Step ${currentStep + 1} of ${questions.length}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFB3B0D6),
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Text(
                                  'PathForge Setup',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFFF5722),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Image.asset(
                                        'assets/logo.png',
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => const Icon(
                                          Icons.trending_up,
                                          size: 14,
                                          color: Color(0xFF7C5CBF),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: progress),
                            duration: const Duration(milliseconds: 350),
                            builder: (_, val, __) => LinearProgressIndicator(
                              value: val,
                              backgroundColor: Colors.white12,
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xFFFF5722),
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Column(
                          key: ValueKey(currentStep),
                          children: [
                            Center(
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF7C5CBF),
                                      Color(0xFFFF5722),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF7C5CBF)
                                          .withOpacity(0.28),
                                      blurRadius: 18,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    q['icon'] as IconData,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            Text(
                              q['question'],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF111322),
                                height: 1.25,
                                letterSpacing: -0.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),

                            Text(
                              q['subtitle'] ?? 'Choose one to continue',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                color: const Color(0xFF6B6890),
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            ...currentOptions.map((opt) {
                              final title = opt['title'] as String;
                              final desc = opt['desc'] as String?;
                              final icon = opt['icon'] as IconData?;
                              final badge = opt['badge'] as String?;
                              final isSelected = answers[q['key']] == title;

                              return GestureDetector(
                                onTap: () => selectAnswer(title),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFFFF3EE)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFFF5722)
                                          : const Color(0xFFE2E4F0),
                                      width: isSelected ? 2 : 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? const Color(0xFFFF5722)
                                                .withOpacity(0.14)
                                            : Colors.black.withOpacity(0.03),
                                        blurRadius: isSelected ? 12 : 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFFFF5722)
                                                  .withOpacity(0.15)
                                              : const Color(0xFF7C5CBF)
                                                  .withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          icon ?? q['icon'] as IconData,
                                          color: isSelected
                                              ? const Color(0xFFFF5722)
                                              : const Color(0xFF7C5CBF),
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 14),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    title,
                                                    style: GoogleFonts
                                                        .plusJakartaSans(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          const Color(0xFF111322),
                                                    ),
                                                  ),
                                                ),
                                                if (badge != null)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                              0xFFFF5722)
                                                          .withOpacity(0.12),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    child: Text(
                                                      badge,
                                                      style: GoogleFonts
                                                          .plusJakartaSans(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: const Color(
                                                            0xFFFF5722),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            if (desc != null) ...[
                                              const SizedBox(height: 3),
                                              Text(
                                                desc,
                                                style: GoogleFonts
                                                    .plusJakartaSans(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w500,
                                                  color:
                                                      const Color(0xFF6B6890),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? const Color(0xFFFF5722)
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFFFF5722)
                                                : const Color(0xFFD3D5E6),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: isSelected
                                            ? const Icon(
                                                Icons.check_rounded,
                                                color: Colors.white,
                                                size: 15,
                                              )
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
