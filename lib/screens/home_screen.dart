import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    if (user == null) { setState(() => isLoading = false); return; }
    final uid = user.uid;
    try {
      final newStreak = await FirestoreService.updateStreak(uid: uid);
      await FirestoreService.logActiveDay(uid: uid);
      final activity = await FirestoreService.getWeekActivity(uid: uid);
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(uid).get();
      final uData = userDoc.data() ?? {};
      final roadmapSnap = await FirebaseFirestore.instance
          .collection('roadmaps')
          .where('uid', isEqualTo: uid)
          .limit(1).get();
      final rData = roadmapSnap.docs.isNotEmpty
          ? roadmapSnap.docs.first.data() : null;
      final lb = await FirestoreService.getLeaderboard(currentUid: uid);
      if (mounted) {
        setState(() {
          userName = uData['name'] ?? user.email?.split('@')[0] ?? 'Student';
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
    if (mounted) setState(() { aiInsight = insight; aiLoading = false; });
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

  @override
  Widget build(BuildContext context) {
    final weeks = roadmapData?['weeks'] as List? ?? [];
    final doneCount = weeks.where((w) => w['status'] == 'done').length;
    final totalWeeks = weeks.length;
    final progress = totalWeeks > 0 ? doneCount / totalWeeks : 0.0;
    final track = roadmapData?['track'] ?? '';
    final currentWeek = weeks.isNotEmpty
        ? weeks.firstWhere((w) => w['status'] != 'done',
            orElse: () => weeks.last)
        : {};

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.orange))
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadEverything,
                color: AppTheme.orange,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Hero band
                      Container(
                        color: AppTheme.navy,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_greeting,
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12, color: Colors.white60)),
                                  const SizedBox(height: 2),
                                  Text(userName,
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white)),
                                ],
                              )),
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: AppTheme.orange.withOpacity(0.5)),
                                  ),
                                  child: Text('Lv.$level',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.orange)),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () => context.go('/profile'),
                                  child: Container(
                                    width: 42, height: 42,
                                    decoration: BoxDecoration(
                                      color: AppTheme.orange,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(child: Text(
                                      userName.isNotEmpty
                                          ? userName[0].toUpperCase() : 'S',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white))),
                                  ),
                                ),
                              ]),
                            ]),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(levelName,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11, color: Colors.white60)),
                                Text('$xp / $_xpForNextLevel XP',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.orange)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: _xpProgress),
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.easeOut,
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
                            const SizedBox(height: 20),
                            Row(children: [
                              _StatChip(
                                icon: Icons.local_fire_department_rounded,
                                iconColor: AppTheme.orange,
                                value: '$streak',
                                label: 'Streak',
                                bg: AppTheme.orange.withOpacity(0.15),
                              ),
                              const SizedBox(width: 10),
                              _StatChip(
                                icon: Icons.check_circle_rounded,
                                iconColor: AppTheme.green,
                                value: '$doneCount',
                                label: 'Weeks done',
                                bg: AppTheme.green.withOpacity(0.15),
                              ),
                              const SizedBox(width: 10),
                              _StatChip(
                                icon: Icons.leaderboard_rounded,
                                iconColor: Colors.amber,
                                value: myRank > 0 ? '#$myRank' : '--',
                                label: 'Rank',
                                bg: Colors.amber.withOpacity(0.15),
                              ),
                            ]),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // Share + Interview buttons
                            Row(children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => context.go('/share'),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppTheme.navy,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.share_rounded,
                                            color: Colors.white, size: 18),
                                        const SizedBox(width: 8),
                                        Text('Share progress',
                                            style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => track.isNotEmpty
                                      ? context.go(
                                          '/interview?track=${Uri.encodeComponent(track)}&week=Week%201')
                                      : context.go('/track'),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppTheme.purpleLight,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: AppTheme.purpleBorder),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.quiz_rounded,
                                            color: AppTheme.primary, size: 18),
                                        const SizedBox(width: 8),
                                        Text('Practice interview',
                                            style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.primary)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 24),

                            // Active Quest
                            _sectionRow('Active quest', null),
                            const SizedBox(height: 10),
                            roadmapData != null
                                ? _QuestCard(
                                    track: track,
                                    doneCount: doneCount,
                                    totalWeeks: totalWeeks,
                                    progress: progress,
                                    currentWeekTitle:
                                        currentWeek['title'] ?? '',
                                    onTap: () => context.go(
                                        '/roadmap?track=${Uri.encodeComponent(track)}'),
                                  )
                                : _NoQuestCard(
                                    onTap: () => context.go('/onboarding')),
                            const SizedBox(height: 24),

                            // Roadmap scroll
                            if (weeks.isNotEmpty) ...[
                              _sectionRow('Your roadmap', 'Full view',
                                  onTap: () => context.go(
                                      '/roadmap?track=${Uri.encodeComponent(track)}')),
                              const SizedBox(height: 10),
                              _WeeksScroll(weeks: weeks),
                              const SizedBox(height: 24),
                            ],

                            // AI Mentor card
                          _sectionRow('AI mentor', 'Chat now',
                              onTap: () => context.go('/mentor')),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => context.go('/mentor'),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppTheme.greenBorder),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: AppTheme.green,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.psychology_rounded,
                                      color: Colors.white, size: 26),
                                ),
                                const SizedBox(width: 14),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Text('AI Mentor',
                                          style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.textDark)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppTheme.green.withOpacity(0.3)),
                                        ),
                                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                                          Container(width: 5, height: 5,
                                              decoration: BoxDecoration(
                                                  color: AppTheme.green,
                                                  shape: BoxShape.circle)),
                                          const SizedBox(width: 4),
                                          Text('Online',
                                              style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme.green)),
                                        ]),
                                      ),
                                    ]),
                                    Text('Remembers your journey · Multi-turn LLM',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12, color: AppTheme.textMid)),
                                  ],
                                )),
                                Icon(Icons.arrow_forward_ios_rounded,
                                    color: AppTheme.textLight, size: 14),
                              ]),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Job Market Analyser card
                          _sectionRow('Job market analysis', 'View',
                              onTap: () => context.go('/market')),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => context.go('/market'),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.greenLight,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppTheme.greenBorder),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: AppTheme.green.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(Icons.trending_up_rounded,
                                      color: AppTheme.green, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Text('Job Market Analyser',
                                          style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.green)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.green.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppTheme.green.withOpacity(0.4)),
                                        ),
                                        child: Text('Agentic AI',
                                            style: GoogleFonts.plusJakartaSans(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.green)),
                                      ),
                                    ]),
                                    Text('Real-time demand, salary & trending skills',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12, color: AppTheme.green.withOpacity(0.7))),
                                  ],
                                )),
                                Icon(Icons.arrow_forward_ios_rounded,
                                    color: AppTheme.green.withOpacity(0.5), size: 14),
                              ]),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // AI Resume Rewriter card
                          _sectionRow('AI resume rewriter', 'Try it',
                              onTap: () => context.go('/rewriter')),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => context.go('/rewriter'),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.navy,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: AppTheme.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(Icons.auto_fix_high_rounded,
                                      color: AppTheme.orange, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Text('AI Resume Rewriter',
                                          style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.orange.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppTheme.orange.withOpacity(0.4)),
                                        ),
                                        child: Text('Agentic AI',
                                            style: GoogleFonts.plusJakartaSans(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.orange)),
                                      ),
                                    ]),
                                    Text('Paste any job → AI rewrites your resume',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12, color: Colors.white54)),
                                  ],
                                )),
                                Icon(Icons.arrow_forward_ios_rounded,
                                    color: Colors.white38, size: 14),
                              ]),
                            ),
                          ),
                          const SizedBox(height: 24),

                          
                          // Resume Scanner
                            _sectionRow('Resume scanner', 'Try it',
                                onTap: () => context.go('/resume')),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => context.go('/resume'),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Row(children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(
                                      color: AppTheme.purpleLight,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                        Icons.document_scanner_rounded,
                                        color: AppTheme.primary, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Scan your resume',
                                          style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.textDark)),
                                      Text('Find skill gaps for your track',
                                          style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              color: AppTheme.textMid)),
                                    ],
                                  )),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text('New',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white)),
                                  ),
                                ]),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Job Readiness Score
                            _sectionRow('Job readiness', 'View details',
                                onTap: () => context.go('/readiness')),
                            const SizedBox(height: 10),
                            _JobReadinessCard(
                              score: (userData?['jobReadinessScore'] ?? 0) as int,
                              label: userData?['jobReadinessLabel']?.toString() ?? 'Getting Started',
                              onTap: () => context.go('/readiness'),
                            ),
                            const SizedBox(height: 24),

                            // AI Coach
                            _sectionRow('AI coach', null),
                            const SizedBox(height: 10),
                            _AiCoachCard(
                                insight: aiInsight, isLoading: aiLoading),
                            const SizedBox(height: 24),

                            // Leaderboard
                            if (topUsers.isNotEmpty) ...[
                              _sectionRow('Leaderboard', null),
                              const SizedBox(height: 10),
                              _LeaderboardCard(
                                topUsers: topUsers,
                                myRank: myRank,
                                currentUid: FirebaseAuth
                                        .instance.currentUser?.uid ??
                                    '',
                                myXP: xp,
                                myName: userName,
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Streak
                            _sectionRow('Streak tracker', null),
                            const SizedBox(height: 10),
                            _StreakCard(
                                streak: streak, weekActivity: weekActivity),
                            const SizedBox(height: 24),

                            // Explore tracks
                            _sectionRow('Explore tracks', 'See all',
                                onTap: () => context.go('/track')),
                            const SizedBox(height: 10),
                            _TracksScroll(
                                onTrackTap: () => context.go('/track')),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: _BottomNav(
        currentIndex: 0,
        onHome: () {},
        onRoadmap: () => track.isNotEmpty
            ? context.go(
                '/roadmap?track=${Uri.encodeComponent(track)}')
            : context.go('/track'),
        onResources: () => context.go('/resources'),
        onProfile: () => context.go('/profile'),
      ),
    );
  }

  Widget _sectionRow(String title, String? action, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark)),
        if (action != null)
          GestureDetector(
            onTap: onTap,
            child: Text(action,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary)),
          ),
      ],
    );
  }
}

