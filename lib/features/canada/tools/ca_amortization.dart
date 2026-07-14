// lib/features/canada/tools/ca_amortization.dart

import 'dart:math' as dm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/canada_rates_provider.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class CAAmortization extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const CAAmortization({super.key, required this.theme});

  @override
  ConsumerState<CAAmortization> createState() => _CAAmortizationState();
}

class _CAAmortizationState extends ConsumerState<CAAmortization> {
  final _loanController = TextEditingController(text: '585000');
  final _rateController = TextEditingController(text: '4.99');

  int _amortYears = 25;
  String _paymentFreq = 'biweekly'; // monthly | biweekly | weekly
  int _selectedYear = 1;

  final _resultsKey = GlobalKey();
  bool _showResults = false;
  final Map<dynamic, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};

  @override
  void dispose() {
    _loanController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  double _val(TextEditingController c) {
    if (_showResults && _calcSnapshot.containsKey(c)) {
      return _calcSnapshot[c]!;
    }
    double defaultVal = 0.0;
    if (c == _loanController) {
      defaultVal = 585000.0;
    } else if (c == _rateController) {
      defaultVal = 4.99;
    }
    return double.tryParse(c.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? defaultVal;
  }

  void _calculate() {
    final errors = <String, String>{};
    final loan = double.tryParse(_loanController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (loan <= 0) errors['loan'] = 'Enter a valid loan amount';
    
    final rate = double.tryParse(_rateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (rate <= 0 || rate > 25) errors['rate'] = 'Enter interest rate (0.1% - 25%)';

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) return;

    setState(() {
      _calcSnapshot[_loanController] = loan;
      _calcSnapshot[_rateController] = rate;
      _calcSnapshot['_amortYears'] = _amortYears;
      _calcSnapshot['_paymentFreq'] = _paymentFreq;
      _showResults = true;
      _selectedYear = 1;
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

  void _resetInputs() {
    setState(() {
      _loanController.text = '585000';
      _rateController.text = '4.99';
      _amortYears = 25;
      _paymentFreq = 'biweekly';
      _selectedYear = 1;
      _calcSnapshot.clear();
      _errors.clear();
      _showResults = false;
    });
  }

  void _saveCalculation() async {
    final double loan = _val(_loanController);
    final double rate = _val(_rateController);
    final int amortYears = _showResults ? (_calcSnapshot['_amortYears'] ?? _amortYears) : _amortYears;
    final String paymentFreq = _showResults ? (_calcSnapshot['_paymentFreq'] ?? _paymentFreq) : _paymentFreq;

    final int ppY = paymentFreq == 'monthly' ? 12 : (paymentFreq == 'biweekly' ? 26 : 52);
    final double ea = dm.pow(1 + rate / 200, 2) - 1;
    final double r = ea / ppY;
    final int n = amortYears * ppY;
    final double pmt = loan * r / (1 - dm.pow(1 + r, -n));
    final double totalPaid = pmt * n;
    final double totalInt = totalPaid - loan;

    final labelCtrl = TextEditingController(text: 'Amortization Plan');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/ca_amortization/save'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Calculation',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: Total Interest ${CurrencyFormatter.compact(totalInt, symbol: 'CA\$')} · Loan: ${CurrencyFormatter.compact(loan, symbol: 'CA\$')}',
              style: AppTextStyles.dmSans(
                  size: 11, color: widget.theme.getMutedColor(context)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. 25-yr Schedule)',
                hintStyle: AppTextStyles.dmSans(size: 13, color: Colors.grey),
                filled: true,
                fillColor: widget.theme.getBgColor(context),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: AppTextStyles.dmSans(
                    size: 12, color: Colors.grey, weight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.theme.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save',
                style: AppTextStyles.dmSans(
                    size: 12, color: Colors.white, weight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final label = labelCtrl.text.trim().isNotEmpty
          ? labelCtrl.text.trim()
          : 'Amortization';
      final calc = SavedCalc.create(
        country: 'Canada',
        calcType: 'Amortization Schedule',
        inputs: {
          'Loan': loan,
          'Rate': rate,
          'Amort': amortYears.toDouble(),
        },
        results: {
          'Payment': pmt,
          'TotalInterest': totalInt,
          'TotalPaid': totalPaid,
          'Freq': paymentFreq == 'monthly' ? 1.0 : (paymentFreq == 'biweekly' ? 2.0 : 3.0),
        },
        label: label,
        currencyCode: 'CAD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Schedule saved successfully!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: widget.theme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  bool _rateInitialized = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    // Watch rates provider to initialize default interest rate
    final ratesAsync = ref.watch(canadaCalculatedRatesProvider);
    if (ratesAsync.hasValue && !_rateInitialized) {
      final defaultRate = ratesAsync.value!.rate5yrFixed;
      _rateController.text = defaultRate.toStringAsFixed(2);
      _rateInitialized = true;
    }

    final double loan = _val(_loanController);
    final double rate = _val(_rateController);
    final int amortYears = _showResults ? (_calcSnapshot['_amortYears'] ?? _amortYears) : _amortYears;
    final String paymentFreq = _showResults ? (_calcSnapshot['_paymentFreq'] ?? _paymentFreq) : _paymentFreq;

    final double ea = dm.pow(1 + rate / 200, 2) - 1;
    final int ppY = paymentFreq == 'monthly' ? 12 : (paymentFreq == 'biweekly' ? 26 : 52);
    final double perPeriod = ea / ppY;
    final int periods = amortYears * ppY;
    final double pmt = loan * perPeriod / (1 - dm.pow(1 + perPeriod, -periods));

    // Generate schedule
    final List<Map<String, double>> schedule = [];
    double balance = loan;
    for (int i = 1; i <= periods; i++) {
      final intCharge = balance * perPeriod;
      final prin = dm.min(pmt - intCharge, balance);
      balance = dm.max(0, balance - prin);
      schedule.add({
        'period': i.toDouble(),
        'payment': pmt,
        'interest': intCharge,
        'principal': prin,
        'balance': balance,
      });
    }

    final double totalPaid = pmt * periods;
    final double totalInt = totalPaid - loan;
    final double intPctVal = totalPaid > 0 ? (totalInt / totalPaid * 100) : 0;

    final freqLabel = paymentFreq == 'monthly'
        ? 'Monthly Payment'
        : (paymentFreq == 'biweekly' ? 'Bi-Weekly Payment' : 'Weekly Payment');
    final freqSub = paymentFreq == 'monthly'
        ? 'Every month · $periods payments total'
        : (paymentFreq == 'biweekly' ? 'Every 2 weeks · $periods payments total' : 'Every week · $periods payments total');

    // Milestones
    String crossoverYr = '—';
    String eq25 = '—';
    String eq50 = '—';
    double cumulativeInt = 0;
    double cumulativePrin = 0;
    for (int i = 0; i < schedule.length; i++) {
      cumulativeInt += schedule[i]['interest']!;
      cumulativePrin += schedule[i]['principal']!;
      final yr = ((i + 1) / ppY).ceil();
      if (crossoverYr == '—' && cumulativePrin >= cumulativeInt) {
        crossoverYr = 'Yr $yr';
      }
      if (eq25 == '—' && schedule[i]['balance']! <= loan * 0.75) {
        eq25 = 'Yr $yr';
      }
      if (eq50 == '—' && schedule[i]['balance']! <= loan * 0.50) {
        eq50 = 'Yr $yr';
      }
    }

    // Chart Data (first 10 years)
    final int chartYrs = dm.min(amortYears, 10);
    final List<Map<String, double>> yearData = [];
    double maxYearTotal = 1.0;
    for (int y = 1; y <= chartYrs; y++) {
      final s = (y - 1) * ppY;
      final e = dm.min(y * ppY, schedule.length);
      double yi = 0;
      double yp = 0;
      for (int i = s; i < e; i++) {
        yi += schedule[i]['interest']!;
        yp += schedule[i]['principal']!;
      }
      final total = yi + yp;
      if (total > maxYearTotal) maxYearTotal = total;
      yearData.add({'interest': yi, 'principal': yp, 'total': total});
    }

    // Render table data for selected year
    final int clampedSelectedYear = _selectedYear.clamp(1, amortYears);
    final int startIdx = (clampedSelectedYear - 1) * ppY;
    final int endIdx = dm.min(clampedSelectedYear * ppY, schedule.length);
    final List<Map<String, double>> yearPayments = [];
    // If weekly or bi-weekly, let's step to keep lists reasonable
    final step = paymentFreq == 'monthly' ? 1 : (paymentFreq == 'biweekly' ? 2 : 4);
    for (int i = startIdx; i < endIdx; i += step) {
      if (i < schedule.length) {
        yearPayments.add(schedule[i]);
      }
    }

    final isDirty = _showResults && (
      (double.tryParse(_loanController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_loanController] ?? 0.0) ||
      (double.tryParse(_rateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_rateController] ?? 0.0) ||
      _amortYears != (_calcSnapshot['_amortYears'] ?? _amortYears) ||
      _paymentFreq != (_calcSnapshot['_paymentFreq'] ?? _paymentFreq)
    );

    final saved = ref.watch(savedProvider);
    final localSaved = saved
        .where((c) =>
            c.country.toLowerCase() == 'canada' &&
            c.calcType.toLowerCase() == 'amortization schedule')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input Section Label
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MORTGAGE DETAILS',
              style: AppTextStyles.dmSans(
                size: 10,
                weight: FontWeight.bold,
                color: theme.getMutedColor(context),
                letterSpacing: 0.6,
              ),
            ),
            GestureDetector(
              onTap: _resetInputs,
              child: Text(
                'Reset',
                style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Input card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [
              _buildInputField('Mortgage Amount', _loanController, prefix: 'CA\$', errorText: _errors['loan']),
              const SizedBox(height: 12),
              _buildInputField('Annual Interest Rate', _rateController, suffix: '%', errorText: _errors['rate']),
              const SizedBox(height: 16),

              // Amortization Toggle
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'AMORTIZATION',
                  style: AppTextStyles.dmSans(
                    size: 9,
                    weight: FontWeight.bold,
                    color: theme.getMutedColor(context),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [15, 20, 25, 30].map((y) {
                  final active = _amortYears == y;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _amortYears = y;
                        if (_selectedYear > y) _selectedYear = y;
                      }),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: active ? theme.primaryColor : theme.getBgColor(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: active ? theme.primaryColor : theme.getBorderColor(context),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$y yr',
                          style: AppTextStyles.dmSans(
                            size: 11,
                            weight: FontWeight.bold,
                            color: active ? Colors.white : theme.getTextColor(context),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Frequency Toggle
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'PAYMENT FREQUENCY',
                  style: AppTextStyles.dmSans(
                    size: 9,
                    weight: FontWeight.bold,
                    color: theme.getMutedColor(context),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _freqBtn('Monthly', 'monthly', theme),
                  _freqBtn('Bi-Weekly', 'biweekly', theme),
                  _freqBtn('Weekly', 'weekly', theme),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _calculate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC8102E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        '📅 Generate Schedule',
                        style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (_showResults) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _saveCalculation,
                      child: Container(
                        width: 50,
                        height: 46,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text('💾', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_showResults) ...[
          if (isDirty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                      'Inputs have changed. Tap Calculate to refresh results.',
                      style: AppTextStyles.dmSans(size: 11, color: Colors.amber[800], weight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            key: _resultsKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Result Card Summary
                Text(
                  'PAYMENT SUMMARY',
                  style: AppTextStyles.dmSans(
                    size: 10,
                    weight: FontWeight.bold,
                    color: theme.getMutedColor(context),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A2E1A), Color(0xFF1A5C35)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        freqLabel.toUpperCase(),
                        style: AppTextStyles.dmSans(
                          size: 9,
                          color: Colors.white60,
                          weight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'CA\$',
                            style: AppTextStyles.dmSans(
                              size: 18,
                              weight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.compact(pmt, symbol: ''),
                            style: AppTextStyles.playfair(
                              size: 32,
                              weight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        freqSub,
                        style: AppTextStyles.dmSans(
                          size: 10.5,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _summaryBox('Total Paid', CurrencyFormatter.format(totalPaid, symbol: 'CA\$'))),
                          const SizedBox(width: 8),
                          Expanded(child: _summaryBox('Total Interest', CurrencyFormatter.format(totalInt, symbol: 'CA\$'), isRed: true)),
                          const SizedBox(width: 8),
                          Expanded(child: _summaryBox('Interest %', '${intPctVal.toStringAsFixed(1)}%', isRed: true)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Visual Breakdown Chart
                Text(
                  'PRINCIPAL VS. INTEREST OVER TIME',
                  style: AppTextStyles.dmSans(
                    size: 10,
                    weight: FontWeight.bold,
                    color: theme.getMutedColor(context),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.getCardColor(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.getBorderColor(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Interest / Principal Breakdown (First 10 Years)',
                        style: AppTextStyles.playfair(size: 12.5, weight: FontWeight.bold, color: theme.getTextColor(context)),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 160,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: yearData.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final val = entry.value;
                            final y = idx + 1;
                            final double tot = val['total']!;
                            final double pPct = tot > 0 ? (val['principal']! / tot) : 0;
                            final double iPct = tot > 0 ? (val['interest']! / tot) : 0;

                            return Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final double maxH = constraints.maxHeight;
                                        final double barH = (tot / maxYearTotal) * maxH;
                                        final double priH = barH * pPct;
                                        final double intH = barH * iPct;

                                        return Stack(
                                          alignment: Alignment.bottomCenter,
                                          children: [
                                            Container(
                                              width: 14,
                                              height: barH.clamp(2.0, double.infinity),
                                              decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(3)),
                                            ),
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                Container(
                                                  width: 14,
                                                  height: intH.clamp(0.0, double.infinity),
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFFC8102E),
                                                    borderRadius: BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3)),
                                                  ),
                                                ),
                                                Container(
                                                  width: 14,
                                                  height: priH.clamp(0.0, double.infinity),
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFF1A5C35),
                                                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(3), bottomRight: Radius.circular(3)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Yr $y',
                                    style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context), weight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _chartLeg('Principal Paid', const Color(0xFF1A5C35)),
                          const SizedBox(width: 20),
                          _chartLeg('Interest Paid', const Color(0xFFC8102E)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Milestones & Insights
                Text(
                  'AMORTIZATION MILESTONES',
                  style: AppTextStyles.dmSans(
                    size: 10,
                    weight: FontWeight.bold,
                    color: theme.getMutedColor(context),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.getCardColor(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.getBorderColor(context)),
                  ),
                  child: Column(
                    children: [
                      _msRow('⚖️', 'Principal Crossover', 'When payment begins reducing balance faster than interest accumulates', crossoverYr, const Color(0xFFEFF6FF)),
                      const Divider(height: 24, thickness: 0.5),
                      _msRow('🔓', '25% Equity Cleared', 'When mortgage balance reaches 75% of original loan amount', eq25, const Color(0xFFF0FDF4)),
                      const Divider(height: 24, thickness: 0.5),
                      _msRow('🔑', '50% Equity Cleared', 'When mortgage balance reaches 50% of original loan amount', eq50, const Color(0xFFFFFBEB)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Annual Schedule Table Detail
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ANNUAL SCHEDULE DETAIL',
                      style: AppTextStyles.dmSans(
                        size: 10,
                        weight: FontWeight.bold,
                        color: theme.getMutedColor(context),
                        letterSpacing: 0.6,
                      ),
                    ),
                    DropdownButton<int>(
                      value: clampedSelectedYear,
                      dropdownColor: theme.getCardColor(context),
                      style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: theme.getTextColor(context)),
                      underline: Container(),
                      items: List.generate(amortYears, (i) => i + 1).map((y) {
                        return DropdownMenuItem<int>(
                          value: y,
                          child: Text('Year $y Schedule'),
                        );
                      }).toList(),
                      onChanged: (y) {
                        if (y != null) {
                          setState(() => _selectedYear = y);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: theme.getCardColor(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.getBorderColor(context)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        color: theme.getBgColor(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('Period', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.bold, color: theme.getMutedColor(context)))),
                            Expanded(child: Text('Payment', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.bold, color: theme.getMutedColor(context)), textAlign: TextAlign.right)),
                            Expanded(child: Text('Principal', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.bold, color: theme.getMutedColor(context)), textAlign: TextAlign.right)),
                            Expanded(child: Text('Interest', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.bold, color: theme.getMutedColor(context)), textAlign: TextAlign.right)),
                            Expanded(child: Text('Balance', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.bold, color: theme.getMutedColor(context)), textAlign: TextAlign.right)),
                          ],
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: yearPayments.length,
                        separatorBuilder: (context, i) => const Divider(height: 1, thickness: 0.5),
                        itemBuilder: (context, i) {
                          final p = yearPayments[i];
                          final label = paymentFreq == 'monthly'
                              ? 'Mo ${(p['period']! % 12 == 0 ? 12 : p['period']! % 12).toInt()}'
                              : (paymentFreq == 'biweekly' ? 'Bi-W ${p['period']!.toInt()}' : 'W ${p['period']!.toInt()}');

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(label, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: theme.getTextColor(context)))),
                                Expanded(child: Text(CurrencyFormatter.format(p['payment']!, symbol: ''), style: AppTextStyles.dmSans(size: 10.5, color: theme.getTextColor(context)), textAlign: TextAlign.right)),
                                Expanded(child: Text(CurrencyFormatter.format(p['principal']!, symbol: ''), style: AppTextStyles.dmSans(size: 10.5, color: const Color(0xFF1A5C35), weight: FontWeight.bold), textAlign: TextAlign.right)),
                                Expanded(child: Text(CurrencyFormatter.format(p['interest']!, symbol: ''), style: AppTextStyles.dmSans(size: 10.5, color: const Color(0xFFC8102E)), textAlign: TextAlign.right)),
                                Expanded(child: Text(CurrencyFormatter.format(p['balance']!, symbol: ''), style: AppTextStyles.dmSans(size: 10.5, color: theme.getTextColor(context), weight: FontWeight.w600), textAlign: TextAlign.right)),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Local saved calcs
        if (localSaved.isNotEmpty) ...[
          Text(
            'SAVED SCHEDULES',
            style: AppTextStyles.dmSans(
              size: 10,
              weight: FontWeight.bold,
              color: theme.getMutedColor(context),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: localSaved.length,
            itemBuilder: (context, idx) {
              final c = localSaved[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.getCardColor(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.getBorderColor(context)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Loan CA\$${((c.inputs['Loan'] ?? 0) / 1000).round()}K · ${c.inputs['Amort']!.toInt()} yr amort',
                            style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: theme.getTextColor(context)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Saved ${c.savedAt.day}/${c.savedAt.month}/${c.savedAt.year} · ${c.inputs['Rate']}% rate',
                            style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(c.results['Payment'] ?? 0, symbol: 'CA\$'),
                      style: AppTextStyles.playfair(size: 14, weight: FontWeight.bold, color: theme.primaryColor),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => ref.read(savedProvider.notifier).delete(c.id),
                      child: const Text('✕', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {String? prefix, String? suffix, String? errorText}) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 9,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: errorText != null ? Colors.red : theme.getBorderColor(context),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              if (prefix != null)
                Padding(
                  padding: const EdgeInsets.only(left: 11),
                  child: Text(prefix, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.bold, color: theme.primaryColor)),
                ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  onChanged: (val) => setState(() {}),
                  style: AppTextStyles.dmSans(
                    size: 16,
                    weight: FontWeight.bold,
                    color: theme.getTextColor(context),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 11, vertical: 12),
                    isDense: true,
                  ),
                ),
              ),
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.only(right: 11),
                  child: Text(suffix, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w600, color: theme.getMutedColor(context))),
                ),
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: AppTextStyles.dmSans(size: 10, color: Colors.red, weight: FontWeight.w500),
          ),
        ],
      ],
    );
  }

  Widget _freqBtn(String title, String key, CountryTheme theme) {
    final active = _paymentFreq == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentFreq = key),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? theme.primaryColor : theme.getBgColor(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? theme.primaryColor : theme.getBorderColor(context),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: AppTextStyles.dmSans(
              size: 11,
              weight: FontWeight.bold,
              color: active ? Colors.white : theme.getTextColor(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryBox(String label, String value, {bool isRed = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.dmSans(size: 8, color: Colors.white60, weight: FontWeight.bold, letterSpacing: 0.3),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.playfair(
              size: 12.5,
              weight: FontWeight.bold,
              color: isRed ? const Color(0xFFFF8A9A) : const Color(0xFF6EDFA0),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _chartLeg(String title, Color color) {
    final theme = widget.theme;
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text(title, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.bold, color: theme.getMutedColor(context))),
      ],
    );
  }

  Widget _msRow(String emoji, String title, String subtitle, String val, Color badgeBg) {
    final theme = widget.theme;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 16)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: theme.getTextColor(context))),
              Text(subtitle, style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context))),
            ],
          ),
        ),
        Text(
          val,
          style: AppTextStyles.playfair(size: 12, weight: FontWeight.bold, color: theme.primaryColor),
        ),
      ],
    );
  }
}
