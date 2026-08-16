import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool isLoading = false;
  bool isGoogleLoading = false;
  String? errorMessage;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String _selectedCountryCode = '+91';
  final List<String> _countryCodes = [
    '+91',
    '+1',
    '+44',
    '+61',
    '+65',
    '+971',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      if (isPhoneMode) {
        final phone = _phoneController.text.trim();
        final pass = _passwordController.text;

        if (phone.isEmpty || phone.length < 10) {
          setState(() {
            errorMessage = 'Please enter a valid 10-digit mobile number';
            isLoading = false;
          });
          return;
        }

        if (pass.isEmpty || pass.length < 6) {
          setState(() {
            errorMessage = 'Password must be at least 6 characters';
            isLoading = false;
          });
          return;
        }

        final emailPlaceholder =
            '${_selectedCountryCode.replaceAll('+', '')}$phone@pathforge.app';

        if (isLogin) {
          final res = await AuthService.signInWithEmail(emailPlaceholder, pass);
          if (res['error'] != null) {
            setState(() {
              errorMessage = res['error'];
              isLoading = false;
            });
            return;
          }
          await _navigateAfterLogin();
        } else {
          final name = _nameController.text.trim();
          if (name.isEmpty) {
            setState(() {
              errorMessage = 'Please enter your full name';
              isLoading = false;
            });
            return;
          }
          final confirm = _confirmPasswordController.text;
          if (pass != confirm) {
            setState(() {
              errorMessage = 'Passwords do not match';
              isLoading = false;
            });
            return;
          }

          final res = await AuthService.signUpWithEmail(
            name: name,
            email: emailPlaceholder,
            password: pass,
          );
          if (res['error'] != null) {
            setState(() {
              errorMessage = res['error'];
              isLoading = false;
            });
            return;
          }
          if (mounted) context.go('/onboarding');
        }
      } else {
        final email = _emailController.text.trim();
        final pass = _passwordController.text;

        if (email.isEmpty || !email.contains('@')) {
          setState(() {
            errorMessage = 'Please enter a valid email address';
            isLoading = false;
          });
          return;
        }

        if (pass.isEmpty || pass.length < 6) {
          setState(() {
            errorMessage = 'Password must be at least 6 characters';
            isLoading = false;
          });
          return;
        }

        if (isLogin) {
          final res = await AuthService.signInWithEmail(email, pass);
          if (res['error'] != null) {
            setState(() {
              errorMessage = res['error'];
              isLoading = false;
            });
            return;
          }
          await _navigateAfterLogin();
        } else {
          final name = _nameController.text.trim();
          if (name.isEmpty) {
            setState(() {
              errorMessage = 'Please enter your full name';
              isLoading = false;
            });
            return;
          }
          final confirm = _confirmPasswordController.text;
          if (pass != confirm) {
            setState(() {
              errorMessage = 'Passwords do not match';
              isLoading = false;
            });
            return;
          }

          final res = await AuthService.signUpWithEmail(
            name: name,
            email: email,
            password: pass,
          );
          if (res['error'] != null) {
            setState(() {
              errorMessage = res['error'];
              isLoading = false;
            });
            return;
          }
          if (mounted) context.go('/onboarding');
        }
      }
    } catch (e) {
      setState(() => errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      isGoogleLoading = true;
      errorMessage = null;
    });

    final result = await AuthService.signInWithGoogle();

    if (!mounted) return;
    setState(() => isGoogleLoading = false);

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
              // ── Top Navy Section ─────
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  16,
                  topPadding > 0 ? topPadding + 8 : 20,
                  16,
                  14,
                ),
                color: const Color(0xFF111322),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
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
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'PathForge',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Your AI career roadmap',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFFB3B0D6),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Bottom White Card (Properly Proportioned & Zero Scroll) ──
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.68,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Community Badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F5FB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7F2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                _miniAvatar(const Color(0xFF7C5CBF), 'S'),
                                Transform.translate(
                                  offset: const Offset(-4, 0),
                                  child: _miniAvatar(
                                      const Color(0xFFFF5722), 'A'),
                                ),
                                Transform.translate(
                                  offset: const Offset(-8, 0),
                                  child: _miniAvatar(
                                      const Color(0xFF00B894), 'R'),
                                ),
                              ],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Join 50,000+ AI Career Builders 🚀',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1B1D36),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      isLogin ? 'Welcome back' : 'Create account',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      isLogin
                          ? 'Sign in to continue your roadmap'
                          : 'Join PathForge — get your personalized AI roadmap',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF6B6890),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Google Sign-In Button
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: OutlinedButton(
                        onPressed: isGoogleLoading ? null : _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(
                              color: Color(0xFFE2E4F0), width: 1.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                        ),
                        child: isGoogleLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
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
                                    width: 17,
                                    height: 17,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.g_mobiledata_rounded,
                                      color: Color(0xFF4285F4),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Continue with Google',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1B1D36),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Divider
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: Color(0xFFE8E9F2), thickness: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'or',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
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

                    const SizedBox(height: 8),

                    // Tab Selector: Email vs Mobile Phone
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(2.5),
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
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: !isPhoneMode
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.04),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.email_outlined,
                                        size: 13,
                                        color: !isPhoneMode
                                            ? const Color(0xFF1B1D36)
                                            : const Color(0xFF7B7998),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Email',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
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
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: isPhoneMode
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.04),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.phone_iphone_rounded,
                                        size: 13,
                                        color: isPhoneMode
                                            ? const Color(0xFF1B1D36)
                                            : const Color(0xFF7B7998),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Mobile Phone',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
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

                    const SizedBox(height: 10),

                    // Name Field (Sign Up only)
                    if (!isLogin) ...[
                      _buildTextField(
                        controller: _nameController,
                        hint: 'Full Name',
                        icon: Icons.person_outline_rounded,
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 8),
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
                      Row(
                        children: [
                          Container(
                            width: 62,
                            height: 42,
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
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1B1D36),
                                ),
                                items: _countryCodes.map((c) {
                                  return DropdownMenuItem<String>(
                                    value: c,
                                    child: Text(
                                      c,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
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

                    const SizedBox(height: 8),

                    // Password Field
                    _buildTextField(
                      controller: _passwordController,
                      hint: isPhoneMode ? 'Enter Password' : 'Password',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      showPassword: _showPassword,
                      onTogglePassword: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),

                    if (!isLogin) ...[
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 6),
                      Text(
                        errorMessage!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Submit Button (Crisp Centered Typography - 0 Clipping)
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
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

                    const SizedBox(height: 10),

                    // Toggle Login / Sign Up
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
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
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
                                style: const TextStyle(
                                  color: Color(0xFFFF5722),
                                  fontWeight: FontWeight.w800,
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

  Widget _miniAvatar(Color color, String letter) {
    return Container(
      width: 17,
      height: 17,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool showPassword = false,
    VoidCallback? onTogglePassword,
  }) {
    return Container(
      height: 42,
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
          fontSize: 12.5,
          color: const Color(0xFF1B1D36),
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: const Color(0xFF9B99B5),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF9B99B5), size: 16),
          suffixIcon: isPassword
              ? GestureDetector(
                  onTap: onTogglePassword,
                  child: Icon(
                    showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF9B99B5),
                    size: 16,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
        ),
      ),
    );
  }
}
