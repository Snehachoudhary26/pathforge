import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<String?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      await result.user?.updateDisplayName(name);
      await _db.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'name': name,
        'email': email,
        'createdAt': DateTime.now().toIso8601String(),
        'xp': 0,
        'level': 1,
        'levelName': 'Code Newcomer',
        'streak': 0,
        'authProvider': 'email',
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  static Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      final result = await _auth.signInWithPopup(googleProvider);
      final user = result.user;

      if (user == null) {
        return {'error': 'Sign in failed', 'isNewUser': false};
      }

      final isNewUser = result.additionalUserInfo?.isNewUser ?? false;

      if (isNewUser) {
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': user.displayName ??
              user.email?.split('@')[0] ?? 'Student',
          'email': user.email ?? '',
          'createdAt': DateTime.now().toIso8601String(),
          'xp': 0,
          'level': 1,
          'levelName': 'Code Newcomer',
          'streak': 0,
          'authProvider': 'google',
          'photoUrl': user.photoURL ?? '',
        });
      } else {
        await _db.collection('users').doc(user.uid).set({
          'photoUrl': user.photoURL ?? '',
          'lastSignIn': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }

      return {'error': null, 'isNewUser': isNewUser};
    } on FirebaseAuthException catch (e) {
      return {'error': e.message ?? 'Google sign in failed',
              'isNewUser': false};
    } catch (e) {
      return {'error': e.toString(), 'isNewUser': false};
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
