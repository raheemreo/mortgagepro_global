// lib/features/india/tools/in_80c_24b_guide.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class IN80C24BGuide extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const IN80C24BGuide({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<IN80C24BGuide> createState() => _IN80C24BGuideState();
}

class _IN80C24BGuideState extends ConsumerState<IN80C24BGuide> {
  double _grossIncome = 15.0; // In lakhs
  double _principalPaid = 1.5; // In lakhs
  double _interestPaid = 2.5; // In lakhs
  double _other80C = 0.5; // In lakhs
  bool _isFirstHome = false;

  double _calcOldRegimeTax(double income, double deductions) {
    double taxable = max(income - deductions - 0.5, 0.0); // 50,000 standard deduction
    double tax = 0.0;

    if (taxable <= 2.5) return 0.0;

    if (taxable <= 5.0) {
      tax = (taxable - 2.5) * 0.05;
      // Section 87A rebate
      if (taxable <= 5.0) tax = 0.0;
    } else if (taxable <= 10.0) {
      tax = 0.125 + (taxable - 5.0) * 0.20; // 5% of 2.5L is 12,500
    } else {
      tax = 0.125 + 1.0 + (taxable - 10.0) * 0.30; // 20% of 5L is 1L
    }

    return tax * 1.04; // 4% cess
  }

  double _calcNewRegimeTax(double income) {
    double taxable = max(income - 0.75, 0.0); // 75,000 standard deduction
    double tax = 0.0;

    if (taxable <= 3.0) return 0.0;

    if (taxable <= 7.0) {
      tax = (taxable - 3.0) * 0.05;
      // Section 87A rebate for income up to 7L (under new tax regime)
      if (taxable <= 7.0) tax = 0.0;
    } else if (taxable <= 10.0) {
      tax = 0.20 + (taxable - 7.0) * 0.10; // 5% of 4L is 20,000
    } else if (taxable <= 12.0) {
      tax = 0.20 + 0.30 + (taxable - 10.0) * 0.15; // 10% of 3L is 30,000
    } else if (taxable <= 15.0) {
      tax = 0.20 + 0.30 + 0.30 + (taxable - 12.0) * 0.20; // 15% of 2L is 30,000
    } else {
      tax = 0.20 + 0.30 + 0.30 + 0.60 + (taxable - 15.0) * 0.30; // 20% of 3L is 60,000
    }

    return tax * 1.04; // 4% cess
  }

