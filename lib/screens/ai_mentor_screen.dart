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
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, String>> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;
  Map<String, dynamic> _userContext = {};

  final List<String> _quickQuestions = [
    '💡 How do I improve my score?',
    '📚 What should I learn first?',
    '💼 Recommend a portfolio project',
    '⚡ Give me a 5-min DSA challenge',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserAndChatHistory();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndChatHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final rSnap = await FirebaseFirestore.instance
          .collection('roadmaps')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      final userData = userDoc.data() ?? {};
      Map<String, dynamic>? roadmapData;
      if (rSnap.docs.isNotEmpty) {
        roadmapData = rSnap.docs.first.data();
      }

      final weeks = roadmapData?['weeks'] as List? ?? [];
      final doneWeeks = weeks.where((w) => w['status'] == 'done').length;

      _userContext = {
        'name': userData['name'] ?? 'Engineer',
        'track': roadmapData?['track'] ?? userData['track'] ?? 'General Tech',
        'doneWeeks': doneWeeks,
        'totalWeeks': weeks.isEmpty ? 12 : weeks.length,
        'xp': userData['xp'] ?? 0,
        'streak': userData['streak'] ?? 1,
        'goal': userData['goal'] ?? 'Get placed at top tech company',
        'experience': userData['experience'] ?? 'Beginner',
      };

      final chatDoc = await FirebaseFirestore.instance
          .collection('mentor_chats')
          .doc(uid)
          .get();

      if (chatDoc.exists && chatDoc.data()?['messages'] != null) {
        final savedList = chatDoc.data()!['messages'] as List;
        _messages = savedList
            .map((m) => {
                  'role': (m['role'] ?? 'assistant').toString(),
                  'text': (m['text'] ?? '').toString(),
                })
            .toList();
      } else {
        _messages = [
          {
            'role': 'assistant',
            'text':
                'Hi ${_userContext['name']}! 👋 I\'m your PathForge AI Mentor. I know everything about your learning journey — you\'re ${_userContext['doneWeeks']}/${_userContext['totalWeeks']} weeks through ${_userContext['track']}, with ${_userContext['xp']} XP and a ${_userContext['streak']}-day streak.\n\nAsk me anything about your career, roadmap, or skills!',
          }
        ];
      }
    } catch (_) {
      _messages = [
        {
          'role': 'assistant',
          'text':
              'Hi there! 👋 I\'m your PathForge AI Mentor. How can I help you accelerate your tech career today?',
        }
      ];
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  void _sendMessage([String? presetText]) async {
    final text = (presetText ?? _msgController.text).trim();
    if (text.isEmpty || _isTyping) return;

    _msgController.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final reply = await AiEngine.getMentorResponse(
        userMessage: text,
        userContext: _userContext,
        conversationHistory: _messages,
      );

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({'role': 'assistant', 'text': reply});
        });
        _scrollToBottom();
        _persistChat();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({
            'role': 'assistant',
            'text':
                'I\'m having trouble connecting right now, but keep pushing forward with your roadmap goals! Ask again in a moment.',
          });
        });
        _scrollToBottom();
      }
    }
  }

  void _persistChat() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final toSave = _messages.length > 50
          ? _messages.sublist(_messages.length - 50)
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
    setState(() {
      _messages.add({
        'role': 'assistant',
        'text':
            'Chat cleared! Hi ${_userContext['name']}, I\'m ready for a fresh conversation. What would you like to ask?',
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── Top Navy Header (Compact) ────────────────────────
            Container(
              color: const Color(0xFF111322),
              padding: EdgeInsets.fromLTRB(
                12,
                topPadding > 0 ? topPadding + 6 : 18,
                12,
                8,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/home'),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Robot Avatar
                      Container(
                        width: 28,
                        height: 28,
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
                              size: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Title & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'AI Mentor',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00B894)
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF00B894)
                                          .withOpacity(0.4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 3.5,
                                        height: 3.5,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF00B894),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 2.5),
                                      Text(
                                        'Online',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 8,
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
                              'Knows your journey · Remembers chats',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                color: const Color(0xFFB3B0D6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Clear Chat Button
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(
                                'Clear Conversation?',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              content: Text(
                                'This will clear all previous messages with your AI Mentor.',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _clearHistory();
                                  },
                                  child: Text(
                                    'Clear',
                                    style: TextStyle(
                                        color: Colors.red.shade600),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white70,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Horizontal Context Badges
                  if (_userContext.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _ContextPill(
                            '${_userContext['track']}',
                            const Color(0xFFFF5722),
                            const Color(0xFFFFF0EC),
                          ),
                          const SizedBox(width: 5),
                          _ContextPill(
                            '${_userContext['doneWeeks']}/${_userContext['totalWeeks']} weeks',
                            const Color(0xFF7C5CBF),
                            const Color(0xFFF3EFFB),
                          ),
                          const SizedBox(width: 5),
                          _ContextPill(
                            '${_userContext['xp']} XP',
                            const Color(0xFFE08D00),
                            const Color(0xFFFEFBE8),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ── Message Stream Area (Compact font & padding) ─────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF5722),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                      itemCount: _messages.length +
                          (_isTyping ? 1 : 0),
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

            // ── Suggested Quick Question Chips (Compact & All Visible) ─
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _quickQuestions.map((q) {
                    return _QuickChip(q, () => _sendMessage(q));
                  }).toList(),
                ),
              ),
            ),

            // ── Bottom Input Bar (Compact) ───────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4FA),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: TextField(
                        controller: _msgController,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF1A1A2E),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask your mentor anything...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            color: const Color(0xFF9B99B5),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                        textInputAction: TextInputAction.send,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _sendMessage(),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _isTyping
                            ? const Color(0xFFD4D6E2)
                            : const Color(0xFFFF5722),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5722).withOpacity(0.3),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 15,
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

// ── Message Bubble (Standardized Compact Mobile Fonts) ────────────
class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const _MessageBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
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
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1D36),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  text,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    color: Colors.white,
                    height: 1.3,
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
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
                  size: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(3),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border.all(color: const Color(0xFFE8E9F2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  color: const Color(0xFF1A1A2E),
                  height: 1.32,
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

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
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
                  size: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE8E9F2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 9,
                  height: 9,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.2,
                    color: Color(0xFF7C5CBF),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Thinking...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    color: const Color(0xFF7C5CBF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Context Pill ──────────────────────────────────────────────────
class _ContextPill extends StatelessWidget {
  final String text;
  final Color color;
  final Color bg;
  const _ContextPill(this.text, this.color, this.bg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── Quick Chip (Compact & Neat) ──────────────────────────────────
class _QuickChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _QuickChip(this.text, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 5),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F0FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2DCF2)),
        ),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B1D36),
          ),
        ),
      ),
    );
  }
}
