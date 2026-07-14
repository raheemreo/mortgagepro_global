// lib/features/australia/tools/au_extra_repayments.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class AUExtraRepayments extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const AUExtraRepayments({super.key, this.theme = CountryThemes.australia});

  @override
  ConsumerState<AUExtraRepayments> createState() => _AUExtraRepaymentsState();
}

class _AUExtraRepaymentsState extends ConsumerState<AUExtraRepayments> {
  double _loanBalance = 480000;
  double _interestRate = 6.09;
  int _loanTerm = 25;
  String _repaymentType = 'monthly'; // 'monthly', 'fortnightly', 'weekly'
  double _extraAmount = 500;
  String _freqExtra = 'fortnightly'; // 'weekly', 'fortnightly', 'monthly', 'yearly'
  int _startFrom = 0; // 0 (now), 12 (Year 1), 24 (Year 2), 36 (Year 3), 60 (Year 5)
  double _lumpSum = 0;

  bool _showResults = false;
  final Map<String, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};
  final _resultsKey = GlobalKey();

  void _reset() {
    setState(() {
      _loanBalance = 480000;
      _interestRate = 6.09;
      _loanTerm = 25;
      _repaymentType = 'monthly';
      _extraAmount = 500;
      _freqExtra = 'fortnightly';
      _startFrom = 0;
      _lumpSum = 0;
      _showResults = false;
      _calcSnapshot.clear();
      _errors.clear();
    });
  }

  double _extraPerMonth(double amount, String freq) {
    switch (freq) {
      case 'weekly':
        return amount * 52 / 12;
      case 'fortnightly':
        return amount * 26 / 12;
      case 'monthly':
        return amount;
      case 'yearly':
        return amount / 12;
      default:
        return amount;
    }
  }

  double _monthlyPmt(double p, double annualRate, int years) {
    final r = annualRate / 100 / 12;
    final n = years * 12;
    if (r == 0) return p / n;
    return p * r * pow(1 + r, n) / (pow(1 + r, n) - 1);
  }

  void _calculate() {
    final errors = <String, String>{};

    if (_loanBalance <= 0) {
      errors['loanBalance'] = 'Enter valid loan balance';
    }
    if (_interestRate <= 0 || _interestRate > 25) {
      errors['interestRate'] = 'Enter rate (0.1% - 25%)';
    }
    if (_loanTerm <= 0 || _loanTerm > 50) {
      errors['loanTerm'] = 'Enter term (1-50)';
    }
    if (_extraAmount < 0) {
      errors['extraAmount'] = 'Extra amount cannot be negative';
    }
    if (_lumpSum < 0) {
      errors['lumpSum'] = 'Lump sum cannot be negative';
    }

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) return;

    setState(() {
      _calcSnapshot['loanBalance'] = _loanBalance;
      _calcSnapshot['interestRate'] = _interestRate;
      _calcSnapshot['loanTerm'] = _loanTerm;
      _calcSnapshot['repaymentType'] = _repaymentType;
      _calcSnapshot['extraAmount'] = _extraAmount;
      _calcSnapshot['freqExtra'] = _freqExtra;
      _calcSnapshot['startFrom'] = _startFrom;
      _calcSnapshot['lumpSum'] = _lumpSum;
      _showResults = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_resultsKey.currentContext != null) {
        Scrollable.ensureVisible(
          _resultsKey.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _saveCalculation() async {
    final double snapLoanBalance = _calcSnapshot['loanBalance'] ?? _loanBalance;
    final double snapInterestRate = _calcSnapshot['interestRate'] ?? _interestRate;
    final int snapLoanTerm = _calcSnapshot['loanTerm'] ?? _loanTerm;
    final double snapExtraAmount = _calcSnapshot['extraAmount'] ?? _extraAmount;
    final String snapFreqExtra = _calcSnapshot['freqExtra'] ?? _freqExtra;
    final int snapStartFrom = _calcSnapshot['startFrom'] ?? _startFrom;
    final double snapLumpSum = _calcSnapshot['lumpSum'] ?? _lumpSum;

    final r = snapInterestRate / 100 / 12;
    final n = snapLoanTerm * 12;
    final stdPmt = _monthlyPmt(snapLoanBalance, snapInterestRate, snapLoanTerm);
    final extraMo = _extraPerMonth(snapExtraAmount, snapFreqExtra);

    // Standard
    double balStd = snapLoanBalance;
    double intStd = 0;
    for (int m = 1; m <= n; m++) {
      final i = balStd * r;
      intStd += i;
      balStd = max(0.0, balStd - (stdPmt - i));
    }

    // With extra
    double balNew = snapLoanBalance - snapLumpSum;
    double intNew = 0;
    int newN = 0;
    double bal = max(0.0, balNew);
    for (int m = 1; m <= n + 120; m++) {
      if (bal <= 0) break;
      final i = bal * r;
      intNew += i;
      final payment = stdPmt + (m > snapStartFrom ? extraMo : 0);
      bal = max(0.0, bal - (payment - i));
      newN = m;
    }

    final saved = max(0.0, intStd - intNew);
    final mthSaved = n - newN;
    final yrsSaved = mthSaved ~/ 12;
    final moSaved = mthSaved % 12;

    final labelCtrl = TextEditingController(text: 'Extra Repay Plan');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/au_extra_repayments/save'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Scenario', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving: \$${CurrencyFormatter.compact(saved, symbol: 'AU\$')} saved · $yrsSaved yrs $moSaved mo cut',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. \$500 extra/fortnight)',
                hintStyle: AppTextStyles.dmSans(size: 13, color: Colors.grey),
                filled: true,
                fillColor: widget.theme.getBgColor(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTextStyles.dmSans(size: 12, color: Colors.grey, weight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF002868),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save', style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'Extra Plan';
      final calc = SavedCalc.create(
        country: 'Australia',
        calcType: 'Extra Repayments',
        inputs: {
          'loanBalance': snapLoanBalance,
          'interestRate': snapInterestRate,
          'loanTerm': snapLoanTerm.toDouble(),
          'extraAmount': snapExtraAmount,
          'frequency': snapFreqExtra == 'weekly'
              ? 0.0
              : snapFreqExtra == 'fortnightly'
                  ? 1.0
                  : snapFreqExtra == 'monthly'
                      ? 2.0
                      : 3.0,
          'lumpSum': snapLumpSum,
        },
        results: {
          'interestSaved': saved,
          'yrsSaved': yrsSaved.toDouble(),
          'moSaved': moSaved.toDouble(),
          'newTermMonths': newN.toDouble(),
        },
        label: label,
        currencyCode: 'AUD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Calculation saved!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF002868),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double snapLoanBalance = _showResults ? (_calcSnapshot['loanBalance'] ?? _loanBalance) : _loanBalance;
    final double snapInterestRate = _showResults ? (_calcSnapshot['interestRate'] ?? _interestRate) : _interestRate;
    final int snapLoanTerm = _showResults ? (_calcSnapshot['loanTerm'] ?? _loanTerm) : _loanTerm;
    final double snapExtraAmount = _showResults ? (_calcSnapshot['extraAmount'] ?? _extraAmount) : _extraAmount;
    final String snapFreqExtra = _showResults ? (_calcSnapshot['freqExtra'] ?? _freqExtra) : _freqExtra;
    final int snapStartFrom = _showResults ? (_calcSnapshot['startFrom'] ?? _startFrom) : _startFrom;
    final double snapLumpSum = _showResults ? (_calcSnapshot['lumpSum'] ?? _lumpSum) : _lumpSum;

    final r = snapInterestRate / 100 / 12;
    final n = snapLoanTerm * 12;
    final stdPmt = _monthlyPmt(snapLoanBalance, snapInterestRate, snapLoanTerm);
    final extraMo = _extraPerMonth(snapExtraAmount, snapFreqExtra);

    // Standard simulation
    double balStd = snapLoanBalance;
    double intStd = 0;
    final List<_YearData> stdYearly = [];
    for (int m = 1; m <= n; m++) {
      final i = balStd * r;
      intStd += i;
      balStd = max(0.0, balStd - (stdPmt - i));
      if (m % 12 == 0) {
        stdYearly.add(_YearData(yr: m ~/ 12, bal: balStd, intPaid: intStd));
      }
    }

    // New simulation with extra payments
    double balNew = snapLoanBalance - snapLumpSum;
    double intNew = 0;
    int newN = 0;
    final List<_YearData> newYearly = [];
    double bal = max(0.0, balNew);
    for (int m = 1; m <= n + 120; m++) {
      if (bal <= 0) break;
      final i = bal * r;
      intNew += i;
      final payment = stdPmt + (m > snapStartFrom ? extraMo : 0);
      bal = max(0.0, bal - (payment - i));
      newN = m;
      if (m % 12 == 0) {
        newYearly.add(_YearData(yr: m ~/ 12, bal: bal, intPaid: intNew));
      }
    }

    final saved = max(0.0, intStd - intNew);
    final mthSaved = n - newN;
    final yrsSaved = max(0, mthSaved ~/ 12);
    final moSaved = max(0, mthSaved % 12);

    final today = DateTime.now();
    final payoffOrig = DateTime(today.year, today.month + n);
    final payoffNew = DateTime(today.year, today.month + newN);
    const monthsNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String payoffFmt(DateTime d) => '${monthsNames[d.month - 1]} ${d.year}';

    final origTermLabel = '$snapLoanTerm years';
    final newTermLabel = (() {
      final y = newN ~/ 12;
      final m = newN % 12;
      return m > 0 ? '$y yr $m mo' : '$y years';
    })();
    final newPct = n > 0 ? (newN / n) : 1.0;

    // Amortization preview list
    final List<_AmortRowData> amortRows = [];
    final yearsToShow = min(10, min(yearlyCount(n), yearlyCount(newN)));
    for (int yr = 0; yr < yearsToShow; yr++) {
      final std = yr < stdYearly.length
          ? stdYearly[yr]
          : _YearData(yr: yr + 1, bal: 0, intPaid: intStd);
      final nw = yr < newYearly.length
          ? newYearly[yr]
          : _YearData(yr: yr + 1, bal: 0, intPaid: intNew);
      final stdPrev = yr > 0 ? stdYearly[yr - 1].intPaid : 0.0;
      final nwPrev = yr > 0 && yr - 1 < newYearly.length ? newYearly[yr - 1].intPaid : 0.0;
      final intThisYrStd = std.intPaid - stdPrev;
      final intThisYrNew = nw.intPaid - nwPrev;
      final ySaving = max(0.0, intThisYrStd - intThisYrNew);

      final pctP = (1 - std.bal / snapLoanBalance).clamp(0.0, 1.0);
      final pctI = (intThisYrStd / (stdPmt * 12)).clamp(0.0, 1.0);
      final pctS = intThisYrStd > 0 ? (ySaving / intThisYrStd).clamp(0.0, 1.0) : 0.0;

      amortRows.add(_AmortRowData(
        year: yr + 1,
        balance: std.bal,
        interestSaved: ySaving,
        pctP: pctP,
        pctI: pctI,
        pctS: pctS,
      ));
    }

    final isDirty = _showResults && (
      _loanBalance != (_calcSnapshot['loanBalance'] ?? 0.0) ||
      _interestRate != (_calcSnapshot['interestRate'] ?? 0.0) ||
      _loanTerm != (_calcSnapshot['loanTerm'] ?? 0) ||
      _repaymentType != (_calcSnapshot['repaymentType'] ?? '') ||
      _extraAmount != (_calcSnapshot['extraAmount'] ?? 0.0) ||
      _freqExtra != (_calcSnapshot['freqExtra'] ?? '') ||
      _startFrom != (_calcSnapshot['startFrom'] ?? 0) ||
      _lumpSum != (_calcSnapshot['lumpSum'] ?? 0.0)
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? theme.getCardColor(context) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? theme.getBorderColor(context) : theme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Current Mortgage Details',
                      style: AppTextStyles.dmSans(
                          size: 11,
                          color: theme.primaryColor,
                          weight: FontWeight.w700,
                          letterSpacing: 0.5)),
                  GestureDetector(
                    onTap: _reset,
                    child: Text('Reset ↺',
                        style: AppTextStyles.dmSans(
                            size: 11,
                            color: theme.primaryColor,
                            weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _buildInputBox('Loan Balance', 'AUD \$', _loanBalance,
                          errorText: _errors['loanBalance'],
                          onChanged: (v) => setState(() => _loanBalance = v))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _buildInputBox('Interest Rate', '% p.a.', _interestRate,
                          isPercent: true,
                          errorText: _errors['interestRate'],
                          onChanged: (v) => setState(() => _interestRate = v))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _buildInputBox('Remaining Term', 'yrs', _loanTerm.toDouble(),
                          isInteger: true,
                          errorText: _errors['loanTerm'],
                          onChanged: (v) => setState(() => _loanTerm = v.toInt()))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('REPAYMENT TYPE',
                            style: AppTextStyles.dmSans(
                                size: 9,
                                color: theme.mutedColor,
                                weight: FontWeight.w800)),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFFFF8F0),
                              border: Border.all(color: isDark ? theme.getBorderColor(context) : theme.borderColor),
                              borderRadius: BorderRadius.circular(10)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _repaymentType,
                              isExpanded: true,
                              dropdownColor: theme.getCardColor(context),
                              style: AppTextStyles.dmSans(
                                  size: 14,
                                  color: theme.getTextColor(context),
                                  weight: FontWeight.bold),
                              items: const [
                                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                                DropdownMenuItem(value: 'fortnightly', child: Text('Fortnightly')),
                                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _repaymentType = v);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Extra Repayment Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? theme.getCardColor(context) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? theme.getBorderColor(context) : theme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Additional Payment',
                  style: AppTextStyles.dmSans(
                      size: 11,
                      color: theme.primaryColor,
                      weight: FontWeight.w700,
                      letterSpacing: 0.5)),
              const SizedBox(height: 12),
              _buildInputBox('Extra Amount Per Period', 'AUD \$', _extraAmount,
                  errorText: _errors['extraAmount'],
                  onChanged: (v) => setState(() => _extraAmount = v)),
              const SizedBox(height: 10),
              Text('PAYMENT FREQUENCY',
                  style: AppTextStyles.dmSans(
                      size: 9,
                      color: theme.mutedColor,
                      weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: _buildFreqBtn('Weekly', _freqExtra == 'weekly', () => setState(() => _freqExtra = 'weekly'))),
                  const SizedBox(width: 4),
                  Expanded(child: _buildFreqBtn('Fortnightly', _freqExtra == 'fortnightly', () => setState(() => _freqExtra = 'fortnightly'))),
                  const SizedBox(width: 4),
                  Expanded(child: _buildFreqBtn('Monthly', _freqExtra == 'monthly', () => setState(() => _freqExtra = 'monthly'))),
                  const SizedBox(width: 4),
                  Expanded(child: _buildFreqBtn('Yearly', _freqExtra == 'yearly', () => setState(() => _freqExtra = 'yearly'))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('START FROM',
                            style: AppTextStyles.dmSans(
                                size: 9,
                                color: theme.mutedColor,
                                weight: FontWeight.w800)),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFFFF8F0),
                              border: Border.all(color: isDark ? theme.getBorderColor(context) : theme.borderColor),
                              borderRadius: BorderRadius.circular(10)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _startFrom,
                              isExpanded: true,
                              dropdownColor: theme.getCardColor(context),
                              style: AppTextStyles.dmSans(
                                  size: 14,
                                  color: theme.getTextColor(context),
                                  weight: FontWeight.bold),
                              items: const [
                                DropdownMenuItem(value: 0, child: Text('Now')),
                                DropdownMenuItem(value: 12, child: Text('Year 1')),
                                DropdownMenuItem(value: 24, child: Text('Year 2')),
                                DropdownMenuItem(value: 36, child: Text('Year 3')),
                                DropdownMenuItem(value: 60, child: Text('Year 5')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _startFrom = v);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _buildInputBox('Lump Sum (One-off)', 'AUD \$', _lumpSum,
                          errorText: _errors['lumpSum'],
                          onChanged: (v) => setState(() => _lumpSum = v))),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text('📈 Calculate Savings',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        color: Colors.white,
                        weight: FontWeight.w800)),
              ),
            ],
          ),
        ),

        // Results Section
        if (_showResults) ...[
          if (isDirty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Text('⚠️ ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(
                      'Inputs have changed. Tap Calculate Savings to refresh results.',
                      style: AppTextStyles.dmSans(size: 11, color: Colors.amber[800], weight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Container(
            key: _resultsKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Savings Summary Hero
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Your Savings Summary', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
                    GestureDetector(
                      onTap: _saveCalculation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                          border: Border.all(color: theme.getBorderColor(context)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('💾 Save',
                            style: AppTextStyles.dmSans(
                                size: 11,
                                color: isDark ? const Color(0xFFFFD700) : theme.primaryColor,
                                weight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A0A00), Color(0xFF7C2D12)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Interest Saved',
                          style: AppTextStyles.dmSans(
                              size: 10,
                              color: Colors.white60,
                              weight: FontWeight.w700,
                              letterSpacing: 0.8)),
                      const SizedBox(height: 4),
                      Text(CurrencyFormatter.format(saved, currencyCode: 'AUD'),
                          style: AppTextStyles.playfair(
                              size: 38,
                              color: const Color(0xFFFFD700),
                              weight: FontWeight.w800)),
                      Text('by making extra repayments', style: AppTextStyles.dmSans(size: 12, color: Colors.white70)),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        children: [
                          _buildHeroBox('Time Saved', '$yrsSaved yrs $moSaved mo', color: const Color(0xFFFFD700)),
                          _buildHeroBox('New Payoff Date', payoffFmt(payoffNew), color: const Color(0xFFBBF7D0)),
                          _buildHeroBox('Old Repayment', '${CurrencyFormatter.format(stdPmt, currencyCode: 'AUD')}/mo'),
                          _buildHeroBox('New Total/Period', '${CurrencyFormatter.format(stdPmt + extraMo, currencyCode: 'AUD')}/mo', color: const Color(0xFFFFD700)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Loan Term Comparison Card
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? theme.getCardColor(context) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isDark ? theme.getBorderColor(context) : theme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('⏱ Loan Term Comparison',
                          style: AppTextStyles.dmSans(
                              size: 13,
                              weight: FontWeight.w800,
                              color: theme.getTextColor(context))),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildLegendItem(const Color(0xFF7C2D12), 'Original Term'),
                          const SizedBox(width: 16),
                          _buildLegendItem(const Color(0xFF16A34A), 'With Extra Repayments'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Original Term bar
                      _buildTermBar('Original Term', 1.0, const Color(0xFF7C2D12)),
                      Text('0 to $origTermLabel', style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context))),
                      const SizedBox(height: 10),

                      // New Term bar
                      _buildTermBar('New Term', newPct, const Color(0xFF16A34A)),
                      Text('0 to $newTermLabel', style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context))),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildTimelineStat('Original Term', '$snapLoanTerm yrs')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildTimelineStat('New Term', newTermLabel, isGreen: true)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildTimelineStat('Extra/Month', '${CurrencyFormatter.format(extraMo, currencyCode: 'AUD')}/mo', isGreen: true)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Cumulative Interest Chart Card
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? theme.getCardColor(context) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isDark ? theme.getBorderColor(context) : theme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📊 Cumulative Interest Over Time',
                          style: AppTextStyles.dmSans(
                              size: 13,
                              weight: FontWeight.w800,
                              color: theme.getTextColor(context))),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildLegendItem(const Color(0xFFEF4444), 'Without Extra'),
                          const SizedBox(width: 14),
                          _buildLegendItem(const Color(0xFF16A34A), 'With Extra'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 150,
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: _CumulativeInterestPainter(
                            stdYearly: stdYearly,
                            newYearly: newYearly,
                            maxYrs: snapLoanTerm,
                            maxV: intStd,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Key Milestones Card
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF002868),
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🎯 Key Milestones', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 12),
                      _buildMilestoneRow('🏁', 'Loan paid off', 'Original: ${payoffFmt(payoffOrig)}', payoffFmt(payoffNew)),
                      _buildMilestoneRow('💰', 'Total interest without extra', 'Standard repayments only', CurrencyFormatter.format(intStd, currencyCode: 'AUD')),
                      _buildMilestoneRow('✅', 'Total interest with extra', 'Reduced by extra repayments', CurrencyFormatter.format(intNew, currencyCode: 'AUD')),
                      _buildMilestoneRow('🎉', 'Total interest saved', 'Money back in your pocket', CurrencyFormatter.format(saved, currencyCode: 'AUD')),
                      _buildMilestoneRow('📅', 'Years cut from loan', 'Time freed up earlier', '$yrsSaved yrs $moSaved mo'),
                    ],
                  ),
                ),

                // Year-by-year Amortization preview
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? theme.getCardColor(context) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isDark ? theme.getBorderColor(context) : theme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📋 Year-by-Year Balance Preview',
                          style: AppTextStyles.dmSans(
                              size: 13,
                              weight: FontWeight.w800,
                              color: theme.getTextColor(context))),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildLegendItem(const Color(0xFF002868), 'Principal (Standard)'),
                          const SizedBox(width: 14),
                          _buildLegendItem(const Color(0xFFFCA5A5), 'Interest (Standard)'),
                          const SizedBox(width: 14),
                          _buildLegendItem(const Color(0xFFBBF7D0), 'Interest Saving'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...amortRows.map((ar) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                  width: 36,
                                  child: Text('Yr ${ar.year}',
                                      style: AppTextStyles.dmSans(
                                          size: 11,
                                          weight: FontWeight.bold,
                                          color: const Color(0xFF92400E)))),
                              Expanded(
                                child: Column(
                                  children: [
                                    Container(
                                      height: 5,
                                      alignment: Alignment.centerLeft,
                                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(3)),
                                      child: FractionallySizedBox(
                                        widthFactor: ar.pctP,
                                        child: Container(decoration: BoxDecoration(color: const Color(0xFF002868), borderRadius: BorderRadius.circular(3))),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      height: 5,
                                      alignment: Alignment.centerLeft,
                                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(3)),
                                      child: FractionallySizedBox(
                                        widthFactor: ar.pctI,
                                        child: Container(decoration: BoxDecoration(color: const Color(0xFFFCA5A5), borderRadius: BorderRadius.circular(3))),
                                      ),
                                    ),
                                    if (ar.interestSaved > 0) ...[
                                      const SizedBox(height: 2),
                                      Container(
                                        height: 5,
                                        alignment: Alignment.centerLeft,
                                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(3)),
                                        child: FractionallySizedBox(
                                          widthFactor: ar.pctS,
                                          child: Container(decoration: BoxDecoration(color: const Color(0xFFBBF7D0), borderRadius: BorderRadius.circular(3))),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${CurrencyFormatter.format(ar.balance, currencyCode: 'AUD')} bal',
                                      style: AppTextStyles.dmSans(size: 10, weight: FontWeight.bold, color: theme.getTextColor(context))),
                                  if (ar.interestSaved > 0)
                                    Text('-${CurrencyFormatter.format(ar.interestSaved, currencyCode: 'AUD')} int',
                                        style: const TextStyle(fontSize: 9, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  int yearlyCount(int n) => (n / 12).ceil();

  Widget _buildInputBox(String label, String prefix, double value,
      {bool isPercent = false,
      bool isInteger = false,
      String? errorText,
      required ValueChanged<double> onChanged}) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: AppTextStyles.dmSans(
                size: 9, color: theme.mutedColor, weight: FontWeight.w800)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFFFF8F0),
            border: Border.all(color: errorText != null ? Colors.red : theme.borderColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              if (!isPercent)
                Text('$prefix ',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        color: theme.getMutedColor(context),
                        weight: FontWeight.bold)),
              Expanded(
                child: TextFormField(
                  key: ValueKey(value),
                  initialValue: isInteger ? value.toInt().toString() : value.toString(),
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.dmSans(
                      size: 14,
                      color: theme.getTextColor(context),
                      weight: FontWeight.bold),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
                  onChanged: (v) {
                    final d = double.tryParse(v) ?? 0.0;
                    onChanged(d);
                  },
                ),
              ),
              if (isPercent)
                Text('%',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        color: theme.getMutedColor(context),
                        weight: FontWeight.bold)),
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(errorText, style: AppTextStyles.dmSans(size: 10, color: Colors.red, weight: FontWeight.w500)),
        ],
      ],
    );
  }

  Widget _buildFreqBtn(String text, bool active, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF7C2D12) : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFFFF8F0)),
          border: Border.all(color: active ? const Color(0xFF7C2D12) : (isDark ? widget.theme.getBorderColor(context) : const Color(0x3B7C2D12))),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.w700,
            color: active ? Colors.white : const Color(0xFF92400E),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBox(String label, String val, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.white54)),
          const SizedBox(height: 2),
          Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color ?? Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color col, String text) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(fontSize: 10, color: widget.theme.getTextColor(context))),
      ],
    );
  }

  Widget _buildTermBar(String label, double barPct, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 12,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFFFF0E4),
          borderRadius: BorderRadius.circular(6)),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: barPct.clamp(0.0, 1.0),
        child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6))),
      ),
    );
  }

  Widget _buildTimelineStat(String label, String value, {bool isGreen = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
      decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFFFF8F0),
          border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.1)) : null,
          borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 9, color: isDark ? Colors.white70 : const Color(0xFF92400E))),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isGreen ? const Color(0xFF16A34A) : (isDark ? Colors.white : Colors.black),
                  fontFamily: 'Georgia')),
        ],
      ),
    );
  }

  Widget _buildMilestoneRow(String emoji, String title, String sub, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(sub, style: const TextStyle(fontSize: 9, color: Colors.white38)),
              ],
            ),
          ),
          Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
        ],
      ),
    );
  }
}

