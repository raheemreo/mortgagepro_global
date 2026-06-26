// lib/core/services/nz_api_service.dart
// New Zealand live data service
//   • ratesapi.nz/mortgage  — NZ bank mortgage rates (free, no key, hourly)
//   • open.er-api.com       — NZD/USD, NZD/AUD, NZD/GBP FX rates (free, no key, daily)
// All data cached in-memory (TTL: 60 min rates / 24 hr FX).
// Falls back to hardcoded 2025 Q2 values so screens never crash.

import 'dart:async';
import 'package:dio/dio.dart';
import 'usa_api_service.dart'; // re-use LiveRate

// ─── Cache ────────────────────────────────────────────────────────────────────
class _CacheEntry {
  final dynamic value;
  final DateTime fetchedAt;
  const _CacheEntry(this.value, this.fetchedAt);
  bool isExpired(Duration ttl) => DateTime.now().difference(fetchedAt) > ttl;
}

// ─── NZ Rates Model ───────────────────────────────────────────────────────────
class NZRatesModel {
  // --- OCR (from Remote Config — passed in at construction) ---
  final double ocr;

  // --- Mortgage rates from ratesapi.nz ---
  final LiveRate fixed1yr;
  final LiveRate fixed2yr;
  final LiveRate fixed3yr;
  final LiveRate fixed5yr;
  final LiveRate floating;

  // --- Per-bank 1yr rates ---
  final double anz1yr;
  final double asb1yr;
  final double westpac1yr;
  final double kiwibank1yr;
  final double bnz1yr;

  // --- FX rates from open.er-api.com ---
  final LiveRate nzdUsd;
  final LiveRate nzdAud;
  final LiveRate nzdGbp;

  final bool isLive;

  const NZRatesModel({
    required this.ocr,
    required this.fixed1yr,
    required this.fixed2yr,
    required this.fixed3yr,
    required this.fixed5yr,
    required this.floating,
    required this.anz1yr,
    required this.asb1yr,
    required this.westpac1yr,
    required this.kiwibank1yr,
    required this.bnz1yr,
    required this.nzdUsd,
    required this.nzdAud,
    required this.nzdGbp,
    required this.isLive,
  });
}

// ─── NZ API Service ───────────────────────────────────────────────────────────
class NZApiService {
  NZApiService._();
  static final NZApiService instance = NZApiService._();

  static const _ratesTtl = Duration(minutes: 60);
  static const _fxTtl    = Duration(hours: 24);

