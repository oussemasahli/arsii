import 'package:firebase_auth/firebase_auth.dart';

/// Centralized Firebase Authentication service.
/// Wraps FirebaseAuth to keep UI decoupled from the Firebase SDK.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Stream of auth state changes ─────────────────────────────────
  /// Emits the current [User] on login/logout. `null` = signed out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The currently signed-in user (or `null`).
  User? get currentUser => _auth.currentUser;

  // ── Email / Password ─────────────────────────────────────────────

  /// Create a new account with email & password.
  /// Returns the [UserCredential] on success.
  /// Throws [FirebaseAuthException] on failure.
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in an existing user with email & password.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Send a password-reset email.
  Future<void> resetPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
