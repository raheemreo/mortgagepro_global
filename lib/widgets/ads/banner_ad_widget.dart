// lib/widgets/ads/banner_ad_widget.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/ad_config.dart';
import '../../services/ad_manager.dart';
import '../../services/ad_free_manager.dart';

/// BannerAdWidget — Displays an adaptive banner ad for the given [screenName].
///
/// Spacing requirements:
///   • 150 dp from Calculate, Save, and Export PDF buttons.
///   • 32 dp from BottomNavigationBar.
///   • 32 dp from all other interactive elements.
///
/// Collapses to zero height with no layout shift when keyboard is visible,
/// when loading, or when ad fails to load.
class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({
    super.key,
    required this.screenName,
  });

  /// snake_case screen identifier, e.g. "usa_screen".
  final String screenName;

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  AdSize? _adSize;
  bool _isLoaded = false;

  String get _adUnitId => Platform.isIOS ? AdConfig.bannerAdUnitIos : AdConfig.bannerAdUnitAndroid;

  @override
  void initState() {
    super.initState();
    // Reset retry counter on screen entry
    AdManager.instance.resetRetryCounter(_adUnitId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadAd();
    });
  }

  @override
  void dispose() {
    // Banner lifecycle is owned by AdManager, but we clean up when widget is destroyed
    AdManager.instance.disposeBanner(_adUnitId, screen: widget.screenName);
    super.dispose();
  }

  Future<void> _loadAd() async {
    final width = MediaQuery.of(context).size.width.truncate();
    AdSize adSize = AdSize.banner;

    try {
      final adaptiveSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
      if (adaptiveSize != null) adSize = adaptiveSize;
    } catch (_) {}

    if (!mounted) return;

    final ad = await AdManager.instance.loadBanner(_adUnitId, adSize, screen: widget.screenName);

    if (!mounted) return;

    if (ad != null) {
      setState(() {
        _bannerAd = ad;
        _adSize = adSize;
        _isLoaded = true;
      });
    } else {
      setState(() {
        _isLoaded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final adFreeActive = ref.watch(adFreeActiveProvider);
    ref.listen<bool>(adFreeActiveProvider, (previous, next) {
      if (next) {
        AdManager.instance.disposeBanner(_adUnitId, screen: widget.screenName);
        if (mounted) {
          setState(() {
            _bannerAd = null;
            _isLoaded = false;
          });
        }
      }
    });

    if (adFreeActive) return const SizedBox.shrink();

    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (keyboardVisible) return const SizedBox.shrink();

    final double height = _isLoaded && _adSize != null ? _adSize!.height.toDouble() : 0.0;

    return AnimatedOpacity(
      opacity: _isLoaded ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: _isLoaded
              ? Border(
                  top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
                  bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
                )
              : null,
        ),
        child: _isLoaded && _bannerAd != null
            ? AdWidget(ad: _bannerAd!)
            : const SizedBox.shrink(),
      ),
    );
  }
}
