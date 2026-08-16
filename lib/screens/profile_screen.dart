import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  Map<String, dynamic>? roadmapData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => isLoading = false);
      return;
    }
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final roadmapSnap = await FirebaseFirestore.instance
          .collection('roadmaps')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (mounted) {
        setState(() {
          userData = userDoc.data();
          roadmapData = roadmapSnap.docs.isNotEmpty
              ? roadmapSnap.docs.first.data()
              : null;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String get _name =>
      userData?['name'] ??
      FirebaseAuth.instance.currentUser?.email?.split('@')[0] ??
      'Student';

  String get _initial =>
      _name.isNotEmpty ? _name[0].toUpperCase() : 'S';

  // ── Photo Picker Modal (Triggered by clicking on Avatar or Camera icon) ──
  void _openPhotoPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _PhotoPickerSheet(
        currentPhotoUrl: userData?['photoUrl'],
        onPhotoSelected: (photoUrl) async {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid == null) return;

          setState(() {
            userData = {...?userData, 'photoUrl': photoUrl};
          });

          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'photoUrl': photoUrl,
          }, SetOptions(merge: true));

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  photoUrl.isEmpty
                      ? 'Profile photo removed'
                      : 'Profile photo updated successfully!',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: const Color(0xFF00B894),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        },
      ),
    );
  }

  // ── Text Details Edit Sheet (Triggered ONLY by the top-right Edit button) ──
  void _openEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        userData: userData ?? {},
        onSaved: (updated) async {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid == null) return;
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .set(updated, SetOptions(merge: true));
          if (mounted) {
            setState(() => userData = {...?userData, ...updated});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Profile updated!',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: const Color(0xFF00B894),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildAvatarWidget(double size) {
    final photoUrl = userData?['photoUrl'] as String?;

    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('data:image')) {
        try {
          final base64Str = photoUrl.split(',').last;
          final bytes = base64Decode(base64Str);
          return Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildInitialAvatar(size),
          );
        } catch (_) {
          return _buildInitialAvatar(size);
        }
      } else if (photoUrl.startsWith('http')) {
        return Image.network(
          photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialAvatar(size),
        );
      } else if (photoUrl.startsWith('assets/')) {
        return Image.asset(
          photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialAvatar(size),
        );
      }
    }

    return _buildInitialAvatar(size);
  }

  Widget _buildInitialAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFFF5722), Color(0xFF7C5CBF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          _initial,
          style: GoogleFonts.plusJakartaSans(
            fontSize: size * 0.44,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF111322),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF5722)),
        ),
      );
    }

    final track = roadmapData?['track'] ?? 'Data Scientist';
    final weeks = roadmapData?['weeks'] as List? ?? [];
    final doneWeeks =
        weeks.where((w) => w['status'] == 'done').length;
    final totalWeeks = weeks.isEmpty ? 12 : weeks.length;
    final progress = totalWeeks > 0 ? doneWeeks / totalWeeks : 0.0;
    final xp = (userData?['xp'] ?? 0) as int;
    final level = (userData?['level'] ?? 1) as int;
    final levelName = userData?['levelName'] ?? 'Code Newcomer';
    final streak = (userData?['streak'] ?? 1) as int;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Deep Navy Top Header
              Container(
                color: const Color(0xFF111322),
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + 14,
                  20,
                  24,
                ),
                child: Column(
                  children: [
                    // Top App Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => context.go('/home'),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                        Text(
                          'Profile',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: _openEditSheet,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5722).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFFF5722).withOpacity(0.5),
                              ),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Color(0xFFFF5722),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Interactive Profile Avatar with Photo Picker
                    GestureDetector(
                      onTap: _openPhotoPickerSheet,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF5722), Color(0xFF7C5CBF)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF5722).withOpacity(0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(3),
                            child: ClipOval(
                              child: _buildAvatarWidget(80),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5722),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF111322),
                                  width: 2.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // User Name & Subtitle
                    Text(
                      _name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${userData?['branch'] ?? 'Other'} · ${userData?['year'] ?? 'Graduated'}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: const Color(0xFFB3B0D6),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Level & Track Badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5722).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFF5722).withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFF5722),
                                size: 14,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Level $level · $levelName',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFFF5722),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C5CBF).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF7C5CBF).withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            track,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFD6C8F5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Stats Row Card
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE8E9F2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _StatItem(
                      '$xp',
                      'Total XP',
                      Icons.bolt_rounded,
                      const Color(0xFFE08D00),
                      const Color(0xFFFFF9E6),
                    ),
                    _Div(),
                    _StatItem(
                      '$doneWeeks',
                      'Weeks done',
                      Icons.check_circle_rounded,
                      const Color(0xFF00B894),
                      const Color(0xFFE6F8F4),
                    ),
                    _Div(),
                    _StatItem(
                      '$streak',
                      'Day streak',
                      Icons.local_fire_department_rounded,
                      const Color(0xFFFF5722),
                      const Color(0xFFFFECE5),
                    ),
                    _Div(),
                    _StatItem(
                      'Lv.$level',
                      'Level',
                      Icons.star_rounded,
                      const Color(0xFF7C5CBF),
                      const Color(0xFFF3F0FA),
                    ),
                  ],
                ),
              ),

              // Body Content
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Job Readiness Score Card
                    GestureDetector(
                      onTap: () => context.go('/job-readiness'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B1D36),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF5722),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '0',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Job Readiness Score',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'See your full score breakdown',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: const Color(0xFF9B99B5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5722),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'View',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // XP Progress Card
                    _SectionTitle('XP Progress'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1D36),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                levelName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '$xp / 500 XP',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFFF5722),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: ((xp % 500) / 500).clamp(0.0, 1.0),
                              backgroundColor: Colors.white12,
                              valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFFFF5722)),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${500 - (xp % 500)} XP to Level 2',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF9B99B5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Current Progress Card
                    _SectionTitle('Current progress'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE8E9F2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                track,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1A1A2E),
                                ),
                              ),
                              Text(
                                '$doneWeeks/$totalWeeks weeks',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFFF5722),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: const Color(0xFFF0EDF8),
                              valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFFFF5722)),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(progress * 100).toInt()}% complete',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: const Color(0xFF6B6890),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go(
                                    '/roadmap?track=${Uri.encodeComponent(track)}'),
                                child: Text(
                                  'View Roadmap →',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFFF5722),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Achievements Row
                    _SectionTitle('Achievements'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _Badge(
                            Icons.rocket_launch_rounded,
                            'Started',
                            'Joined PathForge',
                            const Color(0xFFFF5722),
                            const Color(0xFFFFECE5),
                            true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _Badge(
                            Icons.code_rounded,
                            'Coder',
                            'Completed Week 1',
                            const Color(0xFF7C5CBF),
                            const Color(0xFFF3F0FA),
                            doneWeeks >= 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _Badge(
                            Icons.local_fire_department_rounded,
                            '7–Day Streak',
                            'Keeps going!',
                            const Color(0xFFE08D00),
                            const Color(0xFFFFF9E6),
                            streak >= 7,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // My Profile Details Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SectionTitle('My profile'),
                        GestureDetector(
                          onTap: _openEditSheet,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.edit_rounded,
                                size: 13,
                                color: Color(0xFFFF5722),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Edit',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFFF5722),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE8E9F2)),
                      ),
                      child: Column(
                        children: [
                          _InfoRow(
                            Icons.school_rounded,
                            'Branch',
                            userData?['branch'] ?? 'Other',
                          ),
                          _InfoRow(
                            Icons.calendar_today_rounded,
                            'Year',
                            userData?['year'] ?? 'Graduated',
                          ),
                          _InfoRow(
                            Icons.laptop_mac_rounded,
                            'Experience',
                            userData?['experience'] ?? 'Advanced',
                          ),
                          _InfoRow(
                            Icons.access_time_rounded,
                            'Study hours',
                            userData?['hours'] ?? '12+ hours',
                          ),
                          _InfoRow(
                            Icons.flag_rounded,
                            'Main goal',
                            userData?['goal'] ?? 'Research & PhD',
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Settings & Account
                    _SectionTitle('Settings & Account'),
                    const SizedBox(height: 8),
                    _SettingTile(
                      Icons.swap_horiz_rounded,
                      'Change Career Track',
                      'Explore or regenerate your learning path',
                      const Color(0xFF7C5CBF),
                      const Color(0xFFF3F0FA),
                      () => context.go('/track'),
                    ),
                    const SizedBox(height: 8),
                    _SettingTile(
                      Icons.delete_sweep_rounded,
                      'Reset Mentor Chat History',
                      'Clear conversation context with AI Mentor',
                      const Color(0xFFFF5722),
                      const Color(0xFFFFECE5),
                      () async {
                        final uid = FirebaseAuth.instance.currentUser?.uid;
                        if (uid != null) {
                          await FirebaseFirestore.instance
                              .collection('mentor_chats')
                              .doc(uid)
                              .delete();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Mentor chat history cleared!',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: const Color(0xFF00B894),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    _SettingTile(
                      Icons.logout_rounded,
                      'Sign Out',
                      'Log out of your PathForge account',
                      Colors.red.shade600,
                      Colors.red.shade50,
                      () async {
                        await AuthService.signOut();
                        if (context.mounted) context.go('/auth');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE8E9F2))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home', false,
                () => context.go('/home')),
            _NavItem(Icons.map_outlined, Icons.map_rounded, 'Roadmap', false,
                () => context.go('/roadmap?track=${Uri.encodeComponent(track)}')),
            _NavItem(Icons.play_circle_outline, Icons.play_circle, 'Resources',
                false, () => context.go('/resources')),
            _NavItem(Icons.person_outline, Icons.person_rounded, 'Profile', true,
                () {}),
          ],
        ),
      ),
    );
  }
}

// ── Photo Picker Bottom Sheet ─────────────────────────────────────

class _PhotoPickerSheet extends StatefulWidget {
  final String? currentPhotoUrl;
  final Function(String) onPhotoSelected;
  const _PhotoPickerSheet({
    required this.currentPhotoUrl,
    required this.onPhotoSelected,
  });

  @override
  State<_PhotoPickerSheet> createState() => _PhotoPickerSheetState();
}

class _PhotoPickerSheetState extends State<_PhotoPickerSheet> {
  bool _isProcessing = false;

  Future<void> _pickImageFromDevice() async {
    setState(() => _isProcessing = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final bytes = result.files.first.bytes;
        final name = result.files.first.name.toLowerCase();
        if (bytes != null) {
          final extension = name.endsWith('.jpg') || name.endsWith('.jpeg')
              ? 'jpeg'
              : name.endsWith('.webp')
                  ? 'webp'
                  : 'png';
          final base64String =
              'data:image/$extension;base64,${base64Encode(bytes)}';
          widget.onPhotoSelected(base64String);
          if (mounted) Navigator.pop(context);
          return;
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not pick image file')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E4F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Change Profile Photo',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select an image from your device or pick a developer avatar',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: const Color(0xFF6B6890),
            ),
          ),
          const SizedBox(height: 20),

          if (_isProcessing)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Color(0xFFFF5722)),
              ),
            )
          else ...[
            // Option 1: Pick from Device / Browser Gallery
            GestureDetector(
              onTap: _pickImageFromDevice,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECE5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF5722).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5722),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.photo_library_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose from Device / Gallery',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            'Upload PNG, JPG, or WEBP photo',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: const Color(0xFF6B6890),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFFF5722),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Option 2: Choose Preset Avatars
            Text(
              'Or choose a Developer Avatar',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF9B99B5),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _PresetAvatarTile(
                    label: 'PathForge Emblem',
                    imagePath: 'assets/images/logo.png',
                    onTap: () {
                      widget.onPhotoSelected('assets/images/logo.png');
                      Navigator.pop(context);
                    },
                  ),
                  _PresetAvatarTile(
                    label: 'FORGE Robot',
                    imagePath: 'assets/images/robot-for-chatbot.png',
                    onTap: () {
                      widget.onPhotoSelected('assets/images/robot-for-chatbot.png');
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Option 3: Remove Current Photo
            if (widget.currentPhotoUrl != null &&
                widget.currentPhotoUrl!.isNotEmpty)
              GestureDetector(
                onTap: () {
                  widget.onPhotoSelected('');
                  Navigator.pop(context);
                },
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Remove Current Photo',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _PresetAvatarTile extends StatelessWidget {
  final String label;
  final String imagePath;
  final VoidCallback onTap;
  const _PresetAvatarTile({
    required this.label,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F4FB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2DCF2)),
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF111322),
              ),
              child: ClipOval(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.account_circle,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1B1D36),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Edit Profile Sheet (Text Fields Only) ─────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic>) onSaved;
  const _EditProfileSheet({required this.userData, required this.onSaved});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late TextEditingController _nameController;
  String? _branch, _year, _experience, _hours, _goal;
  bool _saving = false;

  final branches = [
    'Computer Science',
    'Information Technology',
    'Electronics',
    'Mechanical',
    'Other'
  ];
  final years = ['1st Year', '2nd Year', '3rd Year', '4th Year', 'Graduated'];
  final experiences = [
    'Complete Beginner',
    'Know basics',
    'Intermediate',
    'Advanced'
  ];
  final hoursList = ['2-4 hours', '5-8 hours', '8-12 hours', '12+ hours'];
  final goals = [
    'Get a job',
    'Crack FAANG',
    'Build startup',
    'Research & PhD'
  ];

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.userData['name'] ?? '');
    _branch = widget.userData['branch'] ?? 'Other';
    _year = widget.userData['year'] ?? 'Graduated';
    _experience = widget.userData['experience'] ?? 'Advanced';
    _hours = widget.userData['hours'] ?? '12+ hours';
    _goal = widget.userData['goal'] ?? 'Research & PhD';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSaved({
      'name': _nameController.text.trim(),
      if (_branch != null) 'branch': _branch,
      if (_year != null) 'year': _year,
      if (_experience != null) 'experience': _experience,
      if (_hours != null) 'hours': _hours,
      if (_goal != null) 'goal': _goal,
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E4F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Edit Profile',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 16),

            // Name Field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Dropdowns
            _dropdown('Branch', _branch, branches, (v) => setState(() => _branch = v)),
            const SizedBox(height: 12),
            _dropdown('Year', _year, years, (v) => setState(() => _year = v)),
            const SizedBox(height: 12),
            _dropdown('Experience', _experience, experiences,
                (v) => setState(() => _experience = v)),
            const SizedBox(height: 12),
            _dropdown('Study Hours', _hours, hoursList,
                (v) => setState(() => _hours = v)),
            const SizedBox(height: 12),
            _dropdown('Main Goal', _goal, goals, (v) => setState(() => _goal = v)),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Save Changes',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(String label, String? current, List<String> items,
      ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: items.contains(current) ? current : items.first,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ── Supporting Profile Widgets ─────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF1A1A2E),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  const _StatItem(this.value, this.label, this.icon, this.color, this.bg);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                color: const Color(0xFF6B6890),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Div extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 40,
        color: const Color(0xFFE8E9F2),
      );
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final Color color;
  final Color bg;
  final bool unlocked;
  const _Badge(
      this.icon, this.title, this.sub, this.color, this.bg, this.unlocked);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: unlocked ? 1.0 : 0.4,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked
                ? const Color(0xFFFF5722).withOpacity(0.3)
                : const Color(0xFFE8E9F2),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            Text(
              sub,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: const Color(0xFF6B6890),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;
  const _InfoRow(this.icon, this.label, this.value, {this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF0EDF8))),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7C5CBF), size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF6B6890),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onTap;
  const _SettingTile(this.icon, this.title, this.subtitle, this.iconColor,
      this.iconBg, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8E9F2)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF6B6890),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9B99B5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _NavItem(IconData icon, IconData activeIcon, String label,
    bool active, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFFEFEA) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? activeIcon : icon,
            color: active ? const Color(0xFFFF5722) : const Color(0xFF9B99B5),
            size: 22,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color:
                  active ? const Color(0xFFFF5722) : const Color(0xFF9B99B5),
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}
