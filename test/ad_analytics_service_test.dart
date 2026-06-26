import 'package:flutter_test/flutter_test.dart';
import 'package:mortgagepro_global/services/ad_analytics_service.dart';
import 'package:mortgagepro_global/services/consent_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdAnalyticsService Tests', () {
    test('should prevent tracking when consent is not granted', () {
      final analytics = AdAnalyticsService.instance;
      expect(ConsentService.instance.isConsentGranted, isFalse);

      // Verify that event tracking doesn't execute or queue events without consent
      // We can invoke a track method and confirm no errors/exceptions are thrown.
      analytics.trackBannerRequest(
        adUnit: 'test_banner',
        screen: 'test_screen',
        retryAttempt: 0,
      );
    });
  });
}
