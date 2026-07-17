// lib/features/india/tools/in_prepayment_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class INPrepaymentCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INPrepaymentCalc({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INPrepaymentCalc> createState() => _INPrepaymentCalcState();
}

class _INPrepaymentCalcState extends ConsumerState<INPrepaymentCalc> {
  late TextEditingController _loanController;
  late TextEditingController _rateController;
  late TextEditingController _tenureController;
  late TextEditingController _prepayController;

  String _goal = 'tenure'; // 'tenure', 'emi'

  bool _hasCalculated = false;
  double _calcLoan = 4500000;
  double _calcRate = 8.50;
  int _calcTenure = 18;
  double _calcPrepay = 500000;
  String _calcGoal = 'tenure';
  final GlobalKey _resultsKey = GlobalKey();

  bool _loanError = false;
  bool _rateError = false;
  bool _tenureError = false;
  bool _prepayError = false;

  @override
  void initState() {
    super.initState();
    _loanController = TextEditingController(text: '4500000');
    _rateController = TextEditingController(text: '8.50');
    _tenureController = TextEditingController(text: '18');
    _prepayController = TextEditingController(text: '500000');

    // Add listeners to trigger state updates for inputs
    _loanController.addListener(_onInputChanged);
    _rateController.addListener(_onInputChanged);
    _tenureController.addListener(_onInputChanged);
    _prepayController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _loanController.removeListener(_onInputChanged);
    _rateController.removeListener(_onInputChanged);
    _tenureController.removeListener(_onInputChanged);
    _prepayController.removeListener(_onInputChanged);

    _loanController.dispose();
    _rateController.dispose();
    _tenureController.dispose();
    _prepayController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    setState(() {});
  }

  bool _areInputsChanged() {
    final loan = double.tryParse(_loanController.text.replaceAll(',', '')) ?? 0.0;
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    final tenure = int.tryParse(_tenureController.text) ?? 0;
    final prepay = double.tryParse(_prepayController.text.replaceAll(',', '')) ?? 0.0;
    return loan != _calcLoan ||
        rate != _calcRate ||
        tenure != _calcTenure ||
        prepay != _calcPrepay ||
        _goal != _calcGoal;
  }

  void _reset() {
    setState(() {
      _loanController.text = '4500000';
      _rateController.text = '8.50';
      _tenureController.text = '18';
      _prepayController.text = '500000';
      _goal = 'tenure';
      _hasCalculated = false;
      _calcLoan = 4500000;
      _calcRate = 8.50;
      _calcTenure = 18;
      _calcPrepay = 500000;
      _calcGoal = 'tenure';
      _loanError = false;
      _rateError = false;
      _tenureError = false;
      _prepayError = false;
    });
  }

  double _calcEMI(double p, double r, int n) {
    if (r <= 0 || n <= 0) return 0.0;
    final double power = pow(1 + r, n).toDouble();
    if (power <= 1.0) return 0.0;
    return p * r * power / (power - 1);
  }

