import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mortgagepro_global/services/consent_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConsentService Tests', () {
    test('default status should block ads until initialization', () {
      final service = ConsentService.instance;
      expect(service.isConsentGranted, isFalse);
      expect(service.canShowPersonalizedAds, isFalse);
      expect(service.currentStatus, equals(ConsentStatus.unknown));
    });
  });
}
