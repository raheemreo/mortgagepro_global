// lib/providers/settings_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/currency_formatter.dart';
import '../services/analytics_service.dart';

class AppSettings {
  final String themeMode; // 'light' | 'dark' | 'system'
  final int defaultTermYears;
  final double defaultDepositPercent;
  final String preferredCountry;
  final String preferredCurrency;
  final bool privacyChoicesOptOut;
  final String? region;
  final String? selectedEuropeCountry;
  final Map<String, String> preferredCalculatorTab;
  final String? pinnedCountry;
  final Map<String, String> calculatorInputs;

  const AppSettings({
    this.themeMode = 'system',
    this.defaultTermYears = 30,
    this.defaultDepositPercent = 20.0,
    this.preferredCountry = 'USA',
    this.preferredCurrency = 'USD',
    this.privacyChoicesOptOut = false,
    this.region,
    this.selectedEuropeCountry,
    this.preferredCalculatorTab = const {},
    this.pinnedCountry,
    this.calculatorInputs = const {},
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
    String? preferredCountry,
    String? preferredCurrency,
    bool? privacyChoicesOptOut,
    String? region,
    String? selectedEuropeCountry,
    Map<String, String>? preferredCalculatorTab,
    String? pinnedCountry,
    Map<String, String>? calculatorInputs,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      defaultTermYears: defaultTermYears ?? this.defaultTermYears,
      defaultDepositPercent:
          defaultDepositPercent ?? this.defaultDepositPercent,
      preferredCountry: preferredCountry ?? this.preferredCountry,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      privacyChoicesOptOut: privacyChoicesOptOut ?? this.privacyChoicesOptOut,
      region: region ?? this.region,
      selectedEuropeCountry:
          selectedEuropeCountry ?? this.selectedEuropeCountry,
      preferredCalculatorTab:
          preferredCalculatorTab ?? this.preferredCalculatorTab,
      pinnedCountry: pinnedCountry ?? this.pinnedCountry,
      calculatorInputs: calculatorInputs ?? this.calculatorInputs,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Secure Cleanup: Remove any previously stored plaintext gemini_key
    if (prefs.containsKey('gemini_key')) {
      await prefs.remove('gemini_key');
    }

    final cur = prefs.getString('preferred_currency') ?? 'USD';
    CurrencyFormatter.preferredCurrencyCode = cur;

    // Migrate from old bool dark_mode key to the new string theme_mode key
    String storedTheme = prefs.getString('theme_mode') ?? '';
    if (storedTheme.isEmpty) {
      final legacyDark = prefs.getBool('dark_mode') ?? false;
      storedTheme = legacyDark ? 'dark' : 'system';
    }

    // Load new fields
    final region = prefs.getString('region');
    final selectedEuropeCountry = prefs.getString('selected_europe_country');
    final pinnedCountry = prefs.getString('pinned_country');
    
    Map<String, String> preferredCalculatorTab = {};
    final tabsStr = prefs.getString('preferred_calculator_tabs') ?? '';
    if (tabsStr.isNotEmpty) {
      try {
        final decoded = json.decode(tabsStr);
        if (decoded is Map) {
          preferredCalculatorTab = decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      } catch (_) {}
    }

    Map<String, String> calculatorInputs = {};
    final inputsStr = prefs.getString('calculator_inputs') ?? '';
    if (inputsStr.isNotEmpty) {
      try {
        final decoded = json.decode(inputsStr);
        if (decoded is Map) {
          calculatorInputs = decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      } catch (_) {}
    }

    state = AppSettings(
      themeMode: storedTheme,
      defaultTermYears: prefs.getInt('default_term') ?? 30,
      defaultDepositPercent: prefs.getDouble('default_deposit') ?? 20.0,
      preferredCountry: prefs.getString('preferred_country') ?? 'USA',
      preferredCurrency: cur,
      privacyChoicesOptOut: prefs.getBool('privacy_choices_opt_out') ?? false,
      region: region,
      selectedEuropeCountry: selectedEuropeCountry,
      preferredCalculatorTab: preferredCalculatorTab,
      pinnedCountry: pinnedCountry,
      calculatorInputs: calculatorInputs,
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

  Future<void> setRegion(String? value) async {
    state = AppSettings(
      themeMode: state.themeMode,
      defaultTermYears: state.defaultTermYears,
      defaultDepositPercent: state.defaultDepositPercent,
      preferredCountry: state.preferredCountry,
      preferredCurrency: state.preferredCurrency,
      privacyChoicesOptOut: state.privacyChoicesOptOut,
      region: value,
      selectedEuropeCountry: state.selectedEuropeCountry,
      preferredCalculatorTab: state.preferredCalculatorTab,
      pinnedCountry: state.pinnedCountry,
      calculatorInputs: state.calculatorInputs,
    );
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove('region');
    } else {
      await prefs.setString('region', value);
    }
  }

  Future<void> setEuropeCountry(String? value) async {
    state = AppSettings(
      themeMode: state.themeMode,
      defaultTermYears: state.defaultTermYears,
      defaultDepositPercent: state.defaultDepositPercent,
      preferredCountry: state.preferredCountry,
      preferredCurrency: state.preferredCurrency,
      privacyChoicesOptOut: state.privacyChoicesOptOut,
      region: state.region,
      selectedEuropeCountry: value,
      preferredCalculatorTab: state.preferredCalculatorTab,
      pinnedCountry: state.pinnedCountry,
      calculatorInputs: state.calculatorInputs,
    );
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove('selected_europe_country');
    } else {
      await prefs.setString('selected_europe_country', value);
    }
  }

  Future<void> setCalculatorTab(String country, String tab) async {
    final newTabs = Map<String, String>.from(state.preferredCalculatorTab);
    newTabs[country] = tab;
    
    state = AppSettings(
      themeMode: state.themeMode,
      defaultTermYears: state.defaultTermYears,
      defaultDepositPercent: state.defaultDepositPercent,
      preferredCountry: state.preferredCountry,
      preferredCurrency: state.preferredCurrency,
      privacyChoicesOptOut: state.privacyChoicesOptOut,
      region: state.region,
      selectedEuropeCountry: state.selectedEuropeCountry,
      preferredCalculatorTab: newTabs,
      pinnedCountry: state.pinnedCountry,
      calculatorInputs: state.calculatorInputs,
    );

    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(newTabs);
    await prefs.setString('preferred_calculator_tabs', jsonStr);
  }

  Future<void> setPinnedCountry(String? value) async {
    state = AppSettings(
      themeMode: state.themeMode,
      defaultTermYears: state.defaultTermYears,
      defaultDepositPercent: state.defaultDepositPercent,
      preferredCountry: state.preferredCountry,
      preferredCurrency: state.preferredCurrency,
      privacyChoicesOptOut: state.privacyChoicesOptOut,
      region: state.region,
      selectedEuropeCountry: state.selectedEuropeCountry,
      preferredCalculatorTab: state.preferredCalculatorTab,
      pinnedCountry: value,
      calculatorInputs: state.calculatorInputs,
    );
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove('pinned_country');
    } else {
      await prefs.setString('pinned_country', value);
    }
  }

  Future<void> saveCalculatorInput(String country, String toolId, Map<String, dynamic> inputs) async {
    final key = '${country.toLowerCase()}_${toolId.toLowerCase()}';
    final newInputs = Map<String, String>.from(state.calculatorInputs);
    newInputs[key] = json.encode(inputs);

    state = AppSettings(
      themeMode: state.themeMode,
      defaultTermYears: state.defaultTermYears,
      defaultDepositPercent: state.defaultDepositPercent,
      preferredCountry: state.preferredCountry,
      preferredCurrency: state.preferredCurrency,
      privacyChoicesOptOut: state.privacyChoicesOptOut,
      region: state.region,
      selectedEuropeCountry: state.selectedEuropeCountry,
      preferredCalculatorTab: state.preferredCalculatorTab,
      pinnedCountry: state.pinnedCountry,
      calculatorInputs: newInputs,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('calculator_inputs', json.encode(newInputs));
  }

  Map<String, dynamic>? getCalculatorInputs(String country, String toolId) {
    final key = '${country.toLowerCase()}_${toolId.toLowerCase()}';
    final val = state.calculatorInputs[key];
    if (val == null || val.isEmpty) return null;
    try {
      return json.decode(val) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
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