// ─── Stat Chip ────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor, bg;
  final String value, label;
  const _StatChip({required this.icon, required this.iconColor,
      required this.value, required this.label, required this.bg});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.plusJakartaSans(
            fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
        Text(label, style: GoogleFonts.plusJakartaSans(
            fontSize: 9, color: Colors.white70, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

// ─── Quest Card ───────────────────────────────────────────────────
class _QuestCard extends StatelessWidget {
  final String track, currentWeekTitle;
  final int doneCount, totalWeeks;
  final double progress;
  final VoidCallback onTap;
  const _QuestCard({required this.track, required this.currentWeekTitle,
      required this.doneCount, required this.totalWeeks,
      required this.progress, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: AppTheme.navy, borderRadius: BorderRadius.circular(22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
                color: AppTheme.orange,
                borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.bar_chart_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(track, style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w800,
                  color: Colors.white)),
              Text('Week $doneCount of $totalWeeks · In progress',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, color: Colors.white54)),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: AppTheme.orange,
                borderRadius: BorderRadius.circular(20)),
            child: Text('${(progress * 100).toInt()}%',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
        ]),
        const SizedBox(height: 14),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOut,
          builder: (_, val, __) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: val,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(AppTheme.orange),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(currentWeekTitle.isNotEmpty
              ? 'Now: $currentWeekTitle' : 'Ready to start',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, color: Colors.white54)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
                color: AppTheme.orange,
                borderRadius: BorderRadius.circular(20)),
            child: Text('Continue',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ]),
      ]),
    ),
  );
}

