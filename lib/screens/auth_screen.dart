import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isLoading = false;
  bool isGoogleLoading = false;
  bool _showPassword = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  String? errorMessage;

  Future<void> _submit() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() => errorMessage = 'Please fill all fields');
      return;
    }
    setState(() { isLoading = true; errorMessage = null; });

    if (isLogin) {
      final error = await AuthService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      setState(() => isLoading = false);
      if (error == null) {
        if (!mounted) return;
        await _navigateAfterLogin();
      } else {
        setState(() => errorMessage = error);
      }
    } else {
      if (_nameController.text.trim().isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'Please enter your name';
        });
        return;
      }
      final error = await AuthService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
      );
      setState(() => isLoading = false);
      if (error == null) {
        if (mounted) context.go('/onboarding');
      } else {
        setState(() => errorMessage = error);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { isGoogleLoading = true; errorMessage = null; });
    final result = await AuthService.signInWithGoogle();
    setState(() => isGoogleLoading = false);

    if (!mounted) return;

    if (result['error'] != null) {
      setState(() => errorMessage = result['error']);
      return;
    }

    if (result['isNewUser'] == true) {
      context.go('/onboarding');
    } else {
      await _navigateAfterLogin();
    }
  }

  Future<void> _navigateAfterLogin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('roadmaps')
          .where('uid', isEqualTo: uid)
          .limit(1).get();
      if (!mounted) return;
      if (snap.docs.isNotEmpty) {
        final track = snap.docs.first.data()['track'] ?? '';
        context.go('/roadmap?track=${Uri.encodeComponent(track)}');
      } else {
        context.go('/home');
      }
    } catch (_) {
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Navy top band
              Container(
                color: AppTheme.navy,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
                child: Column(
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.orange,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.route_rounded,
                          color: Colors.white, size: 38),
                    ),
                    const SizedBox(height: 14),
                    Text('PathForge',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 28, fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Your AI career roadmap',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, color: Colors.white54)),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isLogin ? 'Welcome back' : 'Create account',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 22, fontWeight: FontWeight.w800,
                              color: AppTheme.textDark)),
                      const SizedBox(height: 4),
                      Text(
                        isLogin
                            ? 'Sign in to continue your roadmap'
                            : 'Join PathForge — get your AI roadmap',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, color: AppTheme.textMid),
                      ),
                      const SizedBox(height: 24),

                      // Google Sign-In button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: isGoogleLoading ? null : _signInWithGoogle,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(color: AppTheme.border, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: isGoogleLoading
                              ? SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      color: AppTheme.primary, strokeWidth: 2))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Google G logo using coloured squares
                                    SizedBox(
                                      width: 20, height: 20,
                                      child: CustomPaint(
                                          painter: _GoogleLogoPainter()),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      isLogin
                                          ? 'Continue with Google'
                                          : 'Sign up with Google',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textDark),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Divider
                      Row(children: [
                        Expanded(child: Divider(color: AppTheme.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12, color: AppTheme.textLight)),
                        ),
                        Expanded(child: Divider(color: AppTheme.border)),
                      ]),

                      const SizedBox(height: 16),

                      if (errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(children: [
                            Icon(Icons.error_outline_rounded,
                                color: Colors.red.shade600, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(errorMessage!,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.red.shade700))),
                          ]),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (!isLogin) ...[
                        _Field(
                          controller: _nameController,
                          hint: 'Full name',
                          icon: Icons.person_outline_rounded,
                          autofillHints: const [AutofillHints.name],
                        ),
                        const SizedBox(height: 12),
                      ],

                      _Field(
                        controller: _emailController,
                        hint: 'Email address',
                        icon: Icons.email_outlined,
                        type: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                      ),
                      const SizedBox(height: 12),
                      // Password field with show/hide toggle
                      TextField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: isLogin
                            ? const [AutofillHints.password]
                            : const [AutofillHints.newPassword],
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, color: AppTheme.textDark),
                        decoration: InputDecoration(
                          hintText: 'Password (min 6 characters)',
                          hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 13, color: AppTheme.textLight),
                          prefixIcon: Icon(Icons.lock_outline_rounded,
                              color: AppTheme.textLight, size: 20),
                          suffixIcon: GestureDetector(
                            onTap: () => setState(
                                () => _showPassword = !_showPassword),
                            child: Icon(
                              _showPassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: AppTheme.textLight, size: 20,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  BorderSide(color: AppTheme.border)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  BorderSide(color: AppTheme.border)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                  color: AppTheme.orange, width: 2)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.navy,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text(
                                  isLogin ? 'Sign In' : 'Create Account',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Center(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            isLogin = !isLogin;
                            errorMessage = null;
                          }),
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13, color: AppTheme.textMid),
                              children: [
                                TextSpan(
                                    text: isLogin
                                        ? "Don't have an account? "
                                        : "Already have an account? "),
                                TextSpan(
                                  text: isLogin ? 'Sign Up' : 'Sign In',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.orange),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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

// Google G logo painter
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw circle outline
    paint.color = const Color(0xFFEEEEEE);
    canvas.drawCircle(center, radius, paint);

    // Blue arc (top right)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 1),
      -0.3, 1.9, true, paint,
    );

    // Red arc (top left)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 1),
      3.14 + 0.3, 1.5, true, paint,
    );

    // Yellow arc (bottom)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 1),
      2.1, 1.1, true, paint,
    );

    // Green arc
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 1),
      1.6, 0.55, true, paint,
    );

    // White center
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.55, paint);

    // Blue right bar of G
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(center.dx, center.dy - radius * 0.15,
          radius * 0.9, radius * 0.3),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? type;
  final Iterable<String> autofillHints;

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.type,
    this.autofillHints = const [],
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      autocorrect: false,
      enableSuggestions: !obscure,
      autofillHints: autofillHints,
      style: GoogleFonts.plusJakartaSans(
          fontSize: 14, color: AppTheme.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13, color: AppTheme.textLight),
        prefixIcon: Icon(icon, color: AppTheme.textLight, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppTheme.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppTheme.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppTheme.orange, width: 2)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
      ),
    );
  }
}
