// lib/services/performance_service.dart

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

import 'crashlytics_service.dart';

// ── TraceHandle ───────────────────────────────────────────────────────────────

/// A thin wrapper around [Trace] that exposes stop(), putAttribute(),
/// and incrementMetric() with safe error handling.
///
/// Obtain instances exclusively via [PerformanceService] factory methods —
/// never construct directly.
class TraceHandle {
  TraceHandle._(this._trace);

  final Trace _trace;

  /// Stops the trace and records its duration to Firebase Performance.
  /// Safe to call multiple times — subsequent calls are no-ops.
  /// Never throws.
  void stop() {
    try {
      _trace.stop();
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'TraceHandle.stop() failed',
      );
    }
  }

  /// Adds or updates a custom string attribute on this trace.
  ///
  /// [key]   max 32 characters, alphanumeric + underscore.
  /// [value] max 100 characters.
  /// Never throws.
  void putAttribute(String key, String value) {
    try {
      _trace.putAttribute(key, value);
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'TraceHandle.putAttribute() failed — key: $key',
      );
    }
  }

  /// Increments a custom counter metric on this trace by [value].
  ///
  /// [metric] max 32 characters, alphanumeric + underscore.
  /// [value]  the amount to increment (may be negative to decrement).
  /// Never throws.
  void incrementMetric(String metric, int value) {
    try {
      _trace.incrementMetric(metric, value);
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'TraceHandle.incrementMetric() failed — metric: $metric',
      );
    }
  }
}

// ── PerformanceService ────────────────────────────────────────────────────────

/// PerformanceService — Centralised Firebase Performance tracing for
/// MortgagePro Global.
///
/// All methods return a [TraceHandle]. Call [TraceHandle.stop()] when the
/// measured operation completes.
///
/// All failures are caught and forwarded to [CrashlyticsService.recordError()].
/// No method ever throws or crashes the app.
class PerformanceService {
  // ── Singleton ─────────────────────────────────────────────────────────────
  PerformanceService._();
  static final PerformanceService instance = PerformanceService._();

  // ── Init ──────────────────────────────────────────────────────────────────

  /// Enables or disables Firebase Performance data collection.
  ///
  /// Collection is disabled in debug mode to avoid polluting production
  /// dashboards with development data.
  static Future<void> init() async {
    try {
      await FirebasePerformance.instance
          .setPerformanceCollectionEnabled(!kDebugMode);
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'PerformanceService.init() failed',
      );
      // Continue — performance monitoring is non-critical.
    }
  }

  // ── Core factory ─────────────────────────────────────────────────────────

  /// Creates, starts, and returns a [TraceHandle] for the given [name].
  ///
  /// Trace names must be ≤ 100 characters, contain only alphanumeric
  /// characters, underscores, hyphens, and spaces, and must not start
  /// with an underscore.
  ///
  /// Returns a no-op [TraceHandle] backed by a stopped trace on failure.
  static Future<TraceHandle> startTrace(String name) async {
    try {
      final trace = FirebasePerformance.instance.newTrace(name);
      await trace.start();
      return TraceHandle._(trace);
    } catch (e, s) {
      CrashlyticsService.recordError(
        e,
        s,
        reason: 'PerformanceService.startTrace() failed — name: $name',
      );
      // Return a no-op handle so callers never have to null-check.
      return _noOpHandle();
    }
  }

  // ── Named convenience traces ──────────────────────────────────────────────

  /// Measures the full app startup sequence (steps 1–9 in main.dart).
  ///
  /// Start before Firebase.initializeApp(); stop inside runApp().
  static Future<TraceHandle> traceAppStartup() async {
    return startTrace('app_startup');
  }

  /// Measures the time taken to render [screenName] from route push to
  /// first meaningful frame.
  ///
  /// [screenName] must be a snake_case identifier, e.g. "usa_screen".
  static Future<TraceHandle> traceScreenRender(String screenName) async {
    return startTrace('screen_render_$screenName');
  }

  /// Measures a Firestore read or write against [collection].
  ///
  /// [collection] should be the top-level collection name, e.g. "calculations".
  static Future<TraceHandle> traceFirestoreRequest(String collection) async {
    return startTrace('firestore_$collection');
  }

  /// Measures an outbound HTTP/API request to [endpoint].
  ///
  /// [endpoint] should be a stable, non-PII identifier,
  /// e.g. "exchange_rates" or "mortgage_limits".
  static Future<TraceHandle> traceApiRequest(String endpoint) async {
    return startTrace('api_$endpoint');
  }

  /// Measures the time taken to generate a PDF amortisation report.
  static Future<TraceHandle> tracePdfGeneration() async {
    return startTrace('pdf_generation');
  }

  /// Measures the ad loading latency for [adType].
  ///
  /// [adType] — one of: "banner", "native", "interstitial", "rewarded".
  static Future<TraceHandle> traceAdLoading(String adType) async {
    return startTrace('ad_load_$adType');
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  /// Returns a [TraceHandle] wrapping an already-stopped trace.
  /// Used as a safe fallback when [startTrace] itself fails.
  static Future<TraceHandle> _noOpHandle() async {
    try {
      // Create a trace, start it, and immediately stop it so it is in a
      // defined terminal state. All subsequent calls on the handle are no-ops.
      final trace = FirebasePerformance.instance.newTrace('_noop');
      await trace.start();
      await trace.stop();
      return TraceHandle._(trace);
    } catch (_) {
      // If even the no-op construction fails, rethrow into a dummy trace
      // via a minimal Trace-compatible shell. Since Trace is a final SDK
      // class we cannot subclass it, so we create a second attempt with a
      // different name and swallow all errors on the returned handle.
      final trace = FirebasePerformance.instance.newTrace('_noop_fallback');
      try {
        await trace.start();
        await trace.stop();
      } catch (_) {
        // Intentionally swallowed — this is the deepest fallback path.
      }
      return TraceHandle._(trace);
    }
  }
}
