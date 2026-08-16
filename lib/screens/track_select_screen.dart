import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';

class TrackSelectScreen extends StatefulWidget {
  const TrackSelectScreen({super.key});
  @override
  State<TrackSelectScreen> createState() => _TrackSelectScreenState();
}

class _TrackSelectScreenState extends State<TrackSelectScreen> {
  int _selectedCategory = 0;
  String _searchQuery = '';

  final List<Map<String, dynamic>> categories = [
    {'label': 'Data & AI', 'icon': Icons.bar_chart_rounded, 'color': AppTheme.primary},
    {'label': 'Development', 'icon': Icons.code_rounded, 'color': AppTheme.green},
    {'label': 'DevOps', 'icon': Icons.cloud_rounded, 'color': const Color(0xFF1565C0)},
    {'label': 'Security', 'icon': Icons.security_rounded, 'color': const Color(0xFFC62828)},
    {'label': 'Design', 'icon': Icons.brush_rounded, 'color': const Color(0xFF6A1B9A)},
    {'label': 'Emerging', 'icon': Icons.rocket_launch_rounded, 'color': AppTheme.orange},
  ];

  final Map<int, List<Map<String, dynamic>>> tracks = {
    0: [
      {
        'title': 'Data Scientist',
        'icon': Icons.bar_chart_rounded,
        'desc': 'Analyse data, build ML models and extract business insights',
        'skills': ['Python', 'Statistics', 'ML', 'SQL'],
        'duration': '16 weeks',
        'salary': '₹8–18 LPA',
        'demand': 'High',
        'demandColor': AppTheme.green,
        'tag': 'Most Popular',
        'tagColor': AppTheme.orange,
        'color': AppTheme.primary,
        'bg': AppTheme.purpleLight,
      },
      {
        'title': 'Data Analyst',
        'icon': Icons.analytics_rounded,
        'desc': 'Analyse business data and create reports and dashboards',
        'skills': ['Excel', 'SQL', 'Power BI', 'Tableau'],
        'duration': '12 weeks',
        'salary': '₹5–12 LPA',
        'demand': 'Steady',
        'demandColor': AppTheme.primary,
        'tag': 'Best for Beginners',
        'tagColor': AppTheme.green,
        'color': AppTheme.primary,
        'bg': AppTheme.purpleLight,
      },
      {
        'title': 'Data Engineer',
        'icon': Icons.storage_rounded,
        'desc': 'Build data pipelines, warehouses and large-scale data systems',
        'skills': ['SQL', 'Spark', 'Kafka', 'Airflow'],
        'duration': '20 weeks',
        'salary': '₹10–22 LPA',
        'demand': 'Growing',
        'demandColor': AppTheme.orange,
        'tag': 'Fast Growing',
        'tagColor': AppTheme.orange,
        'color': AppTheme.primary,
        'bg': AppTheme.purpleLight,
      },
      {
        'title': 'ML Engineer',
        'icon': Icons.psychology_rounded,
        'desc': 'Build and deploy machine learning models into production',
        'skills': ['Python', 'TensorFlow', 'PyTorch', 'Docker'],
        'duration': '24 weeks',
        'salary': '₹12–30 LPA',
        'demand': 'Very High',
        'demandColor': AppTheme.green,
        'tag': 'Highest Paying',
        'tagColor': AppTheme.amber,
        'color': AppTheme.primary,
        'bg': AppTheme.purpleLight,
      },
      {
        'title': 'AI Engineer',
        'icon': Icons.auto_awesome_rounded,
        'desc': 'Build AI systems like chatbots, recommendation engines and AI apps',
        'skills': ['Python', 'OpenAI APIs', 'LangChain', 'LLMs'],
        'duration': '24 weeks',
        'salary': '₹15–35 LPA',
        'demand': 'Explosive',
        'demandColor': AppTheme.green,
        'tag': 'Future of Tech',
        'tagColor': AppTheme.primary,
        'color': AppTheme.primary,
        'bg': AppTheme.purpleLight,
      },
      {
        'title': 'NLP Engineer',
        'icon': Icons.chat_rounded,
        'desc': 'Build human language AI systems and text processing pipelines',
        'skills': ['Python', 'Transformers', 'Hugging Face', 'BERT'],
        'duration': '20 weeks',
        'salary': '₹12–28 LPA',
        'demand': 'High',
        'demandColor': AppTheme.green,
        'tag': 'Specialised',
        'tagColor': AppTheme.primary,
        'color': AppTheme.primary,
        'bg': AppTheme.purpleLight,
      },
      {
        'title': 'Computer Vision Engineer',
        'icon': Icons.remove_red_eye_rounded,
        'desc': 'Build image and video AI systems for detection and recognition',
        'skills': ['Python', 'OpenCV', 'PyTorch', 'TensorFlow'],
        'duration': '20 weeks',
        'salary': '₹12–28 LPA',
        'demand': 'High',
        'demandColor': AppTheme.green,
        'tag': 'Specialised',
        'tagColor': AppTheme.primary,
        'color': AppTheme.primary,
        'bg': AppTheme.purpleLight,
      },
      {
        'title': 'Prompt Engineer',
        'icon': Icons.edit_note_rounded,
        'desc': 'Design prompts and workflows for AI systems and LLMs',
        'skills': ['ChatGPT APIs', 'LangChain', 'RAG', 'Workflows'],
        'duration': '8 weeks',
        'salary': '₹8–20 LPA',
        'demand': 'New & Growing',
        'demandColor': AppTheme.orange,
        'tag': 'Newest Role',
        'tagColor': AppTheme.orange,
        'color': AppTheme.primary,
        'bg': AppTheme.purpleLight,
      },
    ],
    1: [
      {
        'title': 'Frontend Developer',
        'icon': Icons.web_rounded,
        'desc': 'Build beautiful user interfaces for websites and web apps',
        'skills': ['HTML', 'CSS', 'JavaScript', 'React'],
        'duration': '16 weeks',
        'salary': '₹6–15 LPA',
        'demand': 'High',
        'demandColor': AppTheme.green,
        'tag': 'Always in Demand',
        'tagColor': AppTheme.green,
        'color': AppTheme.green,
        'bg': AppTheme.greenLight,
      },
      {
        'title': 'Backend Developer',
        'icon': Icons.dns_rounded,
        'desc': 'Build servers, APIs, databases and business logic',
        'skills': ['Node.js', 'Express', 'Django', 'PostgreSQL'],
        'duration': '18 weeks',
        'salary': '₹8–18 LPA',
        'demand': 'High',
        'demandColor': AppTheme.green,
        'tag': 'Core Role',
        'tagColor': AppTheme.green,
        'color': AppTheme.green,
        'bg': AppTheme.greenLight,
      },
      {
        'title': 'Full Stack Developer',
        'icon': Icons.layers_rounded,
        'desc': 'Handle both frontend and backend development end to end',
        'skills': ['React', 'Node.js', 'MongoDB', 'PostgreSQL'],
        'duration': '24 weeks',
        'salary': '₹8–20 LPA',
        'demand': 'Very High',
        'demandColor': AppTheme.green,
        'tag': 'Most Versatile',
        'tagColor': AppTheme.green,
        'color': AppTheme.green,
        'bg': AppTheme.greenLight,
      },
      {
        'title': 'Mobile App Developer',
        'icon': Icons.phone_android_rounded,
        'desc': 'Build Android and iOS apps using Flutter or React Native',
        'skills': ['Flutter', 'Dart', 'React Native', 'Firebase'],
        'duration': '20 weeks',
        'salary': '₹7–18 LPA',
        'demand': 'High',
        'demandColor': AppTheme.green,
        'tag': 'Great for India',
        'tagColor': AppTheme.green,
        'color': AppTheme.green,
        'bg': AppTheme.greenLight,
      },
      {
        'title': 'Software Engineer',
        'icon': Icons.terminal_rounded,
        'desc': 'Build software applications, systems and platforms',
        'skills': ['Python', 'Java', 'DSA', 'OOP'],
        'duration': '24 weeks',
        'salary': '₹8–25 LPA',
        'demand': 'Very High',
        'demandColor': AppTheme.green,
        'tag': 'Foundation Role',
        'tagColor': AppTheme.green,
        'color': AppTheme.green,
        'bg': AppTheme.greenLight,
      },
      {
        'title': 'Game Developer',
        'icon': Icons.sports_esports_rounded,
        'desc': 'Create games for PC, mobile and consoles using Unity or Unreal',
        'skills': ['Unity', 'C#', 'Unreal', 'C++'],
        'duration': '24 weeks',
        'salary': '₹6–15 LPA',
        'demand': 'Growing',
        'demandColor': AppTheme.orange,
        'tag': 'Creative Tech',
        'tagColor': AppTheme.orange,
        'color': AppTheme.green,
        'bg': AppTheme.greenLight,
      },
    ],
    2: [
      {
        'title': 'DevOps Engineer',
        'icon': Icons.loop_rounded,
        'desc': 'Automate deployment, CI/CD pipelines and infrastructure',
        'skills': ['Docker', 'Kubernetes', 'Jenkins', 'AWS'],
        'duration': '20 weeks',
        'salary': '₹10–25 LPA',
        'demand': 'Very High',
        'demandColor': AppTheme.green,
        'tag': 'Always Needed',
        'tagColor': AppTheme.green,
        'color': const Color(0xFF1565C0),
        'bg': const Color(0xFFE3F2FD),
      },
      {
        'title': 'Cloud Engineer',
        'icon': Icons.cloud_done_rounded,
        'desc': 'Manage cloud infrastructure and services on AWS, Azure or GCP',
        'skills': ['AWS', 'Azure', 'GCP', 'Docker'],
        'duration': '20 weeks',
        'salary': '₹12–28 LPA',
        'demand': 'Explosive',
        'demandColor': AppTheme.green,
        'tag': 'Future Proof',
        'tagColor': const Color(0xFF1565C0),
        'color': const Color(0xFF1565C0),
        'bg': const Color(0xFFE3F2FD),
      },
      {
        'title': 'Site Reliability Engineer',
        'icon': Icons.monitor_heart_rounded,
        'desc': 'Maintain system reliability, scalability and performance',
        'skills': ['Kubernetes', 'Monitoring', 'Linux', 'Cloud'],
        'duration': '20 weeks',
        'salary': '₹15–35 LPA',
        'demand': 'High',
        'demandColor': AppTheme.green,
        'tag': 'Senior Role',
        'tagColor': const Color(0xFF1565C0),
        'color': const Color(0xFF1565C0),
        'bg': const Color(0xFFE3F2FD),
      },
    ],
    3: [
      {
        'title': 'Cybersecurity Engineer',
        'icon': Icons.security_rounded,
        'desc': 'Protect systems from hacking, attacks and vulnerabilities',
        'skills': ['Kali Linux', 'Wireshark', 'Burp Suite', 'Networks'],
        'duration': '20 weeks',
        'salary': '₹10–25 LPA',
        'demand': 'Very High',
        'demandColor': AppTheme.green,
        'tag': 'Critical Role',
        'tagColor': const Color(0xFFC62828),
        'color': const Color(0xFFC62828),
        'bg': const Color(0xFFFCE4EC),
      },
      {
        'title': 'QA Test Engineer',
        'icon': Icons.bug_report_rounded,
        'desc': 'Test software, find bugs and ensure product quality',
        'skills': ['Selenium', 'JUnit', 'Cypress', 'Postman'],
        'duration': '14 weeks',
        'salary': '₹5–12 LPA',
        'demand': 'Steady',
        'demandColor': AppTheme.primary,
        'tag': 'Entry Friendly',
        'tagColor': AppTheme.green,
        'color': const Color(0xFFC62828),
        'bg': const Color(0xFFFCE4EC),
      },
    ],
    4: [
      {
        'title': 'UI/UX Designer',
        'icon': Icons.design_services_rounded,
        'desc': 'Design user-friendly interfaces and great user experiences',
        'skills': ['Figma', 'Adobe XD', 'Wireframing', 'Prototyping'],
        'duration': '12 weeks',
        'salary': '₹6–15 LPA',
        'demand': 'High',
        'demandColor': AppTheme.green,
        'tag': 'Creative Role',
        'tagColor': const Color(0xFF6A1B9A),
        'color': const Color(0xFF6A1B9A),
        'bg': const Color(0xFFF3E5F5),
      },
    ],
    5: [
      {
        'title': 'AR/VR Engineer',
        'icon': Icons.view_in_ar_rounded,
        'desc': 'Build Augmented Reality and Virtual Reality applications',
        'skills': ['Unity', 'Unreal', 'ARKit', 'ARCore'],
        'duration': '24 weeks',
        'salary': '₹10–25 LPA',
        'demand': 'Growing',
        'demandColor': AppTheme.orange,
        'tag': 'Future Tech',
        'tagColor': AppTheme.orange,
        'color': AppTheme.orange,
        'bg': AppTheme.orangeLight,
      },
      {
        'title': 'Robotics Engineer',
        'icon': Icons.precision_manufacturing_rounded,
        'desc': 'Build robots and automation systems using ROS and sensors',
        'skills': ['ROS', 'Python', 'C++', 'Sensors'],
        'duration': '24 weeks',
        'salary': '₹8–20 LPA',
        'demand': 'Growing',
        'demandColor': AppTheme.orange,
        'tag': 'Niche Tech',
        'tagColor': AppTheme.orange,
        'color': AppTheme.orange,
        'bg': AppTheme.orangeLight,
      },
    ],
  };

