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
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { setState(() => isLoading = false); return; }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(uid).get();
      final roadmapSnap = await FirebaseFirestore.instance
          .collection('roadmaps')
          .where('uid', isEqualTo: uid)
          .limit(1).get();
      if (mounted) setState(() {
        userData = userDoc.data();
        roadmapData = roadmapSnap.docs.isNotEmpty
            ? roadmapSnap.docs.first.data() : null;
        isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String get _name => userData?['name'] ??
      FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? 'Student';
  String get _initial =>
      _name.isNotEmpty ? _name[0].toUpperCase() : 'S';

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
              .collection('users').doc(uid)
              .set(updated, SetOptions(merge: true));
          if (mounted) {
            setState(() => userData = {...?userData, ...updated});
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Profile updated!',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700, color: Colors.white)),
              backgroundColor: AppTheme.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Center(child: CircularProgressIndicator(color: AppTheme.orange)));

    final track = roadmapData?['track'] ?? '';
    final weeks = roadmapData?['weeks'] as List? ?? [];
    final doneWeeks = weeks.where((w) => w['status'] == 'done').length;
    final totalWeeks = weeks.length;
    final progress = totalWeeks > 0 ? doneWeeks / totalWeeks : 0.0;
    final xp = (userData?['xp'] ?? 0) as int;
    final level = (userData?['level'] ?? 1) as int;
    final levelName = userData?['levelName'] ?? 'Code Newcomer';
    final streak = (userData?['streak'] ?? 0) as int;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: [

            // Navy header
            Container(
              color: AppTheme.navy,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(children: [
                Row(children: [
                  GestureDetector(
                    onTap: () => context.go('/home'),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  const Spacer(),
                  Text('Profile', style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.w800,
                      color: Colors.white)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _openEditSheet,
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.orange.withOpacity(0.4)),
                      ),
                      child: Icon(Icons.edit_rounded,
                          color: AppTheme.orange, size: 16),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                Stack(
                  children: [
                    Container(
                      width: 76, height: 76,
                      decoration: BoxDecoration(
                        color: AppTheme.orange,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white24, width: 3),
                      ),
                      child: Center(child: Text(_initial,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 30, fontWeight: FontWeight.w800,
                              color: Colors.white))),
                    ),
                    Positioned(
                      right: 0, bottom: 0,
                      child: GestureDetector(
                        onTap: _openEditSheet,
                        child: Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: AppTheme.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.edit_rounded,
                              color: Colors.white, size: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(_name, style: GoogleFonts.plusJakartaSans(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  '${userData?['branch'] ?? 'Add your branch'} · ${userData?['year'] ?? 'Add your year'}',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: Colors.white54),
                ),
                const SizedBox(height: 8),
                // Level pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppTheme.orange.withOpacity(0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.star_rounded,
                        color: AppTheme.orange, size: 14),
                    const SizedBox(width: 5),
                    Text('Level $level · $levelName',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: AppTheme.orange)),
                  ]),
                ),
                if (track.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(track, style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: Colors.white70)),
                  ),
                ],
              ]),
            ),

            // Stats row
            Container(
              margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(children: [
                _StatItem('$xp', 'Total XP',
                    Icons.bolt_rounded, AppTheme.amber, AppTheme.amberLight),
                _Div(),
                _StatItem('$doneWeeks', 'Weeks',
                    Icons.check_circle_rounded, AppTheme.green,
                    AppTheme.greenLight),
                _Div(),
                _StatItem('$streak', 'Streak',
                    Icons.local_fire_department_rounded, AppTheme.orange,
                    AppTheme.orangeLight),
                _Div(),
                _StatItem('Lv.$level', 'Level',
                    Icons.star_rounded, AppTheme.primary,
                    AppTheme.purpleLight),
              ]),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [


                  // Job Readiness Score button
                  GestureDetector(
                    onTap: () => context.go('/readiness'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.navy,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.orange.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.bar_chart_rounded,
                              color: AppTheme.orange, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Job Readiness Score',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14, fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                            Text('See your full score breakdown',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11, color: Colors.white54)),
                          ],
                        )),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.orange,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('View',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12, fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // XP Progress
                  _SectionTitle('XP Progress'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.navy,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(levelName,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13, fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          Text('$xp / ${level * 500} XP',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12, fontWeight: FontWeight.w700,
                                  color: AppTheme.orange)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ((xp % 500) / 500).clamp(0.0, 1.0),
                          backgroundColor: Colors.white12,
                          valueColor:
                              AlwaysStoppedAnimation(AppTheme.orange),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${500 - (xp % 500)} XP to Level ${level + 1}',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, color: Colors.white54),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // Current Progress
                  if (roadmapData != null) ...[
                    _SectionTitle('Current progress'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(track,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14, fontWeight: FontWeight.w800,
                                    color: AppTheme.textDark))),
                            Text('$doneWeeks/$totalWeeks weeks',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12, fontWeight: FontWeight.w700,
                                    color: AppTheme.orange)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppTheme.border,
                            valueColor:
                                AlwaysStoppedAnimation(AppTheme.orange),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${(progress * 100).toInt()}% complete',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11, color: AppTheme.textMid)),
                            GestureDetector(
                              onTap: () => context.go(
                                  '/roadmap?track=${Uri.encodeComponent(track)}'),
                              child: Text('View Roadmap →',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11, fontWeight: FontWeight.w700,
                                      color: AppTheme.orange)),
                            ),
                          ],
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Achievements
                  _SectionTitle('Achievements'),
                  const SizedBox(height: 10),
                  Row(children: [
                    _Badge(Icons.rocket_launch_rounded, 'Started',
                        'Joined PathForge', AppTheme.orange,
                        AppTheme.orangeLight, true),
                    const SizedBox(width: 10),
                    _Badge(Icons.code_rounded, 'Coder',
                        'Completed Week 1', AppTheme.primary,
                        AppTheme.purpleLight, doneWeeks >= 1),
                    const SizedBox(width: 10),
                    _Badge(Icons.local_fire_department_rounded,
                        '7 Day Streak', 'Keep going!', AppTheme.amber,
                        AppTheme.amberLight, streak >= 7),
                  ]),
                  const SizedBox(height: 20),

                  // Profile info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionTitle('My profile'),
                      GestureDetector(
                        onTap: _openEditSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.orangeLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppTheme.orangeBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_rounded,
                                  size: 12, color: AppTheme.orange),
                              const SizedBox(width: 4),
                              Text('Edit',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.orange)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(children: [
                      _InfoRow(Icons.school_rounded, 'Branch',
                          userData?['branch'] ?? 'Not set'),
                      _InfoRow(Icons.calendar_today_rounded, 'Year',
                          userData?['year'] ?? 'Not set'),
                      _InfoRow(Icons.laptop_mac_rounded, 'Experience',
                          userData?['experience'] ?? 'Not set'),
                      _InfoRow(Icons.access_time_rounded, 'Study Time',
                          userData?['hours'] ?? 'Not set'),
                      _InfoRow(Icons.flag_rounded, 'Goal',
                          userData?['goal'] ?? 'Not set'),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // Settings
                  _SectionTitle('Settings'),
                  const SizedBox(height: 10),
                  _SettingTile(Icons.refresh_rounded, 'Regenerate Roadmap',
                      'Get a fresh AI roadmap', AppTheme.primary,
                      AppTheme.purpleLight, () => context.go('/track')),
                  _SettingTile(Icons.swap_horiz_rounded, 'Change Track',
                      'Switch career path', AppTheme.orange,
                      AppTheme.orangeLight, () => context.go('/track')),
                  _SettingTile(Icons.logout_rounded, 'Sign Out',
                      'Log out of PathForge', Colors.red.shade600,
                      Colors.red.shade50, () async {
                        await AuthService.signOut();
                        if (context.mounted) context.go('/auth');
                      }),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ]),
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
            _NavItem(Icons.home_outlined, Icons.home_rounded,
                'Home', false, () => context.go('/home')),
            _NavItem(Icons.map_outlined, Icons.map_rounded, 'Roadmap', false,
                () => track.isNotEmpty
                    ? context.go('/roadmap?track=${Uri.encodeComponent(track)}')
                    : context.go('/track')),
            _NavItem(Icons.play_circle_outline, Icons.play_circle,
                'Resources', false, () => context.go('/resources')),
            _NavItem(Icons.person_outline, Icons.person_rounded,
                'Profile', true, () {}),
          ],
        ),
      ),
    );
  }
}

