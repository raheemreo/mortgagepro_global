// lib/services/remote_config_service.dart

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'ad_config.dart';
import 'crashlytics_service.dart';

/// RemoteConfigService — Typed, reactive wrapper around Firebase Remote Config.
///
/// Provides kill-switches, feature flags, and ad-frequency settings.
/// Listens to onConfigUpdated for real-time propagation without restart.
///
/// All getters return safe defaults when Remote Config is unavailable.
/// Never throws. Never crashes the app.
class RemoteConfigService extends ChangeNotifier {
  // ── Singleton ─────────────────────────────────────────────────────────────
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  // ── Remote Config instance ────────────────────────────────────────────────
  final FirebaseRemoteConfig _rc = FirebaseRemoteConfig.instance;

  // ── Default values ────────────────────────────────────────────────────────
  // These are returned whenever the key has not yet been fetched from the
  // server, or when the network is unavailable.
  static const Map<String, dynamic> _defaults = {
    'banner_enabled': true,
    'native_enabled': true,
    'interstitial_enabled': true,
    'rewarded_enabled': true,
    'interstitial_cooldown_seconds': 60,
    'reward_ad_free_duration': 10,
    'native_frequency': 0,
    'show_banner_ad': true,
    'show_native_ad': true,
    'show_rewarded_ad': true,
    'interstitial_frequency': 90,   // seconds between interstitial shows
    'maintenance_mode': false,
    'disable_ads': false,
    'disable_interstitials': false,
    'disable_rewarded': false,
    'feature_flag_pdf': true,
    'feature_flag_compare': true,

    // ── New Zealand — updated to reflect current RBNZ position (Jun 2025) ──
    'nz_ocr_rate': '2.25',          // RBNZ OCR — cut 9 times since 2024
    'nz_next_meeting': '6 Aug 2025', // Next MPC meeting date
    'nz_cut_probability': '68%',    // Market-implied cut probability
    'nz_bond_2yr': '3.85',          // 2-Yr Govt Bond yield %
    'nz_bond_10yr': '4.45',         // 10-Yr Govt Bond yield %
    'nz_cpi': '2.5',                // CPI Inflation % (Stats NZ quarterly)
    // Region median house prices (NZ$, thousands — update quarterly via REINZ)
    'nz_price_auckland': '950',
    'nz_price_wellington': '780',
    'nz_price_christchurch': '610',
    'nz_price_hamilton': '650',
    'nz_price_tauranga': '810',
    'nz_price_dunedin': '520',
  };

  // ── Init ──────────────────────────────────────────────────────────────────

  /// Fetches and activates Remote Config values.
  ///
  /// Cache interval:
  ///   • Test mode or debug build → Duration.zero (always fresh).
  ///   • Production               → 1 hour.
  ///
  /// Subscribes to [onConfigUpdated] for real-time config propagation.
  /// On failure: logs to Crashlytics and continues with defaults.
  Future<void> init() async {
    try {
      // Set in-app defaults so typed getters return correct values
      // even before the first successful fetch.
      await _rc.setDefaults(_defaults);

      // Determine fetch interval.
      const fetchInterval = (AdConfig.isTestMode || kDebugMode)
          ? Duration.zero
          : Duration(hours: 1);

      await _rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: fetchInterval,
        ),
      );

      // Fetch and activate the latest values.
      await _rc.fetchAndActivate();

