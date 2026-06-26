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

  @override
  void dispose() {
    _loanController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _saveCalculation() async {
    final double loan = double.tryParse(_loanController.text) ?? 585000;
    final double rate = double.tryParse(_rateController.text) ?? 4.99;
    final int ppY = _paymentFreq == 'monthly' ? 12 : (_paymentFreq == 'biweekly' ? 26 : 52);
    final double ea = dm.pow(1 + rate / 200, 2) - 1;
    final double r = ea / ppY;
    final int n = _amortYears * ppY;
    final double pmt = loan * r / (1 - dm.pow(1 + r, -n));
    final double totalPaid = pmt * n;
    final double totalInt = totalPaid - loan;

    final labelCtrl = TextEditingController(text: 'Amortization Plan');
    final confirmed = await showDialog<bool>(
      context: context,
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
          'Amort': _amortYears.toDouble(),
        },
        results: {
          'Payment': pmt,
          'TotalInterest': totalInt,
          'TotalPaid': totalPaid,
          'Freq': _paymentFreq == 'monthly' ? 1.0 : (_paymentFreq == 'biweekly' ? 2.0 : 3.0),
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

    final double loan = double.tryParse(_loanController.text) ?? 585000;
    final double rate = double.tryParse(_rateController.text) ?? 4.99;

    final double ea = dm.pow(1 + rate / 200, 2) - 1;
    final int ppY = _paymentFreq == 'monthly' ? 12 : (_paymentFreq == 'biweekly' ? 26 : 52);
    final double perPeriod = ea / ppY;
    final int periods = _amortYears * ppY;
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

    final freqLabel = _paymentFreq == 'monthly'
        ? 'Monthly Payment'
        : (_paymentFreq == 'biweekly' ? 'Bi-Weekly Payment' : 'Weekly Payment');
    final freqSub = _paymentFreq == 'monthly'
        ? 'Every month · $periods payments total'
        : (_paymentFreq == 'biweekly' ? 'Every 2 weeks · $periods payments total' : 'Every week · $periods payments total');

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
    final int chartYrs = dm.min(_amortYears, 10);
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
    final int startIdx = (_selectedYear - 1) * ppY;
    final int endIdx = dm.min(_selectedYear * ppY, schedule.length);
    final List<Map<String, double>> yearPayments = [];
    // If weekly or bi-weekly, let's step to keep lists reasonable
    final step = _paymentFreq == 'monthly' ? 1 : (_paymentFreq == 'biweekly' ? 2 : 4);
    for (int i = startIdx; i < endIdx; i += step) {
      if (i < schedule.length) {
        yearPayments.add(schedule[i]);
      }
    }

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
        Text(
          'MORTGAGE DETAILS',
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.6,
          ),
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
              _buildInputField('Mortgage Amount', _loanController, prefix: 'CA\$'),
              const SizedBox(height: 12),
              _buildInputField('Annual Interest Rate', _rateController, suffix: '%'),
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
                      onPressed: () => setState(() {}),
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
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

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
                'Annual Payment Breakdown',
                style: AppTextStyles.playfair(size: 13, weight: FontWeight.bold, color: theme.getTextColor(context)),
              ),
              Text(
                'First 10 years shown',
                style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)),
              ),
              const SizedBox(height: 20),
              // Custom double stacked bars
              SizedBox(
                height: 110,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: yearData.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final data = entry.value;

                    final double priH = (data['principal']! / maxYearTotal) * 85;
                    final double intH = (data['interest']! / maxYearTotal) * 85;

                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: priH.clamp(2.0, 85.0),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A5C35),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  height: intH.clamp(2.0, 85.0),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFC8102E),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Yr${idx + 1}',
                            style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: theme.getMutedColor(context)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _chartLeg('Principal', const Color(0xFF1A5C35)),
                  const SizedBox(width: 14),
                  _chartLeg('Interest', const Color(0xFFC8102E)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Milestones
        Text(
          'KEY MILESTONES',
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
                'Your Mortgage Journey',
                style: AppTextStyles.playfair(size: 13, weight: FontWeight.bold, color: theme.getTextColor(context)),
              ),
              const SizedBox(height: 12),
              _msRow('⚖️', 'Equity Crossover', 'When principal paid > interest paid', crossoverYr, const Color(0xFFFEF3C7)),
              const Divider(height: 18, thickness: 0.5),
              _msRow('🎯', '25% Equity', 'Balance = 75% of original loan', eq25, const Color(0xFFDCF4E8)),
              const Divider(height: 18, thickness: 0.5),
              _msRow('🏆', '50% Equity', 'Balance = 50% of original loan', eq50, const Color(0xFFDCF4E8)),
              const Divider(height: 18, thickness: 0.5),
              _msRow('🎉', 'Mortgage Free', 'Full payoff date', 'Yr $_amortYears', const Color(0xFFD1FAE5)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Annual Summary List
        Text(
          'ANNUAL SUMMARY',
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        // Year tabs horizontal scrolling list
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _amortYears,
            itemBuilder: (context, idx) {
              final y = idx + 1;
              final active = _selectedYear == y;
              return GestureDetector(
                onTap: () => setState(() => _selectedYear = y),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? theme.primaryColor : theme.getCardColor(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: active ? theme.primaryColor : theme.getBorderColor(context)),
                  ),
                  child: Text(
                    'Year $y',
                    style: AppTextStyles.dmSans(
                      size: 11,
                      weight: FontWeight.bold,
                      color: active ? Colors.white : theme.getMutedColor(context),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // Detailed Payments Table Card
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                color: theme.getBgColor(context),
                child: Row(
                  children: [
                    Expanded(flex: 15, child: Text('Period', style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: theme.getMutedColor(context)))),
                    Expanded(flex: 10, child: Text('Payment', style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: theme.getMutedColor(context)))),
                    Expanded(flex: 10, child: Text('Interest', style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: theme.getMutedColor(context)))),
                    Expanded(flex: 10, child: Text('Balance', style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: theme.getMutedColor(context)))),
                  ],
                ),
              ),
              ...yearPayments.map((item) {
                final int pIdx = item['period']!.round();
                final pLabel = _paymentFreq == 'monthly' ? 'Mo $pIdx' : 'Pmt $pIdx';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: theme.getBorderColor(context), width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 15, child: Text(pLabel, style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context)))),
                      Expanded(flex: 10, child: Text(CurrencyFormatter.format(item['payment']!, symbol: '\$'), style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: theme.getTextColor(context)))),
                      Expanded(flex: 10, child: Text(CurrencyFormatter.format(item['interest']!, symbol: '\$'), style: AppTextStyles.dmSans(size: 11, color: const Color(0xFFC8102E)))),
                      Expanded(flex: 10, child: Text(CurrencyFormatter.format(item['balance']!, symbol: '\$'), style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: const Color(0xFF1A5C35)))),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),

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
              final freqStr = c.results['Freq'] == 1.0
                  ? 'Monthly'
                  : (c.results['Freq'] == 2.0 ? 'Bi-Weekly' : 'Weekly');
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
                            'CA\$${(c.inputs['Loan'] ?? 0).toStringAsFixed(0)} · ${c.inputs['Rate']}% · ${c.inputs['Amort']?.round()}yr',
                            style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: theme.getTextColor(context)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Saved ${c.savedAt.day}/${c.savedAt.month}/${c.savedAt.year} · $freqStr',
                            style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context)),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${CurrencyFormatter.format(c.results['Payment'] ?? 0, symbol: 'CA\$')}/pmt',
                          style: AppTextStyles.playfair(size: 13, weight: FontWeight.bold, color: theme.primaryColor),
                        ),
                        Text(
                          '${CurrencyFormatter.format(c.results['TotalInterest'] ?? 0, symbol: 'CA\$')} int',
                          style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFC8102E), weight: FontWeight.bold),
                        ),
                      ],
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

  Widget _buildInputField(String label, TextEditingController controller, {String? prefix, String? suffix}) {
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
            border: Border.all(color: theme.getBorderColor(context), width: 1.5),
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