// ─── Edit Profile Bottom Sheet ────────────────────────────────────

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

  final branches = ['Computer Science', 'Information Technology',
      'Electronics', 'Mechanical', 'Other'];
  final years = ['1st Year', '2nd Year', '3rd Year', '4th Year', 'Graduated'];
  final experiences = ['Complete Beginner', 'Know basics', 'Intermediate', 'Advanced'];
  final hoursList = ['2-4 hours', '5-8 hours', '8-12 hours', '12+ hours'];
  final goals = ['Get a job', 'Crack FAANG', 'Build startup', 'Research & PhD'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
        text: widget.userData['name'] ?? '');
    _branch = widget.userData['branch'];
    _year = widget.userData['year'];
    _experience = widget.userData['experience'];
    _hours = widget.userData['hours'];
    _goal = widget.userData['goal'];
  }

  @override
  void dispose() { _nameController.dispose(); super.dispose(); }

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
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Edit Profile', style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w800,
                    color: AppTheme.textDark)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.cream,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded,
                        size: 16, color: AppTheme.textMid),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Name field
            Text('Full name', style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: AppTheme.textMid)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, color: AppTheme.textDark),
              decoration: InputDecoration(
                hintText: 'Your full name',
                hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: AppTheme.textLight),
                filled: true,
                fillColor: AppTheme.cream,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: AppTheme.orange, width: 2)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Dropdowns
            _Dropdown('Branch', _branch, branches,
                Icons.school_rounded, (v) => setState(() => _branch = v)),
            const SizedBox(height: 12),
            _Dropdown('Year', _year, years,
                Icons.calendar_today_rounded, (v) => setState(() => _year = v)),
            const SizedBox(height: 12),
            _Dropdown('Experience', _experience, experiences,
                Icons.laptop_mac_rounded, (v) => setState(() => _experience = v)),
            const SizedBox(height: 12),
            _Dropdown('Study hours/week', _hours, hoursList,
                Icons.access_time_rounded, (v) => setState(() => _hours = v)),
            const SizedBox(height: 12),
            _Dropdown('Goal', _goal, goals,
                Icons.flag_rounded, (v) => setState(() => _goal = v)),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('Save changes',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _Dropdown(String label, String? value, List<String> options,
      IconData icon, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: AppTheme.textMid)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.cream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.contains(value) ? value : null,
              hint: Row(children: [
                Icon(icon, size: 16, color: AppTheme.textLight),
                const SizedBox(width: 8),
                Text('Select $label',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: AppTheme.textLight)),
              ]),
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.textLight),
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: AppTheme.textDark),
              onChanged: onChanged,
              items: options.map((o) => DropdownMenuItem(
                value: o,
                child: Text(o),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color, bg;
  const _StatItem(this.value, this.label, this.icon, this.color, this.bg);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(children: [
        Container(width: 32, height: 32,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16)),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: GoogleFonts.plusJakartaSans(
            fontSize: 10, color: AppTheme.textLight,
            fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _Div extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 50, color: AppTheme.border);
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String title, desc;
  final Color color, bg;
  final bool earned;
  const _Badge(this.icon, this.title, this.desc,
      this.color, this.bg, this.earned);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Opacity(
      opacity: earned ? 1.0 : 0.4,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: earned ? color.withOpacity(0.3) : AppTheme.border),
        ),
        child: Column(children: [
          Container(width: 36, height: 36,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18)),
          const SizedBox(height: 6),
          Text(title, textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppTheme.textDark)),
          Text(desc, textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 9, color: AppTheme.textLight), maxLines: 2),
        ]),
      ),
    ),
  );
}

