import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/gemini_service.dart';
import '../services/ai_engine.dart';

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
  int streak = 0;
  int weeklyTargetHours = 10;
  int completedHours = 0;
  String selectedDay = 'Sun';
  bool isChatOpen = false;
  String coachInsight = '';
  bool isLoadingCoach = false;
  bool isGenerating = false;
  final TextEditingController _quickChatInput = TextEditingController();
  final List<Map<String, String>> _quickChatMessages = [];
  bool _isForgeTyping = false;

  final List<Map<String, dynamic>> leaderboard = [
    {'name': 'Sarthak', 'xp': 400, 'rank': 1, 'badge': '🥇'},
    {'name': 'Priya', 'xp': 280, 'rank': 2, 'badge': '🥈'},
    {'name': 'Aman', 'xp': 220, 'rank': 3, 'badge': '🥉'},
    {'name': 'Rahul', 'xp': 180, 'rank': 4, 'badge': '⭐'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAllUserData();
  }

  @override
  void dispose() {
    _quickChatInput.dispose();
    super.dispose();
  }

  Future<void> _loadAllUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final rSnap = await FirebaseFirestore.instance
          .collection('roadmaps')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          userData = userDoc.data() ?? {};
          userName = userData?['name'] ?? 'Engineer';
          xp = userData?['xp'] ?? 0;
          streak = userData?['streak'] ?? 1;
          weeklyTargetHours = userData?['weeklyHours'] ?? 10;
          completedHours = userData?['completedHours'] ?? 0;
          if (rSnap.docs.isNotEmpty) {
            roadmapData = rSnap.docs.first.data();
          }
        });
        _fetchCoachInsight();
      }
    } catch (_) {}
  }

  Future<void> _fetchCoachInsight() async {
    if (roadmapData == null) return;
    setState(() => isLoadingCoach = true);

    final weeks = roadmapData?['weeks'] as List? ?? [];
    final doneWeeks = weeks.where((w) => w['status'] == 'done').length;

    try {
      final insight = await GeminiService.getCoachInsight(
        userName: userName,
        track: roadmapData?['track'] ?? 'Data Scientist',
        doneWeeks: doneWeeks,
        totalWeeks: weeks.isEmpty ? 12 : weeks.length,
        streak: streak,
        xp: xp,
        goal: userData?['goal'] ?? 'Get placed',
        experience: userData?['experience'] ?? 'Beginner',
      );
      if (mounted) {
        setState(() {
          coachInsight = insight;
          isLoadingCoach = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoadingCoach = false);
    }
  }

  String get _currentLevelName {
    if (xp < 500) return 'Novice Explorer';
    if (xp < 1500) return 'Code Apprentice';
    if (xp < 3500) return 'Algorithm Knight';
    if (xp < 7000) return 'System Architect';
    return 'PathForge Legend';
  }

  int get _level {
    if (xp < 500) return 1;
    if (xp < 1500) return 2;
    if (xp < 3500) return 3;
    if (xp < 7000) return 4;
    return 5;
  }

  void _sendForgeMessage(String query, String track, int doneCount) async {
    final q = query.trim();
    if (q.isEmpty) return;

    _quickChatInput.clear();
    setState(() {
      _quickChatMessages.add({'role': 'user', 'text': q});
      _isForgeTyping = true;
    });

    final reply = await AiEngine.getMentorResponse(
      userMessage: q,
      userContext: {
        'name': userName.isNotEmpty ? userName : 'Student',
        'track': track,
        'doneWeeks': doneCount,
        'totalWeeks': (roadmapData?['weeks'] as List?)?.length ?? 12,
        'xp': xp,
        'streak': streak,
      },
      conversationHistory: _quickChatMessages,
    );

    if (mounted) {
      setState(() {
        _isForgeTyping = false;
        _quickChatMessages.add({'role': 'assistant', 'text': reply});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final weeks = roadmapData?['weeks'] as List? ?? [];
    final doneCount = weeks.where((w) => w['status'] == 'done').length;
    final totalWeeks = weeks.isEmpty ? 12 : weeks.length;
    final progress = totalWeeks > 0 ? doneCount / totalWeeks : 0.0;
    final track = roadmapData?['track'] ?? 'Data Scientist';
    final currentWeek = weeks.isNotEmpty
        ? weeks.firstWhere((w) => w['status'] != 'done',
            orElse: () => weeks.first)
        : {'title': 'Python Basics', 'weekNumber': 1};

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF111322),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          // ── 1. Top Header ───────────────────────
                          Container(
                            color: const Color(0xFF111322),
                            padding: EdgeInsets.fromLTRB(
                              16,
                              topPadding > 0 ? topPadding + 10 : 26,
                              16,
                              14,
                            ),
                            child: Row(
                              children: [
                                // User Avatar
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF1A1A2E),
                                    border: Border.all(
                                      color: const Color(0xFF7C5CBF)
                                          .withOpacity(0.6),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(
                                          userName.isNotEmpty
                                              ? userName[0].toUpperCase()
                                              : 'N',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Name & Level Title
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Good day, ${userName.split(' ').first}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        _currentLevelName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          color: const Color(0xFF9B99B5),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Streak & XP Pills
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _StatPill(
                                      icon: Icons.local_fire_department_rounded,
                                      iconColor: const Color(0xFFFF5722),
                                      value: '$streak',
                                    ),
                                    const SizedBox(width: 5),
                                    _StatPill(
                                      icon: Icons.bolt_rounded,
                                      iconColor: const Color(0xFFE08D00),
                                      value: '$xp',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // ── 2. White Card Content Body ──────────
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(26),
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Active Track Card
                                _buildActiveTrackCard(track, doneCount,
                                    totalWeeks, progress, currentWeek),
                                const SizedBox(height: 14),

                                // 🤖 AI Mentor Hero Card
                                _buildAiMentorBanner(context),
                                const SizedBox(height: 14),

                                // Agentic Tools Suite
                                _buildAgenticToolsRow(context, track),
                                const SizedBox(height: 14),

                                // 👨‍💻 Job Readiness Score Card
                                _buildJobReadinessCard(context),
                                const SizedBox(height: 12),

                                // 👨‍💻 Career Placement Goal Card
                                _buildPlacementGoalCard(context),
                                const SizedBox(height: 14),

                                // AI Coach Live Insight Banner
                                _buildCoachCard(),
                                const SizedBox(height: 14),

                                // 🚀 Leaderboard & Peer Study Group
                                _buildLeaderboardSection(context),
                                const SizedBox(height: 14),

                                // Weekly Streak Tracker Card
                                _buildStreakTargetCard(),
                                const SizedBox(height: 14),

                                // Daily 5-Min Challenge Card
                                _buildChallengeCard(track),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Navigation Bar
                    _buildBottomNav(context, track),
                  ],
                ),

                // ── 3. Floating FORGE AI Compact Card ───────
                if (isChatOpen)
                  Positioned(
                    right: 14,
                    bottom: 110,
                    left: 14,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 380,
                          maxHeight: 380,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFE8E9F2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1B1D36),
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(18)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: const BoxDecoration(
                                        color: Colors.white12,
                                        shape: BoxShape.circle,
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/images/robot-for-chatbot.png',
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                            Icons.smart_toy_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'FORGE AI',
                                              style: GoogleFonts
                                                  .plusJakartaSans(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Container(
                                              width: 5,
                                              height: 5,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF00B894),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          'PathForge Assistant · Online',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 9.5,
                                            color: const Color(0xFFB3B0D6),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () => setState(
                                          () => isChatOpen = false),
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: Colors.white12,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          color: Colors.white,
                                          size: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Chat messages list & suggestions
                              Flexible(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF7F8FC),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFFE2E4F0),
                                          ),
                                        ),
                                        child: Text(
                                          'Hi! I\'m FORGE 🤖 — your PathForge career assistant. Ask me anything about your $track roadmap, interview prep, or skills!',
                                          style: GoogleFonts
                                              .plusJakartaSans(
                                            fontSize: 10.5,
                                            color: const Color(0xFF1A1A2E),
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),

                                      ...[
                                        '🎯 What is my #1 priority this week?',
                                        '⚡ How do I boost my Job Readiness Score?',
                                        '💡 Recommend a portfolio project',
                                        '🔥 Give me a 5-minute coding challenge',
                                        '💼 What salary can I expect for my track?',
                                      ].map((prompt) {
                                        return GestureDetector(
                                          onTap: () => _sendForgeMessage(
                                              prompt, track, doneCount),
                                          child: Container(
                                            width: double.infinity,
                                            margin: const EdgeInsets.only(
                                                bottom: 4),
                                            padding: const EdgeInsets
                                                .symmetric(
                                              horizontal: 8,
                                              vertical: 4.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF6F4FB),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(0xFFE2DCF2),
                                                width: 1.0,
                                              ),
                                            ),
                                            child: Text(
                                              prompt,
                                              style: GoogleFonts
                                                  .plusJakartaSans(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF1B1D36),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),

                                      ..._quickChatMessages.map((m) {
                                        final isUser =
                                            m['role'] == 'user';
                                        return Container(
                                          margin: const EdgeInsets.only(
                                              top: 5),
                                          alignment: isUser
                                              ? Alignment.centerRight
                                              : Alignment.centerLeft,
                                          child: Container(
                                            padding:
                                                const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: isUser
                                                  ? const Color(0xFF1B1D36)
                                                  : const Color(0xFFF3F0FA),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: isUser
                                                  ? null
                                                  : Border.all(
                                                      color: const Color(
                                                          0xFFE2DCF2)),
                                            ),
                                            child: Text(
                                              m['text'] ?? '',
                                              style: GoogleFonts
                                                  .plusJakartaSans(
                                                fontSize: 10.5,
                                                color: isUser
                                                    ? Colors.white
                                                    : const Color(0xFF1A1A2E),
                                                height: 1.3,
                                              ),
                                            ),
                                          ),
                                        );
                                      }),

                                      if (_isForgeTyping) ...[
                                        const SizedBox(height: 5),
                                        const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF7C5CBF),
                                            strokeWidth: 1.5,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),

                              // Chat text input bar
                              Container(
                                padding: const EdgeInsets.fromLTRB(
                                    8, 4, 8, 6),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(
                                      bottom: Radius.circular(18)),
                                  border: Border(
                                    top: BorderSide(
                                        color: Color(0xFFE2E4F0)),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _quickChatInput,
                                            style: GoogleFonts
                                                .plusJakartaSans(
                                              fontSize: 11.5,
                                              color: const Color(0xFF1A1A2E),
                                            ),
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Ask FORGE anything...',
                                              hintStyle: GoogleFonts
                                                  .plusJakartaSans(
                                                fontSize: 10.5,
                                                color: const Color(
                                                    0xFF9B99B5),
                                              ),
                                              isDense: true,
                                              filled: true,
                                              fillColor:
                                                  const Color(0xFFF5F6FA),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                borderSide: BorderSide.none,
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                            ),
                                            onSubmitted: (val) =>
                                                _sendForgeMessage(
                                                    val, track, doneCount),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        GestureDetector(
                                          onTap: () => _sendForgeMessage(
                                              _quickChatInput.text,
                                              track,
                                              doneCount),
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFFF5722),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.arrow_upward_rounded,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() => isChatOpen = false);
                                        context.go('/mentor');
                                      },
                                      child: Text(
                                        'Open Full AI Mentor Screen →',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFFF5722),
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
                    ),
                  ),

                // ── 4. Floating Robot Trigger ──────────────
                Positioned(
                  right: 16,
                  bottom: 60,
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => isChatOpen = !isChatOpen),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: isChatOpen
                          ? Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF1B1D36),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            )
                          : Image.asset(
                              'assets/images/robot-for-chatbot.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.smart_toy_rounded,
                                color: Color(0xFF7C5CBF),
                                size: 30,
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
    );
  }

  // ── Helper Widgets & Sections ───────────────────────────────────

  Widget _buildActiveTrackCard(String track, int doneCount, int totalWeeks,
      double progress, Map<dynamic, dynamic> currentWeek) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAEAF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE ROADMAP',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFFF5722),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      track,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$doneCount / $totalWeeks WEEKS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF7C5CBF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFF0EDF8),
              valueColor:
                  const AlwaysStoppedAnimation(Color(0xFFFF5722)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Next: ${currentWeek['title'] ?? 'Week 1 Milestone'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF6B6890),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => context
                    .go('/roadmap?track=${Uri.encodeComponent(track)}'),
                child: Text(
                  'Continue →',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFF5722),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🤖 AI Mentor Featured Banner (100% Overflow-Free & Crisp White Text)
  Widget _buildAiMentorBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/mentor'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C5CBF).withOpacity(0.18),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(
                  'assets/AI-mentor-guidance.jpeg',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) => Image.network(
                    'https://raw.githubusercontent.com/Snehachoudhary26/pathforge/main/assets/AI-mentor-guidance.jpeg',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1B1D36),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF111322).withOpacity(0.92),
                        const Color(0xFF111322).withOpacity(0.15),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.65],
                    ),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5722),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'AI MENTOR',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '24/7 Personalized Career Coaching',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Ask DSA, Roadmaps & Strategy',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Chat Now',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF111322),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Color(0xFF111322),
                                  size: 10,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Agentic Tools Row
  Widget _buildAgenticToolsRow(BuildContext context, String track) {
    return Column(
      children: [
        _ToolItemTile(
          icon: Icons.auto_graph_rounded,
          iconColor: const Color(0xFF00B894),
          iconBg: const Color(0xFFE6F8F4),
          title: 'Job Market Analyser',
          badgeText: 'Agentic AI',
          subtitle: 'Real-time demand, salary & trending skills',
          onTap: () => context.go('/job-market'),
        ),
        const SizedBox(height: 8),
        _ToolItemTile(
          icon: Icons.edit_document,
          iconColor: const Color(0xFFFF5722),
          iconBg: const Color(0xFFFFECE5),
          title: 'AI Resume Rewriter',
          badgeText: 'Agentic AI',
          subtitle: 'Paste any job → AI rewrites your resume',
          onTap: () => context.go('/resume-rewriter'),
        ),
        const SizedBox(height: 8),
        _ToolItemTile(
          icon: Icons.document_scanner_rounded,
          iconColor: const Color(0xFF7C5CBF),
          iconBg: const Color(0xFFF0EDF8),
          title: 'Scan your resume',
          badgeText: 'New',
          badgeColor: const Color(0xFF7C5CBF),
          subtitle: 'Find skill gaps for your track',
          onTap: () => context.go('/resume-scanner'),
        ),
      ],
    );
  }

  // 👨‍💻 Job Readiness Score Card
  Widget _buildJobReadinessCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B1D36),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFFF5722),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '0',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
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
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Getting Started · Tap to see breakdown',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: const Color(0xFF9B99B5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => context.go('/job-readiness'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5722),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'View',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 👨‍💻 Career Placement Goal Card
  Widget _buildPlacementGoalCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/job-readiness'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9.5,
                child: Image.asset(
                  'assets/men-with-laptop.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) => Image.network(
                    'https://raw.githubusercontent.com/Snehachoudhary26/pathforge/main/assets/men-with-laptop.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF4A2BB8),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF111322).withOpacity(0.92),
                        const Color(0xFF111322).withOpacity(0.12),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.6],
                    ),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5722),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'CAREER GOAL',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Placement Ready: ₹12–25 LPA',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Master your roadmap to crack dream campus offers',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: const Color(0xFFD6C8F5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoachCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2FBF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC7EEDB)),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF00B894),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 15,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'AI coach · live',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF00B894),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5722),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  coachInsight.isNotEmpty
                      ? coachInsight
                      : 'Start Week 1 of Data Scientist today — the first step is the hardest. 12 weeks from now you will be interview-ready.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF1B1D36),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🚀 Leaderboard & Study Group Card
  Widget _buildLeaderboardSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E9F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(18)),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.asset(
                    'assets/GroupProgress.jpeg',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => Image.network(
                      'https://raw.githubusercontent.com/Snehachoudhary26/pathforge/main/assets/GroupProgress.jpeg',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF1B1D36),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF111322).withOpacity(0.9),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        stops: const [0.0, 0.55],
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    alignment: Alignment.bottomLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Peer Study Leaderboard',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const Icon(
                          Icons.emoji_events_rounded,
                          color: Color(0xFFFFC107),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('🥇', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(
                      'Sarthak',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
                Text(
                  '400 XP',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF7C5CBF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakTargetCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE8B3)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'This week — don\'t break it!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B1D36),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Color(0xFFFF5722),
                    size: 14,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '$streak days',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFFF5722),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DayPill('M', false),
              _DayPill('T', false),
              _DayPill('W', false),
              _DayPill('T', false),
              _DayPill('F', false),
              _DayPill('S', false),
              _DayPill('S', true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(String track) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2DCF2)),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF7C5CBF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily 5-Min Challenge',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1B1D36),
                  ),
                ),
                Text(
                  'Earn +50 XP towards Level ${_level + 1}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: const Color(0xFF6B6890),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => isChatOpen = true),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF7C5CBF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Start',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, String track) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEAEAF2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
              Icons.home_rounded, Icons.home_rounded, 'Home', true, () {}),
          _NavItem(Icons.map_outlined, Icons.map_rounded, 'Roadmap', false,
              () => context.go('/roadmap?track=${Uri.encodeComponent(track)}')),
          _NavItem(Icons.play_circle_outline, Icons.play_circle, 'Resources',
              false, () => context.go('/resources')),
          _NavItem(Icons.person_outline, Icons.person_rounded, 'Profile', false,
              () => context.go('/profile')),
        ],
      ),
    );
  }
}

// ── Supporting Stateless Widgets ──────────────────────────────────

class _StatPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  const _StatPill(
      {required this.icon, required this.iconColor, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 13),
          const SizedBox(width: 3),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolItemTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String badgeText;
  final Color? badgeColor;
  final String subtitle;
  final VoidCallback onTap;

  const _ToolItemTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.badgeText,
    this.badgeColor,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bColor = badgeColor ?? const Color(0xFF00B894);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEAEAF2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1B1D36),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: bColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badgeText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: bColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: const Color(0xFF6B6890),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9B99B5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  final String day;
  final bool active;
  const _DayPill(this.day, this.active);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFF5722) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: active ? const Color(0xFFFF5722) : const Color(0xFFE2E4F0),
        ),
      ),
      child: Center(
        child: Text(
          day,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? Colors.white : const Color(0xFF6B6890),
          ),
        ),
      ),
    );
  }
}

Widget _NavItem(IconData icon, IconData activeIcon, String label,
    bool active, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFFEFEA) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? activeIcon : icon,
            color: active ? const Color(0xFFFF5722) : const Color(0xFF9B99B5),
            size: 20,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              color:
                  active ? const Color(0xFFFF5722) : const Color(0xFF9B99B5),
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}