class _NoQuestCard extends StatelessWidget {
  final VoidCallback onTap;
  const _NoQuestCard({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.purpleLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.purpleBorder, width: 1.5),
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Generate your roadmap',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w800,
                    color: AppTheme.textDark)),
            const SizedBox(height: 3),
            Text('Answer 5 questions → get your AI plan',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: AppTheme.textMid)),
          ],
        )),
        Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.primary),
      ]),
    ),
  );
}

// ─── Weeks Scroll ─────────────────────────────────────────────────
class _WeeksScroll extends StatelessWidget {
  final List weeks;
  const _WeeksScroll({required this.weeks});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 110,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: weeks.length,
      itemBuilder: (context, i) {
        final w = weeks[i];
        final isDone = w['status'] == 'done';
        final isCurrent = !isDone &&
            weeks.take(i).every((x) => x['status'] == 'done');
        return _WeekChip(
          weekNum: i + 1,
          title: w['title'] ?? 'Week ${i + 1}',
          hours: w['estimatedHours'] ?? 8,
          isDone: isDone,
          isCurrent: isCurrent,
        );
      },
    ),
  );
}

class _WeekChip extends StatelessWidget {
  final int weekNum, hours;
  final String title;
  final bool isDone, isCurrent;
  const _WeekChip({required this.weekNum, required this.title,
      required this.hours, required this.isDone, required this.isCurrent});
  @override
  Widget build(BuildContext context) {
    Color bg = Colors.white;
    Color border = AppTheme.border;
    Color titleColor = AppTheme.textDark;
    Color subColor = AppTheme.textLight;
    if (isDone) { bg = AppTheme.navy; border = AppTheme.navy; titleColor = Colors.white70; subColor = AppTheme.primary.withOpacity(0.8); }
    if (isCurrent) { bg = AppTheme.orange; border = AppTheme.orange; titleColor = Colors.white; subColor = Colors.white70; }
    return Container(
      width: 105,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        isDone
            ? Container(width: 18, height: 18,
                decoration: BoxDecoration(
                    color: AppTheme.primary, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 11))
            : Text(isCurrent ? 'NOW' : 'WK $weekNum',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 9, fontWeight: FontWeight.w800, color: subColor)),
        const SizedBox(height: 6),
        Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: titleColor, height: 1.3)),
        const Spacer(),
        Text('$hours hrs', style: GoogleFonts.plusJakartaSans(
            fontSize: 10, color: subColor)),
      ]),
    );
  }
}

