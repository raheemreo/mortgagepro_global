// lib/services/ad_free_analytics_tracker.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_service.dart';
import 'crashlytics_service.dart';
import 'ad_free_manager.dart';
import 'remote_config_service.dart';

/// AdFreeAnalyticsTracker — Enterprise-grade tracking layer for Rewarded Ads
/// and Ad-Free Sessions, including active usage tracking, fraud detection,
/// and Crashlytics structured logging.
class AdFreeAnalyticsTracker with WidgetsBindingObserver {
  static final AdFreeAnalyticsTracker instance = AdFreeAnalyticsTracker._();
  AdFreeAnalyticsTracker._();

  static late SharedPreferences _prefs;

  // ── State keys ────────────────────────────────────────────────────────────
  static const String _activeUsageSecondsKey = 'ad_free_analytics_active_seconds';
  static const String _lastRewardTimeKey = 'ad_free_analytics_last_reward_time';
  static const String _lastRequestTimeKey = 'ad_free_analytics_last_request_time';
  static const String _dailyAdCountKey = 'ad_free_analytics_daily_ad_count';
  static const String _dailyAdDateKey = 'ad_free_analytics_daily_ad_date';

  // ── Metrics ───────────────────────────────────────────────────────────────
  int _activeUsageSeconds = 0;
  int _extensionCount = 0;
  Timer? _ticker;
  bool _isAppInForeground = true;

  // ── Fraud Detection Counters ──────────────────────────────────────────────
  DateTime? _lastRewardTime;
  DateTime? _lastRequestTime;
  int _dailyAdCount = 0;
  int _consecutiveFailures = 0;

  /// Initialises the tracker, restores state, and registers observer.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await instance._restoreState();
    WidgetsBinding.instance.addObserver(instance);

    // Initial check for active session at launch
    if (AdFreeManager.instance.isActive) {
      instance._startActiveUsageTimer();
      instance._trackSessionRestored();
    }

