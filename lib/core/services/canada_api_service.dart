// lib/core/services/canada_api_service.dart
// Centralized API service for Canada data — Bank of Canada (BoC) Valet API
// Caches observations in-memory (TTL: 60 min)
// Clean offline fallbacks to avoid crashes when APIs are unreachable.

import 'dart:async';
import 'package:dio/dio.dart';
import 'usa_api_service.dart'; // Reuses LiveRate and CacheEntry structure

class _CacheEntry {
  final dynamic value;
  final DateTime fetchedAt;
  const _CacheEntry(this.value, this.fetchedAt);
  bool isExpired(Duration ttl) => DateTime.now().difference(fetchedAt) > ttl;
}

class CanadaApiService {
  CanadaApiService._();
  static final CanadaApiService instance = CanadaApiService._();

  static const _bocBase = 'https://www.bankofcanada.ca/valet/observations';
  static const _ratesTtl = Duration(minutes: 60);

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 8),
  ));

  final Map<String, _CacheEntry> _cache = {};

  // Historical defaults (2025-2026 typical cycle levels)
  static const Map<String, double> _bocFallbacks = {
    'V39079': 2.25,      // Policy overnight rate
    'V80691311': 4.45,   // Canadian Retail Prime rate
    'V80691335': 6.09,   // 5-Year conventional benchmark mortgage
    'FXUSDCAD': 1.3977,  // USD/CAD exchange rate
    // New series
    'V122495': 4.45,     // Prime Business Loan Rate (alt key)
    'V39051': 3.75,      // Canadian 5-Year Govt Bond Yield
    'V39052': 3.95,      // Canadian 10-Year Govt Bond Yield
  };

  /// Fetch a rate from Bank of Canada Valet API
  Future<LiveRate> fetchBocRate(String seriesId) async {
    final cacheKey = 'boc_$seriesId';
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired(_ratesTtl)) {
      return cached.value as LiveRate;
    }

    try {
      final response = await _dio.get('$_bocBase/$seriesId/json', queryParameters: {
        'recent': 5,
      });

      final observations = response.data['observations'] as List?;
      if (observations == null || observations.isEmpty) {
        return _bocFallback(seriesId);
      }

      // Find most recent observation with a valid value
      for (final obs in observations) {
        final valMap = obs[seriesId] as Map?;
        final valStr = valMap?['v']?.toString();
        if (valStr == null || valStr.isEmpty || valStr == 'null') continue;
        final val = double.tryParse(valStr);
        if (val == null) continue;

        final rate = LiveRate(
          value: val,
          source: 'Bank of Canada',
          fetchedAt: DateTime.now(),
          isLive: true,
        );
        _cache[cacheKey] = _CacheEntry(rate, DateTime.now());
        return rate;
      }
      return _bocFallback(seriesId);
    } catch (_) {
      return _bocFallback(seriesId);
    }
  }

  LiveRate _bocFallback(String seriesId) => LiveRate(
        value: _bocFallbacks[seriesId] ?? 4.99,
        source: 'est.',
        fetchedAt: DateTime.now(),
        isLive: false,
      );

  /// Fetch all core Canada rates (original 4 series)
  Future<CanadaMortgageRatesModel> fetchAllCanadaRates() async {
    final results = await Future.wait([
      fetchBocRate('V39079'),
      fetchBocRate('V80691311'),
      fetchBocRate('V80691335'),
      fetchBocRate('FXUSDCAD'),
    ]);

    return CanadaMortgageRatesModel(
      overnight: results[0],
      prime: results[1],
      benchmark5yr: results[2],
      usdCadFx: results[3],
    );
  }

  /// Fetch extended Canada rates — adds bond yields and alternate prime series
  Future<CanadaMortgageRatesModelExtended> fetchAllCanadaRatesExtended() async {
    final results = await Future.wait([
      fetchBocRate('V39079'),      // Overnight target rate
      fetchBocRate('V80691311'),   // Retail Prime rate
      fetchBocRate('V80691335'),   // 5-yr conventional benchmark
      fetchBocRate('FXUSDCAD'),    // USD/CAD FX
      fetchBocRate('V122495'),     // Prime Business Loan Rate
      fetchBocRate('V39051'),      // 5-yr Govt Bond Yield
      fetchBocRate('V39052'),      // 10-yr Govt Bond Yield
    ]);

    return CanadaMortgageRatesModelExtended(
      overnight: results[0],
      prime: results[1],
      benchmark5yr: results[2],
      usdCadFx: results[3],
      primeBusiness: results[4],
      bond5yr: results[5],
      bond10yr: results[6],
    );
  }
}

// ─── Core model (4 series) ───────────────────────────────────────────────────
class CanadaMortgageRatesModel {
  final LiveRate overnight;
  final LiveRate prime;
  final LiveRate benchmark5yr;
  final LiveRate usdCadFx;

  const CanadaMortgageRatesModel({
    required this.overnight,
    required this.prime,
    required this.benchmark5yr,
    required this.usdCadFx,
  });
}

// ─── Extended model (7 series) ───────────────────────────────────────────────
class CanadaMortgageRatesModelExtended {
  final LiveRate overnight;
  final LiveRate prime;
  final LiveRate benchmark5yr;
  final LiveRate usdCadFx;
  final LiveRate primeBusiness;
  final LiveRate bond5yr;
  final LiveRate bond10yr;

  const CanadaMortgageRatesModelExtended({
    required this.overnight,
    required this.prime,
    required this.benchmark5yr,
    required this.usdCadFx,
    required this.primeBusiness,
    required this.bond5yr,
    required this.bond10yr,
  });
}
