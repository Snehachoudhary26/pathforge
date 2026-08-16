import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../core/theme.dart';
import '../services/firestore_service.dart';

class JobReadinessScreen extends StatefulWidget {
  const JobReadinessScreen({super.key});
  @override
  State<JobReadinessScreen> createState() => _JobReadinessScreenState();
}

class _JobReadinessScreenState extends State<JobReadinessScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? data;
  bool isLoading = true;
  late AnimationController _animController;
  late Animation<double> _scoreAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _scoreAnim = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _loadScore();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadScore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }
    final result = await FirestoreService.calculateJobReadiness(uid: uid);
    if (mounted) {
      setState(() {
        data = result;
        isLoading = false;
      });
      _animController.forward();
    }
  }

  Color get _scoreColor {
    final score = data?['score'] ?? 0;
    if (score >= 80) return AppTheme.green;
    if (score >= 60) return AppTheme.primary;
    if (score >= 40) return AppTheme.orange;
    return AppTheme.amber;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Compact Deep Navy Header
            Container(
              color: const Color(0xFF111322),
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 8,
                16,
                12,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/home'),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Job Readiness Score',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Based on your real progress',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: const Color(0xFFB3B0D6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => isLoading = true);
                      _animController.reset();
                      _loadScore();
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Area (Single Screen, Zero Scrolling)
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF5722),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Compact Hero Score Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF111322),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                AnimatedBuilder(
                                  animation: _scoreAnim,
                                  builder: (_, __) => CircularPercentIndicator(
                                    radius: 46,
                                    lineWidth: 7.5,
                                    percent: (_scoreAnim.value *
                                            (data?['score'] ?? 0) /
                                            100)
                                        .clamp(0.0, 1.0),
                                    center: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${((_scoreAnim.value * (data?['score'] ?? 0)).round())}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w800,
                                            color: _scoreColor,
                                            height: 1.0,
                                          ),
                                        ),
                                        Text(
                                          '/ 100',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF9B99B5),
                                          ),
                                        ),
                                      ],
                                    ),
                                    progressColor: _scoreColor,
                                    backgroundColor: Colors.white12,
                                    circularStrokeCap: CircularStrokeCap.round,
                                    animation: false,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _scoreColor.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _scoreColor.withOpacity(0.35),
                                    ),
                                  ),
                                  child: Text(
                                    data?['label'] ?? 'Making Progress',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _scoreColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data?['advice'] ??
                                      'Keep your daily streak going — consistency is the fastest path to job-ready.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    color: const Color(0xFFB3B0D6),
                                    height: 1.25,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 2. Score Breakdown Header
                          Text(
                            'Score breakdown',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // 3. Compact Breakdown Cards
                          _BreakdownCard(
                            icon: Icons.map_rounded,
                            label: 'Roadmap Progress',
                            desc:
                                '${data?['doneWeeks'] ?? 0} of ${data?['totalWeeks'] ?? 8} weeks done',
                            points: data?['breakdown']?['progress'] ?? 0,
                            maxPoints: 40,
                            color: const Color(0xFF7C5CBF),
                            bg: const Color(0xFFF0EDF8),
                          ),
                          const SizedBox(height: 5),
                          _BreakdownCard(
                            icon: Icons.local_fire_department_rounded,
                            label: 'Study Consistency',
                            desc: 'Based on your daily streak',
                            points: data?['breakdown']?['streak'] ?? 0,
                            maxPoints: 20,
                            color: const Color(0xFFFF5722),
                            bg: const Color(0xFFFFEFEA),
                          ),
                          const SizedBox(height: 5),
                          _BreakdownCard(
                            icon: Icons.bolt_rounded,
                            label: 'XP Earned',
                            desc: 'From completing weeks',
                            points: data?['breakdown']?['xp'] ?? 0,
                            maxPoints: 20,
                            color: const Color(0xFFE08D00),
                            bg: const Color(0xFFFFF8E7),
                          ),
                          const SizedBox(height: 5),
                          _BreakdownCard(
                            icon: Icons.psychology_rounded,
                            label: 'Skills Completed',
                            desc: 'Individual skills mastered',
                            points: data?['breakdown']?['skills'] ?? 0,
                            maxPoints: 20,
                            color: const Color(0xFF00B894),
                            bg: const Color(0xFFE6F9F5),
                          ),
                          const SizedBox(height: 8),

                          // 4. Compact Tips Box
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F4FB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2DCF2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.tips_and_updates_rounded,
                                      color: Color(0xFF7C5CBF),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'How to increase your score',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF7C5CBF),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const _Tip('+40 pts', 'Complete all weeks in your roadmap'),
                                const _Tip('+20 pts', 'Build a 30-day study streak'),
                                const _Tip('+20 pts', 'Earn 2000+ XP by completing weeks'),
                                const _Tip('+20 pts', 'Master all skills in each week', isLast: true),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 5. Action Button
                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: ElevatedButton.icon(
                              onPressed: () => context.go('/home'),
                              icon: const Icon(
                                Icons.rocket_launch_rounded,
                                size: 15,
                              ),
                              label: Text(
                                'Continue learning',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF111322),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final IconData icon;
  final String label, desc;
  final int points, maxPoints;
  final Color color, bg;

  const _BreakdownCard({
    required this.icon,
    required this.label,
    required this.desc,
    required this.points,
    required this.maxPoints,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E9F2)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  desc,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    color: const Color(0xFF9B99B5),
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (points / maxPoints).clamp(0.0, 1.0),
                    backgroundColor: const Color(0xFFF0EDF8),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$points',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.0,
                ),
              ),
              Text(
                '/$maxPoints',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9B99B5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final String points, text;
  final bool isLast;
  const _Tip(this.points, this.text, {this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: const Color(0xFF7C5CBF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              points,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: const Color(0xFF4A4868),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
