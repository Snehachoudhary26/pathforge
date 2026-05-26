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
        vsync: this, duration: const Duration(milliseconds: 1200));
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
    if (uid == null) { setState(() => isLoading = false); return; }
    final result = await FirestoreService.calculateJobReadiness(uid: uid);
    if (mounted) {
      setState(() { data = result; isLoading = false; });
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
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Navy header
            Container(
              color: AppTheme.navy,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Row(
                children: [
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Job Readiness Score',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 18, fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        Text('Based on your real progress',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 11, color: Colors.white54)),
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
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.refresh_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(
                      color: AppTheme.orange))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Main score circle
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: AppTheme.navy,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              children: [
                                AnimatedBuilder(
                                  animation: _scoreAnim,
                                  builder: (_, __) => CircularPercentIndicator(
                                    radius: 90,
                                    lineWidth: 12,
                                    percent: (_scoreAnim.value *
                                            (data?['score'] ?? 0) / 100)
                                        .clamp(0.0, 1.0),
                                    center: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${((_scoreAnim.value * (data?['score'] ?? 0)).round())}',
                                          style: GoogleFonts.plusJakartaSans(
                                              fontSize: 48,
                                              fontWeight: FontWeight.w800,
                                              color: _scoreColor),
                                        ),
                                        Text('/ 100',
                                            style: GoogleFonts.plusJakartaSans(
                                                fontSize: 14,
                                                color: Colors.white54)),
                                      ],
                                    ),
                                    progressColor: _scoreColor,
                                    backgroundColor: Colors.white12,
                                    circularStrokeCap:
                                        CircularStrokeCap.round,
                                    animation: false,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _scoreColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: _scoreColor.withOpacity(0.4)),
                                  ),
                                  child: Text(
                                    data?['label'] ?? 'Getting Started',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: _scoreColor),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  data?['advice'] ?? '',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: Colors.white70,
                                      height: 1.5),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Score breakdown
                          Text('Score breakdown',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15, fontWeight: FontWeight.w800,
                                  color: AppTheme.textDark)),
                          const SizedBox(height: 12),

                          _BreakdownCard(
                            icon: Icons.map_rounded,
                            label: 'Roadmap Progress',
                            desc: '${data?['doneWeeks']} of ${data?['totalWeeks']} weeks done',
                            points: data?['breakdown']['progress'] ?? 0,
                            maxPoints: 40,
                            color: AppTheme.primary,
                            bg: AppTheme.purpleLight,
                          ),
                          const SizedBox(height: 10),
                          _BreakdownCard(
                            icon: Icons.local_fire_department_rounded,
                            label: 'Study Consistency',
                            desc: 'Based on your daily streak',
                            points: data?['breakdown']['streak'] ?? 0,
                            maxPoints: 20,
                            color: AppTheme.orange,
                            bg: AppTheme.orangeLight,
                          ),
                          const SizedBox(height: 10),
                          _BreakdownCard(
                            icon: Icons.bolt_rounded,
                            label: 'XP Earned',
                            desc: 'From completing weeks',
                            points: data?['breakdown']['xp'] ?? 0,
                            maxPoints: 20,
                            color: AppTheme.amber,
                            bg: AppTheme.amberLight,
                          ),
                          const SizedBox(height: 10),
                          _BreakdownCard(
                            icon: Icons.psychology_rounded,
                            label: 'Skills Completed',
                            desc: 'Individual skills mastered',
                            points: data?['breakdown']['skills'] ?? 0,
                            maxPoints: 20,
                            color: AppTheme.green,
                            bg: AppTheme.greenLight,
                          ),

                          const SizedBox(height: 20),

                          // What to do next
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.purpleLight,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppTheme.purpleBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Icon(Icons.tips_and_updates_rounded,
                                      color: AppTheme.primary, size: 18),
                                  const SizedBox(width: 8),
                                  Text('How to increase your score',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.primary)),
                                ]),
                                const SizedBox(height: 12),
                                _Tip('+40 pts', 'Complete all weeks in your roadmap'),
                                _Tip('+20 pts', 'Build a 30-day study streak'),
                                _Tip('+20 pts', 'Earn 2000+ XP by completing weeks'),
                                _Tip('+20 pts', 'Master all skills in each week'),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // CTA — share score
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () => context.go('/home'),
                              icon: const Icon(Icons.rocket_launch_rounded,
                                  size: 18),
                              label: Text('Continue learning',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.navy,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),
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
    required this.icon, required this.label, required this.desc,
    required this.points, required this.maxPoints,
    required this.color, required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppTheme.textDark)),
              Text(desc, style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, color: AppTheme.textMid)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (points / maxPoints).clamp(0.0, 1.0),
                  backgroundColor: AppTheme.border,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          children: [
            Text('$points', style: GoogleFonts.plusJakartaSans(
                fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text('/$maxPoints', style: GoogleFonts.plusJakartaSans(
                fontSize: 10, color: AppTheme.textLight)),
          ],
        ),
      ]),
    );
  }
}

class _Tip extends StatelessWidget {
  final String points, text;
  const _Tip(this.points, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(points, style: GoogleFonts.plusJakartaSans(
              fontSize: 10, fontWeight: FontWeight.w800,
              color: Colors.white)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: GoogleFonts.plusJakartaSans(
            fontSize: 12, color: AppTheme.textMid))),
      ]),
    );
  }
}