  void _saveTaxCalc() async {
    final labelCtrl = TextEditingController(text: 'Home Loan Tax Benefits');

    // Math outputs
    const limit80C = 1.5;
    final allowed80C = min(_principalPaid + _other80C, limit80C);
    final allowed24b = min(_interestPaid, 2.0);
    final allowed80EEA = _isFirstHome ? min(max(_interestPaid - 2.0, 0.0), 1.5) : 0.0;
    final totalDeductions = allowed80C + allowed24b + allowed80EEA;

    final taxOld = _calcOldRegimeTax(_grossIncome, totalDeductions);
    final taxNew = _calcNewRegimeTax(_grossIncome);
    final taxSavings = max(taxNew - taxOld, 0.0);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Tax Calculation', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving Tax Benefit summary: ₹${(taxSavings).toStringAsFixed(2)}L annual saving',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. FY2026 Home Loan Tax)',
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
              backgroundColor: const Color(0xFF046A38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save', style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'Home Loan Tax Benefit';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'Section 80C & 24(b) Guide',
        inputs: {
          'grossIncome': _grossIncome * 100000,
          'principalPaid': _principalPaid * 100000,
          'interestPaid': _interestPaid * 100000,
          'other80C': _other80C * 100000,
          'isFirstHome': _isFirstHome ? 1.0 : 0.0,
        },
        results: {
          'totalDeductions': totalDeductions * 100000,
          'taxOld': taxOld * 100000,
          'taxNew': taxNew * 100000,
          'taxSavings': taxSavings * 100000,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Tax calculation saved successfully!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
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

    // Tax calculation math
    const limit80C = 1.5;
    final total80CPaid = _principalPaid + _other80C;
    final allowed80C = min(total80CPaid, limit80C);
    final allowed24b = min(_interestPaid, 2.0);
    final allowed80EEA = _isFirstHome ? min(max(_interestPaid - 2.0, 0.0), 1.5) : 0.0;
    final totalDeductions = allowed80C + allowed24b + allowed80EEA;

    final taxOld = _calcOldRegimeTax(_grossIncome, totalDeductions);
    final taxNew = _calcNewRegimeTax(_grossIncome);
    final taxSavings = max(taxNew - taxOld, 0.0);

    // Percentage for Donut visual
    const double totalMaxDeduction = 5.0; // 80C(1.5) + 24b(2.0) + 80EEA(1.5)
    final double pctDeduction = (totalDeductions / totalMaxDeduction * 100).clamp(1.0, 100.0);

    final numFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Info
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B00),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoCell('Sec 24(b)', '₹2.0L Max', 'Interest Ded.', isSaffron: true),
              _infoCell('Sec 80C', '₹1.5L Max', 'Principal Ded.', isSaffron: true),
              _infoCell('Sec 80EEA', '₹1.5L Extra', 'First-Home'),
              _infoCell('Regimes', 'Old vs New', 'Tax Comparison'),
            ],
          ),
        ),

        // Hero Card
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 16),
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
              Text('INCOME TAX DEDUCTIONS · FY 2025-26',
                  style: AppTextStyles.dmSans(size: 8.5, color: Colors.white.withValues(alpha: 0.6), weight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Home Loan Tax Guide & Slabs',
                  style: AppTextStyles.playfair(size: 18, color: Colors.white, weight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Maximize deductions u/s 80C, 24(b), and 80EEA on interest and principal',
                  style: AppTextStyles.dmSans(size: 10, color: Colors.white.withValues(alpha: 0.7))),
              const SizedBox(height: 14),
              Row(
                children: [
                  _hBox('Interest Limit', '₹2,00,000', 'Self-Occupied'),
                  const SizedBox(width: 8),
                  _hBox('Principal Limit', '₹1,50,000', 'Under Sec 80C'),
                  const SizedBox(width: 8),
                  _hBox('First Buyer', '₹1,50,000', 'Sec 80EEA (Extra)'),
                ],
              )
            ],
          ),
        ),

        // Tax Savings Banner
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            border: Border.all(color: const Color(0xFF6EE7B7), width: 1.5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('YOUR HOME LOAN TAX ANNUAL SAVINGS',
                  style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF07543A), weight: FontWeight.w800, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text('₹${(taxSavings * 100000).toStringAsFixed(0)} /yr',
                  style: AppTextStyles.playfair(size: 30, color: const Color(0xFF07543A), weight: FontWeight.w800)),
              Text('Saved under Old Regime with total deductions of ${numFormat.format(totalDeductions * 100000)}',
                  style: AppTextStyles.dmSans(size: 10, color: const Color(0xFF046A38))),
              const SizedBox(height: 14),
              Row(
                children: [
                  _resBox('Tax (Old Regime)', numFormat.format(taxOld * 100000)),
                  const SizedBox(width: 8),
                  _resBox('Tax (New Regime)', numFormat.format(taxNew * 100000)),
                ],
              ),
            ],
          ),
        ),

        // Inputs Card
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tax Benefits Inputs', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: theme.getTextColor(context))),
              const SizedBox(height: 16),
              _buildSliderRow('GROSS ANNUAL INCOME (₹ LAKH)', _grossIncome, 2.5, 50.0, 95, (v) => setState(() => _grossIncome = v)),
              const SizedBox(height: 12),
              _buildSliderRow('HOME LOAN INTEREST PAID (₹ LAKH)', _interestPaid, 0.0, 8.0, 80, (v) => setState(() => _interestPaid = v)),
              const SizedBox(height: 12),
              _buildSliderRow('HOME LOAN PRINCIPAL PAID (₹ LAKH)', _principalPaid, 0.0, 3.0, 30, (v) => setState(() => _principalPaid = v)),
              const SizedBox(height: 12),
              _buildSliderRow('OTHER 80C DEDUCTIONS (₹ LAKH)', _other80C, 0.0, 2.0, 20, (v) => setState(() => _other80C = v)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FIRST TIME HOME BUYER (SEC 80EEA)',
                          style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: theme.getTextColor(context))),
                      Text('Extra ₹1.5L deduction on interest',
                          style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                    ],
                  ),
                  Switch(
                    value: _isFirstHome,
                    activeThumbColor: const Color(0xFF046A38),
                    activeTrackColor: const Color(0xFF046A38).withValues(alpha: 0.5),
                    onChanged: (v) => setState(() => _isFirstHome = v),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Deduction donut visual
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Deductions Breakdown (Old Regime)',
                  style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: theme.getTextColor(context))),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CustomPaint(
                      painter: _DeductionDonutPainter(pct: pctDeduction),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _legendRow(const Color(0xFF046A38), 'Sec 24(b) Allowed', numFormat.format(allowed24b * 100000)),
                        const SizedBox(height: 4),
                        _legendRow(const Color(0xFFFF6B00), 'Sec 80C Allowed', numFormat.format(allowed80C * 100000)),
                        const SizedBox(height: 4),
                        _legendRow(const Color(0xFF1A3A8F), 'Sec 80EEA Allowed', numFormat.format(allowed80EEA * 100000)),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _saveTaxCalc,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF046A38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.save, color: Colors.white, size: 16),
                  label: Text('Save Tax Calculation', style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),

        // Quick Slabs Table
        Text('Tax Slab Breakdown (New Regime vs Old)', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Table(
            border: TableBorder(horizontalInside: BorderSide(color: theme.getBorderColor(context).withValues(alpha: 0.5))),
            children: [
              TableRow(
                children: [
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Income Range', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: theme.getTextColor(context)))),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Old Rate (With Ded.)', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: theme.getTextColor(context)))),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('New Rate (No Ded.)', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: theme.getTextColor(context)))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Up to ₹3.0 Lakh', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)))),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Nil', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)))),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Nil', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('₹3.0L – ₹7.0 Lakh', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)))),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('5% (>₹2.5L)', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)))),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('5% (Rebate up to 7L)', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('₹7.0L – ₹10.0 Lakh', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)))),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('20% (>₹5L)', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)))),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('10%', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('₹10.0L – ₹12.0 Lakh', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)))),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('30%', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)))),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('15%', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)))),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Above ₹15.0 Lakh', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)))),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('30%', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)))),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('30%', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)))),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoCell(String label, String value, String note, {bool isSaffron = false, bool isGreen = false}) {
    Color valColor = Colors.white;
    if (isSaffron) {
      valColor = const Color(0xFFFFDEA0);
    } else if (isGreen) {
      valColor = const Color(0xFF86EFAC);
    }
    return Column(
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white.withValues(alpha: 0.55), weight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(value, style: AppTextStyles.dmSans(size: 13, color: valColor, weight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(note, style: AppTextStyles.dmSans(size: 8, color: Colors.white.withValues(alpha: 0.4))),
      ],
    );
  }

  Widget _hBox(String label, String val, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.09),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white54)),
            const SizedBox(height: 2),
            Text(val, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 1),
            Text(sub, style: AppTextStyles.dmSans(size: 7, color: const Color(0xFFFFDEA0))),
          ],
        ),
      ),
    );
  }

  Widget _resBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF046A38).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 8, color: const Color(0xFF046A38))),
            const SizedBox(height: 2),
            Text(value, style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: const Color(0xFF07543A))),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow(String title, double val, double min, double max, int div, ValueChanged<double> onChanged) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context), weight: FontWeight.w800)),
            Text('${val.toStringAsFixed(1)} Lakh',
                style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
          ],
        ),
        Slider(
          value: val.clamp(min, max),
          min: min,
          max: max,
          divisions: div,
          activeColor: const Color(0xFFFF6B00),
          inactiveColor: const Color(0xFFFF6B00).withValues(alpha: 0.15),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _legendRow(Color color, String label, String value) {
    final theme = widget.theme;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.dmSans(size: 10, color: theme.getTextColor(context))),
        const Spacer(),
        Text(value, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: theme.getTextColor(context))),
      ],
    );
  }
}

class _DeductionDonutPainter extends CustomPainter {
  final double pct;
  _DeductionDonutPainter({required this.pct});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 4;

    final basePaint = Paint()
      ..color = const Color(0xFFF3E8D0)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    final activePaint = Paint()
      ..color = const Color(0xFF046A38)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, basePaint);

    final sweepAngle = 2 * pi * (pct / 100.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      activePaint,
    );

    // Text in center
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${pct.toStringAsFixed(0)}%',
        style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: const Color(0xFF07543A)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _DeductionDonutPainter oldDelegate) => oldDelegate.pct != pct;
}
