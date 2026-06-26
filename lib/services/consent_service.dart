// lib/services/consent_service.dart

import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'crashlytics_service.dart';

/// ConsentService — UMP (User Messaging Platform) + ATT consent manager.
///
/// Covers jurisdictions:
///   • EEA, UK, Switzerland  — GDPR
///   • US states             — CPRA (CA), CPA (CO), VCDPA (VA),
///                             CTDPA (CT), UCPA (UT)
///
/// STORAGE RULE:
///   Never writes consent state to SharedPreferences.
///   Never duplicates IAB TCF keys.
///   UMP / google_mobile_ads is the ONLY source of truth.
///   All ad-loading decisions read from
///   ConsentInformation.instance.getConsentStatus() directly.
///
/// ConsentStatus values in google_mobile_ads v5:
///   ConsentStatus.notRequired — outside a regulated region; ads allowed.
///   ConsentStatus.obtained    — user explicitly granted consent.
///   ConsentStatus.required    — consent required but not yet obtained.
///   ConsentStatus.unknown     — status is undetermined; block ads.
///
/// Never throws. Never crashes the app.
/// On any failure: isConsentGranted defaults to false (blocks ads).
class ConsentService {
  // ── Singleton ─────────────────────────────────────────────────────────────
  ConsentService._();
  static final ConsentService instance = ConsentService._();

  // ── Internal state ────────────────────────────────────────────────────────

  /// Reflects the most recently resolved UMP consent status.
  /// Defaults to false (deny ads) until consent is confirmed.
  bool _isConsentGranted = false;

  /// Cached consent status from the most recent resolution.
  ConsentStatus _currentStatus = ConsentStatus.unknown;

  /// Triggered whenever consent settings change (e.g. form dismissal).
  VoidCallback? onConsentChanged;

  // ── Public API ────────────────────────────────────────────────────────────

  /// True when the user has granted consent (or consent is not required
  /// in their jurisdiction). Safe to use as the primary ad-load gate.
  bool get isConsentGranted => _isConsentGranted;

  /// True when personalized ads are permitted.
  /// Requires consent granted AND ConsentStatus.obtained from UMP.
  bool get canShowPersonalizedAds =>
      _isConsentGranted && _currentStatus == ConsentStatus.obtained;

  /// The most recently cached UMP consent status.
  /// Populated during init() and refreshed after showPrivacyOptionsForm().
  ConsentStatus get currentStatus => _currentStatus;

  // ── Init ──────────────────────────────────────────────────────────────────

  /// Runs the full consent + ATT flow.
  ///
  /// Flow (must not be reordered):
  ///   Both platforms:
  ///     1. requestConsentInfoUpdate()
  ///     2. If form available → load and show ConsentForm, await completion.
  ///     3. Derive isConsentGranted from canRequestAds.
  ///   iOS only (after step 3):
  ///     4. Guard with Platform.isIOS.
  ///     5. Request ATT via AppTrackingTransparency.
  ///     6. Await ATT result before continuing.
  ///     7. ATT result does NOT override isConsentGranted.
  ///
  /// Must be fully awaited by the caller (main.dart step 5).
  Future<void> init() async {
    try {
      // ── Step 1: Request consent information update ─────────────────────
      final updateCompleter = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () => updateCompleter.complete(),
        (FormError error) {
          CrashlyticsService.recordError(
            error,
            null,
            reason: 'ConsentService requestConsentInfoUpdate failed: ${error.message}',
          );
          updateCompleter.complete();
        },
      );
      await updateCompleter.future;

      // ── Step 2: Show consent form if available ─────────────────────────
      final formAvailable = await ConsentInformation.instance.isConsentFormAvailable();
      if (formAvailable) {
        await _showConsentForm();
      }

      // ── Step 3: Derive isConsentGranted ───────────────────────────────
      _currentStatus = await ConsentInformation.instance.getConsentStatus();
      _isConsentGranted = await ConsentInformation.instance.canRequestAds();

      CrashlyticsService.log(
        'ConsentService: status=${_currentStatus.name} isConsentGranted=$_isConsentGranted',
      );
    } catch (e, s) {
      _isConsentGranted = false;
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'ConsentService UMP flow failed — ads blocked',
      );
    }

    if (Platform.isIOS) {
      await _requestATT();
    }
  }

  // ── showPrivacyOptionsForm ────────────────────────────────────────────────

  /// Presents the UMP privacy options form so the user can update their
  /// consent preferences at any time.
  Future<void> showPrivacyOptionsForm(BuildContext context) async {
    try {
      final requirement = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();

      if (requirement != PrivacyOptionsRequirementStatus.required) {
        CrashlyticsService.log(
          'ConsentService.showPrivacyOptionsForm: not required (${requirement.name})',
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ad consent settings are not required in your region.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final completer = Completer<void>();
      await ConsentForm.showPrivacyOptionsForm((FormError? formError) {
        if (formError != null) {
          CrashlyticsService.recordError(
            formError,
            null,
            reason: 'ConsentService.showPrivacyOptionsForm formError: ${formError.message}',
          );
        }
        completer.complete();
      });
      await completer.future;

      _currentStatus = await ConsentInformation.instance.getConsentStatus();
      _isConsentGranted = await ConsentInformation.instance.canRequestAds();

      CrashlyticsService.log(
        'ConsentService: privacy form dismissed — status=${_currentStatus.name} isConsentGranted=$_isConsentGranted',
      );

      onConsentChanged?.call();
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'ConsentService.showPrivacyOptionsForm() failed',
      );
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Loads and presents the UMP consent form, then awaits user response.
  ///
  /// Uses ConsentForm.loadAndShowConsentFormIfRequired() which shows the form
  /// only when UMP determines one is needed. If the form is not needed,
  /// the callback fires immediately with no error.
  Future<void> _showConsentForm() async {
    final completer = Completer<void>();

    // Correct v5 method name: loadAndShowConsentFormIfRequired
    // (not loadAndShowIfRequired).
    await ConsentForm.loadAndShowConsentFormIfRequired((FormError? formError) {
      if (formError != null) {
        CrashlyticsService.recordError(
          formError,
          null,
          reason: 'ConsentService._showConsentForm formError: '
              '${formError.message}',
        );
      }
      if (!completer.isCompleted) completer.complete();
    });

    await completer.future;
  }

  /// Requests App Tracking Transparency permission on iOS (steps 4–7).
  ///
  /// • Checks the current ATT status first; only requests if undetermined.
  /// • The result is logged to Crashlytics but does NOT override UMP consent.
  Future<void> _requestATT() async {
    try {
      // Step 5: Read current ATT authorisation status.
      final attStatus =
          await AppTrackingTransparency.trackingAuthorizationStatus;

      // Step 6: Only present the system prompt if status is undetermined.
      if (attStatus == TrackingStatus.notDetermined) {
        final result =
            await AppTrackingTransparency.requestTrackingAuthorization();
        CrashlyticsService.log(
          'ConsentService ATT: result=${result.name}',
        );
      } else {
        CrashlyticsService.log(
          'ConsentService ATT: already resolved — '
          'status=${attStatus.name}',
        );
      }

      // Step 7: ATT result intentionally NOT used to override _isConsentGranted.
      // UMP (google_mobile_ads) is the sole source of truth for ad consent.
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'ConsentService._requestATT() failed',
      );
      // Never throw. App launch continues regardless of ATT outcome.
    }
  }
}
