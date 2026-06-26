// lib/providers/uk_rates_provider.dart
// Riverpod FutureProvider — fetches all live BoE rates.
// Pattern identical to canada_rates_provider.dart and europe_rates_provider.dart.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/boe_api_service.dart';

export '../core/services/boe_api_service.dart' show UKRatesModel;

/// Provides live UK mortgage rates from the Bank of England IADB API.
/// Falls back to 2025 Q2 hardcoded values on any network error.
final ukRatesProvider = FutureProvider.autoDispose<UKRatesModel>((ref) async {
  return BoeApiService.instance.fetchAllUKRates();
});
