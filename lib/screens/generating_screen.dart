import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme.dart';
import '../services/gemini_service.dart';
import '../services/firestore_service.dart';

class GeneratingScreen extends StatefulWidget {
  final String track;
  const GeneratingScreen({super.key, required this.track});
  @override
  State<GeneratingScreen> createState() => _GeneratingScreenState();
}

class _GeneratingScreenState extends State<GeneratingScreen> {
  int _msgIndex = 0;
  bool _isDone = false;
  String _statusText = '';

  final List<String> _messages = [
    'Analysing your profile...',
    'Selecting best resources...',
    'Building your week-by-week plan...',
    'Adding YouTube channels...',
    'Finalising your roadmap...',
  ];

  @override
  void initState() {
    super.initState();
    _cycleMessages();
    _generateRoadmap();
  }

  void _cycleMessages() {
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && _msgIndex < _messages.length - 1) {
        setState(() => _msgIndex++);
        _cycleMessages();
      }
    });
  }

  Future<void> _generateRoadmap() async {
    setState(() => _statusText = 'Calling Gemini AI...');

    try {
      final roadmap = await GeminiService.generateRoadmap(
        track: widget.track,
        branch: 'Engineering',
        year: '3rd Year',
        experience: 'Intermediate',
        hours: '8-12 hours',
        goal: 'Get a job',
      );

      setState(() => _statusText = 'Roadmap generated! Saving...');

      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (roadmap != null && uid != null) {
        roadmap['track'] = widget.track;
        await FirestoreService.saveRoadmap(uid: uid, roadmap: roadmap);
        setState(() => _statusText = 'Saved successfully!');
      } else {
        setState(() => _statusText = 'Error: roadmap=$roadmap, uid=$uid');
      }

      // Wait 1 second so user sees completion
      await Future.delayed(const Duration(seconds: 1));

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
      backgroundColor: AppTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 40, spreadRadius: 8,
                  )],
                ),
                child: const Icon(Icons.route_rounded,
                    color: Colors.white, size: 52),
              )
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(begin: 1.0, end: 1.08,
                  duration: 800.ms, curve: Curves.easeInOut)
              .then()
              .scaleXY(begin: 1.08, end: 1.0,
                  duration: 800.ms, curve: Curves.easeInOut),

              const SizedBox(height: 40),

              Text('Building your roadmap',
                style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),

              const SizedBox(height: 8),

              Text(widget.track,
                style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),

              const SizedBox(height: 12),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _messages[_msgIndex],
                  key: ValueKey(_msgIndex),
                  style: GoogleFonts.poppins(
                    fontSize: 14, color: AppTheme.textMid,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              // Status text for debugging
              if (_statusText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _statusText.contains('Error')
                        ? Colors.red.shade50
                        : AppTheme.light,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _statusText.contains('Error')
                          ? Colors.red.shade200
                          : AppTheme.border,
                    ),
                  ),
                  child: Text(_statusText,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _statusText.contains('Error')
                          ? Colors.red.shade700
                          : AppTheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) =>
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: i <= _msgIndex ? 10 : 8,
                    height: i <= _msgIndex ? 10 : 8,
                    decoration: BoxDecoration(
                      color: i <= _msgIndex
                          ? AppTheme.primary
                          : AppTheme.border,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: List.generate(_messages.length, (i) =>
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            width: 20, height: 20,
                            decoration: BoxDecoration(
                              color: i < _msgIndex
                                  ? AppTheme.primary
                                  : i == _msgIndex
                                      ? AppTheme.light
                                      : AppTheme.border.withOpacity(0.3),
                              shape: BoxShape.circle,
                              border: i == _msgIndex
                                  ? Border.all(color: AppTheme.primary, width: 2)
                                  : null,
                            ),
                            child: i < _msgIndex
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 12)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Text(_messages[i],
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: i <= _msgIndex
                                  ? AppTheme.textDark
                                  : AppTheme.textLight,
                              fontWeight: i == _msgIndex
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
