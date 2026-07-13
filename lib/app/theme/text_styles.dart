// lib/app/theme/text_styles.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // ── DM Sans for Headings (formerly Playfair) ──────────────────
  static TextStyle playfair({
    double size = 16,
    FontWeight weight = FontWeight.w800,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  // ── DM Sans (Body / Labels) ──────────────────────────────────
  static TextStyle dmSans({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  // ── Named styles ─────────────────────────────────────────────
  static TextStyle headerTitle(Color color) =>
      dmSans(size: 19, weight: FontWeight.w800, color: color);

  static TextStyle headerSub(Color color) =>
      dmSans(size: 10, weight: FontWeight.w500, color: color);

  static TextStyle heroTitle(Color color) =>
      dmSans(size: 18, weight: FontWeight.w800, color: color, height: 1.2);

  static TextStyle heroTag(Color color) => dmSans(
        size: 9,
        weight: FontWeight.w600,
        color: color,
        letterSpacing: 0.8,
      );

  static TextStyle sectionLabel(Color color) => dmSans(
        size: 10.5,
        weight: FontWeight.w800,
        color: color,
        letterSpacing: 1.0,
      );

  static TextStyle cardTitle(Color color) =>
      dmSans(size: 13, weight: FontWeight.w800, color: color, height: 1.2);

  static TextStyle cardDesc(Color color) =>
      dmSans(size: 9.5, weight: FontWeight.w400, color: color);

  static TextStyle rateValue(Color color) =>
      dmSans(size: 15.5, weight: FontWeight.w800, color: color, height: 1.15);

  static TextStyle rateLabel(Color color) => dmSans(
        size: 8,
        weight: FontWeight.w600,
        color: color,
        letterSpacing: 0.4,
      );

  static TextStyle rateNote(Color color) =>
      dmSans(size: 8, weight: FontWeight.w400, color: color);

  static TextStyle inputLabel(Color color) =>
      dmSans(size: 8.5, weight: FontWeight.w500, color: color);

  static TextStyle inputValue(Color color) =>
      dmSans(size: 13, weight: FontWeight.w700, color: color);

  static TextStyle buttonText(Color color) =>
      dmSans(size: 13, weight: FontWeight.w800, color: color);

  static TextStyle navLabel(Color color) => dmSans(
        size: 10,
        weight: FontWeight.w700,
        color: color,
        letterSpacing: 0.2,
      );

  static TextStyle infoTitle(Color color) =>
      dmSans(size: 12.5, weight: FontWeight.w800, color: color);

  static TextStyle infoSub(Color color) =>
      dmSans(size: 9.5, weight: FontWeight.w400, color: color);

  static TextStyle resultValue(Color color) =>
      dmSans(size: 28, weight: FontWeight.w800, color: color);

  static TextStyle resultLabel(Color color) =>
      dmSans(size: 11, weight: FontWeight.w600, color: color, letterSpacing: 0.3);

  static TextStyle badgeText(Color color) => dmSans(
        size: 8.5,
        weight: FontWeight.w700,
        color: color,
        letterSpacing: 0.2,
      );
}
