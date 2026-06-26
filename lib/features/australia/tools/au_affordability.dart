// lib/features/australia/tools/au_affordability.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class AUAffordability extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const AUAffordability({super.key, this.theme = CountryThemes.australia});

  @override
  ConsumerState<AUAffordability> createState() => _AUAffordabilityState();
}

class _AUAffordabilityState extends ConsumerState<AUAffordability> {
  double _income = 120000;
  double _partnerIncome = 0;
  double _expenses = 3500;
  double _debts = 0;
  double _deposit = 80000;
  int _termYears = 30;

  bool _showResults = false;

  void _reset() {
    setState(() {
      _income = 120000;
      _partnerIncome = 0;
      _expenses = 3500;
      _debts = 0;
      _deposit = 80000;
      _termYears = 30;
      _showResults = false;
    });
  }

  double _netIncome(double gross) {
    // 2024-25 ATO tax brackets
    double tax = 0;
    if (gross <= 18200) {
      tax = 0;
    } else if (gross <= 45000) {
      tax = (gross - 18200) * 0.19;
    } else if (gross <= 135000) {
      tax = 5092 + (gross - 45000) * 0.325;
    } else if (gross <= 190000) {
      tax = 34342 + (gross - 135000) * 0.37;
    } else {
      tax = 54682 + (gross - 190000) * 0.45;
    }
    // Medicare levy 2%
    tax += gross * 0.02;
    return gross - tax;
  }

