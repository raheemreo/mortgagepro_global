// lib/widgets/ads/native_ad_widget.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/ad_config.dart';
import '../../services/ad_manager.dart';
import '../../services/ad_free_manager.dart';

/// NativeAdWidget — Displays a native ad for the given [screenName].
///
/// Protection layers:
///   ✅ Consent gate  — collapses if AdManager.canShowAds == false
///   ✅ Dynamic load  — fetches via AdManager if not cached
///   ✅ No shimmer    — collapses completely during loading/failed states
///   ✅ Clean entry   — fades in over 250ms when loaded
///   ✅ Compliance    — 20dp clear zone, high-contrast 'Ad' badge
class NativeAdWidget extends ConsumerStatefulWidget {
  /// snake_case screen identifier used for analytics, e.g. "usa_home".
  final String screenName;

  /// Factory ID registered in MainActivity.kt / AppDelegate.swift.
  /// Supported values: 'compactListTile', 'contentAd', 'mediumCard', 'largeBanner'.
  final String adType;

  const NativeAdWidget({
    super.key,
    required this.screenName,
    required this.adType,
  });

  @override
  ConsumerState<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends ConsumerState<NativeAdWidget> {
  NativeAd? _ad;
  bool _isLoaded = false;
  bool _loadFailed = false;
  double _opacity = 0.0; // animates to 1.0 when ad is ready

  String get _adUnitId => Platform.isIOS ? AdConfig.nativeAdUnitIos : AdConfig.nativeAdUnitAndroid;

  @override
  void initState() {
    super.initState();
    _loadFailed = false;
    // Reset retry counter on screen entry
    AdManager.instance.resetRetryCounter(_adUnitId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadNativeAd();
    });
  }

  @override
  void dispose() {
    AdManager.instance.disposeNative(_adUnitId, screen: widget.screenName);
    super.dispose();
  }

  Future<void> _loadNativeAd() async {
    if (mounted) {
      setState(() {
        _loadFailed = false;
      });
    }

    // ── Check cached pool first ──
    final cachedAd = AdManager.instance.getCachedNative(_adUnitId, screen: widget.screenName);
    if (cachedAd != null) {
      if (mounted) {
        setState(() {
          _ad = cachedAd;
          _isLoaded = true;
          _loadFailed = false;
        });
      }
      return;
    }

    // ── Load dynamically ──
    final loadedAd = await AdManager.instance.loadNative(
      _adUnitId,
      screen: widget.screenName,
      factoryId: widget.adType,
      isDark: Theme.of(context).brightness == Brightness.dark,
    );

    if (!mounted) return;

    if (loadedAd != null) {
      setState(() {
        _ad = loadedAd;
        _isLoaded = true;
        _loadFailed = false;
        _opacity = 1.0; // trigger fade-in
      });
    } else {
      setState(() {
        _isLoaded = false;
        _loadFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final adFreeActive = ref.watch(adFreeActiveProvider);
    ref.listen<bool>(adFreeActiveProvider, (previous, next) {
      if (next) {
        AdManager.instance.disposeNative(_adUnitId, screen: widget.screenName);
        if (mounted) {
          setState(() {
            _ad = null;
            _isLoaded = false;
            _loadFailed = false;
            _opacity = 0.0;
          });
        }
      }
    });

    if (adFreeActive) return const SizedBox.shrink();
    if (_loadFailed) return const SizedBox.shrink();

    final double expectedHeight = switch (widget.adType) {
      'compactListTile' => 160.0,
      'contentAd'       => 180.0,
      'mediumCard'      => 268.0,
      'largeBanner'     => 360.0,
      _                 => 268.0,
    };

    final bool showAdWidget = _isLoaded && _ad != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 1.0),
      child: Container(
        height: expectedHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: showAdWidget
            ? AnimatedOpacity(
                opacity: _opacity,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeIn,
                child: Stack(
                  children: [
                    AdWidget(ad: _ad!),
                    // WCAG AA compliant 'Ad' badge
                    Positioned(
                      left: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Ad',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
