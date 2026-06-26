// lib/core/services/boe_api_service.dart
// Bank of England Statistical Interactive Database (IADB) — No API key required.
// Returns CSV. Last non-empty data row = current value.
// All calls are cached in-memory (TTL: 60 min).
// Falls back to hardcoded 2025 Q2 defaults so screens never crash.

import 'package:dio/dio.dart';
import 'usa_api_service.dart'; // re-use LiveRate only

// ─── Local cache entry ────────────────────────────────────────────────────────
class _CacheEntry {
  final Object value;
  final DateTime createdAt;
  const _CacheEntry(this.value, this.createdAt);
  bool isExpired(Duration ttl) => DateTime.now().difference(createdAt) > ttl;
}

// ─── UK Rates Data Model ─────────────────────────────────────────────────────
class UKRatesModel {
  final LiveRate boeBase;   // BoE Official Bank Rate
  final LiveRate gilt2yr;   // 2-Year Gilt Yield
  final LiveRate gilt5yr;   // 5-Year Gilt Yield
  final LiveRate gilt10yr;  // 10-Year Gilt Yield
  final LiveRate fixed2yr;  // 2-Yr Fixed Mortgage avg (75% LTV)
  final LiveRate fixed5yr;  // 5-Yr Fixed Mortgage avg (75% LTV)
  final LiveRate svr;       // Standard Variable Rate
  final LiveRate gbpUsd;    // GBP/USD exchange rate
  final bool isLive;

  const UKRatesModel({
    required this.boeBase,
    required this.gilt2yr,
    required this.gilt5yr,
    required this.gilt10yr,
    required this.fixed2yr,
    required this.fixed5yr,
    required this.svr,
    required this.gbpUsd,
    required this.isLive,
  });

  /// Tracker rate = BoE base + 0.25 (typical tracker spread)
  double get trackerRate => boeBase.value + 0.25;
}

// ─── BoE API Service ─────────────────────────────────────────────────────────
class BoeApiService {
  BoeApiService._();
  static final BoeApiService instance = BoeApiService._();

  static const _ratesTtl = Duration(minutes: 60);
  static const _base =
      'https://www.bankofengland.co.uk/boeapps/database/fromshowcolumns.asp';

  // Wide date range — no annual maintenance needed
  static const _dateParams =
      'DAT=RNG&FD=1&FM=Jan&FY=2024&TD=31&TM=Dec&TY=2026&VFD=Y';

  final Map<String, _CacheEntry> _cache = {};

  // ── Hardcoded 2025 Q2 fallbacks ──────────────────────────────────────────
  static const Map<String, double> _fallbacks = {
    'IUDBEDR':  4.25,   // BoE Official Bank Rate
    'IUDMNPY2': 4.30,   // 2-Year Gilt Yield
    'IUDMNPY5': 4.10,   // 5-Year Gilt Yield
    'IUDMNPY10':4.35,   // 10-Year Gilt Yield
    'IUMBV34':  4.75,   // 2-Yr Fixed Mortgage (75% LTV)
    'IUMBV42':  4.35,   // 5-Yr Fixed Mortgage (75% LTV)
    'IUMB6V':   7.10,   // SVR
    'XUMAUSS':  1.270,  // GBP/USD
  };

  // ── Core CSV fetch ───────────────────────────────────────────────────────
  Future<LiveRate> _fetchSeries(String seriesCode) async {
    final cached = _cache[seriesCode];
    if (cached != null && !cached.isExpired(_ratesTtl)) {
      return cached.value as LiveRate;
    }

    try {
      final uri =
        '$_base?SeriesCodes=$seriesCode&CSVF=TT&UsingCodes=Y&$_dateParams';
      final res = await Dio().get<String>(
        uri,
        options: Options(
          receiveTimeout: const Duration(seconds: 12),
          responseType: ResponseType.plain,
        ),
      );

      if (res.statusCode == 200 && res.data != null) {
        final lines = res.data!
            .trim()
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .toList();

        // Skip header lines (those containing letters in the value column)
        // Data lines are: "DD Mon YYYY,VALUE"
        String? lastValue;
        for (final line in lines.reversed) {
          final parts = line.split(',');
          if (parts.length >= 2) {
            final val = parts[1].trim();
            final parsed = double.tryParse(val);
            if (parsed != null) {
              lastValue = val;
              break;
            }
          }
        }

        if (lastValue != null) {
          final rate = LiveRate(
            value: double.parse(lastValue),
            source: 'BoE IADB',
            fetchedAt: DateTime.now(),
            isLive: true,
          );
          _cache[seriesCode] = _CacheEntry(rate, DateTime.now());
          return rate;
        }
      }
    } catch (_) {
      // fall through to fallback
    }

    // Fallback
    final fallbackVal = _fallbacks[seriesCode] ?? 0.0;
    return LiveRate(
      value: fallbackVal,
      source: 'BoE (estimated)',
      fetchedAt: DateTime.now(),
      isLive: false,
    );
  }