// ─── Job Readiness Card ───────────────────────────────────────────
class _JobReadinessCard extends StatelessWidget {
  final int score;
  final String label;
  final VoidCallback onTap;
  const _JobReadinessCard({required this.score, required this.label,
      required this.onTap});

  Color get _scoreColor {
    if (score >= 80) return AppTheme.green;
    if (score >= 60) return AppTheme.primary;
    if (score >= 40) return AppTheme.orange;
    return AppTheme.amber;
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppTheme.navy, borderRadius: BorderRadius.circular(22)),
      child: Row(children: [
        SizedBox(
          width: 70, height: 70,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(_scoreColor),
              strokeWidth: 6,
              strokeCap: StrokeCap.round,
            ),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('$score', style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: _scoreColor)),
              Text('/100', style: GoogleFonts.plusJakartaSans(
                  fontSize: 9, color: Colors.white38)),
            ]),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Job Readiness Score',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _scoreColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(label, style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: _scoreColor)),
            ),
            const SizedBox(height: 6),
            Text('Tap to see full breakdown',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, color: Colors.white38)),
          ],
        )),
        Icon(Icons.arrow_forward_ios_rounded,
            color: Colors.white38, size: 14),
      ]),
    ),
  );
}

// ─── AI Coach Card ────────────────────────────────────────────────
class _AiCoachCard extends StatelessWidget {
  final String insight;
  final bool isLoading;
  const _AiCoachCard({required this.insight, required this.isLoading});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.greenLight,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppTheme.greenBorder, width: 1.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _PulsingDot(),
        const SizedBox(width: 8),
        Text('AI coach · live',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: AppTheme.green, letterSpacing: 0.4)),
      ]),
      const SizedBox(height: 10),
      isLoading
          ? Row(children: [
              SizedBox(width: 14, height: 14,
                  child: CircularProgressIndicator(
                      color: AppTheme.green, strokeWidth: 2)),
              const SizedBox(width: 10),
              Text('Thinking...',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: AppTheme.green)),
            ])
          : Text(insight,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: const Color(0xFF1B5E20), height: 1.55)),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
            color: AppTheme.greenBorder,
            borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 14, color: AppTheme.green),
          const SizedBox(width: 6),
          Text('Ask AI coach',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: AppTheme.green)),
        ]),
      ),
    ]),
  );
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(_ctrl);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _anim,
    child: Container(width: 8, height: 8,
        decoration: BoxDecoration(
            color: AppTheme.green, shape: BoxShape.circle)),
  );
}

