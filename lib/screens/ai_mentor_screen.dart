import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ai_engine.dart';

class AiMentorScreen extends StatefulWidget {
  const AiMentorScreen({super.key});
  @override
  State<AiMentorScreen> createState() => _AiMentorScreenState();
}

class _AiMentorScreenState extends State<AiMentorScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  Map<String, dynamic> _userContext = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContext() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final roadmapSnap = await FirebaseFirestore.instance
          .collection('roadmaps')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      final userData = userDoc.data() ?? {};
      final roadmap =
          roadmapSnap.docs.isNotEmpty ? roadmapSnap.docs.first.data() : null;
      final weeks = roadmap?['weeks'] as List? ?? [];
      final doneWeeks =
          weeks.where((w) => w['status'] == 'done').length;

      // Load chat history from Firestore
      final historyDoc = await FirebaseFirestore.instance
          .collection('mentor_chats')
          .doc(uid)
          .get();
      final history = historyDoc.exists
          ? List<Map<String, dynamic>>.from(
              (historyDoc.data()?['messages'] ?? [])
                  .map((m) => Map<String, dynamic>.from(m)))
          : [];

      setState(() {
        _userContext = {
          'name': userData['name'] ?? 'Student',
          'track': roadmap?['track'] ?? 'Data Scientist',
          'doneWeeks': doneWeeks,
          'totalWeeks': weeks.isEmpty ? 12 : weeks.length,
          'xp': userData['xp'] ?? 0,
          'streak': userData['streak'] ?? 1,
          'level': userData['levelName'] ?? 'Code Newcomer',
          'goal': userData['goal'] ?? 'Get a high-paying tech job',
          'branch': userData['branch'] ?? 'Engineering',
          'year': userData['year'] ?? '3rd Year',
          'experience': userData['experience'] ?? 'Beginner',
        };
        _messages = List<Map<String, dynamic>>.from(history);
        _isLoading = false;
      });

      // Initial welcome message if fresh conversation
      if (_messages.isEmpty) {
        _addBotMessage(
          'Hi ${_userContext['name']}! 👋 I\'m your AI Career Mentor. I know everything about your PathForge journey — you\'re $doneWeeks/${_userContext['totalWeeks']} weeks through ${_userContext['track']}, with ${_userContext['xp']} XP and a ${_userContext['streak']}-day streak.\n\nAsk me anything about your career, roadmap, or skills!',
        );
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add({
        'role': 'assistant',
        'text': text,
        'time': DateTime.now().toIso8601String(),
      });
    });
    _saveHistory();
    _scrollToBottom();
  }

  Future<void> _sendMessage([String? presetText]) async {
    final text = (presetText ?? _msgController.text).trim();
    if (text.isEmpty || _isTyping) return;

    _msgController.clear();
    setState(() {
      _messages.add({
        'role': 'user',
        'text': text,
        'time': DateTime.now().toIso8601String(),
      });
      _isTyping = true;
    });
    _scrollToBottom();

    await _getAIResponse(text);
  }

  Future<void> _getAIResponse(String userMessage) async {
    final reply = await AiEngine.getMentorResponse(
      userMessage: userMessage,
      userContext: _userContext,
      conversationHistory: _messages,
    );

    if (mounted) {
      setState(() => _isTyping = false);
      _addBotMessage(reply);
    }
  }

  Future<void> _saveHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final toSave = _messages.length > 25
          ? _messages.sublist(_messages.length - 25)
          : _messages;
      await FirebaseFirestore.instance
          .collection('mentor_chats')
          .doc(uid)
          .set({
        'messages': toSave,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _messages = []);
    await FirebaseFirestore.instance
        .collection('mentor_chats')
        .doc(uid)
        .delete();
    _addBotMessage(
      'Chat cleared! Hi ${_userContext['name']}, I\'m ready for a fresh conversation. What would you like to ask?',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top Header
            Container(
              color: const Color(0xFF111322),
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 12,
                16,
                14,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/home'),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white12,
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
                      // Robot Avatar
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white12,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/robot-for-chatbot.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.smart_toy_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'AI Mentor',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00B894)
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF00B894)
                                          .withOpacity(0.5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF00B894),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Online',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF00B894),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Knows your full journey • Remembers chats',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFFB3B0D6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _clearHistory,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white70,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // User Context Badges Strip
                  if (_userContext.isNotEmpty)
                    Row(
                      children: [
                        _ContextPill(
                          '${_userContext['track']}',
                          const Color(0xFFFF5722),
                          const Color(0xFFFFF0EC),
                        ),
                        const SizedBox(width: 8),
                        _ContextPill(
                          '${_userContext['doneWeeks']}/${_userContext['totalWeeks']} weeks',
                          const Color(0xFF7C5CBF),
                          const Color(0xFFF3EFFB),
                        ),
                        const SizedBox(width: 8),
                        _ContextPill(
                          '${_userContext['xp']} XP',
                          const Color(0xFFE08D00),
                          const Color(0xFFFEFBE8),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Message Stream Area
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF5722),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      itemCount: _messages.length + (_isTyping ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (_isTyping && i == _messages.length) {
                          return const _TypingIndicator();
                        }
                        final msg = _messages[i];
                        final isUser = msg['role'] == 'user';
                        return _MessageBubble(
                          text: msg['text'] ?? '',
                          isUser: isUser,
                        );
                      },
                    ),
            ),

            // Suggested Quick Question Chips
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _QuickChip(
                      '💡 How do I improve my score?',
                      () => _sendMessage('💡 How do I improve my score?'),
                    ),
                    _QuickChip(
                      '📚 What should I learn first?',
                      () => _sendMessage('📚 What should I learn first?'),
                    ),
                    _QuickChip(
                      '🚀 HTML/CSS Project Ideas',
                      () => _sendMessage('🚀 HTML/CSS Project Ideas'),
                    ),
                    _QuickChip(
                      '🔥 Give me a coding challenge',
                      () => _sendMessage('🔥 Give me a 5-minute coding challenge'),
                    ),
                    _QuickChip(
                      '💼 Expected Salary for my track',
                      () => _sendMessage('💼 What salary can I expect for my track?'),
                    ),
                  ],
                ),
              ),
            ),

            // Input Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFF1A1A2E),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ask your mentor anything...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFFA5A3C0),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F6FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFE2E4F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFE2E4F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                              color: Color(0xFFFF5722), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _isTyping
                            ? const Color(0xFFD4D6E2)
                            : const Color(0xFFFF5722),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5722).withOpacity(0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Message Bubble ────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const _MessageBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1D36),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  text,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Assistant Bot Bubble
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF0EDF8),
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
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: const Color(0xFFE8E9F2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  color: const Color(0xFF1A1A2E),
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Typing Indicator ──────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF0EDF8),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Color(0xFF7C5CBF),
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8E9F2)),
            ),
            child: FadeTransition(
              opacity: _anim,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dot(const Color(0xFF7C5CBF)),
                  const SizedBox(width: 4),
                  _dot(const Color(0xFFFF5722)),
                  const SizedBox(width: 4),
                  _dot(const Color(0xFF00B894)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}

// ── Context Pill ──────────────────────────────────────────────────
class _ContextPill extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color bgColor;
  const _ContextPill(this.label, this.textColor, this.bgColor);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

// ── Quick Suggestion Chip ─────────────────────────────────────────
class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickChip(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F0FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2DCF2)),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B1D36),
          ),
        ),
      ),
    );
  }
}
