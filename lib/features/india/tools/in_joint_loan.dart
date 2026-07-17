// lib/features/india/tools/in_joint_loan.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class INJointLoan extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INJointLoan({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INJointLoan> createState() => _INJointLoanState();
}

class _INJointLoanState extends ConsumerState<INJointLoan> {
  late TextEditingController _inc1Controller;
  late TextEditingController _emi1Controller;
  late TextEditingController _cibil1Controller;

  late TextEditingController _inc2Controller;
  late TextEditingController _emi2Controller;
  late TextEditingController _cibil2Controller;

  late TextEditingController _rateController;
  late TextEditingController _tenureController;

  bool _inc1Error = false;
  bool _emi1Error = false;
  bool _cibil1Error = false;
  bool _inc2Error = false;
  bool _emi2Error = false;
  bool _cibil2Error = false;
  bool _rateError = false;
  bool _tenureError = false;

  bool _hasCalculated = false;
  double _calcInc1 = 120000;
  double _calcEmi1 = 8000;
  double _calcCibil1 = 780;
  double _calcInc2 = 85000;
  double _calcEmi2 = 3000;
  double _calcCibil2 = 740;
  double _calcRate = 8.50;
  int _calcTenure = 20;
  final GlobalKey _resultsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _inc1Controller = TextEditingController(text: '120000');
    _emi1Controller = TextEditingController(text: '8000');
    _cibil1Controller = TextEditingController(text: '780');

    _inc2Controller = TextEditingController(text: '85000');
    _emi2Controller = TextEditingController(text: '3000');
    _cibil2Controller = TextEditingController(text: '740');

    _rateController = TextEditingController(text: '8.50');
    _tenureController = TextEditingController(text: '20');

    _inc1Controller.addListener(_onInputChanged);
    _emi1Controller.addListener(_onInputChanged);
    _cibil1Controller.addListener(_onInputChanged);

    _inc2Controller.addListener(_onInputChanged);
    _emi2Controller.addListener(_onInputChanged);
    _cibil2Controller.addListener(_onInputChanged);

    _rateController.addListener(_onInputChanged);
    _tenureController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _inc1Controller.removeListener(_onInputChanged);
    _emi1Controller.removeListener(_onInputChanged);
    _cibil1Controller.removeListener(_onInputChanged);

    _inc2Controller.removeListener(_onInputChanged);
    _emi2Controller.removeListener(_onInputChanged);
    _cibil2Controller.removeListener(_onInputChanged);

    _rateController.removeListener(_onInputChanged);
    _tenureController.removeListener(_onInputChanged);

    _inc1Controller.dispose();
    _emi1Controller.dispose();
    _cibil1Controller.dispose();

    _inc2Controller.dispose();
    _emi2Controller.dispose();
    _cibil2Controller.dispose();

