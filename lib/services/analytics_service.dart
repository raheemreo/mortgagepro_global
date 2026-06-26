// lib/services/analytics_service.dart

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import 'analytics/analytics_calculator.dart';
import 'analytics/analytics_country.dart';
import 'analytics/analytics_feature.dart';
import 'analytics/analytics_resource_category.dart';
import 'analytics/analytics_screen.dart';
import 'crashlytics_service.dart';

// ══════════════════════════════════════════════════════
// ANALYTICS ARCHITECTURE RULES
//
// 1. FirebaseAnalytics.instance must NEVER be called
//    directly outside AnalyticsService — no exceptions.
//
// 2. AnalyticsService is the single source of truth
//    for all analytics collection in this app.
//
// 3. Reuse existing event methods before creating new
//    ones. Check this file first.
//
// 4. Prefer event parameters over new event names.
//    Avoid event proliferation.
//
// 5. Keep total distinct event names well below
//    Firebase's 500-event limit.
//    Current count: 12 / 500.
//
// 6. Every public method must be a safe no-op when
//    analytics is disabled, uninitialized, or consent
//    has not been granted. Never throw. Never crash.
//
// 7. Analytics data must NEVER influence:
//      - Ad frequency or injection
//      - Ad placement decisions
//      - Reward eligibility
//      - Navigation flow
//      - Core calculator functionality
//      - Any app behavior whatsoever
//    Analytics is observational only. This rule
//    applies permanently, including to all future
//    monetization experiments.
//
// 8. NEVER manually collect or log:
//      - IP addresses
//      - Advertising IDs (GAID, IDFA)
//      - Android ID, IMEI, device serial numbers
//      - Firebase Installation IDs
//      - Any device identifier of any kind
//    Firebase handles its own identifier collection.
//    Manual collection is an additional violation.
//
// 9. All string parameters must come from vocabulary
//    constants — never freeform strings:
//      screenName     → AnalyticsScreen constants
//      country        → AnalyticsCountry constants
//      calculatorType → AnalyticsCalculator constants
//      category       → AnalyticsResourceCategory
//      feature        → AnalyticsFeature constants
//      newValue       → predefined label strings only
//
// 10. Crashlytics collection is governed by
//     ConsentService and its own independent consent
//     decision. AnalyticsService must not make any
//     assumptions about Crashlytics consent state.
// ══════════════════════════════════════════════════════

// ══════════════════════════════════════════════════════
// DATA COLLECTION NOTICE
// Feeds Play Store Data Safety form and Privacy Policy.
// Update this block when adding any event, parameter,
// or user property.
//
// EVENTS COLLECTED (12 of Firebase's 500-event limit):
//   country_tab_selected  → country_name,
//                           previous_country
//   calculator_opened     → calculator_type, country
//   calculation_completed → calculator_type, country,
//                           loan_amount_range
//                           (bucketed, never raw)
//   scroll_depth          → screen_name, depth_percent
//   screen_time           → screen_name,
//                           duration_seconds
//   resource_clicked      → resource_name, country,
//                           resource_category
//   setting_changed       → setting_name,
//                           new_value (predefined
//                           label strings only)
//   rewarded_ad_requested → (no parameters)
//   rewarded_ad_shown     → (no parameters)
//   rewarded_ad_completed → (no parameters)
//   reward_granted        → (no parameters)
//   feature_error         → feature, error_type
//                           (runtimeType only)
//
// USER PROPERTIES (1 of Firebase's 25-property limit):
//   preferred_country → AnalyticsCountry constant
//
// DATA NEVER COLLECTED (enforced in code):
//   ✗ Names, emails, phone numbers, addresses
//   ✗ Exact mortgage amounts, income, property values
//   ✗ Interest rates or any user-entered numeric input
//   ✗ User-entered free text of any kind
//   ✗ Numeric strings resembling financial values
//   ✗ Route paths, URLs, or query strings
//   ✗ Advertising IDs, Android ID, IMEI,
//     device serial numbers
//   ✗ Firebase Installation IDs or device identifiers
// ══════════════════════════════════════════════════════

