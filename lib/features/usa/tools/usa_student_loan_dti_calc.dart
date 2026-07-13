// ignore_for_file: no_leading_underscores_for_local_identifiers, non_constant_identifier_names, unused_local_variable, unnecessary_this, prefer_final_fields
// lib/features/usa/tools/usa_student_loan_dti_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAStudentLoanDtiCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const USAStudentLoanDtiCalc({super.key, this.theme = CountryThemes.usa});

  @override
  ConsumerState<USAStudentLoanDtiCalc> createState() => _USAStudentLoanDtiCalcState();
}

class _USAStudentLoanDtiCalcState extends ConsumerState<USAStudentLoanDtiCalc> {
  final _resultsKey = GlobalKey();
  Map<String, String?> _errors = {};
  final Map<dynamic, dynamic> _calcSnapshot = {};
  final _incomeController = TextEditingController(text: '7500');
  final _slBalanceController = TextEditingController(text: '42000');
  final _slPmtController = TextEditingController(text: '420');
  final _otherDebtsController = TextEditingController(text: '250');
  final _homePriceController = TextEditingController(text: '400000');
  final _downPctController = TextEditingController(text: '10');
  final _mortRateController = TextEditingController(text: '6.82');
  final _taxRateController = TextEditingController(text: '1.10');

  bool _showResults = false;
  bool _isCalcDirty = true;
  bool _calculating = false;

