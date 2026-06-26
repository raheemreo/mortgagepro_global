// lib/services/ad_analytics_service.dart

import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'consent_service.dart';

/// AdAnalyticsService — Ad-specific tracking layer for MortgagePro Global.
///
/// Implements Firebase Ad Tracking Specification v2.
/// All events are gated by consent status and canRequestAds.
class AdAnalyticsService {
  AdAnalyticsService._() {
    ConsentService.instance.onConsentChanged = _handleConsentChanged;
  }
  static final AdAnalyticsService instance = AdAnalyticsService._();

  // ── Session state ─────────────────────────────────────────────────────────
  final String _sessionId = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(100000)}';
  final Queue<Map<String, dynamic>> _offlineQueue = Queue<Map<String, dynamic>>();
  bool _consentWithdrawn = false;

  // ── Privacy Gate ──────────────────────────────────────────────────────────
  bool get _canTrack {
    if (_consentWithdrawn) return false;
    return ConsentService.instance.isConsentGranted;
  }

  void _handleConsentChanged() {
    if (!ConsentService.instance.isConsentGranted) {
      _consentWithdrawn = true;
      _offlineQueue.clear();
      FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
    } else {
      _consentWithdrawn = false;
      FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    }
  }

  // ── Global Parameters ─────────────────────────────────────────────────────
  Map<String, Object> _globalParams() => {
        "app_version": "1.0.0", // matches app version contract
        "platform": Platform.isAndroid ? "android" : "ios",
        "consent_status": ConsentService.instance.currentStatus.name,
        "session_id": _sessionId,
      };

  // ── Network Connectivity ──────────────────────────────────────────────────
  Future<bool> _isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  // ── Log Event ─────────────────────────────────────────────────────────────
  Future<void> logEvent(String name, Map<String, Object> params) async {
    if (!_canTrack) return;

    final fullParams = {...params, ..._globalParams()};

    final connected = await _isConnected();
    if (!connected) {
      if (_isCriticalEvent(name)) {
        _offlineQueue.add({"name": name, "params": fullParams});
      }
      return; // drop non-critical events silently
    }

    await _flushQueue();
    try {
      await FirebaseAnalytics.instance.logEvent(name: name, parameters: fullParams);
    } catch (e, s) {
      recordNonFatalError(e, s, "Failed to log Firebase event: $name");
    }
  }

  bool _isCriticalEvent(String name) => [
        "ad_revenue",
        "rewarded_earned",
        "banner_impression",
        "native_impression",
        "interstitial_impression",
      ].contains(name);

  Future<void> _flushQueue() async {
    try {
      while (_offlineQueue.isNotEmpty) {
        final e = _offlineQueue.removeFirst();
        final name = e["name"] as String;
        final parameters = e["params"] as Map<String, Object>;
        await FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);
      }
    } catch (e, s) {
      recordNonFatalError(e, s, "Failed to flush offline analytics queue");
    }
  }

  // ── Network Resolution ────────────────────────────────────────────────────
  String _resolveNetwork(String? networkClassName) {
    if (networkClassName == null) return "unknown";
    final lower = networkClassName.toLowerCase();
    if (lower.contains("facebook") || lower.contains("meta")) {
      return "Meta";
    }
    if (lower.contains("google") || lower.contains("admob")) {
      return "AdMob";
    }
    return networkClassName;
  }

  // ── Banner Ad Events ──────────────────────────────────────────────────────
  void trackBannerRequest({required String adUnit, required String screen, required int retryAttempt}) {
    logEvent("banner_request", {
      "ad_unit": adUnit,
      "screen": screen,
      "retry_attempt": retryAttempt,
    });
  }

  void trackBannerLoaded({
    required String adUnit,
    required String screen,
    required String? network,
    required int responseTimeMs,
    required int retryAttempt,
  }) {
    logEvent("banner_loaded", {
      "ad_unit": adUnit,
      "screen": screen,
      "network": _resolveNetwork(network),
      "response_time_ms": responseTimeMs,
      "retry_attempt": retryAttempt,
    });
  }

  void trackBannerFailed({
    required String adUnit,
    required String screen,
    required String? network,
    required int errorCode,
    required String errorMessage,
    required int responseTimeMs,
    required int retryAttempt,
  }) {
    logEvent("banner_failed", {
      "ad_unit": adUnit,
      "screen": screen,
      "network": _resolveNetwork(network),
      "error_code": errorCode,
      "error_message": errorMessage,
      "response_time_ms": responseTimeMs,
      "retry_attempt": retryAttempt,
    });
  }

  void trackBannerImpression({required String adUnit, required String screen, required String? network}) {
    logEvent("banner_impression", {
      "ad_unit": adUnit,
      "screen": screen,
      "network": _resolveNetwork(network),
    });
  }

  void trackBannerClicked({required String adUnit, required String screen, required String? network}) {
    logEvent("banner_clicked", {
      "ad_unit": adUnit,
      "screen": screen,
      "network": _resolveNetwork(network),
    });
  }

  // ── Native Ad Events ──────────────────────────────────────────────────────
  void trackNativeRequest({required String adUnit, required String screen, required int retryAttempt}) {
    logEvent("native_request", {
      "ad_unit": adUnit,
      "screen": screen,
      "retry_attempt": retryAttempt,
    });
  }

  void trackNativeLoaded({
    required String adUnit,
    required String screen,
    required String? network,
    required int responseTimeMs,
    required int retryAttempt,
  }) {
    logEvent("native_loaded", {
      "ad_unit": adUnit,
      "screen": screen,
      "network": _resolveNetwork(network),
      "response_time_ms": responseTimeMs,
      "retry_attempt": retryAttempt,
    });
  }

  void trackNativeFailed({
    required String adUnit,
    required String screen,
    required String? network,
    required int errorCode,
    required String errorMessage,
    required int responseTimeMs,
    required int retryAttempt,
  }) {
    logEvent("native_failed", {
      "ad_unit": adUnit,
      "screen": screen,
      "network": _resolveNetwork(network),
      "error_code": errorCode,
      "error_message": errorMessage,
      "response_time_ms": responseTimeMs,
      "retry_attempt": retryAttempt,
    });
  }

  void trackNativeImpression({required String adUnit, required String screen, required String? network}) {
    logEvent("native_impression", {
      "ad_unit": adUnit,
      "screen": screen,
      "network": _resolveNetwork(network),
    });
  }

  void trackNativeClicked({required String adUnit, required String screen, required String? network}) {
    logEvent("native_clicked", {
      "ad_unit": adUnit,
      "screen": screen,
      "network": _resolveNetwork(network),
    });
  }

  // ── Interstitial Ad Events ────────────────────────────────────────────────
  void trackInterstitialRequest({required String adUnit, required String screen, required int retryAttempt}) {
    logEvent("interstitial_request", {
      "ad_unit": adUnit,
      "screen": screen,
      "retry_attempt": retryAttempt,
    });
  }

  void trackInterstitialLoaded({
    required String adUnit,
    required String screen,
    required String? network,
    required int responseTimeMs,
    required int retryAttempt,
  }) {
    logEvent("interstitial_loaded", {
      "ad_unit": adUnit,
      "screen": screen,
      "network": _resolveNetwork(network),
      "response_time_ms": responseTimeMs,
      "retry_attempt": retryAttempt,
    });
  }

  void trackInterstitialFailed({
    required String adUnit,
    required String screen,
    required String? network,
    required int errorCode,
    required String errorMessage,
    required int responseTimeMs,
    required int retryAttempt,
  }) {
    logEvent("interstitial_failed", {
      "ad_unit": adUnit,
      "screen": screen,
      "network": _resolveNetwork(network),
      "error_code": errorCode,
      "error_message": errorMessage,
      "response_time_ms": responseTimeMs,
      "retry_attempt": retryAttempt,
    });
  }

  void trackInterstitialShow({required String adUnit, required String screen, required String? network}) {
    logEvent("interstitial_show", {
      "ad_unit": adUnit,
      "screen": screen,
      "network": _resolveNetwork(network),
    });
  }

  void trackInterstitialImpression({required String adUnit, required String screen, required String? network}) {
    logEvent("interstitial_impression", {
      "ad_unit": adUnit,
      "screen": screen,
      "network": _resolveNetwork(network),
    });
  }

  void trackInterstitialClicked({required String adUnit, required String screen, required String? network}) {
    logEvent("interstitial_clicked", {
      "ad_unit": adUnit,
      "screen": screen,
      "network": _resolveNetwork(network),
    });
  }

  void trackInterstitialClosed({
    required String adUnit,
    required String screen,
    required String? network,
    required bool wasClicked,
  }) {
    logEvent("interstitial_closed", {
      "ad_unit": adUnit,
      "screen": screen,
      "network": _resolveNetwork(network),
      "was_clicked": wasClicked,
    });
  }

  // ── Rewarded Ad Events ────────────────────────────────────────────────────
  void trackRewardedRequest({required String adUnit, required String screen, required int retryAttempt}) {
    logEvent("rewarded_request", {
      "ad_unit": adUnit,
      "screen": screen,
      "retry_attempt": retryAttempt,
    });
  }

  void trackRewardedLoaded({
    required String adUnit,
    required String screen,
    required String? network,
    required int responseTimeMs,
    required int retryAttempt,
  }) {
    logEvent("rewarded_loaded", {
      "ad_unit": adUnit,
      "screen": screen,
      "network": _resolveNetwork(network),
      "response_time_ms": responseTimeMs,
      "retry_attempt": retryAttempt,
    });
  }

  void trackRewardedFailed({
    required String adUnit,
    required String screen,
    required String? network,
    required int errorCode,
    required String errorMessage,
    required int responseTimeMs,
    required int retryAttempt,
  }) {
    logEvent("rewarded_failed", {
      "ad_unit": adUnit,
      "screen": screen,
      "network": _resolveNetwork(network),
      "error_code": errorCode,
      "error_message": errorMessage,
      "response_time_ms": responseTimeMs,
      "retry_attempt": retryAttempt,
    });
  }

  void trackRewardedShow({required String adUnit, required String screen, required String? network}) {
    logEvent("rewarded_show", {
      "ad_unit": adUnit,
      "screen": screen,
      "network": _resolveNetwork(network),
    });
  }

  void trackRewardedImpression({required String adUnit, required String screen, required String? network}) {
    logEvent("rewarded_impression", {
      "ad_unit": adUnit,
      "screen": screen,
      "network": _resolveNetwork(network),
    });
  }

  void trackRewardedClicked({required String adUnit, required String screen, required String? network}) {
    logEvent("rewarded_clicked", {
      "ad_unit": adUnit,
      "screen": screen,
      "network": _resolveNetwork(network),
    });
  }

  void trackRewardedClosed({
    required String adUnit,
    required String screen,
    required String? network,
    required bool rewardEarned,
  }) {
    logEvent("rewarded_closed", {
      "ad_unit": adUnit,
      "screen": screen,
      "network": _resolveNetwork(network),
      "reward_earned": rewardEarned,
    });
  }

  void trackRewardedEarned({
    required String adUnit,
    required String screen,
    required String? network,
    required String rewardType,
    required int amount,
  }) {
    logEvent("rewarded_earned", {
      "ad_unit": adUnit,
      "screen": screen,
      "network": _resolveNetwork(network),
      "reward_type": rewardType,
      "reward_amount": amount,
    });
  }

  // ── Revenue Event ─────────────────────────────────────────────────────────
  void trackRevenue({
    required String adUnitId,
    required String adType,
    required String screen,
    required String? network,
    required double valueMicros,
    required String currencyCode,
    required String precisionName,
  }) {
    logEvent("ad_revenue", {
      "ad_unit": adUnitId,
      "ad_type": adType,
      "screen": screen,
      "network": _resolveNetwork(network),
      "currency": currencyCode,
      "value_micros": valueMicros,
      "precision": precisionName,
    });
  }

  // ── Crashlytics Severity ──────────────────────────────────────────────────
  void recordFatalError(dynamic exception, StackTrace? stack, String reason) {
    _logBreadcrumb("FATAL ERROR: $reason");
    FirebaseCrashlytics.instance.recordError(
      exception,
      stack,
      reason: reason,
      fatal: true,
    );
  }

  void recordNonFatalError(
    dynamic exception,
    StackTrace? stack,
    String reason, {
    String? adUnit,
    String? network,
    int? retryAttempt,
  }) {
    _logBreadcrumb("NON-FATAL ERROR: $reason");
    _setCrashlyticsKeys(adUnit: adUnit, network: network, retryAttempt: retryAttempt);
    FirebaseCrashlytics.instance.recordError(
      exception,
      stack,
      reason: reason,
      fatal: false,
    );
  }

  void logBreadcrumbOrError({
    required int errorCode,
    required String errorMessage,
    required String reason,
    required String adUnit,
    required String? network,
    required int retryAttempt,
  }) {
    final msg = "$reason: Code=$errorCode, Message=$errorMessage";
    _logBreadcrumb(msg);

    if (errorCode == 3) {
      // Error code 3 is No Fill — log as breadcrumb only
      return;
    }

    // Otherwise log as non-fatal
    recordNonFatalError(
      msg,
      null,
      reason,
      adUnit: adUnit,
      network: network,
      retryAttempt: retryAttempt,
    );
  }

  void _logBreadcrumb(String message) {
    FirebaseCrashlytics.instance.log(message);
  }

  void _setCrashlyticsKeys({String? adUnit, String? network, int? retryAttempt}) {
    final consentName = ConsentService.instance.currentStatus.name;
    FirebaseCrashlytics.instance.setCustomKey("consent_status", consentName);
    if (adUnit != null) {
      FirebaseCrashlytics.instance.setCustomKey("ad_unit", adUnit);
    }
    if (network != null) {
      FirebaseCrashlytics.instance.setCustomKey("network", _resolveNetwork(network));
    }
    if (retryAttempt != null) {
      FirebaseCrashlytics.instance.setCustomKey("retry_attempt", retryAttempt);
    }
  }

  void trackSessionRevenue(double revenueUSD) {
    logEvent("session_revenue", {
      "revenue": revenueUSD,
    });
  }
}
