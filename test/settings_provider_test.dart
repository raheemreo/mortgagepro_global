import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mortgagepro_global/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsNotifier Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'dark_mode': true,
        'default_term': 15,
        'privacy_choices_opt_out': true,
      });
    });

    test('should load initial values and then clear them using clearAll', () async {
      final notifier = SettingsNotifier();
      
      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(notifier.state.darkMode, isTrue);
      expect(notifier.state.defaultTermYears, equals(15));
      expect(notifier.state.privacyChoicesOptOut, isTrue);

      // Perform clearAll
      await notifier.clearAll();

      expect(notifier.state.darkMode, isFalse);
      expect(notifier.state.defaultTermYears, equals(30)); // default defaultTermYears
      expect(notifier.state.privacyChoicesOptOut, isFalse);
      
      // Verify SharedPreferences has been cleared
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('dark_mode'), isNull);
    });
  });
}
