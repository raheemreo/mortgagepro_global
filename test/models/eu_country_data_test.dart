// test/models/eu_country_data_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mortgagepro_global/models/eu_country_data.dart';

void main() {
  group('EuCountryData.byCode', () {
    test('returns Germany for code DE', () {
      final result = EuCountryData.byCode('DE');
      expect(result.code, 'DE');
      expect(result.name, 'Germany');
    });

    test('returns France for code FR', () {
      final result = EuCountryData.byCode('FR');
      expect(result.code, 'FR');
      expect(result.name, 'France');
    });

    test('returns Spain for code ES', () {
      final result = EuCountryData.byCode('ES');
      expect(result.code, 'ES');
      expect(result.name, 'Spain');
    });

    test('returns Italy for code IT', () {
      final result = EuCountryData.byCode('IT');
      expect(result.code, 'IT');
      expect(result.name, 'Italy');
    });

    test('returns Netherlands for code NL', () {
      final result = EuCountryData.byCode('NL');
      expect(result.code, 'NL');
      expect(result.name, 'Netherlands');
    });

    test('returns Portugal for code PT', () {
      final result = EuCountryData.byCode('PT');
      expect(result.code, 'PT');
      expect(result.name, 'Portugal');
    });

    test('returns Germany fallback for unknown code XYZ — does not throw', () {
      // Should never throw; Germany is the safe default.
      expect(() => EuCountryData.byCode('XYZ'), returnsNormally);
      final result = EuCountryData.byCode('XYZ');
      expect(result.code, 'DE');
      expect(result.name, 'Germany');
    });

    test('returns Germany fallback for empty string — does not throw', () {
      expect(() => EuCountryData.byCode(''), returnsNormally);
      final result = EuCountryData.byCode('');
      expect(result.code, 'DE');
    });

    test('returns Germany fallback for lowercase code — does not throw', () {
      // byCode() is case-sensitive by design; 'de' != 'DE', so it falls back.
      expect(() => EuCountryData.byCode('de'), returnsNormally);
      final result = EuCountryData.byCode('de');
      expect(result.code, 'DE');
    });

    test('all 6 entries in EuCountryData.all have unique codes', () {
      final codes = EuCountryData.all.map((c) => c.code).toList();
      expect(codes.toSet().length, codes.length);
    });

    test('all 6 entries have non-empty flag, name, accentWord, rateType', () {
      for (final c in EuCountryData.all) {
        expect(c.flag, isNotEmpty, reason: '${c.code}.flag is empty');
        expect(c.name, isNotEmpty, reason: '${c.code}.name is empty');
        expect(c.accentWord, isNotEmpty, reason: '${c.code}.accentWord is empty');
        expect(c.rateType, isNotEmpty, reason: '${c.code}.rateType is empty');
      }
    });

    test('all 6 entries have typicalRate > 0', () {
      for (final c in EuCountryData.all) {
        expect(c.typicalRate, greaterThan(0),
            reason: '${c.code}.typicalRate should be positive');
      }
    });
  });
}
