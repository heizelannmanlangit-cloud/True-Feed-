import 'package:firebase_auth/firebase_auth.dart';

// Talks to Firebase Authentication (login, register, logout)
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> register(String name, String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await result.user?.updateDisplayName(name.trim());
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}

// Turns a Firebase error code into a message the user can understand
String friendlyAuthError(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'That email address is not valid.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Wrong email or password.';
    case 'email-already-in-use':
      return 'There is already an account with that email.';
    case 'weak-password':
      return 'Password is too weak. Use at least 6 characters.';
    case 'network-request-failed':
      return 'No internet connection. Try again.';
    case 'too-many-requests':
      return 'Too many tries. Wait a moment and try again.';
    default:
      return 'Something went wrong (${e.code}).';
  }
}
