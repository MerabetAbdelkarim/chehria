import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/errors/error_reporter.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseReady = true;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // `flutterfire configure` has not been run yet: the app shows setup help.
    firebaseReady = false;
  }

  if (firebaseReady) {
    await initErrorReporting();
    await _activateAppCheck();
  }

  runApp(ProviderScope(child: ChehriaApp(firebaseReady: firebaseReady)));
}

/// Proves to Firebase that requests come from the genuine app, so the public
/// API key alone is not enough to reach Firestore. Debug builds use the debug
/// provider: register the token printed in the console in Firebase → App Check.
Future<void> _activateAppCheck() async {
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.appAttestWithDeviceCheckFallback,
    );
  } catch (e, st) {
    // Without App Check the app still works until enforcement is switched on.
    reportError(e, st, reason: 'App Check activation');
  }
}
