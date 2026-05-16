import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Not logged in → Auth screen
      context.go('/auth');
      return;
    }

    // Logged in → check if they have a roadmap already
    try {
      final doc = await FirebaseFirestore.instance
          .collection('roadmaps')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (doc.exists && doc.data() != null) {
        // Has roadmap → go to roadmap
        context.go('/home');
      } else {
        // No roadmap yet → go to onboarding
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              AppTheme.primary.withOpacity(0.08),
              AppTheme.background,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 30, spreadRadius: 5,
                )],
              ),
              child: const Icon(Icons.route_rounded, color: Colors.white, size: 48),
            )
            .animate()
            .scale(duration: 600.ms, curve: Curves.elasticOut)
            .fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            Text('PathForge',
              style: GoogleFonts.poppins(
                fontSize: 36, fontWeight: FontWeight.w700,
                color: AppTheme.textDark, letterSpacing: -0.5,
              ),
            )
            .animate()
            .fadeIn(delay: 300.ms, duration: 600.ms)
            .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 8),

            Text('Your AI career roadmap',
              style: GoogleFonts.poppins(
                fontSize: 16, color: AppTheme.textMid,
              ),
            )
            .animate()
            .fadeIn(delay: 500.ms, duration: 600.ms),

            const SizedBox(height: 50),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TrackChip('Data Science', AppTheme.dsColor),
                const SizedBox(width: 8),
                _TrackChip('AI / ML', AppTheme.mlColor),
              ],
            ).animate().fadeIn(delay: 700.ms),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TrackChip('Data Engg', AppTheme.deColor),
                const SizedBox(width: 8),
                _TrackChip('Analytics', AppTheme.daColor),
              ],
            ).animate().fadeIn(delay: 900.ms),

            const SizedBox(height: 60),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) =>
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                )
                .animate(onPlay: (c) => c.repeat())
                .scaleXY(
                  begin: 0.5, end: 1.0,
                  delay: Duration(milliseconds: i * 200),
                  duration: 600.ms,
                ),
              ),
            ).animate().fadeIn(delay: 1100.ms),
          ],
        ),
      ),
    );
  }
}

class _TrackChip extends StatelessWidget {
  final String label;
  final Color color;
  const _TrackChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
        style: GoogleFonts.poppins(
          fontSize: 12, fontWeight: FontWeight.w500, color: color,
        ),
      ),
    );
  }
}
