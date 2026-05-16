import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.mlColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15, spreadRadius: 2,
                        )],
                      ),
                      child: Center(
                        child: Text('S',
                          style: GoogleFonts.poppins(
                            fontSize: 32, fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Sneha Choudhary',
                      style: GoogleFonts.poppins(
                        fontSize: 20, fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Computer Science • 3rd Year',
                      style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.4)),
                      ),
                      child: Text('🎯 Data Science Track',
                        style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Stats row
              Container(
                margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    _StatItem('25%', 'Completed', '📊'),
                    _Divider(),
                    _StatItem('2', 'Weeks Done', '✅'),
                    _Divider(),
                    _StatItem('7', 'Day Streak', '🔥'),
                    _Divider(),
                    _StatItem('14', 'Skills', '⚡'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Progress',
                      style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.light,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Data Science Roadmap',
                                style: GoogleFonts.poppins(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              Text('2/16 weeks',
                                style: GoogleFonts.poppins(
                                  fontSize: 12, color: AppTheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: 0.25,
                              backgroundColor: AppTheme.border,
                              valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Current: Week 3 — Data Wrangling',
                                style: GoogleFonts.poppins(
                                  fontSize: 11, color: AppTheme.textMid),
                              ),
                              Text('25%',
                                style: GoogleFonts.poppins(
                                  fontSize: 11, color: AppTheme.primary,
                                  fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text('Achievements',
                      style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _Badge('🚀', 'Started', 'Joined PathForge'),
                        const SizedBox(width: 10),
                        _Badge('🐍', 'Pythonista', 'Completed Python'),
                        const SizedBox(width: 10),
                        _Badge('🔥', '7 Day\nStreak', 'Keep going!'),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Text('My Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: [
                          _InfoRow('🎓', 'Branch', 'Computer Science'),
                          _InfoRow('📅', 'Year', '3rd Year'),
                          _InfoRow('💻', 'Experience', 'Intermediate'),
                          _InfoRow('⏰', 'Study Time', '8-12 hrs/week'),
                          _InfoRow('🎯', 'Goal', 'Get a job'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text('Settings',
                      style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _SettingsTile('🔄', 'Regenerate Roadmap',
                        'Get a fresh AI roadmap',
                        () => context.go('/track')),
                    _SettingsTile('📊', 'Change Track',
                        'Switch to different career path',
                        () => context.go('/track')),

                    // SIGN OUT — properly clears auth and goes to auth screen
                    GestureDetector(
                      onTap: () async {
                        await AuthService.signOut();
                        if (context.mounted) context.go('/auth');
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Text('🚪', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Sign Out',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13, fontWeight: FontWeight.w500,
                                      color: Colors.red.shade700)),
                                  Text('Log out of PathForge',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11, color: Colors.red.shade400)),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios,
                              size: 14, color: Colors.red.shade400),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(Icons.map_outlined, 'Roadmap', false,
                () => context.go('/roadmap')),
            _NavItem(Icons.play_circle_outline, 'Resources', false,
                () => context.go('/resources')),
            _NavItem(Icons.person_outline, 'Profile', true, () {}),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value, label, emoji;
  const _StatItem(this.value, this.label, this.emoji);
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primary)),
          Text(label, style: GoogleFonts.poppins(
            fontSize: 10, color: AppTheme.textLight)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
    Container(width: 1, height: 40, color: AppTheme.border);
}

class _Badge extends StatelessWidget {
  final String emoji, title, desc;
  const _Badge(this.emoji, this.title, this.desc);
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(title, textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: AppTheme.textDark)),
            Text(desc, textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 9, color: AppTheme.textLight),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _InfoRow(String emoji, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 12),
        Text(label, style: GoogleFonts.poppins(
          fontSize: 13, color: AppTheme.textMid)),
        const Spacer(),
        Text(value, style: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w500,
          color: AppTheme.textDark)),
      ],
    ),
  );
}

Widget _SettingsTile(String emoji, String title, String sub, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: AppTheme.textDark)),
                Text(sub, style: GoogleFonts.poppins(
                  fontSize: 11, color: AppTheme.textLight)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textLight),
        ],
      ),
    ),
  );
}

Widget _NavItem(IconData icon, String label, bool active, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: active ? AppTheme.primary : AppTheme.textLight, size: 24),
        const SizedBox(height: 3),
        Text(label, style: GoogleFonts.poppins(
          fontSize: 10,
          color: active ? AppTheme.primary : AppTheme.textLight,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
        )),
      ],
    ),
  );
}
