// lib/core/utils/mortgage_math.dart

import 'dart:math';

class AmortizationEntry {
  final int month;
  final double payment;
  final double principal;
  final double interest;
  final double balance;
  final double totalInterestPaid;

  const AmortizationEntry({
    required this.month,
    required this.payment,
    required this.principal,
    required this.interest,
    required this.balance,
    required this.totalInterestPaid,
  });

  int get year => ((month - 1) ~/ 12) + 1;
}

class MortgageMath {
  /// Standard monthly payment — PMT formula
  /// P * r * (1+r)^n / ((1+r)^n - 1)
  static double monthlyPayment({
    required double principal,
    required double annualRatePercent,
    required int termYears,
  }) {
    if (annualRatePercent <= 0) {
      return principal / (termYears * 12);
    }
    final r = annualRatePercent / 100 / 12;
    final n = termYears * 12;
    final factor = pow(1 + r, n);
    return principal * (r * factor) / (factor - 1);
  }

  /// Canadian standard: semi-annual compounding
  /// Effective monthly rate = (1 + annualRate/2)^(1/6) - 1
  static double canadianMonthlyPayment({
    required double principal,
    required double annualRatePercent,
    required int termYears,
  }) {
    if (annualRatePercent <= 0) return principal / (termYears * 12);
    final r = pow(1 + annualRatePercent / 100 / 2, 1 / 6) - 1;
    final n = termYears * 12;
    final factor = pow(1 + r, n);
    return principal * (r * factor) / (factor - 1);
  }

  /// Fortnightly payment (AU/NZ): divide monthly by 2
  /// Effectively makes 13 months of payments per year
  static double fortnightlyPayment({
    required double principal,
    required double annualRatePercent,
    required int termYears,
  }) {
    final monthly = monthlyPayment(
      principal: principal,
      annualRatePercent: annualRatePercent,
      termYears: termYears,
    );
    return monthly / 2;
  }

  /// Full amortization schedule
  static List<AmortizationEntry> amortizationSchedule({
    required double principal,
    required double annualRatePercent,
    required int termYears,
    double extraMonthlyPayment = 0,
    bool canadian = false,
  }) {
    final schedule = <AmortizationEntry>[];
    double balance = principal;
    double totalInterestPaid = 0;
    final r = canadian
        ? (pow(1 + annualRatePercent / 100 / 2, 1 / 6) - 1).toDouble()
        : annualRatePercent / 100 / 12;
    final payment = canadian
        ? canadianMonthlyPayment(
            principal: principal,
            annualRatePercent: annualRatePercent,
            termYears: termYears,
          )
        : monthlyPayment(
            principal: principal,
            annualRatePercent: annualRatePercent,
            termYears: termYears,
          );
    final totalPayment = payment + extraMonthlyPayment;
    final n = termYears * 12;

    for (int month = 1; month <= n; month++) {
      if (balance <= 0) break;
      final interestCharge = balance * r;
      final principalCharge =
          min(totalPayment - interestCharge, balance);
      totalInterestPaid += interestCharge;
      balance -= principalCharge;
      if (balance < 0.01) balance = 0;

      schedule.add(AmortizationEntry(
        month: month,
        payment: interestCharge + principalCharge,
        principal: principalCharge,
        interest: interestCharge,
        balance: balance,
        totalInterestPaid: totalInterestPaid,
      ));
    }
    return schedule;
  }

  /// Total interest paid over loan term
  static double totalInterest({
    required double principal,
    required double annualRatePercent,
    required int termYears,
    bool canadian = false,
  }) {
    final monthly = canadian
        ? canadianMonthlyPayment(
            principal: principal,
            annualRatePercent: annualRatePercent,
            termYears: termYears,
          )
        : monthlyPayment(
            principal: principal,
            annualRatePercent: annualRatePercent,
            termYears: termYears,
          );
    return (monthly * termYears * 12) - principal;
  }

  /// Loan-to-Value ratio
  static double ltv(double loanAmount, double propertyValue) {
    if (propertyValue == 0) return 0;
    return (loanAmount / propertyValue) * 100;
  }

  /// Debt-to-Income ratio
  static double dti(double monthlyDebts, double grossMonthlyIncome) {
    if (grossMonthlyIncome == 0) return 0;
    return (monthlyDebts / grossMonthlyIncome) * 100;
  }

  /// Maximum borrowing capacity given DTI constraint
  static double maxBorrowing({
    required double grossAnnualIncome,
    required double annualRatePercent,
    required int termYears,
    required double maxDtiPercent,
  }) {
    final maxMonthlyPayment =
        (grossAnnualIncome / 12) * (maxDtiPercent / 100);
    if (annualRatePercent <= 0) return maxMonthlyPayment * termYears * 12;
    final r = annualRatePercent / 100 / 12;
    final n = termYears * 12;
    final factor = pow(1 + r, n);
    return maxMonthlyPayment * (factor - 1) / (r * factor);
  }

  /// Refinance break-even months
  static int refinanceBreakEven({
    required double closingCosts,
    required double monthlySavings,
  }) {
    if (monthlySavings <= 0) return -1;
    return (closingCosts / monthlySavings).ceil();
  }

  /// Simple interest (for short-term loans)
  static double simpleInterest({
    required double principal,
    required double annualRatePercent,
    required double years,
  }) {
    return principal * (annualRatePercent / 100) * years;
  }

  /// Annual percentage rate from monthly rate
  static double aprFromMonthlyRate(double monthlyRate) {
    return (pow(1 + monthlyRate, 12) - 1) * 100;
  }

  /// Yearly amortization summary (for chart)
  static List<Map<String, double>> yearlyAmortization({
    required double principal,
    required double annualRatePercent,
    required int termYears,
    double extraMonthlyPayment = 0,
    bool canadian = false,
  }) {
    final schedule = amortizationSchedule(
      principal: principal,
      annualRatePercent: annualRatePercent,
      termYears: termYears,
      extraMonthlyPayment: extraMonthlyPayment,
      canadian: canadian,
    );

    final Map<int, Map<String, double>> yearMap = {};
    for (final entry in schedule) {
      final yr = entry.year;
      yearMap[yr] ??= {'principal': 0, 'interest': 0, 'balance': 0};
      yearMap[yr]!['principal'] = yearMap[yr]!['principal']! + entry.principal;
      yearMap[yr]!['interest'] = yearMap[yr]!['interest']! + entry.interest;
      yearMap[yr]!['balance'] = entry.balance;
    }

    return yearMap.entries
        .map((e) => {
              'year': e.key.toDouble(),
              'principal': e.value['principal']!,
              'interest': e.value['interest']!,
              'balance': e.value['balance']!,
            })
        .toList();
  }
}
