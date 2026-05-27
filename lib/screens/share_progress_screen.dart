import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import '../core/theme.dart';

class ShareProgressScreen extends StatefulWidget {
  const ShareProgressScreen({super.key});
  @override
  State<ShareProgressScreen> createState() => _ShareProgressScreenState();
}

class _ShareProgressScreenState extends State<ShareProgressScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  Map<String, dynamic>? userData;
  Map<String, dynamic>? roadmapData;
  bool isLoading = true;
  bool isSharing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { setState(() => isLoading = false); return; }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(uid).get();
      final roadmapSnap = await FirebaseFirestore.instance
          .collection('roadmaps').where('uid', isEqualTo: uid).limit(1).get();
      if (mounted) setState(() {
        userData = userDoc.data();
        roadmapData = roadmapSnap.docs.isNotEmpty
            ? roadmapSnap.docs.first.data() : null;
        isLoading = false;
      });
    } catch (_) { if (mounted) setState(() => isLoading = false); }
  }

  Future<void> _shareCard() async {
    setState(() => isSharing = true);
    try {
      final image = await _screenshotController.capture(
          pixelRatio: 3.0);
      if (image == null) return;

      final name = userData?['name'] ?? 'Student';
      final track = roadmapData?['track'] ?? 'my career path';
      final weeks = roadmapData?['weeks'] as List? ?? [];
      final done = weeks.where((w) => w['status'] == 'done').length;
      final total = weeks.length;
      final pct = total > 0 ? (done / total * 100).round() : 0;

      await Share.shareXFiles(
        [XFile.fromData(image, mimeType: 'image/png', name: 'progress.png')],
        text: 'I\'m $pct% through $track on PathForge! '
            '🚀 $done/$total weeks done. '
            'Building my career one week at a time. '
            '#PathForge #CareerGoals #$track',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not share. Try again.',
              style: GoogleFonts.plusJakartaSans(color: Colors.white)),
          backgroundColor: AppTheme.navy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } finally {
      if (mounted) setState(() => isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Center(child: CircularProgressIndicator(color: AppTheme.orange)));

    final name = userData?['name'] ?? 'Student';
    final track = roadmapData?['track'] ?? 'Career Path';
    final weeks = roadmapData?['weeks'] as List? ?? [];
    final doneWeeks = weeks.where((w) => w['status'] == 'done').length;
    final totalWeeks = weeks.length;
    final progress = totalWeeks > 0 ? doneWeeks / totalWeeks : 0.0;
    final pct = (progress * 100).round();
    final xp = (userData?['xp'] ?? 0) as int;
    final streak = (userData?['streak'] ?? 0) as int;
    final level = userData?['levelName'] ?? 'Code Newcomer';
    final score = (userData?['jobReadinessScore'] ?? 0) as int;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Column(children: [
          // Header
          Container(
            color: AppTheme.navy,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(children: [
              GestureDetector(
                onTap: () => context.go('/home'),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Share Progress',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 18, fontWeight: FontWeight.w800,
                      color: Colors.white))),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [

                Text('Your shareable progress card',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: AppTheme.textMid)),
                const SizedBox(height: 16),

                // The card to screenshot
                Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.navy,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row
                        Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.route_rounded,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 10),
                          Column(crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('PathForge',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16, fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                            Text('AI Career Roadmap',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11, color: Colors.white54)),
                          ]),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppTheme.orange.withOpacity(0.4)),
                            ),
                            child: Text(level,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10, fontWeight: FontWeight.w700,
                                    color: AppTheme.orange)),
                          ),
                        ]),

                        const SizedBox(height: 20),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 16),

                        // Name + track
                        Text(name,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 22, fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(track,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14, color: AppTheme.orange,
                                fontWeight: FontWeight.w600)),

                        const SizedBox(height: 20),

                        // Progress bar
                        Row(mainAxisAlignment:
                            MainAxisAlignment.spaceBetween, children: [
                          Text('Roadmap Progress',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12, color: Colors.white60)),
                          Text('$pct%',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12, fontWeight: FontWeight.w800,
                                  color: AppTheme.orange)),
                        ]),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation(AppTheme.orange),
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('$doneWeeks of $totalWeeks weeks completed',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 11, color: Colors.white38)),

                        const SizedBox(height: 20),

                        // Stats row
                        Row(children: [
                          _StatBox('$xp', 'XP Earned', AppTheme.amber),
                          const SizedBox(width: 10),
                          _StatBox('$streak', 'Day Streak', AppTheme.orange),
                          const SizedBox(width: 10),
                          _StatBox('$score%', 'Job Ready', AppTheme.green),
                        ]),

                        const SizedBox(height: 20),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 12),

                        // Footer
                        Center(child: Text('pathforge.app',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12, color: Colors.white38,
                                fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Share button
                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton.icon(
                    onPressed: isSharing ? null : _shareCard,
                    icon: isSharing
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.share_rounded, size: 20),
                    label: Text(
                      isSharing ? 'Preparing...' : 'Share this card',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text('Share to LinkedIn, WhatsApp, or anywhere',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: AppTheme.textLight),
                    textAlign: TextAlign.center),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatBox(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(children: [
        Text(value, style: GoogleFonts.plusJakartaSans(
            fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: GoogleFonts.plusJakartaSans(
            fontSize: 10, color: Colors.white60)),
      ]),
    ),
  );
}
