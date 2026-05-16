import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  @override
  void initState() {
    super.initState();
    _loadRoadmap();
  }

  Future<void> _loadRoadmap() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      print('👤 Loading roadmap for uid=$uid track=${widget.track}');

      if (uid == null) {
        setState(() {
          isLoading = false;
          error = 'Not logged in';
        });
        return;
      }

      final data = await FirestoreService.getRoadmapForTrack(
        uid: uid,
        track: widget.track,
      );

      print('📊 Loaded data: ${data?.keys.toList()}');

      if (data != null && data['weeks'] != null) {
        final rawWeeks = data['weeks'] as List<dynamic>;
        print('📅 Number of weeks: ${rawWeeks.length}');

        setState(() {
          weeks = rawWeeks.map((w) {
            final week = Map<String, dynamic>.from(w as Map);
            if (week['skills'] is List) {
              week['skills'] = (week['skills'] as List)
                  .map((s) => s.toString())
                  .toList();
            } else {
              week['skills'] = <String>[];
            }
            return week;
          }).toList();
          isLoading = false;
        });
      } else {
        print('❌ No data or no weeks found');
        setState(() {
          isLoading = false;
          error = 'No roadmap found. Please generate one.';
        });
      }
    } catch (e) {
      print('❌ Error loading roadmap: $e');
      setState(() {
        isLoading = false;
        error = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final doneCount =
        weeks.where((w) => w['status'] == 'done').length;
    final progress =
        weeks.isEmpty ? 0.0 : doneCount / weeks.length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              color: AppTheme.background,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.track,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                            Text(
                              '${weeks.length} weeks • AI generated for you',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppTheme.textMid),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.light,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Text(
                          '${(progress * 100).toInt()}% done',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppTheme.border,
                      valueColor:
                          AlwaysStoppedAnimation(AppTheme.primary),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$doneCount of ${weeks.length} weeks done',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.textLight)),
                      Text('${weeks.length - doneCount} weeks left',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.textLight)),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                              color: AppTheme.primary),
                          const SizedBox(height: 16),
                          Text('Loading your roadmap...',
                            style: GoogleFonts.poppins(
                                color: AppTheme.textMid)),
                        ],
                      ),
                    )
                  : error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const Text('⚠️',
                                    style:
                                        TextStyle(fontSize: 48)),
                                const SizedBox(height: 16),
                                Text(
                                  'No roadmap yet for\n${widget.track}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textDark,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Click below to generate your AI roadmap',
                                  style: GoogleFonts.poppins(
                                      color: AppTheme.textMid),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: () => context.go(
                                    '/generating?track=${Uri.encodeComponent(widget.track)}',
                                  ),
                                  icon: const Icon(Icons.auto_awesome),
                                  label: Text(
                                    'Generate ${widget.track} Roadmap',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                              20, 8, 20, 20),
                          itemCount: weeks.length,
                          itemBuilder: (context, i) {
                            final week = weeks[i];
                            final isLast = i == weeks.length - 1;
                            final weekNum =
                                week['weekNumber'] ??
                                week['week'] ??
                                (i + 1);
                            final title =
                                week['title'] ?? 'Week ${i + 1}';
                            final skills =
                                (week['skills'] as List<dynamic>)
                                    .cast<String>();
                            final hours =
                                week['estimatedHours'] ??
                                week['hours'] ??
                                8;
                            final isDone =
                                week['status'] == 'done';
                            final isCurrent = i == 0 && !isDone;

                            return _WeekRow(
                              weekNum: weekNum,
                              title: title,
                              skills: skills,
                              hours: hours,
                              isDone: isDone,
                              isCurrent: isCurrent,
                              isLast: isLast,
                              onTap: () => _showWeekDetail(
                                context,
                                week,
                                title,
                                skills,
                              ),
                            );
                          },
                        ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                    top: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(Icons.map_outlined, 'Roadmap',
                      true, () {}),
                  _NavItem(
                      Icons.play_circle_outline,
                      'Resources',
                      false,
                      () => context.go('/resources')),
                  _NavItem(Icons.person_outline, 'Profile',
                      false, () => context.go('/profile')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWeekDetail(
    BuildContext context,
    Map<String, dynamic> week,
    String title,
    List<String> skills,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            if (week['why'] != null)
              Text('💡 ${week['why']}',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppTheme.textMid),
              ),
            const SizedBox(height: 16),
            Text('Skills this week',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            ...skills.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(s,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.textDark)),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Got it!',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  final dynamic weekNum;
  final String title;
  final List<String> skills;
  final dynamic hours;
  final bool isDone, isCurrent, isLast;
  final VoidCallback onTap;

  const _WeekRow({
    required this.weekNum,
    required this.title,
    required this.skills,
    required this.hours,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppTheme.primary
                      : isCurrent
                          ? Colors.white
                          : AppTheme.border,
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(
                          color: AppTheme.primary, width: 2.5)
                      : null,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: AppTheme.primary
                                .withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
                      : [],
                ),
                child: isDone
                    ? const Icon(Icons.check,
                        color: Colors.white, size: 14)
                    : isCurrent
                        ? Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              '$weekNum',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: AppTheme.textLight,
                              ),
                            ),
                          ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone
                        ? AppTheme.primary
                        : AppTheme.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.fromLTRB(
                    14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppTheme.light
                      : AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCurrent
                        ? AppTheme.primary
                        : AppTheme.border,
                    width: isCurrent ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Week $weekNum — $title',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                        if (isDone)
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.light,
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Text('✓ Done',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (isCurrent && !isDone)
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Text('● Now',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: skills
                          .map((s) => Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDone || isCurrent
                                      ? AppTheme.primary
                                          .withOpacity(0.08)
                                      : AppTheme.background,
                                  borderRadius:
                                      BorderRadius.circular(6),
                                ),
                                child: Text(s,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: isDone || isCurrent
                                        ? AppTheme.primary
                                        : AppTheme.textLight,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 6),
                    Text('⏱ $hours hrs • Tap for details',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textLight,
                      )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _NavItem(
  IconData icon,
  String label,
  bool active,
  VoidCallback onTap,
) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
          color:
              active ? AppTheme.primary : AppTheme.textLight,
          size: 24),
        const SizedBox(height: 3),
        Text(label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: active
                ? AppTheme.primary
                : AppTheme.textLight,
            fontWeight: active
                ? FontWeight.w600
                : FontWeight.w400,
          )),
      ],
    ),
  );
}
