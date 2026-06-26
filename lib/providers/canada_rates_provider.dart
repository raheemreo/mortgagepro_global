// lib/providers/canada_rates_provider.dart
// Riverpod FutureProviders for Canada live API data from Bank of Canada (BoC)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/canada_api_service.dart';
import '../core/services/usa_api_service.dart'; // LiveRate model

// ─── Individual Series Providers ─────────────────────────────────────────────

/// Policy Interest Rate (BoC: V39079)
final bocOvernightRateProvider = FutureProvider<LiveRate>((ref) async {
  return CanadaApiService.instance.fetchBocRate('V39079');
});

/// Canadian Retail Prime Rate (BoC: V80691311)
final canadaPrimeRateProvider = FutureProvider<LiveRate>((ref) async {
  return CanadaApiService.instance.fetchBocRate('V80691311');
});

/// 5-Year Conventional Mortgage Benchmark (BoC: V80691335)
final canadaMortgage5yrBenchmarkProvider = FutureProvider<LiveRate>((ref) async {
  return CanadaApiService.instance.fetchBocRate('V80691335');
});

/// USD/CAD Exchange Rate (BoC: FXUSDCAD)
final cadUsdExchangeRateProvider = FutureProvider<LiveRate>((ref) async {
  return CanadaApiService.instance.fetchBocRate('FXUSDCAD');
});

/// Prime Business Loan Rate (BoC: V122495)
final canadaPrimeBusinessProvider = FutureProvider<LiveRate>((ref) async {
  return CanadaApiService.instance.fetchBocRate('V122495');
});

/// Canadian 5-Year Government Bond Yield (BoC: V39051)
final canadaBond5yrProvider = FutureProvider<LiveRate>((ref) async {
  return CanadaApiService.instance.fetchBocRate('V39051');
});

/// Canadian 10-Year Government Bond Yield (BoC: V39052)
final canadaBond10yrProvider = FutureProvider<LiveRate>((ref) async {
  return CanadaApiService.instance.fetchBocRate('V39052');
});

// ─── Calculated Rates Model ───────────────────────────────────────────────────

/// Consolidated Canadian mortgage rates with dynamic market offsets and OSFI stress rates
class CanadaCalculatedRates {
  final LiveRate overnight;
  final LiveRate prime;
  final LiveRate benchmark5yr;
  final LiveRate usdCad;
  final LiveRate primeBusiness;
  final LiveRate bond5yr;
  final LiveRate bond10yr;
  final double rate5yrFixed;
  final double rate3yrFixed;
  final double rateVariable;
  final double stressTestRate;
  final bool isLive;

  const CanadaCalculatedRates({
    required this.overnight,
    required this.prime,
    required this.benchmark5yr,
    required this.usdCad,
    required this.primeBusiness,
    required this.bond5yr,
    required this.bond10yr,
    required this.rate5yrFixed,
    required this.rate3yrFixed,
    required this.rateVariable,
    required this.stressTestRate,
    required this.isLive,
  });

  /// Convenience: formatted USD/CAD string e.g. "1.3977"
  String get usdCadFormatted => usdCad.value.toStringAsFixed(4);

  /// Convenience: formatted 5-yr bond e.g. "3.75%"
  String get bond5yrFormatted => '${bond5yr.value.toStringAsFixed(2)}%';

  /// Convenience: formatted 10-yr bond e.g. "3.95%"
  String get bond10yrFormatted => '${bond10yr.value.toStringAsFixed(2)}%';
}

// ─── Main Calculated Rates Provider ──────────────────────────────────────────

/// Dynamic mortgage rate structure calculated from live BoC feeds (7 series)
final canadaCalculatedRatesProvider = FutureProvider<CanadaCalculatedRates>((ref) async {
  final model = await CanadaApiService.instance.fetchAllCanadaRatesExtended();

  // 5-Yr Fixed Market: Benchmark − 1.10% (spread offset; e.g. 6.09% → 4.99%)
  final rate5yrFixed = model.benchmark5yr.value - 1.10;

  // 3-Yr Fixed Market: Benchmark − 0.95% (e.g. 6.09% → 5.14%)
  final rate3yrFixed = model.benchmark5yr.value - 0.95;

  // Variable: Prime − 0.50% (e.g. 4.45% → 3.95%; or 6.45% → 5.95%)
  final rateVariable = model.prime.value - 0.50;

  // Stress Test Rate: qualifying rate is max(5-Yr Fixed Market + 2%, 5.25%)
  final stressTestRate = [rate5yrFixed + 2.0, 5.25].reduce((a, b) => a > b ? a : b);

  final allLive = model.overnight.isLive &&
      model.prime.isLive &&
      model.benchmark5yr.isLive;

  return CanadaCalculatedRates(
    overnight: model.overnight,
    prime: model.prime,
    benchmark5yr: model.benchmark5yr,
    usdCad: model.usdCadFx,
    primeBusiness: model.primeBusiness,
    bond5yr: model.bond5yr,
    bond10yr: model.bond10yr,
    rate5yrFixed: rate5yrFixed,
    rate3yrFixed: rate3yrFixed,
    rateVariable: rateVariable,
    stressTestRate: stressTestRate,
    isLive: allLive,
  );
});
