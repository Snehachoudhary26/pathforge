import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../core/theme.dart';

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
      final doneWeeks = weeks.where((w) => w['status'] == 'done').length;

      final historyDoc = await FirebaseFirestore.instance
          .collection('mentor_chats')
          .doc(uid)
          .get();
      final history = historyDoc.exists
          ? List<Map<String, dynamic>>.from(
              (historyDoc.data()?['messages'] ?? [])
                  .map((m) => Map<String, dynamic>.from(m)),
            )
          : [];

      setState(() {
        _userContext = {
          'name': userData['name'] ?? 'Student',
          'track': roadmap?['track'] ?? 'Frontend Developer',
          'doneWeeks': doneWeeks,
          'totalWeeks': weeks.isEmpty ? 12 : weeks.length,
          'xp': userData['xp'] ?? 0,
          'streak': userData['streak'] ?? 1,
          'level': userData['levelName'] ?? 'Code Newcomer',
          'goal': userData['goal'] ?? 'Get a job',
          'branch': userData['branch'] ?? 'Engineering',
          'year': userData['year'] ?? '3rd Year',
          'experience': userData['experience'] ?? 'Beginner',
        };
        _messages = List<Map<String, dynamic>>.from(history);
        _isLoading = false;
      });

      if (_messages.isEmpty) {
        _addBotMessage(
          'Hi ${_userContext['name']}! 👋 I\'m your AI mentor. I know everything about your PathForge journey — you\'re $doneWeeks/${_userContext['totalWeeks']} weeks through ${_userContext['track']}, with ${_userContext['xp']} XP and a ${_userContext['streak']}-day streak.\n\nAsk me anything about your career, roadmap, or skills!',
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

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
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
    const apiKey = AppConfig.groqApiKey;
    const groqUrl = AppConfig.groqUrl;
    const model = AppConfig.groqModel;

    final name = _userContext['name'] ?? 'Student';
    final track = _userContext['track'] ?? 'Software Engineer';
    final doneWeeks = _userContext['doneWeeks'] ?? 0;
    final totalWeeks = _userContext['totalWeeks'] ?? 12;
    final xp = _userContext['xp'] ?? 0;
    final streak = _userContext['streak'] ?? 1;
    final goal = _userContext['goal'] ?? 'Get a job';
    final branch = _userContext['branch'] ?? 'Engineering';
    final year = _userContext['year'] ?? '3rd Year';

    final recentHistory =
        _messages.length > 6 ? _messages.sublist(_messages.length - 6) : _messages;
    final historyText = recentHistory
        .map((m) =>
            (m['role'] == 'user' ? 'Student: ' : 'Mentor: ') +
            (m['text'] ?? ''))
        .join('\n');

    final prompt =
        'You are an expert AI career mentor for Indian engineering students. '
        'Student name: $name. '
        'Track: $track. '
        'Progress: $doneWeeks of $totalWeeks weeks done. '
        'XP: $xp. Streak: $streak days. Goal: $goal. '
        'Branch: $branch. Year: $year. '
        'Recent conversation:\n$historyText\n'
        'Student just asked: "$userMessage"\n'
        'Give a specific, helpful answer to exactly what they asked. '
        'Reference their actual data. Under 100 words. '
        'Do not repeat previous answers. Be a real mentor, not a chatbot.';

    try {
      final response = await http.post(
        Uri.parse(groqUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + apiKey,
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.85,
          'max_tokens': 250,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'] as String;
        if (mounted) setState(() => _isTyping = false);
        _addBotMessage(reply.trim());
      } else {
        if (mounted) setState(() => _isTyping = false);
        _addBotMessage(_fallbackReply(userMessage));
      }
    } catch (e) {
      if (mounted) setState(() => _isTyping = false);
      _addBotMessage(_fallbackReply(userMessage));
    }
  }

  String _fallbackReply(String msg) {
    final name = _userContext['name'] ?? 'Student';
    final track = _userContext['track'] ?? 'your track';
    final done = _userContext['doneWeeks'] ?? 0;
    final total = _userContext['totalWeeks'] ?? 12;
    return 'Great question, $name! Based on your progress ($done/$total weeks in $track), I\'d recommend focusing on completing your current week first. Consistency beats intensity — your ${_userContext['streak']}-day streak shows you have the discipline. Keep going!';
  }

  Future<void> _saveHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final toSave = _messages.length > 20
          ? _messages.sublist(_messages.length - 20)
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
      'Chat cleared! Hi ${_userContext['name']}, I\'m ready for a fresh conversation. What would you like to talk about?',
    );
  }

  @override
  Widget build(BuildContext context) {
    final track = _userContext['track'] ?? 'Frontend Developer';
    final done = _userContext['doneWeeks'] ?? 0;
    final total = _userContext['totalWeeks'] ?? 12;
    final xp = _userContext['xp'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF111322),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Container(
              color: const Color(0xFFF8F9FE),
              child: Column(
                children: [
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
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF7C5CBF),
                                    Color(0xFFFF5722),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7C5CBF).withOpacity(0.3),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(2),
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Image.asset(
                                      'assets/logo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.trending_up,
                                        size: 16,
                                        color: Color(0xFF7C5CBF),
                                      ),
                                    ),
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
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00B894)
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: const Color(0xFF00B894)
                                                .withOpacity(0.4),
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
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF55EFC4),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Knows your full journey • Remembers chats',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
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
                                  color: Colors.white.withOpacity(0.08),
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
                        const SizedBox(height: 12),

                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _ContextPill(
                                track,
                                const Color(0xFFFF5722),
                                const Color(0xFFFFF3EE),
                              ),
                              const SizedBox(width: 8),
                              _ContextPill(
                                '$done/$total weeks',
                                const Color(0xFF7C5CBF),
                                const Color(0xFFF5F3FF),
                              ),
                              const SizedBox(width: 8),
                              _ContextPill(
                                '$xp XP',
                                const Color(0xFFD48806),
                                const Color(0xFFFFFBE6),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF7C5CBF),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            itemCount:
                                _messages.length + (_isTyping ? 1 : 0),
                            itemBuilder: (ctx, i) {
                              if (i == _messages.length && _isTyping) {
                                return const _TypingIndicator();
                              }
                              final m = _messages[i];
                              return _MessageBubble(
                                text: m['text'] ?? '',
                                isUser: m['role'] == 'user',
                              );
                            },
                          ),
                  ),

                  if (!_isTyping)
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _QuickChip(
                              '💡 How do I improve my score?',
                              _msgController,
                              _sendMessage,
                            ),
                            _QuickChip(
                              '📚 What should I learn first?',
                              _msgController,
                              _sendMessage,
                            ),
                            _QuickChip(
                              '🚀 HTML/CSS Project Ideas',
                              _msgController,
                              _sendMessage,
                            ),
                            _QuickChip(
                              '⚡ Review my progress',
                              _msgController,
                              _sendMessage,
                            ),
                          ],
                        ),
                      ),
                    ),

                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _msgController,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              color: const Color(0xFF1A1A2E),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Ask your mentor anything...',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                color: const Color(0xFF9B99B5),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF5F6FA),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 13,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                            textInputAction: TextInputAction.send,
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _sendMessage,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _isTyping
                                  ? const Color(0xFFE2E4F0)
                                  : const Color(0xFFFF5722),
                              shape: BoxShape.circle,
                              boxShadow: _isTyping
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: const Color(0xFFFF5722)
                                            .withOpacity(0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                            ),
                            child: Icon(
                              Icons.send_rounded,
                              color: _isTyping
                                  ? const Color(0xFF9B99B5)
                                  : Colors.white,
                              size: 19,
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
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const _MessageBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C5CBF).withOpacity(0.12),
                border: Border.all(
                  color: const Color(0xFF7C5CBF).withOpacity(0.25),
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/robot-for-chatbot.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/ai_mentor_guidance.jpeg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.smart_toy_rounded,
                      color: Color(0xFF7C5CBF),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF1B1D36) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? null
                    : Border.all(color: const Color(0xFFE2E4F0), width: 1.1),
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
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                  color: isUser ? Colors.white : const Color(0xFF111322),
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 6),
        ],
      ),
    );
  }
}

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
    _anim = Tween(begin: 0.35, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
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
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: const Color(0xFFE2E4F0)),
            ),
            child: FadeTransition(
              opacity: _anim,
              child: Row(
                children: [
                  _Dot(const Color(0xFF7C5CBF)),
                  const SizedBox(width: 4),
                  _Dot(const Color(0xFFFF5722)),
                  const SizedBox(width: 4),
                  _Dot(const Color(0xFF00B894)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot(this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onSend;
  const _QuickChip(this.label, this.controller, this.onSend);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        controller.text = label;
        onSend();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E4F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4D3B82),
          ),
        ),
      ),
    );
  }
}
