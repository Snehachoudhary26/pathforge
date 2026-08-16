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
      'subtitle': 'Customizes courses, core subjects & projects',
      'icon': Icons.school_rounded,
      'key': 'branch',
      'options': [
        {'title': 'Computer Science', 'desc': 'CSE, Software & Programming'},
        {'title': 'Information Technology', 'desc': 'IT, Systems & Web Tech'},
        {'title': 'Electronics & Comm', 'desc': 'ECE, Embedded & Hardware'},
        {'title': 'Mechanical / Civil', 'desc': 'Core Engineering Branches'},
        {'title': 'Other Branch', 'desc': 'BCA, BSc, MCA or other degree'},
      ]
    },
    {
      'question': 'Which year are you in?',
      'subtitle': 'Helps set the right pace and timeline for placements',
      'icon': Icons.calendar_today_rounded,
      'key': 'year',
      'options': [
        {'title': '1st Year', 'desc': 'Building fundamentals & basics', 'tag': ''},
        {'title': '2nd Year', 'desc': 'Core skills & mini projects', 'tag': ''},
        {'title': '3rd Year', 'desc': 'Internship prep & major projects', 'tag': 'Peak Prep 🔥'},
        {'title': '4th Year', 'desc': 'Placements & full-time job hunt', 'tag': 'Job Ready ⚡'},
        {'title': 'Graduated', 'desc': 'Immediate career switch / job search', 'tag': ''},
      ]
    },
    {
      'question': 'What is your coding experience?',
      'subtitle': 'We adapt the roadmap difficulty to your level',
      'icon': Icons.laptop_mac_rounded,
      'key': 'experience',
      'options': [
        {'title': 'Complete Beginner', 'desc': 'Never coded or just starting out'},
        {'title': 'Know Basics', 'desc': 'Familiar with syntax and loops'},
        {'title': 'Intermediate', 'desc': 'Built small projects & know DSA basics'},
        {'title': 'Advanced', 'desc': 'Confident in full-stack, ML or systems'},
      ]
    },
    {
      'question': 'How many hours can you study?',
      'subtitle': 'Calculates your estimated weekly completion targets',
      'icon': Icons.access_time_rounded,
      'key': 'hours',
      'options': [
        {'title': '2–4 hours / week', 'desc': 'Light pace · Casual learning'},
        {'title': '5–8 hours / week', 'desc': 'Balanced pace · Recommended'},
        {'title': '8–12 hours / week', 'desc': 'Intensive pace · Fast-track'},
        {'title': '12+ hours / week', 'desc': 'Full-time immersive bootcamp mode'},
      ]
    },
    {
      'question': 'What is your primary career goal?',
      'subtitle': 'AI tailors interview questions & portfolio guidance',
      'icon': Icons.flag_rounded,
      'key': 'goal',
      'options': [
        {'title': 'Get a Software Job', 'desc': 'Land high-paying campus/off-campus role'},
        {'title': 'Crack Top Product Companies', 'desc': 'FAANG, Tier-1 MNCs & startups'},
        {'title': 'Build AI & Web Startups', 'desc': 'Launch products & freelance'},
        {'title': 'Higher Studies & Research', 'desc': 'MS, GATE or PhD preparation'},
      ]
    },
  ];

  void selectAnswer(String answer) async {
    setState(() => answers[questions[currentStep]['key']] = answer);
    await Future.delayed(const Duration(milliseconds: 200));
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
    final options = q['options'] as List<Map<String, String>>;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top App Bar
            Container(
              color: const Color(0xFF111322),
              padding: EdgeInsets.fromLTRB(
                16,
                topPadding > 0 ? topPadding + 6 : 18,
                16,
                12,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (currentStep > 0) {
                            setState(() => currentStep--);
                          }
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: currentStep > 0
                                ? Colors.white
                                : Colors.white24,
                            size: 13,
                          ),
                        ),
                      ),
                      Text(
                        'Step ${currentStep + 1} of ${questions.length}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        'PathForge Setup',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFF5722),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFFFF5722),
                      ),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),

            // Quiz Body (Proportioned to fit on 1 screen)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    // Icon Badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF5722), Color(0xFF7C5CBF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(
                        q['icon'] as IconData,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Question Title
                    Text(
                      q['question'],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A2E),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),

                    // Subtitle
                    Text(
                      q['subtitle'],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF6B6890),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Options List
                    ...options.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final opt = entry.value;
                      final isSelected =
                          answers[q['key']] == opt['title'];
                      final tag = opt['tag'] ?? '';

                      return GestureDetector(
                        onTap: () => selectAnswer(opt['title']!),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 7),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8.5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF111322)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF111322)
                                  : const Color(0xFFE5E7F2),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Number Badge
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFFF5722)
                                      : const Color(0xFFF0EDF8),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '${idx + 1}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF7C5CBF),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Title & Description
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          opt['title']!,
                                          style:
                                              GoogleFonts.plusJakartaSans(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFF1A1A2E),
                                          ),
                                        ),
                                        if (tag.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFF5722)
                                                  .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              tag,
                                              style: GoogleFonts
                                                  .plusJakartaSans(
                                                fontSize: 8.5,
                                                fontWeight:
                                                    FontWeight.w700,
                                                color: const Color(
                                                    0xFFFF5722),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      opt['desc']!,
                                      style:
                                          GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        color: isSelected
                                            ? Colors.white70
                                            : const Color(0xFF7B7998),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Radio Indicator
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFFF5722)
                                        : const Color(0xFFD4D6E2),
                                    width: isSelected ? 4 : 1.5,
                                  ),
                                ),
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
          ],
        ),
      ),
    );
  }
}
