// test/providers/settings_provider_test.dart
//
// PHASE-2: Unit tests for SettingsNotifier covering the three new preference
// fields (region, selectedEuropeCountry, preferredCalculatorTab) plus the
// existing dark_mode legacy migration path (B3 confirmed: key exists).
//
// Run: flutter test test/providers/settings_provider_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mortgagepro_global/providers/settings_provider.dart';

void main() {
  // Use fake SharedPreferences for all tests — no disk I/O.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsNotifier — safe defaults on missing keys', () {
    test('initial state has expected defaults when no prefs stored', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      // Trigger provider initialization
      container.read(settingsProvider);
      // Give _load() time to complete.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      
      final settings = container.read(settingsProvider);

      expect(settings.themeMode, 'system');
      expect(settings.preferredCountry, 'USA');
      expect(settings.preferredCurrency, 'USD');
      expect(settings.defaultTermYears, 30);
      expect(settings.defaultDepositPercent, 20.0);
      expect(settings.privacyChoicesOptOut, false);
      // PHASE-2 new fields: all null/empty by default
      expect(settings.region, isNull);
      expect(settings.selectedEuropeCountry, isNull);
      expect(settings.preferredCalculatorTab, isEmpty);
    });
  });

  group('SettingsNotifier — dark_mode legacy migration (B3 confirmed)', () {
    test('migrates old bool dark_mode=true to theme_mode="dark"', () async {
      SharedPreferences.setMockInitialValues({'dark_mode': true});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      container.read(settingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      
      expect(container.read(settingsProvider).themeMode, 'dark');
    });

    test('migrates old bool dark_mode=false to theme_mode="system"', () async {
      SharedPreferences.setMockInitialValues({'dark_mode': false});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      container.read(settingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      
      expect(container.read(settingsProvider).themeMode, 'system');
    });

    test('theme_mode string takes precedence over legacy dark_mode bool', () async {
      SharedPreferences.setMockInitialValues({
        'dark_mode': true,
        'theme_mode': 'light',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      container.read(settingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      
      expect(container.read(settingsProvider).themeMode, 'light');
    });
  });

  group('SettingsNotifier — region persistence', () {
    test('setRegion persists and restores value', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      container.read(settingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container.read(settingsProvider.notifier).setRegion('NSW');
      expect(container.read(settingsProvider).region, 'NSW');

      // Simulate a restart by creating a new container with the same prefs.
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);
      
      container2.read(settingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      
      expect(container2.read(settingsProvider).region, 'NSW');
    });

    test('setRegion(null) clears the stored value', () async {
      SharedPreferences.setMockInitialValues({'region': 'QLD'});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      container.read(settingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container.read(settingsProvider.notifier).setRegion(null);
      expect(container.read(settingsProvider).region, isNull);
    });
  });

  group('SettingsNotifier — selectedEuropeCountry persistence', () {
    test('setEuropeCountry persists and restores value', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      container.read(settingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container.read(settingsProvider.notifier).setEuropeCountry('FR');
      expect(container.read(settingsProvider).selectedEuropeCountry, 'FR');

      final container2 = ProviderContainer();
      addTearDown(container2.dispose);
      
      container2.read(settingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      
      expect(container2.read(settingsProvider).selectedEuropeCountry, 'FR');
    });

    test('setEuropeCountry(null) clears the stored value', () async {
      SharedPreferences.setMockInitialValues({'selected_europe_country': 'DE'});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      container.read(settingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container.read(settingsProvider.notifier).setEuropeCountry(null);
      expect(container.read(settingsProvider).selectedEuropeCountry, isNull);
    });
  });

  group('SettingsNotifier — preferredCalculatorTab persistence', () {
    test('setCalculatorTab updates state immediately', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      container.read(settingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      container.read(settingsProvider.notifier).setCalculatorTab('USA', 'mortgage');
      expect(
        container.read(settingsProvider).preferredCalculatorTab['USA'],
        'mortgage',
      );
    });

    test('each country remembers its own last-viewed tab independently', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      container.read(settingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      container.read(settingsProvider.notifier).setCalculatorTab('USA', 'affordability');
      container.read(settingsProvider.notifier).setCalculatorTab('UK', 'sdlt');
      container.read(settingsProvider.notifier).setCalculatorTab('CANADA', 'stress-test');

      final tabs = container.read(settingsProvider).preferredCalculatorTab;
      expect(tabs['USA'], 'affordability');
      expect(tabs['UK'], 'sdlt');
      expect(tabs['CANADA'], 'stress-test');
    });

    test('setCalculatorTab persists and restores across restart', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      container.read(settingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      container.read(settingsProvider.notifier).setCalculatorTab('UK', 'sdlt');
      // Allow fire-and-forget write to settle.
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final container2 = ProviderContainer();
      addTearDown(container2.dispose);
      
      container2.read(settingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      
      expect(
        container2.read(settingsProvider).preferredCalculatorTab['UK'],
        'sdlt',
      );
    });

    test('later tab overrides earlier tab for same country', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      container.read(settingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      container.read(settingsProvider.notifier).setCalculatorTab('USA', 'mortgage');
      container.read(settingsProvider.notifier).setCalculatorTab('USA', 'refinance');

      expect(
        container.read(settingsProvider).preferredCalculatorTab['USA'],
        'refinance',
      );
    });
  });

  group('SettingsNotifier — pinnedCountry persistence', () {
    test('setPinnedCountry persists and restores value', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      container.read(settingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container.read(settingsProvider.notifier).setPinnedCountry('CANADA');
      expect(container.read(settingsProvider).pinnedCountry, 'CANADA');

      final container2 = ProviderContainer();
      addTearDown(container2.dispose);
      
      container2.read(settingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      
      expect(container2.read(settingsProvider).pinnedCountry, 'CANADA');
    });

    test('setPinnedCountry(null) clears the stored value', () async {
      SharedPreferences.setMockInitialValues({'pinned_country': 'UK'});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      container.read(settingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container.read(settingsProvider.notifier).setPinnedCountry(null);
      expect(container.read(settingsProvider).pinnedCountry, isNull);
    });
  });
}