  @override
  void initState() {
    super.initState();
    _incomeController.addListener(() => setState(() {}));
    _slBalanceController.addListener(() => setState(() {}));
    _slPmtController.addListener(() => setState(() {}));
    _otherDebtsController.addListener(() => setState(() {}));
    _homePriceController.addListener(() => setState(() {}));
    _downPctController.addListener(() => setState(() {}));
    _mortRateController.addListener(() => setState(() {}));
    _taxRateController.addListener(() => setState(() {}));

    final controllers = [
      _incomeController,
      _slBalanceController,
      _slPmtController,
      _otherDebtsController,
      _homePriceController,
      _downPctController,
      _mortRateController,
      _taxRateController
    ];
    for (final c in controllers) {
      c.addListener(_markDirty);
    }
    // Auto calculate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculate();
    });
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _slBalanceController.dispose();
    _slPmtController.dispose();
    _otherDebtsController.dispose();
    _homePriceController.dispose();
    _downPctController.dispose();
    _mortRateController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isCalcDirty) {
      setState(() {
        _isCalcDirty = true;
      });
    }
  }

  double _val(TextEditingController c) {
    if (_showResults && _calcSnapshot.containsKey(c)) {
      return _calcSnapshot[c]!;
    }
    return double.tryParse(c.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
  }

  double _calcPI(double loan, double rate, int months) {
    final double mo = rate / 1200;
    return mo == 0 ? loan / months : loan * mo * pow(1 + mo, months) / (pow(1 + mo, months) - 1);
  }

  Map<String, dynamic> _computeDTI() {
    final income = _val(_incomeController);
    final slBal = _val(_slBalanceController);
    final slPmt = _val(_slPmtController);
    final other = _val(_otherDebtsController);
    final hp = _val(_homePriceController);
    final dp = _val(_downPctController);
    final mr = _val(_mortRateController);
    final tr = _val(_taxRateController);
    const double ins = 150.0; // standard insurance

    final double loan = hp * (1 - dp / 100);
    final double mortPmt = _calcPI(loan, mr, 360);
    final double taxMo = hp * tr / 1200;
    final double housing = mortPmt + taxMo + ins;
    final double totalObl = housing + slPmt + other;

    final double dtiSL = income == 0 ? 0.0 : (totalObl / income) * 100;
    final double dtiNoSL = income == 0 ? 0.0 : ((housing + other) / income) * 100;

    double maxHP(double slPmtUsed) {
      final double maxHousing = 0.43 * income - other - slPmtUsed;
      final double mo = mr / 1200;
      const int n = 360;
      final double factor = (1 - dp / 100) * (mo == 0 ? 1 / n : mo * pow(1 + mo, n) / (pow(1 + mo, n) - 1));
      final double taxF = tr / 1200;
      return max(0.0, (maxHousing - ins) / (factor + taxF));
    }

    final double mxNoSL = maxHP(0);
    final double mxWithSL = maxHP(slPmt);
    final double bpLoss = max(0.0, mxNoSL - mxWithSL);
    final double incomeNeeded = 0.43 == 0 ? 0.0 : totalObl / 0.43;

    // Student loan plans
    final double std = _calcPI(slBal, 6.53, 120);
    final double ext = _calcPI(slBal, 6.53, 300);
    final double ibrPmt = max(0.0, (income * 12 - 18225 * 1.5) * 0.05 / 12);
    final double payePmt = max(0.0, (income * 12 - 18225 * 1.5) * 0.10 / 12);

    return {
      'income': income,
      'slBal': slBal,
      'slPmt': slPmt,
      'other': other,
      'hp': hp,
      'mortPmt': mortPmt,
      'taxMo': taxMo,
      'ins': ins,
      'housing': housing,
      'totalObl': totalObl,
      'dtiSL': dtiSL,
      'dtiNoSL': dtiNoSL,
      'mxNoSL': mxNoSL,
      'mxWithSL': mxWithSL,
      'bpLoss': bpLoss,
      'incomeNeeded': incomeNeeded,
      'std': std,
      'ext': ext,
      'ibr': ibrPmt,
      'paye': payePmt,
    };
  }

    void _calculate() {
    final errors = <String, String>{};
    final val_income = double.tryParse(_incomeController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (val_income <= 0) errors['income'] = 'Please enter a valid amount';
    final val_slBalance = double.tryParse(_slBalanceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final val_slPmt = double.tryParse(_slPmtController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final val_otherDebts = double.tryParse(_otherDebtsController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final val_homePrice = double.tryParse(_homePriceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (val_homePrice <= 0) errors['homePrice'] = 'Please enter a valid amount';
    final val_downPct = double.tryParse(_downPctController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final val_mortRate = double.tryParse(_mortRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final val_taxRate = double.tryParse(_taxRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) {
      return;
    }

    setState(() {
      _calcSnapshot[_incomeController] = val_income;
      _calcSnapshot[_slBalanceController] = val_slBalance;
      _calcSnapshot[_slPmtController] = val_slPmt;
      _calcSnapshot[_otherDebtsController] = val_otherDebts;
      _calcSnapshot[_homePriceController] = val_homePrice;
      _calcSnapshot[_downPctController] = val_downPct;
      _calcSnapshot[_mortRateController] = val_mortRate;
      _calcSnapshot[_taxRateController] = val_taxRate;
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


  void _saveCalculation() async {
    final income = _val(_incomeController);
    if (income <= 0) return;

    final data = _computeDTI();
    final dtiSL = data['dtiSL'] as double;
    final slBal = data['slBal'] as double;

    final label = 'DTI Analysis (Income: ${CurrencyFormatter.compact(income, symbol: r'$')})';
    final labelCtrl = TextEditingController(text: label);

    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_student_loan_dti_calc'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save DTI Calculation',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: Student Loan Balance: ${CurrencyFormatter.compact(slBal, symbol: r'$')} · DTI w/ SL: ${dtiSL.toStringAsFixed(1)}%',
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
                hintText: 'Label',
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
      final savedLabel = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : label;
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'Student Loan DTI',
        inputs: {
          'Income': income,
          'SLBal': slBal,
          'SLPmt': data['slPmt'] as double,
          'Other': data['other'] as double,
          'HomePrice': data['hp'] as double,
        },
        results: {
          'DTI with SL': dtiSL,
          'DTI without SL': data['dtiNoSL'] as double,
          'Max Price with SL': data['mxWithSL'] as double,
          'Max Price no SL': data['mxNoSL'] as double,
        },
        label: savedLabel,
        currencyCode: 'USD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Calculation saved successfully!',
                style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: widget.theme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

    void _resetInputs() {
    setState(() {
      _incomeController.text = '7500';
      _slBalanceController.text = '42000';
      _slPmtController.text = '420';
      _otherDebtsController.text = '250';
      _homePriceController.text = '400000';
      _downPctController.text = '10';
      _mortRateController.text = '6.82';
      _taxRateController.text = '1.10';
      _calcSnapshot.clear();
      _errors.clear();
      _showResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    final isDirty = _showResults && (double.tryParse(_incomeController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_incomeController] ?? 0.0) || double.tryParse(_slBalanceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_slBalanceController] ?? 0.0) || double.tryParse(_slPmtController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_slPmtController] ?? 0.0) || double.tryParse(_otherDebtsController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_otherDebtsController] ?? 0.0) || double.tryParse(_homePriceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_homePriceController] ?? 0.0) || double.tryParse(_downPctController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_downPctController] ?? 0.0) || double.tryParse(_mortRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_mortRateController] ?? 0.0) || double.tryParse(_taxRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_taxRateController] ?? 0.0));

    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final data = _computeDTI();
    final dtiSL = data['dtiSL'] as double;
    final dtiNoSL = data['dtiNoSL'] as double;
    final slAdds = dtiSL - dtiNoSL;
    final isOk = dtiSL <= 43.0;

    // Monthly bars scale
    final totalObl = data['totalObl'] as double;
    final mortPmt = data['mortPmt'] as double;
    final slPmt = data['slPmt'] as double;
    final taxIns = (data['taxMo'] as double) + (data['ins'] as double);
    final other = data['other'] as double;

    // Custom Gauge color
    Color gaugeColor = dtiSL <= 36.0
        ? const Color(0xFF15803D)
        : dtiSL <= 43.0
            ? const Color(0xFFD97706)
            : const Color(0xFFB91C1C);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStat('Undergrad \'25', '6.53%', 'Federal', theme, context),
              _buildHeaderStat('Grad \'25', '8.08%', 'Direct', theme, context),
              _buildHeaderStat('Avg Balance', r'$37.7K', 'DOE 2024', theme, context),
              _buildHeaderStat('Back-End DTI', '43%', 'FHA Max', theme, context, isGold: true),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildSectionHeader('YOUR INFORMATION', onReset: _resetInputs),
        const SizedBox(height: 8),

        // Inputs Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildTextField('Gross Monthly Income (\$)', _incomeController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Student Loan Bal (\$)', _slBalanceController)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Actual Monthly Pmt (\$)', _slPmtController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Other Monthly Debts (\$)', _otherDebtsController)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Target Home Price (\$)', _homePriceController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Down Payment (%)', _downPctController)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Mortgage Rate (%)', _mortRateController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Prop. Tax Rate (%)', _taxRateController)),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD97706), Color(0xFFB45309)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _calculate,
                        child: _calculating
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text('🎓 Analyze DTI Impact', style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _showResults ? _saveCalculation : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: _showResults ? const Color(0xFF15803D) : theme.getBgColor(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.getBorderColor(context)),
                      ),
                      alignment: Alignment.center,
                      child: Text('💾 Save',
                          style: AppTextStyles.dmSans(
                              size: 13,
                              color: _showResults ? Colors.white : theme.getMutedColor(context),
                              weight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_showResults) ...[
        Container(
          key: _resultsKey,
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDirty) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.amber),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Inputs have changed. Tap "Calculate" to update results.',
                          style: AppTextStyles.dmSans(size: 11, color: theme.getTextColor(context), weight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

          // Result Hero
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD97706), Color(0xFFB45309)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BACK-END DTI WITH STUDENT LOANS', style: AppTextStyles.dmSans(size: 9.5, color: Colors.white60, weight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('${dtiSL.toStringAsFixed(1)}%',
                    style: AppTextStyles.playfair(size: 38, color: Colors.white, weight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  isOk
                      ? '✅ Within FHA 43% limit — approval likely'
                      : '⚠️ Above FHA 43% limit — approval at risk',
                  style: AppTextStyles.dmSans(size: 11, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildHeroResult('Without SL', '${dtiNoSL.toStringAsFixed(1)}%'),
                    _buildHeroResult('SL Adds', '+${slAdds.toStringAsFixed(1)}%'),
                    _buildHeroResult('Max FHA', '43%'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Gauge + Circle Comparisons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DTI Impact Comparison', style: AppTextStyles.playfair(size: 13, color: theme.getTextColor(context), weight: FontWeight.bold)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    // Semi-circle gauge
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 85,
                            width: 140,
                            child: CustomPaint(
                              painter: _DtiGaugePainter(
                                dti: dtiSL,
                                color: gaugeColor,
                                isDark: isDark,
                              ),
                            ),
                          ),
                          Text('DTI w/ SL', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Comparison circles
                    Expanded(
                      flex: 5,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildCompareCircle('No SL', dtiNoSL, const Color(0xFFEFF6FF), const Color(0xFF1B3F72), 'Base DTI'),
                          _buildCompareCircle('With SL', dtiSL, dtiSL <= 36 ? const Color(0xFFF0FDF4) : dtiSL <= 43 ? const Color(0xFFFFFBEB) : const Color(0xFFFEF2F2), gaugeColor, 'Full DTI'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DTI Progress Meter', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context), weight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 9,
                        color: theme.getBgColor(context),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: (dtiSL / 50.0).clamp(0.05, 1.0),
                          child: Container(
                            color: gaugeColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0%', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context), weight: FontWeight.bold)),
                        Text('28%', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context), weight: FontWeight.bold)),
                        Text('36%', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context), weight: FontWeight.bold)),
                        Text('43%', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context), weight: FontWeight.bold)),
                        Text('50%+', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context), weight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Monthly Payment Breakdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📊 Monthly Payment Breakdown', style: AppTextStyles.playfair(size: 13, color: theme.getTextColor(context), weight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildObligationRow('Mortgage', mortPmt, totalObl, const Color(0xFF1B3F72)),
                const SizedBox(height: 8),
                _buildObligationRow('Student Loan', slPmt, totalObl, const Color(0xFFD97706)),
                const SizedBox(height: 8),
                _buildObligationRow('Tax + Ins', taxIns, totalObl, const Color(0xFF64748B)),
                const SizedBox(height: 8),
                _buildObligationRow('Other Debts', other, totalObl, const Color(0xFFB91C1C)),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Monthly Obligations', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
                    Text('${CurrencyFormatter.format(totalObl, symbol: r'$')}/mo', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context), weight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Buying Power Analysis
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Buying Power Analysis', style: AppTextStyles.playfair(size: 13, color: theme.getTextColor(context), weight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildPowerRow('Max home price (no student loans)', data['mxNoSL'] as double, isLoss: false),
                _buildPowerRow('Max home price (with student loans)', data['mxWithSL'] as double, isLoss: true),
                _buildPowerRow('Buying power reduction', data['bpLoss'] as double, isLoss: true, isDiff: true),
                _buildPowerRow('Income needed for target home', data['incomeNeeded'] as double, isLoss: false, isMo: true),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    children: [
                      const Text('🏠', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              CurrencyFormatter.compact(data['bpLoss'] as double, symbol: r'$'),
                              style: AppTextStyles.playfair(size: 20, color: const Color(0xFFB91C1C), weight: FontWeight.bold),
                            ),
                            Text('buying power lost to student loans', style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF1E40AF), weight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Repayment plans
          Text('REPAYMENT PLAN OPTIONS (2025)', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.35,
            children: [
              _buildPlanCard('Standard (10yr)', data['std'] as double, 'Fixed payment · fastest payoff', 'Highest pmt', const Color(0xFFFEF2F2), const Color(0xFFB91C1C)),
              _buildPlanCard('Extended (25yr)', data['ext'] as double, 'Lower payment · more interest', 'Moderate', const Color(0xFFFFF7ED), const Color(0xFFC2410C)),
              _buildPlanCard('IBR / SAVE Plan', data['ibr'] as double, '5% discretionary income', 'Lowest pmt', const Color(0xFFF0FDF4), const Color(0xFF15803D)),
              _buildPlanCard('PAYE / ICR', data['paye'] as double, '10% discretionary income', 'IDR plan', const Color(0xFFF0FDF4), const Color(0xFF15803D)),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Lender Treatment
        Text('LENDER TREATMENT OF STUDENT LOANS', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildGuideCard('Conventional (Fannie/Freddie)', 'Use actual payment or 1% of balance if \$0/deferred', theme, context),
        _buildGuideCard('FHA Loans', 'Use actual payment or 0.5% of balance if \$0/deferred', theme, context),
        _buildGuideCard('VA Loans', '12-month history of \$0 payments = exclude from DTI calculation', theme, context),
        _buildGuideCard('USDA Loans', 'Use actual payment or 0.5% of balance/mo if deferred', theme, context),
      ],
    );
  }

  Widget _buildHeaderStat(String label, String value, String note, CountryTheme theme, BuildContext context, {bool isGold = false}) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context))),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.playfair(size: 14, color: isGold ? const Color(0xFFD97706) : theme.getTextColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 1),
        Text(note, style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? errorText}) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            border: Border.all(color: errorText != null ? Colors.redAccent : theme.getBorderColor(context), width: 1.5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: AppTextStyles.dmSans(size: 13, color: theme.getTextColor(context), weight: FontWeight.bold),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 3),
          Text(
            errorText,
            style: AppTextStyles.dmSans(
              size: 9,
              color: Colors.redAccent,
              weight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeroResult(String label, String val) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white60)),
        const SizedBox(height: 4),
        Text(val, style: AppTextStyles.playfair(size: 14, color: Colors.white, weight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCompareCircle(String label, double val, Color bg, Color textCol, String desc) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 9, color: widget.theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text('${val.toStringAsFixed(0)}%', style: AppTextStyles.playfair(size: 15, color: textCol, weight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(desc, style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context))),
      ],
    );
  }

  Widget _buildObligationRow(String label, double val, double total, Color color) {
    final theme = widget.theme;
    final double pct = total > 0 ? (val / total).clamp(0.03, 1.0) : 0.03;
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context), weight: FontWeight.bold), textAlign: TextAlign.right)),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 22,
            decoration: BoxDecoration(color: theme.getBgColor(context), borderRadius: BorderRadius.circular(11)),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: pct,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)]),
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(width: 44, child: Text(CurrencyFormatter.format(val, symbol: r'$'), style: AppTextStyles.playfair(size: 11, color: theme.getTextColor(context), weight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildPowerRow(String label, double val, {required bool isLoss, bool isDiff = false, bool isMo = false}) {
    final theme = widget.theme;
    final Color valColor = isLoss
        ? const Color(0xFFB91C1C)
        : isMo
            ? theme.getTextColor(context)
            : const Color(0xFF15803D);

    final String prefix = isDiff ? '-' : '';
    final String suffix = isMo ? '/mo' : '';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.getBorderColor(context)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.w600)),
          Text(
            isMo
                ? '$prefix${CurrencyFormatter.format(val, symbol: r'$')}$suffix'
                : '$prefix${CurrencyFormatter.compact(val, symbol: r'$')}$suffix',
            style: AppTextStyles.playfair(size: 13, color: valColor, weight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String name, double val, String desc, String tag, Color tagBg, Color tagFg) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: AppTextStyles.playfair(size: 11, color: theme.getTextColor(context), weight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(CurrencyFormatter.format(val, symbol: r'$'), style: AppTextStyles.playfair(size: 18, color: const Color(0xFFD97706), weight: FontWeight.bold)),
          const SizedBox(height: 1),
          Text(desc, style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(10)),
            child: Text(tag, style: AppTextStyles.dmSans(size: 8, color: tagFg, weight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(String title, String desc, CountryTheme theme, BuildContext context) {
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
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(color: theme.getBgColor(context), borderRadius: BorderRadius.circular(11)),
            alignment: Alignment.center,
            child: const Text('🏦', style: TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.playfair(size: 12.5, color: theme.getTextColor(context), weight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(desc, style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onReset, String resetLabel = 'Reset'}) {
    final theme = widget.theme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 11,
            color: theme.getMutedColor(context),
            weight: FontWeight.bold,
          ),
        ),
        if (onReset != null)
          TextButton(
            onPressed: onReset,
            child: Text(
              resetLabel,
              style: AppTextStyles.dmSans(
                size: 11,
                color: theme.accentColor,
                weight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

class _DtiGaugePainter extends CustomPainter {
  final double dti;
  final Color color;
  final bool isDark;

  _DtiGaugePainter({
    required this.dti,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height - 10);
    final double radius = size.height - 15;

    // Background track arc
    final bgPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFEEF2F8)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi, pi, false, bgPaint);

    // Active track arc
    final activePaint = Paint()
      ..color = color
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double dtiPct = (dti / 50.0).clamp(0.0, 1.0);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi, pi * dtiPct, false, activePaint);

    // Pin center circle
    final pinPaint = Paint()..color = isDark ? Colors.white : const Color(0xFF0B1D3A);
    canvas.drawCircle(center, 4, pinPaint);

    // Value text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${dti.toStringAsFixed(1)}%',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
          fontFamily: 'Georgia',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - 25));
  }

  @override
  bool shouldRepaint(covariant _DtiGaugePainter oldDelegate) {
    return oldDelegate.dti != dti || oldDelegate.color != color || oldDelegate.isDark != isDark;
  }
}

