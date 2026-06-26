// lib/core/utils/currency_formatter.dart

import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String? preferredCurrencyCode;

  static String get activeCurrencyCode => preferredCurrencyCode ?? 'USD';

  static String format(
    double amount, {
    String? symbol,
    String? locale,
    int decimalDigits = 0,
    String? currencyCode,
  }) {
    final code = currencyCode ?? activeCurrencyCode;
    if (code == 'INR') {
      return _formatINR(amount);
    }
    final sym = symbol ?? _symbol(code);
    final loc = locale ?? _locale(code);
    final formatter = NumberFormat.currency(
      locale: loc,
      symbol: sym,
      decimalDigits: decimalDigits,
    );
    return formatter.format(amount);
  }

  static String compact(
    double amount, {
    String? symbol,
    String? currencyCode,
  }) {
    final code = currencyCode ?? activeCurrencyCode;
    final sym = symbol ?? _symbol(code);
    if (code == 'INR') {
      return _formatINR(amount);
    }
    if (amount >= 1000000) {
      return '$sym${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '$sym${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '$sym${amount.toStringAsFixed(0)}';
  }

  static String forCountry(double amount, String currencyCode) {
    return format(amount, currencyCode: currencyCode);
  }

  static String _formatINR(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)} L';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  static String percent(double value, {int decimals = 2}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  static String compactForCountry(double amount, String currencyCode) {
    return compact(amount);
  }

  static String _symbol(String code) {
    switch (code.toUpperCase()) {
      case 'GBP': return '£';
      case 'EUR': return '€';
      case 'INR': return '₹';
      case 'AUD': return 'AU\$';
      case 'CAD': return 'CA\$';
      case 'NZD': return 'NZ\$';
      default: return '\$';
    }
  }

  static String _locale(String code) {
    switch (code.toUpperCase()) {
      case 'GBP': return 'en_GB';
      case 'EUR': return 'de_DE';
      case 'AUD': return 'en_AU';
      case 'CAD': return 'en_CA';
      case 'NZD': return 'en_NZ';
      case 'INR': return 'en_IN';
      default: return 'en_US';
    }
  }
}
