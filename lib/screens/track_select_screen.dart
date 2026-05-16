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

  final List<String> categories = [
    '📊 Data & AI',
    '🖥️ Development',
    '☁️ DevOps & Cloud',
    '🔒 Security',
    '🎨 Design',
    '🤖 Emerging Tech',
  ];

  final Map<int, List<Map<String, dynamic>>> tracks = {
    0: [
      {
        'title': 'Data Scientist',
        'emoji': '📊',
        'desc': 'Analyse data, build ML models and extract business insights',
        'skills': ['Python', 'Statistics', 'ML', 'Power BI', 'SQL'],
        'duration': '16 weeks',
        'salary': '₹8–18 LPA',
        'demand': 'High',
        'tag': 'Most Popular 🔥',
        'color': Color(0xFF8B53EC),
      },
      {
        'title': 'Data Analyst',
        'emoji': '📈',
        'desc': 'Analyse business data and create reports and dashboards',
        'skills': ['Excel', 'SQL', 'Power BI', 'Tableau', 'Python'],
        'duration': '12 weeks',
        'salary': '₹5–12 LPA',
        'demand': 'Steady',
        'tag': 'Best for Beginners ⭐',
        'color': Color(0xFF6B35CC),
      },
      {
        'title': 'Data Engineer',
        'emoji': '🔧',
        'desc': 'Build data pipelines, warehouses and large-scale data systems',
        'skills': ['SQL', 'Spark', 'Kafka', 'Airflow', 'dbt'],
        'duration': '20 weeks',
        'salary': '₹10–22 LPA',
        'demand': 'Growing',
        'tag': 'Fast Growing 📈',
        'color': Color(0xFFAA75F0),
      },
      {
        'title': 'ML Engineer',
        'emoji': '🤖',
        'desc': 'Build and deploy machine learning models into production',
        'skills': ['Python', 'TensorFlow', 'PyTorch', 'Docker', 'FastAPI'],
        'duration': '24 weeks',
        'salary': '₹12–30 LPA',
        'demand': 'Very High',
        'tag': 'Highest Paying 💰',
        'color': Color(0xFF8B53EC),
      },
      {
        'title': 'AI Engineer',
        'emoji': '🧠',
        'desc': 'Build AI systems like chatbots, recommendation engines and AI apps',
        'skills': ['Python', 'OpenAI APIs', 'LangChain', 'LLMs', 'Vector DBs'],
        'duration': '24 weeks',
        'salary': '₹15–35 LPA',
        'demand': 'Explosive',
        'tag': 'Future of Tech 🚀',
        'color': Color(0xFF6B35CC),
      },
      {
        'title': 'NLP Engineer',
        'emoji': '💬',
        'desc': 'Build human language AI systems and text processing pipelines',
        'skills': ['Python', 'Transformers', 'Hugging Face', 'BERT', 'LLMs'],
        'duration': '20 weeks',
        'salary': '₹12–28 LPA',
        'demand': 'High',
        'tag': 'Specialised 🎯',
        'color': Color(0xFFAA75F0),
      },
      {
        'title': 'Computer Vision Engineer',
        'emoji': '👁️',
        'desc': 'Build image and video AI systems for detection and recognition',
        'skills': ['Python', 'OpenCV', 'PyTorch', 'TensorFlow', 'YOLO'],
        'duration': '20 weeks',
        'salary': '₹12–28 LPA',
        'demand': 'High',
        'tag': 'Specialised 🎯',
        'color': Color(0xFF8B53EC),
      },
      {
        'title': 'Prompt Engineer',
        'emoji': '✍️',
        'desc': 'Design prompts and workflows for AI systems and LLMs',
        'skills': ['ChatGPT APIs', 'LangChain', 'RAG', 'AI workflows'],
        'duration': '8 weeks',
        'salary': '₹8–20 LPA',
        'demand': 'New & Growing',
        'tag': 'Newest Role 🆕',
        'color': Color(0xFF6B35CC),
      },
    ],
    1: [
      {
        'title': 'Frontend Developer',
        'emoji': '🎨',
        'desc': 'Build beautiful user interfaces for websites and web apps',
        'skills': ['HTML', 'CSS', 'JavaScript', 'React', 'Tailwind'],
        'duration': '16 weeks',
        'salary': '₹6–15 LPA',
        'demand': 'High',
        'tag': 'Always in Demand 💼',
        'color': Color(0xFF8B53EC),
      },
      {
        'title': 'Backend Developer',
        'emoji': '⚙️',
        'desc': 'Build servers, APIs, databases and business logic',
        'skills': ['Node.js', 'Express', 'Django', 'PostgreSQL', 'REST APIs'],
        'duration': '18 weeks',
        'salary': '₹8–18 LPA',
        'demand': 'High',
        'tag': 'Core Role 🔑',
        'color': Color(0xFF6B35CC),
      },
      {
        'title': 'Full Stack Developer',
        'emoji': '💻',
        'desc': 'Handle both frontend and backend development end to end',
        'skills': ['React', 'Node.js', 'MongoDB', 'PostgreSQL', 'Docker'],
        'duration': '24 weeks',
        'salary': '₹8–20 LPA',
        'demand': 'Very High',
        'tag': 'Most Versatile 🌟',
        'color': Color(0xFFAA75F0),
      },
      {
        'title': 'Mobile App Developer',
        'emoji': '📱',
        'desc': 'Build Android and iOS apps using Flutter or React Native',
        'skills': ['Flutter', 'Dart', 'React Native', 'Firebase', 'APIs'],
        'duration': '20 weeks',
        'salary': '₹7–18 LPA',
        'demand': 'High',
        'tag': 'Great for India 🇮🇳',
        'color': Color(0xFF8B53EC),
      },
      {
        'title': 'Software Engineer',
        'emoji': '🛠️',
        'desc': 'Build software applications, systems and platforms',
        'skills': ['Python', 'Java', 'DSA', 'OOP', 'Git'],
        'duration': '24 weeks',
        'salary': '₹8–25 LPA',
        'demand': 'Very High',
        'tag': 'Foundation Role 🏗️',
        'color': Color(0xFF6B35CC),
      },
      {
        'title': 'Game Developer',
        'emoji': '🎮',
        'desc': 'Create games for PC, mobile and consoles using Unity or Unreal',
        'skills': ['Unity', 'C#', 'Unreal Engine', 'C++', '3D Math'],
        'duration': '24 weeks',
        'salary': '₹6–15 LPA',
        'demand': 'Growing',
        'tag': 'Creative Tech 🎯',
        'color': Color(0xFFAA75F0),
      },
      {
        'title': 'Blockchain Developer',
        'emoji': '⛓️',
        'desc': 'Build decentralised applications and smart contracts',
        'skills': ['Solidity', 'Ethereum', 'Web3.js', 'Smart Contracts'],
        'duration': '20 weeks',
        'salary': '₹12–30 LPA',
        'demand': 'Niche but High',
        'tag': 'High Paying 💰',
        'color': Color(0xFF8B53EC),
      },
    ],
    2: [
      {
        'title': 'DevOps Engineer',
        'emoji': '🔄',
        'desc': 'Automate deployment, CI/CD pipelines and infrastructure',
        'skills': ['Docker', 'Kubernetes', 'Jenkins', 'AWS', 'Linux'],
        'duration': '20 weeks',
        'salary': '₹10–25 LPA',
        'demand': 'Very High',
        'tag': 'Always Needed 🔑',
        'color': Color(0xFF8B53EC),
      },
      {
        'title': 'Cloud Engineer',
        'emoji': '☁️',
        'desc': 'Manage cloud infrastructure and services on AWS, Azure or GCP',
        'skills': ['AWS', 'Azure', 'GCP', 'Docker', 'Kubernetes'],
        'duration': '20 weeks',
        'salary': '₹12–28 LPA',
        'demand': 'Explosive',
        'tag': 'Future Proof ☁️',
        'color': Color(0xFF6B35CC),
      },
      {
        'title': 'Site Reliability Engineer',
        'emoji': '📡',
        'desc': 'Maintain system reliability, scalability and performance',
        'skills': ['Kubernetes', 'Monitoring', 'Linux', 'Cloud', 'Automation'],
        'duration': '20 weeks',
        'salary': '₹15–35 LPA',
        'demand': 'High',
        'tag': 'Senior Role 🎓',
        'color': Color(0xFFAA75F0),
      },
      {
        'title': 'Database Administrator',
        'emoji': '🗄️',
        'desc': 'Manage, optimise and secure databases at scale',
        'skills': ['MySQL', 'PostgreSQL', 'Oracle', 'SQL', 'Backup'],
        'duration': '16 weeks',
        'salary': '₹8–18 LPA',
        'demand': 'Steady',
        'tag': 'Essential Role 💼',
        'color': Color(0xFF8B53EC),
      },
      {
        'title': 'Embedded Systems Engineer',
        'emoji': '🔌',
        'desc': 'Develop software for hardware devices and microcontrollers',
        'skills': ['C', 'C++', 'Arduino', 'Raspberry Pi', 'RTOS'],
        'duration': '20 weeks',
        'salary': '₹7–18 LPA',
        'demand': 'Steady',
        'tag': 'Hardware + SW 🔧',
        'color': Color(0xFF6B35CC),
      },
    ],
    3: [
      {
        'title': 'Cybersecurity Engineer',
        'emoji': '🔒',
        'desc': 'Protect systems from hacking, attacks and vulnerabilities',
        'skills': ['Kali Linux', 'Wireshark', 'Burp Suite', 'Networking'],
        'duration': '20 weeks',
        'salary': '₹10–25 LPA',
        'demand': 'Very High',
        'tag': 'Critical Role 🛡️',
        'color': Color(0xFF8B53EC),
      },
      {
        'title': 'QA Test Engineer',
        'emoji': '🧪',
        'desc': 'Test software, find bugs and ensure product quality',
        'skills': ['Selenium', 'JUnit', 'Cypress', 'Postman', 'Manual Testing'],
        'duration': '14 weeks',
        'salary': '₹5–12 LPA',
        'demand': 'Steady',
        'tag': 'Entry Friendly ⭐',
        'color': Color(0xFF6B35CC),
      },
    ],
    4: [
      {
        'title': 'UI/UX Designer',
        'emoji': '🎨',
        'desc': 'Design user-friendly interfaces and great user experiences',
        'skills': ['Figma', 'Adobe XD', 'Wireframing', 'Prototyping'],
        'duration': '12 weeks',
        'salary': '₹6–15 LPA',
        'demand': 'High',
        'tag': 'Creative Role 🎭',
        'color': Color(0xFF8B53EC),
      },
    ],
    5: [
      {
        'title': 'AR/VR Engineer',
        'emoji': '🥽',
        'desc': 'Build Augmented Reality and Virtual Reality applications',
        'skills': ['Unity', 'Unreal Engine', 'ARKit', 'ARCore', '3D'],
        'duration': '24 weeks',
        'salary': '₹10–25 LPA',
        'demand': 'Growing',
        'tag': 'Future Tech 🔮',
        'color': Color(0xFF8B53EC),
      },
      {
        'title': 'Robotics Engineer',
        'emoji': '🤖',
        'desc': 'Build robots and automation systems using ROS and sensors',
        'skills': ['ROS', 'Python', 'C++', 'Sensors', 'Electronics'],
        'duration': '24 weeks',
        'salary': '₹8–20 LPA',
        'demand': 'Growing',
        'tag': 'Niche but Exciting 🚀',
        'color': Color(0xFF6B35CC),
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          color: AppTheme.textDark,
          onPressed: () => context.go('/onboarding'),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose your track',
                  style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                Text('AI will build your personalised week-by-week roadmap',
                  style: GoogleFonts.poppins(
                    fontSize: 13, color: AppTheme.textMid),
                ),
              ],
            ),
          ),

          // Category tabs
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => setState(() => _selectedCategory = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedCategory == i
                        ? AppTheme.primary
                        : AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedCategory == i
                          ? AppTheme.primary
                          : AppTheme.border,
                    ),
                  ),
                  child: Text(categories[i],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _selectedCategory == i
                          ? Colors.white
                          : AppTheme.textMid,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Track list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: tracks[_selectedCategory]?.length ?? 0,
              itemBuilder: (context, i) {
                final track = tracks[_selectedCategory]![i];
                return _TrackCard(
                  track: track,
                  onTap: () => context.go('/generating?track=${Uri.encodeComponent(track['title'])}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  final Map<String, dynamic> track;
  final VoidCallback onTap;
  const _TrackCard({required this.track, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = track['color'] as Color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withOpacity(0.2)),
                        ),
                        child: Center(
                          child: Text(track['emoji'],
                            style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(track['title'],
                              style: GoogleFonts.poppins(
                                fontSize: 15, fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                            Text(track['duration'],
                              style: GoogleFonts.poppins(
                                fontSize: 12, color: AppTheme.textMid),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withOpacity(0.2)),
                        ),
                        child: Text(track['tag'],
                          style: GoogleFonts.poppins(
                            fontSize: 9, fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(track['desc'],
                    style: GoogleFonts.poppins(
                      fontSize: 12, color: AppTheme.textMid, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6, runSpacing: 4,
                    children: (track['skills'] as List<String>).map((s) =>
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: color.withOpacity(0.2)),
                        ),
                        child: Text(s,
                          style: GoogleFonts.poppins(
                            fontSize: 10, fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ),
                    ).toList(),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                    top: BorderSide(color: color.withOpacity(0.15))),
              ),
              child: Row(
                children: [
                  Text('💰',
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Avg Salary',
                        style: GoogleFonts.poppins(
                            fontSize: 9, color: AppTheme.textLight)),
                      Text(track['salary'],
                        style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 28, width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: AppTheme.border,
                  ),
                  Text('📊',
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Demand',
                        style: GoogleFonts.poppins(
                            fontSize: 9, color: AppTheme.textLight)),
                      Text(track['demand'],
                        style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Select →',
                        style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
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