  void _saveCalculation() async {
    final netMthly = (_netIncome(_income) + _netIncome(_partnerIncome)) / 12;
    const assessRate = 0.0609 + 0.03;
    const r = assessRate / 12;
    final n = _termYears * 12;

    final availRepay = netMthly - _expenses - _debts;
    if (availRepay <= 0) return;

    final loanAmt = availRepay * (1 - pow(1 + r, -n)) / r;
    const realRate = 0.0609 / 12;
    final realRepay = loanAmt * realRate / (1 - pow(1 + realRate, -n));
    final maxProp = loanAmt + _deposit;
    final totalRepay = realRepay * n;
    final totalInterest = totalRepay - loanAmt;
    final dti = loanAmt / (max(1.0, _income + _partnerIncome));

    final labelCtrl = TextEditingController(text: 'My Borrowing Power');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Capacity Check', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving: \$${CurrencyFormatter.compact(loanAmt, symbol: 'AU\$')} borrowing power',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My Borrowing Power)',
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
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'Borrowing Capacity';
      final calc = SavedCalc.create(
        country: 'Australia',
        calcType: 'Affordability',
        inputs: {
          'income': _income,
          'partnerIncome': _partnerIncome,
          'expenses': _expenses,
          'debts': _debts,
          'deposit': _deposit,
          'termYears': _termYears.toDouble(),
        },
        results: {
          'loanAmt': loanAmt,
          'maxProp': maxProp,
          'realRepay': realRepay,
          'dti': dti,
          'totalRepay': totalRepay,
          'totalInterest': totalInterest,
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

    // Calculations
    final totalGross = _income + _partnerIncome;
    final netMthly = (_netIncome(_income) + _netIncome(_partnerIncome)) / 12;

    // APRA buffer: assess at 6.09% + 3% = 9.09%
    const assessRate = 0.0609 + 0.03;
    const r = assessRate / 12;
    final n = _termYears * 12;

    final availRepay = max(0.0, netMthly - _expenses - _debts);

    // Loan amount from annuity formula
    final loanAmt = r > 0 ? availRepay * (1 - pow(1 + r, -n)) / r : 0.0;

    // Actual repayment at real rate
    const realRate = 0.0609 / 12;
    final realRepay = loanAmt > 0 ? loanAmt * realRate / (1 - pow(1 + realRate, -n)) : 0.0;

    final maxProp = loanAmt + _deposit;
    final totalRepay = realRepay * n;
    final totalInterest = max(0.0, totalRepay - loanAmt);
    final dti = totalGross > 0 ? loanAmt / totalGross : 0.0;

    // Alloc bar percentages
    final repayPct = netMthly > 0 ? (realRepay / netMthly).clamp(0.0, 1.0) : 0.0;
    final expPct = netMthly > 0 ? (_expenses / netMthly).clamp(0.0, 1.0 - repayPct) : 0.0;
    final freePct = max(0.0, 1.0 - repayPct - expPct);

    // Donut percentages
    final donutTotal = loanAmt + totalInterest;
    final principalPct = donutTotal > 0 ? loanAmt / donutTotal : 0.0;
    final interestPct = donutTotal > 0 ? totalInterest / donutTotal : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Finances', style: AppTextStyles.dmSans(size: 11, color: isDark ? const Color(0xFFFFD700) : theme.primaryColor, weight: FontWeight.w700, letterSpacing: 0.5)),
                  GestureDetector(
                    onTap: _reset,
                    child: Text('Reset ↺', style: AppTextStyles.dmSans(size: 11, color: isDark ? const Color(0xFFFFD700) : theme.primaryColor, weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildSliderInputRow(
                label: 'Gross Annual Income',
                value: _income,
                min: 50000,
                max: 400000,
                onChanged: (val) => setState(() => _income = val),
              ),
              const SizedBox(height: 12),

              _buildSliderInputRow(
                label: 'Partner Income (optional)',
                value: _partnerIncome,
                min: 0,
                max: 300000,
                onChanged: (val) => setState(() => _partnerIncome = val),
              ),
              const SizedBox(height: 12),

              _buildSliderInputRow(
                label: 'Monthly Living Expenses',
                value: _expenses,
                min: 1000,
                max: 15000,
                onChanged: (val) => setState(() => _expenses = val),
              ),
              const SizedBox(height: 12),

              // Existing debts
              Text('EXISTING MONTHLY DEBTS', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFFFF8F0),
                  border: Border.all(color: theme.getBorderColor(context)),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  children: [
                    Text('\$ ', style: AppTextStyles.dmSans(size: 14, color: isDark ? const Color(0xFFFFD700) : theme.primaryColor, weight: FontWeight.w700)),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey(_debts),
                        initialValue: _debts.toInt().toString(),
                        keyboardType: TextInputType.number,
                        style: AppTextStyles.dmSans(size: 14, color: theme.getTextColor(context), weight: FontWeight.w800),
                        decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
                        onChanged: (val) {
                          setState(() => _debts = double.tryParse(val) ?? 0.0);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              _buildSliderInputRow(
                label: 'Deposit Saved',
                value: _deposit,
                min: 0,
                max: 500000,
                onChanged: (val) => setState(() => _deposit = val),
              ),
              const SizedBox(height: 12),

              // Term Select
              Text('LOAN TERM', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFFFF8F0),
                  border: Border.all(color: theme.getBorderColor(context)),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _termYears,
                    isExpanded: true,
                    dropdownColor: isDark ? const Color(0xFF141C33) : const Color(0xFFFFF8F0),
                    style: AppTextStyles.dmSans(size: 14, color: theme.getTextColor(context), weight: FontWeight.w800),
                    items: [
                      DropdownMenuItem(value: 30, child: Text('30 years', style: AppTextStyles.dmSans(size: 14, color: theme.getTextColor(context)))),
                      DropdownMenuItem(value: 25, child: Text('25 years', style: AppTextStyles.dmSans(size: 14, color: theme.getTextColor(context)))),
                      DropdownMenuItem(value: 20, child: Text('20 years', style: AppTextStyles.dmSans(size: 14, color: theme.getTextColor(context)))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _termYears = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  if (availRepay <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Expenses and debts exceed your net monthly income!', style: AppTextStyles.dmSans())),
                    );
                    return;
                  }
                  setState(() => _showResults = true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text('💰 Calculate Borrowing Capacity', style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.w800, letterSpacing: 0.3)),
              ),
            ],
          ),
        ),

        // Results Card
        if (_showResults) ...[
          const SizedBox(height: 20),
          // Capacity Summary Card
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
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Maximum Borrowing Capacity', style: AppTextStyles.dmSans(size: 10, color: Colors.white60, weight: FontWeight.w700, letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text(CurrencyFormatter.format(loanAmt, currencyCode: 'AUD'), style: AppTextStyles.playfair(size: 36, color: const Color(0xFFFFD700), weight: FontWeight.w800)),
                Text('Based on APRA serviceability buffer of 3%', style: AppTextStyles.dmSans(size: 11, color: Colors.white70)),
                const SizedBox(height: 16),

                // rc-grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _buildResultBox('Max Property', CurrencyFormatter.format(maxProp, currencyCode: 'AUD'), color: const Color(0xFFFFD700)),
                    _buildResultBox('Monthly Repayment', '${CurrencyFormatter.format(realRepay, currencyCode: 'AUD')}/mo'),
                    _buildResultBox('Serviceability Rate', '9.09%', color: const Color(0xFFBBF7D0)),
                    _buildResultBox('DTI Ratio', '${dti.toStringAsFixed(1)}x', color: dti > 6 ? const Color(0xFFFCA5A5) : dti > 4.5 ? const Color(0xFFFBBF24) : const Color(0xFF86EFAC)),
                  ],
                ),
                const SizedBox(height: 16),

                // Income allocation bar
                Text('INCOME ALLOCATION', style: AppTextStyles.dmSans(size: 9, color: Colors.white60, weight: FontWeight.w700, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    children: [
                      if (repayPct > 0) Expanded(flex: (repayPct * 100).toInt(), child: Container(color: const Color(0xFFFFD700))),
                      if (expPct > 0) Expanded(flex: (expPct * 100).toInt(), child: Container(color: const Color(0xFF60A5FA))),
                      if (freePct > 0) Expanded(flex: (freePct * 100).toInt(), child: Container(color: const Color(0xFFBBF7D0))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildAllocLegend(const Color(0xFFFFD700), 'Repayment'),
                    const SizedBox(width: 10),
                    _buildAllocLegend(const Color(0xFF60A5FA), 'Expenses'),
                    const SizedBox(width: 10),
                    _buildAllocLegend(const Color(0xFFBBF7D0), 'Surplus'),
                  ],
                ),
                const SizedBox(height: 12),

                ElevatedButton(
                  onPressed: _saveCalculation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🔖', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text('Save This Calculation', style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Donut repays card
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Repayment Breakdown', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context), weight: FontWeight.w800)),
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: CustomPaint(
                          painter: _SimpleDonutPainter(
                            principalPct: principalPct,
                            interestPct: interestPct,
                            isDark: isDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Total Repayable', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.w700)),
                      Text(CurrencyFormatter.format(totalRepay, currencyCode: 'AUD'), style: AppTextStyles.playfair(size: 22, color: theme.getTextColor(context), weight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDonutLegendItem('Principal', const Color(0xFF7C2D12), CurrencyFormatter.format(loanAmt, currencyCode: 'AUD')),
                          const SizedBox(width: 16),
                          _buildDonutLegendItem('Interest', const Color(0xFF002868), CurrencyFormatter.format(totalInterest, currencyCode: 'AUD')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Help text
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF7C2D12).withValues(alpha: 0.2) : const Color(0xFFFFF7ED),
            border: Border.all(color: isDark ? const Color(0xFFEA580C) : const Color(0xFFFCA5A5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.dmSans(size: 11, color: isDark ? const Color(0xFFFFEDD5) : const Color(0xFF92400E), height: 1.5),
              children: [
                TextSpan(text: '🏦 APRA Serviceability Buffer: ', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFFFD700) : const Color(0xFF7C2D12))),
                const TextSpan(text: 'As of 2025, Australian lenders must assess your ability to repay at your actual rate '),
                const TextSpan(text: '+ 3% ', style: TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(text: '(up from 2.5%). This means on a 6.09% loan, you\'ll be assessed at ~9.09%. Your borrowing power is calculated on net income after tax using the '),
                const TextSpan(text: 'HEM (Household Expenditure Measure).', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderInputRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFFFFD700) : theme.primaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.w800, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFFFF8F0),
            border: Border.all(color: theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              Text('\$ ', style: AppTextStyles.dmSans(size: 14, color: primaryColor, weight: FontWeight.w700)),
              Expanded(
                child: TextFormField(
                  key: ValueKey(value),
                  initialValue: value.toInt().toString(),
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.dmSans(size: 14, color: theme.getTextColor(context), weight: FontWeight.w800),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
                  onChanged: (val) {
                    final d = double.tryParse(val) ?? 0.0;
                    onChanged(d);
                  },
                ),
              ),
            ],
          ),
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: primaryColor,
            inactiveTrackColor: primaryColor.withValues(alpha: 0.15),
            thumbColor: primaryColor,
            trackHeight: 3,
            overlayColor: primaryColor.withValues(alpha: 0.1),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('\$${(min / 1000).toStringAsFixed(0)}K', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context))),
            Text('\$${(max / 1000).toStringAsFixed(0)}K', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context))),
          ],
        ),
      ],
    );
  }

  Widget _buildResultBox(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white60)),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: color ?? Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildAllocLegend(Color color, String text) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(text, style: AppTextStyles.dmSans(size: 10, color: Colors.white70)),
      ],
    );
  }

  Widget _buildDonutLegendItem(String label, Color color, String amount) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text('$label: ', style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context), weight: FontWeight.w600)),
        Text(amount, style: AppTextStyles.dmSans(size: 11, color: widget.theme.getTextColor(context), weight: FontWeight.w800)),
      ],
    );
  }
}

class _SimpleDonutPainter extends CustomPainter {
  final double principalPct;
  final double interestPct;
  final bool isDark;

  _SimpleDonutPainter({
    required this.principalPct,
    required this.interestPct,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    const strokeWidth = 14.0;

    final paintBg = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, paintBg);

    double startAngle = -pi / 2;

    if (principalPct > 0) {
      final sweepAngle = principalPct * 2 * pi;
      final paintP = Paint()
        ..color = const Color(0xFF7C2D12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, paintP);
      startAngle += sweepAngle;
    }

    if (interestPct > 0) {
      final sweepAngle = interestPct * 2 * pi;
      final paintI = Paint()
        ..color = const Color(0xFF002868)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, paintI);
    }
  }

  @override
  bool shouldRepaint(covariant _SimpleDonutPainter oldDelegate) =>
      oldDelegate.principalPct != principalPct || oldDelegate.interestPct != interestPct || oldDelegate.isDark != isDark;
}
