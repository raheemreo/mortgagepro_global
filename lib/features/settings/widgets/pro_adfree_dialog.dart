// lib/features/settings/widgets/pro_adfree_dialog.dart
//
// BUG FIX — CTA handler now calls onWatchAdvertisement() BEFORE
// Navigator.pop(). The original order (pop → watch) disposed the
// RewardedAdButton widget while AdManager.showRewarded() was still
// trying to call ad.show(), causing a no-op on first tap (ad was torn
// down) and confusing the load state so the second tap fired two ads.
//
// Additional fix: _adRequested flag prevents double-tap between the
// moment the button is tapped and the moment the dialog actually closes.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/text_styles.dart';
import '../../../services/ad_free_manager.dart';
import '../../../services/remote_config_service.dart';

class _C {
  static const Color navy = Color(0xFF0B1D3A);
  static const Color teal = Color(0xFF0D9488);
  static const Color amber = Color(0xFFD97706);
  static const Color muted = Color(0xFF5B6E8F);
  static const Color red = Color(0xFFB91C1C);
  static const Color warn = Color(0xFF92400E);
}

const _kWarnThreshold = Duration(minutes: 3);

void showProDialog(
  BuildContext context, {
  required VoidCallback onWatchAdvertisement,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => _ProAdFreeDialog(
      onWatchAdvertisement: onWatchAdvertisement,
    ),
  );
}

class _ProAdFreeDialog extends ConsumerStatefulWidget {
  final VoidCallback onWatchAdvertisement;
  const _ProAdFreeDialog({required this.onWatchAdvertisement});

  @override
  ConsumerState<_ProAdFreeDialog> createState() => _ProAdFreeDialogState();
}

class _ProAdFreeDialogState extends ConsumerState<_ProAdFreeDialog> {
  Timer? _ticker;

  /// Prevents double-tap between the user tapping and the dialog closing.
  bool _adRequested = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ── Derived state ────────────────────────────────────────────────────────

  Duration get _remaining => AdFreeManager.instance.remaining;
  int get _minutesLeft => _remaining.inMinutes;
  bool get _canWatch => AdFreeManager.instance.canWatchAd;
  int get _adsLeft => AdFreeManager.instance.adsRemainingInWindow;
  Duration get _resetIn => AdFreeManager.instance.windowResetIn;

  bool _isExpired(bool isActive) => !isActive;
  bool _showExtend(bool isActive) => isActive && _remaining < _kWarnThreshold;

  Color get _timerColor {
    if (_minutesLeft <= 3) return _C.red;
    if (_minutesLeft <= 6) return _C.amber;
    return _C.teal;
  }

  // ── CTA handler ───────────────────────────────────────────────────────────

