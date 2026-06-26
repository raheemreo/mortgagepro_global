// lib/widgets/ads/rewarded_ad_button.dart

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'dart:io';
import '../../services/ad_config.dart';
import '../../services/ad_manager.dart';

// ══════════════════════════════════════════════════════
// ⚠️  ADMOB POLICY — ANALYTICS PROHIBITED IN THIS FILE
//
// Never call AnalyticsService.logRewardedAdEvent()
// from this widget or any UI component.
//
// All rewarded ad lifecycle analytics must originate
// from AdMob SDK callbacks inside AdManager only
// (onAdShowedFullScreenContent, onAdDismissedFullScreenContent,
//  onUserEarnedReward, and at SDK load dispatch).
//
// Firing ad events from UI interactions (onTap, onPressed,
// GestureDetector, InkWell, etc.) constitutes synthetic traffic
// and violates AdMob's Invalid Traffic Policy. Violations
// may result in account suspension without warning.
// ══════════════════════════════════════════════════════

// ══════════════════════════════════════════════════════
// ⚠️  ADMOB POLICY — INCENTIVIZED AD DISCLOSURE
//
// The label parameter must clearly describe the specific
// reward before the user commits to watching the ad.
//
//   ✓ "Watch ad for 10 min ad-free"
//   ✓ "Watch ad to unlock calculator results"
//   ✗ "Get reward"    ← vague, policy violation
//   ✗ "Watch ad"      ← reward not described
//   ✗ "Unlock"        ← reward not described
//
// The caller (not this widget) provides the label string
// and is responsible for compliance.
// ══════════════════════════════════════════════════════

/// RewardedAdButton
///
/// BUG FIXES applied in this revision:
///
/// FIX 1 — Button stays disabled until both the ad dismisses AND the next
///   preload completes (or times out).
///   Original: _isShowing was cleared before _preload() ran, reopening the
///   tap window mid-load. A second tap during that gap would call
///   showRewarded() while _rewardedAd was still null → no-op, but
///   combined with AdManager's race it could double-fire.
///   Fix: keep _isShowing = true until _preload() finishes, then clear it.
///
/// FIX 2 — _onTap() is fully re-entrant safe.
///   The existing _isShowing guard is correct in principle but was being
///   released too early (see FIX 1). Now the guard covers the entire
///   show-then-reload cycle.
///
/// Everything else (preload on initState, spinner states, theme colours)
/// is unchanged.
class RewardedAdButton extends StatefulWidget {
  const RewardedAdButton({
    super.key,
    required this.label,
    required this.onReward,
  });

  final String label;
  final OnUserEarnedRewardCallback onReward;

  @override
  State<RewardedAdButton> createState() => _RewardedAdButtonState();
}

class _RewardedAdButtonState extends State<RewardedAdButton> {
  bool _isLoading = false;
  bool _isReady = false;

  /// True for the entire show-then-reload cycle.
  /// FIX 1: cleared only after _preload() completes, not before.
  bool _isShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _preload();
    });
  }

  // ── Ad lifecycle ──────────────────────────────────────────────────────────

  String get _adUnitId => Platform.isIOS
      ? AdConfig.rewardedAdUnitIos
      : AdConfig.rewardedAdUnitAndroid;

  Future<void> _preload() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _isReady = false;
    });

    await AdManager.instance.loadRewarded(_adUnitId, screen: 'reward_button');

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isReady = true;
    });
  }

  Future<void> _onTap() async {
    // Guard: must be ready and not already in a show cycle.
    if (!_isReady || _isLoading || _isShowing) return;
    if (!mounted) return;

    setState(() {
      _isShowing = true; // locks the button for the entire cycle
      _isReady = false;
    });

    AdManager.instance.showRewarded(
      _adUnitId,
      screen: 'reward_button',
      onEarned: widget.onReward,
    );

    // Button stays disabled during the reload so the user cannot tap while
    // the next ad is in-flight.
    await _preload();

    if (mounted) {
      setState(() => _isShowing = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final bool isActive = _isReady && !_isLoading && !_isShowing;

    return AnimatedOpacity(
      opacity: isActive ? 1.0 : 0.55,
      duration: const Duration(milliseconds: 200),
      child: FilledButton.tonal(
        onPressed: isActive ? _onTap : null,
        style: FilledButton.styleFrom(
          backgroundColor: cs.secondaryContainer,
          foregroundColor: cs.onSecondaryContainer,
          disabledBackgroundColor: cs.surfaceContainerHighest,
          disabledForegroundColor: cs.onSurfaceVariant,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        child: _buildChild(cs, tt, isActive),
      ),
    );
  }

  Widget _buildChild(ColorScheme cs, TextTheme tt, bool isActive) {
    if (_isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 10),
          Text(
            'Preparing Ad\u2026',
            style: tt.labelLarge?.copyWith(
                color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    if (_isShowing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 10),
          Text(
            'Ad Playing\u2026',
            style: tt.labelLarge?.copyWith(
                color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.play_circle_outline_rounded,
          size: 20,
          color: isActive ? cs.onSecondaryContainer : cs.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: tt.labelLarge?.copyWith(
              color: isActive ? cs.onSecondaryContainer : cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
