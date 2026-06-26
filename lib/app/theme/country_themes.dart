// lib/app/theme/country_themes.dart

import 'package:flutter/material.dart';

class CountryTheme {
  final LinearGradient headerGradient;
  final LinearGradient heroGradient;
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color cardColor;
  final Color textColor;
  final Color mutedColor;
  final Color borderColor;
  final String flag;
  final String emoji; // Decorative watermark emoji
  final String name;
  final String subtitle;
  final String currencySymbol;
  final String currencyCode;
  final Color alertBannerBg1;
  final Color alertBannerBg2;
  final Color alertBannerBorder;
  final Color alertBannerButton;

  const CountryTheme({
    required this.headerGradient,
    required this.heroGradient,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.cardColor,
    required this.textColor,
    required this.mutedColor,
    required this.borderColor,
    required this.flag,
    required this.emoji,
    required this.name,
    required this.subtitle,
    required this.currencySymbol,
    required this.currencyCode,
    required this.alertBannerBg1,
    required this.alertBannerBg2,
    required this.alertBannerBorder,
    required this.alertBannerButton,
  });

  Color getBgColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0A0F1E)
        : backgroundColor;
  }

  Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF141C33)
        : cardColor;
  }

  Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : textColor;
  }

  Color getMutedColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : mutedColor;
  }

  Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.10)
        : borderColor;
  }
}