  void _handleWatchAd() {
    if (_adRequested) return; // double-tap guard
    setState(() => _adRequested = true);

    // ── FIX: fire the ad BEFORE closing the dialog ────────────────────────
    // Calling Navigator.pop() first disposed the widget owning the
    // RewardedAdButton while AdManager was still trying to call ad.show().
    // Result: ad silently no-op'd on first tap, then the stale preload
    // fired on the second tap — appearing as two simultaneous ads.
    widget.onWatchAdvertisement();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF111827) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB);
    final textNavy = isDark ? Colors.white : _C.navy;
    final textMuted = isDark ? Colors.white70 : _C.muted;

    final isActive = ref.watch(adFreeActiveProvider);
    final expired = _isExpired(isActive);
    final showExtend = _showExtend(isActive);

    final canAct = (expired || showExtend) && _canWatch && !_adRequested;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: dialogBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icon ────────────────────────────────────────────────────
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: showExtend
                      ? const Color(0xFFFFFBEB)
                      : isActive
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFFFFBEB),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: showExtend
                        ? _C.amber.withValues(alpha: 0.35)
                        : isActive
                            ? _C.teal.withValues(alpha: 0.30)
                            : _C.amber.withValues(alpha: 0.20),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  showExtend
                      ? '⚠️'
                      : isActive
                          ? '✅'
                          : '⭐',
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(height: 20),

              // ── Title ────────────────────────────────────────────────────
              Text(
                showExtend
                    ? 'Session Expiring Soon'
                    : isActive
                        ? 'Ad-Free Session Active'
                        : 'Go Ad-Free',
                style: AppTextStyles.playfair(
                  size: 24,
                  color: showExtend ? _C.amber : textNavy,
                  weight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // ── Description ──────────────────────────────────────────────
              Text(
                expired && !_canWatch
                    ? 'You\'ve used both sessions for this window. '
                        'Your next sessions will be available in '
                        '${_formatRemaining(_resetIn)}.'
                    : expired
                        ? 'Unlock ${RemoteConfigService.instance.rewardAdFreeDuration} minutes of ad-free usage across all '
                            'mortgage tools by watching a short rewarded ad.'
                        : showExtend
                            ? 'Your session is almost over. Watch another '
                                'rewarded ad to add ${RemoteConfigService.instance.rewardAdFreeDuration} more minutes.'
                            : 'Enjoy your clean, distraction-free '
                                'calculation workspace.',
                style: AppTextStyles.dmSans(
                  size: 14,
                  color: textMuted,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // ── Countdown card ────────────────────────────────────────────
              if (isActive) ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: showExtend
                        ? (isDark
                            ? const Color(0xFF1C1005)
                            : const Color(0xFFFFFBEB))
                        : cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: showExtend
                          ? _C.amber.withValues(alpha: 0.40)
                          : _timerColor.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'REMAINING TIME',
                        style: AppTextStyles.dmSans(
                          size: 11,
                          color: _timerColor,
                          weight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatRemaining(_remaining),
                        style: AppTextStyles.dmSans(
                          size: 26,
                          color: _timerColor,
                          weight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Window usage indicator ────────────────────────────────────
              _WindowUsageIndicator(
                cap: AdFreeManager.kWindowAdCap,
                used: AdFreeManager.kWindowAdCap -
                    AdFreeManager.instance.adsRemainingInWindow,
                isDark: isDark,
                textNavy: textNavy,
                textMuted: textMuted,
              ),
              const SizedBox(height: 16),

              // ── Warning notice ────────────────────────────────────────────
              if (showExtend) ...[
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1C1005)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.amber.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('⚠️', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ads will resume when this session ends. '
                          'Watch an ad now to add ${RemoteConfigService.instance.rewardAdFreeDuration} more minutes.',
                          style: AppTextStyles.dmSans(
                            size: 12,
                            color: isDark ? const Color(0xFFFBBF24) : _C.warn,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Reset countdown ───────────────────────────────────────────
              if (expired && !_canWatch) ...[
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1F2937)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.muted.withValues(alpha: 0.20)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'NEXT WINDOW OPENS IN',
                        style: AppTextStyles.dmSans(
                          size: 11,
                          color: textMuted,
                          weight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatResetIn(_resetIn),
                        style: AppTextStyles.dmSans(
                          size: 22,
                          color: textNavy,
                          weight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Primary CTA ───────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: canAct ? _handleWatchAd : null,
                  icon: Icon(
                    showExtend
                        ? Icons.timer_outlined
                        : expired && !_canWatch
                            ? Icons.lock_clock_outlined
                            : Icons.play_circle_fill,
                    color: canAct
                        ? (showExtend ? _C.navy : Colors.white)
                        : textMuted,
                  ),
                  label: Text(
                    _adRequested
                        ? 'Opening Ad…'
                        : expired && !_canWatch
                            ? 'Window Limit Reached'
                            : expired
                                ? 'Watch Ad to Unlock  ($_adsLeft left)'
                                : showExtend
                                    ? 'Extend Now — Add ${RemoteConfigService.instance.rewardAdFreeDuration} Min'
                                    : 'Session Running',
                    style: AppTextStyles.dmSans(
                      size: 15,
                      color: canAct
                          ? (showExtend ? _C.navy : Colors.white)
                          : textMuted,
                      weight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canAct
                        ? (showExtend ? _C.amber : _C.teal)
                        : (isDark
                            ? const Color(0xFF374151)
                            : const Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFE5E7EB),
                    disabledForegroundColor: textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Dismiss ───────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    isActive ? 'Close' : 'No Thanks',
                    style: AppTextStyles.dmSans(
                      size: 14,
                      color: textMuted,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _formatRemaining(Duration r) {
    if (r == Duration.zero) return '00:00';
    final m = r.inMinutes;
    final s = r.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatResetIn(Duration d) {
    if (d == Duration.zero) return '—';
    if (d.inHours >= 1) {
      final h = d.inHours;
      final m = d.inMinutes % 60;
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    }
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
  }
}

// ── Window usage indicator ────────────────────────────────────────────────
class _WindowUsageIndicator extends StatelessWidget {
  final int cap;
  final int used;
  final bool isDark;
  final Color textNavy;
  final Color textMuted;

  const _WindowUsageIndicator({
    required this.cap,
    required this.used,
    required this.isDark,
    required this.textNavy,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'SESSIONS THIS WINDOW',
          style: TextStyle(
            fontSize: 10,
            color: textMuted,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(cap, (i) {
            final isUsed = i < used;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUsed
                    ? _C.teal.withValues(alpha: 0.15)
                    : (isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFF3F4F6)),
                border: Border.all(
                  color: isUsed
                      ? _C.teal.withValues(alpha: 0.50)
                      : _C.muted.withValues(alpha: 0.20),
                  width: 1.5,
                ),
              ),
              child: Icon(
                isUsed ? Icons.check_rounded : Icons.play_arrow_rounded,
                size: 18,
                color: isUsed ? _C.teal : _C.muted.withValues(alpha: 0.40),
              ),
            );
          }),
        ),
      ],
    );
  }
}
