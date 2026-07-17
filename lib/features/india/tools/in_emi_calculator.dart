// lib/features/india/tools/in_emi_calculator.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class INEmiCalculator extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INEmiCalculator({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INEmiCalculator> createState() => _INEmiCalculatorState();
}

class _INEmiCalculatorState extends ConsumerState<INEmiCalculator> {
  double _loanAmount = 5000000;
  double _ratePercent = 8.50;
  int _termYears = 20;

  bool _hasCalculated = false;
  double _calcLoanAmount = 5000000;
  double _calcRatePercent = 8.50;
  int _calcTermYears = 20;
  final GlobalKey _resultsKey = GlobalKey();

  final List<Map<String, dynamic>> _banks = const [
    {'icon': '🏦', 'name': 'SBI Home Loan', 'rate': 8.50, 'type': 'PSU Bank · Floating'},
    {'icon': '🏛️', 'name': 'HDFC Bank', 'rate': 8.70, 'type': 'Private · Floating'},
    {'icon': '💼', 'name': 'ICICI Bank', 'rate': 8.75, 'type': 'Private · Floating'},
    {'icon': '⚡', 'name': 'Axis Bank', 'rate': 8.75, 'type': 'Private · Floating'},
    {'icon': '🏗️', 'name': 'LIC HFL', 'rate': 8.65, 'type': 'HFC · Fixed/Float'},
    {'icon': '🔶', 'name': 'Bajaj HFL', 'rate': 8.55, 'type': 'NBFC · Floating'},
  ];

  bool _areInputsChanged() {
    return _loanAmount != _calcLoanAmount ||
        _ratePercent != _calcRatePercent ||
        _termYears != _calcTermYears;
  }

  void _reset() {
    setState(() {
      _loanAmount = 5000000;
      _ratePercent = 8.50;
      _termYears = 20;
      _hasCalculated = false;
      _calcLoanAmount = 5000000;
      _calcRatePercent = 8.50;
      _calcTermYears = 20;
    });
  }

  double _calcEMI(double p, double rpa, int nMonths) {
    final r = rpa / (12 * 100);
    return p * r * pow(1 + r, nMonths) / (pow(1 + r, nMonths) - 1);
  }

