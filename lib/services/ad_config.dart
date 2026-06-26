// lib/services/ad_config.dart

import 'package:flutter/foundation.dart';

// ignore_for_file: avoid_classes_with_only_static_members

/// AdConfig — Central ad unit ID registry for MortgagePro Global.
///
/// Under AdMob policies, requesting real ads during development/testing is a
/// severe policy violation (click fraud / invalid traffic). Therefore, this config
/// automatically returns official Google AdMob test IDs when [isTestMode] is true or
/// in debug builds, and live production IDs only when built in release mode.
class AdConfig {
  // ── No instantiation ──────────────────────────────────────────────────────
  AdConfig._();

  // ── Test-mode flag ────────────────────────────────────────────────────────

  /// Set to true or kDebugMode to ensure AdMob test IDs are used during testing.
  /// Set to false only for production builds.
  static const bool isTestMode = kDebugMode;

  // ── Banner ────────────────────────────────────────────────────────────────

  /// Android banner ad unit.
  static const String bannerAdUnitAndroid = isTestMode
      ? 'ca-app-pub-3940256099942544/6300978111'
      : String.fromEnvironment('BANNER_AD_UNIT_ANDROID', defaultValue: 'ca-app-pub-3940256099942544/6300978111');

  /// iOS banner ad unit.
  static const String bannerAdUnitIos = isTestMode
      ? 'ca-app-pub-3940256099942544/6300978111'
      : String.fromEnvironment('BANNER_AD_UNIT_IOS', defaultValue: 'ca-app-pub-3940256099942544/6300978111');

  // ── Native ────────────────────────────────────────────────────────────────

  /// Android native ad unit.
  static const String nativeAdUnitAndroid = isTestMode
      ? 'ca-app-pub-3940256099942544/2247696110'
      : String.fromEnvironment('NATIVE_AD_UNIT_ANDROID', defaultValue: 'ca-app-pub-3940256099942544/2247696110');

  /// iOS native ad unit.
  static const String nativeAdUnitIos = isTestMode
      ? 'ca-app-pub-3940256099942544/2247696110'
      : String.fromEnvironment('NATIVE_AD_UNIT_IOS', defaultValue: 'ca-app-pub-3940256099942544/2247696110');

  // ── Interstitial ──────────────────────────────────────────────────────────

  /// Android interstitial ad unit.
  static const String interstitialAdUnitAndroid = isTestMode
      ? 'ca-app-pub-3940256099942544/1033173712'
      : String.fromEnvironment('INTERSTITIAL_AD_UNIT_ANDROID', defaultValue: 'ca-app-pub-3940256099942544/1033173712');

  /// iOS interstitial ad unit.
  static const String interstitialAdUnitIos = isTestMode
      ? 'ca-app-pub-3940256099942544/1033173712'
      : String.fromEnvironment('INTERSTITIAL_AD_UNIT_IOS', defaultValue: 'ca-app-pub-3940256099942544/1033173712');

  // ── Rewarded ──────────────────────────────────────────────────────────────

  /// Android rewarded ad unit.
  static const String rewardedAdUnitAndroid = isTestMode
      ? 'ca-app-pub-3940256099942544/5224354917'
      : String.fromEnvironment('REWARDED_AD_UNIT_ANDROID', defaultValue: 'ca-app-pub-3940256099942544/5224354917');

  /// iOS rewarded ad unit.
  static const String rewardedAdUnitIos = isTestMode
      ? 'ca-app-pub-3940256099942544/5224354917'
      : String.fromEnvironment('REWARDED_AD_UNIT_IOS', defaultValue: 'ca-app-pub-3940256099942544/5224354917');
}

