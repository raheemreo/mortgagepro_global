// lib/services/app_check_service.dart

// App Check enforcement must be enabled in the Firebase
// Console for: Analytics, Remote Config, Firestore,
// Cloud Storage. This is a console setting, not an SDK
// setting. The SDK only activates the provider —
// enforcement is server-side.

import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import 'ad_config.dart';
import 'crashlytics_service.dart';

/// AppCheckService — Activates the appropriate Firebase App Check provider
/// based on platform and build mode.
///
/// Provider selection matrix:
///   isTestMode || kDebugMode (any platform) → DebugProvider
///   Android production                       → PlayIntegrityProvider
///   iOS 14+ production                       → AppAttestProvider
///   iOS < 14 production                      → DeviceCheckProvider
///
/// Enforcement is server-side (Firebase Console). The SDK only registers
/// the provider — it does not enforce anything locally.
///
/// Never throws. Never crashes the app.
class AppCheckService {
  // ── No instantiation ──────────────────────────────────────────────────────
  AppCheckService._();

  // ── Init ──────────────────────────────────────────────────────────────────

  /// Activates Firebase App Check with the appropriate provider.
  ///
  /// Must be called after Firebase.initializeApp() and after
  /// CrashlyticsService.init() so that any failure can be reported.
  ///
  /// On failure: logs to CrashlyticsService and continues app launch.
  static Future<void> init() async {
    try {
      final AndroidProvider androidProvider;
      final AppleProvider appleProvider;

      if (AdConfig.isTestMode || kDebugMode) {
        // ── Debug / test mode (any platform) ────────────────────────────
        // DebugProvider generates a debug token printed to the console.
        // Register that token in the Firebase Console under
        // App Check > Apps > [your app] > Debug tokens.
        // NEVER ship a production build with isTestMode = true.
        androidProvider = AndroidProvider.debug;
        appleProvider = AppleProvider.debug;
      } else if (Platform.isAndroid) {
        // ── Android production ───────────────────────────────────────────
        // Play Integrity replaces SafetyNet as of 2024.
        // Requires the Play Integrity API enabled in Google Cloud Console.
        androidProvider = AndroidProvider.playIntegrity;

        // appleProvider is unused on Android; assign a default to satisfy
        // the compiler — it will not be passed to activate().
        appleProvider = AppleProvider.deviceCheck;
      } else {
        // ── iOS production ───────────────────────────────────────────────
        // App Attest is available on iOS 14+ (A12 Bionic chip or later).
        // DeviceCheck is the fallback for iOS < 14 devices.
        // The SDK automatically falls back at runtime; we declare the
        // preferred provider here.
        androidProvider = AndroidProvider.playIntegrity; // unused on iOS
        appleProvider = _resolveAppleProvider();
      }

      await FirebaseAppCheck.instance.activate(
        // androidProvider is used on Android; ignored on iOS/macOS.
        androidProvider: androidProvider,
        // appleProvider is used on iOS/macOS; ignored on Android.
        appleProvider: appleProvider,
      );

      CrashlyticsService.log(
        'AppCheckService: activated — '
        'android=${androidProvider.name} '
        'apple=${appleProvider.name}',
      );
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'AppCheckService.init() failed — continuing without App Check',
      );
      // Continue launch. App Check failure is non-fatal; the app can still
      // function, though server-side enforcement may reject requests.
    }
  }

  // ── getToken ──────────────────────────────────────────────────────────────

  /// Returns the current App Check token, or null on failure.
  ///
  /// Pass this token in the X-Firebase-AppCheck header when making
  /// direct REST calls to Firebase services that enforce App Check.
  /// The SDK attaches tokens automatically for supported Firebase SDKs.
  ///
  /// Never throws.
  static Future<String?> getToken() async {
    try {
      final result = await FirebaseAppCheck.instance.getToken();
      return result;
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'AppCheckService.getToken() failed',
      );
      return null;
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Selects the Apple provider based on the iOS version at runtime.
  ///
  /// App Attest requires iOS 14.0+ and an Apple A12 Bionic chip or later.
  /// Devices that do not meet this requirement fall back to DeviceCheck.
  ///
  /// The Firebase SDK performs its own internal capability check, but we
  /// declare the preferred provider explicitly for clarity and auditability.
  static AppleProvider _resolveAppleProvider() {
    if (Platform.isIOS) {
      // Parse the OS version string to determine if iOS 14+ is available.
      // Platform.operatingSystemVersion format: "iPhone OS 17.4.0 ..."
      final versionString = Platform.operatingSystemVersion;
      final versionMatch = RegExp(r'(\d+)\.\d+').firstMatch(versionString);

      if (versionMatch != null) {
        final majorVersion = int.tryParse(versionMatch.group(1) ?? '0') ?? 0;
        if (majorVersion >= 14) {
          // iOS 14+ production → App Attest (preferred)
          return AppleProvider.appAttest;
        }
      }

      // iOS < 14 production → DeviceCheck (fallback)
      return AppleProvider.deviceCheck;
    }

    // macOS or other Apple platforms → App Attest
    return AppleProvider.appAttest;
  }
}