    // Set user properties automatically at launch
    await instance._setUserPropertiesAtLaunch();
  }

  Future<void> _restoreState() async {
    _activeUsageSeconds = _prefs.getInt(_activeUsageSecondsKey) ?? 0;
    
    final lastRewardMs = _prefs.getInt(_lastRewardTimeKey);
    if (lastRewardMs != null) {
      _lastRewardTime = DateTime.fromMillisecondsSinceEpoch(lastRewardMs);
    }

    final lastRequestMs = _prefs.getInt(_lastRequestTimeKey);
    if (lastRequestMs != null) {
      _lastRequestTime = DateTime.fromMillisecondsSinceEpoch(lastRequestMs);
    }

    // Daily ad count reset if calendar day has changed
    final savedDate = _prefs.getString(_dailyAdDateKey);
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    if (savedDate == todayStr) {
      _dailyAdCount = _prefs.getInt(_dailyAdCountKey) ?? 0;
    } else {
      _dailyAdCount = 0;
      await _prefs.setString(_dailyAdDateKey, todayStr);
      await _prefs.setInt(_dailyAdCountKey, 0);
    }
  }

  // ── WidgetsBindingObserver ────────────────────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasForeground = _isAppInForeground;
    _isAppInForeground = state == AppLifecycleState.resumed;

    if (AdFreeManager.instance.isActive) {
      if (wasForeground && !_isAppInForeground) {
        _trackActiveUsagePaused();
      } else if (!wasForeground && _isAppInForeground) {
        _trackActiveUsageResumed();
      }
    }
  }

  // ── Ad-Free Session Tracking (Requirement 3) ──────────────────────────────

  /// Call this when a session is successfully restored on app start.
  void _trackSessionRestored() {
    AnalyticsService.instance.logEvent(
      name: 'adfree_session_restored',
      parameters: {
        'remaining_minutes': AdFreeManager.instance.remaining.inMinutes,
        'active_usage_minutes': (_activeUsageSeconds / 60.0).toStringAsFixed(2),
        'country': _getPreferredCountry(),
        'user_type': 'ad_free_active',
      },
    );
  }

  /// Call this when the ad-free session starts.
  void trackSessionStarted() {
    _activeUsageSeconds = 0;
    _extensionCount = 0;
    _prefs.setInt(_activeUsageSecondsKey, 0);

    AnalyticsService.instance.logEvent(
      name: 'adfree_session_started',
      parameters: {
        'duration_minutes': RemoteConfigService.instance.rewardAdFreeDuration,
        'country': _getPreferredCountry(),
        'user_type': 'ad_free_active',
      },
    );

    _startActiveUsageTimer();
    _trackActiveUsageStarted();
  }

  /// Call this when the session is extended inside the warning window.
  void trackSessionExtended() {
    _extensionCount++;
    AnalyticsService.instance.logEvent(
      name: 'adfree_session_extended',
      parameters: {
        'duration_minutes': RemoteConfigService.instance.rewardAdFreeDuration,
        'remaining_minutes': AdFreeManager.instance.remaining.inMinutes,
        'extension_count': _extensionCount,
        'country': _getPreferredCountry(),
        'user_type': 'ad_free_active',
      },
    );
  }

  /// Call this when the session naturally expires.
  void trackSessionExpired() {
    _stopActiveUsageTimer();
    _trackActiveUsageCompleted();

    AnalyticsService.instance.logEvent(
      name: 'adfree_session_expired',
      parameters: {
        'active_usage_minutes': (_activeUsageSeconds / 60.0).toStringAsFixed(2),
        'extension_count': _extensionCount,
        'country': _getPreferredCountry(),
        'user_type': 'free',
      },
    );

    _activeUsageSeconds = 0;
    _prefs.setInt(_activeUsageSecondsKey, 0);
  }

  // ── Active Usage Timer Analytics (Requirement 5) ──────────────────────────

  void _startActiveUsageTimer() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!AdFreeManager.instance.isActive) {
        trackSessionExpired();
        return;
      }

      if (_isAppInForeground) {
        _activeUsageSeconds++;
        if (_activeUsageSeconds % 10 == 0) {
          _prefs.setInt(_activeUsageSecondsKey, _activeUsageSeconds);
        }
      }
    });
  }

  void _stopActiveUsageTimer() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _trackActiveUsageStarted() {
    if (_isAppInForeground) {
      AnalyticsService.instance.logEvent(
        name: 'active_usage_started',
        parameters: {
          'timestamp': DateTime.now().toIso8601String(),
          'country': _getPreferredCountry(),
        },
      );
    }
  }

  void _trackActiveUsagePaused() {
    AnalyticsService.instance.logEvent(
      name: 'active_usage_paused',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
        'accumulated_active_seconds': _activeUsageSeconds,
        'remaining_minutes': AdFreeManager.instance.remaining.inMinutes,
      },
    );
  }

  void _trackActiveUsageResumed() {
    AnalyticsService.instance.logEvent(
      name: 'active_usage_resumed',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
        'accumulated_active_seconds': _activeUsageSeconds,
      },
    );
  }

  void _trackActiveUsageCompleted() {
    AnalyticsService.instance.logEvent(
      name: 'active_usage_completed',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
        'total_active_seconds': _activeUsageSeconds,
        'total_active_minutes': (_activeUsageSeconds / 60.0).toStringAsFixed(2),
      },
    );
  }

  // ── Rewarded Ad Lifecycle & Fraud Tracking (Requirements 2 & 4) ────────────

  /// Tracks a request to load a rewarded ad. Evaluates request frequency
  /// to flag invalid or rapid repeated requests.
  void trackRewardedAdRequested({required String placement}) {
    final now = DateTime.now();

    // Multiple reward requests fraud detection (requesting too fast, e.g., < 15 seconds)
    if (_lastRequestTime != null) {
      final elapsedSec = now.difference(_lastRequestTime!).inSeconds;
      if (elapsedSec < 15) {
        _trackFraudEvent(
          name: 'multiple_reward_requests',
          parameters: {
            'elapsed_seconds': elapsedSec,
            'placement': placement,
          },
        );
      }
    }

    _lastRequestTime = now;
    _prefs.setInt(_lastRequestTimeKey, now.millisecondsSinceEpoch);

    _logAdLifecycleEvent(name: 'rewarded_ad_requested', placement: placement);
    _logFraudEvent(name: 'reward_attempt', placement: placement);
  }

  /// Tracks when a rewarded ad has loaded successfully.
  void trackRewardedAdLoaded({
    required String placement,
    required String adNetwork,
  }) {
    _consecutiveFailures = 0;
    _logAdLifecycleEvent(
      name: 'rewarded_ad_loaded',
      placement: placement,
      adNetwork: adNetwork,
    );
  }

  /// Tracks when a rewarded ad has failed to load. Reports failure to Crashlytics.
  void trackRewardedAdFailed({
    required String placement,
    required String errorCode,
    required String errorMessage,
  }) {
    _consecutiveFailures++;

    _logAdLifecycleEvent(
      name: 'rewarded_ad_failed',
      placement: placement,
      parameters: {
        'error_code': errorCode,
        'error_message': errorMessage,
        'consecutive_failures': _consecutiveFailures,
      },
    );

    // Structured Crashlytics logging for ad load failures
    CrashlyticsService.recordError(
      'RewardedAd failed to load: code=$errorCode, message=$errorMessage',
      StackTrace.current,
      reason: 'AdMob RewardedAd Load Failure in $placement',
      fatal: false,
    );

    if (_consecutiveFailures >= 3) {
      _trackFraudEvent(
        name: 'suspicious_reward_behavior',
        parameters: {
          'reason': 'consecutive_ad_failures',
          'failures_count': _consecutiveFailures,
        },
      );
    }
  }

  /// Tracks when the rewarded ad is presented to the user.
  void trackRewardedAdShown({required String placement}) {
    _logAdLifecycleEvent(name: 'rewarded_ad_shown', placement: placement);
  }

  /// Tracks when the user completes watching the ad.
  void trackRewardedAdCompleted({required String placement}) {
    _logAdLifecycleEvent(name: 'rewarded_ad_completed', placement: placement);
  }

  /// Tracks when the reward is successfully granted. Enforces rate limits
  /// to flag rapid unlocking.
  void trackRewardGranted({required String placement}) {
    final now = DateTime.now();

    // Check for rapid reward unlock fraud (< 5 minutes since last reward)
    if (_lastRewardTime != null) {
      final elapsedMin = now.difference(_lastRewardTime!).inMinutes;
      if (elapsedMin < 5) {
        _trackFraudEvent(
          name: 'rapid_reward_attempt',
          parameters: {
            'elapsed_minutes': elapsedMin,
            'placement': placement,
          },
        );
      }
    }

    _lastRewardTime = now;
    _prefs.setInt(_lastRewardTimeKey, now.millisecondsSinceEpoch);

    _dailyAdCount++;
    _prefs.setInt(_dailyAdCountKey, _dailyAdCount);

    _logAdLifecycleEvent(name: 'rewarded_reward_granted', placement: placement);
    _logFraudEvent(
      name: 'reward_granted',
      placement: placement,
      parameters: {
        'daily_ad_count': _dailyAdCount,
      },
    );

    // Flag overall high usage frequency
    if (_dailyAdCount > 4) {
      _trackFraudEvent(
        name: 'suspicious_reward_behavior',
        parameters: {
          'reason': 'exceeded_daily_watches',
          'daily_ad_count': _dailyAdCount,
        },
      );
    }
  }

  /// Tracks when a reward watch is denied (e.g. cap hit).
  void trackRewardDenied({required String placement, required String reason}) {
    _logFraudEvent(
      name: 'reward_denied',
      placement: placement,
      parameters: {
        'reason': reason,
      },
    );
  }

  /// Tracks when the ad is closed.
  void trackRewardedAdDismissed({required String placement}) {
    _logAdLifecycleEvent(name: 'rewarded_ad_dismissed', placement: placement);
  }

  // ── Helper Logging Methods ────────────────────────────────────────────────

  void _logAdLifecycleEvent({
    required String name,
    required String placement,
    String? adNetwork,
    Map<String, Object>? parameters,
  }) {
    final Map<String, Object> map = {
      'timestamp': DateTime.now().toIso8601String(),
      'ad_placement': placement,
      'country': _getPreferredCountry(),
      'app_version': '1.0.0',
      'session_state': AdFreeManager.instance.isActive ? 'active' : 'inactive',
      'ad_network': adNetwork ?? 'admob',
    };
    if (parameters != null) {
      map.addAll(parameters);
    }
    AnalyticsService.instance.logEvent(name: name, parameters: map);
  }

  void _logFraudEvent({
    required String name,
    required String placement,
    Map<String, Object>? parameters,
  }) {
    final Map<String, Object> map = {
      'timestamp': DateTime.now().toIso8601String(),
      'placement': placement,
      'country': _getPreferredCountry(),
      'ads_watched_daily': _dailyAdCount,
    };
    if (parameters != null) {
      map.addAll(parameters);
    }
    AnalyticsService.instance.logEvent(name: name, parameters: map);
  }

  void _trackFraudEvent({
    required String name,
    required Map<String, Object> parameters,
  }) {
    final Map<String, Object> map = {
      'timestamp': DateTime.now().toIso8601String(),
      'country': _getPreferredCountry(),
      'ads_watched_daily': _dailyAdCount,
    };
    map.addAll(parameters);

    AnalyticsService.instance.logEvent(name: name, parameters: map);

    // Also write a structured log to Crashlytics for manual dashboard reviews
    CrashlyticsService.log('FRAUD DETECTED: event=$name, params=$map');
  }

  String _getPreferredCountry() {
    // Falls back to SharedPreferences key directly to avoid Riverpod build dependency loops
    return _prefs.getString('preferred_country') ?? 'USA';
  }

  /// Sets initial Firebase User Properties on launch.
  Future<void> _setUserPropertiesAtLaunch() async {
    try {
      final country = _prefs.getString('preferred_country') ?? 'USA';
      final currency = _prefs.getString('preferred_currency') ?? 'USD';
      final darkMode = _prefs.getBool('dark_mode') ?? false;

      await AnalyticsService.instance.setUserProperties(
        country: country,
        preferredCurrency: currency,
        preferredTheme: darkMode ? 'dark' : 'light',
        appVersion: '1.0.0+1',
        devicePlatform: Platform.isIOS ? 'ios' : 'android',
      );
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'AdFreeAnalyticsTracker._setUserPropertiesAtLaunch() failed',
      );
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
  }
}
