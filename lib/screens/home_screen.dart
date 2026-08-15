import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../core/theme.dart';
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = '';
  Map<String, dynamic>? userData;
  Map<String, dynamic>? roadmapData;
  int xp = 0;
  int level = 1;
  String levelName = 'Code Newcomer';
  int streak = 0;
  int myRank = 0;
  List<bool> weekActivity = List.filled(7, false);
  List<Map<String, dynamic>> topUsers = [];
  String aiInsight = '';
  bool aiLoading = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEverything();
  }

  Future<void> _loadEverything() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }
    final uid = user.uid;
    try {
      final newStreak = await FirestoreService.updateStreak(uid: uid);
      await FirestoreService.logActiveDay(uid: uid);
      final activity = await FirestoreService.getWeekActivity(uid: uid);
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final uData = userDoc.data() ?? {};
      final roadmapSnap = await FirebaseFirestore.instance
          .collection('roadmaps')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      final rData =
          roadmapSnap.docs.isNotEmpty ? roadmapSnap.docs.first.data() : null;
      final lb = await FirestoreService.getLeaderboard(currentUid: uid);
      if (mounted) {
        setState(() {
          userName =
              uData['name'] ?? user.email?.split('@')[0] ?? 'Student';
          userData = uData;
          roadmapData = rData;
          xp = (uData['xp'] ?? 0) as int;
          level = (uData['level'] ?? 1) as int;
          levelName = uData['levelName'] ?? 'Code Newcomer';
          streak = newStreak;
          weekActivity = activity;
          topUsers = List<Map<String, dynamic>>.from(lb['topUsers'] ?? []);
          myRank = (lb['currentUserRank'] ?? 0) as int;
          isLoading = false;
        });
      }
      _loadAiCoach(uData, rData);
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loadAiCoach(
      Map<String, dynamic> uData, Map<String, dynamic>? rData) async {
    final weeks = rData?['weeks'] as List? ?? [];
    final doneWeeks = weeks.where((w) => w['status'] == 'done').length;
    final insight = await GeminiService.getCoachInsight(
      userName: userName,
      track: rData?['track'] ?? '',
      doneWeeks: doneWeeks,
      totalWeeks: weeks.length,
      streak: streak,
      xp: xp,
      goal: uData['goal'] ?? 'Get a job',
      experience: uData['experience'] ?? 'Beginner',
    );
    if (mounted) {
      setState(() {
        aiInsight = insight;
        aiLoading = false;
      });
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  int get _xpForCurrentLevel => (level - 1) * 500;
  int get _xpForNextLevel => level * 500;
  double get _xpProgress {
    final range = _xpForNextLevel - _xpForCurrentLevel;
    final current = xp - _xpForCurrentLevel;
    return (current / range).clamp(0.0, 1.0);
  }

  void _openQuickAssistantSheet(String track, int doneCount, int totalWeeks) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickAssistantSheet(
        userName: userName,
        track: track,
        doneWeeks: doneCount,
        totalWeeks: totalWeeks,
        xp: xp,
        streak: streak,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weeks = roadmapData?['weeks'] as List? ?? [];
    final doneCount = weeks.where((w) => w['status'] == 'done').length;
    final totalWeeks = weeks.isEmpty ? 8 : weeks.length;
    final progress = totalWeeks > 0 ? doneCount / totalWeeks : 0.0;
    final track = roadmapData?['track'] ?? 'Data Analyst';
    final currentWeek = weeks.isNotEmpty
        ? weeks.firstWhere((w) => w['status'] != 'done',
            orElse: () => weeks.last)
        : {};

    return Scaffold(
      backgroundColor: const Color(0xFF111322),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Container(
              color: const Color(0xFFF8F9FE),
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF5722),
                      ),
                    )
                  : Stack(
                      children: [
                        Column(
                          children: [
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: _loadEverything,
                                color: const Color(0xFFFF5722),
                                child: SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          MediaQuery.of(context).padding.top +
                                              16,
                                          20,
                                          22,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      _greeting,
                                                      style: GoogleFonts
                                                          .plusJakartaSans(
                                                        fontSize: 13,
                                                        color: const Color(
                                                            0xFFB3B0D6),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      userName,
                                                      style: GoogleFonts
                                                          .plusJakartaSans(
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                GestureDetector(
                                                  onTap: () =>
                                                      context.go('/profile'),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 9,
                                                          vertical: 4,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: const Color(
                                                                  0xFFFF5722)
                                                              .withOpacity(
                                                                  0.18),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      12),
                                                          border: Border.all(
                                                            color: const Color(
                                                                    0xFFFF5722)
                                                                .withOpacity(
                                                                    0.4),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          'Lv.$level',
                                                          style: GoogleFonts
                                                              .plusJakartaSans(
                                                            fontSize: 11.5,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: const Color(
                                                                0xFFFF8A65),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration:
                                                            BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          gradient:
                                                              const LinearGradient(
                                                            colors: [
                                                              Color(0xFFFF5722),
                                                              Color(0xFF7C5CBF),
                                                            ],
                                                          ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: const Color(
                                                                      0xFFFF5722)
                                                                  .withOpacity(
                                                                      0.3),
                                                              blurRadius: 8,
                                                            ),
                                                          ],
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            userName.isNotEmpty
                                                                ? userName[0]
                                                                    .toUpperCase()
                                                                : 'S',
                                                            style: GoogleFonts
                                                                .plusJakartaSans(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 14),

                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  levelName,
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(
                                                        0xFFD4C9FF),
                                                  ),
                                                ),
                                                Text(
                                                  '$xp / $_xpForNextLevel XP',
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(
                                                        0xFFB3B0D6),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: LinearProgressIndicator(
                                                value: _xpProgress,
                                                backgroundColor:
                                                    Colors.white12,
                                                valueColor:
                                                    const AlwaysStoppedAnimation(
                                                  Color(0xFFFF5722),
                                                ),
                                                minHeight: 5,
                                              ),
                                            ),
                                            const SizedBox(height: 16),

                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _StatPill(
                                                    icon: Icons
                                                        .local_fire_department_rounded,
                                                    label: '$streak',
                                                    sub: 'Streak',
                                                    color:
                                                        const Color(0xFFFF5722),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: _StatPill(
                                                    icon: Icons
                                                        .check_circle_rounded,
                                                    label: '$doneCount',
                                                    sub: 'Weeks done',
                                                    color:
                                                        const Color(0xFF00B894),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: _StatPill(
                                                    icon: Icons
                                                        .leaderboard_rounded,
                                                    label: myRank > 0
                                                        ? '#$myRank'
                                                        : '#4',
                                                    sub: 'Rank',
                                                    color:
                                                        const Color(0xFFFFB800),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Quick Actions
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 12, 16, 6),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: _ActionButton(
                                                icon: Icons.share_rounded,
                                                label: 'Share progress',
                                                bg: const Color(0xFF1B1D36),
                                                fg: Colors.white,
                                                onTap: () => context
                                                    .go('/share-progress'),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: _ActionButton(
                                                icon: Icons.mic_rounded,
                                                label: 'Practice Interview',
                                                bg: const Color(0xFFF0EDF8),
                                                fg: const Color(0xFF7C5CBF),
                                                onTap: () =>
                                                    context.go('/interview'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Active Quest Card
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 10, 16, 6),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Active quest',
                                              style: GoogleFonts
                                                  .plusJakartaSans(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF1A1A2E),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1B1D36),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        const Color(0xFF1B1D36)
                                                            .withOpacity(0.12),
                                                    blurRadius: 10,
                                                    offset:
                                                        const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: const Color(
                                                                  0xFFFF5722)
                                                              .withOpacity(0.2),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: const Icon(
                                                          Icons
                                                              .bar_chart_rounded,
                                                          color:
                                                              Color(0xFFFF5722),
                                                          size: 22,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              track,
                                                              style: GoogleFonts
                                                                  .plusJakartaSans(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                            Text(
                                                              'Week $doneCount of $totalWeeks · In progress',
                                                              style:
                                                                  GoogleFonts
                                                                      .plusJakartaSans(
                                                                fontSize: 12,
                                                                color: const Color(
                                                                    0xFFB3B0D6),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: const Color(
                                                                  0xFFFF5722)
                                                              .withOpacity(0.2),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Text(
                                                          '${(progress * 100).toInt()}%',
                                                          style: GoogleFonts
                                                              .plusJakartaSans(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: const Color(
                                                                0xFFFF5722),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 14),
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    child:
                                                        LinearProgressIndicator(
                                                      value: progress,
                                                      backgroundColor:
                                                          Colors.white12,
                                                      valueColor:
                                                          const AlwaysStoppedAnimation(
                                                        Color(0xFFFF5722),
                                                      ),
                                                      minHeight: 4.5,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          'Now: ${currentWeek['title'] ?? 'Fundamentals'}',
                                                          style: GoogleFonts
                                                              .plusJakartaSans(
                                                            fontSize: 12,
                                                            color: const Color(
                                                                0xFFD4C9FF),
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      GestureDetector(
                                                        onTap: () => context.go(
                                                            '/roadmap?track=${Uri.encodeComponent(track)}'),
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 12,
                                                            vertical: 6,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: const Color(
                                                                0xFFFF5722),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                          child: Text(
                                                            'Continue',
                                                            style: GoogleFonts
                                                                .plusJakartaSans(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Roadmap Scroller
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 12, 16, 6),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Your roadmap',
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        const Color(0xFF1A1A2E),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () => context.go(
                                                      '/roadmap?track=${Uri.encodeComponent(track)}'),
                                                  child: Text(
                                                    'Full view',
                                                    style: GoogleFonts
                                                        .plusJakartaSans(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: const Color(
                                                          0xFF7C5CBF),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            SizedBox(
                                              height: 95,
                                              child: ListView.builder(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                itemCount: weeks.isNotEmpty
                                                    ? weeks.length
                                                    : 8,
                                                itemBuilder: (ctx, i) {
                                                  final w = i < weeks.length
                                                      ? weeks[i]
                                                      : {
                                                          'week': i + 1,
                                                          'title':
                                                              'Week ${i + 1}',
                                                          'status': i == 0
                                                              ? 'now'
                                                              : 'locked'
                                                        };
                                                  final isCurrent =
                                                      i == doneCount;
                                                  return Container(
                                                    width: 88,
                                                    margin:
                                                        const EdgeInsets.only(
                                                            right: 8),
                                                    padding:
                                                        const EdgeInsets.all(
                                                            10),
                                                    decoration: BoxDecoration(
                                                      color: isCurrent
                                                          ? const Color(
                                                              0xFFFF5722)
                                                          : Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                      border: Border.all(
                                                        color: isCurrent
                                                            ? const Color(
                                                                0xFFFF5722)
                                                            : const Color(
                                                                0xFFE2E4F0),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          isCurrent
                                                              ? 'NOW'
                                                              : 'WK ${i + 1}',
                                                          style: GoogleFonts
                                                              .plusJakartaSans(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: isCurrent
                                                                ? Colors.white
                                                                : const Color(
                                                                    0xFF9B99B5),
                                                          ),
                                                        ),
                                                        Text(
                                                          w['title'] ?? 'Topic',
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: GoogleFonts
                                                              .plusJakartaSans(
                                                            fontSize: 10.5,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: isCurrent
                                                                ? Colors.white
                                                                : const Color(
                                                                    0xFF1A1A2E),
                                                          ),
                                                        ),
                                                        Text(
                                                          '${w['hours'] ?? '10'} hrs',
                                                          style: GoogleFonts
                                                              .plusJakartaSans(
                                                            fontSize: 9.5,
                                                            color: isCurrent
                                                                ? Colors.white70
                                                                : const Color(
                                                                    0xFF9B99B5),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // AI Features Hub
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 12, 16, 6),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _FeatureCard(
                                              title: 'AI Mentor',
                                              subtitle:
                                                  'Remembers your journey • Multi-turn LLM',
                                              badge: 'Online',
                                              badgeColor:
                                                  const Color(0xFF00B894),
                                              icon: Icons.smart_toy_rounded,
                                              iconBg: const Color(0xFF00B894),
                                              onTap: () =>
                                                  context.go('/mentor'),
                                            ),
                                            const SizedBox(height: 10),
                                            _FeatureCard(
                                              title: 'Job Market Analyser',
                                              subtitle:
                                                  'Real-time demand, salary & trending skills',
                                              badge: 'Agentic AI',
                                              badgeColor:
                                                  const Color(0xFF7C5CBF),
                                              icon: Icons.trending_up_rounded,
                                              iconBg: const Color(0xFFE8F5E9),
                                              iconColor:
                                                  const Color(0xFF2E7D32),
                                              cardBg: const Color(0xFFF1F8E9),
                                              onTap: () =>
                                                  context.go('/market'),
                                            ),
                                            const SizedBox(height: 10),
                                            _FeatureCard(
                                              title: 'AI Resume Rewriter',
                                              subtitle:
                                                  'Paste any job → AI rewrites your resume',
                                              badge: 'Agentic AI',
                                              badgeColor:
                                                  const Color(0xFFFF5722),
                                              icon: Icons.auto_fix_high_rounded,
                                              iconBg: const Color(0xFFFF5722),
                                              cardBg: const Color(0xFF1B1D36),
                                              isDark: true,
                                              onTap: () =>
                                                  context.go('/rewriter'),
                                            ),
                                            const SizedBox(height: 10),
                                            _FeatureCard(
                                              title: 'Scan your resume',
                                              subtitle:
                                                  'Find skill gaps for your track',
                                              badge: 'New',
                                              badgeColor:
                                                  const Color(0xFF7C5CBF),
                                              icon: Icons
                                                  .document_scanner_rounded,
                                              iconBg: const Color(0xFFF5F3FF),
                                              iconColor:
                                                  const Color(0xFF7C5CBF),
                                              onTap: () =>
                                                  context.go('/resume'),
                                            ),
                                            const SizedBox(height: 10),
                                            _JobReadinessCard(
                                              onTap: () =>
                                                  context.go('/readiness'),
                                            ),
                                          ],
                                        ),
                                      ),

                                      if (aiInsight.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              16, 10, 16, 6),
                                          child: Container(
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE8F8F0),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: const Color(0xFFB7E8CE),
                                              ),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF00B894),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: const Icon(
                                                    Icons.auto_awesome,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'AI coach · live',
                                                        style: GoogleFonts
                                                            .plusJakartaSans(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: const Color(
                                                              0xFF00875A),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        aiInsight,
                                                        style: GoogleFonts
                                                            .plusJakartaSans(
                                                          fontSize: 12.5,
                                                          color: const Color(
                                                              0xFF1A1A2E),
                                                          height: 1.4,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 12, 16, 6),
                                        child: _LeaderboardCard(
                                          topUsers: topUsers,
                                          myRank: myRank,
                                          myXP: xp,
                                        ),
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 10, 16, 6),
                                        child: _StreakCard(
                                          streak: streak,
                                          weekActivity: weekActivity,
                                        ),
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 12, 16, 24),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Explore tracks',
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        const Color(0xFF1A1A2E),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () =>
                                                      context.go('/track'),
                                                  child: Text(
                                                    'See all',
                                                    style: GoogleFonts
                                                        .plusJakartaSans(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: const Color(
                                                          0xFF7C5CBF),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            _TracksScroll(
                                              onTrackTap: () =>
                                                  context.go('/track'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            _BottomNav(
                              currentIndex: 0,
                              onHome: () => context.go('/home'),
                              onRoadmap: () => context.go(
                                  '/roadmap?track=${Uri.encodeComponent(track)}'),
                              onResources: () => context.go('/resources'),
                              onProfile: () => context.go('/profile'),
                            ),
                          ],
                        ),

                        // Floating AI Quick-Assistant Robot Button (Right above bottom nav)
                        Positioned(
                          right: 18,
                          bottom: 68,
                          child: GestureDetector(
                            onTap: () => _openQuickAssistantSheet(
                                track, doneCount, totalWeeks),
                            child: Container(
                              width: 56,
                              height: 56,
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
                                        .withOpacity(0.4),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(2.5),
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF1B1D36),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/robot-for-chatbot.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(
                                      Icons.smart_toy_rounded,
                                      color: Color(0xFFFF5722),
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                            ),
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

// ── Quick Assistant Modal Bottom Sheet ──────────────────────────────

class _QuickAssistantSheet extends StatefulWidget {
  final String userName;
  final String track;
  final int doneWeeks;
  final int totalWeeks;
  final int xp;
  final int streak;

  const _QuickAssistantSheet({
    required this.userName,
    required this.track,
    required this.doneWeeks,
    required this.totalWeeks,
    required this.xp,
    required this.streak,
  });

  @override
  State<_QuickAssistantSheet> createState() => _QuickAssistantSheetState();
}

class _QuickAssistantSheetState extends State<_QuickAssistantSheet> {
  String? selectedQuestion;
  String? aiAnswer;
  bool isThinking = false;

  final questions = [
    '🎯 What is my #1 priority this week?',
    '⚡ How do I boost my Job Readiness Score?',
    '💡 Recommend a portfolio project',
    '🔥 Give me a 5-minute coding challenge',
  ];

  void _ask(String q) async {
    setState(() {
      selectedQuestion = q;
      isThinking = true;
      aiAnswer = null;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    String reply;
    if (q.contains('priority')) {
      reply =
          'Focus on completing Week ${widget.doneWeeks + 1} of ${widget.track}. Allocate 60 mins today to build the core mini-project and earn +80 XP!';
    } else if (q.contains('Job Readiness')) {
      reply =
          'Your score increases fastest by: 1) Marking week roadmap goals done (+15 pts), 2) Scanning your updated resume in Resume Scanner, and 3) Completing 1 AI Mock Interview!';
    } else if (q.contains('portfolio project')) {
      reply =
          'Build a "${widget.track} Real-Time Analytics Dashboard" with live charts, search filters, and deploy it to GitHub. This proves real-world skills to recruiters!';
    } else {
      reply =
          'Today\'s Challenge: Write a function to check if two strings are anagrams in O(n) time using a hash map. Test with "listen" & "silent"!';
    }

    if (mounted) {
      setState(() {
        isThinking = false;
        aiAnswer = reply;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7C5CBF).withOpacity(0.12),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/robot-for-chatbot.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.smart_toy_rounded,
                      color: Color(0xFF7C5CBF),
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Quick Assistant',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    'Instant insights for ${widget.track}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: const Color(0xFF6B6890),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded,
                    color: Color(0xFF9B99B5), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4 Predefined Questions
          ...questions.map((q) {
            final isSelected = selectedQuestion == q;
            return GestureDetector(
              onTap: () => _ask(q),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFFF3EE)
                      : const Color(0xFFF8F9FE),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFF5722)
                        : const Color(0xFFE2E4F0),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        q,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFFFF5722)
                              : const Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: isSelected
                          ? const Color(0xFFFF5722)
                          : const Color(0xFF9B99B5),
                    ),
                  ],
                ),
              ),
            );
          }),

          // AI Answer Display Card
          if (isThinking || aiAnswer != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1D36),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: Color(0xFFFF8A65), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'AI Mentor Reply:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFF8A65),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (isThinking)
                    const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF5722),
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Synthesizing personalized advice...',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    )
                  else
                    Text(
                      aiAnswer!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.white,
                        height: 1.45,
                      ),
                    ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/mentor');
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Open Full Chat →',
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
            ),
          ],
        ],
      ),
    );
  }
}

// ── Components ────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  const _StatPill(
      {required this.icon,
      required this.label,
      required this.sub,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              color: const Color(0xFFB3B0D6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.bg,
      required this.fg,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: bg.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final IconData icon;
  final Color iconBg;
  final Color? iconColor;
  final Color? cardBg;
  final bool isDark;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.icon,
    required this.iconBg,
    this.iconColor,
    this.cardBg,
    this.isDark = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg ?? Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.transparent : const Color(0xFFE2E4F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
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
              child: Icon(
                icon,
                color: iconColor ?? Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: isDark
                          ? const Color(0xFFB3B0D6)
                          : const Color(0xFF6B6890),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white54 : const Color(0xFF9B99B5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _JobReadinessCard extends StatelessWidget {
  final VoidCallback onTap;
  const _JobReadinessCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1D36),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFFF5722),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '0',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Job Readiness Score',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Getting Started · Tap to see breakdown',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: const Color(0xFFB3B0D6),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5722),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'View',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  final List<Map<String, dynamic>> topUsers;
  final int myRank;
  final int myXP;
  const _LeaderboardCard(
      {required this.topUsers, required this.myRank, required this.myXP});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E4F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Leaderboard',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              const Icon(Icons.workspace_premium_rounded,
                  color: Color(0xFFFFB800), size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🥇', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    'Sarthak',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
              Text(
                '400 XP',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF7C5CBF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int streak;
  final List<bool> weekActivity;
  const _StreakCard({required this.streak, required this.weekActivity});

  @override
  Widget build(BuildContext context) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday - 1;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE5A3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "This week — don't break it!",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      color: Color(0xFFFF5722), size: 16),
                  const SizedBox(width: 3),
                  Text(
                    '$streak days',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFFF5722),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final isActive =
                  i == today || (i < weekActivity.length && weekActivity[i]);
              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFFF5722) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFFFF5722)
                        : const Color(0xFFFFE5A3),
                  ),
                ),
                child: Center(
                  child: Text(
                    days[i],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : const Color(0xFF9B99B5),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TracksScroll extends StatelessWidget {
  final VoidCallback onTrackTap;
  const _TracksScroll({required this.onTrackTap});

  @override
  Widget build(BuildContext context) {
    final tracks = [
      {
        'icon': Icons.bar_chart_rounded,
        'name': 'Data Science',
        'dur': '16 wks',
        'color': const Color(0xFF7C5CBF)
      },
      {
        'icon': Icons.psychology_rounded,
        'name': 'AI Engineer',
        'dur': '24 wks',
        'color': const Color(0xFFFF5722)
      },
      {
        'icon': Icons.code_rounded,
        'name': 'Full Stack',
        'dur': '24 wks',
        'color': const Color(0xFF00B894)
      },
      {
        'icon': Icons.phone_android_rounded,
        'name': 'Mobile Dev',
        'dur': '20 wks',
        'color': const Color(0xFF1565C0)
      },
      {
        'icon': Icons.security_rounded,
        'name': 'Cybersec',
        'dur': '20 wks',
        'color': const Color(0xFFC62828)
      },
    ];
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tracks.length,
        itemBuilder: (context, i) {
          final t = tracks[i];
          final color = t['color'] as Color;
          return GestureDetector(
            onTap: onTrackTap,
            child: Container(
              width: 90,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E4F0)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(t['icon'] as IconData, color: color, size: 20),
                  const SizedBox(height: 5),
                  Text(
                    t['name'] as String,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    t['dur'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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
