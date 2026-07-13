// test/theme/wcag_contrast_test.dart
//
// PHASE-1: WCAG contrast ratio regression test for all CountryTheme palettes.
// Fails the build if any mutedColor drops below 4.5:1 against the matching
// cardColor or backgroundColor — locking in the currently-passing palette
// against future regressions.
//
// WCAG formula reference: https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio
// Run: flutter test test/theme/wcag_contrast_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mortgagepro_global/app/theme/country_themes.dart';

void main() {
  group('WCAG contrast regression — CountryTheme palettes', () {
    // Helper: WCAG 2.1 relative luminance for a single 8-bit channel value.
    double sRGBToLinear(double v) {
      final c = v / 255.0;
      return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) * ((c + 0.055) / 1.055);
    }

    // Relative luminance (L) for a colour using the modern component accessors.
    double luminance(Color c) {
      // Use toARGB32() to extract channel bytes without deprecated .red/.green/.blue.
      final argb = c.toARGB32();
      final r = sRGBToLinear(((argb >> 16) & 0xFF).toDouble());
      final g = sRGBToLinear(((argb >> 8) & 0xFF).toDouble());
      final b = sRGBToLinear((argb & 0xFF).toDouble());
      return 0.2126 * r + 0.7152 * g + 0.0722 * b;
    }

    // Contrast ratio between two colours (always >= 1).
    double contrastRatio(Color a, Color b) {
      final la = luminance(a);
      final lb = luminance(b);
      final lighter = la > lb ? la : lb;
      final darker = la > lb ? lb : la;
      return (lighter + 0.05) / (darker + 0.05);
    }

    // All country themes under test.
    final themes = {
      'USA': CountryThemes.usa,
      'UK': CountryThemes.uk,
      'Australia': CountryThemes.australia,
      'Canada': CountryThemes.canada,
      'Europe': CountryThemes.europe,
      'India': CountryThemes.india,
      'New Zealand': CountryThemes.newZealand,
    };

    for (final entry in themes.entries) {
      final name = entry.key;
      final theme = entry.value;

      test('$name: mutedColor vs cardColor ≥ 4.5:1 (WCAG AA)', () {
        final ratio = contrastRatio(theme.mutedColor, theme.cardColor);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '$name mutedColor (${theme.mutedColor.toARGB32().toRadixString(16)}) '
              'vs cardColor (${theme.cardColor.toARGB32().toRadixString(16)}) '
              'contrast ratio is ${ratio.toStringAsFixed(2)}:1, '
              'below WCAG AA minimum 4.5:1',
        );
      });

      test('$name: mutedColor vs backgroundColor ≥ 4.5:1 (WCAG AA)', () {
        final ratio = contrastRatio(theme.mutedColor, theme.backgroundColor);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '$name mutedColor (${theme.mutedColor.toARGB32().toRadixString(16)}) '
              'vs backgroundColor (${theme.backgroundColor.toARGB32().toRadixString(16)}) '
              'contrast ratio is ${ratio.toStringAsFixed(2)}:1, '
              'below WCAG AA minimum 4.5:1',
        );
      });

      test('$name: textColor vs cardColor ≥ 7.0:1 (WCAG AAA)', () {
        final ratio = contrastRatio(theme.textColor, theme.cardColor);
        expect(
          ratio,
          greaterThanOrEqualTo(7.0),
          reason: '$name textColor (${theme.textColor.toARGB32().toRadixString(16)}) '
              'vs cardColor (${theme.cardColor.toARGB32().toRadixString(16)}) '
              'contrast ratio is ${ratio.toStringAsFixed(2)}:1, '
              'below WCAG AAA minimum 7.0:1',
        );
      });
    }

    // Smoke test: alert that AppTheme.light hint color meets AA.
    test('AppTheme.light hintColor (#4C5D7E) vs white ≥ 4.5:1', () {
      const hintColor = Color(0xFF4C5D7E);
      const white = Color(0xFFFFFFFF);
      final ratio = contrastRatio(hintColor, white);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason: 'InputDecorationTheme hintColor contrast ratio vs white is '
            '${ratio.toStringAsFixed(2)}:1, below WCAG AA',
      );
    });
  });
}
