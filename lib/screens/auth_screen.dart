import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  final List<String> _countryCodes = [
    '+91',
    '+1',
    '+44',
    '+971',
    '+65',
    '+61',
    '+49',
    '+33',
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
    if (pass.isEmpty) {
      setState(() => errorMessage =
          isPhoneMode ? 'Please enter OTP / Password' : 'Password is required');
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
      final phone =
          _phoneController.text.trim().replaceAll(RegExp(r'\s+'), '');
      if (phone.isEmpty || phone.length < 8) {
        setState(
            () => errorMessage = 'Please enter a valid 10-digit mobile number');
        return;
      }
      final cleanDigits = '$_selectedCountryCode$phone'.replaceAll('+', '');
      authEmail = 'phone_$cleanDigits@pathforge.app';
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
          final fullPhone =
              '$_selectedCountryCode ${_phoneController.text.trim()}';
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
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
    if (uid == null) {
      context.go('/home');
      return;
    }
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!userDoc.exists || userDoc.data()?['track'] == null) {
        context.go('/track-select');
        return;
      }
      final rSnap = await FirebaseFirestore.instance
          .collection('roadmaps')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (rSnap.docs.isEmpty) {
        context.go('/track-select');
      } else {
        context.go('/home');
      }
    } catch (_) {
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF111322),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Top Navy Section (Ultra-Compact Header) ─────
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  16,
                  topPadding > 0 ? topPadding + 4 : 16,
                  16,
                  8,
                ),
                color: const Color(0xFF111322),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF7C5CBF).withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PathForge',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Your AI career roadmap',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: const Color(0xFFB3B0D6),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Bottom White Card (Conserved to 1 Screen) ──
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Community Badge
                    Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F5FB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5E7F2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  _miniAvatar(const Color(0xFF7C5CBF), 'S'),
                                  Transform.translate(
                                    offset: const Offset(-3, 0),
                                    child: _miniAvatar(
                                        const Color(0xFFFF5722), 'A'),
                                  ),
                                  Transform.translate(
                                    offset: const Offset(-6, 0),
                                    child: _miniAvatar(
                                        const Color(0xFF00B894), 'R'),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Join 50,000+ AI Career Builders 🚀',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1B1D36),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      isLogin ? 'Welcome back' : 'Create account',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      isLogin
                          ? 'Sign in to continue your roadmap'
                          : 'Join PathForge — get your personalized AI roadmap',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: const Color(0xFF6B6890),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Google Sign-In Button
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: OutlinedButton(
                        onPressed: isGoogleLoading ? null : _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(
                              color: Color(0xFFE2E4F0), width: 1.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                        ),
                        child: isGoogleLoading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFF5722),
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(
                                    'https://cdn1.iconfinder.com/data/icons/google-s-logo/150/Google_Icons-09-512.png',
                                    width: 15,
                                    height: 15,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.g_mobiledata_rounded,
                                      color: Color(0xFF4285F4),
                                      size: 17,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Continue with Google',
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

                    const SizedBox(height: 6),

                    // Divider
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: Color(0xFFE8E9F2), thickness: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            'or',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              color: const Color(0xFF9B99B5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: Color(0xFFE8E9F2), thickness: 1),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Tab Selector: Email vs Mobile Phone
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(2.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                isPhoneMode = false;
                                errorMessage = null;
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: !isPhoneMode
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.email_outlined,
                                        size: 11,
                                        color: !isPhoneMode
                                            ? const Color(0xFF1B1D36)
                                            : const Color(0xFF7B7998),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Email',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: !isPhoneMode
                                            ? const Color(0xFF1B1D36)
                                            : const Color(0xFF7B7998),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                isPhoneMode = true;
                                errorMessage = null;
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isPhoneMode
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.phone_android_rounded,
                                        size: 11,
                                        color: isPhoneMode
                                            ? const Color(0xFF1B1D36)
                                            : const Color(0xFF7B7998),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Mobile Phone',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: isPhoneMode
                                            ? const Color(0xFF1B1D36)
                                            : const Color(0xFF7B7998),
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

                    const SizedBox(height: 6),

                    // Full Name Field (Sign Up only)
                    if (!isLogin) ...[
                      _buildTextField(
                        controller: _nameController,
                        hint: 'Full Name',
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 5),
                    ],

                    // Email or Phone Input
                    if (!isPhoneMode) ...[
                      _buildTextField(
                        controller: _emailController,
                        hint: 'e.g. alex@example.com',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ] else ...[
                      // FIXED SPACING: Country code is small (60px), Contact number gets ~85% width!
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFFE2E4F0), width: 1.0),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCountryCode,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down_rounded,
                                    size: 16, color: Color(0xFF6B6890)),
                                dropdownColor: Colors.white,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1B1D36),
                                ),
                                items: _countryCodes.map((c) {
                                  return DropdownMenuItem<String>(
                                    value: c,
                                    child: Text(
                                      c,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1B1D36),
                                      ),
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
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildTextField(
                              controller: _phoneController,
                              hint: 'Enter 10-digit mobile number',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 5),

                    // Password Field
                    _buildTextField(
                      controller: _passwordController,
                      hint: isPhoneMode ? 'Enter OTP / Password' : 'Password',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      showPassword: _showPassword,
                      onTogglePassword: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),

                    if (!isLogin) ...[
                      const SizedBox(height: 5),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        hint: 'Confirm Password',
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        showPassword: _showConfirmPassword,
                        onTogglePassword: () => setState(() =>
                            _showConfirmPassword = !_showConfirmPassword),
                      ),
                    ],

                    if (errorMessage != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        errorMessage!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
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
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_rounded,
                                      size: 13),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Toggle Sign In vs Sign Up
                    Center(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          isLogin = !isLogin;
                          errorMessage = null;
                        }),
                        child: RichText(
                          text: TextSpan(
                            text: isLogin
                                ? "Don't have an account? "
                                : "Already have an account? ",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: const Color(0xFF6B6890),
                            ),
                            children: [
                              TextSpan(
                                text: isLogin ? 'Sign Up' : 'Sign In',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool showPassword = false,
    VoidCallback? onTogglePassword,
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E4F0), width: 1.0),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !showPassword,
        keyboardType: keyboardType,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1B1D36),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: const Color(0xFF9B99B5),
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF9B99B5), size: 14),
          suffixIcon: isPassword
              ? GestureDetector(
                  onTap: onTogglePassword,
                  child: Icon(
                    showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF9B99B5),
                    size: 14,
                  ),
                )
              : null,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _miniAvatar(Color color, String letter) {
    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.0),
      ),
      child: Center(
        child: Text(
          letter,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 7.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
