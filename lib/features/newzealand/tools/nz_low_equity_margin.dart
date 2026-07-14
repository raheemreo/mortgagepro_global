// lib/features/newzealand/tools/nz_low_equity_margin.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZLowEquityMargin extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZLowEquityMargin({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZLowEquityMargin> createState() => _NZLowEquityMarginState();
}

class _NZLowEquityMarginState extends ConsumerState<NZLowEquityMargin> {
  double _propVal = 750000;
  double _deposit = 112500;
  double _baseRate = 6.59;
  int _termYears = 30;

  bool _showResults = false;
  final Map<String, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};
  final _resultsKey = GlobalKey();

  void _reset() {
    setState(() {
      _propVal = 750000;
      _deposit = 112500;
      _baseRate = 6.59;
      _termYears = 30;
      _showResults = false;
      _calcSnapshot.clear();
      _errors.clear();
    });
  }

  void _calculate() {
    final errors = <String, String>{};

    if (_propVal <= 0) {
      errors['propVal'] = 'Enter valid property value';
    }
    if (_deposit < 0) {
      errors['deposit'] = 'Deposit cannot be negative';
    } else if (_deposit >= _propVal && _propVal > 0) {
      errors['deposit'] = 'Deposit must be less than property value';
    }
    if (_baseRate <= 0 || _baseRate > 25) {
      errors['baseRate'] = 'Enter base rate between 0.1% and 25%';
    }
    if (_termYears <= 0 || _termYears > 50) {
      errors['termYears'] = 'Enter term between 1 and 50 years';
    }

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) return;

    setState(() {
      _calcSnapshot['propVal'] = _propVal;
      _calcSnapshot['deposit'] = _deposit;
      _calcSnapshot['baseRate'] = _baseRate;
      _calcSnapshot['termYears'] = _termYears;
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

  void _saveCalculation(double lvr, double lemRate, double effRate,
      double extraMth, double loan) async {
    final snapPropVal = _calcSnapshot['propVal'] ?? _propVal;
    final snapDeposit = _calcSnapshot['deposit'] ?? _deposit;
    final snapBaseRate = _calcSnapshot['baseRate'] ?? _baseRate;
    final snapTermYears = _calcSnapshot['termYears'] ?? _termYears;

    final labelCtrl = TextEditingController(text: 'NZ LEM Analysis');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/nz_low_equity_margin'),
      builder: (context) {
        return AlertDialog(
          backgroundColor: widget.theme.getCardColor(context),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('💾 Save LEM Calculation',
              style: AppTextStyles.playfair(
                  size: 16, color: widget.theme.getTextColor(context))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saving: LVR of ${lvr.toStringAsFixed(1)}% with +${lemRate.toStringAsFixed(2)}% LEM margin.',
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
                  hintText: 'Label (e.g. 15% Deposit Loan)',
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
                backgroundColor: const Color(0xFFC0392B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Save',
                  style: AppTextStyles.dmSans(
                      size: 12, color: Colors.white, weight: FontWeight.w700)),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final label = labelCtrl.text.trim().isNotEmpty
          ? labelCtrl.text.trim()
          : 'LEM Analysis';
      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'Low Equity Margin',
        inputs: <String, double>{
          'propertyValue': snapPropVal,
          'deposit': snapDeposit,
          'baseRate': snapBaseRate,
          'termYears': snapTermYears.toDouble(),
        },
        results: <String, double>{
          'lvr': lvr,
          'lemRate': lemRate,
          'effectiveRate': effRate,
          'extraMonthly': extraMth,
          'loan': loan,
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Calculation saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF1A6B4A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  double _calculateMonthlyRepayment(double P, double annualRate, int years) {
    final r = annualRate / 100 / 12;
    final n = years * 12;
    if (r == 0) return P / n;
    return P * r * pow(1 + r, n) / (pow(1 + r, n) - 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double rawPropVal = _propVal;
    final double rawDeposit = _deposit;
    final double rawBaseRate = _baseRate;
    final int rawTermYears = _termYears;

    final double propVal = _showResults ? (_calcSnapshot['propVal'] ?? rawPropVal) : rawPropVal;
    final double deposit = _showResults ? (_calcSnapshot['deposit'] ?? rawDeposit) : rawDeposit;
    final double baseRate = _showResults ? (_calcSnapshot['baseRate'] ?? rawBaseRate) : rawBaseRate;
    final int termYears = _showResults ? (_calcSnapshot['termYears'] ?? rawTermYears) : rawTermYears;

    // Base calculations
    final loan = max(0.0, propVal - deposit);
    final lvr = propVal > 0 ? (loan / propVal) * 100 : 0.0;

    // LEM rules logic
    double lemRate = 0.0;
    int activeBand = 4;
    if (lvr > 85) {
      lemRate = 1.50;
      activeBand = 1;
    } else if (lvr > 82.5) {
      lemRate = 1.00;
      activeBand = 2;
    } else if (lvr > 80.0) {
      lemRate = 0.50;
      activeBand = 3;
    } else {
      lemRate = 0.0;
      activeBand = 4;
    }

    final effRate = baseRate + lemRate;
    final mthStd = _calculateMonthlyRepayment(loan, baseRate, termYears);
    final mthLEM = _calculateMonthlyRepayment(loan, effRate, termYears);
    final extraMth = max(0.0, mthLEM - mthStd);

    // Layout percentages for comparison bars
    final maxBar = max(1.0, mthLEM);
    final stdPct = (mthStd / maxBar).clamp(0.0, 1.0);
    final lemPct = (mthLEM / maxBar).clamp(0.0, 1.0);

    final isDirty = _showResults && (
      _propVal != (_calcSnapshot['propVal'] ?? 0.0) ||
      _deposit != (_calcSnapshot['deposit'] ?? 0.0) ||
      _baseRate != (_calcSnapshot['baseRate'] ?? 0.0) ||
      _termYears != (_calcSnapshot['termYears'] ?? 0)
    );

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Rate Strip
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                    child: _buildRateStripCell(
                        'LEM Trigger', '>80%', 'LVR Threshold')),
                _buildDivider(),
                Expanded(
                    child: _buildRateStripCell(
                        'Typical LEM', '0.5–1.5%', 'Of loan')),
                _buildDivider(),
                Expanded(
                    child: _buildRateStripCell('Max LVR', '90%', 'Owner-Occ')),
                _buildDivider(),
                Expanded(
                    child: _buildRateStripCell(
                        'Fee Type', 'Rate', 'Margin added',
                        isGold: true)),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Inputs Card (Hero Styling)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF922B21), Color(0xFFC0392B)],
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
                    Text('Low Equity Margin · NZ Banks 2025',
                        style: AppTextStyles.dmSans(
                            size: 9.5,
                            color: Colors.white60,
                            weight: FontWeight.w600)),
                    GestureDetector(
                      onTap: _reset,
                      child: Text('Reset ↺',
                          style: AppTextStyles.dmSans(
                              size: 11,
                              color: const Color(0xFFF5D060),
                              weight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Calculate your LEM Fee',
                    style: AppTextStyles.playfair(
                        size: 17,
                        color: Colors.white,
                        weight: FontWeight.w800)),
                const SizedBox(height: 14),

                // Property value and deposit input
                Row(
                  children: [
                    Expanded(
                      child: _buildHeroInputBox(
                        label: 'Property Value',
                        value: _propVal,
                        errorText: _errors['propVal'],
                        onChanged: (val) => setState(() => _propVal = val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildHeroInputBox(
                        label: 'Deposit',
                        value: _deposit,
                        errorText: _errors['deposit'],
                        onChanged: (val) => setState(() => _deposit = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Base interest rate and term
                Row(
                  children: [
                    Expanded(
                      child: _buildHeroInputBox(
                        label: 'Base Interest Rate (%)',
                        value: _baseRate,
                        errorText: _errors['baseRate'],
                        onChanged: (val) => setState(() => _baseRate = val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LOAN TERM',
                              style: AppTextStyles.dmSans(
                                  size: 8.5,
                                  color: Colors.white60,
                                  weight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _termYears,
                                dropdownColor: const Color(0xFF922B21),
                                isExpanded: true,
                                style: AppTextStyles.dmSans(
                                    size: 13,
                                    color: Colors.white,
                                    weight: FontWeight.w700),
                                items: [
                                  DropdownMenuItem(
                                      value: 20,
                                      child: Text('20 years',
                                          style: AppTextStyles.dmSans(
                                              size: 13, color: Colors.white))),
                                  DropdownMenuItem(
                                      value: 25,
                                      child: Text('25 years',
                                          style: AppTextStyles.dmSans(
                                              size: 13, color: Colors.white))),
                                  DropdownMenuItem(
                                      value: 30,
                                      child: Text('30 years',
                                          style: AppTextStyles.dmSans(
                                              size: 13, color: Colors.white))),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _termYears = val);
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
                const SizedBox(height: 14),

                ElevatedButton(
                  onPressed: _calculate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A0F0D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  child: Text('🔍 Calculate LEM Cost',
                      style: AppTextStyles.dmSans(
                          size: 13, weight: FontWeight.w800, color: Colors.white)),
                ),
              ],
            ),
          ),

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
                        'Inputs have changed. Tap Calculate LEM Cost to refresh results.',
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  // LEM Result Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: theme.getCardColor(context),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: theme.getBorderColor(context)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Low Equity Margin Analysis',
                                style: AppTextStyles.playfair(
                                    size: 14,
                                    color: theme.getTextColor(context),
                                    weight: FontWeight.w800)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: lemRate > 0
                                    ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2))
                                    : (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                lemRate > 0 ? 'LEM Applies' : 'No LEM',
                                style: AppTextStyles.dmSans(
                                    size: 11,
                                    weight: FontWeight.w800,
                                color: lemRate > 0
                                        ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC0392B))
                                        : (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46))),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Large Added Rate display
                        Center(
                          child: Column(
                            children: [
                              Text('LEM ADDED TO YOUR RATE',
                                  style: AppTextStyles.dmSans(
                                      size: 10,
                                      color: theme.getMutedColor(context),
                                      weight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                lemRate > 0
                                    ? '+${lemRate.toStringAsFixed(2)}%'
                                    : '0.00% (No LEM)',
                                style: AppTextStyles.playfair(
                                    size: 36,
                                    color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC0392B),
                                    weight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                lemRate > 0
                                    ? 'Effective rate: ${effRate.toStringAsFixed(2)}% (${baseRate.toStringAsFixed(2)}% base + ${lemRate.toStringAsFixed(2)}% LEM)'
                                    : 'Your LVR of ${lvr.toStringAsFixed(1)}% is within standard 80% limit — no LEM!',
                                style: AppTextStyles.dmSans(
                                    size: 11, color: theme.getMutedColor(context)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Stats row
                        Row(
                          children: [
                            Expanded(
                              child: _buildResultStatBox(
                                  'Your LVR', '${lvr.toStringAsFixed(1)}%',
                                  isRed: lvr > 80, isGreen: lvr <= 80),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildResultStatBox(
                                  'Effective Rate', '${effRate.toStringAsFixed(2)}%',
                                  isRed: lemRate > 0),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildResultStatBox(
                                  'Extra Monthly',
                                  extraMth > 0
                                      ? '+${CurrencyFormatter.compact(extraMth, symbol: 'NZ\$')}/mo'
                                      : 'Nil',
                                  isRed: extraMth > 0),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Payment comparison bar chart
                        Text('Monthly Payment Comparison',
                            style: AppTextStyles.dmSans(
                                size: 11,
                                weight: FontWeight.w800,
                                color: theme.getTextColor(context))),
                        const SizedBox(height: 8),
                        _buildComparisonBar(
                            'Standard Monthly Repayment', mthStd, stdPct, theme),
                        const SizedBox(height: 10),
                        _buildComparisonBar('With LEM Added Repayment', mthLEM,
                            lemPct, theme,
                            barColor: isDark ? const Color(0xFFEF4444) : const Color(0xFFC0392B)),
                        const Divider(height: 24),

                        // Key facts
                        _buildGuideItem(
                            'Estimated loan amount',
                            CurrencyFormatter.format(loan, currencyCode: 'NZD'),
                            theme),
                        const SizedBox(height: 6),
                        _buildGuideItem(
                            'Monthly penalty cost',
                            '${CurrencyFormatter.format(extraMth, currencyCode: 'NZD')}/month',
                            theme),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Save Analysis Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.getCardColor(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.getBorderColor(context)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('💾 Save This Scenario',
                                  style: AppTextStyles.dmSans(
                                      size: 12,
                                      weight: FontWeight.w800,
                                      color: theme.getTextColor(context))),
                              const SizedBox(height: 2),
                              Text('Keep details in your profile',
                                  style: AppTextStyles.dmSans(
                                      size: 9.5,
                                      color: theme.getMutedColor(context))),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _saveCalculation(
                              lvr, lemRate, effRate, extraMth, loan),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC0392B),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                          ),
                          child: Text('Save ›',
                              style: AppTextStyles.dmSans(
                                  size: 11,
                                  color: Colors.white,
                                  weight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),

          // NZ Bank LEM Brackets Info
          Text('Typical NZ Bank LEM Brackets',
              style: AppTextStyles.playfair(
                  size: 14,
                  color: theme.getTextColor(context),
                  weight: FontWeight.w800)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              children: [
                _buildBandRow('🟢 Safe Band', '≤ 80% LVR', '0.00% LEM',
                    'Base rate applies', theme,
                    active: activeBand == 4),
                const Divider(height: 16),
                _buildBandRow('🟡 Band 1', '80.01% – 82.50% LVR', '+0.50% LEM',
                    'Likely margin added', theme,
                    active: activeBand == 3),
                const Divider(height: 16),
                _buildBandRow('🟠 Band 2', '82.51% – 85.00% LVR', '+1.00% LEM',
                    'Likely margin added', theme,
                    active: activeBand == 2),
                const Divider(height: 16),
                _buildBandRow('🔴 Band 3', '85.01% – 90.00% LVR', '+1.50% LEM',
                    'Significant margin added', theme,
                    active: activeBand == 1),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Informational Tip
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              border: Border.all(color: const Color(0xFFBFDBFE)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '💡 Tip: Low Equity Margin is usually removed automatically by banks once your LVR drops below 80% due to capital gains or principal repayments. Re-evaluate with your bank annually.',
              style: AppTextStyles.dmSans(
                  size: 9.5, color: const Color(0xFF1E3A8A), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateStripCell(String label, String value, String subtitle,
      {bool isGold = false}) {
    return Column(
      children: [
        Text(label.toUpperCase(),
            style: AppTextStyles.dmSans(
                size: 8,
                color: Colors.white60,
                weight: FontWeight.w600,
                letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyles.dmSans(
                size: 14,
                weight: FontWeight.w800,
                color: isGold ? const Color(0xFFF5D060) : Colors.white)),
        const SizedBox(height: 1),
        Text(subtitle,
            style: AppTextStyles.dmSans(size: 7.5, color: Colors.white38)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 25,
      width: 1,
      color: Colors.white12,
    );
  }

  Widget _buildHeroInputBox({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    String? errorText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: errorText != null ? Colors.red : Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: AppTextStyles.dmSans(
                  size: 8, color: Colors.white60, weight: FontWeight.w700)),
          const SizedBox(height: 2),
          TextFormField(
            key: ValueKey(value),
            initialValue: value.toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.playfair(
                size: 14, color: Colors.white, weight: FontWeight.w800),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
            onChanged: (val) {
              final d = double.tryParse(val) ?? 0.0;
              onChanged(d);
            },
          ),
          if (errorText != null) ...[
            const SizedBox(height: 2),
            Text(errorText, style: AppTextStyles.dmSans(size: 8, color: Colors.red, weight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }

  Widget _buildResultStatBox(String label, String value,
      {bool isRed = false, bool isGreen = false}) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.getBgColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Column(
        children: [
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 8.5,
                  color: theme.getMutedColor(context),
                  weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.dmSans(
              size: 12,
              weight: FontWeight.w800,
              color: isRed
                  ? const Color(0xFFC0392B)
                  : isGreen
                      ? const Color(0xFF1A6B4A)
                      : theme.getTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonBar(String label, double val, double pct, CountryTheme theme,
      {Color barColor = const Color(0xFF1A6B4A)}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTextStyles.dmSans(
                    size: 9.5, color: theme.getMutedColor(context), weight: FontWeight.w600)),
            Text('${CurrencyFormatter.format(val, currencyCode: 'NZD')}/mo',
                style: AppTextStyles.dmSans(
                    size: 11, color: theme.getTextColor(context), weight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          height: 10,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            borderRadius: BorderRadius.circular(5),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: pct,
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuideItem(String label, String value, CountryTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 10, color: theme.getMutedColor(context))),
          Text(value,
              style: AppTextStyles.dmSans(
                  size: 10.5, color: theme.getTextColor(context), weight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBandRow(
      String label, String band, String margin, String status, CountryTheme theme,
      {bool active = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFFEF3C7)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.bold,
                  color: active ? const Color(0xFF92400E) : theme.getTextColor(context),
                ),
              ),
              Text(
                status,
                style: AppTextStyles.dmSans(
                  size: 8.5,
                  color: active ? const Color(0xFFB45309) : theme.getMutedColor(context),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                band,
                style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.bold,
                  color: active ? const Color(0xFF92400E) : theme.getTextColor(context),
                ),
              ),
              Text(
                margin,
                style: AppTextStyles.dmSans(
                  size: 9.5,
                  weight: FontWeight.bold,
                  color: active ? const Color(0xFFC0392B) : const Color(0xFF1A6B4A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
