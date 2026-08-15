import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
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
        setState(() {
          isLoading = false;
          error = 'Not logged in';
        });
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
          setState(() {
            isLoading = false;
            error = 'No roadmap found.';
          });
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        error = 'Error: $e';
      });
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

  void _showToast(String msg, bool celebration) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor:
            celebration ? const Color(0xFFFF5722) : const Color(0xFF00B894),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doneWeeks = weeks.where((w) => w['status'] == 'done').length;
    final totalWeeks = weeks.isEmpty ? 8 : weeks.length;
    final progress = totalWeeks > 0 ? doneWeeks / totalWeeks : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF111322),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Container(
              color: const Color(0xFFF8F9FE),
              child: Stack(
                children: [
                  Column(
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
                          22,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => context.go('/home'),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: Colors.white,
                                      size: 16,
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
                                        widget.track,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        '$totalWeeks Weeks · AI Generated',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          color: const Color(0xFFB3B0D6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.go('/track'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF5722)
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFFF5722)
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      'Switch Track',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFFF8A65),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$doneWeeks of $totalWeeks completed',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFD4C9FF),
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
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
                                backgroundColor: Colors.white12,
                                valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFFFF5722),
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Weeks Timeline Stream
                      Expanded(
                        child: isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFF5722),
                                ),
                              )
                            : error != null
                                ? Center(
                                    child: Text(
                                      error!,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFF6B6890),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 16, 16, 20),
                                    itemCount: weeks.length,
                                    itemBuilder: (ctx, i) {
                                      final w = weeks[i];
                                      final isDone = w['status'] == 'done';
                                      final isCurrent =
                                          i == doneWeeks && !isDone;
                                      return _TimelineWeekCard(
                                        index: i,
                                        week: w,
                                        isDone: isDone,
                                        isCurrent: isCurrent,
                                        isLast: i == weeks.length - 1,
                                        onMarkDone: () => _markWeekDone(i),
                                        onUnmark: () => _unmarkWeekDone(i),
                                        onInterview: () => context.go(
                                          '/interview?track=${Uri.encodeComponent(widget.track)}&week=${Uri.encodeComponent(w['title'] ?? 'Week ${i + 1}')}',
                                        ),
                                      );
                                    },
                                  ),
                      ),

                      // Bottom Navigation Bar (Strictly 4 icons)
                      _BottomNav(
                        currentIndex: 1,
                        onHome: () => context.go('/home'),
                        onRoadmap: () => context.go(
                            '/roadmap?track=${Uri.encodeComponent(widget.track)}'),
                        onResources: () => context.go('/resources'),
                        onProfile: () => context.go('/profile'),
                      ),
                    ],
                  ),

                  // Confetti Celebration
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality:
                          BlastDirectionality.explosive,
                      shouldLoop: false,
                      colors: const [
                        Color(0xFFFF5722),
                        Color(0xFF7C5CBF),
                        Color(0xFF00B894),
                        Color(0xFFFFB800),
                      ],
                    ),
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

// ── Timeline Card Component ───────────────────────────────────────

class _TimelineWeekCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> week;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;
  final VoidCallback onMarkDone;
  final VoidCallback onUnmark;
  final VoidCallback onInterview;

  const _TimelineWeekCard({
    required this.index,
    required this.week,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
    required this.onMarkDone,
    required this.onUnmark,
    required this.onInterview,
  });

  @override
  Widget build(BuildContext context) {
    final title = week['title'] ?? 'Week ${index + 1}';
    final hours = week['hours'] ?? '10';
    final skills = week['skills'] as List? ?? [];
    final why = week['why'] ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vertical Timeline Spine & Badge
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? const Color(0xFF00B894)
                    : isCurrent
                        ? const Color(0xFFFF5722)
                        : Colors.white,
                border: Border.all(
                  color: isDone
                      ? const Color(0xFF00B894)
                      : isCurrent
                          ? const Color(0xFFFF5722)
                          : const Color(0xFFE2E4F0),
                  width: 2,
                ),
                boxShadow: [
                  if (isCurrent)
                    BoxShadow(
                      color: const Color(0xFFFF5722).withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                ],
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 20)
                    : Text(
                        isCurrent ? 'NOW' : '${index + 1}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isCurrent ? 9.5 : 12.5,
                          fontWeight: FontWeight.w800,
                          color: isCurrent
                              ? Colors.white
                              : const Color(0xFF6B6890),
                        ),
                      ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2.5,
                height: 120,
                color: isDone
                    ? const Color(0xFF00B894)
                    : const Color(0xFFE2E4F0),
              ),
          ],
        ),
        const SizedBox(width: 14),

        // Main Card
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isCurrent
                    ? const Color(0xFFFF5722)
                    : const Color(0xFFE2E4F0),
                width: isCurrent ? 1.8 : 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isCurrent
                      ? const Color(0xFFFF5722).withOpacity(0.08)
                      : Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'WEEK ${index + 1}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: isCurrent
                                  ? const Color(0xFFFF5722)
                                  : isDone
                                      ? const Color(0xFF00B894)
                                      : const Color(0xFF7C5CBF),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  size: 13, color: Color(0xFF9B99B5)),
                              const SizedBox(width: 4),
                              Text(
                                '$hours hrs',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: const Color(0xFF9B99B5),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Skills Chips
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: skills.map((s) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6FA),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFFE2E4F0)),
                            ),
                            child: Text(
                              s.toString(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4D3B82),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      if (why.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          why,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: const Color(0xFF6B6890),
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Card Action Buttons
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFF0F1F7)),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Mark Done / Undo Button
                      Expanded(
                        child: GestureDetector(
                          onTap: isDone ? onUnmark : onMarkDone,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: isDone
                                  ? const Color(0xFFE8F8F0)
                                  : isCurrent
                                      ? const Color(0xFFFF5722)
                                      : Colors.transparent,
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
                                      ? const Color(0xFF00875A)
                                      : isCurrent
                                          ? Colors.white
                                          : const Color(0xFF1A1A2E),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isDone ? 'Undo' : 'Mark done',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDone
                                        ? const Color(0xFF00875A)
                                        : isCurrent
                                            ? Colors.white
                                            : const Color(0xFF1A1A2E),
                                  ),
                                ),
                                if (!isDone) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: isCurrent
                                          ? Colors.white24
                                          : const Color(0xFFFF5722)
                                              .withOpacity(0.12),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '+80 XP',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: isCurrent
                                            ? Colors.white
                                            : const Color(0xFFFF5722),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Practice Button
                      GestureDetector(
                        onTap: onInterview,
                        child: Container(
                          width: 100,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF5F3FF),
                            border: Border(
                              left: BorderSide(color: Color(0xFFF0F1F7)),
                            ),
                            borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.quiz_rounded,
                                  size: 14, color: Color(0xFF7C5CBF)),
                              const SizedBox(width: 5),
                              Text(
                                'Practice',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF7C5CBF),
                                ),
                              ),
                            ],
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
      ],
    );
  }
}

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
