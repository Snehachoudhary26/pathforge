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
    {
      'title': 'Python Full Course',
      'channel': 'CodeWithHarry',
      'flag': '🇮🇳',
      'level': 'Beginner',
      'desc': 'Best beginner Python course in Hindi',
      'icon': Icons.code_rounded,
      'color': const Color(0xFF7C5CBF),
      'bg': const Color(0xFFF5F3FF),
      'url': 'https://www.youtube.com/playlist?list=PLu0W_9lII9agwh1XjRt242xIpHhPT2P46',
    },
    {
      'title': 'Complete Java Course',
      'channel': 'CodeWithHarry',
      'flag': '🇮🇳',
      'level': 'Beginner',
      'desc': 'Complete Java from basics to advanced',
      'icon': Icons.coffee_rounded,
      'color': const Color(0xFFFF5722),
      'bg': const Color(0xFFFFF3EE),
      'url': 'https://www.youtube.com/playlist?list=PLu0W_9lII9agS67Uits0UnJyrYiXhDS6q',
    },
    {
      'title': 'JavaScript Full Playlist',
      'channel': 'Chai aur Code',
      'flag': '🇮🇳',
      'level': 'Beginner',
      'desc': 'Deep dive JavaScript in Hindi',
      'icon': Icons.javascript_rounded,
      'color': const Color(0xFFFFB800),
      'bg': const Color(0xFFFFF8E7),
      'url': 'https://www.youtube.com/playlist?list=PLu71SKxNbfoBuX3f4EOACle2yCtRC5Q37',
    },
    {
      'title': 'Complete C++ Course',
      'channel': 'Love Babbar',
      'flag': '🇮🇳',
      'level': 'Beginner',
      'desc': 'Complete C++ from scratch',
      'icon': Icons.data_object_rounded,
      'color': const Color(0xFF00B894),
      'bg': const Color(0xFFE8F8F0),
      'url': 'https://www.youtube.com/playlist?list=PLDzeHZWIZsTryvtXdMr6rPh4IDexB5NIA',
    },
  ];

  final List<Map<String, dynamic>> dsa = [
    {
      'title': 'DSA Supreme Batch',
      'channel': 'Love Babbar',
      'flag': '🇮🇳',
      'level': 'All Levels',
      'desc': 'Most comprehensive DSA course in Hindi',
      'icon': Icons.account_tree_rounded,
      'color': const Color(0xFFFF5722),
      'bg': const Color(0xFFFFF3EE),
      'url': 'https://www.youtube.com/playlist?list=PLDzeHZWIZsTqeqvHqXnThv_0n_P_V2E3x',
    },
    {
      'title': 'Take U Forward A2Z Sheet',
      'channel': 'Striver',
      'flag': '🇮🇳',
      'level': 'FAANG Prep',
      'desc': 'The gold standard DSA sheet for placements',
      'icon': Icons.military_tech_rounded,
      'color': const Color(0xFF7C5CBF),
      'bg': const Color(0xFFF5F3FF),
      'url': 'https://takeuforward.org/strivers-a2z-dsa-course/strivers-a2z-dsa-course-sheet-2/',
    },
    {
      'title': 'NeetCode 150',
      'channel': 'NeetCode',
      'flag': '🌍',
      'level': 'Interview Prep',
      'desc': 'Best curated 150 LeetCode problems with solutions',
      'icon': Icons.star_rounded,
      'color': const Color(0xFF00B894),
      'bg': const Color(0xFFE8F8F0),
      'url': 'https://neetcode.io/practice',
    },
  ];

  final List<Map<String, dynamic>> dev = [
    {
      'title': 'React.js Complete Course',
      'channel': 'Chai aur Code',
      'flag': '🇮🇳',
      'level': 'Intermediate',
      'desc': 'Complete React with modern hooks and projects',
      'icon': Icons.web_rounded,
      'color': const Color(0xFF1565C0),
      'bg': const Color(0xFFE3F2FD),
      'url': 'https://www.youtube.com/playlist?list=PLu71SKxNbfoDqgPchmvIsL4hTnJIrtige',
    },
    {
      'title': 'Backend Development (Node + Express)',
      'channel': 'Piyush Garg',
      'flag': '🇮🇳',
      'level': 'Intermediate',
      'desc': 'Production ready backend engineering in Hindi',
      'icon': Icons.dns_rounded,
      'color': const Color(0xFF2E7D32),
      'bg': const Color(0xFFE8F5E9),
      'url': 'https://www.youtube.com/playlist?list=PLinedj3B30sDby4Al-i13hQJGQoRQDfPo',
    },
    {
      'title': 'Flutter 3.0 Complete Guide',
      'channel': 'Rivaan Ranawat',
      'flag': '🇮🇳',
      'level': 'All Levels',
      'desc': 'Build cross-platform mobile apps',
      'icon': Icons.phone_android_rounded,
      'color': const Color(0xFF7C5CBF),
      'bg': const Color(0xFFF5F3FF),
      'url': 'https://www.youtube.com/playlist?list=PL-Wtw_i62eZ_1iJzZqUf9LqPzNfH4g4tT',
    },
  ];

  final List<Map<String, dynamic>> tools = [
    {
      'title': 'Git & GitHub Crash Course',
      'channel': 'Kunal Kushwaha',
      'flag': '🇮🇳',
      'level': 'Beginner',
      'desc': 'Version control mastery and open source',
      'icon': Icons.merge_type_rounded,
      'color': const Color(0xFFFF5722),
      'bg': const Color(0xFFFFF3EE),
      'url': 'https://www.youtube.com/watch?v=apGV9Kg7ics',
    },
    {
      'title': 'Docker for Beginners',
      'channel': 'TechWorld with Nana',
      'flag': '🌍',
      'level': 'Intermediate',
      'desc': 'Containerization concepts explained easily',
      'icon': Icons.layers_rounded,
      'color': const Color(0xFF1565C0),
      'bg': const Color(0xFFE3F2FD),
      'url': 'https://www.youtube.com/watch?v=3c-iBn73dDE',
    },
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
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _list {
    switch (_tabController.index) {
      case 0:
        return languages;
      case 1:
        return dsa;
      case 2:
        return dev;
      case 3:
        return tools;
      default:
        return languages;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  // Top Obsidian Header
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
                      20,
                      MediaQuery.of(context).padding.top + 16,
                      20,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Learning Resources',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Top YouTube courses — Indian & Global',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: const Color(0xFFB3B0D6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          labelColor: const Color(0xFFFF5722),
                          unselectedLabelColor: const Color(0xFFB3B0D6),
                          indicatorColor: const Color(0xFFFF5722),
                          indicatorWeight: 3,
                          indicatorSize: TabBarIndicatorSize.label,
                          dividerColor: Colors.transparent,
                          onTap: (_) => setState(() {}),
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
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

                  // Resources List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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

                  // Bottom Navigation Bar (Strictly 4 icons)
                  _BottomNav(
                    currentIndex: 2,
                    onHome: () => context.go('/home'),
                    onRoadmap: () => context.go('/home'),
                    onResources: () => context.go('/resources'),
                    onProfile: () => context.go('/profile'),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E4F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(resource['icon'] as IconData, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource['title'],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '${resource['flag']} ${resource['channel']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: const Color(0xFF6B6890),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          resource['level'],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    resource['desc'],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: const Color(0xFF9B99B5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5722),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5722).withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Watch',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final VoidCallback onHome, onRoadmap, onResources, onProfile;
  const _BottomNav({
    required this.currentIndex,
    required this.onHome,
    required this.onRoadmap,
    required this.onResources,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E4F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home',
              currentIndex == 0, onHome),
          _NavItem(Icons.map_outlined, Icons.map_rounded, 'Roadmap',
              currentIndex == 1, onRoadmap),
          _NavItem(Icons.play_circle_outline, Icons.play_circle, 'Resources',
              currentIndex == 2, onResources),
          _NavItem(Icons.person_outline, Icons.person_rounded, 'Profile',
              currentIndex == 3, onProfile),
        ],
      ),
    );
  }
}

Widget _NavItem(
  IconData icon,
  IconData activeIcon,
  String label,
  bool active,
  VoidCallback onTap,
) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFFF3EE) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? activeIcon : icon,
              color: active ? const Color(0xFFFF5722) : const Color(0xFF9B99B5),
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color:
                    active ? const Color(0xFFFF5722) : const Color(0xFF9B99B5),
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
