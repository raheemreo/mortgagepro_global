// lib/core/services/ecb_api_service.dart
// ECB Data Portal — No API key required. Completely open.
// SDMX-JSON format: dataSets[0].observations['0:0:0:0:0'][0]
// All calls cached in-memory (TTL: 60 min).
// Falls back to 2025 Q2 hardcoded defaults so screens never crash.

import 'dart:async';
import 'package:dio/dio.dart';
import 'usa_api_service.dart'; // re-use LiveRate only

// ─── Local cache entry (TTL wrapper) ─────────────────────────────────────────
class _CacheEntry {
  final Object value;
  final DateTime createdAt;
  const _CacheEntry(this.value, this.createdAt);
  bool isExpired(Duration ttl) => DateTime.now().difference(createdAt) > ttl;
}

// ─── ECB Series Keys ─────────────────────────────────────────────────────────
// Each entry: (flowRef, seriesKey)
class _EcbSeries {
  final String flow;
  final String key;
  const _EcbSeries(this.flow, this.key);
}

// ─── ECB Rates Data Model ─────────────────────────────────────────────────────
class EuropeRatesModel {
  final LiveRate ecbRate;       // Main Refinancing Rate
  final LiveRate euribor3m;     // 3-Month Euribor
  final LiveRate euribor6m;     // 6-Month Euribor
  final LiveRate euribor12m;    // 12-Month Euribor
  final LiveRate cpiInflation;  // Eurozone CPI (HICP, monthly)
  final LiveRate eurUsd;        // EUR/USD exchange rate
  final LiveRate eurGbp;        // EUR/GBP exchange rate

  const EuropeRatesModel({
    required this.ecbRate,
    required this.euribor3m,
    required this.euribor6m,
    required this.euribor12m,
    required this.cpiInflation,
    required this.eurUsd,
    required this.eurGbp,
  });
}

// ─── ECB API Service ─────────────────────────────────────────────────────────
class EcbApiService {
  EcbApiService._();
  static final EcbApiService instance = EcbApiService._();

  static const _base = 'https://data-api.ecb.europa.eu/service/data';
  static const _ratesTtl = Duration(minutes: 60);

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 12),
    sendTimeout: const Duration(seconds: 8),
    headers: {'Accept': 'application/json'},
  ));

  final Map<String, _CacheEntry> _cache = {};

  // ── Series definitions ───────────────────────────────────────────────────
  static const _ecbRateSeries   = _EcbSeries('FM', 'B.U2.EUR.RT0.BB.1000.M');
  static const _euribor3mSeries = _EcbSeries('FM', 'B.U2.EUR.RT0.MM.EURIBOR3MD_.HSTA');
  static const _euribor6mSeries = _EcbSeries('FM', 'B.U2.EUR.RT0.MM.EURIBOR6MD_.HSTA');
  static const _euribor12mSeries= _EcbSeries('FM', 'B.U2.EUR.RT0.MM.EURIBOR1YD_.HSTA');
  static const _cpiSeries       = _EcbSeries('ICP', 'M.U2.N.000000.4.ANR');
  static const _eurUsdSeries    = _EcbSeries('EXR', 'D.USD.EUR.SP00.A');
  static const _eurGbpSeries    = _EcbSeries('EXR', 'D.GBP.EUR.SP00.A');

  // ── Hardcoded 2025 Q2 fallbacks ──────────────────────────────────────────
  static const Map<String, double> _fallbacks = {
    'FM/B.U2.EUR.RT0.BB.1000.M':               4.00,   // ECB main rate
    'FM/B.U2.EUR.RT0.MM.EURIBOR3MD_.HSTA':     3.65,   // Euribor 3M
    'FM/B.U2.EUR.RT0.MM.EURIBOR6MD_.HSTA':     3.42,   // Euribor 6M
    'FM/B.U2.EUR.RT0.MM.EURIBOR1YD_.HSTA':     3.17,   // Euribor 12M
    'ICP/M.U2.N.000000.4.ANR':                 2.20,   // CPI inflation
    'EXR/D.USD.EUR.SP00.A':                    1.0875, // EUR/USD
    'EXR/D.GBP.EUR.SP00.A':                    0.8420, // EUR/GBP
  };

  // ── Core SDMX-JSON fetch ─────────────────────────────────────────────────
  Future<LiveRate> _fetchSeries(_EcbSeries s) async {
    final cacheKey = '${s.flow}/${s.key}';
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired(_ratesTtl)) {
      return cached.value as LiveRate;
    }

    try {
      final url = '$_base/${s.flow}/${s.key}?lastNObservations=1&format=jsondata';
      final res = await _dio.get(url);

      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        final obs = (data['dataSets'][0]['observations'] as Map<String, dynamic>);
        final firstKey = obs.keys.first;
        final value = (obs[firstKey][0] as num).toDouble();

        final rate = LiveRate(
          value: value,
          source: 'ECB Data Portal',
          fetchedAt: DateTime.now(),
          isLive: true,
        );
        _cache[cacheKey] = _CacheEntry(rate, DateTime.now());
        return rate;
      }
    } catch (_) {
      // fall through to fallback
    }

    final fallbackVal = _fallbacks[cacheKey] ?? 0.0;
    return LiveRate(
      value: fallbackVal,
      source: 'ECB (estimated)',
      fetchedAt: DateTime.now(),
      isLive: false,
    );
  }

  // ── Convenience individual fetchers ─────────────────────────────────────
  Future<LiveRate> fetchEcbRate()     => _fetchSeries(_ecbRateSeries);
  Future<LiveRate> fetchEuribor3m()   => _fetchSeries(_euribor3mSeries);
  Future<LiveRate> fetchEuribor6m()   => _fetchSeries(_euribor6mSeries);
  Future<LiveRate> fetchEuribor12m()  => _fetchSeries(_euribor12mSeries);
  Future<LiveRate> fetchCpi()         => _fetchSeries(_cpiSeries);
  Future<LiveRate> fetchEurUsd()      => _fetchSeries(_eurUsdSeries);
  Future<LiveRate> fetchEurGbp()      => _fetchSeries(_eurGbpSeries);

  // ── Combined fetch — called by the provider ──────────────────────────────
  Future<EuropeRatesModel> fetchAllEuropeRates() async {
    // Fire all requests concurrently — any failure falls back independently
    final results = await Future.wait([
      _fetchSeries(_ecbRateSeries),
      _fetchSeries(_euribor3mSeries),
      _fetchSeries(_euribor6mSeries),
      _fetchSeries(_euribor12mSeries),
      _fetchSeries(_cpiSeries),
      _fetchSeries(_eurUsdSeries),
      _fetchSeries(_eurGbpSeries),
    ]);

    return EuropeRatesModel(
      ecbRate:      results[0],
      euribor3m:    results[1],
      euribor6m:    results[2],
      euribor12m:   results[3],
      cpiInflation: results[4],
      eurUsd:       results[5],
      eurGbp:       results[6],
    );
  }

  /// Clear cache (useful for pull-to-refresh)
  void clearCache() => _cache.clear();
}
