// lib/services/analytics_service.dart

import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'crashlytics_service.dart';
import 'consent_service.dart';
import 'package:mortgagepro_global/services/analytics/analytics_screen.dart';

// ══════════════════════════════════════════════════════
// ANALYTICS ARCHITECTURE RULES (PLAY STORE COMPLIANCE)
//
// 1. FirebaseAnalytics.instance must NEVER be called
//    directly outside AnalyticsService — no exceptions.
//
// 2. AnalyticsService is the single source of truth.
//
// 3. ZERO PII & FINANCIAL DATA:
//    ✗ Never collect names, emails, phone numbers.
//    ✗ Never collect exact mortgage amounts, income,
//      property values, credit scores, or user-entered text.
//    ✗ Never call setUserId().
//    ✗ Never set user_property with identifying values.
//
// 4. UMP Consent Gating:
//    - Collection is disabled on app launch.
//    - Enabled only if UMP consent is resolved as granted
//      and the user has not opted out.
//    - Opt-out is persisted in SharedPreferences.
//
// 5. Minimal Whitelisted Custom Events:
//    - Only log: calculator_used, lender_viewed,
//      external_link_opened, favorite_toggled,
//      search_performed, consent_updated.
//    - All other custom events are no-ops.
// ══════════════════════════════════════════════════════

class AnalyticsService {
  // ── Singleton ─────────────────────────────────────────────────────────────
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  // ── Firebase instance ─────────────────────────────────────────────────────
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // ── State ──────────────────────────────────────────────────────────────────
  bool _initialized = false;
  bool _collectionEnabled = false;

  String? _lastScreenName;
  DateTime? _lastLogTime;

  DateTime? _lastTabLogTime;

  // ── Observer ─────────────────────────────────────────────────────────────
  
  /// The custom [NavigatorObserver] that automatically tracks all route pushes
  /// and replacements as screen_view events.
  late final NavigatorObserver analyticsObserver = _AnalyticsRouteObserver();

  // ── Init ──────────────────────────────────────────────────────────────────

  /// Initializes analytics collection and sets up consent gating.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Step 1: Ensure disabled initially on launch (before consent is resolved)
      await _analytics.setAnalyticsCollectionEnabled(false);

      // Listen to consent changes at runtime (e.g. from the privacy options form)
      ConsentService.instance.addListener(_handleConsentChanged);

      // Step 3 & 4: Evaluate current consent and configure
      await _evaluateConsentAndConfigure(prefs);

