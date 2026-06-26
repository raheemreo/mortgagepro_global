// lib/services/crashlytics_service.dart



import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// CrashlyticsService — Centralised error reporting for MortgagePro Global.
///
/// Covers:
///   • Flutter framework errors        (FlutterError.onError)
///   • Async / Future / isolate errors (PlatformDispatcher.instance.onError)
///   • Network errors                  (call recordError() from Dio interceptors)
///   • Firestore errors                (call recordError() from repository layer)
///   • PDF generation errors           (call recordError() from pdf service)
///   • Ad loading errors               (call recordError() from AdManager)
///
/// Never rethrows. Never crashes the app.
class CrashlyticsService {
  // ── Singleton ─────────────────────────────────────────────────────────────
  CrashlyticsService._();
  static final CrashlyticsService instance = CrashlyticsService._();

  // ── Init ──────────────────────────────────────────────────────────────────

  /// Initialises Crashlytics and registers both global error handlers.
  ///
  /// Must be called once, early in main(), after Firebase.initializeApp().
  /// Do NOT register FlutterError.onError or
  /// PlatformDispatcher.instance.onError anywhere else in the project.
  static Future<void> init() async {
    try {
      // ── Flutter framework errors ──────────────────────────────────────────
      // Catches errors thrown inside the Flutter widget build pipeline,
      // layout, painting, gesture handling, and other framework callbacks.
      FlutterError.onError = (FlutterErrorDetails details) {
        // recordFlutterFatalError marks the error as fatal in the Crashlytics
        // dashboard. Use recordFlutterError for non-fatal widget errors.
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        // Do NOT rethrow — the app continues running.
      };

      // ── Async / Future / isolate errors ──────────────────────────────────
      // Catches all unhandled errors that escape the Dart event loop,
      // including Future errors not caught by .catchError(), isolate errors,
      // and platform channel callback errors.
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        recordError(
          error,
          stack,
          reason: 'Unhandled async/platform error',
          fatal: true,
        );
        // Return true to indicate the error has been handled.
        // The app is NOT terminated.
        return true;
      };

      // Disable Crashlytics in debug mode to reduce noise during development.
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode);
    } catch (e, s) {
      // If Crashlytics itself fails to initialise, degrade gracefully.
      debugPrint('CrashlyticsService.init() failed: $e\n$s');
    }
  }

  // ── recordError ───────────────────────────────────────────────────────────

  /// Records a non-fatal or fatal error to Firebase Crashlytics.
  ///
  /// Error categories this method handles when called from the appropriate
  /// layer of the application:
  ///   • Flutter framework errors  — set via FlutterError.onError in init()
  ///   • Async / Future errors     — set via PlatformDispatcher.onError in init()
  ///   • Network errors            — called from Dio interceptors / http handlers
  ///   • Firestore errors          — called from repository / data-source layer
  ///   • PDF generation errors     — called from the pdf/printing service
  ///   • Ad loading errors         — called from AdManager onAdFailedToLoad
  ///
  /// [fatal] — marks the event as a crash in the Crashlytics dashboard.
  /// Never rethrows. Never crashes the app.
  static void recordError(
    dynamic error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) {
    try {
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: reason,
        fatal: fatal,
      );
    } catch (e, s) {
      // Last-resort fallback — print only; do not rethrow.
      debugPrint('CrashlyticsService.recordError() failed: $e\n$s');
    }
  }

  // ── log ───────────────────────────────────────────────────────────────────

  /// Appends a breadcrumb log message to the next Crashlytics report.
  ///
  /// Useful for annotating the sequence of events leading up to an error.
  /// Messages are visible in the Crashlytics dashboard under "Logs".
  /// Never rethrows. Never crashes the app.
  static void log(String message) {
    try {
      FirebaseCrashlytics.instance.log(message);
    } catch (e, s) {
      debugPrint('CrashlyticsService.log() failed: $e\n$s');
    }
  }

  // ── setUserContext ────────────────────────────────────────────────────────

  /// Attaches contextual key-value pairs to every subsequent Crashlytics report.
  ///
  /// This helps correlate crashes with specific user journeys, countries,
  /// and calculator types — without recording any PII.
  ///
  /// [country]        — e.g. "USA", "India", "UK"
  /// [calculatorType] — e.g. "standard", "affordability", "refinance"
  /// [appVersion]     — e.g. "1.0.0+1"
  /// [screenName]     — snake_case screen name, e.g. "usa_screen"
  ///
  /// Never rethrows. Never crashes the app.
  static Future<void> setUserContext({
    required String country,
    required String calculatorType,
    required String appVersion,
    required String screenName,
  }) async {
    try {
      await Future.wait([
        FirebaseCrashlytics.instance.setCustomKey('country', country),
        FirebaseCrashlytics.instance
            .setCustomKey('calculator_type', calculatorType),
        FirebaseCrashlytics.instance.setCustomKey('app_version', appVersion),
        FirebaseCrashlytics.instance.setCustomKey('screen_name', screenName),
      ]);
    } catch (e, s) {
      debugPrint('CrashlyticsService.setUserContext() failed: $e\n$s');
    }
  }
}
