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
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

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
    setState(() {
      isGoogleLoading = true;
      errorMessage = null;
    });
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
          .limit(1)
          .get();
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

  Widget _buildAvatarStack() {
    final colors = [
      const Color(0xFF6C5CE7),
      const Color(0xFFFF7675),
      const Color(0xFF00B894),
      const Color(0xFFFFA502),
    ];
    final letters = ['S', 'A', 'R', 'P'];
    return SizedBox(
      width: 62,
      height: 24,
      child: Stack(
        children: List.generate(4, (i) {
          return Positioned(
            left: i * 13.0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors[i],
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  letters[i],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111322),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              color: const Color(0xFFF8F9FE),
              child: SingleChildScrollView(
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
                        20,
                        MediaQuery.of(context).padding.top + 28,
                        20,
                        32,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
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
                                  color: const Color(0xFF7C5CBF).withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(3.5),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              padding: const EdgeInsets.all(10),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Image.asset(
                                    'assets/logo.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.trending_up_rounded,
                                      size: 42,
                                      color: Color(0xFF7C5CBF),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'PathForge',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your AI career roadmap',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFB3B0D6),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: const Color(0xFF7C5CBF).withOpacity(0.18),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF7C5CBF).withOpacity(0.06),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildAvatarStack(),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Join 50,000+ AI Career Builders 🚀',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF2D1B69),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            Text(
                              isLogin ? 'Welcome back' : 'Create account',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF111322),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isLogin
                                  ? 'Sign in to continue your roadmap'
                                  : 'Join PathForge — get your AI roadmap',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                color: const Color(0xFF6B6890),
                              ),
                            ),
                            const SizedBox(height: 22),

                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                onPressed: isGoogleLoading ? null : _signInWithGoogle,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Color(0xFFE2E4F0),
                                    width: 1.2,
                                  ),
                                  elevation: 1,
                                  shadowColor: Colors.black.withOpacity(0.04),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: isGoogleLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF7C5CBF),
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CustomPaint(
                                              painter: _GoogleLogoPainter(),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            isLogin
                                                ? 'Continue with Google'
                                                : 'Sign up with Google',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF1A1A2E),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            Row(
                              children: [
                                const Expanded(
                                  child: Divider(color: Color(0xFFE2E4F0), height: 1),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: Text(
                                    'or',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: const Color(0xFF9B99B5),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  child: Divider(color: Color(0xFFE2E4F0), height: 1),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            if (errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF0F0),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFFFCDD2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: Color(0xFFD32F2F),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        errorMessage!,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          color: const Color(0xFFC62828),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
                              icon: Icons.mail_outline_rounded,
                              type: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                            ),
                            const SizedBox(height: 12),

                            TextField(
                              controller: _passwordController,
                              obscureText: !_showPassword,
                              autocorrect: false,
                              enableSuggestions: false,
                              autofillHints: isLogin
                                  ? const [AutofillHints.password]
                                  : const [AutofillHints.newPassword],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: const Color(0xFF1A1A2E),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Password (min 6 characters)',
                                hintStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  color: const Color(0xFF9B99B5),
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: Color(0xFF9B99B5),
                                  size: 20,
                                ),
                                suffixIcon: GestureDetector(
                                  onTap: () => setState(
                                    () => _showPassword = !_showPassword,
                                  ),
                                  child: Icon(
                                    _showPassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: const Color(0xFF9B99B5),
                                    size: 20,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E4F0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E4F0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFFF5722),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF5722),
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shadowColor:
                                      const Color(0xFFFF5722).withOpacity(0.35),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            isLogin ? 'Sign In' : 'Create Account',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            Center(
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  isLogin = !isLogin;
                                  errorMessage = null;
                                }),
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      color: const Color(0xFF6B6890),
                                    ),
                                    children: [
                                      TextSpan(
                                        text: isLogin
                                            ? "Don't have an account? "
                                            : "Already have an account? ",
                                      ),
                                      TextSpan(
                                        text: isLogin ? 'Sign Up' : 'Sign In',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFFF5722),
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    paint.color = const Color(0xFFEEEEEE);
    canvas.drawCircle(center, radius, paint);

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 1), -0.3, 1.9, true, paint);

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 1), 3.14 + 0.3, 1.5, true, paint);

    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 1), 2.1, 1.1, true, paint);

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 1), 1.6, 0.55, true, paint);

    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.55, paint);

    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(Rect.fromLTWH(center.dx, center.dy - radius * 0.15, radius * 0.9, radius * 0.3), paint);
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
        fontSize: 14,
        color: const Color(0xFF1A1A2E),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13.5,
          color: const Color(0xFF9B99B5),
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF9B99B5), size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E4F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E4F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFFF5722),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
