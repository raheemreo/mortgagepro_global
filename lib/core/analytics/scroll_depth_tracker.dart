// lib/core/analytics/scroll_depth_tracker.dart
//
// Attaches to a ScrollController and fires
// AnalyticsService.logScrollDepth() at 25/50/75/100% milestones —
// exactly once per screen session regardless of back-scrolling.
//
// ══════════════════════════════════════════════════════
// USAGE — in a StatefulWidget:
//
//   late final ScrollController _scrollCtrl;
//   late final ScrollDepthTracker _scrollTracker;
//
//   @override
//   void initState() {
//     super.initState();
//     _scrollCtrl = ScrollController();
//     _scrollTracker = ScrollDepthTracker(
//       controller: _scrollCtrl,
//       screenName: AnalyticsScreen.usa,
//     );
//   }
//
//   @override
//   void dispose() {
//     _scrollTracker.dispose(); // removes listener — does NOT dispose controller
//     _scrollCtrl.dispose();
//     super.dispose();
//   }
//
//   // In build():
//   //   ListView(controller: _scrollCtrl, ...)
//
// ══════════════════════════════════════════════════════
// SCROLL VIEW SUPPORT:
//   ✅ ListView               — works immediately after layout.
//   ✅ SingleChildScrollView  — same as ListView.
//   ⚠️  CustomScrollView (slivers) — maxScrollExtent may return 0 until
//       sliver children are fully measured. If 100% is never reached,
//       add a post-frame callback after layout to trigger _onScroll()
//       manually, or use LayoutBuilder-aware sliver measurement.
// ══════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../services/analytics/analytics_screen.dart';
import '../../services/analytics/analytics_feature.dart';
import '../../services/analytics_service.dart';

class ScrollDepthTracker {
  ScrollDepthTracker({
    required this.controller,
    required this.screenName,
    this.isActive,
  }) {
    // Debug: validate screenName at construction time.
    assert(
      AnalyticsScreen.all.contains(screenName),
      'ScrollDepthTracker: screenName "$screenName" is not in '
      'AnalyticsScreen.all. Add it there first.',
    );

    // Release: report invalid screenName and bail out gracefully.
    if (!kDebugMode && !AnalyticsScreen.all.contains(screenName)) {
      AnalyticsService.instance.logFeatureError(
        feature: AnalyticsFeature.navigation,
        exception: 'ScrollDepthTracker: invalid screenName "$screenName"',
      );
      _valid = false;
      return;
    }

    controller.addListener(_onScroll);
  }

  /// The ScrollController attached to the scrollable widget.
  final ScrollController controller;

  /// Must be an [AnalyticsScreen] constant — validated at construction.
  final String screenName;

  /// Optional callback to check if the tracker is currently active.
  final bool Function()? isActive;

  /// False if screenName failed validation — all calls become no-ops.
  bool _valid = true;

  // Milestones in ascending order.
  static const List<int> _milestones = [25, 50, 75, 100];

  // Tracks which milestones have already fired this session.
  final Set<int> _fired = {};

  void _onScroll() {
    if (!_valid) return;
    if (isActive != null && !isActive!()) return;
    if (!controller.hasClients) return;

    final pos = controller.position;
    if (!pos.hasContentDimensions) return;

    final maxExtent = pos.maxScrollExtent;
    if (maxExtent <= 0) return; // content fits in viewport — no scroll needed

    final pixels = pos.pixels.clamp(0.0, maxExtent);
    final percent = ((pixels / maxExtent) * 100).round();

    for (final milestone in _milestones) {
      if (!_fired.contains(milestone) && percent >= milestone) {
        _fired.add(milestone);
        AnalyticsService.instance.logScrollDepth(screenName, milestone);
      }
    }
  }

  /// Removes the scroll listener. Call from [dispose()].
  ///
  /// Does NOT dispose the [controller] — the owning widget is responsible.
  void dispose() {
    if (_valid) {
      controller.removeListener(_onScroll);
    }
  }
}
