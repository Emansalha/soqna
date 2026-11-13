import 'package:firebase_auth/firebase_auth.dart';

/// Friendly auth error with a readable message (no "Exception:" prefix).
class AuthError implements Exception {
  final String message;
  AuthError(this.message);
  @override
  String toString() => message;
}

/// Thrown when the account exists but the email is not verified yet.
/// The UI catches it and opens the "Verify your email" screen.
class EmailNotVerified implements Exception {
  final String email;
  EmailNotVerified(this.email);
  @override
  String toString() => 'Please verify your email first';
}

/// Firebase is used as the identity check (email verification);
/// the Souqna API stays the source of truth for cart, orders and favorites.
class FirebaseGate {
  FirebaseGate._();
  static final instance = FirebaseGate._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? get user => _auth.currentUser;

  /// Creates the Firebase account and sends the verification email.
  Future<User> createAccount(
      String name, String email, String password) async {
    try {
      final c = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final u = c.user!;
      if (name.isNotEmpty) await u.updateDisplayName(name);
      await u.sendEmailVerification();
      return u;
    } on FirebaseAuthException catch (e) {
      throw AuthError(_message(e));
    }
  }

  /// Signs in to Firebase. Returns null when no Firebase account matches
  /// (e.g. an older store account created before Firebase was added).
  Future<User?> signIn(String email, String password) async {
    try {
      final c = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return c.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        return null;
      }
      throw AuthError(_message(e));
    }
  }

  /// Refreshes the user from Firebase and reports whether the email is verified.
  Future<bool> isVerified() async {
    final u = _auth.currentUser;
    if (u == null) return false;
    await u.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> resendVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthError(_message(e));
    }
  }

  /// Used to roll back when the store registration fails.
  Future<void> deleteCurrentUser() async {
    try {
      await _auth.currentUser?.delete();
    } catch (_) {}
  }

  Future<void> signOut() => _auth.signOut();

  static String _message(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Try signing in.';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak — use at least 8 characters';
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found':
        return 'Incorrect email or password';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection';
      case 'operation-not-allowed':
        return 'Email sign-in is not enabled in Firebase yet';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}
