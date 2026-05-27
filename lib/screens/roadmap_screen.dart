import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import '../core/theme.dart';
import '../services/firestore_service.dart';

class RoadmapScreen extends StatefulWidget {
  final String track;
  const RoadmapScreen({super.key, required this.track});
  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  List<Map<String, dynamic>> weeks = [];
  bool isLoading = true;
  String? error;
  String? _docId;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _loadRoadmap();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadRoadmap() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() { isLoading = false; error = 'Not logged in'; });
        return;
      }
      final snap = await FirebaseFirestore.instance
          .collection('roadmaps')
          .where('uid', isEqualTo: uid)
          .where('track', isEqualTo: widget.track)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        _docId = doc.id;
        final rawWeeks = doc.data()['weeks'] as List<dynamic>? ?? [];
        setState(() {
          weeks = rawWeeks.map((w) {
            final week = Map<String, dynamic>.from(w as Map);
            week['skills'] = (week['skills'] as List? ?? [])
                .map((s) => s.toString())
                .toList();
            return week;
          }).toList();
          isLoading = false;
        });
      } else {
        final data = await FirestoreService.getRoadmapForTrack(
            uid: uid, track: widget.track);
        if (data != null && data['weeks'] != null) {
          _docId =
              '${uid}_${widget.track.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
          setState(() {
            weeks = (data['weeks'] as List).map((w) {
              final week = Map<String, dynamic>.from(w as Map);
              week['skills'] = (week['skills'] as List? ?? [])
                  .map((s) => s.toString())
                  .toList();
              return week;
            }).toList();
            isLoading = false;
          });
        } else {
          setState(() { isLoading = false; error = 'No roadmap found.'; });
        }
      }
    } catch (e) {
      setState(() { isLoading = false; error = 'Error: $e'; });
    }
  }

  Future<void> _markWeekDone(int index) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => weeks[index]['status'] = 'done');
    _confettiController.play();
    try {
      if (_docId != null) {
        await FirebaseFirestore.instance
            .collection('roadmaps')
            .doc(_docId)
            .update({'weeks': weeks});
      }
    } catch (_) {}
    try {
      final result = await FirestoreService.addXP(uid: uid, xpToAdd: 80);
      if (mounted) {
        _showToast(
          result['leveledUp'] == true
              ? '🎉 Level Up! You are now ${result['levelName']}!'
              : '+80 XP earned! Keep going!',
          result['leveledUp'] == true,
        );
      }
    } catch (_) {}
  }

  Future<void> _unmarkWeekDone(int index) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => weeks[index]['status'] = 'pending');
    try {
      if (_docId != null) {
        await FirebaseFirestore.instance
            .collection('roadmaps')
            .doc(_docId)
            .update({'weeks': weeks});
      }
      await FirestoreService.removeXP(uid: uid, xpToRemove: 80);
    } catch (_) {}
  }

  void _goToInterview(int index) {
    final week = weeks[index];
    final title = week['title']?.toString() ?? 'Week ${index + 1}';
    final t = Uri.encodeComponent(widget.track);
    final w = Uri.encodeComponent(title);
    context.go('/interview?track=$t&week=$w');
  }

  void _showToast(String message, bool isLevelUp) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: isLevelUp
                  ? AppTheme.amber.withOpacity(0.3)
                  : Colors.white24,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLevelUp ? Icons.emoji_events_rounded : Icons.star_rounded,
              color: isLevelUp ? AppTheme.amber : Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message,
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 13))),
        ]),
        backgroundColor: isLevelUp ? AppTheme.primary : AppTheme.navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isLevelUp ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = weeks.where((w) => w['status'] == 'done').length;
    final progress = weeks.isEmpty ? 0.0 : doneCount / weeks.length;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Navy header
                Container(
                  color: AppTheme.navy,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.track,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                          Text('${weeks.length} weeks · AI generated',
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
                        child: Text('${(progress * 100).toInt()}% done',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 600),
                      builder: (_, val, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: val,
                          backgroundColor: Colors.white12,
                          valueColor:
                              AlwaysStoppedAnimation(AppTheme.orange),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$doneCount of ${weeks.length} weeks done',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 11, color: Colors.white54)),
                        Row(children: [
                          Icon(Icons.star_rounded,
                              color: AppTheme.amber, size: 13),
                          const SizedBox(width: 4),
                          Text('${doneCount * 80} XP earned',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.amber)),
                        ]),
                      ],
                    ),
                  ]),
                ),

                Expanded(
                  child: isLoading
                      ? Center(child: CircularProgressIndicator(
                          color: AppTheme.orange))
                      : error != null
                          ? _ErrorView(
                              track: widget.track,
                              onGenerate: () => context.go(
                                  '/generating?track=${Uri.encodeComponent(widget.track)}'))
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 16, 20, 20),
                              itemCount: weeks.length,
                              itemBuilder: (context, i) {
                                final week = weeks[i];
                                final isDone = week['status'] == 'done';
                                final isCurrent = !isDone &&
                                    weeks
                                        .take(i)
                                        .every((w) => w['status'] == 'done');
                                return _WeekCard(
                                  weekNum: week['weekNumber'] ?? (i + 1),
                                  title: week['title'] ?? 'Week ${i + 1}',
                                  skills: (week['skills'] as List)
                                      .cast<String>(),
                                  hours: week['estimatedHours'] ?? 8,
                                  why: week['why'] ?? '',
                                  isDone: isDone,
                                  isCurrent: isCurrent,
                                  isLast: i == weeks.length - 1,
                                  onMarkDone: () => _markWeekDone(i),
                                  onUnmark: () => _unmarkWeekDone(i),
                                  onInterview: () => _goToInterview(i),
                                );
                              },
                            ),
                ),

                // Bottom nav
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border:
                        Border(top: BorderSide(color: AppTheme.border)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavItem(Icons.home_outlined, Icons.home_rounded,
                          'Home', false, () => context.go('/home')),
                      _NavItem(Icons.map_outlined, Icons.map_rounded,
                          'Roadmap', true, () {}),
                      _NavItem(
                          Icons.play_circle_outline,
                          Icons.play_circle,
                          'Resources',
                          false,
                          () => context.go('/resources')),
                      _NavItem(Icons.person_outline, Icons.person_rounded,
                          'Profile', false, () => context.go('/profile')),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.2,
              shouldLoop: false,
              colors: [
                AppTheme.orange, AppTheme.primary,
                AppTheme.green, AppTheme.amber, Colors.white,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String track;
  final VoidCallback onGenerate;
  const _ErrorView({required this.track, required this.onGenerate});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppTheme.orangeLight,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.map_outlined,
                color: AppTheme.orange, size: 40),
          ),
          const SizedBox(height: 20),
          Text('No roadmap yet',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark)),
          const SizedBox(height: 8),
          Text('Generate your AI plan for $track',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: AppTheme.textMid),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onGenerate,
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text('Generate Roadmap',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ),
  );
}

