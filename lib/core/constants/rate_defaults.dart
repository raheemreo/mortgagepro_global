// lib/core/constants/rate_defaults.dart

/// Fallback rate data when Firestore is unavailable
class RateDefaults {
  static const Map<String, Map<String, dynamic>> rates = {
    'usa': {
      'thirtyYrFixed': 6.82,
      'fifteenYrFixed': 6.11,
      'armFiveOne': 6.05,
      'fedFunds': 5.33,
      'labels': ['30-Yr Fixed', '15-Yr Fixed', '5/1 ARM', 'Fed Funds'],
      'notes': ['Freddie Mac', 'Avg', 'Avg', 'FOMC'],
      'colors': ['red', 'normal', 'normal', 'gold'],
    },
    'uk': {
      'twoYrFixed': 4.75,
      'fiveYrFixed': 4.35,
      'tracker': 5.25,
      'boeBase': 5.00,
      'labels': ['2-Yr Fixed', '5-Yr Fixed', 'Tracker', 'BoE Base'],
      'notes': ['↑ +0.05', 'BoE', 'Base+0.25', 'Current'],
      'colors': ['red', 'normal', 'green', 'gold'],
    },
    'australia': {
      'variable': 6.09,
      'twoYrFixed': 6.29,
      'threeYrFixed': 6.15,
      'rbaCash': 4.35,
      'labels': ['Variable', '2-Yr Fixed', '3-Yr Fixed', 'RBA Cash'],
      'notes': ['↓ -0.25', 'Avg', 'Big 4', 'Current'],
      'colors': ['red', 'normal', 'green', 'gold'],
    },
    'canada': {
      'fiveYrFixed': 4.99,
      'threeYrFixed': 5.14,
      'variable': 5.95,
      'stressTest': 7.00,
      'labels': ['5-Yr Fixed', '3-Yr Fixed', 'Variable', 'Stress Test'],
      'notes': ['↓ -0.1 wk', 'BoC', 'Prime−0.5', 'Min rate'],
      'colors': ['red', 'normal', 'green', 'normal'],
    },
    'europe': {
      'germany': 3.85,
      'france': 3.60,
      'spain': 4.10,
      'ecbRate': 4.00,
      'labels': ['🇩🇪 Germany', '🇫🇷 France', '🇪🇸 Spain', 'ECB Rate'],
      'notes': ['Avg', 'Avg', 'Avg', 'Current'],
      'colors': ['green', 'normal', 'red', 'gold'],
    },
    'india': {
      'sbiRate': 8.50,
      'hdfcRate': 8.75,
      'repoRate': 6.50,
      'maxLtv': 80.0,
      'labels': ['SBI Rate', 'HDFC Rate', 'Repo Rate', 'Max LTV'],
      'notes': ['Effective', 'Effective', 'RBI', 'Limit'],
      'colors': ['normal', 'normal', 'gold', 'normal'],
    },
    'newzealand': {
      'oneYrFixed': 6.99,
      'twoYrFixed': 6.60,
      'variable': 7.10,
      'ocrRate': 5.50,
      'labels': ['1-Yr Fixed', '2-Yr Fixed', 'Variable', 'OCR Rate'],
      'notes': ['↑ +0.1', 'Avg', 'Avg', 'RBNZ'],
      'colors': ['red', 'normal', 'normal', 'gold'],
    },
  };

  static List<double> getValues(String country) {
    final r = rates[country]!;
    return (r.values.whereType<double>().toList());
  }
}
