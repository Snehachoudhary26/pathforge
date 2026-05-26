import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:lottie/lottie.dart';
import '../core/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = '';
  Map<String, dynamic>? roadmapData;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { setState(() => isLoading = false); return; }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      final roadmapSnap = await FirebaseFirestore.instance
          .collection('roadmaps')
          .where('uid', isEqualTo: user.uid)
          .limit(1).get();
      if (mounted) {
        setState(() {
          userData = userDoc.data();
          userName = userDoc.data()?['name'] ??
              user.email?.split('@')[0] ?? 'Student';
          roadmapData = roadmapSnap.docs.isNotEmpty
              ? roadmapSnap.docs.first.data() : null;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final weeks = roadmapData?['weeks'] as List? ?? [];
    final doneCount = weeks.where((w) => w['status'] == 'done').length;
    final totalWeeks = weeks.length;
    final progress = totalWeeks > 0 ? doneCount / totalWeeks : 0.0;
    final track = roadmapData?['track'] ?? '';
    final currentWeek = weeks.firstWhere(
      (w) => w['status'] != 'done', orElse: () => weeks.isNotEmpty ? weeks.last : {});

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _HeroBand(
                      userName: userName,
                      greeting: _greeting,
                      doneCount: doneCount,
                      totalWeeks: totalWeeks,
                      progress: progress,
                      onAvatarTap: () => context.go('/profile'),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionRow('Active quest', null),
                          const SizedBox(height: 10),
                          roadmapData != null
                              ? _QuestCard(
                                  track: track,
                                  doneCount: doneCount,
                                  totalWeeks: totalWeeks,
                                  progress: progress,
                                  currentWeekTitle: currentWeek['title'] ?? '',
                                  onTap: () => context.go(
                                      '/roadmap?track=${Uri.encodeComponent(track)}'),
                                )
                              : _NoQuestCard(
                                  onTap: () => context.go('/onboarding')),
                          const SizedBox(height: 24),

                          if (roadmapData != null && weeks.isNotEmpty) ...[
                            _sectionRow('Your roadmap', 'Full view',
                                onTap: () => context.go(
                                    '/roadmap?track=${Uri.encodeComponent(track)}')),
                            const SizedBox(height: 10),
                            _WeeksScroll(weeks: weeks),
                            const SizedBox(height: 24),
                          ],

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

                          _sectionRow('AI coach', null),
                          const SizedBox(height: 10),
                          _AiCoachCard(
                            userName: userName,
                            track: track,
                            doneCount: doneCount,
                            totalWeeks: totalWeeks,
                          ),
                          const SizedBox(height: 24),

                          _sectionRow('Daily challenge', 'Skip'),
                          const SizedBox(height: 10),
                          _ChallengeCard(
                            currentWeekTitle: currentWeek['title'] ?? 'your current topic',
                            onTap: () => track.isNotEmpty
                                ? context.go('/roadmap?track=${Uri.encodeComponent(track)}')
                                : context.go('/track'),
                          ),
                          const SizedBox(height: 24),

                          _sectionRow('Streak tracker', null),
                          const SizedBox(height: 10),
                          const _StreakCard(),
                          const SizedBox(height: 24),

                          _sectionRow('Explore tracks', 'See all',
                              onTap: () => context.go('/track')),
                          const SizedBox(height: 10),
                          _TracksScroll(onTrackTap: () => context.go('/track')),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _BottomNav(
        currentIndex: 0,
        onHome: () {},
        onRoadmap: () => track.isNotEmpty
            ? context.go('/roadmap?track=${Uri.encodeComponent(track)}')
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
        Text(title, style: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
        if (action != null)
          GestureDetector(
            onTap: onTap,
            child: Text(action, style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
          ),
      ],
    );
  }
}

class _HeroBand extends StatelessWidget {
  final String userName, greeting;
  final int doneCount, totalWeeks;
  final double progress;
  final VoidCallback onAvatarTap;
  const _HeroBand({
    required this.userName, required this.greeting,
    required this.doneCount, required this.totalWeeks,
    required this.progress, required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.navy,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting, style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: Colors.white60,
                        fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(userName, style: GoogleFonts.plusJakartaSans(
                        fontSize: 22, fontWeight: FontWeight.w800,
                        color: Colors.white)),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppTheme.orange.withOpacity(0.4)),
                    ),
                    child: Text('Level 7', style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppTheme.orange)),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: onAvatarTap,
                    child: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.orange,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          userName.isNotEmpty
                              ? userName[0].toUpperCase() : 'S',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 18, fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Code Apprentice',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 11, color: Colors.white60)),
                        Text('3,240 / 5,000 XP',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 11, fontWeight: FontWeight.w700,
                                color: AppTheme.orange)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 0.64,
                        backgroundColor: Colors.white12,
                        valueColor:
                            AlwaysStoppedAnimation(AppTheme.orange),
                        minHeight: 7,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatChip(
                icon: Icons.local_fire_department_rounded,
                iconColor: AppTheme.orange,
                value: '7',
                label: 'Streak',
                bg: AppTheme.orange.withOpacity(0.15),
              ),
              const SizedBox(width: 10),
              _StatChip(
                icon: Icons.check_circle_outline_rounded,
                iconColor: AppTheme.green,
                value: '$doneCount',
                label: 'Weeks done',
                bg: AppTheme.green.withOpacity(0.15),
              ),
              const SizedBox(width: 10),
              _StatChip(
                icon: Icons.star_outline_rounded,
                iconColor: Colors.amber,
                value: '#12',
                label: 'Rank',
                bg: Colors.amber.withOpacity(0.15),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor, bg;
  final String value, label;
  const _StatChip({
    required this.icon, required this.iconColor,
    required this.value, required this.label, required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w800,
                color: Colors.white)),
            Text(label, style: GoogleFonts.plusJakartaSans(
                fontSize: 9, color: Colors.white70,
                fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final String track, currentWeekTitle;
  final int doneCount, totalWeeks;
  final double progress;
  final VoidCallback onTap;
  const _QuestCard({
    required this.track, required this.currentWeekTitle,
    required this.doneCount, required this.totalWeeks,
    required this.progress, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.navy,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.orange,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.bar_chart_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(track, style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, fontWeight: FontWeight.w800,
                          color: Colors.white)),
                      Text('Week $doneCount of $totalWeeks · In progress',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11, color: Colors.white54)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${(progress * 100).toInt()}%',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation(AppTheme.orange),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(currentWeekTitle.isNotEmpty
                    ? 'Now: $currentWeekTitle' : 'Starting soon',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, color: Colors.white54)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Continue',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoQuestCard extends StatelessWidget {
  final VoidCallback onTap;
  const _NoQuestCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.purpleLight,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.purpleBorder, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
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
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}

class _WeeksScroll extends StatelessWidget {
  final List weeks;
  const _WeeksScroll({required this.weeks});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
}

class _WeekChip extends StatelessWidget {
  final int weekNum, hours;
  final String title;
  final bool isDone, isCurrent;
  const _WeekChip({
    required this.weekNum, required this.title,
    required this.hours, required this.isDone, required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.white;
    Color borderColor = AppTheme.border;
    Color titleColor = AppTheme.textDark;
    Color subColor = AppTheme.textLight;
    if (isDone) { bg = AppTheme.navy; borderColor = AppTheme.navy; titleColor = Colors.white70; subColor = AppTheme.primary.withOpacity(0.8); }
    if (isCurrent) { bg = AppTheme.orange; borderColor = AppTheme.orange; titleColor = Colors.white; subColor = Colors.white70; }

    return Container(
      width: 105,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isDone
              ? Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check,
                      color: Colors.white, size: 11),
                )
              : Text(isCurrent ? 'NOW' : 'WK $weekNum',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 9, fontWeight: FontWeight.w800,
                      color: subColor)),
          const SizedBox(height: 6),
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: titleColor, height: 1.3)),
          const Spacer(),
          Text('$hours hrs',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 10, color: subColor)),
        ],
      ),
    );
  }
}