Widget _SectionTitle(String t) => Text(t,
    style: GoogleFonts.plusJakartaSans(
        fontSize: 15, fontWeight: FontWeight.w800,
        color: AppTheme.textDark));

Widget _InfoRow(IconData icon, String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  child: Row(children: [
    Icon(icon, size: 16, color: AppTheme.textLight),
    const SizedBox(width: 10),
    Text(label, style: GoogleFonts.plusJakartaSans(
        fontSize: 13, color: AppTheme.textMid)),
    const Spacer(),
    Text(value, style: GoogleFonts.plusJakartaSans(
        fontSize: 13, fontWeight: FontWeight.w700,
        color: AppTheme.textDark)),
  ]),
);

Widget _SettingTile(IconData icon, String title, String sub,
    Color color, Color bg, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(children: [
          Container(width: 36, height: 36,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppTheme.textDark)),
              Text(sub, style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, color: AppTheme.textLight)),
            ],
          )),
          Icon(Icons.chevron_right_rounded,
              color: AppTheme.textLight, size: 20),
        ]),
      ),
    );

Widget _NavItem(IconData icon, IconData activeIcon, String label,
    bool active, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.orangeLight : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(active ? activeIcon : icon,
              color: active ? AppTheme.orange : AppTheme.textLight, size: 24),
          const SizedBox(height: 3),
          Text(label, style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: active ? AppTheme.orange : AppTheme.textLight,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
        ]),
      ),
    );
