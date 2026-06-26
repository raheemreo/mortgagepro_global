// lib/services/analytics/analytics_feature.dart

/// Feature vocabulary for logFeatureError.
///
/// Always use these constants as the feature parameter.
/// Never pass freeform strings or user-entered text.
/// Freeform feature names make feature_error events
/// unsearchable in Firebase and Crashlytics.
///
/// Add a constant here when adding new features.
abstract final class AnalyticsFeature {
  static const String mortgageCalculator = 'mortgage_calculator';
  static const String affordabilityCalc  = 'affordability_calc';
  static const String refinanceCalc      = 'refinance_calc';
  static const String propertyTaxCalc    = 'property_tax_calc';
  static const String rewardedAdLoad     = 'rewarded_ad_load';
  static const String rewardedAdShow     = 'rewarded_ad_show';
  static const String navigation         = 'navigation';
  static const String remoteConfig       = 'remote_config';
  static const String hiveStorage        = 'hive_storage';
}
