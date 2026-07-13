// test/utils/tab_order_helper_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mortgagepro_global/core/utils/tab_order_helper.dart';

void main() {
  group('computeTabOrder unit tests', () {
    final baseOrder = [
      'GLOBAL',
      'USA',
      'CANADA',
      'UK',
      'AUSTRALIA',
      'NEWZEALAND',
      'EUROPE',
      'INDIA',
    ];

    test('no pin (returns base order unchanged)', () {
      final result = computeTabOrder(baseOrder: baseOrder, pinnedCountry: null);
      expect(result, baseOrder);
    });

    test('valid pin (moves correctly next to GLOBAL at index 1)', () {
      final result = computeTabOrder(baseOrder: baseOrder, pinnedCountry: 'CANADA');
      expect(result, [
        'GLOBAL',
        'CANADA',
        'USA',
        'UK',
        'AUSTRALIA',
        'NEWZEALAND',
        'EUROPE',
        'INDIA',
      ]);
    });

    test('pin value not in base order (defensive — falls back to base order)', () {
      final result = computeTabOrder(baseOrder: baseOrder, pinnedCountry: 'JAPAN');
      expect(result, baseOrder);
    });

    test('pin equal to GLOBAL (defensive — treated as invalid, falls back to base order)', () {
      final result = computeTabOrder(baseOrder: baseOrder, pinnedCountry: 'GLOBAL');
      expect(result, baseOrder);
    });
  });
}
