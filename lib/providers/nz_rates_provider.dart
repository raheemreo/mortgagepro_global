// lib/providers/nz_rates_provider.dart
// Riverpod FutureProvider for New Zealand live rate data.
// Sources:
//   • ratesapi.nz      — NZ bank mortgage rates (hourly)
//   • open.er-api.com  — NZD FX rates (daily)
//   • Remote Config    — OCR, bonds, CPI, region prices (manual update)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/nz_api_service.dart';
import '../services/remote_config_service.dart';

export '../core/services/nz_api_service.dart' show NZRatesModel;

/// The primary NZ rates provider.
/// Passes the current OCR from Remote Config into the API service so the
/// rate is accurate even when the network is unavailable.
final nzRatesProvider = FutureProvider<NZRatesModel>((ref) async {
  final rc = RemoteConfigService.instance;
  final ocr = double.tryParse(rc.nzOcrRate) ?? 2.25;
  return NZApiService.instance.fetchAllNZRates(ocr: ocr);
});