  List<Map<String, dynamic>> get _filteredTracks {
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      final allTracks = tracks.values.expand((element) => element).toList();
      return allTracks.where((t) =>
          t['title'].toString().toLowerCase().contains(query) ||
          t['desc'].toString().toLowerCase().contains(query) ||
          (t['skills'] as List).any((s) =>
              s.toString().toLowerCase().contains(query))
      ).toList();
    }
    return tracks[_selectedCategory] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top Navy Header
            Container(
              color: const Color(0xFF111322),
              padding: EdgeInsets.fromLTRB(
                14,
                topPadding > 0 ? topPadding + 6 : 18,
                14,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                              'Choose your track',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'AI builds your personalised roadmap',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Search bar
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search tracks or skills (e.g. Cloud, AI)...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Colors.white38,
                          size: 16,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Category tabs (Horizontal scrollable)
            Container(
              color: const Color(0xFF111322),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Row(
                  children: categories.asMap().entries.map((e) {
                    final i = e.key;
                    final cat = e.value;
                    final isSelected = _selectedCategory == i && _searchQuery.isEmpty;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedCategory = i;
                        _searchQuery = '';
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cat['color'] as Color
                              : Colors.white10,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? (cat['color'] as Color)
                                : Colors.white12,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat['icon'] as IconData,
                              size: 12,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              cat['label'],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Track list
            Expanded(
              child: _filteredTracks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 40, color: AppTheme.textLight),
                          const SizedBox(height: 8),
                          Text(
                            'No tracks found for "$_searchQuery"',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textMid,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                      itemCount: _filteredTracks.length,
                      itemBuilder: (context, i) => _TrackCard(
                        track: _filteredTracks[i],
                        onTap: () => context.go(
                          '/generating?track=${Uri.encodeComponent(_filteredTracks[i]['title'])}',
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 100% Overflow-Free Track Card ─────────────────────────────────
class _TrackCard extends StatelessWidget {
  final Map<String, dynamic> track;
  final VoidCallback onTap;
  const _TrackCard({required this.track, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = track['color'] as Color;
    final bg = track['bg'] as Color;
    final tagColor = track['tagColor'] as Color;
    final demandColor = track['demandColor'] as Color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAEAF2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          track['icon'] as IconData,
                          color: color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track['title'],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Icon(Icons.access_time_rounded,
                                    size: 11, color: AppTheme.textLight),
                                const SizedBox(width: 3),
                                Text(
                                  track['duration'],
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: AppTheme.textMid,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: tagColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: tagColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          track['tag'],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: tagColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    track['desc'],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.textMid,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Skills
                  Wrap(
                    spacing: 4,
                    runSpacing: 3,
                    children: (track['skills'] as List<String>)
                        .take(4)
                        .map((s) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                s,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),

            // Card Footer (100% Overflow-Free Guaranteed on All Screen Sizes)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 7),
              decoration: const BoxDecoration(
                color: Color(0xFFF9F9FC),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(color: Color(0xFFEAEAF2)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          track['salary'],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: demandColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '${track['demand']} demand',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              color: demandColor,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111322),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Start',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 11,
                        ),
                      ],
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
