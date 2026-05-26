import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
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

  final List<Map<String, dynamic>> languages = [
    {'title': 'Python Full Course', 'channel': 'CodeWithHarry', 'flag': '🇮🇳', 'level': 'Beginner', 'icon': Icons.code_rounded, 'color': AppTheme.primary, 'bg': AppTheme.purpleLight, 'url': 'https://youtu.be/UrsmFxEIp5k', 'desc': 'Best beginner Python course in Hindi'},
    {'title': 'Complete Java Course', 'channel': 'CodeWithHarry', 'flag': '🇮🇳', 'level': 'Beginner', 'icon': Icons.coffee_rounded, 'color': AppTheme.orange, 'bg': AppTheme.orangeLight, 'url': 'https://youtu.be/UmnCZ7-9yDY', 'desc': 'Complete Java from basics to advanced'},
    {'title': 'JavaScript Full Playlist', 'channel': 'CodeWithHarry', 'flag': '🇮🇳', 'level': 'Beginner', 'icon': Icons.javascript_rounded, 'color': AppTheme.amber, 'bg': AppTheme.amberLight, 'url': 'https://youtube.com/playlist?list=PLGjplNEQ1it_oTvuLRNqXfz_v_0pq6unW', 'desc': 'Full JavaScript playlist for web dev'},
    {'title': 'Complete C++ Course', 'channel': 'CodeWithHarry', 'flag': '🇮🇳', 'level': 'Beginner', 'icon': Icons.memory_rounded, 'color': AppTheme.green, 'bg': AppTheme.greenLight, 'url': 'https://youtube.com/playlist?list=PLfqMhTWNBTe0b2nM6JHVCnAkhQRGiZMSJ', 'desc': 'Complete C++ from scratch'},
  ];

  final List<Map<String, dynamic>> dsa = [
    {'title': 'Striver DSA Sheet', 'channel': 'take U forward', 'flag': '🇮🇳', 'level': 'Interview', 'icon': Icons.account_tree_rounded, 'color': AppTheme.primary, 'bg': AppTheme.purpleLight, 'url': 'https://youtube.com/playlist?list=PLgUwDviBIf0oF6QL8m22w1hIDC1vJ_BHz', 'desc': 'Best DSA sheet for coding interviews'},
    {'title': 'Kunal Kushwaha DSA', 'channel': 'Kunal Kushwaha', 'flag': '🇮🇳', 'level': 'Complete', 'icon': Icons.school_rounded, 'color': AppTheme.orange, 'bg': AppTheme.orangeLight, 'url': 'https://youtube.com/playlist?list=PL9gnSGHSqcnr_DxHsP7AW9ftq0AtAyYqJ', 'desc': 'Complete DSA course in Java'},
    {'title': 'Apna College DSA', 'channel': 'Apna College', 'flag': '🇮🇳', 'level': 'Beginner', 'icon': Icons.book_rounded, 'color': AppTheme.green, 'bg': AppTheme.greenLight, 'url': 'https://youtube.com/@ApnaCollegeOfficial', 'desc': 'DSA in Java — great for beginners'},
  ];

  final List<Map<String, dynamic>> dev = [
    {'title': 'Full Data Science Course', 'channel': 'CampusX', 'flag': '🇮🇳', 'level': 'Complete', 'icon': Icons.bar_chart_rounded, 'color': AppTheme.primary, 'bg': AppTheme.purpleLight, 'url': 'https://youtu.be/gDZ6czwuQ18', 'desc': '100 Days of ML — best structured DS course'},
    {'title': 'Machine Learning Course', 'channel': 'Krish Naik', 'flag': '🇮🇳', 'level': 'Intermediate', 'icon': Icons.psychology_rounded, 'color': AppTheme.orange, 'bg': AppTheme.orangeLight, 'url': 'https://youtu.be/ie4oGI85SAE', 'desc': 'End-to-end ML course with projects'},
    {'title': 'AI Engineering PyTorch', 'channel': 'Andrej Karpathy', 'flag': '🌍', 'level': 'Advanced', 'icon': Icons.auto_awesome_rounded, 'color': AppTheme.green, 'bg': AppTheme.greenLight, 'url': 'https://youtu.be/UqA7bxp7VBk', 'desc': 'Build GPT from scratch'},
    {'title': 'Full Stack Web Dev', 'channel': 'CodeWithHarry', 'flag': '🇮🇳', 'level': 'Complete', 'icon': Icons.web_rounded, 'color': AppTheme.primary, 'bg': AppTheme.purpleLight, 'url': 'https://youtube.com/playlist?list=PLu0W_9lII9agq5TrH9XLIKQvv0iaF2X3w', 'desc': 'Complete web development roadmap'},
    {'title': 'Flutter + Firebase', 'channel': 'CodeWithHarry', 'flag': '🇮🇳', 'level': 'Intermediate', 'icon': Icons.phone_android_rounded, 'color': AppTheme.amber, 'bg': AppTheme.amberLight, 'url': 'https://youtu.be/iZ78G3BhDyc', 'desc': 'Build Android apps with Flutter'},
    {'title': 'Math for ML', 'channel': '3Blue1Brown', 'flag': '🌍', 'level': 'Foundation', 'icon': Icons.calculate_rounded, 'color': AppTheme.orange, 'bg': AppTheme.orangeLight, 'url': 'https://www.youtube.com/@3blue1brown', 'desc': 'Linear algebra & calculus visually'},
  ];

  final List<Map<String, dynamic>> tools = [
    {'title': 'React.js Full Course', 'channel': 'CodeWithHarry', 'flag': '🇮🇳', 'level': 'Intermediate', 'icon': Icons.hub_rounded, 'color': AppTheme.primary, 'bg': AppTheme.purpleLight, 'url': 'https://youtu.be/RGKi6LSPDLU', 'desc': 'Complete React from scratch'},
    {'title': 'MongoDB Course', 'channel': 'CodeWithHarry', 'flag': '🇮🇳', 'level': 'Beginner', 'icon': Icons.storage_rounded, 'color': AppTheme.green, 'bg': AppTheme.greenLight, 'url': 'https://youtu.be/M1dKYQ7GsTg', 'desc': 'MongoDB database full course'},
    {'title': 'MySQL Course', 'channel': 'CodeWithHarry', 'flag': '🇮🇳', 'level': 'Beginner', 'icon': Icons.table_chart_rounded, 'color': AppTheme.amber, 'bg': AppTheme.amberLight, 'url': 'https://youtu.be/yE6tIle64tU', 'desc': 'MySQL from basics to advanced'},
    {'title': 'Docker Course', 'channel': 'Various', 'flag': '🌍', 'level': 'Intermediate', 'icon': Icons.view_in_ar_rounded, 'color': AppTheme.primary, 'bg': AppTheme.purpleLight, 'url': 'https://youtu.be/WNUCAPKa44Y', 'desc': 'Docker containers and deployment'},
    {'title': 'LLM Course', 'channel': 'Various', 'flag': '🌍', 'level': 'Advanced', 'icon': Icons.smart_toy_rounded, 'color': AppTheme.orange, 'bg': AppTheme.orangeLight, 'url': 'https://youtu.be/K45s2PgywvI', 'desc': 'Large Language Models from scratch'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link')));
    }
  }

  List<Map<String, dynamic>> get _list {
    switch (_tabController.index) {
      case 0: return languages;
      case 1: return dsa;
      case 2: return dev;
      case 3: return tools;
      default: return languages;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: AppTheme.navy,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Learning Resources',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 20, fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Top YouTube courses — Indian & Global',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: Colors.white54)),
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: AppTheme.orange,
                    unselectedLabelColor: Colors.white54,
                    indicatorColor: AppTheme.orange,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    onTap: (_) => setState(() {}),
                    labelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    tabs: const [
                      Tab(text: 'Languages'),
                      Tab(text: 'DSA'),
                      Tab(text: 'Dev & AI'),
                      Tab(text: 'Tools'),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                itemCount: _list.length,
                itemBuilder: (context, i) {
                  final r = _list[i];
                  return _ResourceCard(
                    resource: r,
                    onTap: () => _launch(r['url']),
                  );
                },
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppTheme.border))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(Icons.home_outlined, Icons.home_rounded,
                      'Home', false, () => context.go('/home')),
                  _NavItem(Icons.map_outlined, Icons.map_rounded,
                      'Roadmap', false, () => context.go('/home')),
                  _NavItem(Icons.play_circle_outline, Icons.play_circle,
                      'Resources', true, () {}),
                  _NavItem(Icons.person_outline, Icons.person_rounded,
                      'Profile', false, () => context.go('/profile')),
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
    final color = resource['color'] as Color;
    final bg = resource['bg'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(13)),
              child: Icon(resource['icon'] as IconData, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(resource['title'],
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: AppTheme.textDark),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text('${resource['flag']} ${resource['channel']}',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11, color: AppTheme.textMid)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(resource['level'],
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 9, fontWeight: FontWeight.w700,
                                color: color)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(resource['desc'],
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, color: AppTheme.textLight),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.navy,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Watch',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppTheme.orangeLight : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(active ? activeIcon : icon,
            color: active ? AppTheme.orange : AppTheme.textLight, size: 24),
        const SizedBox(height: 3),
        Text(label, style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: active ? AppTheme.orange : AppTheme.textLight,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
      ]),
    ),
  );
}
