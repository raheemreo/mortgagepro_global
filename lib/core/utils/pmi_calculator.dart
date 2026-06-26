// lib/core/utils/pmi_calculator.dart — USA PMI

class PMICalculator {
  /// US PMI — Private Mortgage Insurance
  /// Required when LTV > 80% (down payment < 20%)
  /// Annual rate varies by LTV and credit score
  static double annualPMIRate(double ltvPercent,
      {int creditScore = 720}) {
    if (ltvPercent <= 80) return 0;
    // Simplified rate table based on LTV
    if (ltvPercent <= 85) return creditScore >= 740 ? 0.0020 : 0.0030;
    if (ltvPercent <= 90) return creditScore >= 740 ? 0.0040 : 0.0060;
    if (ltvPercent <= 95) return creditScore >= 740 ? 0.0060 : 0.0090;
    return creditScore >= 740 ? 0.0080 : 0.0120;
  }

  static double monthlyPMI({
    required double loanAmount,
    required double ltvPercent,
    int creditScore = 720,
  }) {
    final rate = annualPMIRate(ltvPercent, creditScore: creditScore);
    return loanAmount * rate / 12;
  }

  /// LTV at which PMI can be cancelled (typically 80%)
  static double propertyValueAtCancellation(double loanAmount) =>
      loanAmount / 0.80;

  static bool isPMIRequired(double downPaymentPercent) =>
      downPaymentPercent < 20;

  static String rateDescription(double ltvPercent) {
    if (ltvPercent <= 80) return '0% — No PMI Required';
    if (ltvPercent <= 85) return '0.20%–0.30% annually';
    if (ltvPercent <= 90) return '0.40%–0.60% annually';
    if (ltvPercent <= 95) return '0.60%–0.90% annually';
    return '0.80%–1.20% annually';
  }
}