    _rateController.dispose();
    _tenureController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    setState(() {});
  }

  bool _areInputsChanged() {
    final i1 = double.tryParse(_inc1Controller.text.replaceAll(',', '')) ?? 0.0;
    final e1 = double.tryParse(_emi1Controller.text.replaceAll(',', '')) ?? 0.0;
    final c1 = double.tryParse(_cibil1Controller.text) ?? 0.0;
    final i2 = double.tryParse(_inc2Controller.text.replaceAll(',', '')) ?? 0.0;
    final e2 = double.tryParse(_emi2Controller.text.replaceAll(',', '')) ?? 0.0;
    final c2 = double.tryParse(_cibil2Controller.text) ?? 0.0;
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    final tenure = int.tryParse(_tenureController.text) ?? 1;

    return i1 != _calcInc1 ||
        e1 != _calcEmi1 ||
        c1 != _calcCibil1 ||
        i2 != _calcInc2 ||
        e2 != _calcEmi2 ||
        c2 != _calcCibil2 ||
        rate != _calcRate ||
        tenure != _calcTenure;
  }

  void _reset() {
    setState(() {
      _inc1Controller.text = '120000';
      _emi1Controller.text = '8000';
      _cibil1Controller.text = '780';

      _inc2Controller.text = '85000';
      _emi2Controller.text = '3000';
      _cibil2Controller.text = '740';

      _rateController.text = '8.50';
      _tenureController.text = '20';

      _hasCalculated = false;
      _inc1Error = false;
      _emi1Error = false;
      _cibil1Error = false;
      _inc2Error = false;
      _emi2Error = false;
      _cibil2Error = false;
      _rateError = false;
      _tenureError = false;

      _calcInc1 = 120000;
      _calcEmi1 = 8000;
      _calcCibil1 = 780;
      _calcInc2 = 85000;
      _calcEmi2 = 3000;
      _calcCibil2 = 740;
      _calcRate = 8.50;
      _calcTenure = 20;
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
    final i1 = _calcInc1;
    final i2 = _calcInc2;
    final e1 = _calcEmi1;
    final e2 = _calcEmi2;
    final rate = _calcRate;
    final tenure = _calcTenure;

    final r = rate / 12 / 100;
    final n = tenure * 12;
    const maxFoir = 0.50;

    final cap1 = i1 * maxFoir - e1;
    final capJ = (i1 + i2) * maxFoir - (e1 + e2);

    final factor = r > 0 ? (pow(1 + r, n) - 1) / (r * pow(1 + r, n)) : 0.0;
    final soloLoan = max(cap1 * factor, 0.0);
    final jointLoan = max(capJ * factor, 0.0);
    final benefit = jointLoan - soloLoan;

    final labelCtrl = TextEditingController(text: 'Joint Loan Benefit');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/in_joint_loan'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Joint Report', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving: Joint Loan ${_fmt(jointLoan)} · Benefit ${_fmt(benefit)}',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Joint Home Purchase)',
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
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'Joint Loan Benefit';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'Joint Loan Calc',
        inputs: {
          'inc1': i1,
          'emi1': e1,
          'cibil1': _calcCibil1,
          'inc2': i2,
          'emi2': e2,
          'cibil2': _calcCibil2,
          'rate': rate,
          'tenure': tenure.toDouble(),
        },
        results: {
          'jointLoan': jointLoan,
          'soloLoan': soloLoan,
          'benefit': benefit,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Joint report saved!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
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

    final i1 = double.tryParse(_inc1Controller.text.replaceAll(',', '')) ?? 0.0;
    final i2 = double.tryParse(_inc2Controller.text.replaceAll(',', '')) ?? 0.0;
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    final tenure = int.tryParse(_tenureController.text) ?? 1;

    final calcInc1 = _calcInc1;
    final calcInc2 = _calcInc2;
    final calcEmi1 = _calcEmi1;
    final calcEmi2 = _calcEmi2;
    final calcRate = _calcRate;
    final calcTenure = _calcTenure;

    final r = calcRate / 12 / 100;
    final n = calcTenure * 12;
    const maxFoir = 0.50;

    final cap1 = calcInc1 * maxFoir - calcEmi1;
    final capJ = (calcInc1 + calcInc2) * maxFoir - (calcEmi1 + calcEmi2);

    final factor = r > 0 ? (pow(1 + r, n) - 1) / (r * pow(1 + r, n)) : 0.0;
    final soloLoan = max(cap1 * factor, 0.0);
    final jointLoan = max(capJ * factor, 0.0);
    final benefit = max(jointLoan - soloLoan, 0.0);
    final jointEmi = _calcEMI(jointLoan, r, n);

    final totalIncome = calcInc1 + calcInc2;
    final double pct1 = totalIncome > 0 ? (calcInc1 / totalIncome) : 0.0;
    final double pct2 = totalIncome > 0 ? 1.0 - pct1 : 0.0;

    final f1 = calcInc1 > 0 ? ((calcEmi1 + jointEmi / 2) / calcInc1 * 100).round() : 0;
    final f2 = calcInc2 > 0 ? ((calcEmi2 + jointEmi / 2) / calcInc2 * 100).round() : 0;
    final fj = totalIncome > 0 ? ((calcEmi1 + calcEmi2 + jointEmi) / totalIncome * 100).round() : 0;

    final hasCoApp = calcInc2 > 0;
    final totalTaxDeduction = 150000 + (hasCoApp ? 150000 : 0) + 200000 + (hasCoApp ? 200000 : 0);

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
              _buildRateStripItem('Repo Rate', '6.25%', "RBI Jun'25", isFirst: true),
              _buildRateStripItem('FOIR Limit', '50%', 'RBI Guideline'),
              _buildRateStripItem('Sec 80C', '₹1.5L', 'Each'),
              _buildRateStripItem('Sec 24(b)', '₹2L', 'Each'),
            ],
          ),
        ),

        // Section label
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Primary Applicant & Co-Applicant Setup', style: AppTextStyles.sectionLabel(theme.getMutedColor(context))),
              GestureDetector(
                onTap: _reset,
                child: Text('Reset ↺', style: AppTextStyles.dmSans(size: 11, color: const Color(0xFFFF6B00), weight: FontWeight.w700)),
              ),
            ],
          ),
        ),

        // Split Inputs Card
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
              // Primary Applicant Section
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)]),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: const Text('👤', style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Primary Applicant',
                    style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Primary Gross Income
              _buildSyncSliderRow(
                title: 'Monthly Gross Income (₹)',
                controller: _inc1Controller,
                min: 20000,
                max: 500000,
                divisions: 96,
                displayValue: _fmtShort(i1),
                hasError: _inc1Error,
              ),
              const SizedBox(height: 12),
              // Primary EMIs
              _buildSimpleNumericField(
                label: 'EXISTING EMIS (₹/MONTH)',
                controller: _emi1Controller,
                hintText: 'Enter primary applicant EMIs',
                hasError: _emi1Error,
              ),
              const SizedBox(height: 12),
              // Primary CIBIL
              _buildSimpleNumericField(
                label: 'CIBIL SCORE',
                controller: _cibil1Controller,
                hintText: 'Enter primary applicant CIBIL',
                hasError: _cibil1Error,
              ),

              const Divider(height: 32),

              // Co-Applicant Section
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0F766E)]),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: const Text('👤', style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Co-Applicant',
                    style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Co-Applicant Gross Income
              _buildSyncSliderRow(
                title: 'Monthly Gross Income (₹)',
                controller: _inc2Controller,
                min: 0,
                max: 500000,
                divisions: 100,
                displayValue: _fmtShort(i2),
                isTeal: true,
                hasError: _inc2Error,
              ),
              const SizedBox(height: 12),
              // Co-Applicant EMIs
              _buildSimpleNumericField(
                label: 'EXISTING EMIS (₹/MONTH)',
                controller: _emi2Controller,
                hintText: 'Enter co-applicant EMIs',
                hasError: _emi2Error,
              ),
              const SizedBox(height: 12),
              // Co-Applicant CIBIL
              _buildSimpleNumericField(
                label: 'CIBIL SCORE',
                controller: _cibil2Controller,
                hintText: 'Enter co-applicant CIBIL',
                hasError: _cibil2Error,
              ),

              const Divider(height: 32),

              // Rate Slider
              _buildSyncSliderRow(
                title: 'Interest Rate (% p.a.)',
                controller: _rateController,
                min: 7.00,
                max: 13.00,
                divisions: 120,
                displayValue: '${rate.toStringAsFixed(2)}%',
                hasError: _rateError,
              ),
              const SizedBox(height: 12),

              // Tenure Slider
              _buildSyncSliderRow(
                title: 'Loan Tenure (Years)',
                controller: _tenureController,
                min: 5,
                max: 30,
                divisions: 25,
                displayValue: '$tenure yr',
                hasError: _tenureError,
              ),
              const SizedBox(height: 20),

              // Calculate Button
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _inc1Error = false;
                    _emi1Error = false;
                    _cibil1Error = false;
                    _inc2Error = false;
                    _emi2Error = false;
                    _cibil2Error = false;
                    _rateError = false;
                    _tenureError = false;
                  });

                  final inc1Val = double.tryParse(_inc1Controller.text.replaceAll(',', ''));
                  final emi1Val = double.tryParse(_emi1Controller.text.replaceAll(',', ''));
                  final cibil1Val = double.tryParse(_cibil1Controller.text);
                  final inc2Val = double.tryParse(_inc2Controller.text.replaceAll(',', ''));
                  final emi2Val = double.tryParse(_emi2Controller.text.replaceAll(',', ''));
                  final cibil2Val = double.tryParse(_cibil2Controller.text);
                  final rateVal = double.tryParse(_rateController.text);
                  final tenureVal = int.tryParse(_tenureController.text);

                  bool hasErr = false;
                  if (inc1Val == null || inc1Val <= 0) {
                    setState(() => _inc1Error = true);
                    hasErr = true;
                  }
                  if (emi1Val == null || emi1Val < 0) {
                    setState(() => _emi1Error = true);
                    hasErr = true;
                  }
                  if (cibil1Val == null || cibil1Val < 300 || cibil1Val > 900) {
                    setState(() => _cibil1Error = true);
                    hasErr = true;
                  }
                  if (inc2Val == null || inc2Val < 0) {
                    setState(() => _inc2Error = true);
                    hasErr = true;
                  }
                  if (emi2Val == null || emi2Val < 0) {
                    setState(() => _emi2Error = true);
                    hasErr = true;
                  }
                  if (cibil2Val == null || cibil2Val < 300 || cibil2Val > 900) {
                    setState(() => _cibil2Error = true);
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
                    _calcInc1 = inc1Val!;
                    _calcEmi1 = emi1Val!;
                    _calcCibil1 = cibil1Val!;
                    _calcInc2 = inc2Val!;
                    _calcEmi2 = emi2Val!;
                    _calcCibil2 = cibil2Val!;
                    _calcRate = rateVal!;
                    _calcTenure = tenureVal!;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('⚡ Joint eligibility calculated!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
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
                    '☸ Calculate Joint Eligibility',
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

          // Results Card (4-grid style)
          Container(
            padding: const EdgeInsets.all(18),
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
                Text(
                  'JOINT LOAN RESULTS',
                  style: AppTextStyles.dmSans(size: 9, color: Colors.white60, weight: FontWeight.w700, letterSpacing: 0.5),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.8,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    _buildResultBox('Solo Eligibility', _fmtShort(soloLoan), 'Primary only', true),
                    _buildResultBox('Joint Eligibility', _fmtShort(jointLoan), 'Both applicants', false, isGreen: true),
                    _buildResultBox('Additional Benefit', '+${_fmtShort(benefit)}', 'Co-applicant boost', true),
                    _buildResultBox('Joint EMI', "₹${NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(jointEmi)}", '$calcTenure-year tenure', false),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Combined Income Share Progress Stack
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
                Text('💰 Combined Income Share', style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 76,
                      height: 76,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 10,
                            color: Color(0xFF0F766E), // Co-applicant (teal)
                            backgroundColor: Colors.transparent,
                          ),
                          CircularProgressIndicator(
                            value: pct1,
                            strokeWidth: 10,
                            color: const Color(0xFFFF6B00), // Primary applicant (saffron)
                            backgroundColor: Colors.transparent,
                          ),
                          Text(
                            '${(pct1 * 100).round()}%',
                            style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: theme.getTextColor(context)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        children: [
                          _buildLegendRow(
                            color: const Color(0xFFFF6B00),
                            label: 'Primary',
                            value: "₹${NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(calcInc1)}",
                            pctText: '${(pct1 * 100).round()}% of joint income',
                          ),
                          const SizedBox(height: 10),
                          _buildLegendRow(
                            color: const Color(0xFF0F766E),
                            label: 'Co-Applicant',
                            value: "₹${NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(calcInc2)}",
                            pctText: '${(pct2 * 100).round()}% of joint income',
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

          // Double Tax Benefits Grid
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              border: Border.all(color: const Color(0xFF6EE7B7), width: 1.5),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🎁', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      'Joint Tax Benefits (Annual)',
                      style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: const Color(0xFF07543A)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.1,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    _buildTaxBox('Sec 80C (Primary)', '₹1,50,000'),
                    _buildTaxBox('Sec 80C (Co-App)', hasCoApp ? '₹1,50,000' : '₹0'),
                    _buildTaxBox('Sec 24(b) Primary', '₹2,00,000'),
                    _buildTaxBox('Sec 24(b) Co-App', hasCoApp ? '₹2,00,000' : '₹0'),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL JOINT DEDUCTION',
                        style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: const Color(0xFF046A38)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "₹${NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(totalTaxDeduction)}",
                        style: AppTextStyles.dmSans(size: 18, weight: FontWeight.w900, color: const Color(0xFF07543A)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // FOIR Analysis Horizontal Bars
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
                Text(
                  '📊 FOIR Analysis (RBI: max 50%)',
                  style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context)),
                ),
                const SizedBox(height: 14),
                _buildFoirBarRow(
                  label: 'Primary FOIR',
                  val: f1,
                  colors: const [Color(0xFF1A3A8F), Color(0xFF0B1F48)],
                ),
                const Divider(height: 18),
                _buildFoirBarRow(
                  label: 'Co-App FOIR',
                  val: f2,
                  colors: const [Color(0xFF0D9488), Color(0xFF0F766E)],
                ),
                const Divider(height: 18),
                _buildFoirBarRow(
                  label: 'Combined FOIR',
                  val: fj,
                  colors: const [Color(0xFF046A38), Color(0xFF07543A)],
                  isJoint: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Info Tip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: const Color(0xFF93C5FD), width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.dmSans(size: 10.5, color: const Color(0xFF1E3A8A)),
                      children: const [
                        TextSpan(
                          text: 'Joint Loan Advantage: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: 'Both co-owners can claim Sec 80C (₹1.5L each on principal) and Sec 24(b) (₹2L each on interest) — total ₹7L deduction. Female co-applicant may get 0.05–0.10% rate concession from SBI, HDFC. CIBIL of lower-scoring applicant may affect rate.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Save Button
          ElevatedButton.icon(
            onPressed: _saveCalculation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF046A38),
              shadowColor: const Color(0xFF046A38).withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            icon: const Text('💾', style: TextStyle(fontSize: 16)),
            label: Center(
              child: Text(
                'Save This Calculation',
                style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: Colors.white),
              ),
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
    bool isTeal = false,
    bool hasError = false,
  }) {
    final theme = widget.theme;
    final currentVal = double.tryParse(controller.text) ?? min;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color sliderColor = const Color(0xFFFF6B00);
    Color inactiveColor = isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFF5E6D4);
    if (isTeal) {
      sliderColor = const Color(0xFF0D9488);
      inactiveColor = isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFE0F0EE);
    }

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
                  activeTrackColor: sliderColor,
                  inactiveTrackColor: inactiveColor,
                  thumbColor: sliderColor,
                  overlayColor: sliderColor.withValues(alpha: 0.15),
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
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: hasError ? Colors.red : sliderColor,
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

  Widget _buildSimpleNumericField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    bool hasError = false,
  }) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context), weight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: theme.getTextColor(context)),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTextStyles.dmSans(size: 11, color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              filled: true,
              fillColor: theme.getBgColor(context),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: hasError ? Colors.red : theme.getBorderColor(context),
                  width: hasError ? 1.5 : 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
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
    );
  }

  Widget _buildResultBox(String label, String value, String note, bool isHi, {bool isGreen = false}) {
    Color valColor = Colors.white;
    if (isGreen) {
      valColor = const Color(0xFF86EFAC);
    } else if (isHi) {
      valColor = const Color(0xFFFFDEA0);
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.dmSans(size: 8, color: Colors.white54, weight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: valColor),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            note,
            style: AppTextStyles.dmSans(size: 8.5, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow({
    required Color color,
    required String label,
    required String value,
    required String pctText,
  }) {
    final theme = widget.theme;
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: theme.getTextColor(context)),
                  ),
                  Text(
                    value,
                    style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: color),
                  ),
                ],
              ),
              Text(
                pctText,
                style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaxBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFD1FAE5).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: AppTextStyles.dmSans(size: 8.5, color: const Color(0xFF07543A)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: const Color(0xFF0B1F48)),
          ),
        ],
      ),
    );
  }

  Widget _buildFoirBarRow({
    required String label,
    required int val,
    required List<Color> colors,
    bool isJoint = false,
  }) {
    final theme = widget.theme;
    final isExceeded = val > 50;
    Color valueColor = isExceeded ? const Color(0xFFE05F00) : theme.getTextColor(context);

    return Row(
      children: [
        SizedBox(
          width: 86,
          child: Text(
            label,
            style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context), weight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (val / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: isExceeded
                      ? const LinearGradient(colors: [Color(0xFFE05F00), Color(0xFFB91C1C)])
                      : LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '$val%',
            style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: valueColor),
            textAlign: TextAlign.right,
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
