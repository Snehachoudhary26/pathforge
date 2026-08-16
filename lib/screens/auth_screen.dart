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
  String _selectedCountryName = 'India (+91)';
  String? errorMessage;

  final List<Map<String, String>> _countryCodes = [
    {'code': '+91', 'label': 'India (+91)'},
    {'code': '+1', 'label': 'USA / Canada (+1)'},
    {'code': '+44', 'label': 'UK (+44)'},
    {'code': '+971', 'label': 'UAE (+971)'},
    {'code': '+65', 'label': 'Singapore (+65)'},
    {'code': '+61', 'label': 'Australia (+61)'},
    {'code': '+49', 'label': 'Germany (+49)'},
    {'code': '+33', 'label': 'France (+33)'},
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Top Navy Section ──────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                20,
                topPadding > 0 ? topPadding + 14 : 32,
                20,
                20,
              ),
              color: const Color(0xFF111322),
              child: Column(
                children: [
                  // Circular Logo Emblem
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF7C5CBF).withOpacity(0.5),
                        width: 2,
                      ),
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
                            size: 38,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'PathForge',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your AI career roadmap',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: const Color(0xFFB3B0D6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom White Card ─────────────────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Community Proof Badge (100% Overflow-Free)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F5FB),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE5E7F2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              _miniAvatar(const Color(0xFF7C5CBF), 'S'),
                              Transform.translate(
                                offset: const Offset(-5, 0),
                                child: _miniAvatar(
                                    const Color(0xFFFF5722), 'A'),
                              ),
                              Transform.translate(
                                offset: const Offset(-10, 0),
                                child: _miniAvatar(
                                    const Color(0xFF00B894), 'R'),
                              ),
                            ],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Join 50,000+ AI Career Builders 🚀',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1B1D36),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    isLogin ? 'Welcome back' : 'Create account',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isLogin
                        ? 'Sign in to continue your roadmap'
                        : 'Join PathForge — get your personalized AI roadmap',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF6B6890),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Google Sign-In Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: isGoogleLoading ? null : _signInWithGoogle,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(
                            color: Color(0xFFE2E4F0), width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: isGoogleLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
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
                                  width: 20,
                                  height: 20,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.g_mobiledata_rounded,
                                    color: Color(0xFF4285F4),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Continue with Google',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1B1D36),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Divider
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(color: Color(0xFFE8E9F2), thickness: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
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

                  const SizedBox(height: 16),

                  // Tab Selector: Email vs Mobile Phone
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(3),
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
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !isPhoneMode
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.email_outlined,
                                      size: 15,
                                      color: !isPhoneMode
                                          ? const Color(0xFF1B1D36)
                                          : const Color(0xFF7B7998),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Email',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
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
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isPhoneMode
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.phone_android_rounded,
                                      size: 15,
                                      color: isPhoneMode
                                          ? const Color(0xFF1B1D36)
                                          : const Color(0xFF7B7998),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Mobile Phone',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
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

                  const SizedBox(height: 16),

                  // Full Name Field (Sign Up only)
                  if (!isLogin) ...[
                    _buildTextField(
                      controller: _nameController,
                      hint: 'Full Name',
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 12),
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
                    // Country Code Dropdown + Mobile Number
                    Row(
                      children: [
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFFE2E4F0), width: 1.2),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCountryCode,
                              dropdownColor: Colors.white,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1B1D36),
                              ),
                              items: _countryCodes.map((c) {
                                return DropdownMenuItem<String>(
                                  value: c['code'],
                                  child: Text(c['label'] ?? ''),
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
                        Expanded(
                          child: _buildTextField(
                            controller: _phoneController,
                            hint: 'e.g. 9876543210',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Password Field
                  _buildTextField(
                    controller: _passwordController,
                    hint: isPhoneMode
                        ? 'Enter OTP / Password'
                        : 'Password (min 6 characters)',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    showPassword: _showPassword,
                    onTogglePassword: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),

                  // Confirm Password Field (Sign Up only)
                  if (!isLogin) ...[
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      hint: 'Confirm Password',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      showPassword: _showConfirmPassword,
                      onTogglePassword: () => setState(
                          () => _showConfirmPassword = !_showConfirmPassword),
                    ),
                  ],

                  if (errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECE5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFFF5722).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Color(0xFFFF5722), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: const Color(0xFFFF5722),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
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
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Toggle Sign In / Sign Up
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isLogin = !isLogin;
                          errorMessage = null;
                        });
                      },
                      child: RichText(
                        text: TextSpan(
                          text: isLogin
                              ? "Don't have an account? "
                              : 'Already have an account? ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: const Color(0xFF6B6890),
                          ),
                          children: [
                            TextSpan(
                              text: isLogin ? 'Sign Up' : 'Sign In',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool showPassword = false,
    VoidCallback? onTogglePassword,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E4F0), width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9B99B5), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword && !showPassword,
              keyboardType: keyboardType,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF1B1D36),
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: const Color(0xFFA0A2BD),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (isPassword)
            GestureDetector(
              onTap: onTogglePassword,
              child: Icon(
                showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF9B99B5),
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  Widget _miniAvatar(Color bg, String text) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