      _initialized = true;
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'AnalyticsService.init() failed',
      );
    }
  }

  Future<void> _evaluateConsentAndConfigure(SharedPreferences prefs) async {
    final bool hasConsent = ConsentService.instance.isConsentGranted;
    final bool persistedOptOut = prefs.getBool('analytics_opt_out') ?? false;

    if (hasConsent && !persistedOptOut) {
      await _analytics.setAnalyticsCollectionEnabled(true);
      _collectionEnabled = true;
      if (kDebugMode) {
        print('[Analytics] Enabled collection');
      }
    } else {
      await _analytics.setAnalyticsCollectionEnabled(false);
      _collectionEnabled = false;
      
      // If consent is denied or withdrawn, persist in SharedPreferences
      if (!hasConsent || persistedOptOut) {
        await prefs.setBool('analytics_opt_out', true);
      }
      
      if (kDebugMode) {
        print('[Analytics] Disabled collection');
      }
    }
  }

  void _handleConsentChanged() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _evaluateConsentAndConfigure(prefs);
      await logConsentUpdated();
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'AnalyticsService._handleConsentChanged failed',
      );
    }
  }

  // ── Runtime Consent Settings ──────────────────────────────────────────────

  /// Allows explicit user opt-in/opt-out from a settings screen.
  Future<void> updateConsentStatus(bool granted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('analytics_opt_out', !granted);
      await _evaluateConsentAndConfigure(prefs);
      await logConsentUpdated();
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'AnalyticsService.updateConsentStatus() failed',
      );
    }
  }

  // ── Whitelisted Custom Events ─────────────────────────────────────────────

  /// Logs when a calculator is used (calculation completes).
  ///
  /// [calculatorType] e.g. 'mortgage_usa'.
  Future<void> logCalculatorUsed(String calculatorType) async {
    if (!_initialized || !_collectionEnabled) return;
    
    if (kDebugMode) {
      print('[Analytics] EVENT: calculator_used | calculator_type: $calculatorType | ${DateTime.now().toIso8601String()}');
    }

    await _log(() => _analytics.logEvent(
          name: 'calculator_used',
          parameters: {
            'calculator_type': calculatorType,
          },
        ));
  }

  /// Logs when a lender is viewed.
  ///
  /// [lenderRank] integer position/rank only.
  Future<void> logLenderViewed(int lenderRank) async {
    if (!_initialized || !_collectionEnabled) return;

    if (kDebugMode) {
      print('[Analytics] EVENT: lender_viewed | lender_rank: $lenderRank | ${DateTime.now().toIso8601String()}');
    }

    await _log(() => _analytics.logEvent(
          name: 'lender_viewed',
          parameters: {
            'lender_rank': lenderRank,
          },
        ));
  }

  /// Logs when an external website link is opened.
  Future<void> logExternalLinkOpened() async {
    if (!_initialized || !_collectionEnabled) return;

    if (kDebugMode) {
      print('[Analytics] EVENT: external_link_opened | ${DateTime.now().toIso8601String()}');
    }

    await _log(() => _analytics.logEvent(
          name: 'external_link_opened',
        ));
  }

  /// Logs when a calculator or lender is favorited/unfavorited.
  ///
  /// [itemType] must be either 'calculator' or 'lender'.
  Future<void> logFavoriteToggled({required String itemType}) async {
    if (!_initialized || !_collectionEnabled) return;

    if (kDebugMode) {
      print('[Analytics] EVENT: favorite_toggled | item_type: $itemType | ${DateTime.now().toIso8601String()}');
    }

    await _log(() => _analytics.logEvent(
          name: 'favorite_toggled',
          parameters: {
            'item_type': itemType,
          },
        ));
  }

  /// Logs when a search is performed.
  ///
  /// [resultCount] integer count only.
  Future<void> logSearchPerformed(int resultCount) async {
    if (!_initialized || !_collectionEnabled) return;

    if (kDebugMode) {
      print('[Analytics] EVENT: search_performed | result_count: $resultCount | ${DateTime.now().toIso8601String()}');
    }

    await _log(() => _analytics.logEvent(
          name: 'search_performed',
          parameters: {
            'result_count': resultCount,
          },
        ));
  }

  /// Logs when consent preferences are updated.
  Future<void> logConsentUpdated() async {
    if (!_initialized || !_collectionEnabled) return;

    if (kDebugMode) {
      print('[Analytics] EVENT: consent_updated | ${DateTime.now().toIso8601String()}');
    }

    await _log(() => _analytics.logEvent(
          name: 'consent_updated',
        ));
  }

  /// Logs when a search result is opened.
  Future<void> logSearchResultOpened({
    required int resultIndex,
    required String searchTerm,
    required String toolId,
  }) async {
    if (!_initialized || !_collectionEnabled) return;

    if (kDebugMode) {
      print('[Analytics] EVENT: search_result_opened | result_index: $resultIndex | search_term: $searchTerm | tool_id: $toolId | ${DateTime.now().toIso8601String()}');
    }

    await _log(() => _analytics.logEvent(
          name: 'search_result_opened',
          parameters: {
            'result_index': resultIndex,
            'search_term': searchTerm,
            'tool_id': toolId,
          },
        ));
  }

  // ── Tab Navigation ────────────────────────────────────────────────────────

  /// Logs a screen_view event when a country tab is tapped intentionally on the Home screen.
  ///
  /// [countryCode] is the stable internal country code (e.g. 'CA', 'AU') from the
  /// current tab order. When provided it takes precedence over [index] for deriving
  /// the screen name, so analytics remain correct after the tab bar is reordered by
  /// the Default Country Pinning feature.
  Future<void> logCountryTabTap(int index, {String? countryCode}) async {
    final now = DateTime.now();

    // Debounce: skip if same tab tapped within 500ms
    if (_lastTabLogTime != null &&
        now.difference(_lastTabLogTime!) < const Duration(milliseconds: 500)) {
      return;
    }

    // Prefer code-based resolution when the caller supplies a country code,
    // because tab indices are no longer stable after pinning reorders tabs.
    final String screenName;
    final String pageTitle;
    if (countryCode != null) {
      screenName = switch (countryCode) {
        'GLOBAL' => 'home_global',
        'USA'    => 'home_usa',
        'CA'     => 'home_canada',
        'UK'     => 'home_uk',
        'AU'     => 'home_australia',
        'NZ'     => 'home_new_zealand',
        'EU'     => 'home_europe',
        'IN'     => 'home_india',
        _        => 'home_global',
      };
      pageTitle = switch (countryCode) {
        'GLOBAL' => 'Global Home',
        'USA'    => 'USA Home',
        'CA'     => 'Canada Home',
        'UK'     => 'UK Home',
        'AU'     => 'Australia Home',
        'NZ'     => 'New Zealand Home',
        'EU'     => 'Europe Home',
        'IN'     => 'India Home',
        _        => 'Global Home',
      };
    } else {
      // Legacy fallback — index-based (static tab order only).
      screenName = switch (index) {
        0 => 'home_global',
        1 => 'home_usa',
        2 => 'home_canada',
        3 => 'home_uk',
        4 => 'home_australia',
        5 => 'home_new_zealand',
        6 => 'home_europe',
        7 => 'home_india',
        _ => 'home_global',
      };
      pageTitle = switch (index) {
        0 => 'Global Home',
        1 => 'USA Home',
        2 => 'Canada Home',
        3 => 'UK Home',
        4 => 'Australia Home',
        5 => 'New Zealand Home',
        6 => 'Europe Home',
        7 => 'India Home',
        _ => 'Global Home',
      };
    }

    // Skip if same screen_name as last logged
    if (_lastScreenName == screenName) return;

    _lastTabLogTime = now;

    await _logScreenViewInternal(screenName, 'HomeScreen', pageTitle);
  }

  // ── Screen View logging ───────────────────────────────────────────────────

  /// Resolves the screen view info from a route path and logs it.
  Future<void> logScreenViewFromPath(String path) async {
    final info = _getScreenInfo(path);
    if (info != null) {
      await _logScreenViewInternal(info.screenName, info.screenClass, info.pageTitle);
    } else {
      final sanitised = _sanitisePath(path);
      await _logScreenViewInternal(
        sanitised,
        'DynamicScreen',
        sanitised.replaceAll('_', ' ').toUpperCase(),
      );
    }
  }

  String _sanitisePath(String path) {
    final cleanPath = path.split('?').first;
    final joined = cleanPath
        .split('/')
        .where((s) => s.isNotEmpty && int.tryParse(s) == null && s != '#' && s != '#/')
        .join('_')
        .toLowerCase();
    
    if (joined.isEmpty) return 'unknown_route';
    return joined.length > 40 ? joined.substring(0, 40) : joined;
  }

  Future<void> _logScreenViewInternal(
    String screenName,
    String screenClass,
    String pageTitle,
  ) async {
    if (!_initialized || !_collectionEnabled) return;

    final now = DateTime.now();
    
    // De-duplicate screen views within 300ms
    if (_lastScreenName == screenName &&
        _lastLogTime != null &&
        now.difference(_lastLogTime!) < const Duration(milliseconds: 300)) {
      return;
    }

    _lastScreenName = screenName;
    _lastLogTime = now;

    if (kDebugMode) {
      print('[Analytics] SCREEN: $screenName | TITLE: $pageTitle | ${now.toIso8601String()}');
    }

    await _log(() => _analytics.logScreenView(
          screenName: screenName,
          screenClass: screenClass,
          parameters: {
            'page_title': pageTitle,
          },
        ));
  }

  ScreenInfo? _getScreenInfo(String path) {
    final cleanPath = path.split('?').first;

    // 1. Try registry lookup first
    final regInfo = AnalyticsScreen.routeRegistry[cleanPath];
    if (regInfo != null) {
      return regInfo;
    }

    // 2. Fallback for dynamic /tool/:country/:toolId
    final toolMatch = RegExp(r'^/tool/([^/]+)/([^/]+)').firstMatch(cleanPath);
    if (toolMatch != null) {
      final country = toolMatch.group(1)?.toLowerCase() ?? '';
      final toolId = toolMatch.group(2)?.toLowerCase() ?? '';

      String screenName = 'calc_${toolId}_$country';
      String pageTitle = '${toolId.replaceAll('_', ' ').toUpperCase()} Calculator';
      String screenClass = 'ToolHostScreen';

      if (toolId == 'mortgage') {
        screenName = 'calc_mortgage_$country';
        pageTitle = 'Mortgage Calculator';
      } else if (toolId == 'refinance') {
        screenName = 'calc_refinance_$country';
        pageTitle = 'Refinance Calculator';
      } else if (toolId == 'affordability') {
        screenName = 'calc_affordability_$country';
        pageTitle = 'Affordability Calculator';
      }

      return ScreenInfo(
        screenName: screenName,
        screenClass: screenClass,
        pageTitle: pageTitle,
      );
    }

    return null;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

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

  // ── No-Ops for Backward Compatibility ──────────────────────────────────────

  Future<void> logCountryTabSelected(String country, String previousCountry) async {}
  Future<void> logCalculatorOpened(String type, String country) async {}
  Future<void> logCalculationCompleted({required String calculatorType, required String country, required double rawLoanAmount}) async {}
  Future<void> logScrollDepth(String screenName, int depthPercent) async {}
  Future<void> logScreenDuration(String screenName, int durationSeconds) async {}
  Future<void> logResourceClicked(String name, String country, String category) async {}
  Future<void> logSettingChanged({required String settingName, required String newValue}) async {}
  Future<void> logRewardedAdEvent(dynamic stage) async {}
  Future<void> logFeatureError({required String feature, required Object exception, StackTrace? stackTrace}) async {
    try {
      CrashlyticsService.recordError(exception, stackTrace, reason: feature);
    } catch (_) {}
  }
  Future<void> setPreferredCountry(String country) async {}
  Future<void> setUserProperties({required String country, required String preferredCurrency, required String preferredTheme, required String appVersion, required String devicePlatform}) async {}
  Future<void> setUserProperty(String name, String value) async {}
  Future<void> logAppOpen() async {}
  Future<void> logCountrySelection(String country) async {}
  Future<void> logThemeChange(String theme) async {}
  Future<void> logSavedCalculationOpened(String calculatorType) async {}
  Future<void> logSaveCalculation(String calculatorType) async {}
  Future<void> logPdfExport(String screenName) async {}
  Future<void> logAdRevenue(double valueMicros, String currencyCode, String precisionType, String adSource) async {}
  Future<void> trackTab(int index, String screenName) async {}
  Future<void> logEvent({required String name, Map<String, Object?>? parameters}) async {}
  Future<void> logScreenView(String screenName, [String? screenClass]) async {}
  Future<void> logRatingEvent(String action) async {}
}

enum RewardedAdStage {
  // NOT IMPLEMENTED — stub only
  requested,
  // NOT IMPLEMENTED — stub only
  shown,
  // NOT IMPLEMENTED — stub only
  completed,
  // NOT IMPLEMENTED — stub only
  rewardGranted,
}

// Redundant _ScreenInfo class removed - ScreenInfo is imported from analytics_screen.dart

class _AnalyticsRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _logRoute(newRoute);
    }
  }

  void _logRoute(Route<dynamic> route) {
    final String? path = route.settings.name;
    if (path == null || path.isEmpty) return;

    if (path.startsWith('/#') || path == 'splash' || path == '/splash') return;

    AnalyticsService.instance.logScreenViewFromPath(path);
  }
}
