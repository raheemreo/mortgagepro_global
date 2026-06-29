// lib/features/usa/tools/usa_dti_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USADtiCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const USADtiCalc({super.key, this.theme = CountryThemes.usa});

  @override
  ConsumerState<USADtiCalc> createState() => _USADtiCalcState();
}

class _USADtiCalcState extends ConsumerState<USADtiCalc> {
  // Gross Income
  final _primaryIncomeController = TextEditingController(text: '7500');
  final _coIncomeController = TextEditingController(text: '0');
  final _otherIncomeController = TextEditingController(text: '0');

  // Housing Costs (Front End)
  final _piPaymentController = TextEditingController(text: '1650');
  final _propTaxController = TextEditingController(text: '375');
  final _hoInsController = TextEditingController(text: '150');
  final _pmiController = TextEditingController(text: '0');
  final _hoaController = TextEditingController(text: '0');

  // Other Monthly Debts (Back End)
  final _autoLoanController = TextEditingController(text: '450');
  final _studentLoanController = TextEditingController(text: '200');
  final _creditCardsController = TextEditingController(text: '75');
  final _personalLoanController = TextEditingController(text: '0');
  final _otherDebtsController = TextEditingController(text: '0');

  bool _showResults = false;
  bool _isCalcDirty = true;

  @override
  void initState() {
    super.initState();
    final listeners = [
      _primaryIncomeController,
      _coIncomeController,
      _otherIncomeController,
      _piPaymentController,
      _propTaxController,
      _hoInsController,
      _pmiController,
      _hoaController,
      _autoLoanController,
      _studentLoanController,
      _creditCardsController,
      _personalLoanController,
      _otherDebtsController,
    ];
    for (final controller in listeners) {
      controller.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    final listeners = [
      _primaryIncomeController,
      _coIncomeController,
      _otherIncomeController,
      _piPaymentController,
      _propTaxController,
      _hoInsController,
      _pmiController,
      _hoaController,
      _autoLoanController,
      _studentLoanController,
      _creditCardsController,
      _personalLoanController,
      _otherDebtsController,
    ];
    for (final controller in listeners) {
      controller.removeListener(_markDirty);
      controller.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_isCalcDirty) {
      setState(() {
        _isCalcDirty = true;
      });
    }
  }

  double _val(TextEditingController c) => double.tryParse(c.text) ?? 0.0;

  void _resetInputs() {
    setState(() {
      _primaryIncomeController.text = '7500';
      _coIncomeController.text = '0';
      _otherIncomeController.text = '0';
      _piPaymentController.text = '1650';
      _propTaxController.text = '375';
      _hoInsController.text = '150';
      _pmiController.text = '0';
      _hoaController.text = '0';
      _autoLoanController.text = '450';
      _studentLoanController.text = '200';
      _creditCardsController.text = '75';
      _personalLoanController.text = '0';
      _otherDebtsController.text = '0';
      _showResults = false;
      _isCalcDirty = true;
    });
  }

  void _loadSavedCalculation(SavedCalc calc) {
    setState(() {
      _primaryIncomeController.text = (calc.inputs['PrimaryIncome'] ?? 7500.0).toStringAsFixed(0);
      _coIncomeController.text = (calc.inputs['CoIncome'] ?? 0.0).toStringAsFixed(0);
      _otherIncomeController.text = (calc.inputs['OtherIncome'] ?? 0.0).toStringAsFixed(0);
      _piPaymentController.text = (calc.inputs['PiPayment'] ?? 1650.0).toStringAsFixed(0);
      _propTaxController.text = (calc.inputs['PropTax'] ?? 375.0).toStringAsFixed(0);
      _hoInsController.text = (calc.inputs['HoIns'] ?? 150.0).toStringAsFixed(0);
      _pmiController.text = (calc.inputs['Pmi'] ?? 0.0).toStringAsFixed(0);
      _hoaController.text = (calc.inputs['Hoa'] ?? 0.0).toStringAsFixed(0);
      _autoLoanController.text = (calc.inputs['AutoLoan'] ?? 450.0).toStringAsFixed(0);
      _studentLoanController.text = (calc.inputs['StudentLoan'] ?? 200.0).toStringAsFixed(0);
      _creditCardsController.text = (calc.inputs['CreditCards'] ?? 75.0).toStringAsFixed(0);
      _personalLoanController.text = (calc.inputs['PersonalLoan'] ?? 0.0).toStringAsFixed(0);
      _otherDebtsController.text = (calc.inputs['OtherDebts'] ?? 0.0).toStringAsFixed(0);
      _showResults = true;
      _isCalcDirty = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded saved calculation!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
        backgroundColor: widget.theme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveCalculation() async {
    final primary = _val(_primaryIncomeController);
    final co = _val(_coIncomeController);
    final other = _val(_otherIncomeController);
    final grossIncome = primary + co + (other * 0.75);

    final pi = _val(_piPaymentController);
    final tax = _val(_propTaxController);
    final ins = _val(_hoInsController);
    final pmi = _val(_pmiController);
    final hoa = _val(_hoaController);
    final housing = pi + tax + ins + pmi + hoa;

    final auto = _val(_autoLoanController);
    final student = _val(_studentLoanController);
    final cc = _val(_creditCardsController);
    final personal = _val(_personalLoanController);
    final otherD = _val(_otherDebtsController);
    final otherDebts = auto + student + cc + personal + otherD;

    final totalObligations = housing + otherDebts;
    final backDTI = grossIncome > 0 ? (totalObligations / grossIncome * 100) : 0.0;

    final labelCtrl = TextEditingController(text: 'DTI Calculator');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_dti_calc/save'),
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
              'Saving: DTI ${backDTI.toStringAsFixed(0)}% · Monthly Income: ${CurrencyFormatter.compact(grossIncome, symbol: '\$')}',
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
                hintText: 'Label (e.g. My DTI Calc)',
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
          : 'DTI Calculator';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'DTI Calculator',
        inputs: {
          'PrimaryIncome': primary,
          'CoIncome': co,
          'OtherIncome': other,
          'PiPayment': pi,
          'PropTax': tax,
          'HoIns': ins,
          'Pmi': pmi,
          'Hoa': hoa,
          'AutoLoan': auto,
          'StudentLoan': student,
          'CreditCards': cc,
          'PersonalLoan': personal,
          'OtherDebts': otherD,
        },
        results: {
          'DtiBack': backDTI,
          'GrossIncome': grossIncome,
          'HousingCost': housing,
          'OtherDebtsCost': otherDebts,
          'TotalObligations': totalObligations,
        },
        label: label,
        currencyCode: 'USD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Calculation saved successfully!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: widget.theme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = widget.theme;

    // Fetch Inputs
    final primary = _val(_primaryIncomeController);
    final co = _val(_coIncomeController);
    final other = _val(_otherIncomeController);
    final grossIncome = primary + co + (other * 0.75);

    final pi = _val(_piPaymentController);
    final tax = _val(_propTaxController);
    final ins = _val(_hoInsController);
    final pmi = _val(_pmiController);
    final hoa = _val(_hoaController);
    final housing = pi + tax + ins + pmi + hoa;

    final auto = _val(_autoLoanController);
    final student = _val(_studentLoanController);
    final cc = _val(_creditCardsController);
    final personal = _val(_personalLoanController);
    final otherD = _val(_otherDebtsController);
    final otherDebts = auto + student + cc + personal + otherD;

    final totalObligations = housing + otherDebts;
    final frontDTI = grossIncome > 0 ? (housing / grossIncome * 100) : 0.0;
    final backDTI = grossIncome > 0 ? (totalObligations / grossIncome * 100) : 0.0;

    // Color and status determinations
    String dtiStatusText;
    Color dtiStatusBg;
    Color dtiStatusTextColor;
    if (backDTI <= 28) {
      dtiStatusText = '✅ Excellent — All Loan Types';
      dtiStatusBg = const Color(0xFFF0FDF4);
      dtiStatusTextColor = const Color(0xFF15803D);
    } else if (backDTI <= 36) {
      dtiStatusText = '✅ Good — Conventional Eligible';
      dtiStatusBg = const Color(0xFFF0FDF4);
      dtiStatusTextColor = const Color(0xFF15803D);
    } else if (backDTI <= 43) {
      dtiStatusText = '⚠️ Acceptable — FHA Eligible';
      dtiStatusBg = const Color(0xFFFFF7ED);
      dtiStatusTextColor = const Color(0xFFD97706);
    } else if (backDTI <= 50) {
      dtiStatusText = '⚠️ High — Limited Loan Options';
      dtiStatusBg = const Color(0xFFFFF7ED);
      dtiStatusTextColor = const Color(0xFFD97706);
    } else {
      dtiStatusText = '🔴 Too High — Reduce Debts First';
      dtiStatusBg = const Color(0xFFFEF2F2);
      dtiStatusTextColor = const Color(0xFFB91C1C);
    }

    final savedCalcs = ref.watch(savedProvider).where((c) => c.country == 'USA' && c.calcType == 'DTI Calculator').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip
        Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F4FF),
            border: Border.all(color: isDark ? Colors.white10 : const Color(0x1B1B3F72)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Expanded(child: _RateStripItem(label: '30-Yr Fixed', value: '6.82%', note: 'Freddie Mac')),
              Expanded(child: _RateStripItem(label: 'FHA Max DTI', value: '43%', note: 'Standard')),
              Expanded(child: _RateStripItem(label: 'Conv. Max DTI', value: '45%', note: 'Fannie Mae')),
              Expanded(child: _RateStripItem(label: 'VA Max DTI', value: '41%', note: 'Guideline', isGold: true)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Live Result Hero (visible once calculated or loaded)
        if (_showResults) ...[
          _buildSectionHeader('Your DTI Result', onReset: null),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 36,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DEBT-TO-INCOME RATIO · FRONT & BACK END',
                  style: AppTextStyles.dmSans(
                    size: 9.5,
                    weight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.48),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      backDTI.toStringAsFixed(0),
                      style: AppTextStyles.dmSans(
                        size: 52,
                        weight: FontWeight.w800,
                        color: Colors.white,
                      ).copyWith(fontFamily: 'Georgia', height: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '%',
                        style: AppTextStyles.dmSans(
                          size: 22,
                          weight: FontWeight.w800,
                          color: const Color(0xFFFCD34D),
                        ).copyWith(fontFamily: 'Georgia'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                      decoration: BoxDecoration(
                        color: dtiStatusBg.withValues(alpha: 0.22),
                        border: Border.all(color: dtiStatusTextColor.withValues(alpha: 0.35)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        dtiStatusText,
                        style: AppTextStyles.dmSans(
                          size: 11,
                          weight: FontWeight.w800,
                          color: dtiStatusTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  'Front-end: ${frontDTI.toStringAsFixed(1)}% · Back-end: ${backDTI.toStringAsFixed(1)}% · Income: ${CurrencyFormatter.format(grossIncome)}/mo',
                  style: AppTextStyles.dmSans(
                    size: 9.5,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 14),

                // Bar meters
                _buildDtiBarRow('Front DTI', frontDTI, 45, frontDTI <= 28 ? Colors.green : frontDTI <= 36 ? Colors.orange : Colors.red),
                const SizedBox(height: 5),
                _buildDtiBarRow('Back DTI', backDTI, 45, backDTI <= 36 ? Colors.green : backDTI <= 43 ? Colors.orange : Colors.red),
                const SizedBox(height: 5),
                _buildDtiBarRow('Max Limit', 45, 45, const Color(0xFFD97706)),
                const SizedBox(height: 16),

                // Allocation stacked bar
                Text(
                  'Income Allocation Bar',
                  style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w700, color: Colors.white60),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 18,
                    child: Row(
                      children: [
                        if (frontDTI > 0)
                          Expanded(
                            flex: (frontDTI * 10).round(),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [Color(0xFF1B3F72), Color(0xFF0B1D3A)]),
                              ),
                            ),
                          ),
                        if (backDTI - frontDTI > 0)
                          Expanded(
                            flex: ((backDTI - frontDTI) * 10).round(),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [Color(0xFFD97706), Color(0xFFB45309)]),
                              ),
                            ),
                          ),
                        if (100 - backDTI > 0)
                          Expanded(
                            flex: ((100 - backDTI) * 10).round(),
                            child: Container(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Legend
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _buildAllocLegendItem('Housing', const Color(0xFF1B3F72), '${frontDTI.toStringAsFixed(1)}%'),
                    _buildAllocLegendItem('Other Debts', const Color(0xFFD97706), '${(backDTI - frontDTI).toStringAsFixed(1)}%'),
                    _buildAllocLegendItem('Remaining', Colors.white30, '${max(0.0, 100 - backDTI).toStringAsFixed(1)}%'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Input Card 1: Income
        _buildSectionHeader('Gross Monthly Income', onReset: _resetInputs),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            border: Border.all(color: theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardTitle('💵', 'Monthly Gross Income'),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField('Primary Income', _primaryIncomeController, prefix: '\$', hint: 'Before taxes'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputField('Co-Borrower', _coIncomeController, prefix: '\$', hint: 'Spouse / co-signer'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildInputField('Other Income (Rental / Side / Alimony)', _otherIncomeController, prefix: '\$', hint: '75% rental counted · Must document 2-yr'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Input Card 2: Housing Costs
        _buildSectionHeader('Housing Payment (Front-End)', onReset: null),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            border: Border.all(color: theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardTitle('🏠', 'Monthly Housing Costs'),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField('P&I Payment', _piPaymentController, prefix: '\$'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputField('Property Tax', _propTaxController, prefix: '\$', suffix: '/mo'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField('Homeowners Ins.', _hoInsController, prefix: '\$', suffix: '/mo'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputField('PMI / MIP', _pmiController, prefix: '\$', suffix: '/mo'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildInputField('HOA Fee', _hoaController, prefix: '\$', suffix: '/mo'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Input Card 3: Other Monthly Debts
        _buildSectionHeader('Monthly Debts (Back-End)', onReset: null),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            border: Border.all(color: theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardTitle('💳', 'Recurring Monthly Obligations'),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField('Auto Loan(s)', _autoLoanController, prefix: '\$', suffix: '/mo'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputField('Student Loans', _studentLoanController, prefix: '\$', suffix: '/mo'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField('Credit Cards', _creditCardsController, prefix: '\$', suffix: '/mo'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputField('Personal Loan', _personalLoanController, prefix: '\$', suffix: '/mo'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildInputField('Other Obligations', _otherDebtsController, prefix: '\$', suffix: '/mo'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Actions: Calculate and Save Buttons
        Row(
          children: [
            Expanded(
              flex: 7,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showResults = true;
                    _isCalcDirty = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB91C1C), Color(0xFF991B1B)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB91C1C).withValues(alpha: _isCalcDirty ? 0.40 : 0.20),
                        blurRadius: _isCalcDirty ? 16 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '📊 Calculate My DTI Ratio',
                    style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: Colors.white).copyWith(fontFamily: 'Georgia'),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: GestureDetector(
                onTap: _saveCalculation,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: theme.getCardColor(context),
                    border: Border.all(color: theme.getBorderColor(context), width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '💾 Save',
                    style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context)),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Results Details Breakdown Card
        if (_showResults) ...[
          _buildSectionHeader('Payment Breakdown', onReset: null),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              border: Border.all(color: theme.getBorderColor(context)),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07), blurRadius: 14, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              children: [
                _buildBreakdownRow('Gross Monthly Income', grossIncome),
                _buildBreakdownRow('Total Housing (PITI + HOA)', housing),
                _buildBreakdownRow('Other Monthly Debts', otherDebts),
                _buildBreakdownRow('Total Monthly Obligations', totalObligations, isHighlighted: true),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)]),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Back-End DTI Ratio',
                        style: AppTextStyles.dmSans(size: 11, color: Colors.white70, weight: FontWeight.w600),
                      ),
                      Text(
                        '${backDTI.toStringAsFixed(1)}%',
                        style: AppTextStyles.dmSans(size: 16, color: Colors.white, weight: FontWeight.w800).copyWith(fontFamily: 'Georgia'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // DTI Rules Guide (28/36 Rule)
        _buildSectionHeader('The 28/36 Rule — Lender Guidelines', onReset: null),
        const SizedBox(height: 8),
        const GridViewRules(),
        const SizedBox(height: 20),

        // Lender DTI Limits
        _buildSectionHeader('Lender DTI Limits (2025)', onReset: null),
        const SizedBox(height: 8),
        _buildLimitsList(),
        const SizedBox(height: 20),

        // Saved calculations section
        if (savedCalcs.isNotEmpty) ...[
          _buildSectionHeader(
            'Saved Calculations',
            onReset: () async {
              final messenger = ScaffoldMessenger.of(context);
              for (final calc in savedCalcs) {
                await ref.read(savedProvider.notifier).delete(calc.id);
              }
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('All saved calculations cleared!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            resetLabel: 'Clear All',
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: savedCalcs.length,
            itemBuilder: (context, index) {
              final calc = savedCalcs[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.getCardColor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.getBorderColor(context)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07), blurRadius: 14, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _loadSavedCalculation(calc),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              calc.label,
                              style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: theme.getTextColor(context)).copyWith(fontFamily: 'Georgia'),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Income ${CurrencyFormatter.compact(calc.inputs['PrimaryIncome'] ?? 0.0, symbol: '\$')}/mo · Housing ${CurrencyFormatter.compact(calc.results['HousingCost'] ?? 0.0, symbol: '\$')}/mo',
                              style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(calc.results['DtiBack'] ?? 0.0).toStringAsFixed(0)}% DTI',
                      style: AppTextStyles.dmSans(
                        size: 14,
                        weight: FontWeight.w800,
                        color: theme.primaryColor,
                      ).copyWith(fontFamily: 'Georgia'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      color: theme.getMutedColor(context).withValues(alpha: 0.5),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await ref.read(savedProvider.notifier).delete(calc.id);
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Removed saved calculation!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
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

  Widget _buildSectionHeader(String title, {VoidCallback? onReset, String resetLabel = 'Reset'}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 10.5,
            weight: FontWeight.w800,
            color: widget.theme.getMutedColor(context),
            letterSpacing: 1,
          ),
        ),
        if (onReset != null)
          GestureDetector(
            onTap: onReset,
            child: Text(
              '$resetLabel →',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF93C5FD)
                    : const Color(0xFF1E4FBF),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCardTitle(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 7),
          Text(
            text,
            style: AppTextStyles.dmSans(
              size: 12.5,
              weight: FontWeight.w800,
              color: widget.theme.getTextColor(context),
            ).copyWith(fontFamily: 'Georgia'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    String? prefix,
    String? suffix,
    String? hint,
  }) {
    final theme = widget.theme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(
              size: 9.5,
              weight: FontWeight.w700,
              color: theme.getMutedColor(context),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            decoration: BoxDecoration(
              color: theme.getBgColor(context),
              border: Border.all(color: theme.getBorderColor(context), width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                if (prefix != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 13, right: 10),
                    child: Text(
                      prefix,
                      style: AppTextStyles.dmSans(
                        size: 14,
                        weight: FontWeight.w800,
                        color: theme.getMutedColor(context),
                      ),
                    ),
                  ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: AppTextStyles.dmSans(
                      size: 15,
                      weight: FontWeight.w700,
                      color: theme.getTextColor(context),
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    ),
                  ),
                ),
                if (suffix != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 13),
                    child: Text(
                      suffix,
                      style: AppTextStyles.dmSans(
                        size: 12,
                        weight: FontWeight.w700,
                        color: theme.getMutedColor(context),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                hint,
                style: AppTextStyles.dmSans(
                  size: 8.5,
                  color: theme.getMutedColor(context).withValues(alpha: 0.75),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDtiBarRow(String label, double val, double maxVal, Color fillCol) {
    final pct = (val / maxVal * 100).clamp(0.0, 100.0);
    return Row(
      children: [
        SizedBox(
          width: 65,
          child: Text(
            label,
            style: AppTextStyles.dmSans(size: 9, color: Colors.white54),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 6,
              color: Colors.white12,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: pct / 100.0,
                child: Container(color: fillCol),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            '${val.toStringAsFixed(0)}%',
            textAlign: TextAlign.right,
            style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _buildAllocLegendItem(String label, Color color, String val) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(
          '$label ',
          style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: Colors.white70),
        ),
        Text(
          val,
          style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w800, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(String label, double amount, {bool isHighlighted = false}) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.getBorderColor(context))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(
              size: 12,
              color: isHighlighted ? theme.primaryColor : theme.getMutedColor(context),
              weight: isHighlighted ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          Text(
            CurrencyFormatter.format(amount),
            style: AppTextStyles.dmSans(
              size: isHighlighted ? 14 : 13,
              color: isHighlighted ? const Color(0xFFB91C1C) : theme.getTextColor(context),
              weight: FontWeight.w800,
            ).copyWith(fontFamily: 'Georgia'),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitsList() {
    final theme = widget.theme;
    final items = [
      ('FHA Loan', 'Max 43% standard · Up to 57% with AUS · 31% front-end', '🏦'),
      ('VA Loan', '41% guideline · No hard max · Residual income key qualifier', '🎖️'),
      ('USDA Rural', '29% front · 41% back · GUS approval may allow more', '🌾'),
      ('Jumbo Loan', 'Max 43% · Stricter reserves required · 720+ FICO typical', '🏢'),
    ];
    return Column(
      children: items.map((item) {
        return GestureDetector(
          onTap: () {
            if (item.$1 == 'FHA Loan') {
              context.push('/tool/usa/fha');
            } else if (item.$1 == 'VA Loan') {
              context.push('/tool/usa/va');
            } else if (item.$1 == 'USDA Rural') {
              context.push('/tool/usa/usda');
            } else if (item.$1 == 'Jumbo Loan') {
              context.push('/tool/usa/jumbo');
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              border: Border.all(color: theme.getBorderColor(context)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.getBgColor(context),
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Text(item.$3, style: const TextStyle(fontSize: 17)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$1,
                      style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: theme.getTextColor(context)).copyWith(fontFamily: 'Georgia'),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.$2,
                      style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList(),
    );
  }
}

class _RateStripItem extends StatelessWidget {
  final String label;
  final String value;
  final String note;
  final bool isGold;

  const _RateStripItem({
    required this.label,
    required this.value,
    required this.note,
    this.isGold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(size: 8.5, color: Colors.grey[500]!, weight: FontWeight.w600, letterSpacing: 0.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.dmSans(
            size: 15,
            weight: FontWeight.w800,
            color: isGold ? const Color(0xFFD97706) : Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF061528),
          ).copyWith(fontFamily: 'Georgia'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          note,
          style: AppTextStyles.dmSans(size: 8, color: Colors.grey[500]!),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class GridViewRules extends StatelessWidget {
  const GridViewRules({super.key});

  @override
  Widget build(BuildContext context) {
    final rules = [
      ('Excellent', '≤ 28%', 'Front-end ideal · All loan types', '✅ Best rates available', const Color(0xFFF0FDF4), const Color(0xFF16A34A)),
      ('Good', '29–36%', 'Back-end conventional limit', '✅ Easily approved', const Color(0xFFF0FDF4), const Color(0xFF16A34A)),
      ('Acceptable', '37–43%', 'FHA standard · Conv. w/ DU', '⚠️ Compensating factors', const Color(0xFFFFFBEB), const Color(0xFFD97706)),
      ('High Risk', '44–50%', 'Conv. max w/ strong FICO', '🔴 Limited lenders', const Color(0xFFFEF2F2), const Color(0xFFB91C1C)),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 9,
      crossAxisSpacing: 9,
      childAspectRatio: 1.45,
      children: rules.map((r) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: r.$5,
            border: Border.all(color: r.$6.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.$1.toUpperCase(),
                style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: Colors.grey[600]!, letterSpacing: 0.5),
              ),
              const SizedBox(height: 2),
              Text(
                r.$2,
                style: AppTextStyles.dmSans(size: 17, weight: FontWeight.w800, color: const Color(0xFF0B1D3A)).copyWith(fontFamily: 'Georgia'),
              ),
              const SizedBox(height: 1),
              Text(
                r.$3,
                style: AppTextStyles.dmSans(size: 9, color: Colors.grey[600]!),
              ),
              const Spacer(),
              Text(
                r.$4,
                style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: r.$6),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