      // Subscribe to real-time config updates pushed from the Firebase console.
      // Each update triggers a re-fetch + activate + notifyListeners().
      _rc.onConfigUpdated.listen(
        (_) async {
          try {
            await _rc.fetchAndActivate();
            notifyListeners();
          } catch (e, s) {
            CrashlyticsService.recordError(
              e,
              s,
              reason: 'RemoteConfigService onConfigUpdated re-fetch failed',
            );
            // Listeners are NOT notified on failure — stale values remain.
          }
        },
        onError: (Object e, StackTrace s) {
          CrashlyticsService.recordError(
            e,
            s,
            reason: 'RemoteConfigService onConfigUpdated stream error',
          );
        },
      );
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'RemoteConfigService.init() failed — using defaults',
      );
      // Continue with defaults. Never throw.
    }
  }

  // ── New Ad visibility and configuration flags ─────────────────────────────

  /// Whether banner ads should be loaded and shown.
  bool get bannerEnabled => _getBool('banner_enabled', defaultValue: true);

  /// Whether native ads should be loaded and shown.
  bool get nativeEnabled => _getBool('native_enabled', defaultValue: true);

  /// Whether interstitial ads should be loaded and shown.
  bool get interstitialEnabled => _getBool('interstitial_enabled', defaultValue: true);

  /// Whether rewarded ads should be loaded and shown.
  bool get rewardedEnabled => _getBool('rewarded_enabled', defaultValue: true);

  /// Minimum seconds that must elapse between interstitial impressions.
  int get interstitialCooldownSeconds => _getInt('interstitial_cooldown_seconds', defaultValue: 60);

  /// Duration of ad-free time unlocked by watching a rewarded ad (in minutes).
  int get rewardAdFreeDuration => _getInt('reward_ad_free_duration', defaultValue: 10);

  /// Frequency settings for native ads.
  int get nativeFrequency => _getInt('native_frequency', defaultValue: 0);

  // ── Legacy Compatibility Mappings ──────────────────────────────────────────

  bool get showBannerAd => bannerEnabled;
  bool get showNativeAd => nativeEnabled;
  bool get showRewardedAd => rewardedEnabled;
  int get interstitialFrequency => interstitialCooldownSeconds;
  bool get disableInterstitials => !interstitialEnabled;
  bool get disableRewarded => !rewardedEnabled;

  // ── Kill-switches ─────────────────────────────────────────────────────────

  /// When true, the app is under maintenance.
  /// The splash screen halts initialisation and shows MaintenancePage.
  /// Remote Config key: maintenance_mode · Default: false
  bool get maintenanceMode =>
      _getBool('maintenance_mode', defaultValue: false);

  /// When true, ALL ad formats are suppressed regardless of other flags.
  /// Remote Config key: disable_ads · Default: false
  bool get disableAds => _getBool('disable_ads', defaultValue: false);

  // ── Feature flags ─────────────────────────────────────────────────────────

  /// Whether the PDF export feature is enabled.
  /// Remote Config key: feature_flag_pdf · Default: true
  bool get featureFlagPdf =>
      _getBool('feature_flag_pdf', defaultValue: true);

  /// Whether the loan comparison feature is enabled.
  /// Remote Config key: feature_flag_compare · Default: true
  bool get featureFlagCompare =>
      _getBool('feature_flag_compare', defaultValue: true);

  // ── New Zealand Rate & Market Data ───────────────────────────────────────

  /// RBNZ Official Cash Rate (OCR) as a string, e.g. "2.25"
  /// Update in Firebase Console within minutes of each RBNZ announcement.
  String get nzOcrRate => _getString('nz_ocr_rate', defaultValue: '2.25');

  /// Next RBNZ MPC meeting date, e.g. "6 Aug 2025"
  String get nzNextMeeting => _getString('nz_next_meeting', defaultValue: '6 Aug 2025');

  /// Market-implied OCR cut probability, e.g. "68%"
  String get nzCutProbability => _getString('nz_cut_probability', defaultValue: '68%');

  /// 2-Year NZ Govt Bond yield (%)
  double get nzBond2yr => double.tryParse(_getString('nz_bond_2yr', defaultValue: '3.85')) ?? 3.85;

  /// 10-Year NZ Govt Bond yield (%)
  double get nzBond10yr => double.tryParse(_getString('nz_bond_10yr', defaultValue: '4.45')) ?? 4.45;

  /// CPI Inflation rate (%) — updated quarterly after Stats NZ release
  double get nzCpi => double.tryParse(_getString('nz_cpi', defaultValue: '2.5')) ?? 2.5;

  /// Auckland median house price (NZ$, thousands)
  int get nzPriceAuckland => _getInt('nz_price_auckland', defaultValue: 950);

  /// Wellington median house price (NZ$, thousands)
  int get nzPriceWellington => _getInt('nz_price_wellington', defaultValue: 780);

  /// Christchurch median house price (NZ$, thousands)
  int get nzPriceChristchurch => _getInt('nz_price_christchurch', defaultValue: 610);

  /// Hamilton median house price (NZ$, thousands)
  int get nzPriceHamilton => _getInt('nz_price_hamilton', defaultValue: 650);

  /// Tauranga median house price (NZ$, thousands)
  int get nzPriceTauranga => _getInt('nz_price_tauranga', defaultValue: 810);

  /// Dunedin median house price (NZ$, thousands)
  int get nzPriceDunedin => _getInt('nz_price_dunedin', defaultValue: 520);

  // ── Computed kill-switch ──────────────────────────────────────────────────

  /// Master ad gate.
  ///
  /// Returns false (suppress all ads) when:
  ///   • [disableAds] is true, OR
  ///   • [maintenanceMode] is true.
  ///
  /// This getter must be checked before every ad load in AdManager.
  bool get adsEnabled => !disableAds && !maintenanceMode;

  // ── Private typed helpers ─────────────────────────────────────────────────

  bool _getBool(String key, {required bool defaultValue}) {
    try {
      // getValue() always returns a RemoteConfigValue; no null risk.
      return _rc.getBool(key);
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'RemoteConfigService._getBool() failed — key: $key',
      );
      return defaultValue;
    }
  }

  int _getInt(String key, {required int defaultValue}) {
    try {
      return _rc.getInt(key);
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'RemoteConfigService._getInt() failed — key: $key',
      );
      return defaultValue;
    }
  }

  String _getString(String key, {required String defaultValue}) {
    try {
      final val = _rc.getString(key);
      return val.isEmpty ? defaultValue : val;
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'RemoteConfigService._getString() failed — key: $key',
      );
      return defaultValue;
    }
  }
}
