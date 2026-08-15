import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../services/gemini_service.dart';
import '../services/firestore_service.dart';

class GeneratingScreen extends StatefulWidget {
  final String track;
  const GeneratingScreen({super.key, required this.track});
  @override
  State<GeneratingScreen> createState() => _GeneratingScreenState();
}

class _GeneratingScreenState extends State<GeneratingScreen>
    with TickerProviderStateMixin {
  int _msgIndex = 0;
  String _statusText = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _rotateController;

  final List<Map<String, dynamic>> _steps = [
    {'label': 'Analysing your profile & background', 'icon': Icons.person_search_rounded},
    {'label': 'Selecting best industry resources', 'icon': Icons.auto_stories_rounded},
    {'label': 'Building week-by-week milestones', 'icon': Icons.timeline_rounded},
    {'label': 'Personalising for your career goal', 'icon': Icons.military_tech_rounded},
    {'label': 'Finalising your AI roadmap', 'icon': Icons.task_alt_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _cycleMessages();
    _generateRoadmap();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  void _cycleMessages() {
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted && _msgIndex < _steps.length - 1) {
        setState(() => _msgIndex++);
        _cycleMessages();
      }
    });
  }

  Future<void> _generateRoadmap() async {
    final startTime = DateTime.now();
    setState(() => _statusText = 'Connecting to AI Engine...');
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      String branch = 'Engineering',
          year = '3rd Year',
          experience = 'Intermediate',
          hours = '8-12 hours',
          goal = 'Get a job';

      if (uid != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();
          final data = doc.data() ?? {};
          branch = data['branch'] ?? branch;
          year = data['year'] ?? year;
          experience = data['experience'] ?? experience;
          hours = data['hours'] ?? hours;
          goal = data['goal'] ?? goal;
        } catch (_) {}
      }

      final roadmap = await GeminiService.generateRoadmap(
        track: widget.track,
        branch: branch,
        year: year,
        experience: experience,
        hours: hours,
        goal: goal,
      );

      setState(() => _statusText = 'Calibrating milestones...');

      if (roadmap != null && uid != null) {
        roadmap['track'] = widget.track;
        await FirestoreService.saveRoadmap(uid: uid, roadmap: roadmap);
        setState(() => _statusText = 'Ready! Launching Roadmap...');
      }

      final elapsed = DateTime.now().difference(startTime);
      if (elapsed.inMilliseconds < 4500) {
        await Future.delayed(
            Duration(milliseconds: 4500 - elapsed.inMilliseconds));
      }

      if (mounted) {
        context.go('/roadmap?track=${Uri.encodeComponent(widget.track)}');
      }
    } catch (e) {
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed.inMilliseconds < 4500) {
        await Future.delayed(
            Duration(milliseconds: 4500 - elapsed.inMilliseconds));
      }
      if (mounted) {
        context.go('/roadmap?track=${Uri.encodeComponent(widget.track)}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111322),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _pulseAnim,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF7C5CBF).withOpacity(0.4),
                                const Color(0xFFFF5722).withOpacity(0.15),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        RotationTransition(
                          turns: _rotateController,
                          child: Container(
                            width: 116,
                            height: 116,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  Color(0xFF7C5CBF),
                                  Color(0xFFFF5722),
                                  Color(0xFF00B894),
                                  Color(0xFF7C5CBF),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 104,
                          height: 104,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF1B1D36),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/robot-for-chatbot.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images/ai_mentor_guidance.jpeg',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.smart_toy_rounded,
                                  color: Color(0xFFFF5722),
                                  size: 46,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C5CBF).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF7C5CBF).withOpacity(0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⚡', style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 6),
                        Text(
                          'PathForge AI Engine Active',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFD4C9FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Architecting Your Roadmap',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5722).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.track,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF5722),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      children: _steps.asMap().entries.map((e) {
                        final i = e.key;
                        final step = e.value;
                        final isDone = i < _msgIndex;
                        final isCurrent = i == _msgIndex;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.5),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 350),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isDone
                                      ? const Color(0xFF00B894)
                                      : isCurrent
                                          ? const Color(0xFFFF5722)
                                          : Colors.white12,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: isDone
                                      ? const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        )
                                      : isCurrent
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Icon(
                                              step['icon'] as IconData,
                                              color: Colors.white38,
                                              size: 14,
                                            ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  step['label'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: isCurrent
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: isDone
                                        ? Colors.white60
                                        : isCurrent
                                            ? Colors.white
                                            : Colors.white38,
                                  ),
                                ),
                              ),
                              if (isDone)
                                const Icon(
                                  Icons.check_rounded,
                                  color: Color(0xFF00B894),
                                  size: 16,
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (_statusText.isNotEmpty)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Container(
                        key: ValueKey(_statusText),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5722).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFF5722).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _statusText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF8A65),
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
