// lib/services/analytics/analytics_country.dart

/// Country vocabulary for Firebase Analytics.
///
/// All country parameters must come from these constants.
/// Never pass:
///   - User-entered country names
///   - Locale strings ("en_US")
///   - Dynamically constructed strings
///   - Variants ("Usa", "United States", "USA ")
///
/// Add a constant here when adding a new country tab.
/// Update AnalyticsCountry.all to include it.
/// Update _supportedCountries in AnalyticsService.
/// Update DATA COLLECTION NOTICE in AnalyticsService.
abstract final class AnalyticsCountry {
  static const String usa       = 'USA';
  static const String canada    = 'Canada';
  static const String uk        = 'UK';
  static const String australia = 'Australia';
  static const String newZealand = 'New Zealand';
  static const String europe    = 'Europe';
  static const String india     = 'India';
  // 'Global' is a dashboard tab, not a country — excluded intentionally.

  /// Used for runtime validation in AnalyticsService.
  static const Set<String> all = {
    usa, canada, uk, australia, newZealand, europe, india,
  };
}
