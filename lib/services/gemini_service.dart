import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = 'AIzaSyDW_aqQiooSHQwaZ-8qpDgwDV1epuM3Rtw';
  static const String _url =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  static Future<Map<String, dynamic>?> generateRoadmap({
    required String track,
    required String branch,
    required String year,
    required String experience,
    required String hours,
    required String goal,
  }) async {
    print('🚀 Starting Gemini call for: $track');

    try {
      final uri = Uri.parse('$_url?key=$_apiKey');
      final prompt = _buildPrompt(track);

      print('📡 Sending request to Gemini...');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [{'text': prompt}]
            }
          ],
          'generationConfig': {
            'temperature': 0.5,
            'maxOutputTokens': 2000,
            'responseMimeType': 'application/json',
          }
        }),
      );

      print('📬 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final text = json['candidates'][0]['content']['parts'][0]['text'] as String;
        print('📝 Got text length: ${text.length}');
        print('📝 First 100 chars: ${text.substring(0, text.length > 100 ? 100 : text.length)}');

        String clean = text.trim()
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final start = clean.indexOf('{');
        final end = clean.lastIndexOf('}');
        if (start != -1 && end != -1) {
          clean = clean.substring(start, end + 1);
        }

        final result = jsonDecode(clean) as Map<String, dynamic>;
        final weekCount = (result['weeks'] as List?)?.length ?? 0;
        print('✅ Success! Got $weekCount weeks for $track');
        return result;

      } else {
        print('❌ HTTP Error ${response.statusCode}: ${response.body.substring(0, response.body.length > 300 ? 300 : response.body.length)}');
        print('🔄 Using fallback roadmap...');
        return _fallbackRoadmap(track);
      }
    } catch (e) {
      print('❌ Exception: $e');
      print('🔄 Using fallback roadmap...');
      return _fallbackRoadmap(track);
    }
  }

  static String _buildPrompt(String track) {
    return '''Generate a 12-week learning roadmap for "$track" for Indian engineering students.
Return ONLY valid JSON in this exact format:
{
  "track": "$track",
  "totalWeeks": 12,
  "weeks": [
    {
      "weekNumber": 1,
      "title": "specific topic name",
      "skills": ["skill1", "skill2", "skill3"],
      "why": "why this week matters",
      "estimatedHours": 8
    }
  ]
}
Make content specific to $track. No markdown. No explanation. Just JSON.''';
  }

  static Map<String, dynamic> _fallbackRoadmap(String track) {
    print('📋 Generating fallback roadmap for: $track');

    final roadmaps = {
      'Frontend Developer': [
        {'weekNumber': 1, 'title': 'HTML Fundamentals', 'skills': ['HTML Tags', 'Forms', 'Semantic HTML'], 'why': 'Foundation of every webpage', 'estimatedHours': 8},
        {'weekNumber': 2, 'title': 'CSS Styling', 'skills': ['Selectors', 'Flexbox', 'Grid'], 'why': 'Make websites look good', 'estimatedHours': 10},
        {'weekNumber': 3, 'title': 'JavaScript Basics', 'skills': ['Variables', 'Functions', 'DOM'], 'why': 'Make websites interactive', 'estimatedHours': 12},
        {'weekNumber': 4, 'title': 'JavaScript Advanced', 'skills': ['ES6+', 'Async/Await', 'Fetch API'], 'why': 'Modern JS needed for jobs', 'estimatedHours': 12},
        {'weekNumber': 5, 'title': 'React Fundamentals', 'skills': ['Components', 'Props', 'State'], 'why': 'Most popular frontend framework', 'estimatedHours': 14},
        {'weekNumber': 6, 'title': 'React Hooks', 'skills': ['useState', 'useEffect', 'useContext'], 'why': 'Required for React development', 'estimatedHours': 12},
        {'weekNumber': 7, 'title': 'Tailwind CSS', 'skills': ['Utility classes', 'Responsive design', 'Dark mode'], 'why': 'Fastest way to build UI', 'estimatedHours': 8},
        {'weekNumber': 8, 'title': 'React Router & State', 'skills': ['React Router', 'Redux basics', 'Context API'], 'why': 'Build multi-page apps', 'estimatedHours': 12},
        {'weekNumber': 9, 'title': 'API Integration', 'skills': ['REST APIs', 'Axios', 'Error handling'], 'why': 'Connect frontend to backend', 'estimatedHours': 10},
        {'weekNumber': 10, 'title': 'Testing', 'skills': ['Jest', 'React Testing Library', 'Unit tests'], 'why': 'Required in professional jobs', 'estimatedHours': 10},
        {'weekNumber': 11, 'title': 'Build Tools', 'skills': ['Webpack', 'Vite', 'npm'], 'why': 'Optimize production apps', 'estimatedHours': 8},
        {'weekNumber': 12, 'title': 'Portfolio Project', 'skills': ['Build project', 'Deploy on Vercel', 'GitHub'], 'why': 'Show recruiters your skills', 'estimatedHours': 14},
      ],
      'Data Scientist': [
        {'weekNumber': 1, 'title': 'Python Basics', 'skills': ['Variables', 'Loops', 'Functions'], 'why': 'Python is the main DS language', 'estimatedHours': 8},
        {'weekNumber': 2, 'title': 'Python OOP & Libraries', 'skills': ['Classes', 'NumPy', 'Pandas'], 'why': 'Core libraries for data work', 'estimatedHours': 10},
        {'weekNumber': 3, 'title': 'Data Wrangling', 'skills': ['Pandas advanced', 'Missing data', 'EDA'], 'why': 'Real data is always messy', 'estimatedHours': 12},
        {'weekNumber': 4, 'title': 'Statistics', 'skills': ['Probability', 'Distributions', 'Hypothesis testing'], 'why': 'Math behind every ML model', 'estimatedHours': 10},
        {'weekNumber': 5, 'title': 'Data Visualisation', 'skills': ['Matplotlib', 'Seaborn', 'Plotly'], 'why': 'Communicate insights visually', 'estimatedHours': 8},
        {'weekNumber': 6, 'title': 'SQL for Data Science', 'skills': ['Joins', 'Window functions', 'Aggregations'], 'why': 'Every DS job needs SQL', 'estimatedHours': 10},
        {'weekNumber': 7, 'title': 'Machine Learning Basics', 'skills': ['Scikit-learn', 'Linear regression', 'Classification'], 'why': 'Core of Data Science', 'estimatedHours': 14},
        {'weekNumber': 8, 'title': 'ML Model Evaluation', 'skills': ['Cross validation', 'Metrics', 'Overfitting'], 'why': 'Build models that actually work', 'estimatedHours': 10},
        {'weekNumber': 9, 'title': 'Advanced ML', 'skills': ['Random Forest', 'XGBoost', 'Feature engineering'], 'why': 'Used in most DS projects', 'estimatedHours': 12},
        {'weekNumber': 10, 'title': 'Deep Learning Intro', 'skills': ['Neural networks', 'Keras', 'TensorFlow'], 'why': 'Powers modern AI systems', 'estimatedHours': 12},
        {'weekNumber': 11, 'title': 'End-to-End Project', 'skills': ['Data collection', 'Modelling', 'Deployment'], 'why': 'Show complete DS workflow', 'estimatedHours': 14},
        {'weekNumber': 12, 'title': 'Portfolio & Kaggle', 'skills': ['Kaggle competitions', 'GitHub', 'LinkedIn'], 'why': 'Get noticed by recruiters', 'estimatedHours': 10},
      ],
      'Data Analyst': [
        {'weekNumber': 1, 'title': 'Excel Fundamentals', 'skills': ['Formulas', 'PivotTables', 'Charts'], 'why': 'Most used tool in analytics', 'estimatedHours': 8},
        {'weekNumber': 2, 'title': 'Advanced Excel', 'skills': ['VLOOKUP', 'Power Query', 'Macros'], 'why': 'Advanced analytics in Excel', 'estimatedHours': 10},
        {'weekNumber': 3, 'title': 'SQL Basics', 'skills': ['SELECT', 'WHERE', 'JOIN'], 'why': 'Query databases directly', 'estimatedHours': 10},
        {'weekNumber': 4, 'title': 'SQL Advanced', 'skills': ['Window functions', 'CTEs', 'Subqueries'], 'why': 'Required for analyst jobs', 'estimatedHours': 12},
        {'weekNumber': 5, 'title': 'Python for Analysis', 'skills': ['Pandas', 'NumPy', 'Data cleaning'], 'why': 'Automate repetitive analysis', 'estimatedHours': 12},
        {'weekNumber': 6, 'title': 'Data Visualisation', 'skills': ['Matplotlib', 'Seaborn', 'Plotly'], 'why': 'Tell stories with data', 'estimatedHours': 10},
        {'weekNumber': 7, 'title': 'Power BI', 'skills': ['DAX', 'Dashboards', 'Reports'], 'why': 'Most in-demand BI tool in India', 'estimatedHours': 12},
        {'weekNumber': 8, 'title': 'Tableau', 'skills': ['Charts', 'Filters', 'Calculated fields'], 'why': 'Required in many analyst jobs', 'estimatedHours': 10},
        {'weekNumber': 9, 'title': 'Statistics for Analysts', 'skills': ['Descriptive stats', 'Correlation', 'A/B testing'], 'why': 'Make data-driven decisions', 'estimatedHours': 10},
        {'weekNumber': 10, 'title': 'Business Intelligence', 'skills': ['KPIs', 'Metrics', 'Business context'], 'why': 'Understand what data means', 'estimatedHours': 8},
        {'weekNumber': 11, 'title': 'Real Project', 'skills': ['End-to-end analysis', 'Storytelling', 'Presentation'], 'why': 'Portfolio for interviews', 'estimatedHours': 14},
        {'weekNumber': 12, 'title': 'Job Preparation', 'skills': ['Resume', 'Case studies', 'Interview prep'], 'why': 'Land your first analyst job', 'estimatedHours': 10},
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

    // Get specific roadmap or generate generic one
    final weeks = roadmaps[track] ?? _generateGenericRoadmap(track);

    return {
      'track': track,
      'totalWeeks': weeks.length,
      'weeks': weeks,
    };
  }

  static List<Map<String, dynamic>> _generateGenericRoadmap(
      String track) {
    return [
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
}
