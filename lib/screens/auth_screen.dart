import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
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

    String? error;
    bool isNewUser = false;

    if (isLogin) {
      error = await AuthService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } else {
      if (_nameController.text.trim().isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'Please enter your name';
        });
        return;
      }
      error = await AuthService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
      );
      isNewUser = true;
    }

    setState(() { isLoading = false; });

    if (error == null) {
      if (!mounted) return;
      if (isNewUser) {
        // New user → onboarding quiz
        context.go('/home');
      } else {
        // Existing user → splash will check roadmap and route
        context.go('/home');
      }
    } else {
      setState(() => errorMessage = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 20, spreadRadius: 2,
                  )],
                ),
                child: const Icon(Icons.route_rounded, color: Colors.white, size: 38),
              ),
              const SizedBox(height: 16),
              Text('PathForge',
                style: GoogleFonts.poppins(
                  fontSize: 28, fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              Text('Your AI career roadmap',
                style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textMid),
              ),
              const SizedBox(height: 36),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isLogin ? 'Welcome back 👋' : 'Create account 🚀',
                      style: GoogleFonts.poppins(
                        fontSize: 20, fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(isLogin
                        ? 'Sign in to continue your roadmap'
                        : 'Join PathForge — get your AI roadmap',
                      style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textMid),
                    ),
                    const SizedBox(height: 24),

                    if (errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(errorMessage!,
                          style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.red.shade700),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (!isLogin) ...[
                      _TextField(
                        controller: _nameController,
                        hint: 'Full name',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 10),
                    ],

                    _TextField(
                      controller: _emailController,
                      hint: 'Email address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 10),
                    _TextField(
                      controller: _passwordController,
                      hint: 'Password (min 6 characters)',
                      icon: Icons.lock_outline,
                      obscure: true,
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                              )
                            : Text(isLogin ? 'Sign In' : 'Create Account',
                                style: GoogleFonts.poppins(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => setState(() {
                  isLogin = !isLogin;
                  errorMessage = null;
                }),
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textMid),
                    children: [
                      TextSpan(text: isLogin
                          ? "Don't have an account? "
                          : "Already have an account? "),
                      TextSpan(
                        text: isLogin ? 'Sign Up' : 'Sign In',
                        style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  const _TextField({
    required this.controller, required this.hint,
    required this.icon, this.obscure = false, this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.textLight, size: 20),
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textLight),
        filled: true,
        fillColor: AppTheme.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
