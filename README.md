<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=8B53EC&height=200&section=header&text=PathForge&fontSize=80&fontColor=ffffff&animation=fadeIn&fontAlignY=35&desc=AI-Powered%20Career%20Roadmap%20for%20Engineering%20Students&descAlignY=55&descSize=18" width="100%"/>

<br/>

[![Flutter](https://img.shields.io/badge/Flutter-3.41.9-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11.5-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Gemini AI](https://img.shields.io/badge/Gemini_AI-2.0_Flash-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://aistudio.google.com)
[![License](https://img.shields.io/badge/License-MIT-8B53EC?style=for-the-badge)](LICENSE)

<br/>

> **🎓 Final Year Engineering Project** | Built by [Sneha Choudhary](https://github.com/Snehachoudhary26)

<br/>

[📱 Download APK](#-download) • [🚀 Features](#-features) • [🛠 Tech Stack](#-tech-stack) • [📸 Screenshots](#-screenshots) • [🗺 Roadmap Tracks](#-available-tracks) • [⚡ Quick Start](#-quick-start)

</div>

---

## 🌟 What is PathForge?

> **Most engineering students don't know where to start.** Which language? Which framework? Which job role? PathForge solves this — it asks you 5 questions and **Gemini AI generates a personalised week-by-week roadmap** for your chosen tech career.

PathForge is a **Flutter-based Android/iOS/Web app** that helps engineering students navigate their tech career by providing:

- 🤖 **AI-generated personalised roadmaps** using Google Gemini 2.0
- 📊 **25 career tracks** across Data, Development, DevOps, Security, Design & Emerging Tech
- 🔐 **Real authentication** with Firebase Auth
- 💾 **Cloud data storage** with Cloud Firestore
- 📚 **Curated YouTube resources** from top Indian & Global educators
- 🔥 **Progress tracking** with streak system

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 🎯 Core Features
- ✅ AI-powered roadmap generation (Gemini 2.0)
- ✅ 25 career tracks across 6 categories
- ✅ Personalised 12-week study plans
- ✅ Week-by-week skill breakdown
- ✅ Progress tracking per week
- ✅ Firebase Authentication
- ✅ Cloud Firestore data persistence

</td>
<td width="50%">

### 🚀 User Experience
- ✅ Beautiful purple & white UI
- ✅ Smooth animations (flutter_animate)
- ✅ 5-question onboarding quiz
- ✅ Bottom navigation
- ✅ Week detail bottom sheets
- ✅ Curated YouTube resources
- ✅ Cross-platform (Android + iOS + Web)

</td>
</tr>
</table>

---

## 🗺 Available Tracks

<table>
<tr>
<th>📊 Data & AI</th>
<th>🖥️ Development</th>
<th>☁️ DevOps & Cloud</th>
</tr>
<tr>
<td>

- 📊 Data Scientist
- 📈 Data Analyst
- 🔧 Data Engineer
- 🤖 ML Engineer
- 🧠 AI Engineer
- 💬 NLP Engineer
- 👁️ Computer Vision
- ✍️ Prompt Engineer

</td>
<td>

- 🎨 Frontend Developer
- ⚙️ Backend Developer
- 💻 Full Stack Developer
- 📱 Mobile App Developer
- 🛠️ Software Engineer
- 🎮 Game Developer
- ⛓️ Blockchain Developer

</td>
<td>

- 🔄 DevOps Engineer
- ☁️ Cloud Engineer
- 📡 Site Reliability Engineer
- 🗄️ Database Administrator
- 🔌 Embedded Systems
- 🔒 Cybersecurity Engineer
- 🧪 QA Test Engineer
- 🎨 UI/UX Designer

</td>
</tr>
</table>

---

## 🛠 Tech Stack

<div align="center">

| Category | Technology | Purpose |
|----------|-----------|---------|
| **Frontend** | ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white) Flutter + Dart | Cross-platform mobile & web app |
| **AI/LLM** | ![Google](https://img.shields.io/badge/Gemini_2.0-4285F4?style=flat-square&logo=google&logoColor=white) Gemini API | Roadmap generation |
| **Auth** | ![Firebase](https://img.shields.io/badge/Firebase_Auth-FFCA28?style=flat-square&logo=firebase&logoColor=black) Firebase Auth | Email + Google login |
| **Database** | ![Firestore](https://img.shields.io/badge/Firestore-FF6F00?style=flat-square&logo=firebase&logoColor=white) Cloud Firestore | User data & roadmaps |
| **State** | ![Riverpod](https://img.shields.io/badge/Riverpod-0175C2?style=flat-square&logo=dart&logoColor=white) Flutter Riverpod | State management |
| **Navigation** | GoRouter | App routing |
| **Animations** | flutter_animate | Smooth UI transitions |
| **Version Control** | ![GitHub](https://img.shields.io/badge/GitHub-181717?style=flat-square&logo=github&logoColor=white) Git + GitHub | Source control |

</div>

---

## 📦 Flutter Packages Used

```yaml
dependencies:
  go_router: ^13.0.0          # Navigation & routing
  flutter_riverpod: ^2.5.1    # State management
  firebase_core: ^2.27.0      # Firebase initialization
  firebase_auth: ^4.17.0      # Authentication
  cloud_firestore: ^4.15.0    # Database
  http: ^1.2.0                # Gemini API calls
  flutter_animate: ^4.5.0     # Animations
  google_fonts: ^6.2.1        # Poppins font
  url_launcher: ^6.2.5        # Open YouTube links
  percent_indicator: ^4.2.3   # Progress indicators
  shimmer: ^3.0.0             # Loading skeletons
  lottie: ^3.1.0              # Animated illustrations
```

---

## 📱 App Flow

```
Splash Screen
     │
     ├── New User ──→ Auth Screen ──→ Onboarding Quiz (5 Qs) ──→ Track Select ──→ AI Generating ──→ Roadmap
     │
     └── Returning User ──→ Home Dashboard ──→ Roadmap / Resources / Profile
```

---

## 🎓 YouTube Resources Included

### 🇮🇳 Indian Creators
| Channel | Topics | Language |
|---------|--------|----------|
| [CodeWithHarry](https://www.youtube.com/@CodeWithHarry) | Python, Java, JS, C++, Web Dev | Hindi |
| [Krish Naik](https://www.youtube.com/@krishnaik06) | ML, Deep Learning, Data Science | Hindi/English |
| [CampusX](https://www.youtube.com/@campusx-official) | 100 Days ML, Data Science | Hindi |
| [Apna College](https://www.youtube.com/@ApnaCollegeOfficial) | DSA, Python, Placement | Hindi |
| [Kunal Kushwaha](https://www.youtube.com/@KunalKushwaha) | DSA, Java, DevOps | English |
| [Striver (take U forward)](https://www.youtube.com/@takeUforward) | DSA, Coding Interviews | English |

### 🌍 Global Creators
| Channel | Topics | Language |
|---------|--------|----------|
| [3Blue1Brown](https://www.youtube.com/@3blue1brown) | Math for ML, Linear Algebra | English |
| [Andrej Karpathy](https://www.youtube.com/@AndrejKarpathy) | AI/LLM, Build GPT | English |
| [Ken Jee](https://www.youtube.com/@KenJee_ds) | Data Science Career | English |
| [Sentdex](https://www.youtube.com/@sentdex) | Python, ML Projects | English |

---

## ⚡ Quick Start

### Prerequisites
- Flutter SDK 3.41.9+
- Dart 3.11.5+
- Android Studio / VS Code
- Firebase account
- Gemini API key (free at [aistudio.google.com](https://aistudio.google.com))

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/Snehachoudhary26/pathforge.git

# 2. Navigate to project
cd pathforge/PathForge

# 3. Install dependencies
flutter pub get

# 4. Add your Gemini API key in
# lib/services/gemini_service.dart
# Replace 'YOUR_API_KEY_HERE' with your key

# 5. Setup Firebase
# Add your google-services.json to android/app/
# Run: flutterfire configure

# 6. Run the app
flutter run
```

---

## 🏗 Project Structure

```
lib/
├── core/
│   ├── theme.dart          # App colors & typography
│   └── router.dart         # GoRouter navigation
├── models/
│   └── roadmap_model.dart  # Data models
├── screens/
│   ├── splash_screen.dart
│   ├── auth_screen.dart
│   ├── home_screen.dart
│   ├── onboarding_screen.dart
│   ├── track_select_screen.dart
│   ├── generating_screen.dart
│   ├── roadmap_screen.dart
│   ├── resources_screen.dart
│   └── profile_screen.dart
├── services/
│   ├── auth_service.dart       # Firebase Auth
│   ├── firestore_service.dart  # Firestore CRUD
│   └── gemini_service.dart     # Gemini AI API
└── widgets/
    └── (reusable components)
```

---

## 🔥 Why PathForge?

| Problem | Solution |
|---------|----------|
| Students don't know which language to learn | AI analyses their profile & recommends the right track |
| No structured learning path | Week-by-week roadmap with specific skills per week |
| Don't know which YouTube channels to follow | Curated list of best Indian & global educators per topic |
| Can't track their progress | Real-time progress tracking with Firestore |
| Confused about career options | 25 detailed career tracks with salary & demand info |

---

## 📊 Career Tracks Stats

```
Total Tracks    : 25
Categories      : 6
Avg Duration    : 16 weeks
Salary Range    : ₹5 LPA → ₹35 LPA
YouTube Channels: 20+ curated
```

---

## 🚧 Roadmap (Future Plans)

- [ ] 🤖 AI Mentor Chat (in-app Q&A with Gemini)
- [ ] 🏆 Gamification (XP points, badges, leaderboard)
- [ ] 📤 Share roadmap progress to LinkedIn
- [ ] 🔔 Daily study reminders
- [ ] 📝 Resume gap analyser
- [ ] 🌙 Dark mode
- [ ] 👥 Community features

---

## 👩‍💻 Developer

<div align="center">

**Sneha Choudhary**

[![GitHub](https://img.shields.io/badge/GitHub-Snehachoudhary26-181717?style=for-the-badge&logo=github)](https://github.com/Snehachoudhary26)

*Final Year Engineering Student | Flutter Developer | AI Enthusiast*

*Built PathForge because I was that confused 2nd-year student who didn't know where to start — and I built the tool I wished existed.*

</div>

---

## 📄 License

This project is licensed under the MIT License.

---

<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=8B53EC&height=100&section=footer" width="100%"/>

**⭐ Star this repo if PathForge helped you!**

Made with ❤️ for every confused engineering student in India

</div>
