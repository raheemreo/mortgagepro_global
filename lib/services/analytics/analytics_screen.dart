// lib/services/analytics/analytics_screen.dart

/// Screen name vocabulary for Firebase Analytics.
///
/// All screenName parameters must come from these constants.
/// Never pass:
///   - Route paths ("/home", "/usa")
///   - Widget class names ("_HomeScreenState")
///   - URLs, query strings, or dynamic identifiers
///
/// Add a constant here when adding a new screen.
/// Update DATA COLLECTION NOTICE in AnalyticsService.
/// Update AnalyticsScreen.all to include the new value.
abstract final class AnalyticsScreen {
  static const String home        = 'home';
  static const String usa         = 'usa';
  static const String canada      = 'canada';
  static const String uk          = 'uk';
  static const String australia   = 'australia';
  static const String newZealand  = 'new_zealand';
  static const String europe      = 'europe';
  static const String india       = 'india';
  static const String settings    = 'settings';
  static const String resources   = 'resources';
  static const String propertyTax = 'property_tax';
  static const String saved       = 'saved';
  static const String about       = 'about';

  /// Used for runtime validation in ScreenTimerMixin
  /// and ScrollDepthTracker. Update when adding
  /// new screen constants above.
  static const Set<String> all = {
    home, usa, canada, uk, australia, newZealand,
    europe, india, settings, resources, propertyTax,
    saved, about,
  };
}
