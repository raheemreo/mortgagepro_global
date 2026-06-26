// lib/services/analytics/analytics_calculator.dart

/// Calculator type vocabulary for Firebase Analytics.
///
/// All calculatorType parameters must come from these constants.
/// Never pass freeform strings.
/// Freeform strings produce fragmented Firebase dimension values
/// that cannot be corrected retroactively.
///
/// Add a constant here when adding a new calculator.
/// Update AnalyticsCalculator.all to include it.
abstract final class AnalyticsCalculator {
  static const String mortgage      = 'mortgage';
  static const String affordability = 'affordability';
  static const String refinance     = 'refinance';
  static const String propertyTax   = 'property_tax';

  /// Used for runtime validation in AnalyticsService.
  static const Set<String> all = {
    mortgage, affordability, refinance, propertyTax,
  };
}
