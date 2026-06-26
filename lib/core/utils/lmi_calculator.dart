// lib/core/utils/lmi_calculator.dart — Australia LMI

class LMICalculator {
  /// Lenders Mortgage Insurance (Genworth/QBE approximation)
  /// LVR ≤ 80%: No LMI
  /// LVR 80.01–85%: 0.62% of loan
  /// LVR 85.01–90%: 1.45% of loan
  /// LVR 90.01–95%: 2.23% of loan
  static double calculateLMI({
    required double propertyValue,
    required double depositPercent,
  }) {
    final lvr = 100 - depositPercent;
    final loanAmount = propertyValue * (lvr / 100);
    if (lvr <= 80) return 0;
    if (lvr <= 85) return loanAmount * 0.0062;
    if (lvr <= 90) return loanAmount * 0.0145;
    if (lvr <= 95) return loanAmount * 0.0223;
    return 0; // >95% not typically offered
  }

  static String lmiTier(double depositPercent) {
    final lvr = 100 - depositPercent;
    if (lvr <= 80) return 'No LMI Required';
    if (lvr <= 85) return '0.62% of loan (LVR 80–85%)';
    if (lvr <= 90) return '1.45% of loan (LVR 85–90%)';
    if (lvr <= 95) return '2.23% of loan (LVR 90–95%)';
    return 'LVR exceeds 95% — check lender';
  }

  static bool isRequired(double depositPercent) =>
      depositPercent < 20;
}
