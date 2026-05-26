import 'package:flutter/material.dart';
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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
    _checkAndNavigate();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _checkAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { context.go('/auth'); return; }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('roadmaps').where('uid', isEqualTo: user.uid).limit(1).get();
      if (!mounted) return;
      if (snap.docs.isNotEmpty) {
        final track = snap.docs.first.data()['track'] ?? '';
        context.go('/roadmap?track=${Uri.encodeComponent(track)}');
      } else {
        context.go('/home');
      }
    } catch (_) { if (mounted) context.go('/home'); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  color: AppTheme.orange,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(Icons.route_rounded,
                    color: Colors.white, size: 50),
              ),
            ),
            const SizedBox(height: 24),
            Text('PathForge', style: GoogleFonts.plusJakartaSans(
                fontSize: 36, fontWeight: FontWeight.w800,
                color: Colors.white, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            Text('Your AI career roadmap',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 15, color: Colors.white54)),
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: i == 0
                      ? AppTheme.orange
                      : AppTheme.orange.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}
