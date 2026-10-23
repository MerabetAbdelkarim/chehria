import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Email/password + Google authentication.
class AuthRepository {
  AuthRepository(this._auth);

  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<UserCredential> signUpWithEmail(
    String name,
    String email,
    String password,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      await credential.user?.updateDisplayName(trimmed);
    }
    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    final account = await GoogleSignIn().signIn();
    if (account == null) {
      throw FirebaseAuthException(code: 'sign-in-canceled');
    }
    final auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: auth.idToken,
      accessToken: auth.accessToken,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Whether the signed-in user has an email/password credential (otherwise
  /// they signed in with Google only).
  bool get usesPassword =>
      _auth.currentUser?.providerData.any((p) => p.providerId == 'password') ??
      false;

  /// Confirms the user's identity again: Firebase demands a recent sign-in
  /// before sensitive operations such as deleting the account.
  /// [password] is required for email/password users; Google users go
  /// through the Google sign-in sheet.
  Future<void> reauthenticate({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'user-not-found');

    final AuthCredential credential;
    if (usesPassword) {
      credential = EmailAuthProvider.credential(
        email: user.email ?? '',
        password: password ?? '',
      );
    } else {
      final account = await GoogleSignIn().signIn();
      if (account == null) {
        throw FirebaseAuthException(code: 'sign-in-canceled');
      }
      final auth = await account.authentication;
      credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      );
    }
    await user.reauthenticateWithCredential(credential);
  }

  /// Deletes the Firebase Auth user (call after [reauthenticate] and after
  /// the Firestore data is gone: rules need the user to still exist).
  Future<void> deleteUser() async {
    await _auth.currentUser?.delete();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Google sign-in may never have been used.
    }
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Google sign-in may never have been used.
    }
    await _auth.signOut();
  }
}