  String _fmt(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)} Lakh';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }

  String _fmtShort(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)}Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)}L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }

  void _saveCalculation() async {
    final loan = _calcLoan;
    final rate = _calcRate;
    final tenure = _calcTenure;
    final prepay = _calcPrepay;

    final r = rate / 12 / 100;
    final n = tenure * 12;
    final emi = _calcEMI(loan, r, n);
    final totalBefore = emi * n;
    final intBefore = totalBefore - loan;
    final newLoan = loan - prepay;
    double newEmi, newN, intAfter;

    if (_calcGoal == 'tenure') {
      newEmi = emi;
      final double fraction = newEmi - newLoan * r;
      if (fraction > 0 && newEmi > 0) {
        newN = log(newEmi / fraction) / log(1 + r);
      } else {
        newN = n.toDouble();
      }
      intAfter = newEmi * newN - newLoan;
    } else {
      newN = n.toDouble();
      newEmi = _calcEMI(newLoan, r, n);
      intAfter = newEmi * newN - newLoan;
    }
    final intSaved = intBefore - intAfter;

    final labelCtrl = TextEditingController(text: 'Prepayment Plan');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/in_prepayment_calc'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Prepayment Plan', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving: Interest saved ${_fmt(intSaved)} · Prepay ${_fmt(prepay)}',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My Prepayment Goal)',
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
              backgroundColor: const Color(0xFFFF6B00),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save', style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'Prepayment Plan';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'Prepayment Calc',
        inputs: {
          'loan': loan,
          'rate': rate,
          'tenure': tenure.toDouble(),
          'prepay': prepay,
          'goal': _calcGoal == 'tenure' ? 0.0 : 1.0,
        },
        results: {
          'interestSaved': intSaved,
          'newEmi': newEmi,
          'newTenure': newN / 12,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Prepayment calculation saved!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
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

    final loan = double.tryParse(_loanController.text) ?? 0.0;
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    final tenure = int.tryParse(_tenureController.text) ?? 1;
    final prepay = double.tryParse(_prepayController.text) ?? 0.0;

    final calcLoan = _calcLoan;
    final calcRate = _calcRate;
    final calcTenure = _calcTenure;
    final calcPrepay = _calcPrepay;

    final r = calcRate / 12 / 100;
    final n = calcTenure * 12;
    final emi = _calcEMI(calcLoan, r, n);
    final totalBefore = emi * n;
    final intBefore = totalBefore - calcLoan;
    final newLoan = (calcLoan - calcPrepay).clamp(0.0, calcLoan);
    double newEmi, newN, intAfter, totalAfter;

    if (_calcGoal == 'tenure') {
      newEmi = emi;
      final double fraction = newEmi - newLoan * r;
      if (fraction > 0 && newEmi > 0) {
        newN = log(newEmi / fraction) / log(1 + r);
      } else {
        newN = n.toDouble();
      }
      intAfter = newEmi * newN - newLoan;
      totalAfter = newLoan + intAfter + calcPrepay;
    } else {
      newN = n.toDouble();
      newEmi = _calcEMI(newLoan, r, n);
      intAfter = newEmi * newN - newLoan;
      totalAfter = newLoan + intAfter + calcPrepay;
    }

    final intSaved = (intBefore - intAfter).clamp(0.0, intBefore);
    final yearsSaved = ((n - newN) / 12).clamp(0.0, calcTenure.toDouble());
    final roiMultiplier = calcPrepay > 0 && (totalBefore - totalAfter) > 0 ? (totalBefore - totalAfter) / calcPrepay : 0.0;

    final now = DateTime.now();
    final formatMonthYear = DateFormat('MMM yyyy');
    final befDateStr = formatMonthYear.format(DateTime(now.year, now.month + n));
    final aftDateStr = formatMonthYear.format(DateTime(now.year, now.month + newN.round()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Rate Strip Card
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
              _buildRateStripItem('SBI Prepay', 'NIL', 'Floating', isFirst: true),
              _buildRateStripItem('Fixed Rate', '2%', 'Penalty'),
              _buildRateStripItem('RBI Rule', 'Free', 'Floating loans'),
              _buildRateStripItem('Save', 'Interest', 'Early'),
            ],
          ),
        ),

        // Section label
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Current Loan Details', style: AppTextStyles.sectionLabel(theme.getMutedColor(context))),
              GestureDetector(
                onTap: _reset,
                child: Text('Reset ↺', style: AppTextStyles.dmSans(size: 11, color: const Color(0xFFFF6B00), weight: FontWeight.w700)),
              ),
            ],
          ),
        ),

        // Inputs Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Outstanding Balance
              _buildSyncSliderRow(
                title: 'Outstanding Loan Balance',
                controller: _loanController,
                min: 500000,
                max: 10000000,
                divisions: 95,
                displayValue: _fmtShort(loan),
                hasError: _loanError,
              ),
              const SizedBox(height: 16),

              // Interest Rate
              _buildSyncSliderRow(
                title: 'Interest Rate (% p.a.)',
                controller: _rateController,
                min: 6.50,
                max: 15.00,
                divisions: 170,
                displayValue: '${rate.toStringAsFixed(2)}%',
                hasError: _rateError,
              ),
              const SizedBox(height: 16),

              // Remaining Tenure
              _buildSyncSliderRow(
                title: 'Remaining Tenure (Years)',
                controller: _tenureController,
                min: 1,
                max: 30,
                divisions: 29,
                displayValue: '$tenure yr',
                hasError: _tenureError,
              ),
              const SizedBox(height: 16),

              // Prepayment Amount
              _buildSyncSliderRow(
                title: 'Prepayment Amount',
                controller: _prepayController,
                min: 100000,
                max: 5000000,
                divisions: 98,
                displayValue: _fmtShort(prepay),
                hasError: _prepayError,
              ),
              const SizedBox(height: 16),

              // Prepayment Goal
              Text('PREPAYMENT GOAL', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.w800)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildToggleBtn(
                      '🕐 Reduce Tenure',
                      _goal == 'tenure',
                      () => setState(() => _goal = 'tenure'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildToggleBtn(
                      '📉 Reduce EMI',
                      _goal == 'emi',
                      () => setState(() => _goal = 'emi'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Calculate Button
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loanError = false;
                    _rateError = false;
                    _tenureError = false;
                    _prepayError = false;
                  });

                  final loanVal = double.tryParse(_loanController.text.replaceAll(',', ''));
                  final rateVal = double.tryParse(_rateController.text);
                  final tenureVal = int.tryParse(_tenureController.text);
                  final prepayVal = double.tryParse(_prepayController.text.replaceAll(',', ''));

                  bool hasErr = false;
                  if (loanVal == null || loanVal <= 0) {
                    setState(() => _loanError = true);
                    hasErr = true;
                  }
                  if (rateVal == null || rateVal <= 0 || rateVal > 100) {
                    setState(() => _rateError = true);
                    hasErr = true;
                  }
                  if (tenureVal == null || tenureVal <= 0 || tenureVal > 40) {
                    setState(() => _tenureError = true);
                    hasErr = true;
                  }
                  if (prepayVal == null || prepayVal <= 0 || (loanVal != null && prepayVal > loanVal)) {
                    setState(() => _prepayError = true);
                    hasErr = true;
                  }

                  if (hasErr) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('⚠️ Please correct the invalid fields in red.', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
                        backgroundColor: Colors.red[800],
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  setState(() {
                    _hasCalculated = true;
                    _calcLoan = loanVal!;
                    _calcRate = rateVal!;
                    _calcTenure = tenureVal!;
                    _calcPrepay = prepayVal!;
                    _calcGoal = _goal;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('⚡ Prepayment computed!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
                      backgroundColor: const Color(0xFF046A38),
                      duration: const Duration(milliseconds: 600),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                  shadowColor: const Color(0xFFFF6B00).withValues(alpha: 0.4),
                ),
                child: Center(
                  child: Text(
                    '☸ Calculate Savings',
                    style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_hasCalculated) ...[
          const SizedBox(height: 20),
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

          // Savings Hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF046A38), Color(0xFF07543A)],
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
                Text(
                  'TOTAL INTEREST SAVED BY PREPAYMENT',
                  style: AppTextStyles.dmSans(size: 9, color: Colors.white60, weight: FontWeight.w700, letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),
                Text(
                  _fmt(intSaved),
                  style: AppTextStyles.dmSans(size: 34, weight: FontWeight.w800, color: const Color(0xFF86EFAC)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildFoirBox('Years Saved', yearsSaved > 0 ? '${yearsSaved.toStringAsFixed(1)} Yrs' : '0 Yrs'),
                    const SizedBox(width: 8),
                    _buildFoirBox('New EMI', "₹${NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(newEmi)}"),
                    const SizedBox(width: 8),
                    _buildFoirBox('ROI on Prepay', '${roiMultiplier.toStringAsFixed(1)}x'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Before vs After Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📋 Before vs After Prepayment', style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context))),
                const SizedBox(height: 14),
                Row(
                  children: [
                    // Without Prepay
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),
                              child: Text('WITHOUT PREPAY', style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w800, color: const Color(0xFFEF4444))),
                            ),
                            const SizedBox(height: 12),
                            _buildCompareItem('Monthly EMI', "₹${NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(emi)}"),
                            _buildCompareItem('Remaining Int', _fmtShort(intBefore)),
                            _buildCompareItem('Total Outgo', _fmtShort(totalBefore)),
                            _buildCompareItem('Close Date', befDateStr),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // With Prepay
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          border: Border.all(color: const Color(0xFF6EE7B7), width: 1.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(4)),
                              child: Text('WITH PREPAYMENT', style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w800, color: const Color(0xFF046A38))),
                            ),
                            const SizedBox(height: 12),
                            _buildCompareItem('Monthly EMI', "₹${NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(newEmi)}", isDarker: true),
                            _buildCompareItem('Remaining Int', _fmtShort(intAfter), isDarker: true),
                            _buildCompareItem('Total Outgo', _fmtShort(totalAfter), isDarker: true),
                            _buildCompareItem('Close Date', aftDateStr, isDarker: true),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Prepayment Strategy Tips
          Text('Prepayment Strategy Tips', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _buildTipBox('📅', 'Prepay Early', 'Prepaying in yr 1–5 saves 3× more interest than yr 15–20'),
              _buildTipBox('💵', 'Annual Bonus', 'Use annual bonus/increment for partial prepayment every year'),
              _buildTipBox('🔄', 'Step-up EMI', 'Increase EMI by 5% each year matching income growth'),
              _buildTipBox('🏦', 'No Penalty', 'RBI mandates zero prepayment penalty on floating rate loans'),
            ],
          ),

          const SizedBox(height: 20),

          // Save Bar
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
                      Text('Save Prepayment Plan', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF07543A))),
                      Text('Save interest savings analysis', style: AppTextStyles.dmSans(size: 10, color: isDark ? Colors.white70 : const Color(0xFF046A38))),
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

  // --- Widget Builders ---

  Widget _buildSyncSliderRow({
    required String title,
    required TextEditingController controller,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    bool hasError = false,
  }) {
    final theme = widget.theme;
    final currentVal = double.tryParse(controller.text) ?? min;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFF5E6D4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title.toUpperCase(),
              style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context), weight: FontWeight.w800),
            ),
            Text(
              displayValue,
              style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  activeTrackColor: const Color(0xFFFF6B00),
                  inactiveTrackColor: inactiveColor,
                  thumbColor: const Color(0xFFFF6B00),
                  overlayColor: const Color(0xFFFF6B00).withValues(alpha: 0.15),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                ),
                child: Slider(
                  value: currentVal.clamp(min, max),
                  min: min,
                  max: max,
                  divisions: divisions,
                  onChanged: (val) {
                    setState(() {
                      controller.text = min is int ? val.round().toString() : val.toStringAsFixed(2);
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              height: 32,
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: theme.getTextColor(context)),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  filled: true,
                  fillColor: theme.getBgColor(context),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: hasError ? Colors.red : theme.getBorderColor(context),
                      width: hasError ? 1.5 : 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(
                      color: hasError ? Colors.red : const Color(0xFFFF6B00),
                      width: hasError ? 2.0 : 1.5,
                    ),
                  ),
                ),
                onSubmitted: (val) {
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFF6B00) : Colors.transparent,
          border: Border.all(color: active ? const Color(0xFFFF6B00) : widget.theme.getBorderColor(context)),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 11.5,
            weight: FontWeight.w700,
            color: active ? Colors.white : widget.theme.getMutedColor(context),
          ),
        ),
      ),
    );
  }

  Widget _buildFoirBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white70)),
            const SizedBox(height: 3),
            Text(
              value,
              style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompareItem(String label, String value, {bool isDarker = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(size: 8.5, color: isDarker ? const Color(0xFF046A38) : const Color(0xFFC62828)),
          ),
          Text(
            value,
            style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: const Color(0xFF0B1F48)),
          ),
        ],
      ),
    );
  }

  Widget _buildTipBox(String emoji, String title, String desc) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        border: Border.all(color: theme.getBorderColor(context)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            title,
            style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: theme.getTextColor(context)),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Text(
              desc,
              style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context)),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
                size: 13,
                color: const Color(0xFFFFDEA0),
                weight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
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
