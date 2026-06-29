// lib/features/usa/tools/usa_fha_loan_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/mortgage_math.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../shared/widgets/live_rate_banner.dart';
import '../../../providers/usa_rates_provider.dart';

class USAFhaLoanCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;
  const USAFhaLoanCalc({super.key, this.theme = CountryThemes.usa, this.savedCalc});

  @override
  ConsumerState<USAFhaLoanCalc> createState() => _USAFhaLoanCalcState();
}

class _USAFhaLoanCalcState extends ConsumerState<USAFhaLoanCalc> {
  // Input Controllers
  final _homePriceController = TextEditingController(text: '350000');
  final _rateController = TextEditingController(text: '6.54');
  final _propTaxController = TextEditingController(text: '4200');
  final _insuranceController = TextEditingController(text: '1800');
  final _grossIncomeController = TextEditingController(text: '72000');

  int _selectedScore = 620;
  int _selectedTerm = 30;
  bool _showResults = false;
  bool _isCalcDirty = true;

  @override
  void initState() {
    super.initState();
    _homePriceController.addListener(_markDirty);
    _rateController.addListener(_markDirty);
    _propTaxController.addListener(_markDirty);
    _insuranceController.addListener(_markDirty);
    _grossIncomeController.addListener(_markDirty);

    if (widget.savedCalc != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadSavedCalculation(widget.savedCalc!);
      });
    }
  }

  @override
  void dispose() {
    _homePriceController.removeListener(_markDirty);
    _rateController.removeListener(_markDirty);
    _propTaxController.removeListener(_markDirty);
    _insuranceController.removeListener(_markDirty);
    _grossIncomeController.removeListener(_markDirty);

    _homePriceController.dispose();
    _rateController.dispose();
    _propTaxController.dispose();
    _insuranceController.dispose();
    _grossIncomeController.dispose();
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
      _homePriceController.text = '350000';
      _rateController.text = '6.54';
      _propTaxController.text = '4200';
      _insuranceController.text = '1800';
      _grossIncomeController.text = '72000';
      _selectedScore = 620;
      _selectedTerm = 30;
      _showResults = false;
      _isCalcDirty = true;
    });
  }

  void _loadSavedCalculation(SavedCalc calc) {
    setState(() {
      _homePriceController.text = (calc.inputs['HomePrice'] ?? 350000.0).toStringAsFixed(0);
      _rateController.text = (calc.inputs['InterestRate'] ?? 6.54).toStringAsFixed(2);
      _propTaxController.text = (calc.inputs['PropertyTax'] ?? 4200.0).toStringAsFixed(0);
      _insuranceController.text = (calc.inputs['HomeInsurance'] ?? 1800.0).toStringAsFixed(0);
      _grossIncomeController.text = (calc.inputs['GrossIncome'] ?? 72000.0).toStringAsFixed(0);
      _selectedScore = (calc.inputs['CreditScore'] ?? 620.0).toInt();
      _selectedTerm = (calc.inputs['LoanTerm'] ?? 30.0).toInt();
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
    final rateAnnual = _val(_rateController);
    final propTaxAnnual = _val(_propTaxController);
    final insAnnual = _val(_insuranceController);
    final grossIncome = _val(_grossIncomeController);

    final downPct = _selectedScore >= 580 ? 0.035 : 0.10;
    final downAmt = price * downPct;
    final baseLoan = max(0.0, price - downAmt);
    final ufmip = baseLoan * 0.0175;
    final loanAmt = baseLoan + ufmip;

    final double pi = MortgageMath.monthlyPayment(
      principal: loanAmt,
      annualRatePercent: rateAnnual,
      termYears: _selectedTerm,
    );

    final ltv = price > 0 ? (loanAmt / price * 100) : 0.0;
    double mipRate = 0.0055;
    if (_selectedTerm <= 15) {
      mipRate = ltv > 90.0 ? 0.0040 : 0.0015;
    } else {
      mipRate = ltv > 95.0 ? 0.0055 : 0.0050;
    }
    final mipMonthly = (loanAmt * mipRate) / 12;

    final taxMonthly = propTaxAnnual / 12;
    final insMonthly = insAnnual / 12;
    final total = pi + mipMonthly + taxMonthly + insMonthly;

    final labelCtrl = TextEditingController(text: 'FHA Loan');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_fha_loan_calc/save'),
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
              'Saving: FHA Monthly Payment: ${CurrencyFormatter.format(total, symbol: '\$').split('.').first} · Score: $_selectedScore',
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
                hintText: 'Label (e.g. FHA Family Home)',
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
          : 'FHA Loan';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'FHA Loan Calculator',
        inputs: {
          'HomePrice': price,
          'InterestRate': rateAnnual,
          'PropertyTax': propTaxAnnual,
          'HomeInsurance': insAnnual,
          'GrossIncome': grossIncome,
          'CreditScore': _selectedScore.toDouble(),
          'LoanTerm': _selectedTerm.toDouble(),
        },
        results: {
          'MonthlyPayment': total,
          'DownPaymentAmt': downAmt,
          'BaseLoan': baseLoan,
          'UFMIP': ufmip,
          'LoanAmount': loanAmt,
          'MIPMonthly': mipMonthly,
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
    final rateAnnual = _val(_rateController);
    final propTaxAnnual = _val(_propTaxController);
    final insAnnual = _val(_insuranceController);
    final grossIncome = _val(_grossIncomeController);

    // Calculations
    final downPct = _selectedScore >= 580 ? 0.035 : 0.10;
    final downAmt = price * downPct;
    final baseLoan = max(0.0, price - downAmt);
    final ufmip = baseLoan * 0.0175;
    final loanAmt = baseLoan + ufmip;

    final months = _selectedTerm * 12;
    final double pi = MortgageMath.monthlyPayment(
      principal: loanAmt,
      annualRatePercent: rateAnnual,
      termYears: _selectedTerm,
    );

    final ltv = price > 0 ? (loanAmt / price * 100) : 0.0;
    double mipRate = 0.0055;
    if (_selectedTerm <= 15) {
      mipRate = ltv > 90.0 ? 0.0040 : 0.0015;
    } else {
      mipRate = ltv > 95.0 ? 0.0055 : 0.0050;
    }
    final mipMonthly = (loanAmt * mipRate) / 12;

    final taxMonthly = propTaxAnnual / 12;
    final insMonthly = insAnnual / 12;
    final total = pi + mipMonthly + taxMonthly + insMonthly;
    final totalInterest = (pi * months) - loanAmt;

    // DTI
    final monthlyIncome = grossIncome / 12;
    final dti = monthlyIncome > 0 ? (total / monthlyIncome * 100) : 0.0;

    final limitOk = price <= 498257;

    // Interest formatter helper
    String formattedInterest;
    if (totalInterest >= 1000000) {
      formattedInterest = '\$${(totalInterest / 1000000).toStringAsFixed(2)}M';
    } else {
      formattedInterest = '\$${(totalInterest / 1000).toStringAsFixed(0)}K';
    }

    // Watch saved calculations
    final savedCalcs = ref.watch(savedProvider).where((c) => c.country == 'USA' && c.calcType == 'FHA Loan Calculator').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Rate Strip — Live FRED data
        LightRateStripBanner(items: [
          RateStripItem(label: 'FHA Rate\n(30-Yr)', provider: fredMortgage30Provider, fallback: 6.54),
          RateStripItem(label: 'Min. Down', provider: fredMortgage30Provider, fallback: 3.5, suffix: '', isGold: true),
          RateStripItem(label: 'UFMIP', provider: fredMortgage30Provider, fallback: 1.75, suffix: ''),
          RateStripItem(label: 'Fed Funds', provider: fredFedFundsProvider, fallback: 5.33),
        ]),
        const SizedBox(height: 16),

        _buildSectionHeader('Loan Details', onReset: _resetInputs),
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
                  const Text('🏦 ', style: TextStyle(fontSize: 16)),
                  Text(
                    'FHA Purchase Parameters',
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
                    child: _buildInputField('Home Price', _homePriceController, prefix: '\$', hint: 'Limit: \$498,257 standard'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownField<int>(
                      label: 'Credit Score',
                      value: _selectedScore,
                      items: const [
                        DropdownMenuItem(value: 580, child: Text('580–619')),
                        DropdownMenuItem(value: 620, child: Text('620–659')),
                        DropdownMenuItem(value: 660, child: Text('660–719')),
                        DropdownMenuItem(value: 720, child: Text('720–850')),
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
                    child: _buildInputField('Property Tax', _propTaxController, prefix: '\$', suffix: '/yr'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInputField('Home Insurance', _insuranceController, prefix: '\$', suffix: '/yr'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildInputField('Annual Gross Income', _grossIncomeController, prefix: '\$', hint: 'Used for Debt-to-Income gauge'),
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
                          gradient: const LinearGradient(colors: [Color(0xFF15803D), Color(0xFF166534)]),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF15803D).withValues(alpha: _isCalcDirty ? 0.45 : 0.25),
                              blurRadius: _isCalcDirty ? 16 : 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '🏦 Calculate FHA Payment',
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
              final scoreVal = calc.inputs['CreditScore']?.toInt() ?? 620;
              final dtiVal = calc.results['MonthlyPayment'] != null && calc.inputs['GrossIncome'] != null && calc.inputs['GrossIncome']! > 0
                  ? (calc.results['MonthlyPayment']! / (calc.inputs['GrossIncome']! / 12) * 100)
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
                              'DTI: ${dtiVal.toStringAsFixed(1)}% · Score $scoreVal · ${calc.inputs['LoanTerm']?.toInt() ?? 30} yr term',
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
                        color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
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
                const Text('🦅', style: TextStyle(fontSize: 42)),
                const SizedBox(height: 10),
                Text(
                  'Enter Your Loan Details Above',
                  style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context)),
                ),
                const SizedBox(height: 4),
                Text(
                  'We\'ll calculate your monthly payment,\nupfront and annual MIP, and Debt-to-Income status.',
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
                colors: [Color(0xFF0B1D3A), Color(0xFF15803D)],
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
                  'TOTAL MONTHLY PAYMENT (PITI + MIP)',
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
                  'Base Loan: ${CurrencyFormatter.format(baseLoan, symbol: '\$').split('.').first} · Down: ${CurrencyFormatter.format(downAmt, symbol: '\$').split('.').first} (${(downPct * 100).toStringAsFixed(1)}%) · UFMIP: ${CurrencyFormatter.format(ufmip, symbol: '\$').split('.').first} financed',
                  style: AppTextStyles.dmSans(
                    size: 10,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
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
              _buildMetricCard('💵', 'Principal & Interest', CurrencyFormatter.format(pi), 'Base mortgage payment'),
              _buildMetricCard('🛡️', 'Annual MIP', CurrencyFormatter.format(mipMonthly), '${(mipRate * 100).toStringAsFixed(2)}% of loan ÷ 12'),
              _buildMetricCard('🏛️', 'Property Tax', CurrencyFormatter.format(taxMonthly), 'Escrow monthly'),
              _buildMetricCard('🔥', 'Home Insurance', CurrencyFormatter.format(insMonthly), 'Escrow monthly'),
              _buildMetricCard('📊', 'DTI Impact', '${dti.toStringAsFixed(1)}%', 'At \$${(grossIncome / 1000).toStringAsFixed(0)}K gross income'),
              _buildMetricCard('💰', 'Total Interest Paid', formattedInterest, 'Over loan life'),
            ],
          ),

          const SizedBox(height: 20),
          _buildSectionHeader('Payment Composition', onReset: null),
          const SizedBox(height: 8),

          // Proportional Stacked Payment Composition
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
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 28,
                    width: double.infinity,
                    child: Row(
                      children: [
                        if (pi > 0)
                          Expanded(
                            flex: (pi / total * 1000).round(),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [Color(0xFF15803D), Color(0xFF22C55E)]),
                              ),
                            ),
                          ),
                        if (mipMonthly > 0)
                          Expanded(
                            flex: (mipMonthly / total * 1000).round(),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [Color(0xFFD97706), Color(0xFFF59E0B)]),
                              ),
                            ),
                          ),
                        if (taxMonthly > 0)
                          Expanded(
                            flex: (taxMonthly / total * 1000).round(),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [Color(0xFF1B3F72), Color(0xFF2563EB)]),
                              ),
                            ),
                          ),
                        if (insMonthly > 0)
                          Expanded(
                            flex: (insMonthly / total * 1000).round(),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF0D9488)]),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Legend
                LayoutBuilder(builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _buildLegendItem('P&I', CurrencyFormatter.format(pi), const Color(0xFF15803D), itemWidth),
                      _buildLegendItem('Annual MIP', CurrencyFormatter.format(mipMonthly), const Color(0xFFD97706), itemWidth),
                      _buildLegendItem('Tax', CurrencyFormatter.format(taxMonthly), const Color(0xFF1B3F72), itemWidth),
                      _buildLegendItem('Insurance', CurrencyFormatter.format(insMonthly), const Color(0xFF0F766E), itemWidth),
                    ],
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _buildSectionHeader('DTI Analysis', onReset: null),
          const SizedBox(height: 8),

          // DTI gauge card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.getBorderColor(context)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '📊 DEBT-TO-INCOME RATIO',
                    style: AppTextStyles.dmSans(
                      size: 10.5,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 160,
                  height: 80,
                  child: CustomPaint(
                    painter: _DtiArcPainter(dti: dti, isDark: isDark),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${dti.toStringAsFixed(1)}%',
                  style: AppTextStyles.dmSans(
                    size: 22,
                    weight: FontWeight.w800,
                    color: theme.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getDtiStatusText(dti),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.dmSans(
                    size: 10.5,
                    weight: FontWeight.w600,
                    color: _getDtiColor(dti),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0%', style: AppTextStyles.dmSans(size: 9.0, color: theme.getMutedColor(context))),
                    Text('28% Good', style: AppTextStyles.dmSans(size: 9.0, color: const Color(0xFF15803D), weight: FontWeight.w700)),
                    Text('36% Caution', style: AppTextStyles.dmSans(size: 9.0, color: const Color(0xFFD97706), weight: FontWeight.w700)),
                    Text('43% Limit', style: AppTextStyles.dmSans(size: 9.0, color: const Color(0xFFB91C1C), weight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _buildSectionHeader('FHA Eligibility Checklist', onReset: null),
          const SizedBox(height: 8),

          // Eligibility Card
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
                  label: 'Min. Credit Score',
                  value: _selectedScore >= 580 ? '✅ $_selectedScore (3.5% down)' : '❌ $_selectedScore – Below 580 min',
                  status: _selectedScore >= 580 ? ChecklistStatus.success : ChecklistStatus.failed,
                ),
                _buildChecklistRow(
                  label: 'Down Payment Required',
                  value: '✅ ${CurrencyFormatter.format(downAmt, symbol: '\$').split('.').first} (${(downPct * 100).toStringAsFixed(1)}%)',
                  status: ChecklistStatus.success,
                ),
                _buildChecklistRow(
                  label: 'FHA Loan Limit (National)',
                  value: limitOk ? '✅ ${CurrencyFormatter.format(price, symbol: '\$').split('.').first} – Within limit' : '❌ ${CurrencyFormatter.format(price, symbol: '\$').split('.').first} – Exceeds \$498,257',
                  status: limitOk ? ChecklistStatus.success : ChecklistStatus.failed,
                ),
                _buildChecklistRow(
                  label: 'Max DTI Allowed',
                  value: '✅ 43% (up to 57% w/ AUS)',
                  status: ChecklistStatus.success,
                ),
                _buildChecklistRow(
                  label: 'Primary Residence',
                  value: '✅ Required by FHA',
                  status: ChecklistStatus.success,
                ),
                _buildChecklistRow(
                  label: 'Upfront MIP (UFMIP)',
                  value: '✅ ${CurrencyFormatter.format(ufmip, symbol: '\$').split('.').first} (financed)',
                  status: ChecklistStatus.success,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _buildSectionHeader('2025 MIP Rate Schedule', onReset: null),
          const SizedBox(height: 8),

          // MIP Rate Schedule
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2E1B0F) : const Color(0xFFFEF3C7),
              border: Border.all(color: isDark ? const Color(0xFFB45309).withValues(alpha: 0.5) : const Color(0xFFFDE68A)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🛡️ FHA Annual MIP Rates (HUD 2025)',
                  style: AppTextStyles.dmSans(
                    size: 12.5,
                    weight: FontWeight.w800,
                    color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 10),
                _buildScheduleRow('LTV ≤ 90% · 30-yr term', '0.50% / year', isDark, isActive: _selectedTerm > 15 && ltv <= 90),
                _buildScheduleRow('LTV 90–95% · 30-yr term', '0.50% / year', isDark, isActive: _selectedTerm > 15 && ltv > 90 && ltv <= 95),
                _buildScheduleRow('LTV > 95% · 30-yr term', '0.55% / year', isDark, isActive: _selectedTerm > 15 && ltv > 95),
                _buildScheduleRow('LTV ≤ 90% · 15-yr term', '0.15% / year', isDark, isActive: _selectedTerm <= 15 && ltv <= 90),
                _buildScheduleRow('LTV > 90% · 15-yr term', '0.40% / year', isDark, isActive: _selectedTerm <= 15 && ltv > 90),
                _buildScheduleRow('UFMIP (all loans)', '1.75% upfront', isDark, isActive: false),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),
        _buildSectionHeader('FHA Key Guidelines', onReset: null),
        const SizedBox(height: 8),

        // Key Guidelines List
        Column(
          children: [
            _buildGuidelineCard(
              '📋',
              '2025 FHA Loan Limits',
              'Floor \$498,257 · Ceiling \$1,149,825 (high-cost areas)',
              () => context.push('/usa/fha-loan-limits'),
            ),
            const SizedBox(height: 9),
            _buildGuidelineCard(
              '💳',
              'Credit Score Requirements',
              '580+ → 3.5% down · 500–579 → 10% down required',
              () => context.push('/usa/fha-credit-score-requirements'),
            ),
            const SizedBox(height: 9),
            _buildGuidelineCard(
              '🔄',
              'MIP Cancellation Rules',
              'After Jun 2013: MIP stays for life of loan if down < 10%',
              () => context.push('/usa/fha-mip-cancellation-rules'),
            ),
            const SizedBox(height: 9),
            _buildGuidelineCard(
              '🏠',
              'Property Standards',
              'HUD Minimum Property Standards · Appraisal required',
              () => context.push('/usa/fha-property-standards'),
            ),
            const SizedBox(height: 9),
            _buildGuidelineCard(
              '📈',
              'FHA 203(k) Rehab Option',
              'Purchase + renovation in one FHA loan',
              () => context.push('/usa/fha-203k'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, String value, Color color, double width) {
    final theme = widget.theme;
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.dmSans(
                size: 10.5,
                weight: FontWeight.w600,
                color: theme.getMutedColor(context),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value.split('.').first,
            style: AppTextStyles.dmSans(
              size: 10.5,
              weight: FontWeight.w800,
              color: theme.getTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(String key, String val, bool isDark, {bool isActive = false}) {
    final highlightBg = isDark ? const Color(0xFF452B0A) : const Color(0xFFFDE68A);
    final kColor = isDark ? (isActive ? const Color(0xFFFCD34D) : const Color(0xFFFCA5A5)) : const Color(0xFF92400E);
    final vColor = isDark ? (isActive ? const Color(0xFFFBBF24) : const Color(0xFFF87171)) : const Color(0xFFB45309);
    final borderCol = isDark ? const Color(0xFF5F2525) : const Color(0xFFFDE68A);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: isActive ? highlightBg : Colors.transparent,
        borderRadius: isActive ? BorderRadius.circular(8) : null,
        border: Border(bottom: BorderSide(color: borderCol.withValues(alpha: 0.4), width: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            key,
            style: AppTextStyles.dmSans(
              size: 10,
              weight: isActive ? FontWeight.w800 : FontWeight.w600,
              color: kColor,
            ),
          ),
          Text(
            val,
            style: AppTextStyles.dmSans(
              size: 10,
              weight: FontWeight.w800,
              color: vColor,
            ),
          ),
        ],
      ),
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
            value,
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
          Text(
            value,
            style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: statusColor),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineCard(String emoji, String title, String subtitle, VoidCallback onTap) {
    final theme = widget.theme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
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
      ),
    );
  }

  String _getDtiStatusText(double dti) {
    if (dti <= 28.0) return '✅ Excellent — well within FHA 43% limit';
    if (dti <= 36.0) return '✅ Good — within FHA limit';
    if (dti <= 43.0) return '⚠️ Acceptable — near FHA 43% limit';
    return '❌ Above FHA 43% limit — may need AUS approval';
  }

  Color _getDtiColor(double dti) {
    if (dti <= 36.0) return const Color(0xFF15803D);
    if (dti <= 43.0) return const Color(0xFFD97706);
    return const Color(0xFFB91C1C);
  }
}

class _DtiArcPainter extends CustomPainter {
  final double dti;
  final bool isDark;

  _DtiArcPainter({required this.dti, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height;
    final r = size.width / 2 - 8;

    final paintGreen = Paint()
      ..color = isDark ? const Color(0xFF1B4D24) : const Color(0xFFDCFCE7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final paintYellow = Paint()
      ..color = isDark ? const Color(0xFF5D4017) : const Color(0xFFFEF3C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final paintOrange = Paint()
      ..color = isDark ? const Color(0xFF5F2525) : const Color(0xFFFEE2E2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final paintRed = Paint()
      ..color = isDark ? const Color(0xFF7A1D1D) : const Color(0xFFFCA5A5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    const startA = pi;
    const endA = 2 * pi;
    const sweep = endA - startA;

    // Excellent (0% to 28% DTI) -> 0 to 56% of gauge
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startA,
      sweep * 0.56,
      false,
      paintGreen,
    );

    // Good (28% to 36% DTI) -> 56% to 72%
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startA + sweep * 0.56,
      sweep * 0.16,
      false,
      paintYellow,
    );

    // Caution (36% to 43% DTI) -> 72% to 86%
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startA + sweep * 0.72,
      sweep * 0.14,
      false,
      paintOrange,
    );

    // Limit (43% to 50% DTI) -> 86% to 100%
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startA + sweep * 0.86,
      sweep * 0.14,
      false,
      paintRed,
    );

    final needlePct = (dti / 50.0).clamp(0.0, 1.0);
    final needleA = startA + needlePct * sweep;

    final needleColor = dti <= 28.0
        ? const Color(0xFF15803D)
        : dti <= 36.0
            ? const Color(0xFF166534)
            : dti <= 43.0
                ? const Color(0xFFD97706)
                : const Color(0xFFB91C1C);

    final needlePaint = Paint()
      ..color = needleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final nx = cx + r * cos(needleA);
    final ny = cy + r * sin(needleA);

    canvas.drawLine(Offset(cx, cy), Offset(nx, ny), needlePaint);

    final centerPaint = Paint()..color = needleColor;
    canvas.drawCircle(Offset(cx, cy), 5, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _DtiArcPainter oldDelegate) {
    return oldDelegate.dti != dti || oldDelegate.isDark != isDark;
  }
}

enum ChecklistStatus { success, warning, failed }

