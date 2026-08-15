import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
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
  String get _initial => _name.isNotEmpty ? _name[0].toUpperCase() : 'S';

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

    final track = roadmapData?['track'] ?? 'Data Analyst';
    final weeks = roadmapData?['weeks'] as List? ?? [];
    final doneWeeks = weeks.where((w) => w['status'] == 'done').length;
    final totalWeeks = weeks.isEmpty ? 8 : weeks.length;
    final progress = totalWeeks > 0 ? doneWeeks / totalWeeks : 0.0;
    final xp = (userData?['xp'] ?? 0) as int;
    final level = (userData?['level'] ?? 1) as int;
    final levelName = userData?['levelName'] ?? 'Code Newcomer';
    final streak = (userData?['streak'] ?? 0) as int;

    return Scaffold(
      backgroundColor: const Color(0xFF111322),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Container(
              color: const Color(0xFFF8F9FE),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Top Obsidian Header
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
                              MediaQuery.of(context).padding.top + 16,
                              20,
                              24,
                            ),
                            child: Column(
                              children: [
                                // Top Action Bar
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () => context.go('/home'),
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(10),
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
                                        fontSize: 17,
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
                                          color: const Color(0xFFFF5722)
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: const Color(0xFFFF5722)
                                                .withOpacity(0.4),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.edit_rounded,
                                          color: Color(0xFFFF8A65),
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),

                                // Student Avatar with Camera Badge
                                Stack(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFFF5722),
                                            Color(0xFF7C5CBF),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFF5722)
                                                .withOpacity(0.35),
                                            blurRadius: 16,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          _initial,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: _openEditSheet,
                                        child: Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF5722),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFF1B1D36),
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt_rounded,
                                            color: Colors.white,
                                            size: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Name & Branch
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
                                  '${userData?['branch'] ?? 'Computer Science'} · ${userData?['year'] ?? '2nd Year'}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: const Color(0xFFB3B0D6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Badges Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF5722)
                                            .withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFFF5722)
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        '⭐ Level $level · $levelName',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFFF8A65),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7C5CBF)
                                            .withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF7C5CBF)
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        track,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFD4C9FF),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // 4-Column Quick Stats Row
                          Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                _StatItem(
                                  value: '$xp',
                                  label: 'Total XP',
                                  icon: Icons.bolt_rounded,
                                  color: const Color(0xFFFFB800),
                                  bg: const Color(0xFFFFF8E7),
                                ),
                                _Div(),
                                _StatItem(
                                  value: '$doneWeeks',
                                  label: 'Weeks done',
                                  icon: Icons.check_circle_rounded,
                                  color: const Color(0xFF00B894),
                                  bg: const Color(0xFFE8F8F0),
                                ),
                                _Div(),
                                _StatItem(
                                  value: '$streak',
                                  label: 'Day streak',
                                  icon: Icons.local_fire_department_rounded,
                                  color: const Color(0xFFFF5722),
                                  bg: const Color(0xFFFFF3EE),
                                ),
                                _Div(),
                                _StatItem(
                                  value: 'Lv.$level',
                                  label: 'Level',
                                  icon: Icons.star_rounded,
                                  color: const Color(0xFF7C5CBF),
                                  bg: const Color(0xFFF5F3FF),
                                ),
                              ],
                            ),
                          ),

                          // Profile Content Body
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Job Readiness Score Card
                                GestureDetector(
                                  onTap: () => context.go('/job-readiness'),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1B1D36),
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFF5722),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '0',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Job Readiness Score',
                                                style: GoogleFonts
                                                    .plusJakartaSans(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Text(
                                                'See your full score breakdown',
                                                style: GoogleFonts
                                                    .plusJakartaSans(
                                                  fontSize: 11.5,
                                                  color:
                                                      const Color(0xFFB3B0D6),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF5722),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            'View',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
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
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            levelName,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            '$xp / ${level * 500} XP',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFFB3B0D6),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: (xp % 500) / 500.0,
                                          backgroundColor: Colors.white12,
                                          valueColor:
                                              const AlwaysStoppedAnimation(
                                            Color(0xFFFF5722),
                                          ),
                                          minHeight: 5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${500 - (xp % 500)} XP to Level ${level + 1}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: const Color(0xFFB3B0D6),
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
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color(0xFFE2E4F0),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            track,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF1A1A2E),
                                            ),
                                          ),
                                          Text(
                                            '$doneWeeks/$totalWeeks weeks',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFFFF5722),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          backgroundColor:
                                              const Color(0xFFE2E4F0),
                                          valueColor:
                                              const AlwaysStoppedAnimation(
                                            Color(0xFFFF5722),
                                          ),
                                          minHeight: 5,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${(progress * 100).toInt()}% complete',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: const Color(0xFF6B6890),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => context.go(
                                                '/roadmap?track=${Uri.encodeComponent(track)}'),
                                            child: Text(
                                              'View Roadmap →',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
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

                                // Achievements Grid
                                _SectionTitle('Achievements'),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _Badge(
                                      Icons.rocket_launch_rounded,
                                      'Started',
                                      'Joined PathForge',
                                      const Color(0xFFFF5722),
                                      const Color(0xFFFFF3EE),
                                      true,
                                    ),
                                    const SizedBox(width: 8),
                                    _Badge(
                                      Icons.code_rounded,
                                      'Coder',
                                      'Completed Week 1',
                                      const Color(0xFF7C5CBF),
                                      const Color(0xFFF5F3FF),
                                      doneWeeks >= 1,
                                    ),
                                    const SizedBox(width: 8),
                                    _Badge(
                                      Icons.local_fire_department_rounded,
                                      '7-Day Streak',
                                      'Keeps going!',
                                      const Color(0xFFFFB800),
                                      const Color(0xFFFFF8E7),
                                      streak >= 7,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),

                                // My Profile Details
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _SectionTitle('My profile'),
                                    GestureDetector(
                                      onTap: _openEditSheet,
                                      child: Row(
                                        children: [
                                          const Icon(Icons.edit_rounded,
                                              size: 13,
                                              color: Color(0xFFFF5722)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Edit',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
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
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color(0xFFE2E4F0),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      _InfoRow(
                                        Icons.school_outlined,
                                        'Branch',
                                        userData?['branch'] ??
                                            'Computer Science',
                                      ),
                                      const Divider(
                                          height: 1, color: Color(0xFFF0F1F7)),
                                      _InfoRow(
                                        Icons.calendar_today_outlined,
                                        'Year',
                                        userData?['year'] ?? '2nd Year',
                                      ),
                                      const Divider(
                                          height: 1, color: Color(0xFFF0F1F7)),
                                      _InfoRow(
                                        Icons.code_rounded,
                                        'Experience',
                                        userData?['experience'] ??
                                            'Intermediate',
                                      ),
                                      const Divider(
                                          height: 1, color: Color(0xFFF0F1F7)),
                                      _InfoRow(
                                        Icons.access_time_rounded,
                                        'Study hours',
                                        userData?['hours'] ?? '8-12 hours/week',
                                      ),
                                      const Divider(
                                          height: 1, color: Color(0xFFF0F1F7)),
                                      _InfoRow(
                                        Icons.flag_outlined,
                                        'Main goal',
                                        userData?['goal'] ?? 'Get a job',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Settings & Account Actions
                                _SectionTitle('Settings & Account'),
                                const SizedBox(height: 8),
                                _SettingTile(
                                  Icons.route_rounded,
                                  'Change Career Track',
                                  'Explore or regenerate your learning path',
                                  const Color(0xFF7C5CBF),
                                  const Color(0xFFF5F3FF),
                                  () => context.go('/track'),
                                ),
                                _SettingTile(
                                  Icons.delete_sweep_rounded,
                                  'Reset Mentor Chat History',
                                  'Clear conversation context with AI Mentor',
                                  const Color(0xFFFF5722),
                                  const Color(0xFFFFF3EE),
                                  () async {
                                    final uid = FirebaseAuth
                                        .instance.currentUser?.uid;
                                    if (uid != null) {
                                      await FirebaseFirestore.instance
                                          .collection('mentor_chats')
                                          .doc(uid)
                                          .delete();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text('Chat history cleared!'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                                _SettingTile(
                                  Icons.logout_rounded,
                                  'Sign Out',
                                  'Log out of your PathForge account',
                                  const Color(0xFFD32F2F),
                                  const Color(0xFFFFF0F0),
                                  () async {
                                    await AuthService.signOut();
                                    if (mounted) context.go('/auth');
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Navigation Bar (Strictly 4 icons)
                  _BottomNav(
                    currentIndex: 3,
                    onHome: () => context.go('/home'),
                    onRoadmap: () => context.go(
                        '/roadmap?track=${Uri.encodeComponent(track)}'),
                    onResources: () => context.go('/resources'),
                    onProfile: () => context.go('/profile'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Edit Profile Sheet ─────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic>) onSaved;
  const _EditProfileSheet({required this.userData, required this.onSaved});
  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late TextEditingController _nameController;
  String? _branch, _year, _experience, _goal, _hours;
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
  final goals = [
    'Get a job',
    'Crack FAANG',
    'Build startup',
    'Research & PhD'
  ];
  final hoursList = [
    '2-4 hours',
    '5-8 hours',
    '8-12 hours',
    '12+ hours'
  ];

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.userData['name'] ?? '');
    _branch = widget.userData['branch'];
    _year = widget.userData['year'];
    _experience = widget.userData['experience'];
    _goal = widget.userData['goal'];
    _hours = widget.userData['hours'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = {
      'name': _nameController.text.trim(),
      if (_branch != null) 'branch': _branch,
      if (_year != null) 'year': _year,
      if (_experience != null) 'experience': _experience,
      if (_goal != null) 'goal': _goal,
      if (_hours != null) 'hours': _hours,
    };
    await widget.onSaved(updated);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline_rounded,
                    color: Color(0xFF9B99B5)),
                filled: true,
                fillColor: const Color(0xFFF8F9FE),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E4F0)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _Dropdown('Branch', _branch, branches, Icons.school_rounded,
                (v) => setState(() => _branch = v)),
            const SizedBox(height: 12),
            _Dropdown('Year', _year, years, Icons.calendar_today_rounded,
                (v) => setState(() => _year = v)),
            const SizedBox(height: 12),
            _Dropdown('Coding Experience', _experience, experiences,
                Icons.code_rounded, (v) => setState(() => _experience = v)),
            const SizedBox(height: 12),
            _Dropdown('Goal', _goal, goals, Icons.flag_rounded,
                (v) => setState(() => _goal = v)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Save Changes',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _Dropdown(String label, String? value, List<String> options,
      IconData icon, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E4F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.contains(value) ? value : null,
          hint: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF9B99B5)),
              const SizedBox(width: 10),
              Text(
                'Select $label',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  color: const Color(0xFF9B99B5),
                ),
              ),
            ],
          ),
          isExpanded: true,
          onChanged: onChanged,
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
        ),
      ),
    );
  }
}

// ── Components ────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color, bg;
  const _StatItem(
      {required this.value,
      required this.label,
      required this.icon,
      required this.color,
      required this.bg});

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
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                color: const Color(0xFF9B99B5),
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
  Widget build(BuildContext context) =>
      Container(width: 1, height: 44, color: const Color(0xFFE2E4F0));
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String title, desc;
  final Color color, bg;
  final bool earned;
  const _Badge(
      this.icon, this.title, this.desc, this.color, this.bg, this.earned);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Opacity(
        opacity: earned ? 1.0 : 0.45,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: earned ? color.withOpacity(0.3) : const Color(0xFFE2E4F0),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 17),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              Text(
                desc,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  color: const Color(0xFF9B99B5),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _SectionTitle(String t) => Text(
      t,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A1A2E),
      ),
    );

Widget _InfoRow(IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 17, color: const Color(0xFF9B99B5)),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF6B6890),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );

Widget _SettingTile(
  IconData icon,
  String title,
  String sub,
  Color color,
  Color bg,
  VoidCallback onTap,
) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E4F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    sub,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF9B99B5),
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

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final VoidCallback onHome, onRoadmap, onResources, onProfile;
  const _BottomNav({
    required this.currentIndex,
    required this.onHome,
    required this.onRoadmap,
    required this.onResources,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E4F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home',
              currentIndex == 0, onHome),
          _NavItem(Icons.map_outlined, Icons.map_rounded, 'Roadmap',
              currentIndex == 1, onRoadmap),
          _NavItem(Icons.play_circle_outline, Icons.play_circle, 'Resources',
              currentIndex == 2, onResources),
          _NavItem(Icons.person_outline, Icons.person_rounded, 'Profile',
              currentIndex == 3, onProfile),
        ],
      ),
    );
  }
}

Widget _NavItem(
  IconData icon,
  IconData activeIcon,
  String label,
  bool active,
  VoidCallback onTap,
) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFFF3EE) : Colors.transparent,
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
