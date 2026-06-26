// lib/services/ad_manager.dart

import 'dart:async';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/settings_provider.dart';
import '../services/ad_free_manager.dart';
import 'consent_service.dart';
import 'ad_analytics_service.dart';
import 'analytics_service.dart';
import 'remote_config_service.dart';

class AdManager extends ChangeNotifier with WidgetsBindingObserver {
  AdManager._() {
    ConsentService.instance.onConsentChanged = _handleConsentChanged;
    WidgetsBinding.instance.addObserver(this);
  }
  static final AdManager instance = AdManager._();

  bool _sdkInitialized = false;
  int _sessionRevenueMicros = 0;

  // ── Consent & Remote Config Gate ──────────────────────────────
  bool get canShowAds =>
      ConsentService.instance.isConsentGranted &&
      _sdkInitialized &&
      RemoteConfigService.instance.adsEnabled;

  // ── Cache Pools & LRU ──────────────────────────────────────────
  final Map<String, BannerAd> _banners = {};
  final Map<String, DateTime> _bannerLoadTimes = {};

  final Map<String, NativeAd> _nativeAds = {};
  final Map<String, DateTime> _nativeLoadTimes = {};
  final List<String> _nativeLru = [];

  InterstitialAd? _interstitialAd;
  DateTime? _interstitialLoadTime;
  String? _interstitialAdUnitId;

  RewardedAd? _rewardedAd;
  DateTime? _rewardedLoadTime;
  String? _rewardedAdUnitId;

  // Mutex/State flags for Interstitial and Rewarded
  bool _interstitialShowing = false;
  bool _rewardedShowing = false;
  bool _rewardGranted = false;
  DateTime? _lastInterstitialShownTime;

  // ── Global Cooldown & Retry Counters ───────────────────────────
  final Duration _minLoadInterval = const Duration(seconds: 15);
  final Map<String, DateTime> _lastLoadTime = {};
  final Map<String, int> _retryCounts = {};
  final Map<String, Timer> _retryTimers = {};
  final Map<String, StreamSubscription> _connectivitySubscriptions = {};

  // ── Initialization ────────────────────────────────────────────
  Future<void> initialize() async {
    if (ConsentService.instance.isConsentGranted) {
      if (await isConnected()) {
        await initializeMobileAds();
      }
    }
  }

