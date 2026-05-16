import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> saveUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _db.collection('users').doc(uid).set(
      data, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> getUserProfile(
      String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  static String _safeTrackId(String track) {
    return track
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_');
  }

  static Future<void> saveRoadmap({
    required String uid,
    required Map<String, dynamic> roadmap,
  }) async {
    final track = roadmap['track']?.toString() ?? 'unknown';
    final trackId = _safeTrackId(track);
    print('💾 Saving roadmap for uid=$uid track=$track trackId=$trackId');
    
    // Simple flat save — no subcollection
    await _db.collection('roadmaps').doc('${uid}_$trackId').set({
      ...roadmap,
      'uid': uid,
      'trackId': trackId,
      'savedAt': DateTime.now().toIso8601String(),
    });
    print('✅ Roadmap saved at roadmaps/${uid}_$trackId');
  }

  static Future<Map<String, dynamic>?> getRoadmapForTrack({
    required String uid,
    required String track,
  }) async {
    final trackId = _safeTrackId(track);
    print('🔍 Loading roadmap for uid=$uid track=$track trackId=$trackId');
    
    final doc = await _db
        .collection('roadmaps')
        .doc('${uid}_$trackId')
        .get();
    
    print('📄 Document exists: ${doc.exists}');
    if (doc.exists) {
      print('📄 Data keys: ${doc.data()?.keys.toList()}');
    }
    return doc.exists ? doc.data() : null;
  }

  static Future<Map<String, dynamic>?> getRoadmap(
      String uid) async {
    final doc = await _db.collection('roadmaps').doc(uid).get();
    return doc.data();
  }
}
