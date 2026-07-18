import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';

class GeminiService {
  static const String _apiKey =
      AppConfig.groqApiKey;
  static const String _url =
      AppConfig.groqUrl;
  static const String _model = AppConfig.groqModel;

  static Future<String?> _callGroq(String prompt,
      {double temperature = 0.7, int maxTokens = 1000}) async {
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['choices'][0]['message']['content'] as String;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ─── Roadmap Generation ──────────────────────────────────────────

  static Future<Map<String, dynamic>?> generateRoadmap({
    required String track,
    required String branch,
    required String year,
    required String experience,
    required String hours,
    required String goal,
  }) async {
    final prompt = _buildRoadmapPrompt(
        track, branch, year, experience, hours, goal);
    final text = await _callGroq(prompt, temperature: 0.5, maxTokens: 2000);
    if (text == null) return _fallbackRoadmap(track);
    try {
      String clean = text.trim()
          .replaceAll('```json', '').replaceAll('```', '').trim();
      final start = clean.indexOf('{');
      final end = clean.lastIndexOf('}');
      if (start != -1 && end != -1) clean = clean.substring(start, end + 1);
      return jsonDecode(clean) as Map<String, dynamic>;
    } catch (_) {
      return _fallbackRoadmap(track);
    }
  }

  // ─── AI Coach ────────────────────────────────────────────────────

  static Future<String> getCoachInsight({
    required String userName,
    required String track,
    required int doneWeeks,
    required int totalWeeks,
    required int streak,
    required int xp,
    required String goal,
    required String experience,
  }) async {
    if (track.isEmpty) {
      return 'Generate your roadmap to unlock personalised AI coaching.';
    }
    final left = totalWeeks - doneWeeks;
    final prompt =
        'You are an AI career coach for Indian engineering students. '
        'Student: $userName. Track: $track. '
        'Progress: $doneWeeks of $totalWeeks weeks done. '
        'Streak: $streak days. XP: $xp. Goal: $goal. '
        'Give exactly 2 sentences of personalised actionable advice. '
        'Reference their actual numbers. Under 40 words. Sound like a real mentor.';

    final text = await _callGroq(prompt, temperature: 0.8, maxTokens: 100);
    return text?.trim() ??
        _fallbackInsight(userName, track, doneWeeks, totalWeeks, streak);
  }

  static String _fallbackInsight(String name, String track,
      int done, int total, int streak) {
    final left = total - done;
    if (done == 0) return 'Start Week 1 of $track today — the first step is the hardest. $total weeks from now you will be interview-ready.';
    if (streak >= 7) return 'Outstanding ${streak}-day streak, $name! You are in the top 10% of learners. $left weeks left — keep this momentum.';
    if (done >= total ~/ 2) return 'You are over halfway through $track — $left weeks to go. Focus on projects this week to stand out in interviews.';
    return 'Great pace on $track, $name. $left weeks remaining — aim to complete one skill per day to finish ahead of schedule.';
  }

  // ─── Interview Questions ──────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> generateInterviewQuestions({
    required String track,
    required String weekTitle,
  }) async {
    final prompt =
        'Generate 5 interview questions for a "$track" role about "$weekTitle". '
        'For Indian engineering students applying for their first job. '
        'Return ONLY valid JSON: {"questions":[{"question":"...","type":"Conceptual","difficulty":"Easy","keyPoints":["p1","p2","p3"]}]} '
        'No markdown. Just JSON.';

    final text = await _callGroq(prompt, temperature: 0.7, maxTokens: 1000);
    if (text == null) return _fallbackQuestions(weekTitle);
    try {
      String clean = text.trim()
          .replaceAll('```json', '').replaceAll('```', '').trim();
      final start = clean.indexOf('{');
      final end = clean.lastIndexOf('}');
      if (start != -1 && end != -1) clean = clean.substring(start, end + 1);
      final data = jsonDecode(clean);
      return List<Map<String, dynamic>>.from(data['questions']);
    } catch (_) {
      return _fallbackQuestions(weekTitle);
    }
  }

  static List<Map<String, dynamic>> _fallbackQuestions(String weekTitle) => [
    {'question': 'Explain the main concepts of $weekTitle in simple terms.', 'type': 'Conceptual', 'difficulty': 'Easy', 'keyPoints': ['Definition', 'Use cases', 'Benefits']},
    {'question': 'What are the most common challenges when working with $weekTitle?', 'type': 'Practical', 'difficulty': 'Medium', 'keyPoints': ['Real challenges', 'Solutions', 'Best practices']},
    {'question': 'How would you explain $weekTitle to a non-technical person?', 'type': 'Communication', 'difficulty': 'Easy', 'keyPoints': ['Simple analogy', 'Clear explanation', 'Practical example']},
    {'question': 'What tools or libraries are commonly used for $weekTitle?', 'type': 'Technical', 'difficulty': 'Medium', 'keyPoints': ['Popular tools', 'When to use each', 'Industry standard']},
    {'question': 'Describe a project where you could apply $weekTitle.', 'type': 'Project', 'difficulty': 'Medium', 'keyPoints': ['Problem statement', 'Solution approach', 'Expected outcome']},
  ];

  // ─── Grade Answer ─────────────────────────────────────────────────

  static Future<Map<String, dynamic>> gradeAnswer({
    required String question,
    required List<String> keyPoints,
    required String answer,
    required String track,
  }) async {
    final prompt =
        'Interview question: "$question". '
        'Key points expected: ${keyPoints.join(", ")}. '
        'Student answer: "$answer". '
        'Grade for a $track fresher role. '
        'Return ONLY valid JSON: {"score":7,"maxScore":10,"feedback":"2-3 sentences","missed":["missed point"],"good":["good point"]} '
        'No markdown. Just JSON.';

    final text = await _callGroq(prompt, temperature: 0.3, maxTokens: 400);
    if (text == null) return {'score': 5, 'maxScore': 10, 'feedback': 'Good attempt! Review the key concepts.', 'missed': [], 'good': ['You attempted the question']};
    try {
      String clean = text.trim()
          .replaceAll('```json', '').replaceAll('```', '').trim();
      final start = clean.indexOf('{');
      final end = clean.lastIndexOf('}');
      if (start != -1 && end != -1) clean = clean.substring(start, end + 1);
      return jsonDecode(clean) as Map<String, dynamic>;
    } catch (_) {
      return {'score': 5, 'maxScore': 10, 'feedback': 'Good attempt! Review key concepts for this topic.', 'missed': [], 'good': ['You attempted the question']};
    }
  }

  // ─── Prompts ─────────────────────────────────────────────────────

  static String _buildRoadmapPrompt(String track, String branch,
      String year, String experience, String hours, String goal) {
    return 'Generate a 12-week learning roadmap for "$track" for Indian engineering students. '
        'Student: $branch, $year, $experience level, $hours/week, goal: $goal. '
        'Return ONLY valid JSON: {"track":"$track","totalWeeks":12,"weeks":[{"weekNumber":1,"title":"topic","skills":["s1","s2","s3"],"why":"reason","estimatedHours":8}]} '
        'No markdown. Just JSON.';
  }

  // ─── Fallback Roadmaps ───────────────────────────────────────────

  static Map<String, dynamic> _fallbackRoadmap(String track) {
    final weeks = _fallbackWeeks[track] ?? _genericWeeks(track);
    return {'track': track, 'totalWeeks': weeks.length, 'weeks': weeks};
  }

  static final Map<String, List<Map<String, dynamic>>> _fallbackWeeks = {
    'Data Scientist': [
      {'weekNumber': 1, 'title': 'Python Basics', 'skills': ['Variables', 'Loops', 'Functions'], 'why': 'Python is the main DS language', 'estimatedHours': 8},
      {'weekNumber': 2, 'title': 'NumPy & Pandas', 'skills': ['Arrays', 'DataFrames', 'Indexing'], 'why': 'Core libraries for data work', 'estimatedHours': 10},
      {'weekNumber': 3, 'title': 'Data Wrangling', 'skills': ['Pandas advanced', 'Missing data', 'EDA'], 'why': 'Real data is always messy', 'estimatedHours': 12},
      {'weekNumber': 4, 'title': 'Statistics', 'skills': ['Probability', 'Distributions', 'Hypothesis testing'], 'why': 'Math behind every ML model', 'estimatedHours': 10},
      {'weekNumber': 5, 'title': 'Data Visualisation', 'skills': ['Matplotlib', 'Seaborn', 'Plotly'], 'why': 'Communicate insights visually', 'estimatedHours': 8},
      {'weekNumber': 6, 'title': 'SQL for Data Science', 'skills': ['Joins', 'Window functions', 'Aggregations'], 'why': 'Every DS job needs SQL', 'estimatedHours': 10},
      {'weekNumber': 7, 'title': 'Machine Learning Basics', 'skills': ['Scikit-learn', 'Regression', 'Classification'], 'why': 'Core of Data Science', 'estimatedHours': 14},
      {'weekNumber': 8, 'title': 'ML Model Evaluation', 'skills': ['Cross validation', 'Metrics', 'Overfitting'], 'why': 'Build models that actually work', 'estimatedHours': 10},
      {'weekNumber': 9, 'title': 'Advanced ML', 'skills': ['Random Forest', 'XGBoost', 'Feature engineering'], 'why': 'Used in most DS projects', 'estimatedHours': 12},
      {'weekNumber': 10, 'title': 'Deep Learning Intro', 'skills': ['Neural networks', 'Keras', 'TensorFlow'], 'why': 'Powers modern AI systems', 'estimatedHours': 12},
      {'weekNumber': 11, 'title': 'End-to-End Project', 'skills': ['Data collection', 'Modelling', 'Deployment'], 'why': 'Show complete DS workflow', 'estimatedHours': 14},
      {'weekNumber': 12, 'title': 'Portfolio & Kaggle', 'skills': ['Kaggle competitions', 'GitHub', 'LinkedIn'], 'why': 'Get noticed by recruiters', 'estimatedHours': 10},
    ],
    'Frontend Developer': [
      {'weekNumber': 1, 'title': 'HTML Fundamentals', 'skills': ['HTML Tags', 'Forms', 'Semantic HTML'], 'why': 'Foundation of every webpage', 'estimatedHours': 8},
      {'weekNumber': 2, 'title': 'CSS Styling', 'skills': ['Selectors', 'Flexbox', 'Grid'], 'why': 'Make websites look good', 'estimatedHours': 10},
      {'weekNumber': 3, 'title': 'JavaScript Basics', 'skills': ['Variables', 'Functions', 'DOM'], 'why': 'Make websites interactive', 'estimatedHours': 12},
      {'weekNumber': 4, 'title': 'JavaScript Advanced', 'skills': ['ES6+', 'Async/Await', 'Fetch API'], 'why': 'Modern JS needed for jobs', 'estimatedHours': 12},
      {'weekNumber': 5, 'title': 'React Fundamentals', 'skills': ['Components', 'Props', 'State'], 'why': 'Most popular frontend framework', 'estimatedHours': 14},
      {'weekNumber': 6, 'title': 'React Hooks', 'skills': ['useState', 'useEffect', 'useContext'], 'why': 'Required for React development', 'estimatedHours': 12},
      {'weekNumber': 7, 'title': 'Tailwind CSS', 'skills': ['Utility classes', 'Responsive design', 'Dark mode'], 'why': 'Fastest way to build UI', 'estimatedHours': 8},
      {'weekNumber': 8, 'title': 'API Integration', 'skills': ['REST APIs', 'Axios', 'Error handling'], 'why': 'Connect frontend to backend', 'estimatedHours': 10},
      {'weekNumber': 9, 'title': 'Testing', 'skills': ['Jest', 'React Testing Library', 'Unit tests'], 'why': 'Required in professional jobs', 'estimatedHours': 10},
      {'weekNumber': 10, 'title': 'Build Tools', 'skills': ['Webpack', 'Vite', 'npm'], 'why': 'Optimize production apps', 'estimatedHours': 8},
      {'weekNumber': 11, 'title': 'Portfolio Project', 'skills': ['Build project', 'Deploy on Vercel', 'GitHub'], 'why': 'Show recruiters your skills', 'estimatedHours': 14},
      {'weekNumber': 12, 'title': 'Interview Prep', 'skills': ['Common questions', 'Problem solving', 'Practice'], 'why': 'Land your first job', 'estimatedHours': 10},
    ],
    'ML Engineer': [
      {'weekNumber': 1, 'title': 'Python & Math', 'skills': ['Python', 'Linear Algebra', 'Calculus'], 'why': 'Math powers every ML model', 'estimatedHours': 10},
      {'weekNumber': 2, 'title': 'ML Foundations', 'skills': ['Scikit-learn', 'Regression', 'Classification'], 'why': 'Core ML algorithms', 'estimatedHours': 12},
      {'weekNumber': 3, 'title': 'Deep Learning', 'skills': ['Neural networks', 'Backpropagation', 'Keras'], 'why': 'Powers modern AI', 'estimatedHours': 14},
      {'weekNumber': 4, 'title': 'PyTorch', 'skills': ['Tensors', 'Autograd', 'Custom models'], 'why': 'Industry standard framework', 'estimatedHours': 14},
      {'weekNumber': 5, 'title': 'Computer Vision', 'skills': ['CNNs', 'Transfer learning', 'OpenCV'], 'why': 'Image AI applications', 'estimatedHours': 12},
      {'weekNumber': 6, 'title': 'NLP', 'skills': ['Text processing', 'Transformers', 'BERT'], 'why': 'Language AI applications', 'estimatedHours': 12},
      {'weekNumber': 7, 'title': 'MLOps Basics', 'skills': ['MLflow', 'Model versioning', 'Experiments'], 'why': 'Manage ML in production', 'estimatedHours': 10},
      {'weekNumber': 8, 'title': 'Model Deployment', 'skills': ['FastAPI', 'Docker', 'REST APIs'], 'why': 'Ship models to production', 'estimatedHours': 12},
      {'weekNumber': 9, 'title': 'Cloud ML', 'skills': ['AWS SageMaker', 'GCP Vertex AI', 'Azure ML'], 'why': 'Scale ML workloads', 'estimatedHours': 12},
      {'weekNumber': 10, 'title': 'LLMs & Fine-tuning', 'skills': ['Hugging Face', 'Fine-tuning', 'RLHF'], 'why': 'Latest AI technology', 'estimatedHours': 14},
      {'weekNumber': 11, 'title': 'ML System Design', 'skills': ['Architecture', 'Scaling', 'Monitoring'], 'why': 'Senior ML engineer skills', 'estimatedHours': 10},
      {'weekNumber': 12, 'title': 'Capstone Project', 'skills': ['End-to-end ML', 'GitHub', 'Deploy'], 'why': 'Impress interviewers', 'estimatedHours': 16},
    ],
    'Data Engineer': [
      {'weekNumber': 1, 'title': 'Python & SQL Basics', 'skills': ['Python', 'SQL', 'Linux basics'], 'why': 'Foundation for all DE work', 'estimatedHours': 10},
      {'weekNumber': 2, 'title': 'Databases', 'skills': ['PostgreSQL', 'MySQL', 'Database design'], 'why': 'Core of data engineering', 'estimatedHours': 12},
      {'weekNumber': 3, 'title': 'Data Modelling', 'skills': ['Star schema', 'Dimensional modelling', 'ERD'], 'why': 'Design efficient data stores', 'estimatedHours': 10},
      {'weekNumber': 4, 'title': 'ETL Pipelines', 'skills': ['Extract', 'Transform', 'Load'], 'why': 'Core DE job function', 'estimatedHours': 12},
      {'weekNumber': 5, 'title': 'Apache Spark', 'skills': ['RDDs', 'DataFrames', 'PySpark'], 'why': 'Process big data at scale', 'estimatedHours': 14},
      {'weekNumber': 6, 'title': 'Apache Kafka', 'skills': ['Topics', 'Producers', 'Consumers'], 'why': 'Real-time data streaming', 'estimatedHours': 12},
      {'weekNumber': 7, 'title': 'Apache Airflow', 'skills': ['DAGs', 'Operators', 'Scheduling'], 'why': 'Orchestrate data pipelines', 'estimatedHours': 12},
      {'weekNumber': 8, 'title': 'Cloud Platforms', 'skills': ['AWS S3', 'GCP BigQuery', 'Azure'], 'why': 'All DE jobs use cloud', 'estimatedHours': 12},
      {'weekNumber': 9, 'title': 'dbt', 'skills': ['Models', 'Tests', 'Documentation'], 'why': 'Modern data transformation', 'estimatedHours': 10},
      {'weekNumber': 10, 'title': 'Docker & Kubernetes', 'skills': ['Containers', 'Docker Compose', 'K8s basics'], 'why': 'Deploy pipelines in production', 'estimatedHours': 12},
      {'weekNumber': 11, 'title': 'Data Warehouse', 'skills': ['Snowflake', 'Redshift', 'BigQuery'], 'why': 'Where processed data lives', 'estimatedHours': 10},
      {'weekNumber': 12, 'title': 'Capstone Project', 'skills': ['End-to-end pipeline', 'GitHub', 'Documentation'], 'why': 'Prove your skills to employers', 'estimatedHours': 16},
    ],
    'DevOps Engineer': [
      {'weekNumber': 1, 'title': 'Linux Fundamentals', 'skills': ['Commands', 'File system', 'Shell scripting'], 'why': 'All servers run Linux', 'estimatedHours': 10},
      {'weekNumber': 2, 'title': 'Networking Basics', 'skills': ['TCP/IP', 'DNS', 'HTTP/HTTPS'], 'why': 'Understand server communication', 'estimatedHours': 8},
      {'weekNumber': 3, 'title': 'Git & GitHub', 'skills': ['Branching', 'PRs', 'Git workflows'], 'why': 'Foundation of DevOps', 'estimatedHours': 8},
      {'weekNumber': 4, 'title': 'Docker', 'skills': ['Containers', 'Dockerfile', 'Docker Compose'], 'why': 'Package apps consistently', 'estimatedHours': 12},
      {'weekNumber': 5, 'title': 'Kubernetes', 'skills': ['Pods', 'Services', 'Deployments'], 'why': 'Orchestrate containers at scale', 'estimatedHours': 14},
      {'weekNumber': 6, 'title': 'CI/CD Pipelines', 'skills': ['GitHub Actions', 'Jenkins', 'Pipelines'], 'why': 'Automate deployments', 'estimatedHours': 12},
      {'weekNumber': 7, 'title': 'AWS Basics', 'skills': ['EC2', 'S3', 'IAM'], 'why': 'Most used cloud platform', 'estimatedHours': 12},
      {'weekNumber': 8, 'title': 'Infrastructure as Code', 'skills': ['Terraform', 'Ansible', 'CloudFormation'], 'why': 'Automate infrastructure', 'estimatedHours': 12},
      {'weekNumber': 9, 'title': 'Monitoring', 'skills': ['Prometheus', 'Grafana', 'ELK Stack'], 'why': 'Know when things break', 'estimatedHours': 10},
      {'weekNumber': 10, 'title': 'Security', 'skills': ['SSL/TLS', 'Secrets management', 'RBAC'], 'why': 'Secure production systems', 'estimatedHours': 10},
      {'weekNumber': 11, 'title': 'Site Reliability', 'skills': ['SLOs', 'Error budgets', 'Incident response'], 'why': 'Keep systems running', 'estimatedHours': 10},
      {'weekNumber': 12, 'title': 'Capstone Project', 'skills': ['Full pipeline', 'Documentation', 'GitHub'], 'why': 'Prove DevOps skills', 'estimatedHours': 14},
    ],
  };

  static List<Map<String, dynamic>> _genericWeeks(String track) => [
    {'weekNumber': 1, 'title': 'Fundamentals of $track', 'skills': ['Basics', 'Setup', 'Core concepts'], 'why': 'Build the foundation', 'estimatedHours': 8},
    {'weekNumber': 2, 'title': 'Core Tools', 'skills': ['Primary tools', 'Environment setup', 'Best practices'], 'why': 'Learn the tools of the trade', 'estimatedHours': 10},
    {'weekNumber': 3, 'title': 'Intermediate Concepts', 'skills': ['Intermediate topic 1', 'Intermediate topic 2', 'Practice'], 'why': 'Level up your skills', 'estimatedHours': 12},
    {'weekNumber': 4, 'title': 'Practical Application', 'skills': ['Real-world usage', 'Projects', 'Problem solving'], 'why': 'Apply what you learned', 'estimatedHours': 12},
    {'weekNumber': 5, 'title': 'Advanced Topics', 'skills': ['Advanced concept 1', 'Advanced concept 2', 'Deep dive'], 'why': 'Reach professional level', 'estimatedHours': 14},
    {'weekNumber': 6, 'title': 'Industry Standards', 'skills': ['Best practices', 'Code quality', 'Standards'], 'why': 'Work like a professional', 'estimatedHours': 10},
    {'weekNumber': 7, 'title': 'Project Work', 'skills': ['Build project', 'Problem solving', 'Implementation'], 'why': 'Portfolio for interviews', 'estimatedHours': 14},
    {'weekNumber': 8, 'title': 'Interview Preparation', 'skills': ['Common questions', 'Problem solving', 'Practice'], 'why': 'Land your dream job', 'estimatedHours': 12},
  ];
}