  static const _ratesUrl = 'https://api.ratesapi.nz/mortgage';
  static const _fxUrl    = 'https://open.er-api.com/v6/latest/NZD';

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 10),
  ));

  final Map<String, _CacheEntry> _cache = {};

  // ── 2025 Q2 fallback values ───────────────────────────────────────────────
  // OCR cuts have reduced floating rates significantly from 2024 peaks.
  static const _fb1yr    = 5.59;
  static const _fb2yr    = 5.29;
  static const _fb3yr    = 5.19;
  static const _fb5yr    = 5.09;
  static const _fbFloat  = 7.24;
  static const _fbAnz    = 5.59;
  static const _fbAsb    = 5.59;
  static const _fbWestpac= 5.65;
  static const _fbKiwi   = 5.55;
  static const _fbBnz    = 5.59;
  static const _fbNzdUsd = 0.5995;
  static const _fbNzdAud = 0.9240;
  static const _fbNzdGbp = 0.4780;

  // ── Mortgage rates fetch ──────────────────────────────────────────────────
  Future<Map<String, dynamic>?> _fetchRatesRaw() async {
    const cacheKey = 'nz_rates';
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired(_ratesTtl)) {
      return cached.value as Map<String, dynamic>?;
    }

    try {
      final res = await _dio.get<Map<String, dynamic>>(_ratesUrl);
      if (res.statusCode == 200 && res.data != null) {
        _cache[cacheKey] = _CacheEntry(res.data, DateTime.now());
        return res.data;
      }
    } catch (_) {
      // fall through
    }
    return null;
  }

  // ── FX fetch ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> _fetchFxRaw() async {
    const cacheKey = 'nz_fx';
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired(_fxTtl)) {
      return cached.value as Map<String, dynamic>?;
    }

    try {
      final res = await _dio.get<Map<String, dynamic>>(_fxUrl);
      if (res.statusCode == 200 && res.data != null) {
        _cache[cacheKey] = _CacheEntry(res.data, DateTime.now());
        return res.data;
      }
    } catch (_) {
      // fall through
    }
    return null;
  }

  // ── Helper: safely extract a rate from ratesapi.nz bank data ─────────────
  double _bankRate(Map<String, dynamic>? data, String bank, String term, double fallback) {
    try {
      final rates = data?['rates'] as Map<String, dynamic>?;
      final bankData = rates?[bank] as Map<String, dynamic>?;
      // ratesapi.nz uses keys like "1year", "2year", "5year", "floating"
      final val = bankData?[term];
      if (val is num) return val.toDouble();
    } catch (_) {}
    return fallback;
  }

  double _avg(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  // ── Main combined fetch ───────────────────────────────────────────────────
  Future<NZRatesModel> fetchAllNZRates({double ocr = 2.25}) async {
    final results = await Future.wait([_fetchRatesRaw(), _fetchFxRaw()]);
    final ratesData = results[0];
    final fxData    = results[1];

    final ratesLive = ratesData != null;
    final fxLive    = fxData != null;

    // --- Per-bank 1yr ---
    final anz1yr      = _bankRate(ratesData, 'ANZ',      '1year',    _fbAnz);
    final asb1yr      = _bankRate(ratesData, 'ASB',      '1year',    _fbAsb);
    final westpac1yr  = _bankRate(ratesData, 'Westpac',  '1year',    _fbWestpac);
    final kiwibank1yr = _bankRate(ratesData, 'Kiwibank', '1year',    _fbKiwi);
    final bnz1yr      = _bankRate(ratesData, 'BNZ',      '1year',    _fbBnz);

    // --- Market averages ---
    final avg1yr  = ratesLive ? _avg([anz1yr, asb1yr, westpac1yr, kiwibank1yr, bnz1yr]) : _fb1yr;
    final avg2yr  = ratesLive ? _avg([
      _bankRate(ratesData, 'ANZ', '2year', _fb2yr),
      _bankRate(ratesData, 'ASB', '2year', _fb2yr),
      _bankRate(ratesData, 'Kiwibank', '2year', _fb2yr),
      _bankRate(ratesData, 'BNZ', '2year', _fb2yr),
    ]) : _fb2yr;
    final avg3yr  = ratesLive ? _avg([
      _bankRate(ratesData, 'ANZ', '3year', _fb3yr),
      _bankRate(ratesData, 'ASB', '3year', _fb3yr),
      _bankRate(ratesData, 'Kiwibank', '3year', _fb3yr),
    ]) : _fb3yr;
    final avg5yr  = ratesLive ? _avg([
      _bankRate(ratesData, 'ANZ', '5year', _fb5yr),
      _bankRate(ratesData, 'BNZ', '5year', _fb5yr),
      _bankRate(ratesData, 'Kiwibank', '5year', _fb5yr),
    ]) : _fb5yr;
    final avgFloat = ratesLive ? _avg([
      _bankRate(ratesData, 'ANZ', 'floating', _fbFloat),
      _bankRate(ratesData, 'ASB', 'floating', _fbFloat),
      _bankRate(ratesData, 'BNZ', 'floating', _fbFloat),
    ]) : _fbFloat;

    // --- FX ---
    final rates = fxData?['rates'] as Map<String, dynamic>?;
    final usdVal = (rates?['USD'] as num?)?.toDouble() ?? _fbNzdUsd;
    final audVal = (rates?['AUD'] as num?)?.toDouble() ?? _fbNzdAud;
    final gbpVal = (rates?['GBP'] as num?)?.toDouble() ?? _fbNzdGbp;

    LiveRate createRate(double v, bool live) => LiveRate(
      value: v,
      source: live ? 'live' : 'estimated',
      fetchedAt: DateTime.now(),
      isLive: live,
    );

    return NZRatesModel(
      ocr:          ocr,
      fixed1yr:     createRate(avg1yr,   ratesLive),
      fixed2yr:     createRate(avg2yr,   ratesLive),
      fixed3yr:     createRate(avg3yr,   ratesLive),
      fixed5yr:     createRate(avg5yr,   ratesLive),
      floating:     createRate(avgFloat, ratesLive),
      anz1yr:       anz1yr,
      asb1yr:       asb1yr,
      westpac1yr:   westpac1yr,
      kiwibank1yr:  kiwibank1yr,
      bnz1yr:       bnz1yr,
      nzdUsd:       createRate(usdVal, fxLive),
      nzdAud:       createRate(audVal, fxLive),
      nzdGbp:       createRate(gbpVal, fxLive),
      isLive:       ratesLive || fxLive,
    );
  }

  void clearCache() => _cache.clear();
}
