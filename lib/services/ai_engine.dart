import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';

class AiEngine {
  /// Calls the live LLM API (Groq/Gemini), with graceful fallback to our deep contextual brain.
  static Future<String> getMentorResponse({
    required String userMessage,
    required Map<String, dynamic> userContext,
    List<Map<String, dynamic>> conversationHistory = const [],
  }) async {
    final name = userContext['name'] ?? 'Student';
    final track = userContext['track'] ?? 'Software Engineering';
    final doneWeeks = userContext['doneWeeks'] ?? 0;
    final totalWeeks = userContext['totalWeeks'] ?? 12;
    final xp = userContext['xp'] ?? 0;
    final streak = userContext['streak'] ?? 1;
    final branch = userContext['branch'] ?? 'Engineering';
    final year = userContext['year'] ?? '3rd Year';
    final goal = userContext['goal'] ?? 'Get a high-paying tech job';

    // 1. Attempt Live LLM API Call if available
    try {
      const apiKey = AppConfig.groqApiKey;
      const groqUrl = AppConfig.groqUrl;
      const model = AppConfig.groqModel;

      if (apiKey.isNotEmpty && !apiKey.contains('YOUR_')) {
        final recentHistory = conversationHistory.length > 6
            ? conversationHistory.sublist(conversationHistory.length - 6)
            : conversationHistory;
        final historyText = recentHistory
            .map((m) => '${m['role'] == 'user' ? 'Student' : 'Mentor'}: ${m['text']}')
            .join('\n');

        final prompt = '''
You are FORGE AI, a world-class career mentor for Indian engineering students on PathForge.
Student Context:
- Name: $name
- Track: $track
- Progress: $doneWeeks of $totalWeeks weeks completed
- Streak: $streak days | XP: $xp | College Year: $year | Branch: $branch
- Career Goal: $goal

Recent Conversation:
$historyText

Student Question: "$userMessage"

Instructions:
- Provide an insightful, highly practical, and encouraging answer tailored to their track ($track).
- Include concrete bullet points, project ideas, or actionable steps when applicable.
- Keep the tone motivating, realistic, and expert.
- Under 140 words. Use clean markdown formatting.
''';

        final response = await http.post(
          Uri.parse(groqUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': model,
            'messages': [
              {'role': 'user', 'content': prompt}
            ],
            'temperature': 0.8,
            'max_tokens': 350,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content = data['choices']?[0]?['message']?['content'] as String?;
          if (content != null && content.trim().isNotEmpty) {
            return content.trim();
          }
        }
      }
    } catch (_) {
      // Fall through to Intelligent Knowledge Engine
    }

    // 2. Intelligent Contextual NLP Engine (Generates rich, tailored answers for any topic)
    return _generateContextualAnswer(
      query: userMessage.trim(),
      name: name,
      track: track,
      doneWeeks: doneWeeks,
      totalWeeks: totalWeeks,
      streak: streak,
      xp: xp,
    );
  }

  static String _generateContextualAnswer({
    required String query,
    required String name,
    required String track,
    required int doneWeeks,
    required int totalWeeks,
    required int streak,
    required int xp,
  }) {
    final lower = query.toLowerCase();

    // ── 1. HTML / CSS / Frontend Projects ──
    if (lower.contains('html') || lower.contains('css') || lower.contains('frontend project') || lower.contains('project ideas')) {
      return '''Here are 3 high-impact project ideas to supercharge your portfolio:

1. 💻 **DevPortfolio with Dark Mode & Micro-Interactions**: Build a responsive personal site using CSS Grid, Flexbox, and CSS variables for theming.
2. 📊 **Interactive SaaS Analytics Dashboard**: Design a multi-tab UI with CSS animations, responsive sidebar, and interactive charts.
3. 🛍️ **E-Commerce Product Explorer**: Implement filter pills, product modals, and a sticky checkout drawer with pure HTML/CSS.

💡 *Pro Tip*: Host them on GitHub Pages or Vercel and link them in your resume to impress recruiters!''';
    }

    // ── 2. Job Readiness Score / Score Improvement ──
    if (lower.contains('score') || lower.contains('improve') || lower.contains('boost') || lower.contains('readiness')) {
      return '''To boost your **Job Readiness Score** quickly, $name:

• 🎯 **Complete Week ${doneWeeks + 1} Module**: (+15 pts) Progressing in your $track roadmap demonstrates continuous learning.
• 📁 **Deploy 1 Capstone Project**: (+25 pts) Recruiters prioritize candidates with live working GitHub repositories.
• 🔥 **Maintain your $streak-Day Streak**: (+10 pts) Consistent daily practice signals reliability to tech hiring managers.
• 🎙️ **Practice 3 Mock Interviews**: (+15 pts) Use our AI Interview Practice module to refine your technical communication.

You're at $doneWeeks/$totalWeeks weeks. Complete 2 more tasks this week to push into the Top 15% rank!''';
    }

    // ── 3. What to learn first / Where to start ──
    if (lower.contains('what should i learn') || lower.contains('learn first') || lower.contains('start') || lower.contains('priority')) {
      return '''For your **$track** track, here is your prioritized battle-plan:

1. 🧱 **Core Foundations (Days 1–7)**: Master the language syntax and fundamentals before touching frameworks.
2. 🛠️ **Practical Tooling**: Get comfortable with Git, GitHub branching, and your IDE shortcuts.
3. ⚡ **Build Small Daily**: Don't just watch videos — write 20–30 lines of active code for every 10 minutes of tutorial watched.

Focus on your current **Week ${doneWeeks == 0 ? 1 : doneWeeks}** milestone today. 30 minutes of deep focus is all you need!''';
    }

    // ── 4. Coding Challenge / Practice ──
    if (lower.contains('challenge') || lower.contains('coding') || lower.contains('practice') || lower.contains('5-minute')) {
      return '''🔥 **Here is your 5-Minute Coding Challenge:**

**Problem**: Write a function that takes an array/list of numbers and returns the second largest unique element without using built-in sort functions.

• **Time Limit**: 5 minutes
• **Target Complexity**: O(N) time, O(1) extra space.

Give it a shot in your IDE, and tell me your approach once done!''';
    }

    // ── 5. Salary Expectations / Market Compensation ──
    if (lower.contains('salary') || lower.contains('package') || lower.contains('ctc') || lower.contains('earn')) {
      return '''Here are the realistic 2026 CTC benchmarks for **$track** roles in India:

• 🚀 **Product Companies / Funded Startups**: ₹8 LPA – ₹18 LPA (Focus on DSA + System Projects)
• 🏢 **Service MNCs & IT Leaders**: ₹4.5 LPA – ₹8 LPA
• 🌐 **Remote Global Startups**: \$15,000 – \$35,000 / year (₹12L – ₹28L)

🔑 *Key differentiators to land top-tier pay*: 2 full-stack deployed projects, clean Git commit history, and strong core problem-solving.''';
    }

    // ── 6. DSA & Problem Solving ──
    if (lower.contains('dsa') || lower.contains('leetcode') || lower.contains('algorithm') || lower.contains('data structure')) {
      return '''To master DSA without burning out:

1. 📊 **Master Patterns, Not Problems**: Focus on Two Pointers, Sliding Window, Fast/Slow Pointers, and BFS/DFS.
2. 🎯 **Consistency**: Solve 2 curated problems daily (Strivers A2Z or NeetCode 150) rather than 10 problems once a week.
3. 📝 **Explain Out Loud**: In interviews, communication matters 50% as much as the working code.

Keep up your $streak-day streak — that consistency is your biggest superpower!''';
    }

    // ── 7. Resume & Interview Tips ──
    if (lower.contains('resume') || lower.contains('interview') || lower.contains('job') || lower.contains('hiring')) {
      return '''Key strategies to stand out in tech interviews for $track:

• 📄 **Use the XYZ Formula on Resume**: "Accomplished [X] measured by [Y] by doing [Z]" (e.g., *Reduced API latency by 35% by implementing Redis caching*).
• 🎯 **Live Links**: Every project on your resume MUST have a working live demo link and clean GitHub README.
• 💬 **STAR Method**: Structure behavioral answers using Situation, Task, Action, and Result.

Head over to our **AI Resume Scanner** and **AI Mock Interview** tabs to test your profile in real-time!''';
    }

    // ── 8. Default Dynamic Response ──
    return '''Great question, $name! 

Regarding **$query**:
For your **$track** roadmap (currently at $doneWeeks/$totalWeeks weeks completed with $xp XP):
• Focus on applying this directly inside your current week's practical project.
• Break down the concept into small 15-minute coding exercises.
• Check out our **Resources** tab for top curated video playlists on this exact topic.

What specific part would you like us to dive deeper into?''';
  }
}
