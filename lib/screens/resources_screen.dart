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
      'channel': 'freeCodeCamp',
      'channelInitial': 'F',
      'channelColor': const Color(0xFF00599C),
      'level': 'Beginner',
      'image': 'assets/Resources/Languages/Python.png',
      'onlineThumb': 'https://img.youtube.com/vi/eWRfhZUzrAc/hqdefault.jpg',
      'rawGitThumb':
          'https://raw.githubusercontent.com/Snehachoudhary26/pathforge/main/assets/Resources/Languages/Python.png',
      'url': 'https://youtu.be/eWRfhZUzrAc',
      'desc': 'Variables, loops, OOP, data structures & real projects',
    },
    {
      'title': 'Java Full Course',
      'channel': 'Apna College',
      'channelInitial': 'A',
      'channelColor': const Color(0xFFFF5722),
      'level': 'Beginner',
      'image': 'assets/Resources/Languages/Java.png',
      'onlineThumb': 'https://img.youtube.com/vi/yRpLlJmRo2w/hqdefault.jpg',
      'rawGitThumb':
          'https://raw.githubusercontent.com/Snehachoudhary26/pathforge/main/assets/Resources/Languages/Java.png',
      'url': 'https://youtu.be/yRpLlJmRo2w',
      'desc': 'Core Java, OOPs concepts, collections framework & DSA basics',
    },
    {
      'title': 'JavaScript Mastery',
      'channel': 'Chai aur Code',
      'channelInitial': 'C',
      'channelColor': const Color(0xFFF7DF1E),
      'level': 'Beginner',
      'image': 'assets/Resources/Languages/Javascript.png',
      'onlineThumb': 'https://img.youtube.com/vi/sscX432bMZo/hqdefault.jpg',
      'rawGitThumb':
          'https://raw.githubusercontent.com/Snehachoudhary26/pathforge/main/assets/Resources/Languages/Javascript.png',
      'url': 'https://youtu.be/sscX432bMZo',
      'desc': 'ES6+, DOM, Async/Await, closures & modern JS practices',
    },
    {
      'title': 'C++ Full Course',
      'channel': 'CodeWithHarry',
      'channelInitial': 'C',
      'channelColor': const Color(0xFF00599C),
      'level': 'Beginner',
      'image': 'assets/Resources/Languages/C++.png',
      'onlineThumb': 'https://img.youtube.com/vi/j8nAHeVKL08/hqdefault.jpg',
      'rawGitThumb':
          'https://raw.githubusercontent.com/Snehachoudhary26/pathforge/main/assets/Resources/Languages/C%2B%2B.png',
      'url': 'https://youtu.be/j8nAHeVKL08',
      'desc': 'Pointers, memory management, STL & OOP principles',
    },
  ];

  final List<Map<String, dynamic>> dsa = [
    {
      'title': 'Striver A2Z DSA Course',
      'channel': 'take U forward',
      'channelInitial': 'T',
      'channelColor': const Color(0xFFFF5722),
      'level': 'All Levels',
      'image': 'assets/Resources/DSA/Striver-dsa.png',
      'onlineThumb': 'https://img.youtube.com/vi/EAR7De6Godd/hqdefault.jpg',
      'rawGitThumb':
          'https://raw.githubusercontent.com/Snehachoudhary26/pathforge/main/assets/Resources/DSA/Striver-dsa.png',
      'url': 'https://youtu.be/EAR7De6Godd',
      'desc': 'Arrays, Trees, Graphs, DP & top interview problem patterns',
    },
    {
      'title': 'Love Babbar DSA Sheet',
      'channel': 'CodeHelp',
      'channelInitial': 'L',
      'channelColor': const Color(0xFF7C5CBF),
      'level': 'Beginner to Advanced',
      'image': 'assets/Resources/DSA/Love-babbar-dsa.png',
      'onlineThumb': 'https://img.youtube.com/vi/WQoB2z67hvY/hqdefault.jpg',
      'rawGitThumb':
          'https://raw.githubusercontent.com/Snehachoudhary26/pathforge/main/assets/Resources/DSA/Love-babbar-dsa.png',
      'url': 'https://youtu.be/WQoB2z67hvY',
      'desc': '450+ curated DSA coding interview problems & step-by-step solutions',
    },
    {
      'title': 'Abdul Bari Algorithms',
      'channel': 'Abdul Bari',
      'channelInitial': 'A',
      'channelColor': const Color(0xFF00B894),
      'level': 'Intermediate',
      'image': 'assets/Resources/DSA/Abdul-bari-dsa.png',
      'onlineThumb': 'https://img.youtube.com/vi/0IAPZzGSbME/hqdefault.jpg',
      'rawGitThumb':
          'https://raw.githubusercontent.com/Snehachoudhary26/pathforge/main/assets/Resources/DSA/Abdul-bari-dsa.png',
      'url': 'https://youtu.be/0IAPZzGSbME',
      'desc': 'Time complexity, divide & conquer, greedy, DP & graph algorithms',
    },
    {
      'title': 'Kunal Kushwaha DSA Playlist',
      'channel': 'Kunal Kushwaha',
      'channelInitial': 'K',
      'channelColor': const Color(0xFF00599C),
      'level': 'Beginner',
      'image': 'assets/Resources/DSA/Kunal-kushwaha.png',
      'onlineThumb': 'https://img.youtube.com/vi/rZ41y93P2Qo/hqdefault.jpg',
      'rawGitThumb':
          'https://raw.githubusercontent.com/Snehachoudhary26/pathforge/main/assets/Resources/DSA/Kunal-kushwaha.png',
      'url': 'https://youtu.be/rZ41y93P2Qo',
      'desc': 'Java + DSA with Git, open source & live hands-on practice',
    },
  ];

  final List<Map<String, dynamic>> dev = [
    {
      'title': 'React JS Complete Course',
      'channel': 'Chai aur Code',
      'channelInitial': 'C',
      'channelColor': const Color(0xFF61DAFB),
      'level': 'Beginner',
      'image': 'assets/Resources/DEV & AI/React-js.png',
      'onlineThumb': 'https://img.youtube.com/vi/vz1RlUyrc3w/hqdefault.jpg',
      'rawGitThumb':
          'https://raw.githubusercontent.com/Snehachoudhary26/pathforge/main/assets/Resources/DEV%20%26%20AI/React-js.png',
      'url': 'https://youtube.com/playlist?list=PLu71SKxNbfoDqgPchmvIsL4hTnJIrtige&si=jbMEtRLKDdNATui-',
      'desc': 'Hooks, state management, router, Tailwind & full-stack projects',
    },
    {
      'title': 'Backend Development (Node.js)',
      'channel': 'Piyush Garg',
      'channelInitial': 'P',
      'channelColor': const Color(0xFF68A063),
      'level': 'Intermediate',
      'image': 'assets/Resources/DEV & AI/Backend.png',
      'onlineThumb': 'https://img.youtube.com/vi/ohIAiuHMKMI/hqdefault.jpg',
      'rawGitThumb':
          'https://raw.githubusercontent.com/Snehachoudhary26/pathforge/main/assets/Resources/DEV%20%26%20AI/Backend.png',
      'url': 'https://youtu.be/ohIAiuHMKMI',
      'desc': 'Express, MongoDB, REST APIs, authentication & architecture',
    },
    {
      'title': 'Flutter 3 Complete Course',
      'channel': 'Rivaan Ranawat',
      'channelInitial': 'R',
      'channelColor': const Color(0xFF02569B),
      'level': 'All Levels',
      'image': 'assets/Resources/DEV & AI/Flutter.png',
      'onlineThumb': 'https://img.youtube.com/vi/VPvVD8t02U8/hqdefault.jpg',
      'rawGitThumb':
          'https://raw.githubusercontent.com/Snehachoudhary26/pathforge/main/assets/Resources/DEV%20%26%20AI/Flutter.png',
      'url': 'https://youtu.be/VPvVD8t02U8',
      'desc': 'Cross-platform iOS & Android, Firebase, Riverpod & real apps',
    },
    {
      'title': 'Machine Learning Specialization',
      'channel': 'Andrew Ng',
      'channelInitial': 'A',
      'channelColor': const Color(0xFFFF5722),
      'level': 'Intermediate',
      'image': 'assets/Resources/DEV & AI/Machine-learning.png',
      'onlineThumb': 'https://img.youtube.com/vi/jGwO_b/hqdefault.jpg',
      'rawGitThumb':
          'https://raw.githubusercontent.com/Snehachoudhary26/pathforge/main/assets/Resources/DEV%20%26%20AI/Machine-learning.png',
      'url': 'https://youtu.be/jGwO_bWUtGE',
      'desc': 'Supervised learning, neural networks, LLMs & AI foundations',
    },
  ];

  final List<Map<String, dynamic>> tools = [
    {
      'title': 'Git & GitHub Bootcamp',
      'channel': 'Kunal Kushwaha',
      'channelInitial': 'K',
      'channelColor': const Color(0xFFF05032),
      'level': 'Beginner',
      'image': 'assets/Resources/TOOLS/Git&Github.png',
      'onlineThumb': 'https://img.youtube.com/vi/apGV9Kg7ics/hqdefault.jpg',
      'rawGitThumb':
          'https://raw.githubusercontent.com/Snehachoudhary26/pathforge/main/assets/Resources/TOOLS/Git%26Github.png',
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
      'onlineThumb': 'https://img.youtube.com/vi/fqMOX6JJhGo/hqdefault.jpg',
      'rawGitThumb':
          'https://raw.githubusercontent.com/Snehachoudhary26/pathforge/main/assets/Resources/TOOLS/Docker-for-beginner.png',
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
                16,
                topPadding > 0 ? topPadding + 10 : 24,
                16,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/home'),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Learning Resources',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Top YouTube courses — Indian & Global',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFFB3B0D6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 4 Tabs Strip (100% Overflow-Free)
                  TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    labelColor: const Color(0xFFFF5722),
                    unselectedLabelColor: const Color(0xFF8C8AA8),
                    indicatorColor: const Color(0xFFFF5722),
                    indicatorWeight: 3,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    onTap: (_) => setState(() {}),
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
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
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
              padding: const EdgeInsets.symmetric(vertical: 6),
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
    final onlineThumb = resource['onlineThumb'] as String?;
    final rawGitThumb = resource['rawGitThumb'] as String?;
    final initial = resource['channelInitial'] as String? ?? 'R';
    final initialColor =
        resource['channelColor'] as Color? ?? const Color(0xFF7C5CBF);

    Widget fallbackAvatar = Container(
      color: const Color(0xFFF3F2F9),
      child: Center(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: initialColor, width: 2),
          ),
          child: Center(
            child: Text(
              initial,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: initialColor,
              ),
            ),
          ),
        ),
      ),
    );

    if (imagePath != null && imagePath.isNotEmpty) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          if (onlineThumb != null && onlineThumb.isNotEmpty) {
            return Image.network(
              onlineThumb,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                if (rawGitThumb != null && rawGitThumb.isNotEmpty) {
                  return Image.network(
                    rawGitThumb,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => fallbackAvatar,
                  );
                }
                return fallbackAvatar;
              },
            );
          }
          return fallbackAvatar;
        },
      );
    }

    if (onlineThumb != null && onlineThumb.isNotEmpty) {
      return Image.network(
        onlineThumb,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          if (rawGitThumb != null && rawGitThumb.isNotEmpty) {
            return Image.network(
              rawGitThumb,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallbackAvatar,
            );
          }
          return fallbackAvatar;
        },
      );
    }
    return fallbackAvatar;
  }

  @override
  Widget build(BuildContext context) {
    final initial = resource['channelInitial'] as String? ?? 'R';
    final initialColor =
        resource['channelColor'] as Color? ?? const Color(0xFF7C5CBF);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAEAF2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 16:9 YouTube Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 96,
                  height: 60,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildThumbnail(),
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Video Details (Title, Channel, Level)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource['title'] ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A2E),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Channel initial badge
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: initialColor.withOpacity(0.15),
                            border:
                                Border.all(color: initialColor, width: 1.0),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: initialColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            resource['channel'] ?? '',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B6890),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 5),
                        // Level Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F0FA),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            resource['level'] ?? 'Beginner',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF7C5CBF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Compact Watch Button
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5722),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Watch',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFFEFEA) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? activeIcon : icon,
            color: active ? const Color(0xFFFF5722) : const Color(0xFF9B99B5),
            size: 20,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              color:
                  active ? const Color(0xFFFF5722) : const Color(0xFF9B99B5),
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}
