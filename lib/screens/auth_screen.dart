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
  bool isPhoneMode = false;
  bool isLoading = false;
  bool isGoogleLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  String _selectedCountryCode = '+91';
  String? errorMessage;

  final List<Map<String, String>> _countryCodes = [
    {'code': '+91', 'country': 'India', 'flag': '🇮🇳'},
    {'code': '+1', 'country': 'USA / Canada', 'flag': '🇺🇸'},
    {'code': '+44', 'country': 'UK', 'flag': '🇬🇧'},
    {'code': '+971', 'country': 'UAE', 'flag': '🇦🇪'},
    {'code': '+65', 'country': 'Singapore', 'flag': '🇸🇬'},
    {'code': '+61', 'country': 'Australia', 'flag': '🇦🇺'},
    {'code': '+49', 'country': 'Germany', 'flag': '🇩🇪'},
    {'code': '+33', 'country': 'France', 'flag': '🇫🇷'},
    {'code': '+81', 'country': 'Japan', 'flag': '🇯🇵'},
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => errorMessage = null);

    final pass = _passwordController.text.trim();
    if (pass.isEmpty || pass.length < 6) {
      setState(() => errorMessage = 'Password must be at least 6 characters');
      return;
    }

    if (!isLogin) {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        setState(() => errorMessage = 'Please enter your full name');
        return;
      }
      final confirmPass = _confirmPasswordController.text.trim();
      if (confirmPass.isEmpty) {
        setState(() => errorMessage = 'Please confirm your password');
        return;
      }
      if (pass != confirmPass) {
        setState(() => errorMessage = 'Passwords do not match');
        return;
      }
    }

    String authEmail;
    if (isPhoneMode) {
      final phone = _phoneController.text.trim().replaceAll(RegExp(r'\s+'), '');
      if (phone.isEmpty || phone.length < 7) {
        setState(() => errorMessage = 'Please enter a valid mobile number');
        return;
      }
      final cleanPhone = '$_selectedCountryCode$phone'.replaceAll('+', '');
      authEmail = 'phone_$cleanPhone@pathforge.app';
    } else {
      final email = _emailController.text.trim();
      if (email.isEmpty || !email.contains('@')) {
        setState(() => errorMessage = 'Please enter a valid email address');
        return;
      }
      authEmail = email;
    }

    setState(() => isLoading = true);

    if (isLogin) {
      final error = await AuthService.signIn(
        email: authEmail,
        password: pass,
      );
      setState(() => isLoading = false);
      if (error == null) {
        if (!mounted) return;
        await _navigateAfterLogin();
      } else {
        setState(() => errorMessage = error);
      }
    } else {
      final displayName = _nameController.text.trim();
      final error = await AuthService.signUp(
        email: authEmail,
        password: pass,
        name: displayName,
      );
      setState(() => isLoading = false);
      if (error == null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && isPhoneMode) {
          final fullPhone = '$_selectedCountryCode ${_phoneController.text.trim()}';
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'phone': fullPhone,
            'authMethod': 'phone',
          }, SetOptions(merge: true));
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Navy Header with Glowing Circular Emblem
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
                    // Clean Circular Logo Emblem (Inside the purple/coral circle)
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C5CBF).withOpacity(0.45),
                            blurRadius: 24,
                            spreadRadius: 4,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: const Color(0xFFFF5722).withOpacity(0.25),
                            blurRadius: 18,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF7C5CBF), Color(0xFFFF5722)],
                              ),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 44,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'PathForge',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your AI career roadmap',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        color: const Color(0xFFD4C9FF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Form Container
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Social Proof Pill
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F2F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E4F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '🚀 Join 50,000+ AI Career Builders',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1B1D36),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      isLogin ? 'Welcome back' : 'Create account',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLogin
                          ? 'Sign in to continue your roadmap'
                          : 'Join PathForge — get your personalized AI roadmap',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF6B6890),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Google Sign-In Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: isGoogleLoading ? null : _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(
                              color: Color(0xFFE2E4F0), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isGoogleLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Color(0xFFFF5722),
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
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1A1A2E),
                                  ),
                                ),
                              ],
                            ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Divider
                    Row(
                      children: [
                        const Expanded(
                            child: Divider(color: Color(0xFFE2E4F0))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or continue with',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF9B99B5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Expanded(
                            child: Divider(color: Color(0xFFE2E4F0))),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Email vs Phone Number Segmented Control
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBEBF5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => isPhoneMode = false),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: !isPhoneMode
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: !isPhoneMode
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.06),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.email_outlined,
                                      size: 16,
                                      color: !isPhoneMode
                                          ? const Color(0xFFFF5722)
                                          : const Color(0xFF6B6890),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Email',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: !isPhoneMode
                                            ? const Color(0xFF1A1A2E)
                                            : const Color(0xFF6B6890),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => isPhoneMode = true),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: isPhoneMode
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: isPhoneMode
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.06),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.phone_android_rounded,
                                      size: 16,
                                      color: isPhoneMode
                                          ? const Color(0xFFFF5722)
                                          : const Color(0xFF6B6890),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Mobile Phone',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isPhoneMode
                                            ? const Color(0xFF1A1A2E)
                                            : const Color(0xFF6B6890),
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

                    const SizedBox(height: 18),

                    // Error Box
                    if (errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0ED),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFFD5CC)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFFD63031),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  color: const Color(0xFFD63031),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Full Name (Only for Sign Up)
                    if (!isLogin) ...[
                      _Field(
                        controller: _nameController,
                        hint: 'Full name',
                        icon: Icons.person_outline_rounded,
                        autofillHints: const [AutofillHints.name],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Input Field: Email OR Mobile Phone with Country Code Dropdown
                    if (!isPhoneMode) ...[
                      _Field(
                        controller: _emailController,
                        hint: 'Email address',
                        icon: Icons.email_outlined,
                        type: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          // Country Code Selector Dropdown
                          Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E4F0)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCountryCode,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                    size: 18, color: Color(0xFF6B6890)),
                                items: _countryCodes.map((item) {
                                  return DropdownMenuItem<String>(
                                    value: item['code'],
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(item['flag'] ?? '🇮🇳',
                                            style: const TextStyle(fontSize: 16)),
                                        const SizedBox(width: 6),
                                        Text(
                                          item['code'] ?? '+91',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF1A1A2E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedCountryCode = val);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Phone Number Input
                          Expanded(
                            child: _Field(
                              controller: _phoneController,
                              hint: 'Mobile number (10 digits)',
                              icon: Icons.phone_outlined,
                              type: TextInputType.phone,
                              autofillHints: const [AutofillHints.telephoneNumber],
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Password Field with Visibility Toggle
                    TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFF1A1A2E),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Password (min 6 characters)',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF9B99B5),
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFF9B99B5),
                          size: 20,
                        ),
                        suffixIcon: GestureDetector(
                          onTap: () =>
                              setState(() => _showPassword = !_showPassword),
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
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E4F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E4F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: Color(0xFFFF5722), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),

                    // Confirm Password Field (Only for Sign Up)
                    if (!isLogin) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: !_showConfirmPassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: const Color(0xFF1A1A2E),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Confirm password',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF9B99B5),
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_reset_rounded,
                            color: Color(0xFF9B99B5),
                            size: 20,
                          ),
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() =>
                                _showConfirmPassword = !_showConfirmPassword),
                            child: Icon(
                              _showConfirmPassword
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
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E4F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E4F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: Color(0xFFFF5722), width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isLogin ? 'Sign In' : 'Create Account',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded,
                                      size: 18),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Switch between Sign In and Sign Up
                    Center(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          isLogin = !isLogin;
                          errorMessage = null;
                        }),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
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
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
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
            ],
          ),
        ),
      ),
    );
  }
}

// ── Google Logo Painter ───────────────────────────────────────────
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    paint.color = const Color(0xFFEEEEEE);
    canvas.drawCircle(center, radius, paint);

    // Blue
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 1),
      -0.3,
      1.9,
      true,
      paint,
    );

    // Red
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 1),
      3.14 + 0.3,
      1.5,
      true,
      paint,
    );

    // Yellow
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 1),
      2.1,
      1.1,
      true,
      paint,
    );

    // Green
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 1),
      1.6,
      0.55,
      true,
      paint,
    );

    // White Center
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.55, paint);

    // Blue Bar
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx,
        center.dy - radius * 0.15,
        radius * 0.9,
        radius * 0.3,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Reusable Input Field ──────────────────────────────────────────
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
          fontSize: 13,
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
          borderSide: const BorderSide(color: Color(0xFFFF5722), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
