// lib/core/analytics/screen_timer_mixin.dart
//
// Measures how long the user spends on a screen and fires
// AnalyticsService.logScreenDuration() when the widget is disposed.
// Skips logging if the dwell time is less than 3 seconds.
//
// ══════════════════════════════════════════════════════
// USAGE — add to any StatefulWidget's State:
//
//   class _UsaScreenState extends State<UsaScreen>
//       with ScreenTimerMixin {
//
//     @override
//     String get screenName => AnalyticsScreen.usa; // ← required
//
//     @override
//     void initState() {
//       super.initState();
//       startScreenTimer();
//     }
//
//     @override
//     void dispose() {
//       stopScreenTimer();
//       super.dispose();
//     }
//   }
//
// ══════════════════════════════════════════════════════
// CONTRACT:
//   - screenName MUST return an AnalyticsScreen constant.
//     No default is provided — omitting the override is a compile error.
//   - Never return widget.runtimeType.toString()
//   - Never return route paths or URLs
//   - startScreenTimer() is idempotent — safe to call multiple times.
//   - stopScreenTimer() is idempotent — safe to call multiple times.
//   - Duration < 3 seconds is not logged (not meaningful for analytics).
// ══════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../services/analytics/analytics_screen.dart';
import '../../services/analytics_service.dart';

mixin ScreenTimerMixin<T extends StatefulWidget> on State<T> {
  // ── Required override ─────────────────────────────────────────────────────

  /// Must return an [AnalyticsScreen] constant.
  ///
  /// There is no default implementation — omitting this override
  /// produces a compile error, which is intentional.
  ///
  /// Never return:
  ///   - widget.runtimeType.toString()
  ///   - Route paths or URLs ("/usa", "UsaScreen")
  ///   - Dynamically constructed strings
  String get screenName;

  // ── Private state ─────────────────────────────────────────────────────────
  final Stopwatch _stopwatch = Stopwatch();
  bool _started = false;
  bool _stopped = false;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Starts the stopwatch. Call from [initState].
  /// Idempotent — safe to call multiple times.
  @protected
  void startScreenTimer() {
    if (_started) return;
    _started = true;

    // Debug: validate screenName against AnalyticsScreen.all at startup.
    assert(
      AnalyticsScreen.all.contains(screenName),
      'ScreenTimerMixin: screenName "$screenName" is not in '
      'AnalyticsScreen.all. Add it there first.',
    );

    _stopwatch.start();
  }

  /// Stops the stopwatch and fires [logScreenDuration]. Call from [dispose].
  /// Idempotent — safe to call multiple times.
  /// Skips logging if duration < 3 seconds.
  @protected
  void stopScreenTimer() {
    if (!_started || _stopped) return;
    _stopped = true;
    _stopwatch.stop();

    final seconds = _stopwatch.elapsed.inSeconds;
    _stopwatch.reset();

    // Reset flags so the timer can be started again on subsequent visits (e.g. tabs).
    _started = false;
    _stopped = false;

    // Enforce 3-second minimum — short visits are noise, not signal.
    if (seconds < 3) return;

    // Release: validate screenName before sending to Firebase.
    if (!kDebugMode && !AnalyticsScreen.all.contains(screenName)) return;

    AnalyticsService.instance.logScreenDuration(screenName, seconds);
  }
}
