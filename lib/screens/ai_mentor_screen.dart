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
    if (uid == null) { setState(() => _isLoading = false); return; }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(uid).get();
      final roadmapSnap = await FirebaseFirestore.instance
          .collection('roadmaps')
          .where('uid', isEqualTo: uid)
          .limit(1).get();

      final userData = userDoc.data() ?? {};
      final roadmap = roadmapSnap.docs.isNotEmpty
          ? roadmapSnap.docs.first.data() : null;
      final weeks = roadmap?['weeks'] as List? ?? [];
      final doneWeeks =
          weeks.where((w) => w['status'] == 'done').length;

      // Load chat history from Firestore
      final historyDoc = await FirebaseFirestore.instance
          .collection('mentor_chats').doc(uid).get();
      final history = historyDoc.exists
          ? List<Map<String, dynamic>>.from(
              (historyDoc.data()?['messages'] ?? [])
                  .map((m) => Map<String, dynamic>.from(m)))
          : [];

      setState(() {
        _userContext = {
          'name': userData['name'] ?? 'Student',
          'track': roadmap?['track'] ?? '',
          'doneWeeks': doneWeeks,
          'totalWeeks': weeks.length,
          'xp': userData['xp'] ?? 0,
          'streak': userData['streak'] ?? 0,
          'level': userData['levelName'] ?? 'Code Newcomer',
          'goal': userData['goal'] ?? 'Get a job',
          'branch': userData['branch'] ?? 'Engineering',
          'year': userData['year'] ?? '3rd Year',
          'experience': userData['experience'] ?? 'Beginner',
        };
        _messages = List<Map<String, dynamic>>.from(history);
        _isLoading = false;
      });

      // Welcome message if first time
      if (_messages.isEmpty) {
        _addBotMessage(
          'Hi ${_userContext['name']}! 👋 I\'m your AI mentor. I know everything about your PathForge journey — you\'re $doneWeeks/${weeks.length} weeks through ${_userContext['track']}, with ${_userContext['xp']} XP and a ${_userContext['streak']}-day streak.\n\nAsk me anything about your career, roadmap, or skills!',
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
    final streak = _userContext['streak'] ?? 0;
    final goal = _userContext['goal'] ?? 'Get a job';
    final branch = _userContext['branch'] ?? 'Engineering';
    final year = _userContext['year'] ?? '3rd Year';

    final recentHistory = _messages.length > 6
        ? _messages.sublist(_messages.length - 6)
        : _messages;
    final historyText = recentHistory
        .map((m) => (m['role'] == 'user' ? 'Student: ' : 'Mentor: ') + (m['text'] ?? ''))
        .join('\n');

    final prompt = 'You are an expert AI career mentor for Indian engineering students. '
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
          'temperature': 0.9,
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
      // Keep last 20 messages only
      final toSave = _messages.length > 20
          ? _messages.sublist(_messages.length - 20)
          : _messages;
      await FirebaseFirestore.instance
          .collection('mentor_chats').doc(uid).set({
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
        .collection('mentor_chats').doc(uid).delete();
    _addBotMessage(
        'Chat cleared! Hi ${_userContext['name']}, I\'m ready for a fresh conversation. What would you like to talk about?');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Column(children: [
          // Header
          Container(
            color: AppTheme.navy,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
              // Mentor avatar
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.psychology_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('AI Mentor',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 18, fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppTheme.green.withOpacity(0.5)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                              color: AppTheme.green,
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        Text('Online',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 9, fontWeight: FontWeight.w700,
                                color: AppTheme.green)),
                      ]),
                    ),
                  ]),
                  Text('Knows your full journey · Remembers chats',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 10, color: Colors.white54)),
                ],
              )),
              GestureDetector(
                onTap: _clearHistory,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Colors.white54, size: 18),
                ),
              ),
            ]),
          ),

          // User context strip
          if (_userContext.isNotEmpty)
            Container(
              color: AppTheme.navy.withOpacity(0.95),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(children: [
                _ContextPill(
                    '${_userContext['track']}', AppTheme.orange),
                const SizedBox(width: 8),
                _ContextPill(
                    '${_userContext['doneWeeks']}/${_userContext['totalWeeks']} weeks',
                    AppTheme.primary),
                const SizedBox(width: 8),
                _ContextPill(
                    '${_userContext['xp']} XP', AppTheme.amber),
              ]),
            ),

          // Messages
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(
                    color: AppTheme.green))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (_isTyping && i == _messages.length) {
                        return _TypingIndicator();
                      }
                      final msg = _messages[i];
                      final isUser = msg['role'] == 'user';
                      return _MessageBubble(
                          text: msg['text'] ?? '',
                          isUser: isUser);
                    },
                  ),
          ),

          // Quick suggestions
          if (_messages.length <= 2)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _QuickChip('How do I improve my score?',
                      _msgController, _sendMessage),
                  _QuickChip('What should I learn next?',
                      _msgController, _sendMessage),
                  _QuickChip('How to get my first job?',
                      _msgController, _sendMessage),
                  _QuickChip('Review my progress',
                      _msgController, _sendMessage),
                ]),
              ),
            ),

          // Input area
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _msgController,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, color: AppTheme.textDark),
                  decoration: InputDecoration(
                    hintText: 'Ask your mentor anything...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 15, color: AppTheme.textLight),
                    filled: true,
                    fillColor: AppTheme.cream,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  textInputAction: TextInputAction.send,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: _isTyping
                        ? AppTheme.border : AppTheme.navy,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: _isTyping
                        ? AppTheme.textLight : Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const _MessageBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser) ...[
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppTheme.green,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.psychology_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser ? AppTheme.navy : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
              border: isUser
                  ? null
                  : Border.all(color: AppTheme.border),
            ),
            child: Text(text,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: isUser ? Colors.white : AppTheme.textDark,
                    height: 1.6)),
          ),
        ),
        if (isUser) const SizedBox(width: 8),
      ],
    ),
  );
}

class _TypingIndicator extends StatefulWidget {
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
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: AppTheme.green,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.psychology_rounded,
            color: Colors.white, size: 18),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AppTheme.border),
        ),
        child: FadeTransition(
          opacity: _anim,
          child: Row(children: [
            _Dot(AppTheme.green),
            const SizedBox(width: 4),
            _Dot(AppTheme.primary),
            const SizedBox(width: 4),
            _Dot(AppTheme.orange),
          ]),
        ),
      ),
    ]),
  );
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot(this.color);
  @override
  Widget build(BuildContext context) => Container(
    width: 8, height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _ContextPill extends StatelessWidget {
  final String label;
  final Color color;
  const _ContextPill(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(label,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w600, color: color),
        maxLines: 1, overflow: TextOverflow.ellipsis),
  );
}

class _QuickChip extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onSend;
  const _QuickChip(this.label, this.controller, this.onSend);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      controller.text = label;
      onSend();
    },
    child: Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.purpleLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.purpleBorder),
      ),
      child: Text(label,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: AppTheme.primary)),
    ),
  );
}
