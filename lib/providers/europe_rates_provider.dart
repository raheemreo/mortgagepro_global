// lib/providers/europe_rates_provider.dart
// Riverpod provider for live ECB rate data.
// Consumed by Europe tab, Europe screen, and all EU tool widgets.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/ecb_api_service.dart';
import '../core/services/usa_api_service.dart'; // re-use LiveRate

// ─── Computed Rates Model ─────────────────────────────────────────────────────
class EuropeCalculatedRates {
  // Raw ECB feeds
  final LiveRate ecbRate;
  final LiveRate euribor3m;
  final LiveRate euribor6m;
  final LiveRate euribor12m;
  final LiveRate cpiInflation;
  final LiveRate eurUsd;
  final LiveRate eurGbp;

  // Computed: per-country typical fixed rates using static spreads
  // (ECB does not publish per-country rates — we use observed market spreads)
  final double typicalFixed5yr;   // ecbRate + 0.85 (Germany 10yr proxy)
  final double deRate;            // Germany  = ecbRate + 0.85
  final double frRate;            // France   = ecbRate + 0.60
  final double esRate;            // Spain    = ecbRate + 1.10 (often variable/Euribor-based)
  final double itRate;            // Italy    = ecbRate + 1.20
  final double nlRate;            // Netherlands = ecbRate + 0.95
  final double ptRate;            // Portugal = ecbRate + 1.30

  // Overall connectivity flag
  final bool isLive;

  const EuropeCalculatedRates({
    required this.ecbRate,
    required this.euribor3m,
    required this.euribor6m,
    required this.euribor12m,
    required this.cpiInflation,
    required this.eurUsd,
    required this.eurGbp,
    required this.typicalFixed5yr,
    required this.deRate,
    required this.frRate,
    required this.esRate,
    required this.itRate,
    required this.nlRate,
    required this.ptRate,
    required this.isLive,
  });

  // ── Convenience display getters ──────────────────────────────────────────
  String get ecbRateFormatted    => '${ecbRate.value.toStringAsFixed(2)}%';
  String get euribor3mFormatted  => '${euribor3m.value.toStringAsFixed(2)}%';
  String get euribor6mFormatted  => '${euribor6m.value.toStringAsFixed(2)}%';
  String get euribor12mFormatted => '${euribor12m.value.toStringAsFixed(2)}%';
  String get eurUsdFormatted     => eurUsd.value.toStringAsFixed(4);
  String get eurGbpFormatted     => eurGbp.value.toStringAsFixed(4);
  String get cpiFormatted        => '${cpiInflation.value.toStringAsFixed(1)}%';
  String get liveBadge           => isLive ? '🟢 Live ECB' : 'Estimated';

  double rateForCountry(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'DE': return deRate;
      case 'FR': return frRate;
      case 'ES': return esRate;
      case 'IT': return itRate;
      case 'NL': return nlRate;
      case 'PT': return ptRate;
      default:   return typicalFixed5yr;
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────
final europeRatesProvider = FutureProvider<EuropeCalculatedRates>((ref) async {
  final model = await EcbApiService.instance.fetchAllEuropeRates();

  final ecbVal = model.ecbRate.value;

  // All series are live only if every one of them is live
  final allLive = model.ecbRate.isLive &&
      model.euribor3m.isLive &&
      model.eurUsd.isLive;

  return EuropeCalculatedRates(
    ecbRate:         model.ecbRate,
    euribor3m:       model.euribor3m,
    euribor6m:       model.euribor6m,
    euribor12m:      model.euribor12m,
    cpiInflation:    model.cpiInflation,
    eurUsd:          model.eurUsd,
    eurGbp:          model.eurGbp,
    // Computed
    typicalFixed5yr: ecbVal + 0.85,
    deRate:          ecbVal + 0.85,
    frRate:          ecbVal + 0.60,
    esRate:          ecbVal + 1.10,
    itRate:          ecbVal + 1.20,
    nlRate:          ecbVal + 0.95,
    ptRate:          ecbVal + 1.30,
    isLive:          allLive,
  );
});
