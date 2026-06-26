// lib/providers/usa_rates_provider.dart
// Riverpod FutureProviders for all USA live API data

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/usa_api_service.dart';

// ── FRED Mortgage Rates ────────────────────────────────────────────────────

/// 30-Year Fixed Mortgage Rate (FRED: MORTGAGE30US)
final fredMortgage30Provider = FutureProvider<LiveRate>((ref) async {
  return UsaApiService.instance.fetchFredRate('MORTGAGE30US');
});

/// 15-Year Fixed Mortgage Rate (FRED: MORTGAGE15US)
final fredMortgage15Provider = FutureProvider<LiveRate>((ref) async {
  return UsaApiService.instance.fetchFredRate('MORTGAGE15US');
});

/// SOFR — Secured Overnight Financing Rate, used as ARM index (FRED: SOFR)
final fredSofrProvider = FutureProvider<LiveRate>((ref) async {
  return UsaApiService.instance.fetchFredRate('SOFR');
});

/// Bank Prime Loan Rate — used for HELOC rates (FRED: DPRIME)
final fredPrimeProvider = FutureProvider<LiveRate>((ref) async {
  return UsaApiService.instance.fetchFredRate('DPRIME');
});

/// Federal Funds Effective Rate (FRED: FEDFUNDS)
final fredFedFundsProvider = FutureProvider<LiveRate>((ref) async {
  return UsaApiService.instance.fetchFredRate('FEDFUNDS');
});

/// Batch fetch of all mortgage rates in one shot
final allMortgageRatesProvider = FutureProvider<MortgageRates>((ref) async {
  return UsaApiService.instance.fetchAllMortgageRates();
});

// ── Alpha Vantage — VNQ Real Estate ETF ───────────────────────────────────

/// VNQ Vanguard Real Estate ETF price (proxy for real estate market conditions)
final vnqPriceProvider = FutureProvider<LiveRate>((ref) async {
  return UsaApiService.instance.fetchAlphaVantagePrice('VNQ');
});

// ── Census Data ────────────────────────────────────────────────────────────

/// US Median Home Value from Census Bureau ACS 2022
final censusMedianHomeValueProvider = FutureProvider<LiveRate>((ref) async {
  return UsaApiService.instance.fetchCensusMedianHomeValue();
});

/// State-by-state Census median home values
final censusStateMedianHomeValuesProvider = FutureProvider<Map<String, double>>((ref) async {
  return UsaApiService.instance.fetchCensusStateMedianHomeValues();
});

// ── Frankfurter Exchange Rates ──────────────────────────────────────────────

/// Latest Frankfurter USD exchange rates
final exchangeRatesProvider = FutureProvider<Map<String, double>>((ref) async {
  return UsaApiService.instance.fetchLatestExchangeRates();
});
