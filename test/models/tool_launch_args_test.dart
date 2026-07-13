// test/models/tool_launch_args_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mortgagepro_global/models/tool_launch_args.dart';
import 'package:mortgagepro_global/shared/models/saved_calc.dart';

void main() {
  // Helper to build a minimal SavedCalc without Hive initialisation.
  SavedCalc makeCalc() => SavedCalc(
        id: 'test-id',
        country: 'europe',
        calcType: 'mortgage',
        inputs: {'amount': 300000.0},
        results: {'monthly': 1500.0},
        label: 'Test Calc',
        savedAt: DateTime(2025, 1, 1),
        currencyCode: 'EUR',
      );

  group('ToolLaunchArgs.forCountry', () {
    test('sets initialCountry to the supplied code', () {
      const args = ToolLaunchArgs.forCountry('FR');
      expect(args.initialCountry, 'FR');
    });

    test('savedCalc is null when using forCountry', () {
      const args = ToolLaunchArgs.forCountry('ES');
      expect(args.savedCalc, isNull);
    });

    test('works for all 6 EU country codes', () {
      for (final code in ['DE', 'FR', 'ES', 'IT', 'NL', 'PT']) {
        final args = ToolLaunchArgs.forCountry(code);
        expect(args.initialCountry, code,
            reason: 'Expected initialCountry == $code');
        expect(args.savedCalc, isNull,
            reason: 'Expected savedCalc == null for $code');
      }
    });
  });

  group('ToolLaunchArgs.forSavedCalc', () {
    test('sets savedCalc to the supplied instance', () {
      final calc = makeCalc();
      final args = ToolLaunchArgs.forSavedCalc(calc);
      expect(args.savedCalc, same(calc));
    });

    test('initialCountry is null when using forSavedCalc', () {
      final calc = makeCalc();
      final args = ToolLaunchArgs.forSavedCalc(calc);
      expect(args.initialCountry, isNull);
    });
  });

  group('ToolLaunchArgs default constructor', () {
    test('both fields null when constructed with no args', () {
      const args = ToolLaunchArgs();
      expect(args.savedCalc, isNull);
      expect(args.initialCountry, isNull);
    });

    test('can set both fields simultaneously', () {
      final calc = makeCalc();
      final args = ToolLaunchArgs(savedCalc: calc, initialCountry: 'NL');
      expect(args.savedCalc, same(calc));
      expect(args.initialCountry, 'NL');
    });
  });

  group('ToolLaunchArgs.toString', () {
    test('returns a non-empty string description', () {
      const args = ToolLaunchArgs.forCountry('PT');
      expect(args.toString(), isNotEmpty);
      expect(args.toString(), contains('PT'));
    });
  });
}
