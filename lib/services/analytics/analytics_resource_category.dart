// lib/services/analytics/analytics_resource_category.dart

/// Resource category vocabulary for Firebase Analytics.
///
/// All category parameters in logResourceClicked must
/// come from these constants.
///
/// Add a constant here when adding a new resource type.
/// Update AnalyticsResourceCategory.all to include it.
abstract final class AnalyticsResourceCategory {
  static const String guide      = 'guide';
  static const String article    = 'article';
  static const String government = 'government';
  static const String tax        = 'tax';
  static const String calculator = 'calculator';

  /// Used for runtime validation in AnalyticsService.
  static const Set<String> all = {
    guide, article, government, tax, calculator,
  };
}
