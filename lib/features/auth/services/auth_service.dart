import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();
  static Future<void>? _googleInitFuture;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<void> _ensureGoogleInitialized() {
    return _googleInitFuture ??= GoogleSignIn.instance.initialize();
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No signed in user found.',
      );
    }

    final email = user.email;
    final isPasswordUser = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );
    if (email == null || !isPasswordUser) {
      throw FirebaseAuthException(
        code: 'account-not-password-based',
        message: 'This account does not use password sign-in.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleInitialized();

    final googleSignIn = GoogleSignIn.instance;
    final GoogleSignInAccount account;
    if (googleSignIn.supportsAuthenticate()) {
      account = await googleSignIn.authenticate();
    } else {
      final lightweight = await googleSignIn.attemptLightweightAuthentication();
      if (lightweight == null) {
        throw const GoogleSignInException(
          code: GoogleSignInExceptionCode.uiUnavailable,
          description: 'Google Sign-In is unavailable on this platform.',
        );
      }
      account = lightweight;
    }

    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-credential',
        message: 'Missing Google ID token.',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _ensureGoogleInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Ignore Google SDK sign-out issues for non-Google sessions.
    }
  }

  String messageForException(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'account-not-password-based':
        return 'This account uses Google sign-in. Password change is unavailable.';
      case 'email-already-in-use':
        return 'This email is already in use. Please sign in.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase.';
      case 'requires-recent-login':
        return 'Please sign in again before changing password.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'credential-already-in-use':
        return 'This Google account is already linked with another user.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  String messageForGoogleException(GoogleSignInException error) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        return 'Google sign-in was canceled.';
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Google sign-in is not configured correctly yet.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Google sign-in is currently unavailable on this device.';
      case GoogleSignInExceptionCode.interrupted:
        return 'Google sign-in was interrupted. Please try again.';
      default:
        return error.description ?? 'Google sign-in failed. Please try again.';
    }
  }
}
