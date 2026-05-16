import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});
  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> programmingLanguages = [
    {'title': 'Python Full Course', 'channel': 'CodeWithHarry', 'flag': '🇮🇳', 'level': 'Beginner', 'emoji': '🐍', 'color': Color(0xFF8B53EC), 'url': 'https://youtu.be/UrsmFxEIp5k', 'desc': 'Best beginner-friendly Python course in Hindi'},
    {'title': 'Complete Java Course', 'channel': 'CodeWithHarry', 'flag': '🇮🇳', 'level': 'Beginner', 'emoji': '☕', 'color': Color(0xFF6B35CC), 'url': 'https://youtu.be/UmnCZ7-9yDY', 'desc': 'Complete Java from basics to advanced'},
    {'title': 'JavaScript Full Playlist', 'channel': 'CodeWithHarry', 'flag': '🇮🇳', 'level': 'Beginner', 'emoji': '🌐', 'color': Color(0xFFAA75F0), 'url': 'https://youtube.com/playlist?list=PLGjplNEQ1it_oTvuLRNqXfz_v_0pq6unW', 'desc': 'Full JavaScript playlist for web development'},
    {'title': 'Complete C++ Course', 'channel': 'CodeWithHarry', 'flag': '🇮🇳', 'level': 'Beginner', 'emoji': '⚡', 'color': Color(0xFF8B53EC), 'url': 'https://youtube.com/playlist?list=PLfqMhTWNBTe0b2nM6JHVCnAkhQRGiZMSJ', 'desc': 'Complete C++ from scratch'},
  ];

  final List<Map<String, dynamic>> dsa = [
    {'title': 'Striver DSA Sheet', 'channel': 'take U forward', 'flag': '🇮🇳', 'level': 'Interview', 'emoji': '🎯', 'color': Color(0xFF8B53EC), 'url': 'https://youtube.com/playlist?list=PLgUwDviBIf0oF6QL8m22w1hIDC1vJ_BHz', 'desc': 'Best DSA sheet for coding interviews in C++'},
    {'title': 'Kunal Kushwaha DSA', 'channel': 'Kunal Kushwaha', 'flag': '🇮🇳', 'level': 'Complete', 'emoji': '🏆', 'color': Color(0xFF6B35CC), 'url': 'https://youtube.com/playlist?list=PL9gnSGHSqcnr_DxHsP7AW9ftq0AtAyYqJ', 'desc': 'Complete DSA course in Java for placements'},
    {'title': 'Apna College DSA', 'channel': 'Apna College', 'flag': '🇮🇳', 'level': 'Beginner', 'emoji': '📚', 'color': Color(0xFFAA75F0), 'url': 'https://youtube.com/@ApnaCollegeOfficial', 'desc': 'DSA in Java — great for beginners'},
  ];

  final List<Map<String, dynamic>> development = [
    {'title': 'Full Data Science Course', 'channel': 'CampusX', 'flag': '🇮🇳', 'level': 'Complete', 'emoji': '📊', 'color': Color(0xFF8B53EC), 'url': 'https://youtu.be/gDZ6czwuQ18', 'desc': '100 Days of ML — best structured DS course'},
    {'title': 'Machine Learning Course', 'channel': 'Krish Naik', 'flag': '🇮🇳', 'level': 'Intermediate', 'emoji': '🤖', 'color': Color(0xFF6B35CC), 'url': 'https://youtu.be/ie4oGI85SAE', 'desc': 'End-to-end ML course with projects'},
    {'title': 'AI Engineering PyTorch', 'channel': 'Andrej Karpathy', 'flag': '🌍', 'level': 'Advanced', 'emoji': '🧠', 'color': Color(0xFFAA75F0), 'url': 'https://youtu.be/UqA7bxp7VBk', 'desc': 'Build GPT from scratch — gold standard AI'},
    {'title': 'Full Stack Web Dev', 'channel': 'CodeWithHarry', 'flag': '🇮🇳', 'level': 'Complete', 'emoji': '💻', 'color': Color(0xFF8B53EC), 'url': 'https://youtube.com/playlist?list=PLu0W_9lII9agq5TrH9XLIKQvv0iaF2X3w', 'desc': 'Complete web development roadmap'},
    {'title': 'Flutter + Firebase', 'channel': 'CodeWithHarry', 'flag': '🇮🇳', 'level': 'Intermediate', 'emoji': '📱', 'color': Color(0xFF6B35CC), 'url': 'https://youtu.be/iZ78G3BhDyc', 'desc': 'Build Android apps with Flutter & Firebase'},
    {'title': 'Math for ML', 'channel': '3Blue1Brown', 'flag': '🌍', 'level': 'Foundation', 'emoji': '🔢', 'color': Color(0xFFAA75F0), 'url': 'https://www.youtube.com/@3blue1brown', 'desc': 'Linear algebra & calculus visually explained'},
  ];

  final List<Map<String, dynamic>> tools = [
    {'title': 'React.js Full Course', 'channel': 'CodeWithHarry', 'flag': '🇮🇳', 'level': 'Intermediate', 'emoji': '⚛️', 'color': Color(0xFF8B53EC), 'url': 'https://youtu.be/RGKi6LSPDLU', 'desc': 'Complete React from scratch'},
    {'title': 'MongoDB Course', 'channel': 'CodeWithHarry', 'flag': '🇮🇳', 'level': 'Beginner', 'emoji': '🍃', 'color': Color(0xFF6B35CC), 'url': 'https://youtu.be/M1dKYQ7GsTg', 'desc': 'MongoDB database full course'},
    {'title': 'MySQL Course', 'channel': 'CodeWithHarry', 'flag': '🇮🇳', 'level': 'Beginner', 'emoji': '🗄️', 'color': Color(0xFFAA75F0), 'url': 'https://youtu.be/yE6tIle64tU', 'desc': 'MySQL from basics to advanced'},
    {'title': 'Docker Course', 'channel': 'Various', 'flag': '🌍', 'level': 'Intermediate', 'emoji': '🐳', 'color': Color(0xFF8B53EC), 'url': 'https://youtu.be/WNUCAPKa44Y', 'desc': 'Docker containers and deployment'},
    {'title': 'Django Course', 'channel': 'CodeWithHarry', 'flag': '🇮🇳', 'level': 'Intermediate', 'emoji': '🎸', 'color': Color(0xFF6B35CC), 'url': 'https://youtu.be/rIWJWy3_njo', 'desc': 'Django web framework full course'},
    {'title': 'LLM Course', 'channel': 'Various', 'flag': '🌍', 'level': 'Advanced', 'emoji': '🤖', 'color': Color(0xFFAA75F0), 'url': 'https://youtu.be/K45s2PgywvI', 'desc': 'Large Language Models from scratch'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _currentList {
    switch (_tabController.index) {
      case 0: return programmingLanguages;
      case 1: return dsa;
      case 2: return development;
      case 3: return tools;
      default: return programmingLanguages;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Learning Resources',
                    style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text('Top YouTube courses — Indian & Global',
                    style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textMid),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textLight,
              indicatorColor: AppTheme.primary,
              indicatorWeight: 2.5,
              onTap: (_) => setState(() {}),
              labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
              tabs: const [
                Tab(text: '🧠 Languages'),
                Tab(text: '⚡ DSA'),
                Tab(text: '🚀 Dev'),
                Tab(text: '🛠️ Tools'),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                itemCount: _currentList.length,
                itemBuilder: (context, i) {
                  final r = _currentList[i];
                  return _ResourceCard(resource: r, onTap: () => _launch(r['url']));
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(Icons.map_outlined, 'Roadmap', false, () => Navigator.of(context).pop()),
                  _NavItem(Icons.play_circle_outline, 'Resources', true, () {}),
                  _NavItem(Icons.person_outline, 'Profile', false, () => Navigator.of(context).pop()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final Map<String, dynamic> resource;
  final VoidCallback onTap;
  const _ResourceCard({required this.resource, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: (resource['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(resource['emoji'], style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(resource['title'],
                    style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text('${resource['flag']} ${resource['channel']}',
                        style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textMid),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: (resource['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(resource['level'],
                          style: GoogleFonts.poppins(
                            fontSize: 9, fontWeight: FontWeight.w500,
                            color: resource['color'],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(resource['desc'],
                    style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textLight),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: resource['color'],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Watch',
                  style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: Colors.white,
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem(this.icon, this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? AppTheme.primary : AppTheme.textLight, size: 22),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.poppins(
            fontSize: 10,
            color: active ? AppTheme.primary : AppTheme.textLight,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          )),
        ],
      ),
    );
  }
}