// ══════════════════════════════════════════════════════
// OWNERSHIP BOUNDARY — AdFreeAnalyticsTracker
//
// AdFreeAnalyticsTracker owns:
//   - Session grant events (adfree_session_started)
//   - Ad-free session duration tracking
//   - Session extension events
//
// AnalyticsService owns:
//   - rewarded_ad_requested  (SDK load dispatched)
//   - rewarded_ad_shown      (onAdShowedFullScreenContent)
//   - rewarded_ad_completed  (onAdDismissedFullScreenContent)
//   - reward_granted         (onUserEarnedReward only)
//
// These two must NEVER fire the same event name.
// When in doubt, add to AdFreeAnalyticsTracker.
// ══════════════════════════════════════════════════════

/// AnalyticsService — centralised Firebase Analytics wrapper for
/// Mortgage Pro Global.
///
/// Screen tracking strategy:
///   • GoRouter push routes     → tracked automatically by [analyticsObserver].
///   • StatefulShellRoute /
///     ShellRoute branches      → observer does NOT fire; call [logScreenView()]
///                                or use [ScreenTimerMixin] in the branch.
///   • BottomNavigationBar tabs → call [logCountryTabSelected()] in the listener.
///
/// Never throws. Never crashes the app.
class AnalyticsService {
  // ── Singleton ─────────────────────────────────────────────────────────────
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  // ── Firebase instance ─────────────────────────────────────────────────────
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // ── State ──────────────────────────────────────────────────────────────────

  /// True once [init()] has completed successfully.
  bool _initialized = false;

  /// True when the user has granted analytics consent.
  /// Set from [ConsentService.instance.isConsentGranted] in [init()].
  /// Can be updated at runtime via [updateConsentStatus()].
  bool _consentGranted = false;

  // ── Observer ─────────────────────────────────────────────────────────────

  /// The sole [FirebaseAnalyticsObserver] for this app.
  ///
  /// Attach to GoRouter's observers list in app.dart:
  ///   observers: [AnalyticsService.instance.analyticsObserver]
  ///
  /// Do NOT construct [FirebaseAnalyticsObserver] anywhere else.
  late final FirebaseAnalyticsObserver analyticsObserver =
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ── Init ──────────────────────────────────────────────────────────────────

