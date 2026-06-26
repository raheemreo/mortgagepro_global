// lib/widgets/ads/interstitial_ad_controller.dart

import 'package:flutter/material.dart';

import 'dart:io';
import '../../services/ad_config.dart';
import '../../services/ad_manager.dart';

/// InterstitialAdController — A [ChangeNotifier] that wraps
/// [AdManager.instance.showInterstitial()].
///
/// Usage:
///   final controller = InterstitialAdController();
///   // Pre-load after a result screen renders:
///   await controller.preload();
///   // Show after calculation complete / user exits result:
///   await controller.show(context);
///
/// PLACEMENT RULES (must be respected by every caller):
///   NEVER show on app launch or resume.
///   NEVER show during text input.
///   NEVER show before the user sees a calculation result.
///   ONLY show after: calculation completed, report generated,
///   user exits a result screen, or optional tool completion.
///
/// Never throws. Never crashes the app.
class InterstitialAdController extends ChangeNotifier {
  // ── State ─────────────────────────────────────────────────────────────────

  bool _isReady = false;
  bool _isShowing = false;

  /// True when a pre-loaded interstitial is available and
  /// all suppression gates (consent, adsEnabled, frequency,
  /// disableInterstitials) will be evaluated at show time by [AdManager].
  ///
  /// Use this to conditionally enable a "continue" affordance or to
  /// decide whether to attempt a show. A true value does NOT guarantee
  /// the ad will actually display — [AdManager.showInterstitial] applies
  /// its own guards at the moment of the call.
  bool get isReady => _isReady;

  /// True while an interstitial is being presented full-screen.
  bool get isShowing => _isShowing;

  String get _adUnitId => Platform.isIOS ? AdConfig.interstitialAdUnitIos : AdConfig.interstitialAdUnitAndroid;

  /// Requests [AdManager] to pre-load an interstitial into its cache.
  ///
  /// Call this after a result screen has rendered — never on launch or resume.
  /// Sets [isReady] to true on completion so the caller can react.
  ///
  /// Never throws.
  Future<void> preload() async {
    await AdManager.instance.loadInterstitial(_adUnitId, screen: 'interstitial_controller');
    // We do not have direct visibility into AdManager's internal ad cache,
    // so we optimistically set isReady = true after a successful preload call.
    // AdManager.showInterstitial() will silently no-op if the ad is not ready.
    _isReady = true;
    notifyListeners();
  }

  // ── Show ──────────────────────────────────────────────────────────────────

  /// Shows the pre-loaded interstitial if all conditions are met.
  ///
  /// Blocked when:
  ///   • The keyboard is visible
  ///     ([MediaQuery.viewInsetsOf(context).bottom] > 0).
  ///   • [AdManager.showInterstitial] internally gates on:
  ///       – adsEnabled == false
  ///       – disableInterstitials == true
  ///       – frequency cooldown not yet elapsed
  ///       – no ad loaded
  ///
  /// Resets [isReady] to false after a show attempt so callers do not
  /// attempt a second show before the next [preload] cycle.
  ///
  /// Never throws.
  Future<void> show(BuildContext context, {VoidCallback? onDismissed}) async {
    // Block when keyboard is open — user is mid-input.
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      onDismissed?.call();
      return;
    }

    // Mark as showing while the full-screen ad is presented.
    _isShowing = true;
    _isReady = false;
    notifyListeners();

    await AdManager.instance.showInterstitial(_adUnitId, context, screen: 'interstitial_controller', onDismissed: () {
      // Reset showing state after AdManager returns (ad dismissed or failed).
      _isShowing = false;
      notifyListeners();
      onDismissed?.call();
    });
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  /// Resets [isReady] and [isShowing] to their initial states.
  ///
  /// Call when navigating away from a screen that pre-loaded an ad
  /// but the ad was never shown (e.g. user went back early).
  void reset() {
    _isReady = false;
    _isShowing = false;
    notifyListeners();
  }
}
