import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // ─── User Profile ───────────────────────────────────────────────

  static Future<void> saveUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  // ─── Roadmap ─────────────────────────────────────────────────────

  static String _safeTrackId(String track) =>
      track.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]'), '_');

  static Future<void> saveRoadmap({
    required String uid,
    required Map<String, dynamic> roadmap,
  }) async {
    final track = roadmap['track']?.toString() ?? 'unknown';
    final trackId = _safeTrackId(track);
    await _db.collection('roadmaps').doc('${uid}_$trackId').set({
      ...roadmap,
      'uid': uid,
      'trackId': trackId,
      'savedAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<Map<String, dynamic>?> getRoadmapForTrack({
    required String uid,
    required String track,
  }) async {
    final trackId = _safeTrackId(track);
    final doc = await _db.collection('roadmaps').doc('${uid}_$trackId').get();
    return doc.exists ? doc.data() : null;
  }

  static Future<Map<String, dynamic>?> getRoadmap(String uid) async {
    final doc = await _db.collection('roadmaps').doc(uid).get();
    return doc.data();
  }

  // ─── XP System ───────────────────────────────────────────────────

  static Future<Map<String, dynamic>> addXP({
    required String uid,
    int xpToAdd = 80,
  }) async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    final currentXP = (data['xp'] ?? 0) as int;
    final newXP = currentXP + xpToAdd;
    final newLevel = _calculateLevel(newXP);
    final oldLevel = _calculateLevel(currentXP);
    final leveledUp = newLevel > oldLevel;
    await _db.collection('users').doc(uid).set({
      'xp': newXP,
      'level': newLevel,
      'levelName': _levelName(newLevel),
    }, SetOptions(merge: true));
    return {
      'newXP': newXP,
      'newLevel': newLevel,
      'levelName': _levelName(newLevel),
      'leveledUp': leveledUp,
      'xpToNextLevel': _xpForNextLevel(newLevel),
    };
  }

  static Future<void> removeXP({
    required String uid,
    int xpToRemove = 80,
  }) async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    final currentXP = (data['xp'] ?? 0) as int;
    final newXP = (currentXP - xpToRemove).clamp(0, 999999);
    final newLevel = _calculateLevel(newXP);
    await _db.collection('users').doc(uid).set({
      'xp': newXP,
      'level': newLevel,
      'levelName': _levelName(newLevel),
    }, SetOptions(merge: true));
  }

  static int _calculateLevel(int xp) => (xp ~/ 500) + 1;
  static int _xpForNextLevel(int level) => level * 500;

  static String _levelName(int level) {
    const names = [
      'Code Newcomer', 'Code Apprentice', 'Algorithm Learner',
      'Data Explorer', 'Logic Builder', 'Script Warrior',
      'Code Craftsman', 'Tech Specialist', 'Senior Engineer',
      'Code Master', 'Tech Legend',
    ];
    return names[(level - 1).clamp(0, names.length - 1)];
  }

  // ─── Streak System ───────────────────────────────────────────────

  static Future<int> updateStreak({required String uid}) async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    final today = _dateKey(DateTime.now());
    final lastActive = data['lastActiveDate'] as String? ?? '';
    final currentStreak = (data['streak'] ?? 0) as int;
    if (lastActive == today) return currentStreak;
    final yesterday = _dateKey(
        DateTime.now().subtract(const Duration(days: 1)));
    final newStreak = lastActive == yesterday ? currentStreak + 1 : 1;
    await _db.collection('users').doc(uid).set({
      'lastActiveDate': today,
      'streak': newStreak,
    }, SetOptions(merge: true));
    return newStreak;
  }

  static Future<List<bool>> getWeekActivity({required String uid}) async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    final activeDates = List<String>.from(data['activeDates'] ?? []);
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) {
      final day = startOfWeek.add(Duration(days: i));
      return activeDates.contains(_dateKey(day));
    });
  }

  static Future<void> logActiveDay({required String uid}) async {
    final today = _dateKey(DateTime.now());
    await _db.collection('users').doc(uid).set({
      'activeDates': FieldValue.arrayUnion([today]),
    }, SetOptions(merge: true));
  }

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  // ─── Leaderboard ─────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getLeaderboard({
    required String currentUid,
    int topN = 10,
  }) async {
    final snap = await _db
        .collection('users')
        .orderBy('xp', descending: true)
        .limit(topN)
        .get();

    final topUsers = snap.docs.map((doc) => {
      'uid': doc.id,
      'name': doc.data()['name'] ?? 'Anonymous',
      'xp': doc.data()['xp'] ?? 0,
      'level': doc.data()['level'] ?? 1,
      'track': doc.data()['track'] ?? '',
    }).toList();

    int currentUserRank = -1;
    Map<String, dynamic>? currentUserData;

    for (int i = 0; i < topUsers.length; i++) {
      if (topUsers[i]['uid'] == currentUid) {
        currentUserRank = i + 1;
        currentUserData = topUsers[i];
        break;
      }
    }

    if (currentUserRank == -1) {
      final userDoc = await _db.collection('users').doc(currentUid).get();
      final userData = userDoc.data() ?? {};
      final userXP = (userData['xp'] ?? 0) as int;
      try {
        final countSnap = await _db
            .collection('users')
            .where('xp', isGreaterThan: userXP)
            .count()
            .get();
        currentUserRank = (countSnap.count ?? 0) + 1;
      } catch (_) {
        currentUserRank = topUsers.length + 1;
      }
      currentUserData = {
        'uid': currentUid,
        'name': userData['name'] ?? 'You',
        'xp': userXP,
        'level': userData['level'] ?? 1,
        'track': userData['track'] ?? '',
      };
    }

    return {
      'topUsers': topUsers,
      'currentUserRank': currentUserRank,
      'currentUser': currentUserData,
    };
  }

  // ─── Job Readiness Score ─────────────────────────────────────────

  static Future<Map<String, dynamic>> calculateJobReadiness({
    required String uid,
  }) async {
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};

      final roadmapSnap = await _db
          .collection('roadmaps')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      int progressPoints = 0;
      int skillsPoints = 0;
      int totalWeeks = 0;
      int doneWeeks = 0;
      String currentSkill = '';
      String track = '';

      if (roadmapSnap.docs.isNotEmpty) {
        final roadmap = roadmapSnap.docs.first.data();
        track = roadmap['track'] ?? '';
        final weeks = roadmap['weeks'] as List? ?? [];
        totalWeeks = weeks.length;
        doneWeeks =
            weeks.where((w) => w['status'] == 'done').length;

        progressPoints = totalWeeks > 0
            ? ((doneWeeks / totalWeeks) * 40).round()
            : 0;

        final totalSkills = weeks.fold<int>(
            0,
            (sum, w) =>
                sum + ((w['skills'] as List?)?.length ?? 0));
        final doneSkills = weeks
            .where((w) => w['status'] == 'done')
            .fold<int>(
                0,
                (sum, w) =>
                    sum + ((w['skills'] as List?)?.length ?? 0));
        skillsPoints = totalSkills > 0
            ? ((doneSkills / totalSkills) * 20).round()
            : 0;

        final currentWeek = weeks.firstWhere(
            (w) => w['status'] != 'done',
            orElse: () => {});
        currentSkill = currentWeek['title'] ?? '';
      }

      final streak = (userData['streak'] ?? 0) as int;
      final streakPoints =
          ((streak / 30) * 20).clamp(0, 20).round();

      final xp = (userData['xp'] ?? 0) as int;
      final xpPoints = ((xp / 2000) * 20).clamp(0, 20).round();

      final totalScore =
          (progressPoints + streakPoints + xpPoints + skillsPoints)
              .clamp(0, 100);

      String label;
      String advice;
      if (totalScore >= 80) {
        label = 'Interview Ready';
        advice =
            'You are ready to apply for $track roles. Start sending applications!';
      } else if (totalScore >= 60) {
        label = 'Almost There';
        advice =
            'Complete ${totalWeeks - doneWeeks} more weeks to be fully interview-ready.';
      } else if (totalScore >= 40) {
        label = 'Making Progress';
        advice =
            'Keep your daily streak going — consistency is the fastest path to job-ready.';
      } else if (totalScore >= 20) {
        label = 'Just Starting';
        advice =
            'Complete your first 3 weeks to unlock your first skill badges.';
      } else {
        label = 'Getting Started';
        advice =
            'Generate your roadmap and complete Week 1 to start your score.';
      }

      await _db.collection('users').doc(uid).set({
        'jobReadinessScore': totalScore,
        'jobReadinessLabel': label,
        'lastScoreUpdate': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      return {
        'score': totalScore,
        'label': label,
        'advice': advice,
        'breakdown': {
          'progress': progressPoints,
          'streak': streakPoints,
          'xp': xpPoints,
          'skills': skillsPoints,
        },
        'track': track,
        'doneWeeks': doneWeeks,
        'totalWeeks': totalWeeks,
        'currentSkill': currentSkill,
      };
    } catch (e) {
      return {
        'score': 0,
        'label': 'Getting Started',
        'advice':
            'Complete your profile and generate a roadmap to get your score.',
        'breakdown': {
          'progress': 0,
          'streak': 0,
          'xp': 0,
          'skills': 0,
        },
        'track': '',
        'doneWeeks': 0,
        'totalWeeks': 0,
        'currentSkill': '',
      };
    }
  }
}