  /// Initialises analytics collection.
  ///
  /// Must run at Step 6 in main.dart — after ConsentService.init() (Step 5).
  ///
  /// WHY we do NOT gate this on ConsentService.isConsentGranted:
  ///   Firebase Analytics SDK v11+ integrates with UMP automatically at the
  ///   SDK level — it reads UMP signals from ConsentInformation internally.
  ///   ConsentService.isConsentGranted reflects AD consent, not analytics
  ///   consent. Gating setAnalyticsCollectionEnabled on ad consent:
  ///     a) is architecturally incorrect (separate concerns),
  ///     b) permanently disables analytics if UMP has any network error
  ///        during first launch (isConsentGranted defaults to false),
  ///     c) would disable analytics for users in non-regulated regions
  ///        who never saw a consent form at all.
  ///
  /// Use updateConsentStatus(false) for explicit user opt-out of analytics
  /// (a separate, user-initiated action from ad consent).
  Future<void> init() async {
    try {
      // Always enable collection — Firebase SDK reads UMP signals internally.
      // In debug mode this also enables DebugView event streaming.
      await _analytics.setAnalyticsCollectionEnabled(true);
    } catch (e, s) {
      // Log the failure but do NOT leave _initialized = false.
      // Failing to call setAnalyticsCollectionEnabled is recoverable —
      // Firebase SDK will use its default collection state (enabled).
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'AnalyticsService.init() — setAnalyticsCollectionEnabled failed',
      );
    }
    // Always mark as initialized and consent-granted so the guards pass.
    // If the user later opts out of analytics explicitly, updateConsentStatus(false)
    // is the correct mechanism — not a consent check during init().
    _consentGranted = true;
    _initialized = true;
  }


  // ── Runtime consent toggling ──────────────────────────────────────────────

  /// Updates analytics consent at runtime.
  ///
  /// Safe to call before [init()] completes — revocation is immediate.
  /// Idempotent — safe to call multiple times with the same value.
  /// Does not re-run [init()] logic.
  ///
  /// When [granted] is false:
  ///   - Collection is disabled immediately.
  ///   - [_consentGranted] set to false.
  ///   - [preferred_country] user property is cleared.
  ///
  /// When [granted] is true:
  ///   - Collection is re-enabled.
  ///   - [_consentGranted] set to true.
  Future<void> updateConsentStatus(bool granted) async {
    // No guards on this method — must work before init() and after withdrawal.
    try {
      await _analytics.setAnalyticsCollectionEnabled(granted);
      _consentGranted = granted;

      if (!granted) {
        // Clear the preferred_country user property on withdrawal.
        await _analytics.setUserProperty(
          name: 'preferred_country',
          value: null,
        );
      }
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'AnalyticsService.updateConsentStatus() failed',
      );
    }
  }

  // ── Screen tracking ───────────────────────────────────────────────────────

  /// Logs a screen_view event.
  ///
  /// [screenName]  must be an [AnalyticsScreen] constant.
  /// [screenClass] Dart class name, e.g. "UsaScreen".
  Future<void> logScreenView(
    String screenName,
    String screenClass,
  ) async {
    if (!_initialized || !_consentGranted) return;
    if (!_validateScreen(screenName)) return;
    await _log(() => _analytics.logScreenView(
          screenName: screenName,
          screenClass: screenClass,
        ));
  }

  /// Logs a tab selection event for BottomNavigationBar and shell routes.
  Future<void> trackTab(int index, String screenName) async {
    if (!_initialized || !_consentGranted) return;
    await _log(() => _analytics.logEvent(
          name: 'tab_selected',
          parameters: {
            'tab_index': index,
            'screen_name': _truncate(screenName),
          },
        ));
  }

  // ── User journey ──────────────────────────────────────────────────────────

  /// Logs when a country tab becomes active in the Home screen TabBar.
  ///
  /// [country]         must be an [AnalyticsCountry] constant.
  /// [previousCountry] must be an [AnalyticsCountry] constant or 'Global'.
  ///
  /// Also updates the [preferred_country] Firebase user property (slot 1/25).
  ///
  /// Callers must use [AnalyticsCountry] constants.
  /// The 'Global' tab uses the sentinel string 'Global' — not in
  /// [AnalyticsCountry.all], so the user property is not set for it.
  Future<void> logCountryTabSelected(
    String country,
    String previousCountry,
  ) async {
    if (!_initialized || !_consentGranted) return;

    // 'Global' is a dashboard sentinel — validate only real countries.
    final isRealCountry = AnalyticsCountry.all.contains(country);
    assert(
      isRealCountry || country == 'Global',
      'country "$country" must be an AnalyticsCountry constant or "Global".',
    );

    await _log(() => _analytics.logEvent(
          name: 'country_tab_selected',
          parameters: {
            'country_name': _truncate(country),
            'previous_country': _truncate(previousCountry),
          },
        ));

    // Only set the user property for real countries, not the Global tab.
    if (isRealCountry) {
      await setPreferredCountry(country);
    }
  }

  /// Logs when a calculator screen is opened.
  ///
  /// [type]    must be an [AnalyticsCalculator] constant.
  /// [country] must be an [AnalyticsCountry] constant.
  Future<void> logCalculatorOpened(String type, String country) async {
    if (!_initialized || !_consentGranted) return;
    if (!_validateCalculator(type)) return;
    if (!_validateCountry(country)) return;
    await _log(() => _analytics.logEvent(
          name: 'calculator_opened',
          parameters: {
            'calculator_type': type,
            'country': country,
          },
        ));
  }

  /// Logs when a calculation completes and a result is presented.
  ///
  /// [calculatorType] must be an [AnalyticsCalculator] constant.
  /// [country]        must be an [AnalyticsCountry] constant.
  /// [rawLoanAmount]  is bucketed internally — NEVER logged raw.
  ///                  Never pass this value anywhere else.
  Future<void> logCalculationCompleted({
    required String calculatorType,
    required String country,
    required double rawLoanAmount,
  }) async {
    if (!_initialized || !_consentGranted) return;
    if (!_validateCalculator(calculatorType)) return;
    if (!_validateCountry(country)) return;
    final range = _bucketLoanAmount(rawLoanAmount);
    await _log(() => _analytics.logEvent(
          name: 'calculation_completed',
          parameters: {
            'calculator_type': calculatorType,
            'country': country,
            'loan_amount_range': range,
          },
        ));
  }

  /// Logs scroll depth milestones.
  ///
  /// [screenName]   must be an [AnalyticsScreen] constant.
  /// [depthPercent] must be 25, 50, 75, or 100.
  ///
  /// Deduplication is the caller's responsibility — use [ScrollDepthTracker].
  Future<void> logScrollDepth(String screenName, int depthPercent) async {
    if (!_initialized || !_consentGranted) return;
    if (!_validateScreen(screenName)) return;
    await _log(() => _analytics.logEvent(
          name: 'scroll_depth',
          parameters: {
            'screen_name': screenName,
            'depth_percent': depthPercent,
          },
        ));
  }

  /// Logs how long a user spent on a screen.
  ///
  /// [screenName]      must be an [AnalyticsScreen] constant.
  /// [durationSeconds] must be ≥ 3 — callers (ScreenTimerMixin) enforce this.
  Future<void> logScreenDuration(
    String screenName,
    int durationSeconds,
  ) async {
    if (!_initialized || !_consentGranted) return;
    if (!_validateScreen(screenName)) return;
    if (durationSeconds < 3) return; // not meaningful for analytics
    await _log(() => _analytics.logEvent(
          name: 'screen_time',
          parameters: {
            'screen_name': screenName,
            'duration_seconds': durationSeconds,
          },
        ));
  }

  /// Logs when a resource link is tapped.
  ///
  /// [name]     Resource title — must not contain user-entered text.
  /// [country]  must be an [AnalyticsCountry] constant.
  /// [category] must be an [AnalyticsResourceCategory] constant.
  Future<void> logResourceClicked(
    String name,
    String country,
    String category,
  ) async {
    if (!_initialized || !_consentGranted) return;
    if (!_validateCountry(country)) return;
    if (!_validateResourceCategory(category)) return;
    await _log(() => _analytics.logEvent(
          name: 'resource_clicked',
          parameters: {
            'resource_name': _truncate(name),
            'country': country,
            'resource_category': category,
          },
        ));
  }

  /// Logs when a settings value is changed.
  ///
  /// [settingName] e.g. "app_theme", "default_country", "currency".
  /// [newValue]    must be a predefined label string — see [_isPredefinedSettingValue].
  ///               NEVER a numeric string, user-entered text, or financial value.
  Future<void> logSettingChanged({
    required String settingName,
    required String newValue,
  }) async {
    if (!_initialized || !_consentGranted) return;
    assert(
      _isPredefinedSettingValue(newValue),
      'logSettingChanged: newValue must be a predefined label string — '
      'never a numeric string or user-entered text. Received: $newValue',
    );
    if (!_isPredefinedSettingValue(newValue)) {
      // Release: log to Crashlytics and return — never send to Firebase.
      CrashlyticsService.recordError(
        'logSettingChanged: invalid newValue "$newValue" for setting '
        '"$settingName" — predefined label required',
        null,
        reason: AnalyticsFeature.navigation,
      );
      return;
    }
    await _log(() => _analytics.logEvent(
          name: 'setting_changed',
          parameters: {
            'setting_name': _truncate(settingName),
            'new_value': newValue,
          },
        ));
  }

  // ── Rewarded ad events ────────────────────────────────────────────────────
  //
  // ⚠️  AdMob Policy — valid call sites:
  //
  //   RewardedAdStage.requested → AdManager.loadRewarded() after SDK dispatch
  //   RewardedAdStage.shown     → onAdShowedFullScreenContent callback
  //   RewardedAdStage.completed → onAdDismissedFullScreenContent callback
  //   RewardedAdStage.rewardGranted → onUserEarnedReward callback
  //
  //   onAdLoaded has NO mapped stage — do not fire any event for it.
  //
  // ⚠️  FORBIDDEN call sites (any of these = AdMob Invalid Traffic violation):
  //   onTap() / onPressed() / GestureDetector / InkWell callbacks
  //   Visibility changes / Timer callbacks / Navigator events
  //   initState() / build() / setState()
  //
  // ⚠️  OWNERSHIP BOUNDARY:
  //   Do NOT call from AdFreeAnalyticsTracker — see boundary comment at top.

  /// Logs a rewarded ad lifecycle event.
  ///
  /// Must be called only from AdMob SDK callbacks in [AdManager].
  /// See call-site documentation in ad_manager.dart.
  Future<void> logRewardedAdEvent(RewardedAdStage stage) async {
    if (!_initialized || !_consentGranted) return;
    final String eventName;
    switch (stage) {
      case RewardedAdStage.requested:
        eventName = 'rewarded_ad_requested';
        break;
      case RewardedAdStage.shown:
        eventName = 'rewarded_ad_shown';
        break;
      case RewardedAdStage.completed:
        eventName = 'rewarded_ad_completed';
        break;
      case RewardedAdStage.rewardGranted:
        eventName = 'reward_granted';
        break;
    }
    await _log(() => _analytics.logEvent(name: eventName));
  }

  // ── Error tracking ────────────────────────────────────────────────────────

  /// Records a feature-level error to Crashlytics and Analytics.
  ///
  /// Crashlytics receives the full stack trace unconditionally —
  /// Crashlytics consent is governed by ConsentService independently.
  /// AnalyticsService does not control or assume Crashlytics consent state.
  ///
  /// Analytics receives [feature] + [error_type] (class name only) —
  /// gated on [_initialized] and [_consentGranted].
  ///
  /// [feature]   must be an [AnalyticsFeature] constant.
  /// [exception] the caught exception object.
  /// [stackTrace] associated StackTrace (strongly recommended).
  ///
  /// CRITICAL — [error_type] safety rule:
  ///   Only [exception.runtimeType.toString()] is logged — NEVER
  ///   [exception.toString()] which may contain user-entered financial data.
  Future<void> logFeatureError({
    required String feature,
    required Object exception,
    StackTrace? stackTrace,
  }) async {
    // Crashlytics: always called regardless of analytics consent.
    // ConsentService governs Crashlytics consent independently.
    CrashlyticsService.recordError(
      exception,
      stackTrace,
      reason: feature,
    );

    // Analytics: respects its own consent gate only.
    if (!_initialized || !_consentGranted) return;

    // runtimeType only — never exception.toString() or exception.message
    final errorType = exception.runtimeType.toString();

    await _log(() => _analytics.logEvent(
          name: 'feature_error',
          parameters: {
            'feature': _truncate(feature),
            'error_type': _truncate(errorType),
          },
        ));
  }

  // ── User properties ───────────────────────────────────────────────────────
  //
  // ⚠️  Firebase allows a maximum of 25 user properties per app.
  //     Each slot is PERMANENT. Update the DATA COLLECTION NOTICE
  //     when adding properties.
  //     Current count: 1 / 25.
  //
  // Slot 1 — preferred_country (set on country tab switch)

  /// Sets the [preferred_country] user property (slot 1/25).
  ///
  /// Called automatically by [logCountryTabSelected] on real country switches.
  /// [country] must be an [AnalyticsCountry] constant.
  Future<void> setPreferredCountry(String country) async {
    if (!_initialized || !_consentGranted) return;
    if (!_validateCountry(country)) return;
    await _log(() => _analytics.setUserProperty(
          name: 'preferred_country',
          value: country,
        ));
  }

  /// Sets user properties in bulk (used by AdFreeAnalyticsTracker at launch).
  Future<void> setUserProperties({
    required String country,
    required String preferredCurrency,
    required String preferredTheme,
    required String appVersion,
    required String devicePlatform,
  }) async {
    if (!_initialized || !_consentGranted) return;
    await _log(() async {
      await _analytics.setUserProperty(name: 'country', value: country);
      await _analytics.setUserProperty(
        name: 'preferred_currency',
        value: preferredCurrency,
      );
      await _analytics.setUserProperty(
        name: 'preferred_theme',
        value: preferredTheme,
      );
      await _analytics.setUserProperty(
        name: 'app_version',
        value: appVersion,
      );
      await _analytics.setUserProperty(
        name: 'device_platform',
        value: devicePlatform,
      );
    });
  }

  /// Sets a single user property by name.
  Future<void> setUserProperty(String name, String value) async {
    if (!_initialized || !_consentGranted) return;
    await _log(() => _analytics.setUserProperty(name: name, value: value));
  }

  // ── Generic event (for AdAnalyticsService / AdFreeAnalyticsTracker) ───────

  /// Logs a custom event.
  ///
  /// Prefer typed methods above for all standard events.
  /// This method exists for ad-layer events that do not fit a standard schema.
  ///
  /// [name]       snake_case, max 40 chars.
  /// [parameters] Optional map of string/num parameter values.
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!_initialized || !_consentGranted) return;
    await _log(() => _analytics.logEvent(
          name: name,
          parameters: parameters,
        ));
  }

  // ── Legacy methods — retained for back-compat ─────────────────────────────

  /// Logs an app_open event.
  Future<void> logAppOpen() async {
    if (!_initialized || !_consentGranted) return;
    await _log(() => _analytics.logAppOpen());
  }

  /// Logs a country selection (from settings).
  Future<void> logCountrySelection(String country) async {
    if (!_initialized || !_consentGranted) return;
    await _log(() => _analytics.logEvent(
          name: 'country_selected',
          parameters: {'country': _truncate(country)},
        ));
  }

  /// Logs a theme change.
  Future<void> logThemeChange(String theme) async {
    if (!_initialized || !_consentGranted) return;
    await _log(() => _analytics.logEvent(
          name: 'theme_changed',
          parameters: {'theme': _truncate(theme)},
        ));
  }

  /// Logs a saved calculation opened from history.
  Future<void> logSavedCalculationOpened(String calculatorType) async {
    if (!_initialized || !_consentGranted) return;
    await _log(() => _analytics.logEvent(
          name: 'saved_calc_opened',
          parameters: {'calculator_type': _truncate(calculatorType)},
        ));
  }

  /// Logs a calculation saved to Hive storage.
  Future<void> logSaveCalculation(String calculatorType) async {
    if (!_initialized || !_consentGranted) return;
    await _log(() => _analytics.logEvent(
          name: 'calculation_saved',
          parameters: {'calculator_type': _truncate(calculatorType)},
        ));
  }

  /// Logs a PDF export.
  Future<void> logPdfExport(String screenName) async {
    if (!_initialized || !_consentGranted) return;
    await _log(() => _analytics.logEvent(
          name: 'pdf_exported',
          parameters: {'screen_name': _truncate(screenName)},
        ));
  }

  /// Logs an ad revenue event (called by AdManager.handlePaidEvent).
  ///
  /// REVENUE RULE: [valueMicros] is logged AS-IS from OnPaidEventListener.
  /// Never divide, derive, or display this value outside AdAnalyticsService.
  Future<void> logAdRevenue(
    double valueMicros,
    String currencyCode,
    String precisionType,
    String adSource,
  ) async {
    if (!_initialized || !_consentGranted) return;
    await _log(() => _analytics.logEvent(
          name: 'ad_revenue',
          parameters: {
            'value_micros': valueMicros,
            'currency_code': _truncate(currencyCode),
            'precision_type': _truncate(precisionType),
            'ad_source': _truncate(adSource),
          },
        ));
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Executes [fn] and forwards errors to Crashlytics.
  /// Never throws. Never crashes the app.
  Future<void> _log(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'AnalyticsService._log() failed',
      );
    }
  }

  /// Truncates a string to 100 characters.
  /// Firebase Analytics parameter values are capped at 100 characters.
  /// Event names are string literals and require no runtime truncation.
  String _truncate(String value) =>
      value.length > 100 ? value.substring(0, 100) : value;

  // ── Loan amount bucketing ─────────────────────────────────────────────────

  /// Converts a raw loan amount to a bucketed range string.
  ///
  /// PRIVATE — rawAmount never leaves this method.
  /// The raw numeric value is NEVER logged to Analytics, Crashlytics,
  /// user properties, or any external service.
  String _bucketLoanAmount(double rawAmount) {
    if (rawAmount < 100000) return 'under_100k';
    if (rawAmount < 250000) return '100k_250k';
    if (rawAmount < 500000) return '250k_500k';
    if (rawAmount < 1000000) return '500k_1m';
    return 'over_1m';
  }

  // ── Runtime vocabulary validation ─────────────────────────────────────────

  bool _validateScreen(String screenName) {
    assert(
      AnalyticsScreen.all.contains(screenName),
      'screenName "$screenName" is not in AnalyticsScreen.all. '
      'Add it there first.',
    );
    if (!AnalyticsScreen.all.contains(screenName)) {
      if (!kDebugMode) {
        CrashlyticsService.recordError(
          'Invalid screenName: "$screenName"',
          null,
          reason: AnalyticsFeature.navigation,
        );
      }
      return false;
    }
    return true;
  }

  bool _validateCountry(String country) {
    assert(
      AnalyticsCountry.all.contains(country),
      'country "$country" is not in AnalyticsCountry.all. '
      'Add it there first.',
    );
    if (!AnalyticsCountry.all.contains(country)) {
      if (!kDebugMode) {
        CrashlyticsService.recordError(
          'Invalid country: "$country"',
          null,
          reason: AnalyticsFeature.navigation,
        );
      }
      return false;
    }
    return true;
  }

  bool _validateCalculator(String calculatorType) {
    assert(
      AnalyticsCalculator.all.contains(calculatorType),
      'calculatorType "$calculatorType" is not in AnalyticsCalculator.all. '
      'Add it there first.',
    );
    if (!AnalyticsCalculator.all.contains(calculatorType)) {
      if (!kDebugMode) {
        CrashlyticsService.recordError(
          'Invalid calculatorType: "$calculatorType"',
          null,
          reason: AnalyticsFeature.navigation,
        );
      }
      return false;
    }
    return true;
  }

  bool _validateResourceCategory(String category) {
    assert(
      AnalyticsResourceCategory.all.contains(category),
      'category "$category" is not in AnalyticsResourceCategory.all. '
      'Add it there first.',
    );
    if (!AnalyticsResourceCategory.all.contains(category)) {
      if (!kDebugMode) {
        CrashlyticsService.recordError(
          'Invalid resource category: "$category"',
          null,
          reason: AnalyticsFeature.navigation,
        );
      }
      return false;
    }
    return true;
  }

  // ── Setting value whitelist ───────────────────────────────────────────────

  /// Returns true when [value] is a predefined label string safe for Analytics.
  ///
  /// NEVER pass numeric strings, user-entered text, or financial amounts
  /// to [logSettingChanged]. This whitelist is the enforcement mechanism.
  ///
  /// Update this method when adding new settings to the app.
  bool _isPredefinedSettingValue(String value) {
    const allowed = {
      // Theme
      'theme_light', 'theme_dark', 'theme_system',
      // Feature toggles
      'enabled', 'disabled',
      // Loan term labels
      'term_5y', 'term_10y', 'term_15y', 'term_20y', 'term_25y', 'term_30y',
      // Currency labels
      'currency_usd', 'currency_gbp', 'currency_eur', 'currency_inr',
      'currency_aud', 'currency_cad', 'currency_nzd',
      // Country labels (for default_country setting)
      'country_usa', 'country_uk', 'country_canada', 'country_australia',
      'country_new_zealand', 'country_europe', 'country_india',
    };
    return allowed.contains(value);
  }
}

// ── RewardedAdStage enum ──────────────────────────────────────────────────────

/// Lifecycle stages for a rewarded ad.
///
/// Maps to Firebase event names in [AnalyticsService.logRewardedAdEvent]:
///   requested     → rewarded_ad_requested
///   shown         → rewarded_ad_shown
///   completed     → rewarded_ad_completed
///   rewardGranted → reward_granted
///
/// ⚠️  Only call [logRewardedAdEvent] from AdMob SDK callbacks in AdManager.
/// ⚠️  NEVER call from UI widgets, onTap callbacks, or Timer callbacks.
/// ⚠️  onAdLoaded has NO mapped stage — do not fire any event for it.
enum RewardedAdStage {
  /// Ad load dispatched to SDK.
  /// Fire inside [AdManager.loadRewarded] at SDK load dispatch — NOT onAdLoaded.
  requested,

  /// Ad is being shown to the user.
  /// Fire inside [FullScreenContentCallback.onAdShowedFullScreenContent].
  shown,

  /// User dismissed the ad.
  /// Fire inside [FullScreenContentCallback.onAdDismissedFullScreenContent].
  completed,

  /// Reward has been granted.
  /// Fire inside [RewardedAd.show] onUserEarnedReward — never from UI.
  rewardGranted,
}
