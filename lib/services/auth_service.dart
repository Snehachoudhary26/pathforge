import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Auth state stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email & password
  static Future<String?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      // Save user to Firestore automatically
      await _db.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'name': name,
        'email': email,
        'createdAt': DateTime.now().toIso8601String(),
        'track': '',
        'weeksDone': 0,
        'streak': 0,
      });
      return null; // null means success
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // Sign in with email & password
  static Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email, password: password,
      );
      return null; // null means success
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
