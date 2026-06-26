// lib/core/utils/cmhc_calculator.dart — Canada CMHC

import 'mortgage_math.dart';

class CMHCCalculator {
  /// CMHC Premium rates (2024)
  /// ≥5% and <10%: 4.00% of loan
  /// ≥10% and <15%: 3.10% of loan
  /// ≥15% and <20%: 2.80% of loan
  /// ≥20%: No insurance
  /// >$1.5M: Not eligible for insured mortgage
  static double calculatePremium({
    required double purchasePrice,
    required double downPaymentPercent,
  }) {
    if (purchasePrice > 1500000) return 0;
    if (downPaymentPercent >= 20) return 0;
    final loanAmount = purchasePrice * (1 - downPaymentPercent / 100);
    if (downPaymentPercent >= 15) return loanAmount * 0.028;
    if (downPaymentPercent >= 10) return loanAmount * 0.031;
    if (downPaymentPercent >= 5) return loanAmount * 0.040;
    return 0; // <5% not allowed in Canada
  }

  static String premiumRate(double downPaymentPercent) {
    if (downPaymentPercent >= 20) return '0% (No CMHC)';
    if (downPaymentPercent >= 15) return '2.80%';
    if (downPaymentPercent >= 10) return '3.10%';
    if (downPaymentPercent >= 5) return '4.00%';
    return 'Min 5% required';
  }

  /// Stress Test: qualify at max(contractRate + 2%, 5.25%)
  static double stressTestRate(double contractRate) {
    return [contractRate + 2.0, 5.25].reduce((a, b) => a > b ? a : b);
  }

  /// Maximum amortization: 25 years (insured), 30 years (uninsured)
  static int maxAmortization(double downPaymentPercent) =>
      downPaymentPercent >= 20 ? 30 : 25;

  /// GDS Ratio (Gross Debt Service) — must be ≤ 39%
  static double gdsRatio({
    required double monthlyMortgage,
    required double monthlyPropertyTax,
    required double monthlyHeating,
    required double grossMonthlyIncome,
  }) {
    if (grossMonthlyIncome == 0) return 0;
    return (monthlyMortgage + monthlyPropertyTax + monthlyHeating) /
        grossMonthlyIncome *
        100;
  }

  /// TDS Ratio (Total Debt Service) — must be ≤ 44%
  static double tdsRatio({
    required double monthlyMortgage,
    required double monthlyPropertyTax,
    required double monthlyHeating,
    required double otherMonthlyDebts,
    required double grossMonthlyIncome,
  }) {
    if (grossMonthlyIncome == 0) return 0;
    return (monthlyMortgage +
                monthlyPropertyTax +
                monthlyHeating +
                otherMonthlyDebts) /
            grossMonthlyIncome *
            100;
  }

  /// Can applicant pass stress test?
  static bool passesStressTest({
    required double purchasePrice,
    required double downPaymentPercent,
    required double contractRatePercent,
    required double grossAnnualIncome,
    required int termYears,
  }) {
    final stressRate = stressTestRate(contractRatePercent);
    final loanAmount = purchasePrice * (1 - downPaymentPercent / 100);
    final monthlyPayment = MortgageMath.canadianMonthlyPayment(
      principal: loanAmount,
      annualRatePercent: stressRate,
      termYears: termYears,
    );
    final monthlyIncome = grossAnnualIncome / 12;
    return (monthlyPayment / monthlyIncome) <= 0.39;
  }
}