  Future<void> initializeMobileAds() async {
    if (_sdkInitialized) return;
    if (!(await isConnected())) return;
    try {
      final initStatus = await MobileAds.instance.initialize();
      _sdkInitialized = true;
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: <String>[]),
      );
      initStatus.adapterStatuses.forEach((adapter, status) {
        AdAnalyticsService.instance.recordNonFatalError(
          null,
          null,
          "Mediation adapter initialized: $adapter status=${status.state.name}",
        );
      });
      notifyListeners();
    } catch (e, s) {
      AdAnalyticsService.instance.recordFatalError(e, s, "MobileAds SDK init failure");
    }
  }

  void _handleConsentChanged() async {
    if (ConsentService.instance.isConsentGranted) {
      await initializeMobileAds();
    } else {
      _handleConsentWithdrawn();
    }
  }

  void _handleConsentWithdrawn() {
    disposeAll();
    _sdkInitialized = false;
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────
  bool _isWithinCooldown(String key) {
    final last = _lastLoadTime[key];
    if (last == null) return false;
    return DateTime.now().difference(last) < _minLoadInterval;
  }

  bool _isStale(DateTime? loadTime) {
    if (loadTime == null) return true;
    return DateTime.now().difference(loadTime) > const Duration(hours: 1);
  }

  AdRequest _buildAdRequest() {
    final container = AdFreeManager.container;
    final settings = container != null ? container.read(settingsProvider) : const AppSettings();
    final isPersonalized = ConsentService.instance.canShowPersonalizedAds;
    final extras = <String, String>{};
    if (settings.privacyChoicesOptOut) {
      extras['rdp'] = '1';
    }
    return AdRequest(
      nonPersonalizedAds: !isPersonalized,
      extras: extras.isNotEmpty ? extras : null,
    );
  }

  Future<bool> isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  void resetRetryCounter(String adUnitId) {
    _retryCounts.remove(adUnitId);
    _retryTimers[adUnitId]?.cancel();
    _retryTimers.remove(adUnitId);
    _connectivitySubscriptions[adUnitId]?.cancel();
    _connectivitySubscriptions.remove(adUnitId);
  }

  // ── Revenue Tracking Hook ──────────────────────────────────────
  void handlePaidEvent({
    required String adUnitId,
    required String adType,
    required String screen,
    required String? network,
    required double valueMicros,
    required String currencyCode,
    required String precisionName,
  }) {
    // Accumulate to session revenue (using integer micros to prevent floating point errors)
    _sessionRevenueMicros += valueMicros.toInt();

    AdAnalyticsService.instance.trackRevenue(
      adUnitId: adUnitId,
      adType: adType,
      screen: screen,
      network: network,
      valueMicros: valueMicros,
      currencyCode: currencyCode,
      precisionName: precisionName,
    );
  }

  // ── Connectivity-Aware Retry Logic ─────────────────────────────
  Future<void> _retryWithConnectivityCheck(String adUnitId, String adType, dynamic arg) async {
    final connected = await isConnected();
    final retryAttempt = _retryCounts[adUnitId] ?? 0;

    if (retryAttempt >= 3) {
      AdAnalyticsService.instance.logBreadcrumbOrError(
        errorCode: 0,
        errorMessage: "Max retries (3) reached",
        reason: "Ad load failed: max retries reached",
        adUnit: adUnitId,
        network: null,
        retryAttempt: retryAttempt,
      );
      return;
    }

    if (!connected) {
      _connectivitySubscriptions[adUnitId]?.cancel();
      _connectivitySubscriptions[adUnitId] = Connectivity().onConnectivityChanged.listen((status) {
        if (!status.contains(ConnectivityResult.none)) {
          _connectivitySubscriptions[adUnitId]?.cancel();
          _connectivitySubscriptions.remove(adUnitId);
          _scheduleRetry(adUnitId, adType, arg);
        }
      });
      return;
    }

    _scheduleRetry(adUnitId, adType, arg);
  }

  void _scheduleRetry(String adUnitId, String adType, dynamic arg) {
    final retryAttempt = _retryCounts[adUnitId] ?? 0;
    final nextRetry = retryAttempt + 1;
    _retryCounts[adUnitId] = nextRetry;

    final delaySeconds = nextRetry == 1 ? 30 : (nextRetry == 2 ? 60 : 120);
    _retryTimers[adUnitId]?.cancel();
    _retryTimers[adUnitId] = Timer(Duration(seconds: delaySeconds), () {
      if (adType == 'banner') {
        final map = arg as Map<String, dynamic>;
        loadBanner(
          adUnitId,
          map['size'] as AdSize,
          screen: map['screen'] as String? ?? 'unknown',
        );
      } else if (adType == 'native') {
        final map = arg as Map<String, String>?;
        loadNative(
          adUnitId,
          screen: map?['screen'] ?? 'unknown',
          factoryId: map?['factoryId'] ?? 'mediumCard',
        );
      } else if (adType == 'interstitial') {
        loadInterstitial(adUnitId, screen: arg as String? ?? 'unknown');
      } else if (adType == 'rewarded') {
        loadRewarded(adUnitId, screen: arg as String? ?? 'unknown');
      }
    });
  }

  // ── Banner ────────────────────────────────────────────────────
  Future<BannerAd?> loadBanner(String adUnitId, AdSize size, {String screen = 'unknown'}) async {
    if (AdFreeManager.instance.isActive || !canShowAds || !RemoteConfigService.instance.bannerEnabled) return null;
    if (!(await isConnected())) return null;

    final cacheKey = "$adUnitId:$screen";
    if (_isWithinCooldown(cacheKey)) {
      final cached = _banners[cacheKey];
      if (cached != null) return cached;
    }

    _lastLoadTime[cacheKey] = DateTime.now();
    final retryAttempt = _retryCounts[adUnitId] ?? 0;

    AdAnalyticsService.instance.trackBannerRequest(
      adUnit: adUnitId,
      screen: screen,
      retryAttempt: retryAttempt,
    );

    final startTime = DateTime.now().millisecondsSinceEpoch;
    final completer = Completer<BannerAd?>();

    final ad = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: _buildAdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
          _banners[cacheKey] = ad as BannerAd;
          _bannerLoadTimes[cacheKey] = DateTime.now();
          _retryCounts[adUnitId] = 0; // reset retry count on success

          final network = ad.responseInfo?.loadedAdapterResponseInfo?.adapterClassName ?? ad.responseInfo?.mediationAdapterClassName;
          AdAnalyticsService.instance.trackBannerLoaded(
            adUnit: adUnitId,
            screen: screen,
            network: network,
            responseTimeMs: elapsed,
            retryAttempt: retryAttempt,
          );
          if (!completer.isCompleted) completer.complete(ad);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _banners.remove(cacheKey);
          _bannerLoadTimes.remove(cacheKey);

          final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
          final network = ad.responseInfo?.loadedAdapterResponseInfo?.adapterClassName ?? ad.responseInfo?.mediationAdapterClassName;
          AdAnalyticsService.instance.trackBannerFailed(
            adUnit: adUnitId,
            screen: screen,
            network: network,
            errorCode: error.code,
            errorMessage: error.message,
            responseTimeMs: elapsed,
            retryAttempt: retryAttempt,
          );
          AdAnalyticsService.instance.logBreadcrumbOrError(
            errorCode: error.code,
            errorMessage: error.message,
            reason: "BannerAd failed to load",
            adUnit: adUnitId,
            network: network,
            retryAttempt: retryAttempt,
          );

          if (!completer.isCompleted) completer.complete(null);
          _retryWithConnectivityCheck(adUnitId, 'banner', {'size': size, 'screen': screen});
        },
        onAdOpened: (ad) {
          final network = ad.responseInfo?.loadedAdapterResponseInfo?.adapterClassName ?? ad.responseInfo?.mediationAdapterClassName;
          AdAnalyticsService.instance.trackBannerImpression(
            adUnit: adUnitId,
            screen: screen,
            network: network,
          );
        },
        onAdClicked: (ad) {
          final network = ad.responseInfo?.loadedAdapterResponseInfo?.adapterClassName ?? ad.responseInfo?.mediationAdapterClassName;
          AdAnalyticsService.instance.trackBannerClicked(
            adUnit: adUnitId,
            screen: screen,
            network: network,
          );
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          final network = ad.responseInfo?.loadedAdapterResponseInfo?.adapterClassName ?? ad.responseInfo?.mediationAdapterClassName;
          handlePaidEvent(
            adUnitId: adUnitId,
            adType: 'banner',
            screen: screen,
            network: network,
            valueMicros: valueMicros,
            currencyCode: currencyCode,
            precisionName: precision.name,
          );
        },
      ),
    );

    try {
      await ad.load();
    } catch (e, s) {
      AdAnalyticsService.instance.recordNonFatalError(e, s, "Banner load exception");
      if (!completer.isCompleted) completer.complete(null);
    }
    return completer.future;
  }

  void disposeBanner(String adUnitId, {String screen = 'unknown'}) {
    final cacheKey = "$adUnitId:$screen";
    final ad = _banners.remove(cacheKey);
    _bannerLoadTimes.remove(cacheKey);
    ad?.dispose();
  }

  // ── Native ────────────────────────────────────────────────────
  Future<NativeAd?> loadNative(String adUnitId, {String screen = 'unknown', String factoryId = 'mediumCard'}) async {
    if (AdFreeManager.instance.isActive || !canShowAds || !RemoteConfigService.instance.nativeEnabled) return null;
    if (!(await isConnected())) return null;

    final cached = getCachedNative(adUnitId, screen: screen);
    if (cached != null) return cached;

    final cacheKey = "$adUnitId:$screen";
    if (_isWithinCooldown(cacheKey)) {
      return null;
    }

    _lastLoadTime[cacheKey] = DateTime.now();
    final retryAttempt = _retryCounts[adUnitId] ?? 0;

    AdAnalyticsService.instance.trackNativeRequest(
      adUnit: adUnitId,
      screen: screen,
      retryAttempt: retryAttempt,
    );

    final startTime = DateTime.now().millisecondsSinceEpoch;
    final completer = Completer<NativeAd?>();

    final ad = NativeAd(
      adUnitId: adUnitId,
      factoryId: factoryId,
      request: _buildAdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
          _addNativeToCache(adUnitId, screen, ad as NativeAd);
          _retryCounts[adUnitId] = 0; // reset retry count on success

          final network = ad.responseInfo?.loadedAdapterResponseInfo?.adapterClassName ?? ad.responseInfo?.mediationAdapterClassName;
          AdAnalyticsService.instance.trackNativeLoaded(
            adUnit: adUnitId,
            screen: screen,
            network: network,
            responseTimeMs: elapsed,
            retryAttempt: retryAttempt,
          );
          if (!completer.isCompleted) completer.complete(ad);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _nativeAds.remove(cacheKey);
          _nativeLoadTimes.remove(cacheKey);
          _nativeLru.remove(cacheKey);

          final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
          final network = ad.responseInfo?.loadedAdapterResponseInfo?.adapterClassName ?? ad.responseInfo?.mediationAdapterClassName;
          AdAnalyticsService.instance.trackNativeFailed(
            adUnit: adUnitId,
            screen: screen,
            network: network,
            errorCode: error.code,
            errorMessage: error.message,
            responseTimeMs: elapsed,
            retryAttempt: retryAttempt,
          );
          AdAnalyticsService.instance.logBreadcrumbOrError(
            errorCode: error.code,
            errorMessage: error.message,
            reason: "NativeAd failed to load",
            adUnit: adUnitId,
            network: network,
            retryAttempt: retryAttempt,
          );

          if (!completer.isCompleted) completer.complete(null);
          _retryWithConnectivityCheck(adUnitId, 'native', {'screen': screen, 'factoryId': factoryId});
        },
        onAdOpened: (ad) {
          final network = ad.responseInfo?.loadedAdapterResponseInfo?.adapterClassName ?? ad.responseInfo?.mediationAdapterClassName;
          AdAnalyticsService.instance.trackNativeImpression(
            adUnit: adUnitId,
            screen: screen,
            network: network,
          );
        },
        onAdClicked: (ad) {
          final network = ad.responseInfo?.loadedAdapterResponseInfo?.adapterClassName ?? ad.responseInfo?.mediationAdapterClassName;
          AdAnalyticsService.instance.trackNativeClicked(
            adUnit: adUnitId,
            screen: screen,
            network: network,
          );
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          final network = ad.responseInfo?.loadedAdapterResponseInfo?.adapterClassName ?? ad.responseInfo?.mediationAdapterClassName;
          handlePaidEvent(
            adUnitId: adUnitId,
            adType: 'native',
            screen: screen,
            network: network,
            valueMicros: valueMicros,
            currencyCode: currencyCode,
            precisionName: precision.name,
          );
        },
      ),
    );

    try {
      await ad.load();
    } catch (e, s) {
      AdAnalyticsService.instance.recordNonFatalError(e, s, "Native load exception");
      if (!completer.isCompleted) completer.complete(null);
    }
    return completer.future;
  }

  void _addNativeToCache(String adUnitId, String screen, NativeAd ad) {
    final cacheKey = "$adUnitId:$screen";
    if (_nativeAds.containsKey(cacheKey)) {
      _nativeLru.remove(cacheKey);
    }
    _nativeAds[cacheKey] = ad;
    _nativeLoadTimes[cacheKey] = DateTime.now();
    _nativeLru.add(cacheKey);

    // Limit pool to max 3 native ads simultaneously
    if (_nativeLru.length > 3) {
      final oldestKey = _nativeLru.removeAt(0);
      final oldestAd = _nativeAds.remove(oldestKey);
      _nativeLoadTimes.remove(oldestKey);
      oldestAd?.dispose();
    }
  }

  NativeAd? getCachedNative(String adUnitId, {String screen = 'unknown'}) {
    final cacheKey = "$adUnitId:$screen";
    final ad = _nativeAds[cacheKey];
    if (ad == null) return null;

    final loadTime = _nativeLoadTimes[cacheKey];
    if (_isStale(loadTime)) {
      disposeNative(adUnitId, screen: screen);
      return null;
    }
    return ad;
  }

  void disposeNative(String adUnitId, {String screen = 'unknown'}) {
    final cacheKey = "$adUnitId:$screen";
    final ad = _nativeAds.remove(cacheKey);
    _nativeLoadTimes.remove(cacheKey);
    _nativeLru.remove(cacheKey);
    ad?.dispose();
  }

  // ── Interstitial ──────────────────────────────────────────────
  Future<void> loadInterstitial(String adUnitId, {String screen = 'unknown'}) async {
    if (AdFreeManager.instance.isActive || !canShowAds || !RemoteConfigService.instance.interstitialEnabled) return;
    if (!(await isConnected())) return;

    // Check memory limit (Max 1 interstitial)
    if (_interstitialAd != null) {
      if (_isStale(_interstitialLoadTime)) {
        _interstitialAd?.dispose();
        _interstitialAd = null;
      } else {
        return; // already has active cached ad
      }
    }

    if (_isWithinCooldown(adUnitId)) return;
    _lastLoadTime[adUnitId] = DateTime.now();

    final retryAttempt = _retryCounts[adUnitId] ?? 0;
    AdAnalyticsService.instance.trackInterstitialRequest(
      adUnit: adUnitId,
      screen: screen,
      retryAttempt: retryAttempt,
    );

    final startTime = DateTime.now().millisecondsSinceEpoch;

    try {
      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: _buildAdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
            _interstitialAd = ad;
            _interstitialLoadTime = DateTime.now();
            _interstitialAdUnitId = adUnitId;
            _retryCounts[adUnitId] = 0; // reset retry count

            final network = ad.responseInfo?.loadedAdapterResponseInfo?.adapterClassName ?? ad.responseInfo?.mediationAdapterClassName;
            AdAnalyticsService.instance.trackInterstitialLoaded(
              adUnit: adUnitId,
              screen: screen,
              network: network,
              responseTimeMs: elapsed,
              retryAttempt: retryAttempt,
            );

            ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
              final network = ad.responseInfo?.loadedAdapterResponseInfo?.adapterClassName ?? ad.responseInfo?.mediationAdapterClassName;
              handlePaidEvent(
                adUnitId: adUnitId,
                adType: 'interstitial',
                screen: screen,
                network: network,
                valueMicros: valueMicros,
                currencyCode: currencyCode,
                precisionName: precision.name,
              );
            };
          },
          onAdFailedToLoad: (error) {
            _interstitialAd = null;
            _interstitialLoadTime = null;

            final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
            AdAnalyticsService.instance.trackInterstitialFailed(
              adUnit: adUnitId,
              screen: screen,
              network: null,
              errorCode: error.code,
              errorMessage: error.message,
              responseTimeMs: elapsed,
              retryAttempt: retryAttempt,
            );
            AdAnalyticsService.instance.logBreadcrumbOrError(
              errorCode: error.code,
              errorMessage: error.message,
              reason: "InterstitialAd failed to load",
              adUnit: adUnitId,
              network: null,
              retryAttempt: retryAttempt,
            );

            _retryWithConnectivityCheck(adUnitId, 'interstitial', null);
          },
        ),
      );
    } catch (e, s) {
      AdAnalyticsService.instance.recordNonFatalError(e, s, "Interstitial load exception");
    }
  }

  Future<void> showInterstitial(String adUnitId, BuildContext context, {String screen = 'unknown', VoidCallback? onDismissed}) async {
    if (AdFreeManager.instance.isActive || !canShowAds || !RemoteConfigService.instance.interstitialEnabled) {
      onDismissed?.call();
      return;
    }

    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      onDismissed?.call();
      return;
    }

    // Dynamic frequency cap via Remote Config (minimum 60s floor enforced)
    final cooldown = max(60, RemoteConfigService.instance.interstitialCooldownSeconds);
    if (_lastInterstitialShownTime != null) {
      final elapsed = DateTime.now().difference(_lastInterstitialShownTime!).inSeconds;
      if (elapsed < cooldown) {
        onDismissed?.call();
        return;
      }
    }

    final ad = _interstitialAd;
    if (ad == null || _interstitialAdUnitId != adUnitId) {
      onDismissed?.call();
      return;
    }

    if (_interstitialShowing) return;
    _interstitialShowing = true;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _lastInterstitialShownTime = DateTime.now();
        final network = ad.responseInfo?.loadedAdapterResponseInfo?.adapterClassName ?? ad.responseInfo?.mediationAdapterClassName;
        AdAnalyticsService.instance.trackInterstitialShow(
          adUnit: adUnitId,
          screen: screen,
          network: network,
        );
        AdAnalyticsService.instance.trackInterstitialImpression(
          adUnit: adUnitId,
          screen: screen,
          network: network,
        );
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _interstitialLoadTime = null;
        _interstitialShowing = false;
        final network = ad.responseInfo?.loadedAdapterResponseInfo?.adapterClassName ?? ad.responseInfo?.mediationAdapterClassName;
        AdAnalyticsService.instance.trackInterstitialClosed(
          adUnit: adUnitId,
          screen: screen,
          network: network,
          wasClicked: false,
        );
        onDismissed?.call();
        loadInterstitial(adUnitId, screen: screen);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _interstitialLoadTime = null;
        _interstitialShowing = false;
        final network = ad.responseInfo?.loadedAdapterResponseInfo?.adapterClassName ?? ad.responseInfo?.mediationAdapterClassName;
        AdAnalyticsService.instance.trackInterstitialFailed(
          adUnit: adUnitId,
          screen: screen,
          network: network,
          errorCode: error.code,
          errorMessage: error.message,
          responseTimeMs: 0,
          retryAttempt: 0,
        );
        AdAnalyticsService.instance.recordNonFatalError(
          error,
          null,
          "Interstitial failed to show",
          adUnit: adUnitId,
          network: network,
        );
        onDismissed?.call();
        loadInterstitial(adUnitId, screen: screen);
      },
      onAdClicked: (ad) {
        final network = ad.responseInfo?.loadedAdapterResponseInfo?.adapterClassName ?? ad.responseInfo?.mediationAdapterClassName;
        AdAnalyticsService.instance.trackInterstitialClicked(
          adUnit: adUnitId,
          screen: screen,
          network: network,
        );
      },
    );

    _interstitialAd = null; // consume before show
    await ad.show();
  }

  // ── Rewarded ──────────────────────────────────────────────────
  //
  // ══════════════════════════════════════════════════════
  // OWNERSHIP BOUNDARY — rewarded ad analytics
  //
  // AnalyticsService owns (fired below at SDK callbacks):
  //   rewarded_ad_requested  → SDK load dispatched
  //   rewarded_ad_shown      → onAdShowedFullScreenContent
  //   rewarded_ad_completed  → onAdDismissedFullScreenContent
  //   reward_granted         → onUserEarnedReward
  //
  // AdFreeAnalyticsTracker owns:
  //   adfree_session_started, adfree_session_extended,
  //   adfree_session_expired, and all session-grant events.
  //
  // These two must NEVER fire the same event name.
  // ══════════════════════════════════════════════════════
  //
  // ⚠️  AdMob Policy — onAdLoaded has NO mapped analytics stage.
  //     Do not fire any AnalyticsService event inside onAdLoaded.
  //
  // ⚠️  AdMob Policy — NO touch interception on ad containers.
  //     Never wrap ad containers in GestureDetector, InkWell,
  //     MouseRegion, AbsorbPointer, or Listener.
  //     Touch interception = click injection = immediate account suspension.
  Future<void> loadRewarded(String adUnitId, {String screen = 'unknown'}) async {
    if (AdFreeManager.instance.isActive || !canShowAds || !RemoteConfigService.instance.rewardedEnabled) return;
    if (!(await isConnected())) return;

    if (_rewardedAd != null) {
      if (_isStale(_rewardedLoadTime)) {
        _rewardedAd?.dispose();
        _rewardedAd = null;
      } else {
        return;
      }
    }

    if (_isWithinCooldown(adUnitId)) return;
    _lastLoadTime[adUnitId] = DateTime.now();

    final retryAttempt = _retryCounts[adUnitId] ?? 0;
    AdAnalyticsService.instance.trackRewardedRequest(
      adUnit: adUnitId,
      screen: screen,
      retryAttempt: retryAttempt,
    );
    // Stage: requested — fired at SDK load dispatch, before onAdLoaded.
    // This is the correct position per AdMob policy:
    //   do NOT fire in onTap() or any UI callback.
    //   do NOT fire inside onAdLoaded.
    AnalyticsService.instance.logRewardedAdEvent(RewardedAdStage.requested);

    final startTime = DateTime.now().millisecondsSinceEpoch;

    try {
      await RewardedAd.load(
        adUnitId: adUnitId,
        request: _buildAdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          // ⚠️  onAdLoaded: NO AnalyticsService event fired here.
          //     onAdLoaded = SDK internal state. Policy prohibits
          //     firing analytics events for ad load success.
          onAdLoaded: (ad) {
            final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
            _rewardedAd = ad;
            _rewardedLoadTime = DateTime.now();
            _rewardedAdUnitId = adUnitId;
            _retryCounts[adUnitId] = 0; // reset retry count

            final network = ad.responseInfo?.loadedAdapterResponseInfo?.adapterClassName ?? ad.responseInfo?.mediationAdapterClassName;
            AdAnalyticsService.instance.trackRewardedLoaded(
              adUnit: adUnitId,
              screen: screen,
              network: network,
              responseTimeMs: elapsed,
              retryAttempt: retryAttempt,
            );

            ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
              final network = ad.responseInfo?.loadedAdapterResponseInfo?.adapterClassName ?? ad.responseInfo?.mediationAdapterClassName;
              handlePaidEvent(
                adUnitId: adUnitId,
                adType: 'rewarded',
                screen: screen,
                network: network,
                valueMicros: valueMicros,
                currencyCode: currencyCode,
                precisionName: precision.name,
              );
            };
          },
          onAdFailedToLoad: (error) {
            _rewardedAd = null;
            _rewardedLoadTime = null;

            final elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
            AdAnalyticsService.instance.trackRewardedFailed(
              adUnit: adUnitId,
              screen: screen,
              network: null,
              errorCode: error.code,
              errorMessage: error.message,
              responseTimeMs: elapsed,
              retryAttempt: retryAttempt,
            );
            AdAnalyticsService.instance.logBreadcrumbOrError(
              errorCode: error.code,
              errorMessage: error.message,
              reason: "RewardedAd failed to load",
              adUnit: adUnitId,
              network: null,
              retryAttempt: retryAttempt,
            );
            // Failures → logFeatureError (not logRewardedAdEvent).
            AnalyticsService.instance.logFeatureError(
              feature: 'rewarded_ad_load',
              exception: error,
            );

            _retryWithConnectivityCheck(adUnitId, 'rewarded', null);
          },
        ),
      );
    } catch (e, s) {
      AdAnalyticsService.instance.recordNonFatalError(e, s, "Rewarded load exception");
    }
  }

  Future<void> showRewarded(String adUnitId, {required OnUserEarnedRewardCallback onEarned, String screen = 'unknown'}) async {
    if (!canShowAds || !RemoteConfigService.instance.rewardedEnabled) return;

    if (_rewardedShowing) return;

    final ad = _rewardedAd;
    if (ad == null || _rewardedAdUnitId != adUnitId) return;

    _rewardedAd = null; // consume before show
    _rewardedShowing = true;
    _rewardGranted = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        final network = ad.responseInfo?.loadedAdapterResponseInfo?.adapterClassName ?? ad.responseInfo?.mediationAdapterClassName;
        AdAnalyticsService.instance.trackRewardedShow(
          adUnit: adUnitId,
          screen: screen,
          network: network,
        );
        AdAnalyticsService.instance.trackRewardedImpression(
          adUnit: adUnitId,
          screen: screen,
          network: network,
        );
        // Stage: shown — fired inside SDK's onAdShowedFullScreenContent.
        AnalyticsService.instance.logRewardedAdEvent(RewardedAdStage.shown);
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedShowing = false;
        final network = ad.responseInfo?.loadedAdapterResponseInfo?.adapterClassName ?? ad.responseInfo?.mediationAdapterClassName;
        AdAnalyticsService.instance.trackRewardedClosed(
          adUnit: adUnitId,
          screen: screen,
          network: network,
          rewardEarned: _rewardGranted,
        );
        // Stage: completed — fired inside SDK's onAdDismissedFullScreenContent.
        AnalyticsService.instance.logRewardedAdEvent(RewardedAdStage.completed);
        loadRewarded(adUnitId, screen: screen);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedShowing = false;
        final network = ad.responseInfo?.loadedAdapterResponseInfo?.adapterClassName ?? ad.responseInfo?.mediationAdapterClassName;
        AdAnalyticsService.instance.trackRewardedFailed(
          adUnit: adUnitId,
          screen: screen,
          network: network,
          errorCode: error.code,
          errorMessage: error.message,
          responseTimeMs: 0,
          retryAttempt: 0,
        );
        AdAnalyticsService.instance.recordNonFatalError(
          error,
          null,
          "Rewarded failed to show",
          adUnit: adUnitId,
          network: network,
        );
        // Failures → logFeatureError (not logRewardedAdEvent).
        AnalyticsService.instance.logFeatureError(
          feature: 'rewarded_ad_show',
          exception: error,
        );
        loadRewarded(adUnitId, screen: screen);
      },
      onAdClicked: (ad) {
        final network = ad.responseInfo?.loadedAdapterResponseInfo?.adapterClassName ?? ad.responseInfo?.mediationAdapterClassName;
        AdAnalyticsService.instance.trackRewardedClicked(
          adUnit: adUnitId,
          screen: screen,
          network: network,
        );
      },
    );

    await ad.show(
      onUserEarnedReward: (adWithoutView, reward) {
        if (_rewardGranted) return; // duplicate guard
        _rewardGranted = true;

        final network = ad.responseInfo?.loadedAdapterResponseInfo?.adapterClassName ?? ad.responseInfo?.mediationAdapterClassName;
        AdAnalyticsService.instance.trackRewardedEarned(
          adUnit: adUnitId,
          screen: screen,
          network: network,
          rewardType: reward.type,
          amount: reward.amount.toInt(),
        );
        // Stage: rewardGranted — fired inside onUserEarnedReward only.
        // Never fire this from UI callbacks or onDismissed.
        AnalyticsService.instance.logRewardedAdEvent(RewardedAdStage.rewardGranted);

        onEarned(adWithoutView, reward);
      },
    );
  }

  // ── Diagnostics ───────────────────────────────────────────────
  void openAdInspector() {
    if (kDebugMode) {
      try {
        MobileAds.instance.openAdInspector((error) {
          if (error != null) {
            AdAnalyticsService.instance.recordNonFatalError(
              error,
              null,
              "Ad inspector load error",
            );
          }
        });
      } catch (e, s) {
        AdAnalyticsService.instance.recordNonFatalError(e, s, "Ad inspector failed to open");
      }
    }
  }

  // ── WidgetsBindingObserver Lifecycle ─────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      onAppResumed();
    }
  }

  void onAppPaused() {
    _retryTimers.forEach((_, timer) => timer.cancel());
    // Log session revenue when backgrounded
    if (_sessionRevenueMicros > 0) {
      final revenueUsd = _sessionRevenueMicros / 1000000.0;
      AdAnalyticsService.instance.trackSessionRevenue(revenueUsd);
    }
  }

  void onAppResumed() {
    ConsentService.instance.init().then((_) {
      if (ConsentService.instance.isConsentGranted) {
        initializeMobileAds();
      }
    });
  }

  void clearAll() {
    disposeAll();
  }

  void disposeAll() {
    _retryTimers.forEach((_, timer) => timer.cancel());
    _retryTimers.clear();

    _connectivitySubscriptions.forEach((_, sub) => sub.cancel());
    _connectivitySubscriptions.clear();

    _banners.forEach((_, ad) => ad.dispose());
    _banners.clear();
    _bannerLoadTimes.clear();

    _nativeAds.forEach((_, ad) => ad.dispose());
    _nativeAds.clear();
    _nativeLoadTimes.clear();
    _nativeLru.clear();

    _interstitialAd?.dispose();
    _interstitialAd = null;
    _interstitialLoadTime = null;
    _interstitialAdUnitId = null;

    _rewardedAd?.dispose();
    _rewardedAd = null;
    _rewardedLoadTime = null;
    _rewardedAdUnitId = null;

    _lastLoadTime.clear();
    _retryCounts.clear();
  }
}
