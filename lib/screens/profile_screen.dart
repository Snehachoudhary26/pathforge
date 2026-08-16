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
                  16,
                  MediaQuery.of(context).padding.top + 10,
                  16,
                  20,
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
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        ),
                        Text(
                          'Profile',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: _openEditSheet,
                          child: Container(
                            width: 34,
                            height: 34,
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
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Interactive Profile Avatar
                    GestureDetector(
                      onTap: _openPhotoPickerSheet,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF5722), Color(0xFF7C5CBF)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF5722).withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(2.5),
                            child: ClipOval(
                              child: _buildAvatarWidget(70),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5722),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF111322),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // User Name & Subtitle
                    Text(
                      _name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${userData?['branch'] ?? 'Other'} · ${userData?['year'] ?? 'Graduated'}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: const Color(0xFFB3B0D6),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Level & Track Badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5722).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(16),
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
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Level $level: $levelName',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFF8A65),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C5CBF).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(16),
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

              // Body Content (White Card)
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FE),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Row
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8E9F2)),
                      ),
                      child: Row(
                        children: [
                          _StatItem(
                            '$streak days',
                            'Streak',
                            Icons.local_fire_department_rounded,
                            const Color(0xFFFF5722),
                            const Color(0xFFFFECE5),
                          ),
                          _Div(),
                          _StatItem(
                            '$xp',
                            'Total XP',
                            Icons.bolt_rounded,
                            const Color(0xFFE08D00),
                            const Color(0xFFFEFBE8),
                          ),
                          _Div(),
                          _StatItem(
                            '$doneWeeks/$totalWeeks',
                            'Weeks done',
                            Icons.check_circle_outline_rounded,
                            const Color(0xFF00B894),
                            const Color(0xFFE6F8F4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Roadmap Progress
                    _SectionTitle('Roadmap Progress'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8E9F2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                track,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1A1A2E),
                                ),
                              ),
                              Text(
                                '${(progress * 100).toInt()}% complete',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFF5722),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: const Color(0xFFF0EDF8),
                              valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFFFF5722)),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Academic & Goals
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SectionTitle('Academic & Goals'),
                        GestureDetector(
                          onTap: _openEditSheet,
                          child: Text(
                            'Edit',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFFF5722),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
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
                    const SizedBox(height: 14),

                    // Settings & Account
                    _SectionTitle('Settings & Account'),
                    const SizedBox(height: 6),
                    _SettingTile(
                      Icons.swap_horiz_rounded,
                      'Change Career Track',
                      'Explore or regenerate your learning path',
                      const Color(0xFF7C5CBF),
                      const Color(0xFFF3F0FA),
                      () => context.go('/track'),
                    ),
                    const SizedBox(height: 6),
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
        padding: const EdgeInsets.symmetric(vertical: 6),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD4D6E2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Change Profile Photo',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _pickImageFromDevice,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.upload_file_rounded, size: 16),
              label: Text(
                'Upload from Device',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Edit Profile Sheet ───────────────────────────────────────────

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
      'branch': _branch,
      'year': _year,
      'experience': _experience,
      'hours': _hours,
      'goal': _goal,
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.fromLTRB(
        18,
        14,
        18,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4D6E2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Edit Profile',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),
            _buildField(
              'Full Name',
              TextField(
                controller: _nameController,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1B1D36),
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E4F0)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildDropdown('Branch', branches, _branch, (v) => setState(() => _branch = v)),
            const SizedBox(height: 10),
            _buildDropdown('Year', years, _year, (v) => setState(() => _year = v)),
            const SizedBox(height: 10),
            _buildDropdown('Experience', experiences, _experience, (v) => setState(() => _experience = v)),
            const SizedBox(height: 10),
            _buildDropdown('Main Goal', goals, _goal, (v) => setState(() => _goal = v)),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Save Changes',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
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

  Widget _buildField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6B6890),
          ),
        ),
        const SizedBox(height: 4),
        field,
      ],
    );
  }

  Widget _buildDropdown(
      String label, List<String> items, String? current, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6B6890),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E4F0)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: items.contains(current) ? current : items.first,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B1D36),
              ),
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Supporting Helper Widgets ─────────────────────────────────────

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
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 15),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
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
        height: 36,
        color: const Color(0xFFE8E9F2),
      );
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF0EDF8))),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7C5CBF), size: 16),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF6B6890),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E9F2)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: const Color(0xFF6B6890),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9B99B5),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _SectionTitle(String text) {
  return Text(
    text,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: const Color(0xFF1A1A2E),
    ),
  );
}

Widget _NavItem(IconData icon, IconData activeIcon, String label,
    bool active, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFFEFEA) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? activeIcon : icon,
            color: active ? const Color(0xFFFF5722) : const Color(0xFF9B99B5),
            size: 20,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
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
