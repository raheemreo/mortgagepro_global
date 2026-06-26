// lib/core/utils/sdlt_calculator.dart — UK Stamp Duty Land Tax

import 'dart:math';

class SDLTCalculator {
  /// Standard SDLT bands (2024):
  /// Up to £250,000: 0%
  /// £250,001–£925,000: 5%
  /// £925,001–£1,500,000: 10%
  /// Over £1,500,000: 12%
  static double calculate({
    required double price,
    bool isFirstTimeBuyer = false,
    bool isAdditionalProperty = false,
  }) {
    if (isAdditionalProperty) return _additionalPropertySDLT(price);
    if (isFirstTimeBuyer) return _ftbSDLT(price);
    return _standardSDLT(price);
  }

  static double _standardSDLT(double price) {
    double tax = 0;
    if (price > 1500000) tax += (price - 1500000) * 0.12;
    if (price > 925000) tax += (min(price, 1500000) - 925000) * 0.10;
    if (price > 250000) tax += (min(price, 925000) - 250000) * 0.05;
    return tax;
  }

  /// FTB Relief:
  /// Up to £425,000: 0%
  /// £425,001–£625,000: 5%
  /// Over £625,000: standard rates apply (relief withdrawn)
  static double _ftbSDLT(double price) {
    if (price > 625000) return _standardSDLT(price);
    if (price > 425000) return (price - 425000) * 0.05;
    return 0;
  }

  /// Additional property surcharge: standard + 3%
  static double _additionalPropertySDLT(double price) =>
      _standardSDLT(price) + price * 0.03;

  static String effectiveRateStr(double price, double tax) {
    if (price <= 0) return '0.00%';
    return '${(tax / price * 100).toStringAsFixed(2)}%';
  }

  static Map<String, double> breakdown(double price,
      {bool isFirstTimeBuyer = false, bool isAdditionalProperty = false}) {
    if (isAdditionalProperty) {
      final sdlt = _standardSDLT(price);
      final surcharge = price * 0.03;
      return {
        'Standard SDLT': sdlt,
        '3% Surcharge': surcharge,
        'Total': sdlt + surcharge,
      };
    }
    if (isFirstTimeBuyer && price <= 625000) {
      return {
        'FTB Relief': 0,
        'On amount >£425K': price > 425000 ? (price - 425000) * 0.05 : 0,
        'Total': _ftbSDLT(price),
      };
    }
    final breakdown = <String, double>{};
    double total = 0;
    if (price > 1500000) {
      final band = (price - 1500000) * 0.12;
      breakdown['Over £1.5M (12%)'] = band;
      total += band;
    }
    if (price > 925000) {
      final band = (min(price, 1500000) - 925000) * 0.10;
      breakdown['£925K–£1.5M (10%)'] = band;
      total += band;
    }
    if (price > 250000) {
      final band = (min(price, 925000) - 250000) * 0.05;
      breakdown['£250K–£925K (5%)'] = band;
      total += band;
    }
    breakdown['Up to £250K (0%)'] = 0;
    breakdown['Total SDLT'] = total;
    return breakdown;
  }
}
