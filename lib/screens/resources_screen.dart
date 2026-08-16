import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
      'channelInitial': 'C',
      'channelColor': const Color(0xFF3776AB),
      'level': 'Beginner',
      'image': 'assets/Resources/Languages/Python.png',
      'url': 'https://youtu.be/UrsmFxEIp5k?si=4eQoajookdA2CTJC',
      'desc': 'Best beginner Python course in Hindi with projects',
    },
    {
      'title': 'Complete Java Course',
      'channel': 'CodeWithHarry',
      'channelInitial': 'C',
      'channelColor': const Color(0xFFE76F00),
      'level': 'Beginner',
      'image': 'assets/Resources/Languages/java.png',
      'url': 'https://youtu.be/UmnCZ7-9yDY',
      'desc': 'Complete Java from basics to advanced OOP',
    },
    {
      'title': 'JavaScript Full Playlist',
      'channel': 'Chai aur Code',
      'channelInitial': 'C',
      'channelColor': const Color(0xFFE08D00),
      'level': 'Beginner',
      'image': 'assets/Resources/Languages/Javascript.png',
      'url': 'https://youtube.com/playlist?list=PLu71SKxNbfoBuX3f4EOACle2y-tRC5Q37&si=cLgg8-eMdbhlIeJ3',
      'desc': 'Full JavaScript playlist with DOM & Async JS',
    },
    {
      'title': 'Complete C++ Course',
      'channel': 'Apna College',
      'channelInitial': 'A',
      'channelColor': const Color(0xFF00599C),
      'level': 'Beginner',
      'image': 'assets/Resources/Languages/c++.png',
      'url': 'https://youtube.com/playlist?list=PLfqMhTWNBTe0b2nM6JHVCnAkhQRGiZMSJ&si=Y9mCSjU4C99IKJxp',
      'desc': 'Complete C++ programming course for beginners',
    },
  ];

  final List<Map<String, dynamic>> dsa = [
    {
      'title': 'Complete C++ DSA Course',
      'channel': 'Love Babbar',
      'channelInitial': 'L',
      'channelColor': const Color(0xFFFF5722),
      'level': 'Intermediate',
      'image': 'assets/Resources/DSA/loveBabbar.png',
      'url': 'https://youtube.com/playlist?list=PLDzeHZWIZsTryvtXdMr6rPh4IDexB5NIA&si=JgQVPrVCNH5yNS2O',
      'desc': 'Supreme DSA series covering Arrays, Trees & DP',
    },
    {
      'title': 'Strivers A2Z DSA Course',
      'channel': 'take U forward',
      'channelInitial': 'T',
      'channelColor': const Color(0xFF7C5CBF),
      'level': 'Interview',
      'image': 'assets/Resources/DSA/StriversA2Z-DSA.png',
      'url': 'https://youtube.com/playlist?list=PLgUwDviBIf0oF6QL8m22w1hIDC1vJ_BHz&si=dSCKufLJ0xuwBT7z',
      'desc': 'A to Z complete DSA preparation for MAANG',
    },
    {
      'title': 'NeetCode 150 DSA',
      'channel': 'NeetCode',
      'channelInitial': 'N',
      'channelColor': const Color(0xFF00B894),
      'level': 'Advanced',
      'image': 'assets/Resources/DSA/neetCode150.png',
      'url': 'https://youtube.com/playlist?list=PLot-Xpze53ldVwtstag2TL4HQhAnC8ATf',
      'desc': 'Blind 75 & NeetCode 150 LeetCode video solutions',
    },
  ];

  final List<Map<String, dynamic>> dev = [
    {
      'title': 'React JS Complete Course',
      'channel': 'Chai aur Code',
      'channelInitial': 'C',
      'channelColor': const Color(0xFF61DAFB),
      'level': 'Intermediate',
      'image': 'assets/Resources/DEV & AI/React-JS-complete-course.png',
      'url': 'https://youtube.com/playlist?list=PLu71SKxNbfoDqgPchmvIsL4hTnJIrtige&si=jbMEtRLKDdNATui-',
      'desc': 'Complete React with modern hooks and projects',
    },
    {
      'title': 'Backend Development (Node + Express)',
      'channel': 'Piyush Garg',
      'channelInitial': 'P',
      'channelColor': const Color(0xFF68A063),
      'level': 'Intermediate',
      'image': 'assets/Resources/DEV & AI/Backend-development.png',
      'url': 'https://youtube.com/playlist?list=PLinedj3B30sDby4Al-i13hQJGQoRQDfPo',
      'desc': 'Production ready backend engineering in Hindi',
    },
    {
      'title': 'Flutter 3.0 Complete Guide',
      'channel': 'Rivaan Ranawat',
      'channelInitial': 'R',
      'channelColor': const Color(0xFF7C5CBF),
      'level': 'All Levels',
      'image': 'assets/Resources/DEV & AI/Flutter.png',
      'url': 'https://youtube.com/@rivaanranawat?si=cic9rqgnsefyXwRO',
      'desc': 'Build cross-platform mobile apps',
    },
  ];

  final List<Map<String, dynamic>> tools = [
    {
      'title': 'Git & GitHub Masterclass',
      'channel': 'Kunal Kushwaha',
      'channelInitial': 'K',
      'channelColor': const Color(0xFFF05032),
      'level': 'Beginner',
      'image': 'assets/Resources/TOOLS/Git&Github.png',
      'url': 'https://youtu.be/apGV9Kg7ics',
      'desc': 'Version control, branching & open source workflow',
    },
    {
      'title': 'Docker for Beginners',
      'channel': 'freeCodeCamp',
      'channelInitial': 'F',
      'channelColor': const Color(0xFF2496ED),
      'level': 'Intermediate',
      'image': 'assets/Resources/TOOLS/Docker-for-beginner.png',
      'url': 'https://youtu.be/fqMOX6JJhGo',
      'desc': 'Containers, images, volumes & docker-compose',
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
          const SnackBar(content: Text('Could not open YouTube link')),
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
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top Navy Header
            Container(
              color: const Color(0xFF111322),
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
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Top YouTube courses — Indian & Global',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: const Color(0xFFB3B0D6),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    labelColor: const Color(0xFFFF5722),
                    unselectedLabelColor: const Color(0xFFB3B0D6),
                    indicatorColor: const Color(0xFFFF5722),
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    onTap: (_) => setState(() {}),
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
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

            // Resources List (Mobile Friendly Cards)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
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

            // Bottom Nav Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFEAEAF2)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home',
                      false, () => context.go('/home')),
                  _NavItem(Icons.map_outlined, Icons.map_rounded, 'Roadmap',
                      false, () => context.go('/home')),
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

  Widget _buildThumbnail() {
    final imagePath = resource['image'] as String?;
    final initial = resource['channelInitial'] as String? ?? 'R';
    final initialColor = resource['channelColor'] as Color? ?? const Color(0xFF7C5CBF);

    Widget fallbackAvatar = Container(
      color: const Color(0xFFF3F2F9),
      child: Center(
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: initialColor, width: 2),
          ),
          child: Center(
            child: Text(
              initial,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: initialColor,
              ),
            ),
          ),
        ),
      ),
    );

    if (imagePath == null) return fallbackAvatar;

    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        final altPath = imagePath.contains('Languages /')
            ? imagePath.replaceAll('Languages /', 'Languages/')
            : imagePath.replaceAll('Languages/', 'Languages /');
        return Image.asset(
          altPath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallbackAvatar,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = resource['channelInitial'] as String? ?? 'R';
    final initialColor = resource['channelColor'] as Color? ?? const Color(0xFF7C5CBF);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 16:9 YouTube Thumbnail Banner
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 124,
                height: 72,
                child: _buildThumbnail(),
              ),
            ),
            const SizedBox(width: 12),

            // Video & Channel Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource['title'] ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Mini Channel Initial Badge
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: initialColor, width: 1.2),
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: initialColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          resource['channel'] ?? '',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF6B6890),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Level Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F1FC),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          resource['level'] ?? 'All Levels',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2E6FD9),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    resource['desc'] ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF9B99B5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Vibrant Watch Now CTA Button
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5722),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5722).withOpacity(0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Watch Now',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
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
        color: active ? const Color(0xFFFFEFEA) : Colors.transparent,
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
              color: active ? const Color(0xFFFF5722) : const Color(0xFF9B99B5),
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}
