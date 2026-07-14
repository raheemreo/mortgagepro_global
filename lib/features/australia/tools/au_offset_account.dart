// lib/features/australia/tools/au_offset_account.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class AUOffsetAccount extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const AUOffsetAccount({super.key, this.theme = CountryThemes.australia});

  @override
  ConsumerState<AUOffsetAccount> createState() => _AUOffsetAccountState();
}

class _AUOffsetAccountState extends ConsumerState<AUOffsetAccount> {
  double _loanBal = 675000;
  double _offsetBal = 50000;
  double _rate = 6.09;
  int _termYears = 28;
  double _monthlyContrib = 500;

  bool _showResults = false;
  final Map<String, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};
  final _resultsKey = GlobalKey();

  void _reset() {
    setState(() {
      _loanBal = 675000;
      _offsetBal = 50000;
      _rate = 6.09;
      _termYears = 28;
      _monthlyContrib = 500;
      _showResults = false;
      _calcSnapshot.clear();
      _errors.clear();
    });
  }

  double _calcMonthly(double loan, double r, int n) {
    if (r == 0) return loan / n;
    return loan * (r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
  }

  double _calcTotalInterest(double loan, double r, int n) {
    return _calcMonthly(loan, r, n) * n - loan;
  }

  int _calcPayoffMonths(double loan, double monthlyPayment, double r) {
    if (r == 0) return (loan / monthlyPayment).ceil();
    final val = 1.0 - (loan * r) / monthlyPayment;
    if (val <= 0) return 360; // fallback if payment won't cover interest
    return (-log(val) / log(1 + r)).ceil();
  }

  void _calculate() {
    final errors = <String, String>{};

    if (_loanBal <= 0) {
      errors['loanBal'] = 'Enter valid loan balance';
    }
    if (_offsetBal < 0) {
      errors['offsetBal'] = 'Offset balance cannot be negative';
    }
    if (_rate <= 0 || _rate > 25) {
      errors['rate'] = 'Enter rate (0.1% - 25%)';
    }
    if (_termYears <= 0 || _termYears > 50) {
      errors['termYears'] = 'Enter term (1-50)';
    }
    if (_monthlyContrib < 0) {
      errors['monthlyContrib'] = 'Contribution cannot be negative';
    }

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) return;

    setState(() {
      _calcSnapshot['loanBal'] = _loanBal;
      _calcSnapshot['offsetBal'] = _offsetBal;
      _calcSnapshot['rate'] = _rate;
      _calcSnapshot['termYears'] = _termYears;
      _calcSnapshot['monthlyContrib'] = _monthlyContrib;
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
    final double snapLoanBal = _calcSnapshot['loanBal'] ?? _loanBal;
    final double snapOffsetBal = _calcSnapshot['offsetBal'] ?? _offsetBal;
    final double snapRate = _calcSnapshot['rate'] ?? _rate;
    final int snapTermYears = _calcSnapshot['termYears'] ?? _termYears;
    final double snapMonthlyContrib = _calcSnapshot['monthlyContrib'] ?? _monthlyContrib;

    final r = snapRate / 100 / 12;
    final n = snapTermYears * 12;
    final effectiveLoan = max(0.0, snapLoanBal - snapOffsetBal);

    final monthlyNo = _calcMonthly(snapLoanBal, r, n);
    final monthlyYes = _calcMonthly(effectiveLoan, r, n) + snapMonthlyContrib;
    final intNo = _calcTotalInterest(snapLoanBal, r, n);
    final intYes = _calcTotalInterest(effectiveLoan, r, n);
    final totalSaved = max(0.0, intNo - intYes);
    final effRate = effectiveLoan > 0 ? (snapRate * effectiveLoan / snapLoanBal) : 0.0;

    final monthsNew = _calcPayoffMonths(effectiveLoan, monthlyNo, r);
    final yearsSaved = max(0.0, (n - monthsNew) / 12);

    final labelCtrl = TextEditingController(text: 'Offset Savings Plan');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/au_offset_account'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Offset Calculation',
            style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving: \$${CurrencyFormatter.compact(totalSaved, symbol: 'AU\$')} saved off mortgage',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Main PPOR Offset)',
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
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'Offset Plan';
      final calc = SavedCalc.create(
        country: 'Australia',
        calcType: 'Offset Account',
        inputs: {
          'loanBal': snapLoanBal,
          'offsetBal': snapOffsetBal,
          'rate': snapRate,
          'termYears': snapTermYears.toDouble(),
          'monthlyContrib': snapMonthlyContrib,
        },
        results: {
          'totalSaved': totalSaved,
          'monthlySave': max(0.0, monthlyNo - monthlyYes + snapMonthlyContrib),
          'yearsSaved': yearsSaved,
          'effRate': effRate,
          'intNo': intNo,
          'intYes': intYes,
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

    final double snapLoanBal = _showResults ? (_calcSnapshot['loanBal'] ?? _loanBal) : _loanBal;
    final double snapOffsetBal = _showResults ? (_calcSnapshot['offsetBal'] ?? _offsetBal) : _offsetBal;
    final double snapRate = _showResults ? (_calcSnapshot['rate'] ?? _rate) : _rate;
    final int snapTermYears = _showResults ? (_calcSnapshot['termYears'] ?? _termYears) : _termYears;
    final double snapMonthlyContrib = _showResults ? (_calcSnapshot['monthlyContrib'] ?? _monthlyContrib) : _monthlyContrib;

    // Calculations
    final r = snapRate / 100 / 12;
    final n = snapTermYears * 12;
    final effectiveLoan = max(0.0, snapLoanBal - snapOffsetBal);

    final monthlyNo = _calcMonthly(snapLoanBal, r, n);
    final monthlyYes = _calcMonthly(effectiveLoan, r, n) + snapMonthlyContrib;
    final intNo = _calcTotalInterest(snapLoanBal, r, n);
    final intYes = _calcTotalInterest(effectiveLoan, r, n);
    final totalNo = snapLoanBal + intNo;
    final totalYes = effectiveLoan + intYes;
    final monthlySave = max(0.0, monthlyNo - monthlyYes + snapMonthlyContrib);
    final totalSaved = max(0.0, intNo - intYes);
    final effRate = effectiveLoan > 0 ? (snapRate * effectiveLoan / snapLoanBal) : 0.0;

    final monthsNew = _calcPayoffMonths(effectiveLoan, monthlyNo, r);
    final yearsSaved = max(0.0, (n - monthsNew) / 12);

    // Chart trajectory data points (24 steps)
    final List<double> dataNo = [];
    final List<double> dataYes = [];
    final List<String> labels = [];

    double balNo = snapLoanBal;
    double balYes = effectiveLoan;
    final step = max(1, n ~/ 24);

    for (int m = 0; m <= n; m += step) {
      labels.add('Yr ${(m / 12).round()}');
      dataNo.add(balNo);
      dataYes.add(balYes);

      for (int i = 0; i < step; i++) {
        final iNo = balNo * r;
        final pNo = monthlyNo - iNo;
        balNo = max(0.0, balNo - pNo);

        final iYes = balYes * r;
        final pYes = monthlyNo - iYes; // using base repayment to see payoff speedup
        balYes = max(0.0, balYes - pYes);
      }
    }

    final isDirty = _showResults && (
      _loanBal != (_calcSnapshot['loanBal'] ?? 0.0) ||
      _offsetBal != (_calcSnapshot['offsetBal'] ?? 0.0) ||
      _rate != (_calcSnapshot['rate'] ?? 0.0) ||
      _termYears != (_calcSnapshot['termYears'] ?? 0) ||
      _monthlyContrib != (_calcSnapshot['monthlyContrib'] ?? 0.0)
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F766E), Color(0xFF115E59)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Offset Account Interest Savings Calculator',
                      style: AppTextStyles.dmSans(size: 9, color: Colors.white60, weight: FontWeight.w600)),
                  GestureDetector(
                    onTap: _reset,
                    child: Text('Reset ↺',
                        style: AppTextStyles.dmSans(size: 11, color: const Color(0xFFFFD700), weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('See how much offset saves you',
                  style: AppTextStyles.playfair(size: 18, color: Colors.white, weight: FontWeight.w800)),
              const SizedBox(height: 16),

              // Inputs Grid
              Row(
                children: [
                  Expanded(
                    child: _buildInputBox(
                      label: 'Loan Balance',
                      prefix: 'AUD \$',
                      value: _loanBal,
                      errorText: _errors['loanBal'],
                      onChanged: (val) => setState(() => _loanBal = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputBox(
                      label: 'Offset Balance',
                      prefix: 'AUD \$',
                      value: _offsetBal,
                      errorText: _errors['offsetBal'],
                      onChanged: (val) => setState(() => _offsetBal = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildInputBox(
                      label: 'Interest Rate %',
                      prefix: '',
                      value: _rate,
                      errorText: _errors['rate'],
                      onChanged: (val) => setState(() => _rate = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputBox(
                      label: 'Remaining Term (yrs)',
                      prefix: '',
                      value: _termYears.toDouble(),
                      isInteger: true,
                      errorText: _errors['termYears'],
                      onChanged: (val) => setState(() => _termYears = val.toInt()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              _buildInputBox(
                label: 'Monthly Offset Contribution (optional)',
                prefix: 'AUD \$',
                value: _monthlyContrib,
                errorText: _errors['monthlyContrib'],
                onChanged: (val) => setState(() => _monthlyContrib = val),
              ),
              const SizedBox(height: 14),

              // Calculate Button
              ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF002868),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 44),
                  elevation: 4,
                ),
                child: Text('🏦 Calculate Offset Savings',
                    style: AppTextStyles.dmSans(size: 14, color: Colors.white, weight: FontWeight.w800)),
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
                      'Inputs have changed. Tap Calculate Offset Savings to refresh results.',
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

                // Savings Hero Card
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Savings', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
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
                      colors: [Color(0xFF064E3B), Color(0xFF065F46)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Text('Total interest saved with offset',
                          style: AppTextStyles.dmSans(size: 11, color: Colors.white70, weight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(CurrencyFormatter.format(totalSaved, currencyCode: 'AUD'),
                          style: AppTextStyles.playfair(size: 40, color: const Color(0xFF6EE7B7), weight: FontWeight.w800)),
                      Text('over your remaining loan term', style: AppTextStyles.dmSans(size: 12, color: Colors.white70)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                              child: _buildHeroStatBox(
                                  'Monthly Saving',
                                  CurrencyFormatter.format(
                                      monthlySave > 0 ? monthlySave : (totalSaved / n),
                                      currencyCode: 'AUD'))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildHeroStatBox('Years Saved', yearsSaved > 0 ? '${yearsSaved.toStringAsFixed(1)} yrs' : '< 1 yr')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildHeroStatBox('Effective Rate', '${effRate.toStringAsFixed(2)}%')),
                        ],
                      ),
                    ],
                  ),
                ),

                // Side-by-Side Comparison
                const SizedBox(height: 20),
                Text('Without vs With Offset', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.getCardColor(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.getBorderColor(context)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF064E3B) : const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            Expanded(child: Text('Metric', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w800, color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF115E59)))),
                            Expanded(child: Text('Without Offset', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w800, color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF115E59)), textAlign: TextAlign.right)),
                            Expanded(child: Text('With Offset ✅', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w800, color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF115E59)), textAlign: TextAlign.right)),
                          ],
                        ),
                      ),
                      _buildCompRow('Monthly Repay', '${CurrencyFormatter.format(monthlyNo, currencyCode: 'AUD')}/mo',
                          '${CurrencyFormatter.format(_calcMonthly(effectiveLoan, r, n), currencyCode: 'AUD')}/mo',
                          isGreenHighlight: true),
                      _buildCompRow('Total Interest', CurrencyFormatter.format(intNo, currencyCode: 'AUD'), CurrencyFormatter.format(intYes, currencyCode: 'AUD'), isGreenHighlight: true),
                      _buildCompRow('Total Repaid', CurrencyFormatter.format(totalNo, currencyCode: 'AUD'), CurrencyFormatter.format(totalYes, currencyCode: 'AUD'), isGreenHighlight: true),
                      _buildCompRow('Effective Balance', CurrencyFormatter.format(snapLoanBal, currencyCode: 'AUD'), CurrencyFormatter.format(effectiveLoan, currencyCode: 'AUD'), isGreenHighlight: true),
                    ],
                  ),
                ),

                // Chart Card
                const SizedBox(height: 20),
                Text('Balance Over Time', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.getCardColor(context),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: theme.getBorderColor(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Loan Balance Trajectory', style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context))),
                      Text('With vs without offset account over time', style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context))),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 160,
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: LineChartPainter(
                            dataNo: dataNo,
                            dataYes: dataYes,
                            colorNo: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                            colorYes: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildLegendItem(isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626), 'Without Offset'),
                          const SizedBox(width: 16),
                          _buildLegendItem(isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E), 'With Offset'),
                        ],
                      ),
                    ],
                  ),
                ),

                // Time Saved Banner
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF064E3B).withValues(alpha: 0.3), const Color(0xFF064E3B).withValues(alpha: 0.15)]
                          : const [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                    ),
                    border: Border.all(color: isDark ? const Color(0xFF059669) : const Color(0xFF6EE7B7)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Text('⏰', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              yearsSaved > 0 ? 'Save ${yearsSaved.toStringAsFixed(1)} years off your loan!' : 'Great start — keep growing your offset!',
                              style: AppTextStyles.playfair(size: 15, color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF064E3B), weight: FontWeight.w800),
                            ),
                            Text(
                              'By maintaining \$${CurrencyFormatter.compact(snapOffsetBal)} in offset + \$${CurrencyFormatter.compact(snapMonthlyContrib)}/mo contributions',
                              style: AppTextStyles.dmSans(size: 11, color: isDark ? const Color(0xFFD1FAE5) : const Color(0xFF065F46)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Guide Cards
        const SizedBox(height: 20),
        Text('Offset Tips', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.2) : const Color(0xFFF0FDF4),
            border: Border.all(color: isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC)),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🏦 Offset Account Guide (Australia)',
                  style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF064E3B))),
              const SizedBox(height: 12),
              _buildTipRow('1', 'Every dollar in your offset reduces the loan balance used to calculate interest — effectively earning your mortgage rate tax-free.'),
              _buildTipRow('2', 'In 2026, best HISA rates sit around 5.00%. Your mortgage at 6.09% means offset beats savings by ~1.09% (pre-tax equivalent: ~1.56% for a 30% taxpayer).'),
              _buildTipRow('3', 'Park your salary in the offset before paying bills — even a few days\' difference saves measurable interest over time.'),
              _buildTipRow('4', '100% offset accounts (most common in Australia) give full dollar-for-dollar reduction. Partial offset accounts only reduce a portion — read the fine print.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputBox({
    required String label,
    required String prefix,
    required double value,
    bool isInteger = false,
    String? errorText,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: errorText != null ? Colors.red : Colors.white.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54, weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (prefix.isNotEmpty)
                Text('$prefix ', style: AppTextStyles.dmSans(size: 11, color: Colors.white54, weight: FontWeight.w700)),
              Expanded(
                child: TextFormField(
                  key: ValueKey(value),
                  initialValue: isInteger ? value.toInt().toString() : value.toString(),
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.playfair(size: 15, color: Colors.white, weight: FontWeight.w800),
                  decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none),
                  onChanged: (val) {
                    final d = double.tryParse(val) ?? 0.0;
                    onChanged(d);
                  },
                ),
              ),
            ],
          ),
          if (errorText != null) ...[
            const SizedBox(height: 2),
            Text(errorText, style: AppTextStyles.dmSans(size: 9, color: Colors.red[300], weight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroStatBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 9, color: Colors.white70)),
          const SizedBox(height: 3),
          Text(value, style: AppTextStyles.playfair(size: 14, weight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildCompRow(String metric, String noVal, String yesVal, {required bool isGreenHighlight}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF1F5F9)))),
      child: Row(
        children: [
          Expanded(child: Text(metric, style: AppTextStyles.dmSans(size: 12, color: widget.theme.getTextColor(context), weight: FontWeight.w600))),
          Expanded(child: Text(noVal, style: AppTextStyles.dmSans(size: 12, color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626), weight: FontWeight.w700), textAlign: TextAlign.right)),
          Expanded(child: Text(yesVal, style: AppTextStyles.dmSans(size: 12, color: isGreenHighlight ? (isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A)) : widget.theme.getTextColor(context), weight: FontWeight.w800), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color col, String text) {
    return Row(
      children: [
        Container(width: 12, height: 3, decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(text, style: AppTextStyles.dmSans(size: 10, color: widget.theme.getTextColor(context))),
      ],
    );
  }

  Widget _buildTipRow(String bullet, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(color: Color(0xFF0F766E), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(bullet, style: AppTextStyles.dmSans(size: 9, color: Colors.white, weight: FontWeight.w900)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppTextStyles.dmSans(size: 11, color: const Color(0xFF065F46), height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> dataNo;
  final List<double> dataYes;
  final Color colorNo;
  final Color colorYes;

  LineChartPainter({
    required this.dataNo,
    required this.dataYes,
    required this.colorNo,
    required this.colorYes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataNo.isEmpty || dataYes.isEmpty) return;

    final paintNo = Paint()
      ..color = colorNo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final paintYes = Paint()
      ..color = colorYes
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final maxVal = max(dataNo.reduce(max), dataYes.reduce(max));
    if (maxVal == 0) return;

    final pathNo = Path();
    final pathYes = Path();

    final dx = size.width / (dataNo.length - 1);

    for (int i = 0; i < dataNo.length; i++) {
      final x = i * dx;
      final yNo = size.height - (dataNo[i] / maxVal * size.height);
      final yYes = size.height - (dataYes[i] / maxVal * size.height);

      if (i == 0) {
        pathNo.moveTo(x, yNo);
        pathYes.moveTo(x, yYes);
      } else {
        pathNo.lineTo(x, yNo);
        pathYes.lineTo(x, yYes);
      }
    }

    canvas.drawPath(pathNo, paintNo);
    canvas.drawPath(pathYes, paintYes);
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) => true;
}
