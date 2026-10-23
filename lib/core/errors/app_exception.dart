import 'package:firebase_auth/firebase_auth.dart';

import '../localization/s.dart';

/// Domain failure carrying a localized message for the UI.
class AppFailure implements Exception {
  const AppFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Maps [FirebaseAuthException] codes (and Google sign-in failures) to clear
/// Arabic/French messages.
String authErrorMessage(Object? error, S s) {
  if (error is FirebaseAuthException) {
    return _fromCode(error.code, s);
  }
  if (error is AppFailure) return error.message;
  final text = error?.toString() ?? '';
  if (text.contains('sign_in_canceled') || text.contains('cancelled')) {
    return s.authCancelled;
  }
  if (text.contains('network') || text.contains('SocketException')) {
    return s.errorNetwork;
  }
  return s.errorGeneric;
}

String _fromCode(String code, S s) {
  switch (code) {
    case 'invalid-email':
      return s.authInvalidEmail;
    case 'user-disabled':
      return s.authUserDisabled;
    case 'user-not-found':
    case 'invalid-credential':
    case 'wrong-password':
      return s.authWrongCredentials;
    case 'email-already-in-use':
      return s.authEmailInUse;
    case 'weak-password':
      return s.authWeakPassword;
    case 'operation-not-allowed':
      return s.authNotAllowed;
    case 'network-request-failed':
      return s.errorNetwork;
    case 'too-many-requests':
      return s.authTooManyRequests;
    case 'requires-recent-login':
      return s.authRequiresRecentLogin;
    case 'quota-exceeded':
      return s.authQuotaExceeded;
    case 'invalid-action-code':
    case 'expired-action-code':
      return s.authInvalidActionCode;
    case 'account-exists-with-different-credential':
      return s.authAccountExists;
    case 'user-token-expired':
      return s.authTokenExpired;
    default:
      return s.errorGeneric;
  }
}

/// Wraps unknown repository errors so screens always show something readable.
Future<T> guard<T>(Future<T> Function() action, S s) async {
  try {
    return await action();
  } on AppFailure {
    rethrow;
  } on FirebaseAuthException catch (e) {
    throw AppFailure(authErrorMessage(e, s));
  } catch (e) {
    throw AppFailure(authErrorMessage(e, s));
  }
}