  String _fmt(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)} L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }

  void _saveCalculation() async {
    final emi = _calcEMI(_calcLoanAmount, _calcRatePercent, _calcTermYears * 12);
    final totalPay = emi * _calcTermYears * 12;
    final totalInt = totalPay - _calcLoanAmount;

    final labelCtrl = TextEditingController(text: 'India Home Loan EMI');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/in_emi_calculator'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save EMI Calc', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving: EMI ${_fmt(emi)}/mo · Amount ${_fmt(_calcLoanAmount)}',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. SBI Home Loan)',
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
              backgroundColor: const Color(0xFFE05F00),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save', style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'Home Loan EMI';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'EMI Calculator',
        inputs: {
          'loanAmount': _calcLoanAmount,
          'rate': _calcRatePercent,
          'termYears': _calcTermYears.toDouble(),
        },
        results: {
          'emi': emi,
          'totalInterest': totalInt,
          'totalPayable': totalPay,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Calculation saved!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF046A38),
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

    final emi = _calcEMI(_calcLoanAmount, _calcRatePercent, _calcTermYears * 12);
    final totalPay = emi * _calcTermYears * 12;
    final totalInt = totalPay - _calcLoanAmount;
    final intRatio = totalPay > 0 ? (totalInt / totalPay) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Card
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.09),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRateStripItem('SBI Rate', '8.50%', 'Floating', isFirst: true),
              _buildRateStripItem('HDFC', '8.70%', 'Floating'),
              _buildRateStripItem('LIC HFL', '8.65%', 'Floating'),
              _buildRateStripItem('Repo Rate', '6.50%', 'RBI 2025'),
            ],
          ),
        ),

        // Input Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.09),
                blurRadius: 20,
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
                  Text('Loan Details', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.w800, letterSpacing: 0.5)),
                  GestureDetector(
                    onTap: _reset,
                    child: Text('Reset ↺', style: AppTextStyles.dmSans(size: 11, color: const Color(0xFFE05F00), weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Loan Amount Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('LOAN AMOUNT', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.w800)),
                  Text(_fmt(_loanAmount), style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: theme.getTextColor(context))),
                ],
              ),
              Slider(
                value: _loanAmount,
                min: 500000,
                max: 10000000,
                divisions: 95,
                activeColor: const Color(0xFFE05F00),
                inactiveColor: const Color(0xFFE05F00).withValues(alpha: 0.15),
                onChanged: (val) => setState(() => _loanAmount = val),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _quickBtn('₹20L', 2000000, _loanAmount, (v) => setState(() => _loanAmount = v)),
                  _quickBtn('₹50L', 5000000, _loanAmount, (v) => setState(() => _loanAmount = v)),
                  _quickBtn('₹75L', 7500000, _loanAmount, (v) => setState(() => _loanAmount = v)),
                  _quickBtn('₹1Cr', 10000000, _loanAmount, (v) => setState(() => _loanAmount = v)),
                ],
              ),
              const SizedBox(height: 16),

              // Interest Rate Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('INTEREST RATE (P.A.)', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.w800)),
                  Text('${_ratePercent.toStringAsFixed(2)}%', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: theme.getTextColor(context))),
                ],
              ),
              Slider(
                value: _ratePercent,
                min: 6.50,
                max: 15.00,
                divisions: 170,
                activeColor: const Color(0xFFE05F00),
                inactiveColor: const Color(0xFFE05F00).withValues(alpha: 0.15),
                onChanged: (val) => setState(() => _ratePercent = val),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _quickBtn('8.50%', 8.50, _ratePercent, (v) => setState(() => _ratePercent = v)),
                  _quickBtn('8.70%', 8.70, _ratePercent, (v) => setState(() => _ratePercent = v)),
                  _quickBtn('9.00%', 9.00, _ratePercent, (v) => setState(() => _ratePercent = v)),
                  _quickBtn('9.50%', 9.50, _ratePercent, (v) => setState(() => _ratePercent = v)),
                ],
              ),
              const SizedBox(height: 16),

              // Tenure Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('LOAN TENURE', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.w800)),
                  Text("$_termYears Year${_termYears > 1 ? 's' : ''}", style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: theme.getTextColor(context))),
                ],
              ),
              Slider(
                value: _termYears.toDouble(),
                min: 1,
                max: 30,
                divisions: 29,
                activeColor: const Color(0xFFE05F00),
                inactiveColor: const Color(0xFFE05F00).withValues(alpha: 0.15),
                onChanged: (val) => setState(() => _termYears = val.toInt()),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _quickBtn('10 Yr', 10, _termYears.toDouble(), (v) => setState(() => _termYears = v.toInt())),
                  _quickBtn('15 Yr', 15, _termYears.toDouble(), (v) => setState(() => _termYears = v.toInt())),
                  _quickBtn('20 Yr', 20, _termYears.toDouble(), (v) => setState(() => _termYears = v.toInt())),
                  _quickBtn('30 Yr', 30, _termYears.toDouble(), (v) => setState(() => _termYears = v.toInt())),
                ],
              ),
              const SizedBox(height: 20),

              // Calculate EMI Button
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasCalculated = true;
                    _calcLoanAmount = _loanAmount;
                    _calcRatePercent = _ratePercent;
                    _calcTermYears = _termYears;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('⚡ EMI calculation updated!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
                      backgroundColor: const Color(0xFF046A38),
                      duration: const Duration(milliseconds: 800),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_resultsKey.currentContext != null) {
                      Scrollable.ensureVisible(
                        _resultsKey.currentContext!,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFFFF6B00).withValues(alpha: 0.4),
                ),
                child: Center(
                  child: Text(
                    '☸ Calculate EMI',
                    style: AppTextStyles.dmSans(
                      size: 14,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_hasCalculated) ...[
          const SizedBox(height: 16),
          // Warning banner if inputs changed
          if (_areInputsChanged())
            Container(
              key: _resultsKey,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: isDark ? 0.2 : 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Text('⚠️ ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(
                      'Inputs changed. Tap Calculate to update results.',
                      style: AppTextStyles.dmSans(size: 11, color: isDark ? Colors.amber[200]! : Colors.amber[900]!, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(key: _resultsKey, height: 0),

          // Result Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
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
                Text('YOUR MONTHLY EMI', style: AppTextStyles.dmSans(size: 9, color: Colors.white60, weight: FontWeight.w700, letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text(
                  NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(emi),
                  style: AppTextStyles.playfair(size: 34, color: const Color(0xFFFFDEA0), weight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _resultBox('Principal', _fmt(_calcLoanAmount)),
                    const SizedBox(width: 8),
                    _resultBox('Total Interest', _fmt(totalInt)),
                    const SizedBox(width: 8),
                    _resultBox('Total Amount', _fmt(totalPay)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Pie (Donut) Chart Breakdown
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📊 Payment Breakdown', style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 16,
                            color: Color(0xFFE05F00),
                          ),
                          CircularProgressIndicator(
                            value: intRatio,
                            strokeWidth: 16,
                            color: const Color(0xFF1A3A8F),
                          ),
                          Text('${(intRatio * 100).round()}%', style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        children: [
                          _buildLegendRow(const Color(0xFFE05F00), 'Principal Amount', _fmt(_calcLoanAmount)),
                          const SizedBox(height: 8),
                          _buildLegendRow(const Color(0xFF1A3A8F), 'Total Interest', _fmt(totalInt)),
                          const SizedBox(height: 8),
                          _buildLegendRow(Colors.grey, 'Interest Ratio', '${(intRatio * 100).round()}% of outgo'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Bank Rate Comparison
          Text('Bank Rate Comparison', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
          const SizedBox(height: 10),
          Column(
            children: _banks.map((b) {
              final bRate = b['rate'] as double;
              final bEmi = _calcEMI(_calcLoanAmount, bRate, _calcTermYears * 12);
              final bTotal = bEmi * _calcTermYears * 12;
              final barW = ((bRate - 8.0) / (10.0 - 8.0)).clamp(0.1, 1.0);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.getCardColor(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.getBorderColor(context)),
                ),
                child: Row(
                  children: [
                    Text(b['icon'] as String, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b['name'] as String, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: theme.getTextColor(context))),
                          Text('EMI ${NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(bEmi)} · Total ${_fmt(bTotal)}',
                              style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context))),
                          const SizedBox(height: 4),
                          Container(
                            height: 4,
                            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2)),
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: barW,
                              child: Container(decoration: BoxDecoration(color: const Color(0xFFE05F00), borderRadius: BorderRadius.circular(2))),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${bRate.toStringAsFixed(2)}%', style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: const Color(0xFFE05F00))),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Save bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
              border: Border.all(color: isDark ? const Color(0xFF065F46) : const Color(0xFF6EE7B7)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Text('💾', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Save This Calculation', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF07543A))),
                      Text('Save details for future reference', style: AppTextStyles.dmSans(size: 10, color: isDark ? Colors.white70 : const Color(0xFF046A38))),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _saveCalculation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF046A38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Save', style: AppTextStyles.dmSans(size: 11, color: Colors.white, weight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _quickBtn(String label, double val, double currentVal, ValueChanged<double> onTap) {
    final active = (val - currentVal).abs() < 0.01;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(val),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFE05F00) : Colors.transparent,
            border: Border.all(color: active ? const Color(0xFFE05F00) : widget.theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
              size: 9.5,
              weight: FontWeight.w700,
              color: active ? Colors.white : widget.theme.getMutedColor(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 9, color: Colors.white60)),
            const SizedBox(height: 2),
            Text(value, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendRow(Color color, String label, String value) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w700, color: widget.theme.getTextColor(context))),
              Text(value, style: AppTextStyles.dmSans(size: 9, color: widget.theme.getMutedColor(context))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRateStripItem(String label, String value, String subtitle, {bool isFirst = false}) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: isFirst
              ? null
              : const Border(
                  left: BorderSide(color: Colors.white12, width: 1.0),
                ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.dmSans(
                size: 8,
                color: Colors.white60,
                weight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTextStyles.dmSans(
                size: 14,
                color: const Color(0xFFFFDEA0),
                weight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.dmSans(
                size: 8,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