class _WeekCard extends StatelessWidget {
  final dynamic weekNum;
  final String title, why;
  final List<String> skills;
  final dynamic hours;
  final bool isDone, isCurrent, isLast;
  final VoidCallback onMarkDone, onUnmark, onInterview;

  const _WeekCard({
    required this.weekNum,
    required this.title,
    required this.skills,
    required this.hours,
    required this.why,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
    required this.onMarkDone,
    required this.onUnmark,
    required this.onInterview,
  });

  @override
  Widget build(BuildContext context) {
    Color cardBg = Colors.white;
    Color borderColor = AppTheme.border;
    if (isDone) {
      cardBg = const Color(0xFFF8FDF8);
      borderColor = AppTheme.greenBorder;
    }
    if (isCurrent) {
      cardBg = AppTheme.orangeLight;
      borderColor = AppTheme.orange;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          Column(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: isDone
                    ? AppTheme.green
                    : isCurrent ? AppTheme.orange : AppTheme.border,
                shape: BoxShape.circle,
              ),
              child: isDone
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 15)
                  : isCurrent
                      ? const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 16)
                      : Center(child: Text('$weekNum',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textMid))),
            ),
            if (!isLast)
              Expanded(child: Container(
                width: 2,
                color: isDone
                    ? AppTheme.green.withOpacity(0.3)
                    : AppTheme.border,
              )),
          ]),
          const SizedBox(width: 12),

          // Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(child: Text('Week $weekNum — $title',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isDone
                                      ? AppTheme.textMid
                                      : AppTheme.textDark))),
                          if (isDone)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.greenLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('Done',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.green)),
                            )
                          else if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.orange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('Now',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                            ),
                        ]),
                        const SizedBox(height: 8),

                        // Skills
                        Wrap(
                          spacing: 6, runSpacing: 4,
                          children: skills.map((s) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? AppTheme.orange.withOpacity(0.12)
                                  : isDone
                                      ? AppTheme.greenLight
                                      : AppTheme.purpleLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(s,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isCurrent
                                        ? AppTheme.orange
                                        : isDone
                                            ? AppTheme.green
                                            : AppTheme.primary)),
                          )).toList(),
                        ),
                        const SizedBox(height: 8),

                        Row(children: [
                          Icon(Icons.access_time_rounded,
                              size: 13, color: AppTheme.textLight),
                          const SizedBox(width: 4),
                          Text('$hours hrs',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11, color: AppTheme.textLight)),
                          if (isDone) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.star_rounded,
                                size: 13, color: AppTheme.amber),
                            const SizedBox(width: 3),
                            Text('+80 XP earned',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.amber)),
                          ],
                        ]),

                        if (why.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.lightbulb_outline_rounded,
                                  size: 13, color: AppTheme.textMid),
                              const SizedBox(width: 4),
                              Expanded(child: Text(why,
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppTheme.textMid,
                                      height: 1.4))),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),

                  // Action buttons row
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: isDone ? onUnmark : onMarkDone,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isDone
                                ? AppTheme.greenLight
                                : isCurrent
                                    ? AppTheme.orange
                                    : AppTheme.border.withOpacity(0.4),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isDone
                                    ? Icons.undo_rounded
                                    : Icons.check_circle_outline_rounded,
                                size: 15,
                                color: isDone
                                    ? AppTheme.green
                                    : isCurrent
                                        ? Colors.white
                                        : AppTheme.textMid,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isDone ? 'Undo' : 'Mark done',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDone
                                        ? AppTheme.green
                                        : isCurrent
                                            ? Colors.white
                                            : AppTheme.textMid),
                              ),
                              if (!isDone) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('+80 XP',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: isCurrent
                                              ? Colors.white
                                              : AppTheme.textMid)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Interview practice button
                    GestureDetector(
                      onTap: onInterview,
                      child: Container(
                        width: 110,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.purpleLight,
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(16),
                          ),
                          border: Border(
                              left: BorderSide(color: AppTheme.border)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.quiz_rounded,
                                size: 14, color: AppTheme.primary),
                            const SizedBox(width: 5),
                            Text('Practice',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary)),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
              color: active ? AppTheme.orange : AppTheme.textLight,
              size: 24),
          const SizedBox(height: 3),
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: active ? AppTheme.orange : AppTheme.textLight,
                  fontWeight:
                      active ? FontWeight.w700 : FontWeight.w500)),
        ]),
      ),
    );