  // ── Convenience fetchers ─────────────────────────────────────────────────
  Future<LiveRate> fetchBoeBase()   => _fetchSeries('IUDBEDR');
  Future<LiveRate> fetchGilt2yr()   => _fetchSeries('IUDMNPY2');
  Future<LiveRate> fetchGilt5yr()   => _fetchSeries('IUDMNPY5');
  Future<LiveRate> fetchGilt10yr()  => _fetchSeries('IUDMNPY10');
  Future<LiveRate> fetchFixed2yr()  => _fetchSeries('IUMBV34');
  Future<LiveRate> fetchFixed5yr()  => _fetchSeries('IUMBV42');
  Future<LiveRate> fetchSvr()       => _fetchSeries('IUMB6V');
  Future<LiveRate> fetchGbpUsd()    => _fetchSeries('XUMAUSS');

  // ── Historical series for charts (wider range) ───────────────────────────
  /// Fetches historical data for the BoE Base Rate tracker chart.
  /// Returns a list of (date, value) pairs sorted oldest → newest.
  Future<List<(String, double)>> fetchBoeBaseHistory() async {
    const cacheKey = 'IUDBEDR_HISTORY';
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired(_ratesTtl)) {
      return cached.value as List<(String, double)>;
    }

    try {
      // Request 5 years of history for the chart
      const histParams =
          'DAT=RNG&FD=1&FM=Jan&FY=2020&TD=31&TM=Dec&TY=2026&VFD=Y';
      // ignore: prefer_const_declarations
      final histUri =
        '$_base?SeriesCodes=IUDBEDR&CSVF=TT&UsingCodes=Y&$histParams';
      final res = await Dio().get<String>(
        histUri,
        options: Options(
          receiveTimeout: const Duration(seconds: 15),
          responseType: ResponseType.plain,
        ),
      );

      if (res.statusCode == 200 && res.data != null) {
        final result = <(String, double)>[];
        final lines = res.data!.trim().split('\n');
        for (final line in lines) {
          final parts = line.split(',');
          if (parts.length >= 2) {
            final date = parts[0].trim();
            final val = double.tryParse(parts[1].trim());
            if (val != null && date.isNotEmpty) {
              result.add((date, val));
            }
          }
        }
        if (result.isNotEmpty) {
          _cache[cacheKey] = _CacheEntry(result, DateTime.now());
          return result;
        }
      }
    } catch (_) {
      // fall through to empty
    }

    // Fallback: static history for chart
    return [
      ('Mar 2020', 0.10), ('Dec 2021', 0.25), ('Feb 2022', 0.50),
      ('Mar 2022', 0.75), ('May 2022', 1.00), ('Jun 2022', 1.25),
      ('Aug 2022', 1.75), ('Sep 2022', 2.25), ('Nov 2022', 3.00),
      ('Dec 2022', 3.50), ('Feb 2023', 4.00), ('Mar 2023', 4.25),
      ('May 2023', 4.50), ('Jun 2023', 5.00), ('Aug 2023', 5.25),
      ('Aug 2024', 5.00), ('Nov 2024', 4.75), ('Feb 2025', 4.50),
      ('May 2025', 4.25),
    ];
  }

  // ── Combined fetch — called by the provider ──────────────────────────────
  Future<UKRatesModel> fetchAllUKRates() async {
    final results = await Future.wait([
      _fetchSeries('IUDBEDR'),
      _fetchSeries('IUDMNPY2'),
      _fetchSeries('IUDMNPY5'),
      _fetchSeries('IUDMNPY10'),
      _fetchSeries('IUMBV34'),
      _fetchSeries('IUMBV42'),
      _fetchSeries('IUMB6V'),
      _fetchSeries('XUMAUSS'),
    ]);

    final anyLive = results.any((r) => r.isLive);
    return UKRatesModel(
      boeBase:  results[0],
      gilt2yr:  results[1],
      gilt5yr:  results[2],
      gilt10yr: results[3],
      fixed2yr: results[4],
      fixed5yr: results[5],
      svr:      results[6],
      gbpUsd:   results[7],
      isLive:   anyLive,
    );
  }

  /// Clear cache (useful for pull-to-refresh)
  void clearCache() => _cache.clear();
}
