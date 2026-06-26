// lib/providers/settings_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/currency_formatter.dart';
import '../services/analytics_service.dart';

class AppSettings {
  final String themeMode; // 'light' | 'dark' | 'system'
  final int defaultTermYears;
  final double defaultDepositPercent;
  final String geminiApiKey;
  final String preferredCountry;
  final String preferredCurrency;
  final bool privacyChoicesOptOut;

  const AppSettings({
    this.themeMode = 'system',
    this.defaultTermYears = 30,
    this.defaultDepositPercent = 20.0,
    this.geminiApiKey = '',
    this.preferredCountry = 'USA',
    this.preferredCurrency = 'USD',
    this.privacyChoicesOptOut = false,
  });

  /// Backward-compat getter for code that still checks `settings.darkMode`
  bool get darkMode => themeMode == 'dark';

  /// Convert to Flutter ThemeMode
  ThemeMode get flutterThemeMode {
    switch (themeMode) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  AppSettings copyWith({
    String? themeMode,
    int? defaultTermYears,
    double? defaultDepositPercent,
    String? geminiApiKey,
    String? preferredCountry,
    String? preferredCurrency,
    bool? privacyChoicesOptOut,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      defaultTermYears: defaultTermYears ?? this.defaultTermYears,
      defaultDepositPercent:
          defaultDepositPercent ?? this.defaultDepositPercent,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      preferredCountry: preferredCountry ?? this.preferredCountry,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      privacyChoicesOptOut: privacyChoicesOptOut ?? this.privacyChoicesOptOut,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final cur = prefs.getString('preferred_currency') ?? 'USD';
    CurrencyFormatter.preferredCurrencyCode = cur;

    // Migrate from old bool dark_mode key to the new string theme_mode key
    String storedTheme = prefs.getString('theme_mode') ?? '';
    if (storedTheme.isEmpty) {
      final legacyDark = prefs.getBool('dark_mode') ?? false;
      storedTheme = legacyDark ? 'dark' : 'system';
    }

    state = AppSettings(
      themeMode: storedTheme,
      defaultTermYears: prefs.getInt('default_term') ?? 30,
      defaultDepositPercent: prefs.getDouble('default_deposit') ?? 20.0,
      geminiApiKey: prefs.getString('gemini_key') ?? '',
      preferredCountry: prefs.getString('preferred_country') ?? 'USA',
      preferredCurrency: cur,
      privacyChoicesOptOut: prefs.getBool('privacy_choices_opt_out') ?? false,
    );
  }

  /// Primary setter — accepts 'light', 'dark', or 'system'
  Future<void> setThemeMode(String mode) async {
    assert(
      ['light', 'dark', 'system'].contains(mode),
      'themeMode must be light, dark, or system',
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode);
    // Keep the legacy bool in sync for migration purposes
    await prefs.setBool('dark_mode', mode == 'dark');
    state = state.copyWith(themeMode: mode);
    await AnalyticsService.instance.setUserProperty('preferred_theme', mode);
    await AnalyticsService.instance.logThemeChange(mode);
  }

  /// Backward-compat wrapper — used by any existing code calling setDarkMode(bool)
  Future<void> setDarkMode(bool value) =>
      setThemeMode(value ? 'dark' : 'light');

  Future<void> setDefaultTerm(int years) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('default_term', years);
    state = state.copyWith(defaultTermYears: years);
  }

  Future<void> setDefaultDeposit(double percent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('default_deposit', percent);
    state = state.copyWith(defaultDepositPercent: percent);
  }

  Future<void> setGeminiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_key', key);
    state = state.copyWith(geminiApiKey: key);
  }

  Future<void> setPreferredCountry(String country) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_country', country);
    state = state.copyWith(preferredCountry: country);
    await AnalyticsService.instance.setUserProperty('country', country);
    await AnalyticsService.instance.logCountrySelection(country);
  }

  Future<void> setPreferredCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_currency', currency);
    CurrencyFormatter.preferredCurrencyCode = currency;
    state = state.copyWith(preferredCurrency: currency);
    await AnalyticsService.instance.setUserProperty(
      'preferred_currency',
      currency,
    );
  }

  Future<void> setPrivacyChoicesOptOut(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('privacy_choices_opt_out', value);
    state = state.copyWith(privacyChoicesOptOut: value);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    state = const AppSettings();
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
