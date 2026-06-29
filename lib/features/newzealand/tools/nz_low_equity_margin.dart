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

  void _reset() {
    setState(() {
      _propVal = 750000;
      _deposit = 112500;
      _baseRate = 6.59;
      _termYears = 30;
      _showResults = false;
    });
  }

  void _saveCalculation(double lvr, double lemRate, double effRate,
      double extraMth, double loan) async {
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
      final label = labelCtrl.text;
      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'Low Equity Margin',
        inputs: {
          'propertyValue': _propVal,
          'deposit': _deposit,
          'baseRate': _baseRate,
          'termYears': _termYears.toDouble(),
        },
        results: {
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

    // Base calculations
    final loan = max(0.0, _propVal - _deposit);
    final lvr = _propVal > 0 ? (loan / _propVal) * 100 : 0.0;

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

    final effRate = _baseRate + lemRate;
    final mthStd = _calculateMonthlyRepayment(loan, _baseRate, _termYears);
    final mthLEM = _calculateMonthlyRepayment(loan, effRate, _termYears);
    final extraMth = max(0.0, mthLEM - mthStd);

    // Layout percentages for comparison bars
    final maxBar = max(1.0, mthLEM);
    final stdPct = (mthStd / maxBar).clamp(0.0, 1.0);
    final lemPct = (mthLEM / maxBar).clamp(0.0, 1.0);

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
                        onChanged: (val) => setState(() => _propVal = val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildHeroInputBox(
                        label: 'Deposit',
                        value: _deposit,
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
                  onPressed: () {
                    if (_propVal <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Please enter valid property value',
                                style: AppTextStyles.dmSans())),
                      );
                      return;
                    }
                    setState(() => _showResults = true);
                  },
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
                              ? 'Effective rate: ${effRate.toStringAsFixed(2)}% (${_baseRate.toStringAsFixed(2)}% base + ${lemRate.toStringAsFixed(2)}% LEM)'
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
                  const SizedBox(height: 10),
                  _buildComparisonBar('Without LEM', mthStd, stdPct,
                      const [Color(0xFF1A6B4A), Color(0xFF059669)]),
                  const SizedBox(height: 8),
                  _buildComparisonBar('With LEM', mthLEM, lemPct,
                      const [Color(0xFFC0392B), Color(0xFFE57373)]),
                  const SizedBox(height: 18),

                  // LEM Rate Bands List
                  Text('LEM Rate Bands (NZ Banks)',
                      style: AppTextStyles.dmSans(
                          size: 11,
                          weight: FontWeight.w800,
                          color: theme.getTextColor(context))),
                  const SizedBox(height: 8),
                  _buildBandListRow(
                      '85.01% – 90% LVR',
                      'Highest LEM tier · Limited lender options',
                      '+1.50%',
                      activeBand == 1),
                  _buildBandListRow(
                      '82.51% – 85% LVR',
                      'High LEM tier · Most lenders apply',
                      '+1.00%',
                      activeBand == 2),
                  _buildBandListRow(
                      '80.01% – 82.5% LVR',
                      'Standard LEM entry · Rate margin added',
                      '+0.50%',
                      activeBand == 3),
                  _buildBandListRow('≤80% LVR', 'No LEM · Standard rates apply',
                      '+0.00%', activeBand == 4),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Save calculation button
            ElevatedButton.icon(
              onPressed: () =>
                  _saveCalculation(lvr, lemRate, effRate, extraMth, loan),
              icon: const Text('💾', style: TextStyle(fontSize: 14)),
              label: Text('Save This Calculation',
                  style: AppTextStyles.dmSans(
                      size: 13, weight: FontWeight.w800, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A6B4A),
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
          const SizedBox(height: 18),

          // LEM Explanation Card
          Text('What is LEM?',
              style: AppTextStyles.playfair(
                  size: 14,
                  color: theme.getTextColor(context),
                  weight: FontWeight.w800)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF7F1D1D).withValues(alpha: 0.3), const Color(0xFF7F1D1D).withValues(alpha: 0.15)]
                    : const [Color(0xFFFEE2E2), Color(0xFFFEF2F2)],
              ),
              border: Border.all(color: isDark ? const Color(0xFF991B1B) : const Color(0xFFFECACA)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🔍 Low Equity Margin Explained',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        weight: FontWeight.w800,
                        color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC0392B))),
                const SizedBox(height: 10),
                _buildExplainRow('What is LEM?', 'Rate premium for >80% LVR'),
                _buildExplainRow(
                    'Why charged?', 'Higher default risk to lender'),
                _buildExplainRow('When removed?', 'When LVR drops below 80%'),
                _buildExplainRow('ANZ LEM range', '0.50% – 1.50% p.a.'),
                _buildExplainRow('ASB LEM range', '0.50% – 1.50% p.a.'),
                _buildExplainRow('Westpac LEM', '0.50% – 1.25% p.a.'),
                _buildExplainRow('Kiwibank LEM', '0.50% – 1.00% p.a.'),
                _buildExplainRow(
                    'Vs LMI (Australia)', 'NZ uses rate margin, not insurance'),
              ],
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
                color: Colors.white54,
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
            style: AppTextStyles.dmSans(size: 7.5, color: Colors.white38),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
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
            initialValue: value.toStringAsFixed(value == _baseRate ? 2 : 0),
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
        ],
      ),
    );
  }

  Widget _buildResultStatBox(String label, String value,
      {bool isGreen = false, bool isRed = false}) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: theme.getBgColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Column(
        children: [
          Text(label.toUpperCase(),
              style: AppTextStyles.dmSans(
                  size: 8,
                  color: theme.getMutedColor(context),
                  weight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTextStyles.dmSans(
              size: 13,
              weight: FontWeight.w800,
              color: isGreen
                  ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                  : isRed
                      ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC0392B))
                      : theme.getTextColor(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonBar(
      String name, double val, double widthPct, List<Color> colors) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(name,
              style: AppTextStyles.dmSans(
                  size: 10,
                  color: theme.getMutedColor(context),
                  weight: FontWeight.w700),
              textAlign: TextAlign.right),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 22,
                    decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF1F5F2),
                        borderRadius: BorderRadius.circular(6)),
                  ),
                  Container(
                    width: constraints.maxWidth * widthPct,
                    height: 22,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      CurrencyFormatter.format(val, currencyCode: 'NZD'),
                      style: AppTextStyles.dmSans(
                          size: 10,
                          weight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBandListRow(
      String title, String desc, String rate, bool isActive) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? (isDark ? const Color(0xFF7C2D12) : const Color(0xFFFFF7ED))
            : widget.theme.getBgColor(context),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
            color: isActive
                ? (isDark ? const Color(0xFFEA580C) : const Color(0xFFC0392B))
                : Colors.transparent,
            width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isActive
                  ? (isDark ? const Color(0xFFEA580C) : const Color(0xFFC0392B))
                  : Colors.grey.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.dmSans(
                        size: 11.5,
                        weight: FontWeight.w800,
                        color: widget.theme.getTextColor(context))),
                const SizedBox(height: 1),
                Text(desc,
                    style: AppTextStyles.dmSans(
                        size: 9, color: widget.theme.getMutedColor(context))),
              ],
            ),
          ),
          Text(rate,
              style: AppTextStyles.dmSans(
                  size: 12,
                  weight: FontWeight.w800,
                  color: widget.theme.getTextColor(context))),
        ],
      ),
    );
  }

  Widget _buildExplainRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x1EC0392B))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 11, color: isDark ? Colors.white70 : const Color(0xFF922B21))),
          Text(value,
              style: AppTextStyles.dmSans(
                  size: 11.5,
                  weight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF922B21))),
        ],
      ),
    );
  }
}
