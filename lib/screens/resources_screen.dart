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
      'image': 'https://img.youtube.com/vi/eWRfhZUzrAc/hqdefault.jpg',
      'url': 'https://youtu.be/eWRfhZUzrAc',
    },
    {
      'title': 'Java Full Course',
      'channel': 'Apna College',
      'channelInitial': 'A',
      'channelColor': const Color(0xFFFF5722),
      'level': 'Beginner',
      'image': 'https://img.youtube.com/vi/yRpLlJmRo2w/hqdefault.jpg',
      'url': 'https://youtu.be/yRpLlJmRo2w',
    },
    {
      'title': 'JavaScript Mastery',
      'channel': 'Chai aur Code',
      'channelInitial': 'C',
      'channelColor': const Color(0xFFF7DF1E),
      'level': 'Beginner',
      'image': 'https://img.youtube.com/vi/sscX432bMZo/hqdefault.jpg',
      'url': 'https://youtu.be/sscX432bMZo',
    },
    {
      'title': 'C++ Full Course',
      'channel': 'CodeWithHarry',
      'channelInitial': 'C',
      'channelColor': const Color(0xFF00599C),
      'level': 'Beginner',
      'image': 'https://img.youtube.com/vi/j8nAHeVKL08/hqdefault.jpg',
      'url': 'https://youtu.be/j8nAHeVKL08',
    },
  ];

  final List<Map<String, dynamic>> dsa = [
    {
      'title': 'Striver A2Z DSA Course',
      'channel': 'take U forward',
      'channelInitial': 'T',
      'channelColor': const Color(0xFFFF5722),
      'level': 'All Levels',
      'image': 'https://img.youtube.com/vi/0bHoB35fCkg/hqdefault.jpg',
      'url': 'https://youtu.be/0bHoB35fCkg',
    },
    {
      'title': 'Love Babbar DSA Sheet',
      'channel': 'CodeHelp',
      'channelInitial': 'L',
      'channelColor': const Color(0xFF7C5CBF),
      'level': 'Beginner to Advanced',
      'image': 'https://img.youtube.com/vi/WQoB2z67hvY/hqdefault.jpg',
      'url': 'https://youtu.be/WQoB2z67hvY',
    },
    {
      'title': 'Abdul Bari Algorithms',
      'channel': 'Abdul Bari',
      'channelInitial': 'A',
      'channelColor': const Color(0xFF00B894),
      'level': 'Intermediate',
      'image': 'https://img.youtube.com/vi/0IAPZzGSbME/hqdefault.jpg',
      'url': 'https://youtu.be/0IAPZzGSbME',
    },
    {
      'title': 'Kunal Kushwaha DSA Playlist',
      'channel': 'Kunal Kushwaha',
      'channelInitial': 'K',
      'channelColor': const Color(0xFF00599C),
      'level': 'Beginner',
      'image': 'https://img.youtube.com/vi/rZ41y93P2Qo/hqdefault.jpg',
      'url': 'https://youtu.be/rZ41y93P2Qo',
    },
  ];

  final List<Map<String, dynamic>> dev = [
    {
      'title': 'React JS Complete Course',
      'channel': 'Chai aur Code',
      'channelInitial': 'C',
      'channelColor': const Color(0xFF61DAFB),
      'level': 'Beginner',
      'image': 'https://img.youtube.com/vi/vz1RlUyrc3w/hqdefault.jpg',
      'url': 'https://youtube.com/playlist?list=PLu71SKxNbfoDqgPchmvIsL4hTnJIrtige&si=jbMEtRLKDdNATui-',
    },
    {
      'title': 'Backend Development (Node.js)',
      'channel': 'Piyush Garg',
      'channelInitial': 'P',
      'channelColor': const Color(0xFF68A063),
      'level': 'Intermediate',
      'image': 'https://img.youtube.com/vi/ohIAiuHMKMI/hqdefault.jpg',
      'url': 'https://youtu.be/ohIAiuHMKMI',
    },
    {
      'title': 'Flutter 3 Complete Course',
      'channel': 'Rivaan Ranawat',
      'channelInitial': 'R',
      'channelColor': const Color(0xFF02569B),
      'level': 'All Levels',
      'image': 'https://img.youtube.com/vi/VPvVD8t02U8/hqdefault.jpg',
      'url': 'https://youtu.be/VPvVD8t02U8',
    },
    {
      'title': 'Machine Learning Specialization',
      'channel': 'DeepLearning.AI',
      'channelInitial': 'D',
      'channelColor': const Color(0xFFFF5722),
      'level': 'Intermediate',
      'image': 'https://img.youtube.com/vi/jGwO_bWUtGE/hqdefault.jpg',
      'url': 'https://youtu.be/jGwO_bWUtGE',
    },
  ];

  final List<Map<String, dynamic>> tools = [
    {
      'title': 'Git & GitHub Bootcamp',
      'channel': 'Kunal Kushwaha',
      'channelInitial': 'K',
      'channelColor': const Color(0xFFF05032),
      'level': 'Beginner',
      'image': 'https://img.youtube.com/vi/apGV9Kg7ics/hqdefault.jpg',
      'url': 'https://youtu.be/apGV9Kg7ics',
    },
    {
      'title': 'Docker for Beginners',
      'channel': 'freeCodeCamp',
      'channelInitial': 'F',
      'channelColor': const Color(0xFF2496ED),
      'level': 'Intermediate',
      'image': 'https://img.youtube.com/vi/fqMOX6JJhGo/hqdefault.jpg',
      'url': 'https://youtu.be/fqMOX6JJhGo',
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
                14,
                topPadding > 0 ? topPadding + 10 : 24,
                14,
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Learning Resources',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Top YouTube courses — Indian & Global',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              color: const Color(0xFFB3B0D6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 4 Tabs Strip (Fit full text on small screens)
                  TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                    labelColor: const Color(0xFFFF5722),
                    unselectedLabelColor: const Color(0xFF8C8AA8),
                    indicatorColor: const Color(0xFFFF5722),
                    indicatorWeight: 3,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                    unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
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

  @override
  Widget build(BuildContext context) {
    final initial = resource['channelInitial'] as String? ?? 'R';
    final initialColor =
        resource['channelColor'] as Color? ?? const Color(0xFF7C5CBF);
    final imageUrl = resource['image'] as String? ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEAEAF2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 16:9 YouTube Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 88,
                  height: 54,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF0EDF8),
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
                      Positioned(
                        right: 3,
                        bottom: 3,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Video Details (Title, Channel, Level - with Wrap so it NEVER overflows)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      resource['title'] ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A2E),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Channel initial badge
                        Container(
                          width: 14,
                          height: 14,
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
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: initialColor,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          resource['channel'] ?? '',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B6890),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F0FA),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            resource['level'] ?? 'Beginner',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8,
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
              const SizedBox(width: 6),

              // Compact Watch Button
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5722),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 1),
                    Text(
                      'Watch',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
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
