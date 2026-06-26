// lib/services/ad_free_manager.dart
//
// BUG FIX — unlockFor() now always resets to DateTime.now() + duration.
// The original code added duration on top of _expiryTime when a session
// was still active ("extend" path), which caused the 20-minute timer bug:
//   ~10 min remaining + 10 min added = ~20 min displayed.
//
// The rewardPending mutex was also added as a belt-and-suspenders guard:
// even if AdManager's _rewardGranted flag somehow fails (e.g. different
// call path), a second concurrent unlockFor() call returns immediately.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_manager.dart';
import 'ad_free_analytics_tracker.dart';
import 'remote_config_service.dart';

final adFreeActiveProvider = StateProvider<bool>((ref) {
  return AdFreeManager.instance.isActive;
});

class AdFreeManager {
  static final AdFreeManager instance = AdFreeManager._();
  AdFreeManager._();

  // ── Dependencies ──────────────────────────────────────────────────────────
  static ProviderContainer? container;
  static late SharedPreferences _prefs;

  // ── Storage keys ──────────────────────────────────────────────────────────
  static const String _expiryKey = 'ad_free_expiry';
  static const String _firstWatchKey = 'ad_free_first_watch_at';
  static const String _windowCountKey = 'ad_free_window_count';

  // ── Configuration ─────────────────────────────────────────────────────────
  static const Duration kSessionDuration = Duration(minutes: 10);
  Duration get sessionDuration => Duration(minutes: RemoteConfigService.instance.rewardAdFreeDuration);
  static const int kWindowAdCap = 2;
  static const Duration kResetWindow = Duration(hours: 12);

  // ── Runtime state ─────────────────────────────────────────────────────────
  DateTime? _expiryTime;
  DateTime? _firstWatchAt;
  int _windowCount = 0;
  Timer? _timer;

  /// Belt-and-suspenders mutex.
  /// AdManager._rewardGranted is the primary duplicate-reward guard.
  /// This is the secondary guard at the session-grant layer.
  bool _rewardPending = false;

  // ── Init ──────────────────────────────────────────────────────────────────
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await instance._restoreSession();
    await instance._restoreWindowState();
  }

  Future<void> _restoreSession() async {
    final ms = _prefs.getInt(_expiryKey);
    if (ms == null) return;
    final expiry = DateTime.fromMillisecondsSinceEpoch(ms);
    if (expiry.isAfter(DateTime.now())) {
      _expiryTime = expiry;
      _startTimer();
    } else {
      await _prefs.remove(_expiryKey);
    }
  }

  Future<void> _restoreWindowState() async {
    final ms = _prefs.getInt(_firstWatchKey);
    if (ms == null) return;
    final first = DateTime.fromMillisecondsSinceEpoch(ms);
    final windowExpiry = first.add(kResetWindow);
    if (DateTime.now().isBefore(windowExpiry)) {
      _firstWatchAt = first;
      _windowCount = _prefs.getInt(_windowCountKey) ?? 0;
    } else {
      await _clearWindowState();
    }
  }

  // ── Public state ──────────────────────────────────────────────────────────

  bool get isActive {
    if (_expiryTime == null) return false;
    return _expiryTime!.isAfter(DateTime.now());
  }

  Duration get remaining {
    if (_expiryTime == null) return Duration.zero;
    final diff = _expiryTime!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  bool get canWatchAd => _windowCount < kWindowAdCap && !_rewardPending;

  int get adsRemainingInWindow => kWindowAdCap - _windowCount;

  Duration get windowResetIn {
    if (_firstWatchAt == null) return Duration.zero;
    final expiry = _firstWatchAt!.add(kResetWindow);
    final diff = expiry.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  // ── Session management ────────────────────────────────────────────────────

  /// Grants a fresh [duration] session after a rewarded ad completes.
  ///
  /// Protected by [_rewardPending] mutex so concurrent calls are safe.
  ///
  /// FIX: always sets expiry to DateTime.now() + duration.
  /// Never adds on top of remaining time — that was the 20-minute bug.
  Future<void> unlockFor(Duration duration) async {
    if (_rewardPending || !canWatchAd) return;

    _rewardPending = true;
    try {
      final isNewSession = !isActive;

      if (_firstWatchAt == null) {
        _firstWatchAt = DateTime.now();
        await _prefs.setInt(
            _firstWatchKey, _firstWatchAt!.millisecondsSinceEpoch);
      }

      _windowCount++;
      await _prefs.setInt(_windowCountKey, _windowCount);

      if (isNewSession) {
        AdFreeAnalyticsTracker.instance.trackSessionStarted();
      } else {
        AdFreeAnalyticsTracker.instance.trackSessionExtended();
      }

      // ── FIX: reset to now + duration — never stack ───────────────────────
      _expiryTime = DateTime.now().add(duration);
      await _prefs.setInt(_expiryKey, _expiryTime!.millisecondsSinceEpoch);

      AdManager.instance.clearAll();
      _startTimer();
      _updateProvider(true);
    } finally {
      _rewardPending = false;
    }
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isActive) {
        _handleExpiry();
      } else {
        _checkWindowReset();
        _updateProvider(true);
      }
    });
  }

  void _handleExpiry() {
    _timer?.cancel();
    _expiryTime = null;
    _prefs.remove(_expiryKey);
    _checkWindowReset();
    _updateProvider(false);
  }

  void _checkWindowReset() {
    if (_firstWatchAt == null) return;
    final windowExpiry = _firstWatchAt!.add(kResetWindow);
    if (DateTime.now().isAfter(windowExpiry)) {
      _clearWindowState();
    }
  }

  Future<void> _clearWindowState() async {
    _firstWatchAt = null;
    _windowCount = 0;
    await _prefs.remove(_firstWatchKey);
    await _prefs.remove(_windowCountKey);
  }

  void _updateProvider(bool active) {
    if (container != null) {
      final notifier = container!.read(adFreeActiveProvider.notifier);
      if (notifier.state != active) {
        notifier.state = active;
      }
    }
  }
}
