import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Real authentication using Firebase Auth (email + password).
///
/// We use email/password to start because it needs zero extra console setup.
/// Phone-number OTP (closer to the login screen we mocked up earlier) is a
/// drop-in upgrade later, but it requires SHA-1/SHA-256 fingerprints
/// registered in the Firebase console for Android — an extra manual step
/// we're skipping for now so you can get a real login working today.
class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authState => _auth.authStateChanges();

  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await cred.user?.updateDisplayName(name);

    // Create the rider's profile document in Firestore.
    await _db.collection('riders').doc(cred.user!.uid).set({
      'name': name,
      'email': email,
      'bike': '',
      'plate': '',
      'safetyScore': 100,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return cred;
  }

  Future<UserCredential> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();
}
