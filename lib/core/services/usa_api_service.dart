// lib/core/services/usa_api_service.dart
// Centralized API service — FRED, Alpha Vantage, Census
// All calls are cached in-memory (TTL: 60 min for rates, 24 hr for Census)
// Falls back to hardcoded defaults so screens never crash on network failure.

import 'dart:async';
import 'package:dio/dio.dart';

// ─── Cache Entry ────────────────────────────────────────────────────────────
class _CacheEntry {
  final dynamic value;
  final DateTime fetchedAt;
  const _CacheEntry(this.value, this.fetchedAt);
  bool isExpired(Duration ttl) => DateTime.now().difference(fetchedAt) > ttl;
}

// ─── Rate Data Model ─────────────────────────────────────────────────────────
class LiveRate {
  final double value;
  final String source;
  final DateTime fetchedAt;
  final bool isLive;

  const LiveRate({
    required this.value,
    required this.source,
    required this.fetchedAt,
    this.isLive = true,
  });

  /// Returns a formatted string like "6.82%"
  String get formatted => '${value.toStringAsFixed(2)}%';

  /// Age label for UI display
  String get ageLabel {
    final diff = DateTime.now().difference(fetchedAt);
    if (diff.inMinutes < 2) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─── USA API Service ─────────────────────────────────────────────────────────
class UsaApiService {
  UsaApiService._();
  static final UsaApiService instance = UsaApiService._();

  static const _fredKey = '3ead1b6ecf35e7a1c1ea79083f117ef3';
  static const _avKey = 'RBWTVEZU14NFWX0V';
  static const _censusKey = 'd461f13a152dd4d7e1562cc7876501a5bd647ff9';

  static const _fredBase = 'https://api.stlouisfed.org/fred/series/observations';
  static const _avBase = 'https://www.alphavantage.co/query';
  static const _censusBase = 'https://api.census.gov/data/2022/acs/acs1';

  static const _ratesTtl = Duration(minutes: 60);
  static const _censusTtl = Duration(hours: 24);

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 8),
  ));

  final Map<String, _CacheEntry> _cache = {};

  // ── Hardcoded fallbacks (2025 Q2 data) ──────────────────────────────────
  static const Map<String, double> _fredFallbacks = {
    'MORTGAGE30US': 6.82,
    'MORTGAGE15US': 6.11,
    'SOFR': 5.33,
    'DPRIME': 8.50,
    'FEDFUNDS': 5.33,
  };
  static const double _vnqFallback = 92.50;
  static const double _censusMedianFallback = 310000.0;

  // ── FRED API ─────────────────────────────────────────────────────────────
  Future<LiveRate> fetchFredRate(String seriesId) async {
    final cacheKey = 'fred_$seriesId';
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired(_ratesTtl)) {
      return cached.value as LiveRate;
    }

    try {
      final response = await _dio.get(_fredBase, queryParameters: {
        'series_id': seriesId,
        'api_key': _fredKey,
        'file_type': 'json',
        'sort_order': 'desc',
        'limit': 5,
        'observation_start': '2020-01-01',
      });

      final observations = (response.data['observations'] as List?)
          ?.where((o) => o['value'] != '.' && o['value'] != null)
          .toList();

      if (observations == null || observations.isEmpty) {
        return _fredFallback(seriesId);
      }

      final latest = observations.first;
      final val = double.tryParse(latest['value'].toString());
      if (val == null) return _fredFallback(seriesId);

      final rate = LiveRate(
        value: val,
        source: 'FRED',
        fetchedAt: DateTime.now(),
        isLive: true,
      );
      _cache[cacheKey] = _CacheEntry(rate, DateTime.now());
      return rate;
    } catch (_) {
      return _fredFallback(seriesId);
    }
  }

  LiveRate _fredFallback(String seriesId) => LiveRate(
        value: _fredFallbacks[seriesId] ?? 6.82,
        source: 'est.',
        fetchedAt: DateTime.now(),
        isLive: false,
      );

  // ── Alpha Vantage ────────────────────────────────────────────────────────
  Future<LiveRate> fetchAlphaVantagePrice(String symbol) async {
    final cacheKey = 'av_$symbol';
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired(_ratesTtl)) {
      return cached.value as LiveRate;
    }

    try {
      final response = await _dio.get(_avBase, queryParameters: {
        'function': 'GLOBAL_QUOTE',
        'symbol': symbol,
        'apikey': _avKey,
      });

      final quote = response.data['Global Quote'] as Map<String, dynamic>?;
      if (quote == null || quote.isEmpty) return _avFallback(symbol);

      final price = double.tryParse(quote['05. price']?.toString() ?? '');
      if (price == null) return _avFallback(symbol);

      final rate = LiveRate(
        value: price,
        source: 'Alpha Vantage',
        fetchedAt: DateTime.now(),
        isLive: true,
      );
      _cache[cacheKey] = _CacheEntry(rate, DateTime.now());
      return rate;
    } catch (_) {
      return _avFallback(symbol);
    }
  }

  LiveRate _avFallback(String symbol) => LiveRate(
        value: _vnqFallback,
        source: 'est.',
        fetchedAt: DateTime.now(),
        isLive: false,
      );

  // ── Census API ───────────────────────────────────────────────────────────
  Future<LiveRate> fetchCensusMedianHomeValue() async {
    const cacheKey = 'census_median_home';
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired(_censusTtl)) {
      return cached.value as LiveRate;
    }

    try {
      final response = await _dio.get(_censusBase, queryParameters: {
        'get': 'B25077_001E',
        'for': 'us:1',
        'key': _censusKey,
      });

      // Response: [["B25077_001E","us"],["310000","1"]]
      final data = response.data as List?;
      if (data == null || data.length < 2) return _censusFallback();

      final row = data[1] as List?;
      if (row == null || row.isEmpty) return _censusFallback();

      final val = double.tryParse(row[0].toString());
      if (val == null || val <= 0) return _censusFallback();

      final rate = LiveRate(
        value: val,
        source: 'US Census ACS',
        fetchedAt: DateTime.now(),
        isLive: true,
      );
      _cache[cacheKey] = _CacheEntry(rate, DateTime.now());
      return rate;
    } catch (_) {
      return _censusFallback();
    }
  }

  LiveRate _censusFallback() => LiveRate(
        value: _censusMedianFallback,
        source: 'est.',
        fetchedAt: DateTime.now(),
        isLive: false,
      );

  // ── Census State Median Home Values ──────────────────────────────────────
  Future<Map<String, double>> fetchCensusStateMedianHomeValues() async {
    const cacheKey = 'census_state_medians';
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired(_censusTtl)) {
      return cached.value as Map<String, double>;
    }

    try {
      final response = await _dio.get(_censusBase, queryParameters: {
        'get': 'NAME,B25077_001E',
        'for': 'state:*',
        'key': _censusKey,
      });

      final data = response.data as List?;
      if (data == null || data.length < 2) return _censusStateFallbacks();

      final Map<String, double> results = {};
      for (int i = 1; i < data.length; i++) {
        final row = data[i] as List?;
        if (row == null || row.length < 2) continue;
        final stateName = row[0]?.toString();
        final priceVal = double.tryParse(row[1]?.toString() ?? '');
        if (stateName != null && priceVal != null && priceVal > 0) {
          results[stateName] = priceVal;
        }
      }
      _cache[cacheKey] = _CacheEntry(results, DateTime.now());
      return results;
    } catch (_) {
      return _censusStateFallbacks();
    }
  }

  Map<String, double> _censusStateFallbacks() {
    return {
      'Alabama': 248000.0,
      'Alaska': 338000.0,
      'Arizona': 436000.0,
      'Arkansas': 218000.0,
      'California': 880000.0,
      'Colorado': 575000.0,
      'Connecticut': 449000.0,
      'Delaware': 376000.0,
      'Florida': 420000.0,
      'Georgia': 348000.0,
      'Hawaii': 948000.0,
      'Idaho': 450000.0,
      'Illinois': 295000.0,
      'Indiana': 258000.0,
      'Iowa': 228000.0,
      'Kansas': 242000.0,
      'Kentucky': 241000.0,
      'Louisiana': 228000.0,
      'Maine': 389000.0,
      'Maryland': 469000.0,
      'Massachusetts': 625000.0,
      'Michigan': 268000.0,
      'Minnesota': 349000.0,
      'Mississippi': 181000.0,
      'Missouri': 262000.0,
      'Montana': 498000.0,
      'Nebraska': 284000.0,
      'Nevada': 455000.0,
      'New Hampshire': 499000.0,
      'New Jersey': 560000.0,
      'New Mexico': 332000.0,
      'New York': 750000.0,
      'North Carolina': 368000.0,
      'North Dakota': 282000.0,
      'Ohio': 248000.0,
      'Oklahoma': 215000.0,
      'Oregon': 485000.0,
      'Pennsylvania': 306000.0,
      'Rhode Island': 488000.0,
      'South Carolina': 318000.0,
      'South Dakota': 316000.0,
      'Tennessee': 356000.0,
      'Texas': 355000.0,
      'Utah': 555000.0,
      'Vermont': 378000.0,
      'Virginia': 420000.0,
      'Washington': 578000.0,
      'West Virginia': 189000.0,
      'Wisconsin': 322000.0,
      'Wyoming': 398000.0,
    };
  }

  // ── Frankfurter Currency Conversion ──────────────────────────────────────
  Future<Map<String, double>> fetchLatestExchangeRates() async {
    const cacheKey = 'frankfurter_rates';
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired(_ratesTtl)) {
      return cached.value as Map<String, double>;
    }

    try {
      final response = await _dio.get('https://api.frankfurter.dev/v1/latest', queryParameters: {
        'base': 'USD',
      });
      final rates = response.data['rates'] as Map<String, dynamic>?;
      if (rates == null || rates.isEmpty) return _exchangeRatesFallback();

      final parsed = rates.map((key, val) => MapEntry(key, double.tryParse(val.toString()) ?? 1.0));
      _cache[cacheKey] = _CacheEntry(parsed, DateTime.now());
      return parsed;
    } catch (_) {
      return _exchangeRatesFallback();
    }
  }

  Map<String, double> _exchangeRatesFallback() => {
        'CAD': 1.37,
        'GBP': 0.79,
        'AUD': 1.51,
        'NZD': 1.63,
        'EUR': 0.92,
        'INR': 83.50,
      };

  // ── Convenience batch fetch ──────────────────────────────────────────────
  Future<MortgageRates> fetchAllMortgageRates() async {
    final results = await Future.wait([
      fetchFredRate('MORTGAGE30US'),
      fetchFredRate('MORTGAGE15US'),
      fetchFredRate('SOFR'),
      fetchFredRate('DPRIME'),
      fetchFredRate('FEDFUNDS'),
    ]);
    return MortgageRates(
      rate30yr: results[0],
      rate15yr: results[1],
      sofr: results[2],
      prime: results[3],
      fedFunds: results[4],
    );
  }
}

// ─── Batch Result Model ──────────────────────────────────────────────────────
class MortgageRates {
  final LiveRate rate30yr;
  final LiveRate rate15yr;
  final LiveRate sofr;
  final LiveRate prime;
  final LiveRate fedFunds;

  const MortgageRates({
    required this.rate30yr,
    required this.rate15yr,
    required this.sofr,
    required this.prime,
    required this.fedFunds,
  });
}