class CountryThemes {
  // ─── 🇺🇸 USA ─────────────────────────────────────────────────
  static const usa = CountryTheme(
    headerGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF061528), Color(0xFF0F2D6B), Color(0xFFA51C0E)],
      stops: [0.0, 0.58, 1.0],
    ),
    heroGradient: LinearGradient(
      begin: Alignment(0.0, -1.0),
      end: Alignment(1.0, 1.0),
      colors: [Color(0xFF061528), Color(0xFF0F2D6B)],
    ),
    primaryColor: Color(0xFF0F2D6B),
    accentColor: Color(0xFF1E4FBF),
    backgroundColor: Color(0xFFEEF3FF),
    cardColor: Color(0xFFFFFFFF),
    textColor: Color(0xFF061528),
    mutedColor: Color(0xFF3D5280),
    borderColor: Color(0x161B3F72),
    flag: '🇺🇸',
    emoji: '🦅',
    name: 'USA Financial Tools',
    subtitle: 'USD · FRED · Fed Rate · All 50 States',
    currencySymbol: '\$',
    currencyCode: 'USD',
    alertBannerBg1: Color(0xFFFEF3C7),
    alertBannerBg2: Color(0xFFFDE68A),
    alertBannerBorder: Color(0xFFF59E0B),
    alertBannerButton: Color(0xFFD97706),
  );

  // ─── 🇬🇧 UK ──────────────────────────────────────────────────
  static const uk = CountryTheme(
    headerGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF060618), Color(0xFF14145A), Color(0xFFB80C29)],
      stops: [0.0, 0.55, 1.0],
    ),
    heroGradient: LinearGradient(
      begin: Alignment(0.0, -1.0),
      end: Alignment(1.0, 1.0),
      colors: [Color(0xFF060618), Color(0xFF14145A)],
    ),
    primaryColor: Color(0xFF14145A),
    accentColor: Color(0xFF4F46E5),
    backgroundColor: Color(0xFFF4F4FA),
    cardColor: Color(0xFFFFFFFF),
    textColor: Color(0xFF060618),
    mutedColor: Color(0xFF505080),
    borderColor: Color(0x161A1A5E),
    flag: '🇬🇧',
    emoji: '👑',
    name: 'UK Tools',
    subtitle: 'GBP · BoE Rate · SDLT',
    currencySymbol: '£',
    currencyCode: 'GBP',
    alertBannerBg1: Color(0xFFEEF2FF),
    alertBannerBg2: Color(0xFFE0E7FF),
    alertBannerBorder: Color(0xFFA5B4FC),
    alertBannerButton: Color(0xFF4F46E5),
  );

  // ─── 🇦🇺 Australia ───────────────────────────────────────────
  static const australia = CountryTheme(
    headerGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF140800), Color(0xFF6B1E08), Color(0xFF001F5C)],
      stops: [0.0, 0.55, 1.0],
    ),
    heroGradient: LinearGradient(
      begin: Alignment(0.0, -1.0),
      end: Alignment(1.0, 1.0),
      colors: [Color(0xFF140800), Color(0xFF6B1E08)],
    ),
    primaryColor: Color(0xFF6B1E08),
    accentColor: Color(0xFF001F5C),
    backgroundColor: Color(0xFFFFF7F0),
    cardColor: Color(0xFFFFFFFF),
    textColor: Color(0xFF140800),
    mutedColor: Color(0xFF7A3A1A),
    borderColor: Color(0x147C2D12),
    flag: '🇦🇺',
    emoji: '🦘',
    name: 'Australia Tools',
    subtitle: 'AUD · RBA Rate · LMI',
    currencySymbol: 'AU\$',
    currencyCode: 'AUD',
    alertBannerBg1: Color(0xFFFFF7ED),
    alertBannerBg2: Color(0xFFFFEDD5),
    alertBannerBorder: Color(0xFFFCA5A5),
    alertBannerButton: Color(0xFFEA580C),
  );

  // ─── 🇨🇦 Canada ──────────────────────────────────────────────
  static const canada = CountryTheme(
    headerGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF071F12), Color(0xFF14492A), Color(0xFFB20D28)],
      stops: [0.0, 0.60, 1.0],
    ),
    heroGradient: LinearGradient(
      begin: Alignment(0.0, -1.0),
      end: Alignment(1.0, 1.0),
      colors: [Color(0xFF071F12), Color(0xFF14492A)],
    ),
    primaryColor: Color(0xFF14492A),
    accentColor: Color(0xFFB20D28),
    backgroundColor: Color(0xFFEFF7F3),
    cardColor: Color(0xFFFFFFFF),
    textColor: Color(0xFF071F12),
    mutedColor: Color(0xFF3D6650),
    borderColor: Color(0x141A5C35),
    flag: '🇨🇦',
    emoji: '🍁',
    name: 'Canada Tools',
    subtitle: 'CAD · BoC Rate · CMHC',
    currencySymbol: 'CA\$',
    currencyCode: 'CAD',
    alertBannerBg1: Color(0xFFFEF3C7),
    alertBannerBg2: Color(0xFFFDE68A),
    alertBannerBorder: Color(0xFFF59E0B),
    alertBannerButton: Color(0xFFF59E0B),
  );

  // ─── 🇪🇺 Europe ──────────────────────────────────────────────
  static const europe = CountryTheme(
    headerGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF00236B), Color(0xFF110035), Color(0xFFE6B800)],
      stops: [0.0, 0.55, 1.0],
    ),
    heroGradient: LinearGradient(
      begin: Alignment(0.0, -1.0),
      end: Alignment(1.0, 1.0),
      colors: [Color(0xFF00236B), Color(0xFF110035)],
    ),
    primaryColor: Color(0xFF00236B),
    accentColor: Color(0xFFE6B800),
    backgroundColor: Color(0xFFF6F2FF),
    cardColor: Color(0xFFFFFFFF),
    textColor: Color(0xFF110035),
    mutedColor: Color(0xFF4B3A80),
    borderColor: Color(0x14003399),
    flag: '🇪🇺',
    emoji: '🏛️',
    name: 'Europe Tools',
    subtitle: 'EUR · ECB Rate · Euribor',
    currencySymbol: '€',
    currencyCode: 'EUR',
    alertBannerBg1: Color(0xFFEEF2FF),
    alertBannerBg2: Color(0xFFE0E7FF),
    alertBannerBorder: Color(0xFF818CF8),
    alertBannerButton: Color(0xFF4F46E5),
  );

  // ─── 🇮🇳 India ───────────────────────────────────────────────
  static const india = CountryTheme(
    headerGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF140000), Color(0xFFE05F00), Color(0xFF005200)],
      stops: [0.0, 0.55, 1.0],
    ),
    heroGradient: LinearGradient(
      begin: Alignment(0.0, -1.0),
      end: Alignment(1.0, 1.0),
      colors: [Color(0xFF140000), Color(0xFFB84A00)],
    ),
    primaryColor: Color(0xFFE05F00),
    accentColor: Color(0xFF005200),
    backgroundColor: Color(0xFFFFF7EE),
    cardColor: Color(0xFFFFFFFF),
    textColor: Color(0xFF140000),
    mutedColor: Color(0xFF804A00),
    borderColor: Color(0x14FF6B00),
    flag: '🇮🇳',
    emoji: '🕌',
    name: 'India Tools',
    subtitle: 'INR · RBI Rate · Home Loan',
    currencySymbol: '₹',
    currencyCode: 'INR',
    alertBannerBg1: Color(0xFFFFF7ED),
    alertBannerBg2: Color(0xFFFFEDD5),
    alertBannerBorder: Color(0xFFFBBF24),
    alertBannerButton: Color(0xFFE05F00),
  );

  // ─── 🇳🇿 New Zealand ─────────────────────────────────────────
  static const newZealand = CountryTheme(
    headerGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0A0F0D), Color(0xFF0D3B2E), Color(0xFF1A6B4A)],
      stops: [0.0, 0.55, 1.0],
    ),
    heroGradient: LinearGradient(
      begin: Alignment(0.0, -1.0),
      end: Alignment(1.0, 1.0),
      colors: [Color(0xFF0A0F0D), Color(0xFF0D3B2E)],
    ),
    primaryColor: Color(0xFF1A6B4A),
    accentColor: Color(0xFF0D9488),
    backgroundColor: Color(0xFFEDF5F2),
    cardColor: Color(0xFFFFFFFF),
    textColor: Color(0xFF0A0F0D),
    mutedColor: Color(0xFF4A6358),
    borderColor: Color(0x140D3B2E),
    flag: '🇳🇿',
    emoji: '🌿',
    name: 'New Zealand Tools',
    subtitle: 'NZD · OCR Rate · LVR',
    currencySymbol: 'NZ\$',
    currencyCode: 'NZD',
    alertBannerBg1: Color(0xFFF0FDFA),
    alertBannerBg2: Color(0xFFCCFBF1),
    alertBannerBorder: Color(0xFF5EEAD4),
    alertBannerButton: Color(0xFF0D9488),
  );

  static const List<CountryTheme> all = [
    usa,
    uk,
    australia,
    canada,
    europe,
    india,
    newZealand,
  ];

  static CountryTheme fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'UK':
      case 'UNITED KINGDOM':
        return uk;
      case 'AU':
      case 'AUSTRALIA':
        return australia;
      case 'CA':
      case 'CANADA':
        return canada;
      case 'EU':
      case 'EUROPE':
        return europe;
      case 'IN':
      case 'INDIA':
        return india;
      case 'NZ':
      case 'NEW ZEALAND':
      case 'NEWZEALAND':
        return newZealand;
      default:
        return usa;
    }
  }
}
