import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
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

  final List<Map<String, dynamic>> _steps = [
    {'label': 'Analysing your profile', 'icon': Icons.person_search_rounded},
    {'label': 'Selecting best resources', 'icon': Icons.library_books_rounded},
    {'label': 'Building week-by-week plan', 'icon': Icons.calendar_month_rounded},
    {'label': 'Personalising for your goals', 'icon': Icons.flag_rounded},
    {'label': 'Finalising your roadmap', 'icon': Icons.check_circle_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _cycleMessages();
    _generateRoadmap();
  }

  @override
  void dispose() { _pulseController.dispose(); super.dispose(); }

  void _cycleMessages() {
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted && _msgIndex < _steps.length - 1) {
        setState(() => _msgIndex++);
        _cycleMessages();
      }
    });
  }

  Future<void> _generateRoadmap() async {
    setState(() => _statusText = 'Connecting to AI...');
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      String branch = 'Engineering', year = '3rd Year',
             experience = 'Intermediate', hours = '8-12 hours',
             goal = 'Get a job';

      if (uid != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users').doc(uid).get();
          final data = doc.data() ?? {};
          branch     = data['branch']     ?? branch;
          year       = data['year']       ?? year;
          experience = data['experience'] ?? experience;
          hours      = data['hours']      ?? hours;
          goal       = data['goal']       ?? goal;
        } catch (_) {}
      }

      final roadmap = await GeminiService.generateRoadmap(
        track: widget.track, branch: branch, year: year,
        experience: experience, hours: hours, goal: goal,
      );

      setState(() => _statusText = 'Saving your roadmap...');

      if (roadmap != null && uid != null) {
        roadmap['track'] = widget.track;
        await FirestoreService.saveRoadmap(uid: uid, roadmap: roadmap);
        setState(() => _statusText = 'Ready!');
      }

      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        context.go('/roadmap?track=${Uri.encodeComponent(widget.track)}');
      }
    } catch (e) {
      setState(() => _statusText = 'Error: $e');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        context.go('/roadmap?track=${Uri.encodeComponent(widget.track)}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie animation — falls back to animated icon if asset missing
              ScaleTransition(
                scale: _pulseAnim,
                child: Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    color: AppTheme.orange.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Lottie.network(
                      'https://assets10.lottiefiles.com/packages/lf20_jcikwtux.json',
                      width: 120, height: 120,
                      errorBuilder: (_, __, ___) => Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          color: AppTheme.orange,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 48),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Text('Building your roadmap',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 22, fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 8),
              Text(widget.track,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: AppTheme.orange)),
              const SizedBox(height: 32),

              // Step list
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: _steps.asMap().entries.map((e) {
                    final i = e.key;
                    final step = e.value;
                    final isDone = i < _msgIndex;
                    final isCurrent = i == _msgIndex;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: isDone
                                ? AppTheme.green
                                : isCurrent
                                    ? AppTheme.orange
                                    : Colors.white12,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isDone
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 14)
                                : isCurrent
                                    ? SizedBox(
                                        width: 14, height: 14,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : Icon(step['icon'] as IconData,
                                        color: Colors.white38, size: 14),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(step['label'] as String,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: isCurrent
                                    ? FontWeight.w700 : FontWeight.w400,
                                color: isDone
                                    ? Colors.white60
                                    : isCurrent
                                        ? Colors.white
                                        : Colors.white38)),
                        if (isDone) ...[
                          const Spacer(),
                          Icon(Icons.check_rounded,
                              color: AppTheme.green, size: 14),
                        ],
                      ]),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              if (_statusText.isNotEmpty)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    key: ValueKey(_statusText),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _statusText.contains('Error')
                          ? Colors.red.withOpacity(0.15)
                          : AppTheme.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _statusText.contains('Error')
                            ? Colors.red.withOpacity(0.4)
                            : AppTheme.orange.withOpacity(0.4),
                      ),
                    ),
                    child: Text(_statusText,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: _statusText.contains('Error')
                                ? Colors.red.shade300 : AppTheme.orange)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
