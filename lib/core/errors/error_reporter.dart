import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Single entry point for errors the app catches and recovers from.
///
/// Screens still show a friendly message, but the error is no longer lost:
/// it goes to the debug console and, in release builds, to Crashlytics.
bool _crashlyticsReady = false;

/// Hooks Flutter and platform errors into Crashlytics. Call once, after
/// `Firebase.initializeApp`.
Future<void> initErrorReporting() async {
  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
  _crashlyticsReady = true;

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    crashlytics.recordFlutterFatalError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };
}

/// Records a handled (non-fatal) error. Never throws.
void reportError(Object error, StackTrace stack, {String? reason}) {
  debugPrint('[Chehria] ${reason ?? 'error'}: $error');
  if (kDebugMode) debugPrintStack(stackTrace: stack, maxFrames: 8);
  if (!_crashlyticsReady) return;
  try {
    FirebaseCrashlytics.instance.recordError(error, stack, reason: reason);
  } catch (_) {
    // Reporting must never become a new source of failures.
  }
}

/// Associates reports with the signed-in user (anonymous Firebase uid).
void setErrorReportingUser(String? uid) {
  if (!_crashlyticsReady) return;
  FirebaseCrashlytics.instance.setUserIdentifier(uid ?? '').ignore();
}