class _AiCoachCard extends StatelessWidget {
  final String userName, track;
  final int doneCount, totalWeeks;
  const _AiCoachCard({
    required this.userName, required this.track,
    required this.doneCount, required this.totalWeeks,
  });

  String get _insight {
    if (track.isEmpty) return 'Generate your roadmap to get personalised AI coaching.';
    final weeksLeft = totalWeeks - doneCount;
    if (doneCount == 0) return 'Start Week 1 today and you\'ll be interview-ready in $totalWeeks weeks. Consistency beats intensity.';
    return 'Great pace, $userName! $weeksLeft weeks left on $track. Focus on this week\'s skills — each one directly maps to interview questions.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.greenLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.greenBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.green, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text('AI coach · live',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: AppTheme.green,
                      letterSpacing: 0.4)),
            ],
          ),
          const SizedBox(height: 10),
          Text(_insight,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: const Color(0xFF1B5E20),
                  height: 1.55)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.greenBorder,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 14, color: AppTheme.green),
                  const SizedBox(width: 6),
                  Text('Ask AI coach',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: AppTheme.green)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final String currentWeekTitle;
  final VoidCallback onTap;
  const _ChallengeCard({
    required this.currentWeekTitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.orangeLight,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.orangeBorder, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppTheme.orange,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.lightbulb_outline_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(currentWeekTitle,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, fontWeight: FontWeight.w800,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 3),
                  Text('+150 XP · Bonus streak shield',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF8D4A00))),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 12, color: AppTheme.orange),
                      const SizedBox(width: 4),
                      Text('4h 22m remaining',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: AppTheme.orange)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppTheme.orange, size: 22),
          ],
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard();

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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("This week — don't break it!",
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w800,
                      color: AppTheme.textDark)),
              Text('7 days',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 18, fontWeight: FontWeight.w800,
                      color: AppTheme.amber)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final isDone = i < today;
              final isToday = i == today;
              return Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppTheme.amber
                      : isToday
                          ? AppTheme.amberLight
                          : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isToday
                        ? AppTheme.amber
                        : isDone
                            ? AppTheme.amber
                            : const Color(0xFFFFE082),
                    width: isToday ? 2 : 1.5,
                  ),
                ),
                child: Center(
                  child: Text(days[i],
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: isDone
                              ? Colors.white
                              : AppTheme.amber)),
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(t['icon'] as IconData,
                        color: t['color'] as Color, size: 18),
                  ),
                  const SizedBox(height: 7),
                  Text(t['name'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 2,
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

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final VoidCallback onHome, onRoadmap, onResources, onProfile;
  const _BottomNav({
    required this.currentIndex, required this.onHome,
    required this.onRoadmap, required this.onResources,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded,
              label: 'Home', active: currentIndex == 0, onTap: onHome),
          _NavItem(icon: Icons.map_outlined, activeIcon: Icons.map_rounded,
              label: 'Roadmap', active: currentIndex == 1, onTap: onRoadmap),
          _NavItem(icon: Icons.play_circle_outline, activeIcon: Icons.play_circle,
              label: 'Resources', active: currentIndex == 2, onTap: onResources),
          _NavItem(icon: Icons.person_outline, activeIcon: Icons.person_rounded,
              label: 'Profile', active: currentIndex == 3, onTap: onProfile),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon, required this.activeIcon,
    required this.label, required this.active, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.purpleLight : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(active ? activeIcon : icon,
                color: active ? AppTheme.primary : AppTheme.textLight,
                size: 24),
            const SizedBox(height: 3),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: active ? AppTheme.primary : AppTheme.textLight,
                    fontWeight: active
                        ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─── Job Readiness Card ───────────────────────────────────────────

class _JobReadinessCard extends StatelessWidget {
  final int score;
  final String label;
  final VoidCallback onTap;
  const _JobReadinessCard({
    required this.score,
    required this.label,
    required this.onTap,
  });

  Color get _scoreColor {
    if (score >= 80) return AppTheme.green;
    if (score >= 60) return AppTheme.primary;
    if (score >= 40) return AppTheme.orange;
    return AppTheme.amber;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.navy,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            // Circular score
            SizedBox(
              width: 70, height: 70,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: score / 100,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(_scoreColor),
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$score',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 18, fontWeight: FontWeight.w800,
                              color: _scoreColor)),
                      Text('/100',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 9, color: Colors.white38)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Job Readiness Score',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _scoreColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(label,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: _scoreColor)),
                  ),
                  const SizedBox(height: 8),
                  Text('Complete more weeks to improve your score',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, color: Colors.white54)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white38, size: 14),
          ],
        ),
      ),
    );
  }
}
