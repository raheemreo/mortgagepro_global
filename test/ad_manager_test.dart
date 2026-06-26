import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mortgagepro_global/services/ad_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdManager Tests', () {
    test('default status should prevent showing ads', () {
      final adManager = AdManager.instance;
      expect(adManager.canShowAds, isFalse);
    });

    test('loadBanner should return null when consent not granted', () async {
      final adManager = AdManager.instance;
      final ad = await adManager.loadBanner('test_unit_id', AdSize.banner);
      expect(ad, isNull);
    });

    test('getCachedNative should return null when not cached', () {
      final adManager = AdManager.instance;
      final ad = adManager.getCachedNative('test_native_unit');
      expect(ad, isNull);
    });
  });
}