// ─── Leaderboard Card ─────────────────────────────────────────────
class _LeaderboardCard extends StatelessWidget {
  final List<Map<String, dynamic>> topUsers;
  final int myRank, myXP;
  final String currentUid, myName;
  const _LeaderboardCard({required this.topUsers, required this.myRank,
      required this.currentUid, required this.myXP, required this.myName});

  @override
  Widget build(BuildContext context) {
    final displayUsers = topUsers.take(3).toList();
    final isInTop3 = displayUsers.any((u) => u['uid'] == currentUid);
    final rankColors = [AppTheme.amber, Colors.blueGrey, const Color(0xFFCD7F32)];
    final rankIcons = [Icons.emoji_events_rounded, Icons.military_tech_rounded, Icons.workspace_premium_rounded];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          ...displayUsers.asMap().entries.map((e) {
            final i = e.key;
            final u = e.value;
            final isMe = u['uid'] == currentUid;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.purpleLight : Colors.transparent,
                borderRadius: i == 0
                    ? const BorderRadius.vertical(top: Radius.circular(22))
                    : BorderRadius.zero,
                border: i < displayUsers.length - 1
                    ? Border(bottom: BorderSide(color: AppTheme.border))
                    : null,
              ),
              child: Row(children: [
                Icon(rankIcons[i], color: rankColors[i], size: 20),
                const SizedBox(width: 10),
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: isMe ? AppTheme.purpleBorder : AppTheme.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text(
                    (u['name'] as String).isNotEmpty
                        ? (u['name'] as String)[0].toUpperCase() : '?',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: isMe ? AppTheme.primary : AppTheme.textMid))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Row(children: [
                  Text(u['name'],
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: AppTheme.textDark)),
                  if (isMe) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('You',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 9, fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ],
                ])),
                Text('${u['xp']} XP',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: isMe ? AppTheme.primary : AppTheme.textMid)),
              ]),
            );
          }),
          if (!isInTop3 && myRank > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.purpleLight,
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(22)),
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Row(children: [
                Text('#$myRank',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w800,
                        color: AppTheme.primary)),
                const SizedBox(width: 10),
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.purpleBorder,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text(
                    myName.isNotEmpty ? myName[0].toUpperCase() : 'Y',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: AppTheme.primary))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Row(children: [
                  Text(myName,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: AppTheme.textDark)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(6)),
                    child: Text('You',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 9, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ])),
                Text('$myXP XP',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: AppTheme.primary)),
              ]),
            ),
        ],
      ),
    );
  }
}

