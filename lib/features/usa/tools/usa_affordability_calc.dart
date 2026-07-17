// lib/features/usa/tools/usa_affordability_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/mortgage_math.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../shared/widgets/live_rate_banner.dart';
import '../../../providers/usa_rates_provider.dart';
import '../../../providers/calculator_draft_provider.dart';
import '../../../../widgets/ads/native_ad_widget.dart';

class USAAffordabilityCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const USAAffordabilityCalc({super.key, this.theme = CountryThemes.usa});

  @override
  ConsumerState<USAAffordabilityCalc> createState() =>
      _USAAffordabilityCalcState();
}

class _USAAffordabilityCalcState extends ConsumerState<USAAffordabilityCalc> {
  // Input Controllers
  final _incomeController = TextEditingController(text: '120000');
  final _debtsController = TextEditingController(text: '400');
  final _taxInsController = TextEditingController(text: '550');

  double _rate = 6.82;
  int _selectedTerm = 30;
  double _selectedDP = 20.0;

  final _resultsKey = GlobalKey();
  bool _hasCalculated = false;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(calculatorDraftProvider);
    if (draft != null) {
      if (draft.interestRate != null) {
        _rate = draft.interestRate!;
      }
      if (draft.loanTermYears != null) {
        _selectedTerm = draft.loanTermYears!;
      }
      if (draft.downPayment != null && draft.propertyPrice != null && draft.propertyPrice! > 0) {
        _selectedDP = (draft.downPayment! / draft.propertyPrice! * 100);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(calculatorDraftProvider.notifier).clearDraft();
      });
    }
  }

  // Stored inputs for calculation
  double _calcIncome = 0.0;
  double _calcDebts = 0.0;
  double _calcTaxIns = 0.0;
  double _calcRate = 6.82;
  int _calcTerm = 30;
  double _calcDP = 20.0;

  // Validation errors
  String? _incomeError;
  String? _debtsError;
  String? _taxInsError;

  @override
  void dispose() {
    _incomeController.dispose();
    _debtsController.dispose();
    _taxInsController.dispose();
    super.dispose();
  }

  double _val(TextEditingController c) => double.tryParse(c.text) ?? 0.0;

  void _resetInputs() {
    setState(() {
      _incomeController.clear();
      _debtsController.clear();
      _taxInsController.clear();
      _rate = 6.82;
      _selectedTerm = 30;
      _selectedDP = 20.0;
      _hasCalculated = false;
      _incomeError = null;
      _debtsError = null;
      _taxInsError = null;
    });
  }

  bool _validateInputs() {
    bool isValid = true;
    setState(() {
      final incomeVal = double.tryParse(_incomeController.text);
      if (_incomeController.text.trim().isEmpty) {
        _incomeError = 'Annual gross income is required';
        isValid = false;
      } else if (incomeVal == null || incomeVal < 0) {
        _incomeError = 'Enter a valid income';
        isValid = false;
      } else {
        _incomeError = null;
      }

      final debtsVal = double.tryParse(_debtsController.text);
      if (_debtsController.text.trim().isEmpty) {
        _debtsError = 'Monthly debt is required';
        isValid = false;
      } else if (debtsVal == null || debtsVal < 0) {
        _debtsError = 'Enter valid debts';
        isValid = false;
      } else {
        _debtsError = null;
      }

      final taxInsVal = double.tryParse(_taxInsController.text);
      if (_taxInsController.text.trim().isEmpty) {
        _taxInsError = 'Tax & insurance are required';
        isValid = false;
      } else if (taxInsVal == null || taxInsVal < 0) {
        _taxInsError = 'Enter valid tax & insurance';
        isValid = false;
      } else {
        _taxInsError = null;
      }
    });
    return isValid;
  }

  void _clearAllSaved() async {
    final affCalcs = ref
        .read(savedProvider)
        .where((c) =>
            c.country == 'USA' && c.calcType == 'Affordability Calculator')
        .toList();
    for (final calc in affCalcs) {
      await ref.read(savedProvider.notifier).delete(calc.id);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All saved calculations cleared',
              style: AppTextStyles.dmSans(
                  color: Colors.white, weight: FontWeight.w700)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _saveCalculation() async {
    if (!_hasCalculated) return;
    final income = _calcIncome;
    final debts = _calcDebts;
    final taxIns = _calcTaxIns;
    final monthlyIncome = income / 12;

    final maxHousing = monthlyIncome * 0.28;
    final maxPI = max(0.0, maxHousing - taxIns);
    final dpFrac = _calcDP / 100;
    final r = _calcRate / 100 / 12;
    final n = _calcTerm * 12;

    double maxLoan = 0.0;
    if (r > 0) {
      maxLoan = maxPI * (1 - pow(1 + r, -n)) / r;
    } else {
      maxLoan = maxPI * n;
    }

    final maxPrice = maxLoan / (1 - dpFrac);
    final downAmt = maxPrice * dpFrac;
    final piAmt = max(
        0.0,
        MortgageMath.monthlyPayment(
            principal: maxLoan,
            annualRatePercent: _calcRate,
            termYears: _calcTerm));
    final pmi = _calcDP < 20 ? maxLoan * 0.0085 / 12 : 0.0;
    final totalPITI = piAmt + taxIns + pmi;

    final labelCtrl = TextEditingController(text: 'Home Affordability');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_affordability_calc/save'),
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
              'Saving: Max Price ${CurrencyFormatter.compact(maxPrice, symbol: '\$')} · Max PITI: ${CurrencyFormatter.compact(totalPITI, symbol: '\$')}/mo · Down: ${_calcDP.toStringAsFixed(0)}%',
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
                hintText: 'Label (e.g. My Affordability Calc)',
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
          : 'Affordability Calculator';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'Affordability Calculator',
        inputs: {
          'AnnualIncome': income,
          'MonthlyDebts': debts,
          'MonthlyTaxIns': taxIns,
          'Rate': _calcRate,
          'Term': _calcTerm.toDouble(),
          'DownPct': _calcDP,
        },
        results: {
          'MaxPurchasePrice': maxPrice,
          'MaxHousingPayment': maxHousing,
          'DownPaymentAmount': downAmt,
          'LoanAmount': maxLoan,
          'TotalPITI': totalPITI,
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

  void _loadSavedCalculation(SavedCalc calc) {
    setState(() {
      _incomeController.text =
          (calc.inputs['AnnualIncome'] ?? 120000.0).toStringAsFixed(0);
      _debtsController.text =
          (calc.inputs['MonthlyDebts'] ?? 400.0).toStringAsFixed(0);
      _taxInsController.text =
          (calc.inputs['MonthlyTaxIns'] ?? 550.0).toStringAsFixed(0);
      _rate = calc.inputs['Rate'] ?? 6.82;
      _selectedTerm = (calc.inputs['Term'] ?? 30.0).round();
      _selectedDP = calc.inputs['DownPct'] ?? 20.0;

      _calcIncome = _val(_incomeController);
      _calcDebts = _val(_debtsController);
      _calcTaxIns = _val(_taxInsController);
      _calcRate = _rate;
      _calcTerm = _selectedTerm;
      _calcDP = _selectedDP;
      _hasCalculated = true;
      _incomeError = null;
      _debtsError = null;
      _taxInsError = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded saved calculation!',
            style: AppTextStyles.dmSans(
                color: Colors.white, weight: FontWeight.w700)),
        backgroundColor: widget.theme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Inputs
    final income = _calcIncome;
    final debts = _calcDebts;
    final taxIns = _calcTaxIns;
    final monthlyIncome = income / 12;

    // 28% front-end -> max housing payment
    final maxHousing = monthlyIncome * 0.28;
    // available P&I = maxHousing - taxIns
    final maxPI = max(0.0, maxHousing - taxIns);
    final dpFrac = _calcDP / 100;
    final r = _calcRate / 100 / 12;
    final n = _calcTerm * 12;

    // max loan from P&I using present value of annuity
    double maxLoan = 0.0;
    if (r > 0) {
      maxLoan = maxPI * (1 - pow(1 + r, -n)) / r;
    } else {
      maxLoan = maxPI * n;
    }

    final maxPrice = maxLoan / (1 - dpFrac);
    final downAmt = maxPrice * dpFrac;
    final piAmt = max(
        0.0,
        MortgageMath.monthlyPayment(
            principal: maxLoan,
            annualRatePercent: _calcRate,
            termYears: _calcTerm));
    final pmi = _calcDP < 20 ? maxLoan * 0.0085 / 12 : 0.0;
    final totalPITI = piAmt + taxIns + pmi;

    // DTI ratios
    final frontRatio =
        monthlyIncome > 0 ? (totalPITI / monthlyIncome * 100) : 0.0;
    final backRatio =
        monthlyIncome > 0 ? ((totalPITI + debts) / monthlyIncome * 100) : 0.0;

    // Scenarios
    final consLoan = max(0.0, monthlyIncome * 0.25 - taxIns);
    double consPrice = 0.0;
    if (r > 0) {
      consPrice = (consLoan * (1 - pow(1 + r, -n)) / r) / (1 - dpFrac);
    } else {
      consPrice = (consLoan * n) / (1 - dpFrac);
    }

    final stretchLoan = max(0.0, monthlyIncome * 0.36 - taxIns);
    double stretchPrice = 0.0;
    if (r > 0) {
      stretchPrice = (stretchLoan * (1 - pow(1 + r, -n)) / r) / (1 - dpFrac);
    } else {
      stretchPrice = (stretchLoan * n) / (1 - dpFrac);
    }

    // 15-yr scenario
    const r15 = 6.11 / 100 / 12;
    const n15 = 15 * 12;
    final maxPI15 = max(0.0, maxHousing - taxIns);
    double maxLoan15 = 0.0;
    if (r15 > 0) {
      maxLoan15 = maxPI15 * (1 - pow(1 + r15, -n15)) / r15;
    } else {
      maxLoan15 = maxPI15 * n15;
    }
    final yr15Price = maxLoan15 / (1 - dpFrac);

    // FHA scenario (3.5% down)
    final maxPIFHA = max(0.0, maxHousing - taxIns - 50); // deduct estimated MIP
    double maxLoanFHA = 0.0;
    if (r > 0) {
      maxLoanFHA = maxPIFHA * (1 - pow(1 + r, -n)) / r;
    } else {
      maxLoanFHA = maxPIFHA * n;
    }
    final fhaPrice =
        maxLoanFHA / 0.965; // 3.5% down means loan is 96.5% of price

    // PITI proportions
    final taxAmt = taxIns * 0.63;
    final insAmt = taxIns * 0.37;
    final piPct = totalPITI > 0 ? (piAmt / totalPITI) : 0.0;
    final taxPct = totalPITI > 0 ? (taxAmt / totalPITI) : 0.0;
    final insPct = totalPITI > 0 ? (insAmt / totalPITI) : 0.0;
    final pmiPct = totalPITI > 0 ? (pmi / totalPITI) : 0.0;

    final piPctInt = (piPct * 100).round();
    final taxPctInt = (taxPct * 100).round();
    final insPctInt = (insPct * 100).round();
    final pmiPctInt = (pmiPct * 100).round();

    final showOutdatedWarning = _hasCalculated && (
      _val(_incomeController) != _calcIncome ||
      _val(_debtsController) != _calcDebts ||
      _val(_taxInsController) != _calcTaxIns ||
      _rate != _calcRate ||
      _selectedTerm != _calcTerm ||
      _selectedDP != _calcDP
    );

    // Saved calculations watch
    final savedCalcs = ref
        .watch(savedProvider)
        .where((c) =>
            c.country == 'USA' && c.calcType == 'Affordability Calculator')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip — Live FRED data
        DarkRateStripBanner(items: [
          RateStripItem(
              label: '30-Yr Fixed',
              provider: fredMortgage30Provider,
              fallback: 6.82),
          RateStripItem(
              label: 'Median Price',
              provider: censusMedianHomeValueProvider,
              fallback: 310000,
              isDollar: true,
              suffix: ''),
          RateStripItem(
              label: 'Max DTI',
              provider: fredMortgage30Provider,
              fallback: 43,
              suffix: '',
              isGold: true),
          RateStripItem(
              label: 'Fed Funds',
              provider: fredFedFundsProvider,
              fallback: 5.33),
        ]),
        const SizedBox(height: 20),

        const SizedBox(height: 20),

        if (_hasCalculated) ...[
          _buildSectionHeader('Your Budget',
              onReset: _resetInputs, resetLabel: 'Clear All'),
          const SizedBox(height: 8),

          if (showOutdatedWarning)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                border: Border.all(color: Colors.amber.shade700, width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('⚠️ ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(
                      'Inputs have changed. Tap Calculate to update results.',
                      style: AppTextStyles.dmSans(
                        size: 11,
                        color: Colors.amber.shade800,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Result Hero
          Container(
            key: _resultsKey,
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
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MAXIMUM HOME PURCHASE PRICE',
                  style: AppTextStyles.dmSans(
                    size: 9.5,
                    weight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.48),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$',
                      style: AppTextStyles.dmSans(
                        size: 18,
                        weight: FontWeight.w800,
                        color: const Color(0xFFFCD34D),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(maxPrice, symbol: '')
                          .split('.')
                          .first,
                      style: AppTextStyles.dmSans(
                        size: 38,
                        weight: FontWeight.w800,
                        color: Colors.white,
                      ).copyWith(fontFamily: 'Georgia'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on 28/36 Rule · ${_calcRate.toStringAsFixed(2)}% rate · ${_calcDP.toInt()}% down · $_calcTerm-yr fixed',
                  style: AppTextStyles.dmSans(
                    size: 10,
                    color: Colors.white.withValues(alpha: 0.52),
                  ),
                ),
                const SizedBox(height: 14),

                // Hero metrics row
                Row(
                  children: [
                    Expanded(
                      child: _buildHeroStat(
                          'Max Monthly Pmt',
                          CurrencyFormatter.format(maxHousing, symbol: '\$')
                              .split('.')
                              .first,
                          '28% of income'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildHeroStat(
                          'Down Payment',
                          CurrencyFormatter.format(downAmt, symbol: '\$')
                              .split('.')
                              .first,
                          '${_calcDP.toInt()}% suggested'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildHeroStat(
                          'Loan Amount',
                          CurrencyFormatter.format(maxLoan, symbol: '\$')
                              .split('.')
                              .first,
                          'Principal balance'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        _buildSectionHeader('Your Financial Info',
            onReset: _resetInputs, resetLabel: 'Reset'),
        const SizedBox(height: 8),

        // Inputs Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('💵 ', style: TextStyle(fontSize: 16)),
                  Text(
                    'Income & Debts',
                    style: AppTextStyles.dmSans(
                      size: 12.5,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context),
                    ).copyWith(fontFamily: 'Georgia'),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Income Input
              _buildInputField(
                label: 'Annual Gross Income',
                controller: _incomeController,
                hint: 'US median family: \$75,000/yr',
                prefix: '\$',
                suffix: '/yr',
                errorText: _incomeError,
              ),
              const SizedBox(height: 12),

              // Debts Input
              _buildInputField(
                label: 'Monthly Debt Payments (car, student loans, etc.)',
                controller: _debtsController,
                hint: 'Minimum payments due monthly',
                prefix: '\$',
                suffix: '/mo',
                errorText: _debtsError,
              ),
              const SizedBox(height: 12),

              // Rate Slider
              _buildSliderSection(
                label: 'Interest Rate',
                value: _rate,
                min: 4.0,
                max: 9.0,
                displayValue: '${_rate.toStringAsFixed(2)}%',
                onChanged: (v) =>
                    setState(() => _rate = double.parse(v.toStringAsFixed(2))),
              ),
              const SizedBox(height: 12),

              // Term selectors
              _buildSelectorRow<int>(
                label: 'Loan Term',
                value: _selectedTerm,
                items: [30, 20, 15, 10],
                labelBuilder: (v) => '$v yr',
                onChanged: (v) => setState(() => _selectedTerm = v),
              ),
              const SizedBox(height: 12),

              // Down Payment selectors
              _buildSelectorRow<double>(
                label: 'Down Payment',
                value: _selectedDP,
                items: [3, 5, 10, 20, 25],
                labelBuilder: (v) => '${v.toInt()}%',
                onChanged: (v) => setState(() => _selectedDP = v),
              ),
              const SizedBox(height: 12),

              // Tax & Ins Input
              _buildInputField(
                label: 'Monthly Property Tax + Insurance (est.)',
                controller: _taxInsController,
                hint: 'Property taxes & homeowner insurance',
                prefix: '\$',
                suffix: '/mo',
                errorText: _taxInsError,
              ),
              const SizedBox(height: 16),

              // Calculate and Save Buttons inside Inputs Card
              GestureDetector(
                onTap: () {
                  if (_validateInputs()) {
                    setState(() {
                      _calcIncome = _val(_incomeController);
                      _calcDebts = _val(_debtsController);
                      _calcTaxIns = _val(_taxInsController);
                      _calcRate = _rate;
                      _calcTerm = _selectedTerm;
                      _calcDP = _selectedDP;
                      _hasCalculated = true;
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_resultsKey.currentContext != null) {
                        Scrollable.ensureVisible(
                          _resultsKey.currentContext!,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      }
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0B1D3A).withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '🏠 Calculate My Affordability',
                    style: AppTextStyles.dmSans(
                      size: 13,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ).copyWith(fontFamily: 'Georgia'),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              GestureDetector(
                onTap: _hasCalculated ? _saveCalculation : null,
                child: Opacity(
                  opacity: _hasCalculated ? 1.0 : 0.5,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF166534).withValues(alpha: 0.2)
                          : const Color(0xFFDCFCE7),
                      border:
                          Border.all(color: const Color(0xFF15803D), width: 1.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('💾', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Text(
                          'Save This Calculation',
                          style: AppTextStyles.dmSans(
                            size: 13,
                            weight: FontWeight.w800,
                            color: isDark
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFF15803D),
                          ).copyWith(fontFamily: 'Georgia'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
           if (_hasCalculated) ...[
          const SizedBox(height: 20),
          _buildSectionHeader('Qualification Check', onReset: null),
          const SizedBox(height: 8),

          // Qualification Card (using HTML rule-card style)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0A2E1A) : const Color(0xFFF0FDF4),
              border: Border.all(
                  color: isDark
                      ? const Color(0xFF15803D).withValues(alpha: 0.5)
                      : const Color(0xFF86EFAC)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📏 28 / 36 Rule · FHA 43% DTI',
                  style: AppTextStyles.dmSans(
                    size: 12,
                    weight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFF15803D),
                  ).copyWith(fontFamily: 'Georgia'),
                ),
                const SizedBox(height: 10),
                _buildRatioRow(
                    'Front-End Ratio (Housing / Income)', frontRatio, 28.0, 35.0),
                const SizedBox(height: 8),
                _buildRatioRow(
                    'Back-End Ratio (All Debts / Income)', backRatio, 36.0, 43.0),
                const SizedBox(height: 8),
                _buildRatioRow('FHA Max DTI (43%)', backRatio, 43.0, 50.0,
                    customGoodText: '✓ Qualifies'),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _buildSectionHeader('Monthly Payment Breakdown', onReset: null),
          const SizedBox(height: 8),

          // Breakdown Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.getBorderColor(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.dmSans(
                      size: 12.5,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context),
                    ).copyWith(fontFamily: 'Georgia'),
                    children: [
                      const TextSpan(text: 'Total Estimated PITI — '),
                      TextSpan(
                        text:
                            '${CurrencyFormatter.format(totalPITI, symbol: '\$').split('.').first}/mo',
                        style: TextStyle(
                            color: isDark
                                ? const Color(0xFF93C5FD)
                                : const Color(0xFF1B3F72)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Progress Bar composition
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 8,
                    width: double.infinity,
                    child: Row(
                      children: [
                        if (piPctInt > 0)
                          Expanded(
                            flex: piPctInt,
                            child: Container(color: const Color(0xFF1B3F72)),
                          ),
                        if (taxPctInt > 0)
                          Expanded(
                            flex: taxPctInt,
                            child: Container(color: const Color(0xFFD97706)),
                          ),
                        if (insPctInt > 0)
                          Expanded(
                            flex: insPctInt,
                            child: Container(color: const Color(0xFF15803D)),
                          ),
                        if (pmiPctInt > 0)
                          Expanded(
                            flex: pmiPctInt,
                            child: Container(color: const Color(0xFFB91C1C)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Donut Row
                Row(
                  children: [
                    CustomPaint(
                      size: const Size(92, 92),
                      painter: _AffordabilityDonutPainter(
                        piPct: piPct,
                        taxPct: taxPct,
                        insPct: insPct,
                        pmiPct: pmiPct,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _buildDonutLegendRow(
                            color: const Color(0xFF1B3F72),
                            label: 'Principal & Interest',
                            value: '$piPctInt%',
                          ),
                          const SizedBox(height: 6),
                          _buildDonutLegendRow(
                            color: const Color(0xFFD97706),
                            label: 'Property Tax',
                            value: '$taxPctInt%',
                          ),
                          const SizedBox(height: 6),
                          _buildDonutLegendRow(
                            color: const Color(0xFF15803D),
                            label: 'Insurance',
                            value: '$insPctInt%',
                          ),
                          if (pmiPctInt > 0) ...[
                            const SizedBox(height: 6),
                            _buildDonutLegendRow(
                              color: const Color(0xFFB91C1C),
                              label: 'PMI',
                              value: '$pmiPctInt%',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Detail List
                _buildBreakdownItemDetail(
                    'Principal & Interest',
                    '$_calcTerm yr @ ${_calcRate.toStringAsFixed(2)}%',
                    piAmt,
                    piPctInt,
                    const Color(0xFF1B3F72)),
                _buildBreakdownItemDetail(
                    'Property Tax (est.)',
                    'Avg 1.1% annually',
                    taxAmt,
                    taxPctInt,
                    const Color(0xFFD97706)),
                _buildBreakdownItemDetail(
                    'Homeowner\'s Insurance',
                    'HO-3 policy est.',
                    insAmt,
                    insPctInt,
                    const Color(0xFF15803D)),
                if (pmi > 0)
                  _buildBreakdownItemDetail(
                      'PMI (Private Mortgage Ins.)',
                      '< 20% down · ~0.5–1.5%',
                      pmi,
                      pmiPctInt,
                      const Color(0xFFB91C1C)),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const NativeAdWidget(
            screenName: 'usa_affordability_calc',
            adType: 'mediumCard',
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Budget Scenarios', onReset: null),
          const SizedBox(height: 8),

          // Scenarios Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.25,
            children: [
              _buildScenarioCard(
                title: 'Conservative',
                price: consPrice,
                subtitle:
                    '${CurrencyFormatter.format(monthlyIncome * 0.25, symbol: '\$').split('.').first}/mo · 25% DTI',
                isHighlight: true,
                highlightColor1: const Color(0xFF0B1D3A),
                highlightColor2: const Color(0xFF1B3F72),
              ),
              _buildScenarioCard(
                title: 'Stretch Budget',
                price: stretchPrice,
                subtitle:
                    '${CurrencyFormatter.format(monthlyIncome * 0.36, symbol: '\$').split('.').first}/mo · 36% DTI',
                isHighlight: true,
                highlightColor1: const Color(0xFFD97706),
                highlightColor2: const Color(0xFFB45309),
              ),
              _buildScenarioCard(
                title: '15-Yr Fixed @ 6.11%',
                price: yr15Price,
                subtitle: 'Higher pmt, less interest',
                isHighlight: false,
              ),
              _buildScenarioCard(
                title: 'FHA 3.5% Down',
                price: fhaPrice,
                subtitle: '580+ FICO · with MIP',
                isHighlight: false,
              ),
            ],
          ),

        // Saved Calculations History Panel
        const SizedBox(height: 20),
        _buildSectionHeader(
          'Saved Calculations',
          onReset: savedCalcs.isNotEmpty ? _clearAllSaved : null,
          resetLabel: 'Clear All',
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: savedCalcs.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      'No saved calculations yet. Tap "Save This Calculation" above to bookmark a scenario.',
                      style: AppTextStyles.dmSans(
                        size: 11,
                        color: theme.getMutedColor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: savedCalcs.map((calc) {
                    final isLast =
                        savedCalcs.indexOf(calc) == savedCalcs.length - 1;
                    final incomeVal = calc.inputs['AnnualIncome'] ?? 0.0;
                    final rateVal = calc.inputs['Rate'] ?? 0.0;
                    final termVal = calc.inputs['Term'] ?? 30.0;
                    final dpVal = calc.inputs['DownPct'] ?? 20.0;
                    final maxPriceVal = calc.results['MaxPurchasePrice'] ?? 0.0;
                    final totalPitiVal = calc.results['TotalPITI'] ?? 0.0;

                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isLast
                                ? Colors.transparent
                                : theme
                                    .getBorderColor(context)
                                    .withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _loadSavedCalculation(calc),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${CurrencyFormatter.compact(maxPriceVal, symbol: '\$')} @ ${rateVal.toStringAsFixed(2)}% · ${termVal.toStringAsFixed(0)}yr',
                                    style: AppTextStyles.dmSans(
                                      size: 12,
                                      weight: FontWeight.w800,
                                      color: theme.getTextColor(context),
                                    ).copyWith(fontFamily: 'Georgia'),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Income ${CurrencyFormatter.compact(incomeVal, symbol: '\$')}/yr · ${dpVal.toStringAsFixed(0)}% down · PITI ${CurrencyFormatter.compact(totalPitiVal, symbol: '\$')}/mo',
                                    style: AppTextStyles.dmSans(
                                      size: 9.5,
                                      color: theme.getMutedColor(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              await ref
                                  .read(savedProvider.notifier)
                                  .delete(calc.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Removed saved calculation',
                                        style: AppTextStyles.dmSans(
                                            color: Colors.white,
                                            weight: FontWeight.w700)),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child:
                                  Text('🗑️', style: TextStyle(fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),

        const SizedBox(height: 20),
        _buildSectionHeader('Next Steps', onReset: null),
        const SizedBox(height: 8),

        // Next steps links
        Column(
          children: [
            _buildNextStepCard(
              '🔑',
              'Down Payment Calculator',
              '3% · 5% · 10% · 20% · savings timeline',
              onTap: () => context.push('/tool/usa/downpayment'),
            ),
            const SizedBox(height: 9),
            _buildNextStepCard(
              '💳',
              'Credit Score Impact',
              'How your FICO affects your rate',
              onTap: () => context.push('/tool/usa/creditscore'),
            ),
            const SizedBox(height: 9),
            _buildNextStepCard(
              '🏦',
              'Get Pre-Approved',
              'Rocket · Chase · Wells Fargo · UWM',
              onTap: () => context.push('/usa/top-lenders'),
            ),
            const SizedBox(height: 9),
            _buildNextStepCard(
              '📊',
              'Full Mortgage Calculator',
              'PITI with amortization schedule',
              onTap: () => context.push('/tool/usa/piti'),
            ),
          ],
        ),
      ],
    ],
  );
}

  Widget _buildSectionHeader(String title,
      {VoidCallback? onReset, String? resetLabel}) {
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
              resetLabel ?? 'Reset →',
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

  Widget _buildHeroStat(String label, String value, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(
              size: 8,
              weight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.45),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.dmSans(
              size: 14,
              weight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            sub,
            style: AppTextStyles.dmSans(
              size: 8,
              color: Colors.white.withValues(alpha: 0.38),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    String? prefix,
    String? suffix,
    String? errorText,
  }) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
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
            border: Border.all(
              color: errorText != null ? Colors.red : theme.getBorderColor(context),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(11),
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
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: AppTextStyles.dmSans(
                    size: 14,
                    weight: FontWeight.w700,
                    color: theme.getTextColor(context),
                  ).copyWith(fontFamily: 'Georgia'),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 11),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.only(right: 13, left: 10),
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
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: AppTextStyles.dmSans(
              size: 10,
              color: Colors.red,
              weight: FontWeight.w500,
            ),
          ),
        ],
        if (hint.isNotEmpty && errorText == null) ...[
          const SizedBox(height: 3),
          Text(
            hint,
            style: AppTextStyles.dmSans(
              size: 8.5,
              weight: FontWeight.w500,
              color: theme.getMutedColor(context).withValues(alpha: 0.75),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSliderSection({
    required String label,
    required double value,
    required double min,
    required double max,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              style: AppTextStyles.dmSans(
                size: 9.5,
                weight: FontWeight.w700,
                color: widget.theme.getMutedColor(context),
                letterSpacing: 0.5,
              ),
            ),
            Text(
              displayValue,
              style: AppTextStyles.dmSans(
                size: 12,
                weight: FontWeight.w800,
                color: widget.theme.getTextColor(context),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: widget.theme.primaryColor,
            thumbColor: widget.theme.primaryColor,
            inactiveTrackColor:
                widget.theme.primaryColor.withValues(alpha: 0.15),
            overlayColor: widget.theme.primaryColor.withValues(alpha: 0.15),
            trackHeight: 3,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: 100,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${min.toStringAsFixed(2)}%',
              style: AppTextStyles.dmSans(
                size: 9,
                weight: FontWeight.w600,
                color: widget.theme.getMutedColor(context),
              ),
            ),
            Text(
              '${max.toStringAsFixed(2)}%',
              style: AppTextStyles.dmSans(
                size: 9,
                weight: FontWeight.w600,
                color: widget.theme.getMutedColor(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectorRow<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T> onChanged,
  }) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 9.5,
            weight: FontWeight.w700,
            color: theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: items.map((item) {
            final isActive = item == value;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(item),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF0B1D3A)
                        : theme.getBgColor(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF0B1D3A)
                          : theme.getBorderColor(context),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labelBuilder(item),
                    style: AppTextStyles.dmSans(
                      size: 11,
                      weight: FontWeight.w700,
                      color: isActive
                          ? Colors.white
                          : theme.getMutedColor(context),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRatioRow(
      String label, double val, double idealLimit, double maxLimit,
      {String? customGoodText}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String badgeText;
    Color badgeColor;
    Color badgeBg;

    if (val <= idealLimit) {
      badgeText = customGoodText ?? '✓ Good';
      badgeColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
      badgeBg = isDark ? const Color(0xFF0F3A1D) : const Color(0xFFDCFCE7);
    } else if (val <= maxLimit) {
      badgeText = '⚠ High';
      badgeColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
      badgeBg = isDark ? const Color(0xFF2E1B0F) : const Color(0xFFFEF3C7);
    } else {
      badgeText = '✗ Over';
      badgeColor = isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
      badgeBg = isDark ? const Color(0xFF3F1616) : const Color(0xFFFEF2F2);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.dmSans(
                size: 10.5,
                weight: FontWeight.w600,
                color:
                    isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
              ),
            ),
          ),
          Row(
            children: [
              Text(
                '${val.toStringAsFixed(1)}%',
                style: AppTextStyles.dmSans(
                  size: 12,
                  weight: FontWeight.w800,
                  color: isDark
                      ? const Color(0xFF4ADE80)
                      : const Color(0xFF15803D),
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: AppTextStyles.dmSans(
                    size: 10,
                    weight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItemDetail(
      String label, String sub, double value, int pct, Color color) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
            bottom:
                BorderSide(color: theme.getBorderColor(context), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.dmSans(
                      size: 12,
                      weight: FontWeight.w600,
                      color: theme.getTextColor(context),
                    ),
                  ),
                  Text(
                    sub,
                    style: AppTextStyles.dmSans(
                      size: 9.5,
                      color: theme.getMutedColor(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(value, symbol: '\$').split('.').first,
                style: AppTextStyles.dmSans(
                  size: 13,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context),
                ).copyWith(fontFamily: 'Georgia'),
              ),
              Text(
                '$pct%',
                style: AppTextStyles.dmSans(
                  size: 9.5,
                  color: theme.getMutedColor(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioCard({
    required String title,
    required double price,
    required String subtitle,
    required bool isHighlight,
    Color? highlightColor1,
    Color? highlightColor2,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dec = isHighlight
        ? BoxDecoration(
            gradient:
                LinearGradient(colors: [highlightColor1!, highlightColor2!]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
            ],
          )
        : BoxDecoration(
            color: isDark ? widget.theme.getCardColor(context) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.theme.getBorderColor(context)),
          );

    final titleColor =
        isHighlight ? Colors.white60 : widget.theme.getMutedColor(context);
    final priceColor =
        isHighlight ? Colors.white : widget.theme.getTextColor(context);
    final subColor =
        isHighlight ? Colors.white54 : widget.theme.getMutedColor(context);
    final arrowColor = isHighlight
        ? Colors.white.withValues(alpha: 0.22)
        : widget.theme.getMutedColor(context).withValues(alpha: 0.16);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: dec,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title.toUpperCase(),
                style: AppTextStyles.dmSans(
                  size: 8.5,
                  weight: FontWeight.w700,
                  color: titleColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                price >= 1000
                    ? '\$${(price / 1000).toStringAsFixed(0)}K'
                    : CurrencyFormatter.format(price, symbol: '\$')
                        .split('.')
                        .first,
                style: AppTextStyles.dmSans(
                  size: 18,
                  weight: FontWeight.w800,
                  color: priceColor,
                ).copyWith(fontFamily: 'Georgia'),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.dmSans(
                  size: 9,
                  color: subColor,
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Text(
              '',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w300,
                color: arrowColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepCard(String emoji, String title, String subtitle,
      {VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: widget.theme.getCardColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.theme.getBorderColor(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
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
                  Text(
                    title,
                    style: AppTextStyles.dmSans(
                      size: 12.5,
                      weight: FontWeight.w800,
                      color: widget.theme.getTextColor(context),
                    ).copyWith(fontFamily: 'Georgia'),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.dmSans(
                      size: 9.5,
                      color: widget.theme.getMutedColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color:
                  widget.theme.getMutedColor(context).withValues(alpha: 0.18),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonutLegendRow({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w700,
                color: widget.theme.getTextColor(context)),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.dmSans(
              size: 11,
              weight: FontWeight.w800,
              color: widget.theme.getTextColor(context)),
        ),
      ],
    );
  }
}

class _AffordabilityDonutPainter extends CustomPainter {
  final double piPct;
  final double taxPct;
  final double insPct;
  final double pmiPct;
  final bool isDark;

  _AffordabilityDonutPainter({
    required this.piPct,
    required this.taxPct,
    required this.insPct,
    required this.pmiPct,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const strokeWidth = 13.0;

    final paintBg = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F4FF)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, paintBg);

    final total = piPct + taxPct + insPct + pmiPct;
    if (total <= 0) return;

    // Normalize so they sum to 1.0 for painting segments precisely
    final normPI = piPct / total;
    final normTax = taxPct / total;
    final normIns = insPct / total;
    final normPmi = pmiPct / total;

    double startAngle = -pi / 2;

    if (normPI > 0) {
      final sweep = 2 * pi * normPI;
      final paintPI = Paint()
        ..color = const Color(0xFF1B3F72)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, sweep, false, paintPI);
      startAngle += sweep;
    }

    if (normTax > 0) {
      final sweep = 2 * pi * normTax;
      final paintTax = Paint()
        ..color = const Color(0xFFD97706)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, sweep, false, paintTax);
      startAngle += sweep;
    }

    if (normIns > 0) {
      final sweep = 2 * pi * normIns;
      final paintIns = Paint()
        ..color = const Color(0xFF15803D)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, sweep, false, paintIns);
      startAngle += sweep;
    }

    if (normPmi > 0) {
      final sweep = 2 * pi * normPmi;
      final paintPmi = Paint()
        ..color = const Color(0xFFB91C1C)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, sweep, false, paintPmi);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
