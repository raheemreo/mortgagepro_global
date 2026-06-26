// lib/features/usa/tools/usa_jumbo_loan_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/mortgage_math.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import 'package:go_router/go_router.dart';
import 'usa_fha_loan_calc.dart'; // For ChecklistStatus
import '../../../shared/widgets/live_rate_banner.dart';
import '../../../providers/usa_rates_provider.dart';

class USAJumboLoanCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;
  const USAJumboLoanCalc({super.key, this.theme = CountryThemes.usa, this.savedCalc});

  @override
  ConsumerState<USAJumboLoanCalc> createState() => _USAJumboLoanCalcState();
}

class _USAJumboLoanCalcState extends ConsumerState<USAJumboLoanCalc> {
  // Input Controllers
  final _homePriceController = TextEditingController(text: '1200000');
  final _downPctController = TextEditingController(text: '20');
  final _rateController = TextEditingController(text: '7.04');
  final _annualIncomeController = TextEditingController(text: '350000');
  final _propTaxController = TextEditingController(text: '15000');
  final _insuranceController = TextEditingController(text: '4800');

  int _selectedTerm = 30;
  int _selectedScore = 720;
  bool _showResults = false;
  bool _isCalcDirty = true;

  @override
  void initState() {
    super.initState();
    _homePriceController.addListener(_markDirty);
    _downPctController.addListener(_markDirty);
    _rateController.addListener(_markDirty);
    _annualIncomeController.addListener(_markDirty);
    _propTaxController.addListener(_markDirty);
    _insuranceController.addListener(_markDirty);
    if (widget.savedCalc != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadSavedCalculation(widget.savedCalc!);
      });
    }
  }

  @override
  void dispose() {
    _homePriceController.removeListener(_markDirty);
    _downPctController.removeListener(_markDirty);
    _rateController.removeListener(_markDirty);
    _annualIncomeController.removeListener(_markDirty);
    _propTaxController.removeListener(_markDirty);
    _insuranceController.removeListener(_markDirty);

    _homePriceController.dispose();
    _downPctController.dispose();
    _rateController.dispose();
    _annualIncomeController.dispose();
    _propTaxController.dispose();
    _insuranceController.dispose();
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
      _homePriceController.text = '1200000';
      _downPctController.text = '20';
      _rateController.text = '7.04';
      _annualIncomeController.text = '350000';
      _propTaxController.text = '15000';
      _insuranceController.text = '4800';
      _selectedTerm = 30;
      _selectedScore = 720;
      _showResults = false;
      _isCalcDirty = true;
    });
  }

  void _loadSavedCalculation(SavedCalc calc) {
    setState(() {
      _homePriceController.text = (calc.inputs['HomePrice'] ?? 1200000.0).toStringAsFixed(0);
      _downPctController.text = (calc.inputs['DownPaymentPct'] ?? 20.0).toStringAsFixed(0);
      _rateController.text = (calc.inputs['InterestRate'] ?? 7.04).toStringAsFixed(2);
      _annualIncomeController.text = (calc.inputs['AnnualIncome'] ?? 350000.0).toStringAsFixed(0);
      _propTaxController.text = (calc.inputs['PropertyTax'] ?? 15000.0).toStringAsFixed(0);
      _insuranceController.text = (calc.inputs['HomeInsurance'] ?? 4800.0).toStringAsFixed(0);
      _selectedTerm = (calc.inputs['LoanTerm'] ?? 30.0).toInt();
      _selectedScore = (calc.inputs['CreditScore'] ?? 720.0).toInt();
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
    final price = _val(_homePriceController);
    final downPctRaw = _val(_downPctController);
    final downPct = downPctRaw / 100;
    final rateAnnual = _val(_rateController);
    final annualIncome = _val(_annualIncomeController);
    final propTaxAnnual = _val(_propTaxController);
    final insAnnual = _val(_insuranceController);

    final downAmt = price * downPct;
    final loanAmt = max(0.0, price - downAmt);

    final double pi = MortgageMath.monthlyPayment(
      principal: loanAmt,
      annualRatePercent: rateAnnual,
      termYears: _selectedTerm,
    );

    final pmiMonthly = downPct < 0.20 ? (loanAmt * 0.0080) / 12 : 0.0;
    final taxMonthly = propTaxAnnual / 12;
    final insMonthly = insAnnual / 12;
    final total = pi + pmiMonthly + taxMonthly + insMonthly;

    final isJumbo = loanAmt > 766550;

    final labelCtrl = TextEditingController(text: 'Jumbo Loan');
    final confirmed = await showDialog<bool>(
      context: context,
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
              'Saving: Jumbo Monthly Payment: ${CurrencyFormatter.format(total, symbol: '\$').split('.').first} · ${isJumbo ? "Jumbo" : "Conforming"}',
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
                hintText: 'Label (e.g. Luxury Estate)',
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
          : 'Jumbo Loan';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'Jumbo Loan Calculator',
        inputs: {
          'HomePrice': price,
          'DownPaymentPct': downPctRaw,
          'InterestRate': rateAnnual,
          'LoanTerm': _selectedTerm.toDouble(),
          'AnnualIncome': annualIncome,
          'PropertyTax': propTaxAnnual,
          'HomeInsurance': insAnnual,
          'CreditScore': _selectedScore.toDouble(),
        },
        results: {
          'MonthlyPayment': total,
          'DownPaymentAmt': downAmt,
          'LoanAmount': loanAmt,
          'PMIMonthly': pmiMonthly,
          'IsJumbo': isJumbo ? 1.0 : 0.0,
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
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final price = _val(_homePriceController);
    final downPctRaw = _val(_downPctController);
    final downPct = downPctRaw / 100;
    final rateAnnual = _val(_rateController);
    final annualIncome = _val(_annualIncomeController);
    final propTaxAnnual = _val(_propTaxController);
    final insAnnual = _val(_insuranceController);

    // Calculations
    final downAmt = price * downPct;
    final loanAmt = max(0.0, price - downAmt);
    final months = _selectedTerm * 12;

    final double piVal = MortgageMath.monthlyPayment(
      principal: loanAmt,
      annualRatePercent: rateAnnual,
      termYears: _selectedTerm,
    );

    // PMI applies if down payment is less than 20%
    final pmiMonthly = downPct < 0.20 ? (loanAmt * 0.0080) / 12 : 0.0;
    final taxMonthly = propTaxAnnual / 12;
    final insMonthly = insAnnual / 12;
    final total = piVal + pmiMonthly + taxMonthly + insMonthly;
    final totalInterest = (piVal * months) - loanAmt;

    // Debt-To-Income
    final monthlyIncome = annualIncome > 0 ? (annualIncome / 12) : 1.0;
    final dti = total / monthlyIncome * 100;

    // Checks
    final isJumbo = loanAmt > 766550;
    final isScoreEligible = _selectedScore >= 700;
    final isDownEligible = downPct >= 0.10;
    final isDtiEligible = dti <= 43.0;

    String formattedInterest;
    if (totalInterest >= 1000000) {
      formattedInterest = '\$${(totalInterest / 1000000).toStringAsFixed(2)}M';
    } else {
      formattedInterest = '\$${(totalInterest / 1000).toStringAsFixed(0)}K';
    }

    // Donut segments calculations
    final piPct = total > 0 ? (piVal / total) : 0.0;
    final pmiPct = total > 0 ? (pmiMonthly / total) : 0.0;
    final taxPct = total > 0 ? (taxMonthly / total) : 0.0;
    final insPct = total > 0 ? (insMonthly / total) : 0.0;

    // Amortization snapshot calculation
    final snapYears = [1, 5, 10, 15, 20, 25, 30].where((y) => y <= _selectedTerm).toList();
    final List<Map<String, dynamic>> snapData = [];
    double tempBal = loanAmt;
    double totalPaidP = 0.0;
    double totalPaidI = 0.0;
    final double mr = (rateAnnual / 100) / 12;
    for (int m = 1; m <= months; m++) {
      final interestVal = tempBal * mr;
      final principalVal = piVal - interestVal;
      totalPaidP += principalVal;
      totalPaidI += interestVal;
      tempBal -= principalVal;
      if (snapYears.contains((m / 12).round()) && m % 12 == 0) {
        snapData.add({
          'yr': (m / 12).round(),
          'bal': max(0.0, tempBal),
          'totP': totalPaidP,
          'totI': totalPaidI,
        });
      }
    }
    final maxTot = snapData.isNotEmpty ? (snapData.last['totP'] + snapData.last['totI'] as double) : 1.0;

    // Watch saved calculations
    final savedCalcs = ref.watch(savedProvider).where((c) => c.country == 'USA' && c.calcType == 'Jumbo Loan Calculator').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Rate Strip — Live FRED data
        DarkRateStripBanner(items: [
          RateStripItem(label: 'Jumbo 30-Yr', provider: fredMortgage30Provider, fallback: 7.04),
          RateStripItem(label: 'Jumbo 15-Yr', provider: fredMortgage15Provider, fallback: 6.62),
          RateStripItem(label: 'FHFA Limit', provider: censusMedianHomeValueProvider, fallback: 766000, isDollar: true, suffix: '', isGold: true),
          RateStripItem(label: 'Fed Funds', provider: fredFedFundsProvider, fallback: 5.33),
        ]),
        const SizedBox(height: 16),

        _buildSectionHeader('Loan Details', onReset: _resetInputs),
        const SizedBox(height: 8),

        // Luxury Banner
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1D3A), Color(0xFF334155)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Text('🏢', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Luxury & High-Value Home Financing',
                      style: AppTextStyles.dmSans(
                        size: 13,
                        weight: FontWeight.w800,
                        color: const Color(0xFFFCD34D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '2025 Conforming Limit: \$766,550 standard · \$1,149,825 high-cost.',
                      style: AppTextStyles.dmSans(
                        size: 9.5,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

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
                  const Text('🏢 ', style: TextStyle(fontSize: 16)),
                  Text(
                    'Jumbo Purchase Parameters',
                    style: AppTextStyles.dmSans(
                      size: 13,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Inputs Grid
              Row(
                children: [
                  Expanded(
                    child: _buildInputField('Home Price', _homePriceController, prefix: '\$', hint: 'Must exceed \$766,550'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField('Down Payment', _downPctController, suffix: '%', hint: 'Typically 10–30%'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildInputField('Interest Rate', _rateController, suffix: '%'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownField<int>(
                      label: 'Loan Term',
                      value: _selectedTerm,
                      items: const [
                        DropdownMenuItem(value: 30, child: Text('30 Years')),
                        DropdownMenuItem(value: 20, child: Text('20 Years')),
                        DropdownMenuItem(value: 15, child: Text('15 Years')),
                        DropdownMenuItem(value: 10, child: Text('10 Years')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedTerm = val;
                            _isCalcDirty = true;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField<int>(
                      label: 'Credit Score',
                      value: _selectedScore,
                      items: const [
                        DropdownMenuItem(value: 700, child: Text('700–719')),
                        DropdownMenuItem(value: 720, child: Text('720–759')),
                        DropdownMenuItem(value: 760, child: Text('760–850')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedScore = val;
                            _isCalcDirty = true;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField('Annual Income', _annualIncomeController, prefix: '\$', hint: 'Used for DTI check'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildInputField('Property Tax', _propTaxController, prefix: '\$', suffix: '/yr'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField('Home Insurance', _insuranceController, prefix: '\$', suffix: '/yr'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Calculate & Save buttons
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF334155), Color(0xFF1E293B)]),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF334155).withValues(alpha: _isCalcDirty ? 0.45 : 0.25),
                              blurRadius: _isCalcDirty ? 16 : 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '🏢 Calculate Jumbo Payment',
                          style: AppTextStyles.dmSans(
                            size: 13,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: theme.getCardColor(context),
                          border: Border.all(color: theme.getBorderColor(context), width: 1.5),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2)),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '🔖 Save',
                          style: AppTextStyles.dmSans(
                            size: 13,
                            weight: FontWeight.w800,
                            color: theme.getTextColor(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Saved list
        if (savedCalcs.isNotEmpty) ...[
          _buildSectionHeader(
            'Saved Calculations',
            onReset: () async {
              for (final calc in savedCalcs) {
                await ref.read(savedProvider.notifier).delete(calc.id);
              }
              if (mounted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('All saved calculations cleared!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            resetLabel: 'Clear All',
            countBadge: savedCalcs.length,
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: savedCalcs.length,
            itemBuilder: (context, index) {
              final calc = savedCalcs[index];
              final priceVal = calc.inputs['HomePrice'] ?? 0.0;
              final downVal = calc.inputs['DownPaymentPct'] ?? 0.0;
              final dtiVal = calc.results['MonthlyPayment'] != null && calc.inputs['AnnualIncome'] != null && calc.inputs['AnnualIncome']! > 0
                  ? (calc.results['MonthlyPayment']! / (calc.inputs['AnnualIncome']! / 12) * 100)
                  : 0.0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: theme.getCardColor(context),
                  borderRadius: BorderRadius.circular(14),
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
                              style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${(priceVal / 1000000).toStringAsFixed(2)}M home · ${downVal.toStringAsFixed(0)}% down · DTI ${dtiVal.toStringAsFixed(1)}%',
                              style: AppTextStyles.dmSans(size: 9.0, color: theme.getMutedColor(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CurrencyFormatter.compact(calc.results['MonthlyPayment'] ?? 0.0, symbol: '\$'),
                      style: AppTextStyles.dmSans(
                        size: 13,
                        weight: FontWeight.w800,
                        color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1B3F72),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      color: theme.getMutedColor(context).withValues(alpha: 0.5),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        await ref.read(savedProvider.notifier).delete(calc.id);
                        if (mounted && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
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
          const SizedBox(height: 12),
        ],

        if (!_showResults)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            alignment: Alignment.center,
            child: Column(
              children: [
                const Text('🏢', style: TextStyle(fontSize: 42)),
                const SizedBox(height: 10),
                Text(
                  'Enter Your Loan Details Above',
                  style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context)),
                ),
                const SizedBox(height: 4),
                Text(
                  'We\'ll calculate your monthly Jumbo payment,\nDTI ratio, amortization forecast, and verify standard requirements.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.dmSans(size: 10.5, color: theme.getMutedColor(context)),
                ),
              ],
            ),
          )
        else ...[
          _buildSectionHeader('Monthly Payment Breakdown', onReset: null),
          const SizedBox(height: 8),

          // Result Hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B1D3A), Color(0xFF334155)],
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
                  'TOTAL MONTHLY PAYMENT (PITI)',
                  style: AppTextStyles.dmSans(
                    size: 9.5,
                    weight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.5),
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
                      CurrencyFormatter.format(total, symbol: '').split('.').first,
                      style: AppTextStyles.dmSans(
                        size: 38,
                        weight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      ' /mo',
                      style: AppTextStyles.dmSans(
                        size: 16,
                        weight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Loan: ${CurrencyFormatter.format(loanAmt, symbol: '\$').split('.').first} · Down: ${CurrencyFormatter.format(downAmt, symbol: '\$').split('.').first} (${downPctRaw.toStringAsFixed(0)}%) · ${downPct >= 0.20 ? "No PMI" : "PMI applies"}',
                  style: AppTextStyles.dmSans(
                    size: 10,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSubHeroStat('Front DTI', '${dti.toStringAsFixed(1)}%'),
                    _buildSubHeroStat('Loan Amt', loanAmt >= 1000000 ? '\$${(loanAmt / 1000000).toStringAsFixed(2)}M' : '\$${(loanAmt / 1000).toStringAsFixed(0)}K'),
                    _buildSubHeroStat('Total Interest', formattedInterest),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Donut Composition Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.getBorderColor(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📊 PAYMENT COMPOSITION',
                  style: AppTextStyles.dmSans(
                    size: 10.5,
                    weight: FontWeight.w800,
                    color: theme.getTextColor(context),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(110, 110),
                          painter: _JumboDonutPainter(
                            piPct: piPct,
                            pmiPct: pmiPct,
                            taxPct: taxPct,
                            insPct: insPct,
                            isDark: isDark,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              CurrencyFormatter.format(total, symbol: '\$').split('.').first,
                              style: AppTextStyles.dmSans(
                                size: 13,
                                weight: FontWeight.w800,
                                color: theme.getTextColor(context),
                              ),
                            ),
                            Text(
                              '/mo',
                              style: AppTextStyles.dmSans(
                                size: 7.5,
                                weight: FontWeight.w700,
                                color: theme.getMutedColor(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [
                          _buildDonutLegendRow('P&I', CurrencyFormatter.format(piVal), const Color(0xFF1B3F72)),
                          const SizedBox(height: 8),
                          _buildDonutLegendRow('PMI', CurrencyFormatter.format(pmiMonthly), const Color(0xFFD97706)),
                          const SizedBox(height: 8),
                          _buildDonutLegendRow('Tax', CurrencyFormatter.format(taxMonthly), const Color(0xFF4A5C7A)),
                          const SizedBox(height: 8),
                          _buildDonutLegendRow('Insurance', CurrencyFormatter.format(insMonthly), const Color(0xFF334155)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 6-Card Breakdown Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.22,
            children: [
              _buildMetricCard('💵', 'Principal & Interest', CurrencyFormatter.format(piVal), 'Base mortgage'),
              _buildMetricCard('📊', 'PMI', CurrencyFormatter.format(pmiMonthly), downPct >= 0.20 ? 'None (20%+ down)' : '0.80% annual rate'),
              _buildMetricCard('🏛️', 'Property Tax', CurrencyFormatter.format(taxMonthly), 'Monthly escrow'),
              _buildMetricCard('🔥', 'Home Insurance', CurrencyFormatter.format(insMonthly), 'Monthly escrow'),
              _buildMetricCard('📈', 'Front-End DTI', '${dti.toStringAsFixed(1)}%', 'Housing / gross income'),
              _buildMetricCard('💰', 'Total Interest', formattedInterest, 'Over loan life'),
            ],
          ),

          const SizedBox(height: 20),
          _buildSectionHeader('Amortization Snapshot', onReset: null),
          const SizedBox(height: 8),

          // Amortization snapshot Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.getBorderColor(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📅 Payoff Progress & Remaining Balance',
                  style: AppTextStyles.dmSans(
                    size: 11.5,
                    weight: FontWeight.w700,
                    color: theme.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 14),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapData.length,
                  itemBuilder: (context, idx) {
                    final d = snapData[idx];
                    final yr = d['yr'] as int;
                    final bal = d['bal'] as double;
                    final pVal = d['totP'] as double;
                    final iVal = d['totI'] as double;

                    final pPct = maxTot > 0 ? (pVal / maxTot) : 0.0;
                    final iPct = maxTot > 0 ? (iVal / maxTot) : 0.0;

                    String balStr = bal >= 1000000
                        ? '\$${(bal / 1000000).toStringAsFixed(1)}M'
                        : '\$${(bal / 1000).toStringAsFixed(0)}K';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 38,
                            child: Text(
                              'Yr $yr',
                              style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w800, color: theme.getMutedColor(context)),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 16,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEEF2F8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  if (pPct > 0)
                                    Expanded(
                                      flex: (pPct * 100).round(),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(colors: [Color(0xFF1B3F72), Color(0xFF2563EB)]),
                                          borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
                                        ),
                                      ),
                                    ),
                                  if (iPct > 0)
                                    Expanded(
                                      flex: (iPct * 100).round(),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(colors: [Color(0xFFD97706), Color(0xFFF59E0B)]),
                                          borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 44,
                            child: Text(
                              balStr,
                              style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w800, color: theme.getTextColor(context)),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                const Divider(),
                Row(
                  children: [
                    _buildLegendIndicator('Principal paid', const Color(0xFF1B3F72)),
                    const SizedBox(width: 14),
                    _buildLegendIndicator('Interest paid', const Color(0xFFD97706)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _buildSectionHeader('Jumbo Loan Requirements', onReset: null),
          const SizedBox(height: 8),

          // Requirements Checklist Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              children: [
                _buildChecklistRow(
                  label: 'Loan Amount Check',
                  value: isJumbo
                      ? '✅ ${CurrencyFormatter.format(loanAmt, symbol: '\$').split('.').first} – Jumbo'
                      : '⚠️ ${CurrencyFormatter.format(loanAmt, symbol: '\$').split('.').first} – Conforming (< \$766.5K)',
                  status: isJumbo ? ChecklistStatus.success : ChecklistStatus.warning,
                ),
                _buildChecklistRow(
                  label: 'Min. Credit Score',
                  value: isScoreEligible ? '✅ $_selectedScore – Qualifies' : '❌ $_selectedScore – Need 700+',
                  status: isScoreEligible ? ChecklistStatus.success : ChecklistStatus.failed,
                ),
                _buildChecklistRow(
                  label: 'Min. Down Payment',
                  value: isDownEligible
                      ? '✅ ${downPctRaw.toStringAsFixed(0)}% – Acceptable'
                      : '⚠️ ${downPctRaw.toStringAsFixed(0)}% – Under 10% typical min',
                  status: downPct >= 0.20 ? ChecklistStatus.success : (isDownEligible ? ChecklistStatus.warning : ChecklistStatus.failed),
                ),
                _buildChecklistRow(
                  label: 'Max DTI Check',
                  value: isDtiEligible ? '✅ ${dti.toStringAsFixed(1)}% – Within 43% cap' : '❌ ${dti.toStringAsFixed(1)}% – Over 43% cap',
                  status: isDtiEligible ? ChecklistStatus.success : ChecklistStatus.failed,
                ),
                _buildChecklistRow(
                  label: 'Cash Reserves Required',
                  value: '6–18 months PITI',
                  status: ChecklistStatus.success,
                ),
                _buildChecklistRow(
                  label: 'Full Documentation',
                  value: 'Tax returns + bank statements',
                  status: ChecklistStatus.success,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _buildSectionHeader('2025 FHFA Conforming Limits', onReset: null),
          const SizedBox(height: 8),

          // Conforming Limits Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2E240F) : const Color(0xFFFEF3C7),
              border: Border.all(color: isDark ? const Color(0xFFB45309).withValues(alpha: 0.5) : const Color(0xFFFDE68A)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📋 FHFA 2025 Conforming Limits',
                  style: AppTextStyles.dmSans(
                    size: 12.5,
                    weight: FontWeight.w800,
                    color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 10),
                _buildFhfaLimitRow('Standard 1-Unit (most counties)', '\$766,550', isDark),
                _buildFhfaLimitRow('High-Cost 1-Unit (CA, NY, DC, HI)', '\$1,149,825', isDark),
                _buildFhfaLimitRow('Standard 2-Unit', '\$981,500', isDark),
                _buildFhfaLimitRow('Standard 3-Unit', '\$1,186,350', isDark),
                _buildFhfaLimitRow('Standard 4-Unit', '\$1,474,400', isDark),
                _buildFhfaLimitRow('Anything above these limits', 'Non-Conforming (Jumbo)', isDark, highlight: true),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),
        _buildSectionHeader('Jumbo Lender Resources', onReset: null),
        const SizedBox(height: 8),

        // Resources List
        Column(
          children: [
            _buildGuidelineCard(
              '🏦',
              'Top Jumbo Lenders 2025',
              'Chase · Wells Fargo · Bank of America · Specialty Brokers',
              onTap: () => context.push('/usa/jumbo-lenders'),
            ),
            const SizedBox(height: 9),
            _buildGuidelineCard(
              '📋',
              'Documentation Checklist',
              '2 yrs tax returns · 2 mo statements · W-2s · Asset verifications',
              onTap: () => context.push('/usa/jumbo-documentation'),
            ),
            const SizedBox(height: 9),
            _buildGuidelineCard(
              '🔄',
              'Jumbo ARM Options',
              '5/1, 7/1, 10/1 ARM interest rate alternatives for savings',
              onTap: () => context.push('/usa/jumbo-arm'),
            ),
            const SizedBox(height: 9),
            _buildGuidelineCard(
              '💳',
              'Jumbo vs. Conforming GSEs',
              'No government backing means stricter reserve & DTI controls',
              onTap: () => context.push('/usa/jumbo-vs-conforming'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubHeroStat(String label, String value) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8,
            weight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.5),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.dmSans(
            size: 13,
            weight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDonutLegendRow(String label, String value, Color color) {
    final theme = widget.theme;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.dmSans(
              size: 10.5,
              weight: FontWeight.w600,
              color: theme.getMutedColor(context),
            ),
          ),
        ),
        Text(
          value.split('.').first,
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w800,
            color: theme.getTextColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendIndicator(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w600, color: widget.theme.getMutedColor(context)),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onReset, String? resetLabel, int? countBadge}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
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
            if (countBadge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF134E5E) : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$countBadge',
                  style: AppTextStyles.dmSans(
                    size: 9,
                    weight: FontWeight.w700,
                    color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (onReset != null)
          GestureDetector(
            onTap: onReset,
            child: Text(
              resetLabel ?? 'Reset',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {String? prefix, String? suffix, String? hint}) {
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
            border: Border.all(color: theme.getBorderColor(context), width: 1.5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.dmSans(
              size: 14,
              weight: FontWeight.w700,
              color: theme.getTextColor(context),
            ),
            decoration: InputDecoration(
              prefixText: prefix != null ? '$prefix ' : null,
              suffixText: suffix != null ? ' $suffix' : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            ),
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 3),
          Text(hint, style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context))),
        ],
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            border: Border.all(color: theme.getBorderColor(context), width: 1.5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              style: AppTextStyles.dmSans(
                size: 14,
                weight: FontWeight.w700,
                color: theme.getTextColor(context),
              ),
              dropdownColor: theme.getCardColor(context),
              icon: Icon(Icons.arrow_drop_down, color: theme.getMutedColor(context)),
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String emoji, String label, String value, String sub) {
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w700, color: theme.getMutedColor(context), letterSpacing: 0.3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value.split('.').first,
            style: AppTextStyles.dmSans(size: 16, weight: FontWeight.w800, color: theme.getTextColor(context)),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistRow({required String label, required String value, required ChecklistStatus status}) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color statusColor;
    if (status == ChecklistStatus.success) {
      statusColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
    } else if (status == ChecklistStatus.warning) {
      statusColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
    } else {
      statusColor = isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w700, color: theme.getTextColor(context)),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: statusColor),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFhfaLimitRow(String key, String val, bool isDark, {bool highlight = false}) {
    final kColor = isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E);
    final vColor = highlight
        ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706))
        : (isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309));
    final bColor = isDark ? const Color(0xFFB45309).withValues(alpha: 0.3) : const Color(0xFFFDE68A);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: bColor, width: 0.8))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w600, color: kColor)),
          Text(val, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: vColor)),
        ],
      ),
    );
  }

  Widget _buildGuidelineCard(String emoji, String title, String subtitle, {VoidCallback? onTap}) {
    final theme = widget.theme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.getCardColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.getBorderColor(context)),
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
                    color: theme.getTextColor(context),
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.dmSans(
                    size: 9.5,
                    color: theme.getMutedColor(context),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: theme.getMutedColor(context).withValues(alpha: 0.18),
            size: 16,
          ),
        ],
      ),
    ),);
  }
}

class _JumboDonutPainter extends CustomPainter {
  final double piPct;
  final double pmiPct;
  final double taxPct;
  final double insPct;
  final bool isDark;

  _JumboDonutPainter({
    required this.piPct,
    required this.pmiPct,
    required this.taxPct,
    required this.insPct,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 9;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const strokeWidth = 14.0;

    final bgPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEEF2F8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    const startAngle = -pi / 2;
    double currentStart = startAngle;

    void drawArcSegment(double pct, Color color) {
      if (pct <= 0) return;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = pct * 2 * pi;
      canvas.drawArc(rect, currentStart, sweepAngle, false, paint);
      currentStart += sweepAngle;
    }

    drawArcSegment(piPct, const Color(0xFF1B3F72));
    drawArcSegment(pmiPct, const Color(0xFFD97706));
    drawArcSegment(taxPct, const Color(0xFF4A5C7A));
    drawArcSegment(insPct, const Color(0xFF334155));
  }

  @override
  bool shouldRepaint(covariant _JumboDonutPainter oldDelegate) {
    return oldDelegate.piPct != piPct ||
        oldDelegate.pmiPct != pmiPct ||
        oldDelegate.taxPct != taxPct ||
        oldDelegate.insPct != insPct ||
        oldDelegate.isDark != isDark;
  }
}

