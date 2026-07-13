// lib/models/calculator_draft.dart
//
// PHASE-3: Immutable model for cross-calculator value passing.
//
// A CalculatorDraft is created when a user completes a calculation and wants
// to continue to a related calculator without re-entering shared fields.
// It is held in CalculatorDraftProvider (a Riverpod StateNotifier) and read
// by WorkflowContinuationCard to populate navigation arguments.
//
// Named distinctly from ToolLaunchArgs (which handles route-level country
// pre-selection and saved-calc restoration) to make the separate concerns clear.

class CalculatorDraft {
  /// Loan amount in the draft's currency (e.g. 360,000 USD).
  final double? loanAmount;

  /// Full property/purchase price (e.g. 450,000 USD).
  final double? propertyPrice;

  /// Annual interest rate as a percentage (e.g. 6.82 for 6.82%).
  final double? interestRate;

  /// Loan term in years (e.g. 30).
  final int? loanTermYears;

  /// Country code matching SettingsNotifier keys (e.g. 'USA', 'UK', 'CANADA').
  final String country;

  /// ISO 4217 currency code (e.g. 'USD', 'GBP').
  final String currency;

  /// Down payment amount in the draft's currency.
  final double? downPayment;

  const CalculatorDraft({
    this.loanAmount,
    this.propertyPrice,
    this.interestRate,
    this.loanTermYears,
    required this.country,
    required this.currency,
    this.downPayment,
  });

  CalculatorDraft copyWith({
    double? loanAmount,
    double? propertyPrice,
    double? interestRate,
    int? loanTermYears,
    String? country,
    String? currency,
    double? downPayment,
  }) {
    return CalculatorDraft(
      loanAmount: loanAmount ?? this.loanAmount,
      propertyPrice: propertyPrice ?? this.propertyPrice,
      interestRate: interestRate ?? this.interestRate,
      loanTermYears: loanTermYears ?? this.loanTermYears,
      country: country ?? this.country,
      currency: currency ?? this.currency,
      downPayment: downPayment ?? this.downPayment,
    );
  }

  @override
  String toString() => 'CalculatorDraft('
      'loanAmount: $loanAmount, '
      'propertyPrice: $propertyPrice, '
      'interestRate: $interestRate, '
      'loanTermYears: $loanTermYears, '
      'country: $country, '
      'currency: $currency, '
      'downPayment: $downPayment)';
}