// ─── Streak Card ──────────────────────────────────────────────────
class _StreakCard extends StatelessWidget {
  final int streak;
  final List<bool> weekActivity;
  const _StreakCard({required this.streak, required this.weekActivity});
  @override
  Widget build(BuildContext context) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday - 1;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.amberLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.amberBorder, width: 1.5),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("This week — don't break it!",
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  color: AppTheme.textDark)),
          Row(children: [
            Icon(Icons.local_fire_department_rounded,
                color: AppTheme.amber, size: 20),
            const SizedBox(width: 4),
            Text('$streak days',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, fontWeight: FontWeight.w800,
                    color: AppTheme.amber)),
          ]),
        ]),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final isActive = i < weekActivity.length && weekActivity[i];
            final isToday = i == today;
            return Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.amber
                    : isToday ? AppTheme.amberLight : const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isToday && !isActive
                      ? AppTheme.amber
                      : isActive ? AppTheme.amber : const Color(0xFFFFE082),
                  width: isToday && !isActive ? 2 : 1.5,
                ),
              ),
              child: Center(child: Text(days[i],
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : AppTheme.amber))),
            );
          }),
        ),
      ]),
    );
  }
}

// ─── Tracks Scroll ────────────────────────────────────────────────
class _TracksScroll extends StatelessWidget {
  final VoidCallback onTrackTap;
  const _TracksScroll({required this.onTrackTap});
  @override
  Widget build(BuildContext context) {
    final tracks = [
      {'icon': Icons.bar_chart_rounded, 'name': 'Data Science', 'dur': '16 wks', 'color': AppTheme.primary, 'bg': AppTheme.purpleLight},
      {'icon': Icons.psychology_rounded, 'name': 'AI Engineer', 'dur': '24 wks', 'color': AppTheme.orange, 'bg': AppTheme.orangeLight},
      {'icon': Icons.code_rounded, 'name': 'Full Stack', 'dur': '24 wks', 'color': AppTheme.green, 'bg': AppTheme.greenLight},
      {'icon': Icons.phone_android_rounded, 'name': 'Mobile Dev', 'dur': '20 wks', 'color': const Color(0xFF1565C0), 'bg': const Color(0xFFE3F2FD)},
      {'icon': Icons.security_rounded, 'name': 'Cybersec', 'dur': '20 wks', 'color': const Color(0xFFC62828), 'bg': const Color(0xFFFCE4EC)},
    ];
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tracks.length,
        itemBuilder: (context, i) {
          final t = tracks[i];
          return GestureDetector(
            onTap: onTrackTap,
            child: Container(
              width: 95,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border, width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                        color: t['bg'] as Color,
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(t['icon'] as IconData,
                        color: t['color'] as Color, size: 18),
                  ),
                  const SizedBox(height: 7),
                  Text(t['name'] as String,
                      textAlign: TextAlign.center, maxLines: 2,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: AppTheme.textDark, height: 1.3)),
                  const SizedBox(height: 2),
                  Text(t['dur'] as String,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 9, fontWeight: FontWeight.w600,
                          color: t['color'] as Color)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Bottom Nav ───────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final VoidCallback onHome, onRoadmap, onResources, onProfile;
  const _BottomNav({required this.currentIndex, required this.onHome,
      required this.onRoadmap, required this.onResources,
      required this.onProfile});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border))),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _NavItem(Icons.home_outlined, Icons.home_rounded,
            'Home', currentIndex == 0, onHome),
        _NavItem(Icons.map_outlined, Icons.map_rounded,
            'Roadmap', currentIndex == 1, onRoadmap),
        _NavItem(Icons.play_circle_outline, Icons.play_circle,
            'Resources', currentIndex == 2, onResources),
        _NavItem(Icons.person_outline, Icons.person_rounded,
            'Profile', currentIndex == 3, onProfile),
      ],
    ),
  );
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
              color: active ? AppTheme.orange : AppTheme.textLight, size: 24),
          const SizedBox(height: 3),
          Text(label, style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: active ? AppTheme.orange : AppTheme.textLight,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
        ]),
      ),
    );
