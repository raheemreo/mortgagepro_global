// lib/features/newzealand/tools/nz_moneyhub_mortgage.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZMoneyHubMortgage extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZMoneyHubMortgage({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZMoneyHubMortgage> createState() => _NZMoneyHubMortgageState();
}

class _NZMoneyHubMortgageState extends ConsumerState<NZMoneyHubMortgage> {
  final _propValController = TextEditingController(text: '850000');
  final _depositController = TextEditingController(text: '170000');

  double _intRate = 6.59;
  int _loanTerm = 30;

  @override
  void dispose() {
    _propValController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  void _saveCalculation() async {
    final propVal = double.tryParse(_propValController.text) ?? 850000;
    final deposit = double.tryParse(_depositController.text) ?? 170000;
    final loanAmount = math.max(propVal - deposit, 0.0);

    final double rate = _intRate / 100;
    final int n = _loanTerm * 12;
    final double r = rate / 12;

    final double monthly = r == 0
        ? (n == 0 ? 0.0 : loanAmount / n)
        : loanAmount * (r * math.pow(1 + r, n)) / (math.pow(1 + r, n) - 1);

    final double totalPaid = monthly * n;
    final double totalInt = totalPaid - loanAmount;
    final double lvr = propVal > 0 ? (loanAmount / propVal) * 100 : 0.0;

    final labelCtrl = TextEditingController(text: 'MoneyHub NZ Calculation');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Mortgage Calculation',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving MoneyHub Repayment Calc:\nLoan: ${CurrencyFormatter.compact(loanAmount, symbol: "NZ\$")} · Rate: $_intRate%\nTerm: $_loanTerm Years · Payment: ${CurrencyFormatter.compact(monthly, symbol: "NZ\$")}/mo',
              style: AppTextStyles.dmSans(
                  size: 11.5, color: widget.theme.getMutedColor(context)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. 850k Auckland Home)',
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
                    size: 12,
                    weight: FontWeight.bold,
                    color: widget.theme.getMutedColor(context))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.theme.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Save',
                style: AppTextStyles.dmSans(
                    size: 12, weight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && labelCtrl.text.isNotEmpty && mounted) {
      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'MoneyHub NZ Calculation',
        inputs: {
          'propertyValue': propVal,
          'deposit': deposit,
          'interestRate': _intRate,
          'loanTerm': _loanTerm.toDouble(),
        },
        results: {
          'monthlyPayment': monthly,
          'totalInterest': totalInt,
          'totalRepaid': totalPaid,
          'lvr': lvr,
          'loanAmount': loanAmount,
        },
        label: labelCtrl.text.trim(),
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ MoneyHub calculation saved!'),
            backgroundColor: widget.theme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _deleteSavedCalc(String id) async {
    await ref.read(savedProvider.notifier).delete(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🗑 Calculation removed'),
          backgroundColor: widget.theme.primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _clearAllSaved() async {
    // Confirm first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        title: Text('Clear Calculations', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Text('Are you sure you want to clear all saved calculations?', style: AppTextStyles.dmSans(size: 13, color: widget.theme.getMutedColor(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTextStyles.dmSans(size: 12, color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: widget.theme.primaryColor),
            child: Text('Clear All', style: AppTextStyles.dmSans(size: 12, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final saved = ref.read(savedProvider);
      final mhIds = saved
          .where((c) => c.calcType == 'MoneyHub NZ Calculation' && c.country == 'New Zealand')
          .map((c) => c.id)
          .toList();
      for (var id in mhIds) {
        await ref.read(savedProvider.notifier).delete(id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🗑 All MoneyHub calculations cleared'),
            backgroundColor: widget.theme.primaryColor,
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

    final cardBg = theme.getCardColor(context);
    final textCol = theme.getTextColor(context);
    final mutedCol = theme.getMutedColor(context);
    final borderCol = theme.getBorderColor(context);

    // Compute basic calculation
    final propVal = double.tryParse(_propValController.text) ?? 850000;
    final deposit = double.tryParse(_depositController.text) ?? 170000;
    final loanAmount = math.max(propVal - deposit, 0.0);

    final double rate = _intRate / 100;
    final int n = _loanTerm * 12;
    final double r = rate / 12;

    final double monthly = r == 0
        ? (n == 0 ? 0.0 : loanAmount / n)
        : loanAmount * (r * math.pow(1 + r, n)) / (math.pow(1 + r, n) - 1);

    final double totalPaid = monthly * n;
    final double totalInt = totalPaid - loanAmount;
    final double lvr = propVal > 0 ? (loanAmount / propVal) * 100 : 0.0;

    String lvrText = '';
    Color lvrColor = const Color(0xFFFCA5A5);
    if (lvr <= 65) {
      lvrText = '✓ Investor OK';
      lvrColor = const Color(0xFF6EE7B7);
    } else if (lvr <= 80) {
      lvrText = '✓ Owner-occ OK';
      lvrColor = const Color(0xFF6EE7B7);
    } else {
      lvrText = '⚠ LVR High';
      lvrColor = const Color(0xFFFCA5A5);
    }

    // Rate strip values
    final rateStripItems = [
      _buildStripItem('1-Yr Fixed', '6.59%', 'ANZ / ASB', const Color(0xFFFCA5A5)),
      _buildStripItem('2-Yr Fixed', '6.35%', 'Kiwibank', Colors.white),
      _buildStripItem('Floating', '8.64%', 'Variable', Colors.white),
      _buildStripItem('OCR', '3.75%', 'RBNZ', const Color(0xFFF5D060)),
    ];

    // Lender Rates comparison array
    final lenders = [
      {'name': 'Kiwibank', 'icon': '🥝', 'rate1': 6.55, 'rate2': 6.25, 'isBest': true},
      {'name': 'ANZ', 'icon': '🏦', 'rate1': 6.59, 'rate2': 6.35, 'isBest': false},
      {'name': 'ASB Bank', 'icon': '🏦', 'rate1': 6.59, 'rate2': 6.35, 'isBest': false},
      {'name': 'BNZ', 'icon': '🏦', 'rate1': 6.59, 'rate2': 6.35, 'isBest': false},
      {'name': 'Westpac', 'icon': '🏦', 'rate1': 6.65, 'rate2': 6.39, 'isBest': false},
      {'name': 'SBS / TSB', 'icon': '🏦', 'rate1': 6.55, 'rate2': 6.29, 'isBest': false},
    ];

    // Term bar chart lists
    const terms = ['6-Mo', '1-Yr', '2-Yr', '3-Yr', '5-Yr', 'Float'];
    const bestRates = [6.75, 6.55, 6.25, 6.19, 6.15, 8.64];
    const avgRates = [6.89, 6.59, 6.35, 6.29, 6.19, 8.64];
    const double minBarRate = 6.0;
    const double maxBarRate = 9.5;
    const double maxBarH = 80.0;

    // Amortization schedule calculation
    final List<Map<String, dynamic>> amortRows = [];
    double tempBal = loanAmount;
    final int showYears = math.min(5, _loanTerm);
    for (int y = 1; y <= showYears; y++) {
      double yearInterest = 0.0;
      double yearPrincipal = 0.0;
      for (int m = 0; m < 12; m++) {
        final double interest = tempBal * r;
        final double principalPaid = monthly - interest;
        yearInterest += interest;
        yearPrincipal += principalPaid;
        tempBal = math.max(tempBal - principalPaid, 0.0);
      }
      amortRows.add({
        'year': y,
        'monthly': monthly,
        'principal': yearPrincipal,
        'interest': yearInterest,
        'balance': tempBal,
      });
    }

    // Saved calcs list from Riverpod
    final savedList = ref.watch(savedProvider);
    final mhCalcs = savedList
        .where((c) => c.calcType == 'MoneyHub NZ Calculation' && c.country == 'New Zealand')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Row
        Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.15),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: rateStripItems,
          ),
        ),

        // Section Title
        Text('NZ Mortgage Calculator', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
        const SizedBox(height: 10),

        // Hero Mortgage Card
        Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A0F0D), Color(0xFF0D3B2E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MONEYHUB NZ · INDEPENDENT MORTGAGE GUIDE 2025',
                style: AppTextStyles.dmSans(size: 8.5, color: Colors.white60, weight: FontWeight.w700, letterSpacing: 0.8),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.playfair(size: 17, color: Colors.white, weight: FontWeight.w800),
                  children: const [
                    TextSpan(text: 'Calculate your '),
                    TextSpan(text: 'NZ Home Loan', style: TextStyle(color: Color(0xFFF5D060))),
                    TextSpan(text: '\n& compare all lenders'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Inputs Row 1
              Row(
                children: [
                  Expanded(
                    child: _buildInputBox(
                      label: 'Property Value (NZD)',
                      controller: _propValController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInputBox(
                      label: 'Deposit (NZD)',
                      controller: _depositController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Inputs Row 2
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownBox<double>(
                      label: 'Interest Rate',
                      value: _intRate,
                      items: const [
                        DropdownMenuItem(value: 6.19, child: Text('6.19% — 5-Yr Fixed')),
                        DropdownMenuItem(value: 6.29, child: Text('6.29% — 3-Yr Fixed')),
                        DropdownMenuItem(value: 6.35, child: Text('6.35% — 2-Yr Fixed')),
                        DropdownMenuItem(value: 6.59, child: Text('6.59% — 1-Yr Fixed')),
                        DropdownMenuItem(value: 8.64, child: Text('8.64% — Floating')),
                        DropdownMenuItem(value: 8.70, child: Text('8.70% — Revolving')),
                      ],
                      onChanged: (val) => setState(() => _intRate = val!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDropdownBox<int>(
                      label: 'Loan Term',
                      value: _loanTerm,
                      items: const [
                        DropdownMenuItem(value: 30, child: Text('30 years')),
                        DropdownMenuItem(value: 25, child: Text('25 years')),
                        DropdownMenuItem(value: 20, child: Text('20 years')),
                        DropdownMenuItem(value: 15, child: Text('15 years')),
                        DropdownMenuItem(value: 10, child: Text('10 years')),
                      ],
                      onChanged: (val) => setState(() => _loanTerm = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Results Row 1
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildResultItem('Monthly', CurrencyFormatter.compact(monthly, symbol: 'NZ\$')),
                    _buildResultItem('Total Interest', CurrencyFormatter.compact(totalInt, symbol: 'NZ\$')),
                    _buildResultItem('LVR', '${lvr.round()}%'),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Results Row 2
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildResultItem('Loan Amount', CurrencyFormatter.compact(loanAmount, symbol: 'NZ\$')),
                    _buildResultItem('Total Repaid', CurrencyFormatter.compact(totalPaid, symbol: 'NZ\$')),
                    _buildResultItem('LVR Status', lvrText, valColor: lvrColor),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              ElevatedButton(
                onPressed: () => setState(() {}),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text('🏠 Calculate My NZ Mortgage', style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800)),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _saveCalculation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4A017),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text('💾 Save This Calculation', style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Cost Breakdown Section
        Text('Loan Cost Breakdown', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Principal vs Interest Paid · Over $_loanTerm years', style: AppTextStyles.playfair(size: 12.5, weight: FontWeight.w800, color: textCol)),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: CustomPaint(
                      painter: _MHDonutPainter(
                        principal: loanAmount,
                        totalInterest: totalInt,
                        isDark: isDark,
                        theme: theme,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildLegendItem('Principal', CurrencyFormatter.compact(loanAmount, symbol: 'NZ\$'), theme.primaryColor),
                        _buildLegendItem('Total Interest', CurrencyFormatter.compact(totalInt, symbol: 'NZ\$'), const Color(0xFFC0392B)),
                        _buildLegendItem('Total Repaid', CurrencyFormatter.compact(totalPaid, symbol: 'NZ\$'), const Color(0xFFD4A017)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.getBgColor(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Interest ratio', style: AppTextStyles.dmSans(size: 9, color: mutedCol)),
                              Text(
                                totalPaid > 0 ? '${(totalInt / totalPaid * 100).round()}%' : '0%',
                                style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: const Color(0xFFC0392B)),
                              ),
                            ],
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
        const SizedBox(height: 20),

        // Rate Comparison Chart
        Text('NZ Rate Comparison', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fixed Rate Terms · All Major Lenders (June 2025)', style: AppTextStyles.playfair(size: 12.5, weight: FontWeight.w800, color: textCol)),
              const SizedBox(height: 16),

              // Bar Chart Layout
              SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(terms.length, (i) {
                    final term = terms[i];
                    final bRate = bestRates[i];
                    final aRate = avgRates[i];

                    // Scale heights
                    final bH = math.max(4.0, ((bRate - minBarRate) / (maxBarRate - minBarRate)) * maxBarH);
                    final aH = math.max(4.0, ((aRate - minBarRate) / (maxBarRate - minBarRate)) * maxBarH);

                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('$aRate%', style: AppTextStyles.dmSans(size: 8, weight: FontWeight.bold, color: theme.primaryColor)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                width: 12,
                                height: bH,
                                decoration: BoxDecoration(
                                  color: theme.primaryColor,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Container(
                                width: 12,
                                height: aH,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0D9488),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(term, style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                        ],
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildChartLegend('Best rate', theme.primaryColor),
                  const SizedBox(width: 14),
                  _buildChartLegend('Market avg', const Color(0xFF0D9488)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // OCR Rate History Chart
        Text('OCR Rate History', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RBNZ OCR vs 1-Year Fixed Rate · 2020–2025', style: AppTextStyles.playfair(size: 12.5, weight: FontWeight.w800, color: textCol)),
              const SizedBox(height: 14),
              AspectRatio(
                aspectRatio: 360 / 160,
                child: CustomPaint(
                  painter: _MHOcrHistoryChartPainter(isDark: isDark, theme: theme),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(width: 14, height: 3, decoration: BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 5),
                      Text('OCR Rate', style: AppTextStyles.dmSans(size: 9, color: mutedCol)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Container(width: 14, height: 3, decoration: BoxDecoration(color: const Color(0xFF0EA5E9), borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 5),
                      Text('1-Yr Fixed Rate', style: AppTextStyles.dmSans(size: 9, color: mutedCol)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // NZ Lender Rates Comparison Table
        Text('NZ Lender Rates Comparison', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Header Row
              Container(
                color: theme.getBgColor(context),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text('Lender', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: mutedCol))),
                    Expanded(flex: 2, child: Text('1-Yr', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: mutedCol), textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text('2-Yr', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: mutedCol), textAlign: TextAlign.center)),
                    Expanded(flex: 3, child: Text('Monthly*', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: mutedCol), textAlign: TextAlign.right)),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Lender Rows
              ...lenders.map((l) {
                final String name = l['name'] as String;
                final String icon = l['icon'] as String;
                final double rate1 = l['rate1'] as double;
                final double rate2 = l['rate2'] as double;
                final bool isBest = l['isBest'] as bool;

                // Compute dynamic repayment for this bank's 1-Yr Fixed rate
                final double bankRate = rate1 / 100 / 12;
                final double bankMo = loanAmount * (bankRate * math.pow(1 + bankRate, n)) / (math.pow(1 + bankRate, n) - 1);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isBest ? theme.primaryColor.withValues(alpha: 0.05) : Colors.transparent,
                    border: Border(bottom: BorderSide(color: borderCol, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      // Lender Name & Icon
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Text(icon, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textCol)),
                                  if (isBest)
                                    Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text('BEST RATE', style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w800, color: const Color(0xFF065F46))),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 1-Yr Rate
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${rate1.toStringAsFixed(2)}%',
                          style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.primaryColor),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // 2-Yr Rate
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${rate2.toStringAsFixed(2)}%',
                          style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: textCol),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Monthly
                      Expanded(
                        flex: 3,
                        child: Text(
                          CurrencyFormatter.compact(bankMo, symbol: 'NZ\$'),
                          style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textCol),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Table Note
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: theme.getBgColor(context),
                width: double.infinity,
                child: Text(
                  '*Repayments calculated dynamically based on your ${CurrencyFormatter.compact(loanAmount, symbol: "NZ\$")} loan and $_loanTerm-year P&I term.',
                  style: AppTextStyles.dmSans(size: 8.5, color: mutedCol, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Live Rate Scroll by Term
        Text('Rate Scroll by Term', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
        const SizedBox(height: 10),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildScrollCard('🏠', '6 Month', '6.89%', 'ANZ / BNZ', '↓ -0.06', isDown: true),
              _buildScrollCard('📅', '1-Yr Fixed', '6.59%', 'ANZ / ASB', '↓ -0.10', isDown: true),
              _buildScrollCard('📆', '2-Yr Fixed', '6.35%', 'Kiwibank', '↓ -0.05', isDown: true),
              _buildScrollCard('📊', '3-Yr Fixed', '6.29%', 'Westpac', '↓ -0.06', isDown: true),
              _buildScrollCard('📈', '5-Yr Fixed', '6.19%', 'BNZ / Avg', '↓ -0.04', isDown: true),
              _buildScrollCard('🔄', 'Floating', '8.64%', 'Variable', '→ 0.00', isDown: false),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Amortisation Preview Table
        Text('Amortisation Preview', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('First 5 Years · P&I Breakdown · $_intRate% · $_loanTerm yr', style: AppTextStyles.playfair(size: 12.5, weight: FontWeight.w800, color: textCol)),
              const SizedBox(height: 12),

              Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.2),
                  1: FlexColumnWidth(1.5),
                  2: FlexColumnWidth(1.5),
                  3: FlexColumnWidth(1.5),
                  4: FlexColumnWidth(1.5),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: theme.getBgColor(context)),
                    children: [
                      _buildAmortHeaderCell('Year'),
                      _buildAmortHeaderCell('Monthly'),
                      _buildAmortHeaderCell('Principal'),
                      _buildAmortHeaderCell('Interest'),
                      _buildAmortHeaderCell('Balance'),
                    ],
                  ),
                  ...amortRows.map((row) {
                    final int y = row['year'] as int;
                    final double moVal = row['monthly'] as double;
                    final double prinVal = row['principal'] as double;
                    final double intVal = row['interest'] as double;
                    final double balVal = row['balance'] as double;

                    return TableRow(
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: borderCol, width: 0.5)),
                      ),
                      children: [
                        _buildAmortCell('Year $y', alignLeft: true),
                        _buildAmortCell(CurrencyFormatter.compact(moVal, symbol: 'NZ\$')),
                        _buildAmortCell(CurrencyFormatter.compact(prinVal, symbol: 'NZ\$'), color: theme.primaryColor),
                        _buildAmortCell(CurrencyFormatter.compact(intVal, symbol: 'NZ\$'), color: const Color(0xFFC0392B)),
                        _buildAmortCell(CurrencyFormatter.compact(balVal, symbol: 'NZ\$')),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // DTI Warning Banner
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
            border: Border.all(color: const Color(0xFFF59E0B)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DTI Cap: 6× Your Gross Income', style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.bold, color: const Color(0xFF92400E))),
                    const SizedBox(height: 2),
                    Text('RBNZ debt-to-income limit effective 1 July 2024. On \$100K income, max loan = \$600K.', style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFB45309))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 6-Step Guide Cards
        Text('6-Step Mortgage Guide', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
        const SizedBox(height: 10),
        Column(
          children: [
            _buildGuideCard(1, 'Check Your Credit Score', 'Get your free credit report from Centrix or Equifax NZ. Most major banks require a score above 650. Check for errors — they\'re more common than you think.', 'Free via Centrix.co.nz', const Color(0xFF1A6B4A), const Color(0xFFECFDF5), const Color(0xFF065F46)),
            _buildGuideCard(2, 'Confirm Your Deposit & LVR', 'Owner-occupiers need min 20% deposit (80% LVR). Investors need 35% deposit. First-home buyers can use KiwiSaver first-home withdrawal + HomeStart Grant to boost deposit.', 'RBNZ LVR rules from 2024', const Color(0xFF0D9488), const Color(0xFFF0FDFA), const Color(0xFF0F766E)),
            _buildGuideCard(3, 'Get Pre-Approval (Conditional Approval)', 'Apply to 2–3 lenders or use a mortgage broker. Pre-approval typically valid for 90 days. Provide 3 months bank statements, 2 payslips, ID, and existing debt details.', 'Valid 90 days · Free to apply', const Color(0xFF0EA5E9), const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
            _buildGuideCard(4, 'Choose Fixed vs Floating', 'Fixed rates offer certainty and are currently lower than floating (6.59% vs 8.64%). Most NZ borrowers choose 1–2 year fixed, then refix. Split lending is popular: part fixed, part floating.', '1-yr fixed most popular 2025', const Color(0xFFD4A017), const Color(0xFFFFF7ED), const Color(0xFFC2410C)),
            _buildGuideCard(5, 'Understand All Costs', 'Budget for: legal fees (\$1,500–\$3,000), LIM report (\$300–\$500), building inspection (\$500–\$1,000), valuation (\$700–\$1,200), and bank establishment fees (\$0–\$500). Total: ~\$5,000–\$8,000.', 'Budget \$5K–\$8K in extras', const Color(0xFFC0392B), const Color(0xFFFEF2F2), const Color(0xFFC0392B)),
            _buildGuideCard(6, 'Settlement & Ongoing Management', 'Settlement day: your solicitor handles transfer. Set up automatic payments. Review your rate every time your fixed term expires — refixing at a better rate saves thousands.', 'Review rate at each term end', const Color(0xFF6D28D9), const Color(0xFFF5F3FF), const Color(0xFF6D28D9)),
          ],
        ),
        const SizedBox(height: 20),

        // MoneyHub Quick Tips Grid
        Text('MoneyHub Quick Tips', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 9,
          mainAxisSpacing: 9,
          childAspectRatio: 1.4,
          children: [
            _buildTipCard('💡', 'Use a Broker', 'NZ mortgage brokers are free to you — paid by banks. They access all lenders and can negotiate rates not offered directly.', isDk: true),
            _buildTipCard('📉', 'Rates Falling', 'RBNZ cutting OCR in 2025. Fixed rates expected to fall to ~5.5%–6% by end of 2025. Shorter terms may be smart now.', isFn: true),
            _buildTipCard('🔄', 'Refix Strategy', 'With rates expected to fall, consider 1-yr fixed and refix at lower rates. Break fees apply if you refix early on fixed term.', isTl: true),
            _buildTipCard('💰', 'Extra Repayments', 'Paying \$100/week extra on a \$680K loan at 6.59% saves ~\$147K interest and cuts 8 years off a 30yr term.', isGd: true),
            _buildTipCard('🛡️', 'Avoid LEM Fees', 'Low Equity Margin: banks add 0.25%–1.5% if deposit < 20%. Save above 20% to avoid ongoing fee cost.', isLight: true),
            _buildTipCard('🥝', 'KiwiSaver Boost', 'First-home buyers can withdraw KiwiSaver (after 3 yrs) + \$10K HomeStart grant for new builds to boost deposit.', isLight: true),
          ],
        ),
        const SizedBox(height: 20),

        // Saved Calculations Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Saved Calculations', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
            if (mhCalcs.isNotEmpty)
              GestureDetector(
                onTap: _clearAllSaved,
                child: Text('Clear All', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w600, color: const Color(0xFFC0392B))),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (mhCalcs.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            child: Text(
              'No saved calculations yet. Use the calculator above and tap 💾 Save.',
              style: AppTextStyles.dmSans(size: 11, color: mutedCol),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...mhCalcs.map((c) {
            final double val = c.inputs['propertyValue'] ?? 850000;
            final double dep = c.inputs['deposit'] ?? 170000;
            final double rt = c.inputs['interestRate'] ?? 6.59;
            final double trm = c.inputs['loanTerm'] ?? 30;
            final double moVal = c.results['monthlyPayment'] ?? 0;

            final savedDateStr = '${c.savedAt.day} ${_getMonthName(c.savedAt.month)} ${c.savedAt.year}';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderCol),
              ),
              child: Row(
                children: [
                  const Text('🏠', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${CurrencyFormatter.compact(val, symbol: "NZ\$")} · $rt%',
                          style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.bold, color: textCol),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${trm.round()}yr · Deposit ${CurrencyFormatter.compact(dep, symbol: "NZ\$")} · $savedDateStr',
                          style: AppTextStyles.dmSans(size: 9.5, color: mutedCol),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.compact(moVal, symbol: 'NZ\$'),
                        style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: theme.primaryColor),
                      ),
                      Text(
                        '/month',
                        style: AppTextStyles.dmSans(size: 8.5, color: mutedCol, weight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _deleteSavedCalc(c.id),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Text('✕', style: TextStyle(color: Color(0xFFC0392B), fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 20),

        // MoneyHub Resources Section
        Text('MoneyHub & NZ Resources', style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: textCol)),
        const SizedBox(height: 10),
        Column(
          children: [
            _buildLinkCard('🤝', 'MoneyHub NZ Mortgage Rates', 'Independent comparison of all NZ lender rates'),
            _buildLinkCard('📖', 'MoneyHub Mortgage Guide', 'Step-by-step NZ mortgage application guide'),
            _buildLinkCard('🏛️', 'RBNZ OCR Rate Decisions', 'Official Cash Rate history and future schedule'),
            _buildLinkCard('🧮', 'Sorted.org.nz Calculator', 'Government-backed NZ financial tools'),
            _buildLinkCard('🏦', 'ANZ NZ Home Loans', 'NZ\'s largest mortgage lender — apply online'),
          ],
        ),
      ],
    );
  }

  Widget _buildStripItem(String label, String value, String sub, Color valColor) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white70, weight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(value, style: AppTextStyles.dmSans(size: 14.5, weight: FontWeight.w800, color: valColor)),
        const SizedBox(height: 2),
        Text(sub, style: AppTextStyles.dmSans(size: 8, color: Colors.white54)),
      ],
    );
  }

  Widget _buildInputBox({required String label, required TextEditingController controller}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white60)),
          const SizedBox(height: 2),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: AppTextStyles.dmSans(size: 13, weight: FontWeight.bold, color: Colors.white),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownBox<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white60)),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              dropdownColor: const Color(0xFF141C33),
              style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.w800),
              icon: const SizedBox.shrink(),
              alignment: Alignment.centerLeft,
              isExpanded: true,
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value, {Color? valColor}) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white60, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: valColor ?? const Color(0xFFF5D060))),
      ],
    );
  }

  Widget _buildLegendItem(String label, String val, Color col) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: widget.theme.getTextColor(context))),
          const Spacer(),
          Text(val, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: widget.theme.getMutedColor(context))),
        ],
      ),
    );
  }

  Widget _buildChartLegend(String label, Color col) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.dmSans(size: 9, color: widget.theme.getMutedColor(context))),
      ],
    );
  }

  Widget _buildScrollCard(String emoji, String term, String rate, String bank, String change, {required bool isDown}) {
    final cardBg = widget.theme.getCardColor(context);
    final textCol = widget.theme.getTextColor(context);
    final mutedCol = widget.theme.getMutedColor(context);
    final borderCol = widget.theme.getBorderColor(context);

    return Container(
      width: 112,
      margin: const EdgeInsets.only(right: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(term.toUpperCase(), style: AppTextStyles.dmSans(size: 9, color: mutedCol, weight: FontWeight.w700, letterSpacing: 0.4)),
          const SizedBox(height: 2),
          Text(rate, style: AppTextStyles.dmSans(size: 17, weight: FontWeight.w800, color: textCol)),
          Text(bank, style: AppTextStyles.dmSans(size: 9, color: mutedCol)),
          const SizedBox(height: 4),
          Text(
            change,
            style: AppTextStyles.dmSans(
              size: 9,
              weight: FontWeight.bold,
              color: isDown ? const Color(0xFFC0392B) : const Color(0xFF15803D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmortHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(
        label,
        style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: widget.theme.getMutedColor(context)),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAmortCell(String label, {Color? color, bool alignLeft = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        label,
        style: AppTextStyles.dmSans(
          size: 10.5,
          weight: FontWeight.bold,
          color: color ?? widget.theme.getTextColor(context),
        ),
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
      ),
    );
  }

  Widget _buildGuideCard(
    int step,
    String title,
    String desc,
    String tag,
    Color stepColor,
    Color tagBg,
    Color tagTxt,
  ) {
    final cardBg = widget.theme.getCardColor(context);
    final textCol = widget.theme.getTextColor(context);
    final mutedCol = widget.theme.getMutedColor(context);
    final borderCol = widget.theme.getBorderColor(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [stepColor, stepColor.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              '$step',
              style: AppTextStyles.dmSans(size: 15, weight: FontWeight.w800, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: textCol)),
                const SizedBox(height: 4),
                Text(desc, style: AppTextStyles.dmSans(size: 10, color: mutedCol, height: 1.5)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(tag, style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: tagTxt)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(String emoji, String title, String desc, {bool isDk = false, bool isFn = false, bool isTl = false, bool isGd = false, bool isLight = false}) {
    Color? bg;
    Color? text;
    Color? descC;

    if (isDk) {
      bg = const Color(0xFF0A0F0D);
      text = Colors.white;
      descC = Colors.white54;
    } else if (isFn) {
      bg = const Color(0xFF1A6B4A);
      text = Colors.white;
      descC = Colors.white60;
    } else if (isTl) {
      bg = const Color(0xFF0D9488);
      text = Colors.white;
      descC = Colors.white60;
    } else if (isGd) {
      bg = const Color(0xFFD4A017);
      text = Colors.white;
      descC = Colors.white60;
    } else {
      bg = widget.theme.getCardColor(context);
      text = widget.theme.getTextColor(context);
      descC = widget.theme.getMutedColor(context);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: bg,
        gradient: isDk
            ? const LinearGradient(colors: [Color(0xFF0A0F0D), Color(0xFF0D3B2E)])
            : isFn
                ? const LinearGradient(colors: [Color(0xFF1A6B4A), Color(0xFF0D3B2E)])
                : isTl
                    ? const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0F766E)])
                    : isGd
                        ? const LinearGradient(colors: [Color(0xFFD4A017), Color(0xFFA07810)])
                        : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 7),
          Text(title, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: text)),
          const SizedBox(height: 3),
          Expanded(
            child: Text(
              desc,
              style: AppTextStyles.dmSans(size: 9.5, color: descC, height: 1.4),
              overflow: TextOverflow.fade,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkCard(String emoji, String title, String subtitle) {
    final cardBg = widget.theme.getCardColor(context);
    final textCol = widget.theme.getTextColor(context);
    final mutedCol = widget.theme.getMutedColor(context);
    final borderCol = widget.theme.getBorderColor(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: widget.theme.getBgColor(context),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: textCol)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.dmSans(size: 9.5, color: mutedCol)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: textCol.withValues(alpha: 0.18)),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) return months[month];
    return '';
  }
}

class _MHDonutPainter extends CustomPainter {
  final double principal;
  final double totalInterest;
  final bool isDark;
  final CountryTheme theme;

  const _MHDonutPainter({
    required this.principal,
    required this.totalInterest,
    required this.isDark,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    const strokeW = 18.0;
    final ringRadius = radius - strokeW / 2;

    final basePaint = Paint()
      ..color = isDark ? Colors.white10 : const Color(0xFFEDF5F2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;

    canvas.drawCircle(center, ringRadius, basePaint);

    final rect = Rect.fromCircle(center: center, radius: ringRadius);

    final double totalPaid = principal + totalInterest;
    if (totalPaid <= 0) return;

    final double prinFrac = principal / totalPaid;
    final double intFrac = totalInterest / totalPaid;

    // Principal arc (green/primary)
    const double startAngle = -math.pi / 2; // -90 deg
    final double prinSweep = prinFrac * 2 * math.pi;
    final double intSweep = intFrac * 2 * math.pi;

    final prinPaint = Paint()
      ..color = theme.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;

    final intPaint = Paint()
      ..color = const Color(0xFFC0392B) // secondary/red accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;

    canvas.drawArc(rect, startAngle, prinSweep, false, prinPaint);
    canvas.drawArc(rect, startAngle + prinSweep, intSweep, false, intPaint);

    // Center text
    String label = '';
    if (principal >= 1000000) {
      label = '\$${(principal / 1000000).toStringAsFixed(2)}M';
    } else if (principal >= 1000) {
      label = '\$${(principal / 1000).round()}K';
    } else {
      label = '\$${principal.round()}';
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF0A0F0D),
          fontFamily: 'Palatino',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final subPainter = TextPainter(
      text: TextSpan(
        text: 'Borrowed',
        style: TextStyle(
          fontSize: 8,
          color: isDark ? Colors.white38 : const Color(0xFF4A6358),
          fontFamily: 'Helvetica Neue',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, center + Offset(-textPainter.width / 2, -textPainter.height / 2 - 6));
    subPainter.paint(canvas, center + Offset(-subPainter.width / 2, -subPainter.height / 2 + 10));
  }

  @override
  bool shouldRepaint(covariant _MHDonutPainter oldDelegate) =>
      oldDelegate.principal != principal || oldDelegate.totalInterest != totalInterest || oldDelegate.isDark != isDark;
}

class _MHOcrHistoryChartPainter extends CustomPainter {
  final bool isDark;
  final CountryTheme theme;

  const _MHOcrHistoryChartPainter({required this.isDark, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 360;
    final scaleY = size.height / 160;

    final borderPaint = Paint()
      ..color = isDark ? Colors.white10 : const Color(0x170D3B2E)
      ..strokeWidth = 1.0;

    // Horizontal grid lines
    final yTicks = [20.0, 50.0, 80.0, 110.0, 140.0];
    final yLabels = ['9%', '7%', '5%', '3%', '1%'];

    for (int i = 0; i < yTicks.length; i++) {
      final y = yTicks[i] * scaleY;
      canvas.drawLine(Offset(40 * scaleX, y), Offset(350 * scaleX, y), borderPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: yLabels[i],
          style: TextStyle(
            fontSize: 8,
            color: isDark ? Colors.white54 : const Color(0xFF4A6358),
            fontFamily: 'Helvetica Neue',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(15 * scaleX, y - 5));
    }

    // X Axis Labels
    final xTicks = [60.0, 115.0, 170.0, 225.0, 280.0, 340.0];
    final xLabels = ['2020', '2021', '2022', '2023', '2024', '2025'];
    for (int i = 0; i < xTicks.length; i++) {
      final x = xTicks[i] * scaleX;
      final textPainter = TextPainter(
        text: TextSpan(
          text: xLabels[i],
          style: TextStyle(
            fontSize: 8,
            color: isDark ? Colors.white54 : const Color(0xFF4A6358),
            fontFamily: 'Helvetica Neue',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, 148 * scaleY));
    }

    // OCR points
    const ocrPts = [
      Offset(60, 137), Offset(115, 137), Offset(170, 95), Offset(225, 50), Offset(280, 50), Offset(340, 50)
    ];

    // 1-Yr Fixed points
    const fixedPts = [
      Offset(60, 112), Offset(115, 120), Offset(170, 46), Offset(225, 20), Offset(280, 27), Offset(340, 36)
    ];

    final scaledOcr = ocrPts.map((pt) => Offset(pt.dx * scaleX, pt.dy * scaleY)).toList();
    final scaledFixed = fixedPts.map((pt) => Offset(pt.dx * scaleX, pt.dy * scaleY)).toList();

    // Fill area under OCR line
    if (scaledOcr.length >= 2) {
      final fillPath = Path()..moveTo(scaledOcr.first.dx, scaledOcr.first.dy);
      for (int i = 1; i < scaledOcr.length; i++) {
        fillPath.lineTo(scaledOcr[i].dx, scaledOcr[i].dy);
      }
      fillPath.lineTo(scaledOcr.last.dx, 140 * scaleY);
      fillPath.lineTo(scaledOcr.first.dx, 140 * scaleY);
      fillPath.close();

      final fillPaint = Paint()
        ..color = theme.primaryColor.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw lines
    final ocrPaint = Paint()
      ..color = theme.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fixedPaint = Paint()
      ..color = const Color(0xFF0EA5E9) // sky blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (scaledOcr.length >= 2) {
      final path = Path()..moveTo(scaledOcr.first.dx, scaledOcr.first.dy);
      for (int i = 1; i < scaledOcr.length; i++) {
        path.lineTo(scaledOcr[i].dx, scaledOcr[i].dy);
      }
      canvas.drawPath(path, ocrPaint);
    }

    if (scaledFixed.length >= 2) {
      final path = Path()..moveTo(scaledFixed.first.dx, scaledFixed.first.dy);
      for (int i = 1; i < scaledFixed.length; i++) {
        path.lineTo(scaledFixed[i].dx, scaledFixed[i].dy);
      }
      canvas.drawPath(path, fixedPaint);
    }

    // Draw dots
    final whiteStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final ocrDotPaint = Paint()..color = theme.primaryColor;
    final fixedDotPaint = Paint()..color = const Color(0xFF0EA5E9);

    for (var pt in scaledOcr) {
      canvas.drawCircle(pt, 4.0, ocrDotPaint);
      canvas.drawCircle(pt, 4.0, whiteStroke);
    }

    for (var pt in scaledFixed) {
      canvas.drawCircle(pt, 4.0, fixedDotPaint);
      canvas.drawCircle(pt, 4.0, whiteStroke);
    }

    // Callout labels at the end of the line
    if (scaledFixed.isNotEmpty) {
      final pt = scaledFixed.last;
      final textPainter = TextPainter(
        text: const TextSpan(
          text: '6.59%',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0EA5E9),
            fontFamily: 'Helvetica Neue',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, pt + const Offset(6, -4));
    }

    if (scaledOcr.isNotEmpty) {
      final pt = scaledOcr.last;
      final textPainter = TextPainter(
        text: TextSpan(
          text: '5.50%',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
            fontFamily: 'Helvetica Neue',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, pt + const Offset(6, -4));
    }
  }

  @override
  bool shouldRepaint(covariant _MHOcrHistoryChartPainter oldDelegate) => oldDelegate.isDark != isDark;
}