class _YearData {
  final int yr;
  final double bal;
  final double intPaid;

  _YearData({required this.yr, required this.bal, required this.intPaid});
}

class _AmortRowData {
  final int year;
  final double balance;
  final double interestSaved;
  final double pctP;
  final double pctI;
  final double pctS;

  _AmortRowData({
    required this.year,
    required this.balance,
    required this.interestSaved,
    required this.pctP,
    required this.pctI,
    required this.pctS,
  });
}

class _CumulativeInterestPainter extends CustomPainter {
  final List<_YearData> stdYearly;
  final List<_YearData> newYearly;
  final int maxYrs;
  final double maxV;

  _CumulativeInterestPainter({required this.stdYearly, required this.newYearly, required this.maxYrs, required this.maxV});

  @override
  void paint(Canvas canvas, Size size) {
    if (stdYearly.isEmpty) return;

    final paintStd = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final paintNew = Paint()
      ..color = const Color(0xFF16A34A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final pathStd = Path();
    final pathNew = Path();

    final dx = size.width / maxYrs;

    for (int i = 0; i < stdYearly.length; i++) {
      final x = stdYearly[i].yr * dx;
      final yStd = size.height - (stdYearly[i].intPaid / maxV * size.height);

      if (i == 0) {
        pathStd.moveTo(0, size.height);
        pathStd.lineTo(x, yStd);
      } else {
        pathStd.lineTo(x, yStd);
      }
    }

    for (int i = 0; i < newYearly.length; i++) {
      final x = newYearly[i].yr * dx;
      final yNew = size.height - (newYearly[i].intPaid / maxV * size.height);

      if (i == 0) {
        pathNew.moveTo(0, size.height);
        pathNew.lineTo(x, yNew);
      } else {
        pathNew.lineTo(x, yNew);
      }
    }

    canvas.drawPath(pathStd, paintStd);
    canvas.drawPath(pathNew, paintNew);
  }

  @override
  bool shouldRepaint(covariant _CumulativeInterestPainter oldDelegate) => true;
}
