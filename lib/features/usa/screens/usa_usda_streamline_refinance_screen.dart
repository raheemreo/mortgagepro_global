// lib/features/usa/screens/usa_usda_streamline_refinance_screen.dart

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

class USAUsdaStreamlineRefinanceScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAUsdaStreamlineRefinanceScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAUsdaStreamlineRefinanceScreen> createState() => _USAUsdaStreamlineRefinanceScreenState();
}

class _USAUsdaStreamlineRefinanceScreenState extends ConsumerState<USAUsdaStreamlineRefinanceScreen> {
  static const _theme = CountryThemes.usa;

  // Controllers
  final _balanceController = TextEditingController(text: '260000');
  final _curRateController = TextEditingController(text: '7.25');
  final _newRateController = TextEditingController(text: '6.35');
  final _moRemainController = TextEditingController(text: '324');
  final _closingCostsController = TextEditingController(text: '3500');
  final _guarFeeController = TextEditingController(text: '2600');
  final _taxController = TextEditingController(text: '2800');
  final _insController = TextEditingController(text: '1400');

  bool _calculated = false;

  // Outputs
  double _newLoanAmt = 0;
  double _curTotalPayment = 0;
  double _newTotalPayment = 0;
  double _curPI = 0;
  double _newPI = 0;
  double _curAnnFee = 0;
  double _newAnnFee = 0;
  double _taxMo = 0;
  double _insMo = 0;
  double _monthlySavings = 0;
  double _lifetimeSavings = 0;
  int _breakEvenMonths = 0;
  double _rateReduction = 0;
  bool _netBenefitMet = false;

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _balanceController.text = (inputs['balance'] ?? 260000.0).toStringAsFixed(0);
      _curRateController.text = (inputs['curRate'] ?? 7.25).toStringAsFixed(2);
      _newRateController.text = (inputs['newRate'] ?? 6.35).toStringAsFixed(2);
      _moRemainController.text = (inputs['moRemain'] ?? 324.0).toStringAsFixed(0);
      _closingCostsController.text = (inputs['closingCosts'] ?? 3500.0).toStringAsFixed(0);
      _guarFeeController.text = (inputs['guarFee'] ?? 2600.0).toStringAsFixed(0);
      _taxController.text = (inputs['tax'] ?? 2800.0).toStringAsFixed(0);
      _insController.text = (inputs['insurance'] ?? 1400.0).toStringAsFixed(0);
      _calculate();
    } else {
      _calculate();
    }
  }

  @override
  void dispose() {
    _balanceController.dispose();
    _curRateController.dispose();
    _newRateController.dispose();
    _moRemainController.dispose();
    _closingCostsController.dispose();
    _guarFeeController.dispose();
    _taxController.dispose();
    _insController.dispose();
    super.dispose();
  }

  double _val(TextEditingController c) => double.tryParse(c.text) ?? 0.0;

  void _calculate() {
    final balance = _val(_balanceController);
    final curR = _val(_curRateController) / 100;
    final newR = _val(_newRateController) / 100;
    final moRemain = _val(_moRemainController).toInt();
    final closingCosts = _val(_closingCostsController);
    final guarFee = _val(_guarFeeController);
    final taxAnnual = _val(_taxController);
    final insAnnual = _val(_insController);

    final newLoan = balance + closingCosts + guarFee;
    final taxMo = taxAnnual / 12;
    final insMo = insAnnual / 12;

    // Current P&I and Annual Fee
    final double curPIVal = MortgageMath.monthlyPayment(principal: balance, annualRatePercent: curR * 100, termYears: (moRemain / 12).ceil());
    final curAnnFeeVal = (balance * 0.0035) / 12;
    final curTotal = curPIVal + curAnnFeeVal + taxMo + insMo;

    // New P&I and Annual Fee (30-year / 360 months)
    final double newPIVal = MortgageMath.monthlyPayment(principal: newLoan, annualRatePercent: newR * 100, termYears: 30);
    final newAnnFeeVal = (newLoan * 0.0035) / 12;
    final newTotal = newPIVal + newAnnFeeVal + taxMo + insMo;

    final monthlySave = curTotal - newTotal;
    final totalCosts = closingCosts + guarFee;
    final breakEvenMo = monthlySave > 0 ? (totalCosts / monthlySave).ceil() : 999;
    final lifetimeSave = (monthlySave * 360) - totalCosts;
    final rateDrop = (curR - newR) * 100;
    final netBenefit = monthlySave >= 50.0 || rateDrop >= 1.0;

    setState(() {
      _newLoanAmt = newLoan;
      _curTotalPayment = curTotal;
      _newTotalPayment = newTotal;
      _curPI = curPIVal;
      _newPI = newPIVal;
      _curAnnFee = curAnnFeeVal;
      _newAnnFee = newAnnFeeVal;
      _taxMo = taxMo;
      _insMo = insMo;
      _monthlySavings = monthlySave;
      _lifetimeSavings = lifetimeSave;
      _breakEvenMonths = breakEvenMo;
      _rateReduction = rateDrop;
      _netBenefitMet = netBenefit;
      _calculated = true;
    });
  }

  void _saveCalc() {
    if (!_calculated) return;

    final balance = _val(_balanceController);
    final curR = _val(_curRateController);
    final newR = _val(_newRateController);
    final moRemain = _val(_moRemainController);
    final closingCosts = _val(_closingCostsController);
    final guarFee = _val(_guarFeeController);
    final tax = _val(_taxController);
    final insurance = _val(_insController);

    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'USDA Streamline Refinance',
      label: 'USDA Refi: \$${(balance / 1000).toStringAsFixed(0)}K · ${curR.toStringAsFixed(2)}% → ${newR.toStringAsFixed(2)}%',
      currencyCode: 'USD',
      inputs: {
        'balance': balance,
        'curRate': curR,
        'newRate': newR,
        'moRemain': moRemain,
        'closingCosts': closingCosts,
        'guarFee': guarFee,
        'tax': tax,
        'insurance': insurance,
      },
      results: {
        'MonthlySavings': _monthlySavings,
        'NewPayment': _newTotalPayment,
        'BreakEvenMo': _breakEvenMonths.toDouble(),
        'LifetimeSave': _lifetimeSavings,
      },
    );

    ref.read(savedProvider.notifier).save(calc);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Refinance scenario saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = _theme.getCardColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);
    final borderCol = _theme.getBorderColor(context);
    final bgCol = _theme.getBgColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: bgCol,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                ),
                alignment: Alignment.center,
                child: const Text('←', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0B1D3A), Color(0xFF15803D), Color(0xFF78350F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🔄', style: TextStyle(fontSize: 26)),
                      const SizedBox(height: 2),
                      Text('USDA Streamline Refi',
                          style: AppTextStyles.playfair(
                              size: 17, color: Colors.white, weight: FontWeight.w800)),
                      Text('Reduce Rate · No Appraisal · Existing USDA Loans Only',
                          style: AppTextStyles.dmSans(size: 9.5, color: Colors.white60)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Rate Strip
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141C33) : Colors.white.withValues(alpha: 0.10),
                border: Border.all(color: borderCol),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildStripItem('Current Rate', '${_val(_curRateController).toStringAsFixed(2)}%', '30-yr avg', isDark)),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(child: _buildStripItem('No Appraisal', '✓', 'Required', isDark, isGold: true)),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(child: _buildStripItem('Min. Seasoning', '12 mo', 'On USDA loan', isDark)),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(child: _buildStripItem('Net Benefit', '\$50+', 'Monthly req.', isDark)),
                ],
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader('Current Loan Details'),

                // Inputs Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildInputField('Current Balance (\$)', _balanceController, hint: 'Remaining balance')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildInputField('Current Rate (%)', _curRateController, hint: 'Existing USDA rate')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildInputField('New Rate (%)', _newRateController, hint: 'Target 30-yr rate')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildInputField('Months Remaining', _moRemainController, hint: 'On current loan')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildInputField('Closing Costs (\$)', _closingCostsController, hint: 'Escrows, fees')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildInputField('Guarantee Fee (\$)', _guarFeeController, hint: '1% upfront financed')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildInputField('Annual Property Tax (\$)', _taxController)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildInputField('Annual Insurance (\$)', _insController)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _calculate,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF15803D), Color(0xFF166534)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '🔄 Calculate Refinance Savings',
                            style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Results Hero Panel
                if (_calculated) ...[
                  const SizedBox(height: 20),
                  _buildSectionHeader('Results'),

                  // New Payment Hero
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFF15803D)]),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NEW TOTAL MONTHLY PAYMENT (PITI + ANNUAL FEE)',
                                style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54, weight: FontWeight.w700, letterSpacing: 0.8)),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('\$', style: AppTextStyles.dmSans(size: 16, weight: FontWeight.w800, color: const Color(0xFFFCD34D))),
                                Text(CurrencyFormatter.format(_newTotalPayment, symbol: '').split('.').first,
                                    style: AppTextStyles.playfair(size: 34, color: Colors.white, weight: FontWeight.w800)),
                                Text(' /mo', style: AppTextStyles.dmSans(size: 14, color: Colors.white70, weight: FontWeight.w700)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('New loan: \$${_newLoanAmt.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')} · 30yr @ ${_val(_newRateController).toStringAsFixed(2)}% · USDA Streamline',
                                style: AppTextStyles.dmSans(size: 9.5, color: Colors.white70)),
                          ],
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _saveCalc,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.bookmark_border, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Savings Hero
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF15803D)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MONTHLY SAVINGS AFTER REFINANCE',
                            style: AppTextStyles.dmSans(size: 8.5, color: Colors.white70, weight: FontWeight.w700, letterSpacing: 0.8)),
                        const SizedBox(height: 4),
                        Text(
                          _monthlySavings >= 0
                              ? '+\$${_monthlySavings.toStringAsFixed(0)}/mo'
                              : '-\$${_monthlySavings.abs().toStringAsFixed(0)}/mo',
                          style: AppTextStyles.playfair(size: 28, color: Colors.white, weight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text('vs. your current payment of \$${_curTotalPayment.toStringAsFixed(0)}/mo',
                            style: AppTextStyles.dmSans(size: 9, color: Colors.white60)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Side-by-side comparison boxes
                  Row(
                    children: [
                      Expanded(
                        child: _buildComparisonBox(
                          '⬅ Before',
                          '\$${(_curPI + _curAnnFee).toStringAsFixed(0)}',
                          '${_val(_curRateController).toStringAsFixed(2)}%',
                          'Current P&I + Ann. Fee',
                          const Color(0xFFFEF3C7),
                          const Color(0xFFB45309),
                          const Color(0xFFD97706),
                          const Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildComparisonBox(
                          'After ➡',
                          '\$${(_newPI + _newAnnFee).toStringAsFixed(0)}',
                          '${_val(_newRateController).toStringAsFixed(2)}%',
                          'New P&I + Ann. Fee',
                          const Color(0xFFDCFCE7),
                          const Color(0xFF15803D),
                          const Color(0xFF15803D),
                          const Color(0xFF166534),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Breakdown grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.25,
                    children: [
                      _buildBreakdownCard(
                        '💵',
                        'P&I Payment',
                        '\$${_newPI.toStringAsFixed(0)}',
                        'New Principal & Interest',
                        _curPI - _newPI >= 0 ? '↓ \$${(_curPI - _newPI).toStringAsFixed(0)} less' : '↑ Higher P&I',
                        _curPI - _newPI >= 0,
                      ),
                      _buildBreakdownCard(
                        '🛡️',
                        'Annual Fee',
                        '\$${_newAnnFee.toStringAsFixed(0)}',
                        '0.35% of loan ÷ 12',
                        'Financed over 30 yrs',
                        true,
                      ),
                      _buildBreakdownCard(
                        '📅',
                        'Break-Even',
                        _breakEvenMonths < 500 ? '$_breakEvenMonths mo' : 'Never',
                        'Months to recover costs',
                        _breakEvenMonths < 500 ? '≈${(_breakEvenMonths / 12).ceil()} yrs to recover' : 'Refi increases cost',
                        _breakEvenMonths < 500,
                      ),
                      _buildBreakdownCard(
                        '💰',
                        'Lifetime Savings',
                        _lifetimeSavings >= 0
                            ? '\$${(_lifetimeSavings / 1000).toStringAsFixed(1)}K'
                            : '-\$${(_lifetimeSavings.abs() / 1000).toStringAsFixed(1)}K',
                        'Over remaining term',
                        _lifetimeSavings >= 0 ? 'Net gain over 30 yrs' : 'Net lifetime loss',
                        _lifetimeSavings >= 0,
                      ),
                      _buildBreakdownCard(
                        '📊',
                        'New Loan Amount',
                        '\$${_newLoanAmt.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}',
                        'Balance + costs + fee',
                        'All costs rolled in',
                        true,
                      ),
                      _buildBreakdownCard(
                        '📉',
                        'Rate Reduction',
                        '${_rateReduction.toStringAsFixed(2)}%',
                        'New vs. current rate',
                        _netBenefitMet ? '✅ Net benefit met' : '❌ Target not met',
                        _netBenefitMet,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  _buildSectionHeader('Break-Even Timeline'),

                  // Break-Even visual bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border.all(color: borderCol),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('⏱️ Break-Even Timeline', style: AppTextStyles.playfair(size: 12, color: textCol, weight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Closing costs: \$${(_val(_closingCostsController) + _val(_guarFeeController)).toStringAsFixed(0)}', style: AppTextStyles.dmSans(size: 9.5, color: mutedCol)),
                            Text('Monthly savings: \$${_monthlySavings.toStringAsFixed(0)}', style: AppTextStyles.dmSans(size: 9.5, color: mutedCol)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 14,
                          decoration: BoxDecoration(color: bgCol, borderRadius: BorderRadius.circular(7)),
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: _breakEvenMonths < 500 ? (_breakEvenMonths / 60.0).clamp(0.0, 1.0) : 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF15803D), Color(0xFF22C55E)]),
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Month 1', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                            Text(_breakEvenMonths < 500 ? 'Mo $_breakEvenMonths' : 'Never', style: AppTextStyles.dmSans(size: 8, color: mutedCol, weight: FontWeight.bold)),
                            Text('5 Years', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                _breakEvenMonths < 500
                                    ? '✅ Break-even at month $_breakEvenMonths (${(_breakEvenMonths / 12).ceil()} yrs)'
                                    : _monthlySavings <= 0
                                        ? '❌ Refi increases payment — not recommended'
                                        : '⚠️ Very long break-even period',
                                style: AppTextStyles.playfair(size: 13, color: textCol, weight: FontWeight.w800),
                              ),
                              Text('Closing costs ÷ monthly savings', style: AppTextStyles.dmSans(size: 9, color: mutedCol)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  _buildSectionHeader('Cumulative Savings Over Time'),

                  // Line chart representing savings
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border.all(color: borderCol),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📈 Cumulative Savings Over Time', style: AppTextStyles.playfair(size: 11.5, color: textCol, weight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 110,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: RefiSavingsLineChartPainter(
                              monthlySave: _monthlySavings,
                              costs: _val(_closingCostsController) + _val(_guarFeeController),
                              isDark: isDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Net savings after subtracting closing costs', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  _buildSectionHeader('New Monthly Payment Breakdown'),

                  // Donut composition chart
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border.all(color: borderCol),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📊 New Monthly Payment Breakdown', style: AppTextStyles.playfair(size: 11.5, color: textCol, weight: FontWeight.w800)),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            SizedBox(
                              width: 90,
                              height: 90,
                              child: CustomPaint(
                                painter: RefiPaymentDonutPainter(
                                  pi: _newPI,
                                  fee: _newAnnFee,
                                  tax: _taxMo,
                                  ins: _insMo,
                                  total: _newTotalPayment,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildDonutLegendItem(const Color(0xFF15803D), 'P&I', '\$${_newPI.toStringAsFixed(0)}', textCol, mutedCol),
                                  const SizedBox(height: 5),
                                  _buildDonutLegendItem(const Color(0xFFD97706), 'Annual Fee', '\$${_newAnnFee.toStringAsFixed(0)}', textCol, mutedCol),
                                  const SizedBox(height: 5),
                                  _buildDonutLegendItem(const Color(0xFF1B3F72), 'Property Tax', '\$${_taxMo.toStringAsFixed(0)}', textCol, mutedCol),
                                  const SizedBox(height: 5),
                                  _buildDonutLegendItem(const Color(0xFFFCD34D), 'Insurance', '\$${_insMo.toStringAsFixed(0)}', textCol, mutedCol),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  _buildSectionHeader('Rate Comparison'),

                  // Rates bar charts
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border.all(color: borderCol),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📉 Rate Comparison', style: AppTextStyles.playfair(size: 11.5, color: textCol, weight: FontWeight.w800)),
                        const SizedBox(height: 14),
                        _buildCompareBar('Current Rate', _val(_curRateController), const Color(0xFFB91C1C), textCol),
                        _buildCompareBar('New Rate', _val(_newRateController), const Color(0xFF15803D), textCol),
                        _buildCompareBar('Rate Drop', _rateReduction.abs(), const Color(0xFFD97706), textCol),
                        const SizedBox(height: 6),
                        Text('USDA requires rate reduction — no cash-out on Streamline Refi', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                _buildSectionHeader('Streamline Eligibility Requirements'),

                // Checklist Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      _buildChecklistRow('Existing USDA Loan', 'Must currently have a USDA 502 loan', '✅ Required', const Color(0xFF15803D)),
                      _buildChecklistRow('12-Month Seasoning', 'Must have made 12 on-time payments', '✅ Required', const Color(0xFF15803D)),
                      _buildChecklistRow(
                        'Net Tangible Benefit',
                        'Min. \$50/mo savings OR 1% rate drop',
                        _calculated ? (_netBenefitMet ? '✅ Met' : '❌ Not Met') : '⚠️ Calculate',
                        _netBenefitMet ? const Color(0xFF15803D) : const Color(0xFFB45309),
                      ),
                      _buildChecklistRow('No Appraisal Needed', 'USDA Streamline waives appraisal', '✅ Waived', const Color(0xFF15803D)),
                      _buildChecklistRow('No Credit Re-pull', 'Streamline: no new credit check required', '✅ Waived', const Color(0xFF15803D)),
                      _buildChecklistRow('Income Verification', 'Streamline: no new income docs required', '✅ Waived', const Color(0xFF15803D)),
                      _buildChecklistRow('No Cash-Out', 'Rate & term only — no equity withdrawal', '⚠️ Not Allowed', const Color(0xFFB45309)),
                      _buildChecklistRow('Primary Residence', 'Must remain primary home', '✅ Required', const Color(0xFF15803D)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Benefits & Warnings'),

                // Benefits Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark ? [const Color(0xFF0F3A1D), const Color(0xFF0F393F)] : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
                    ),
                    border: Border.all(color: isDark ? const Color(0xFF15803D).withValues(alpha: 0.4) : const Color(0xFF86EFAC)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('✅ What USDA Streamline Covers', style: AppTextStyles.playfair(size: 12.5, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF14532D), weight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      _buildCoverItem('💰', 'No Out-Of-Pocket Costs:', 'Closing costs and guarantee fees can be financed into the new loan balance.', isDark),
                      _buildCoverItem('⚡', 'Faster Closing:', 'No appraisal or credit checks ensure streamlined 20-30 day settlements.', isDark),
                      _buildCoverItem('📉', 'Refi Program Types:', 'Streamline-Assist is the most popular, requiring minimal background verification.', isDark),
                      _buildCoverItem('🔄', 'Resetting Loan Term:', 'Calculations reset back to 30 years. Ensure cumulative savings justify the reset.', isDark),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Warning Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark ? [const Color(0xFF45220F), const Color(0xFF5D4017)] : [const Color(0xFFFFF7ED), const Color(0xFFFEF3C7)],
                    ),
                    border: Border.all(color: isDark ? const Color(0xFF854D0E).withValues(alpha: 0.4) : const Color(0xFFFCD34D)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('⚠️ Things to Watch For', style: AppTextStyles.playfair(size: 12.5, color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E), weight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      _buildCoverItem('📅', 'Term Extension interest:', 'A new 30-year schedule means paying interest longer, reducing net lifetime gains.', isDark),
                      _buildCoverItem('💸', 'Rolled Closing Costs:', 'Financing closing costs increases balance, costing interest over 30 years.', isDark),
                      _buildCoverItem('🏡', 'Stay Threshold:', 'If you plan to sell or move within 2-3 years, refi costs may exceed savings.', isDark),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStripItem(String label, String value, String sub, bool isDark, {bool isGold = false}) {
    return Column(
      children: [
        Text(label.toUpperCase(),
            style: AppTextStyles.dmSans(
                size: 8,
                weight: FontWeight.w700,
                color: isDark ? Colors.white54 : const Color(0xFF4A5C7A),
                letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyles.playfair(
                size: 13,
                weight: FontWeight.w800,
                color: isGold ? const Color(0xFFFCD34D) : Colors.white)),
        const SizedBox(height: 1),
        Text(sub,
            style: AppTextStyles.dmSans(
                size: 7.5, color: isDark ? Colors.white30 : Colors.white60)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 18),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.dmSans(
          size: 10,
          weight: FontWeight.w800,
          color: _theme.getMutedColor(context),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {String? hint}) {
    const theme = _theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8.5,
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
              size: 13,
              weight: FontWeight.w800,
              color: theme.getTextColor(context),
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: AppTextStyles.dmSans(size: 11.5, color: theme.getMutedColor(context).withValues(alpha: 0.4)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonBox(String label, String value, String rateStr, String note, Color bg, Color valCol, Color rateCol, Color labelCol) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.12 : 0.45),
        border: Border.all(color: bg.withValues(alpha: 0.8)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 9, color: labelCol, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.playfair(size: 24, color: valCol, weight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(rateStr, style: AppTextStyles.dmSans(size: 10, color: rateCol, weight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(note, style: AppTextStyles.dmSans(size: 8.5, color: labelCol)),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(String emoji, String label, String value, String sub, String diff, bool isGreen) {
    const theme = _theme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        border: Border.all(color: theme.getBorderColor(context)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 15)),
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
          Text(value, style: AppTextStyles.playfair(size: 15.5, color: theme.getTextColor(context), weight: FontWeight.w800)),
          const SizedBox(height: 1),
          Text(sub, style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(
            diff,
            style: AppTextStyles.dmSans(size: 8.5, color: isGreen ? const Color(0xFF15803D) : const Color(0xFFB91C1C), weight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDonutLegendItem(Color color, String label, String value, Color textCol, Color mutedCol) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: AppTextStyles.dmSans(size: 10, color: mutedCol)),
        ),
        Text(value, style: AppTextStyles.dmSans(size: 11, color: textCol, weight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildCompareBar(String label, double val, Color color, Color textCol) {
    // Relative scaling factor
    final pct = (val / 8.25).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: AppTextStyles.dmSans(size: 10, color: textCol, weight: FontWeight.w600)),
          ),
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: textCol.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(5),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text('${val.toStringAsFixed(2)}%',
                style: AppTextStyles.dmSans(size: 10, color: textCol, weight: FontWeight.w800),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistRow(String label, String sub, String val, Color valColor) {
    final borderCol = _theme.getBorderColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderCol))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.dmSans(size: 11, color: textCol, weight: FontWeight.w800)),
                Text(sub, style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
              ],
            ),
          ),
          Text(val, style: AppTextStyles.dmSans(size: 10, color: valColor, weight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildCoverItem(String emoji, String strong, String normal, bool isDark) {
    final textCol = isDark ? Colors.white70 : const Color(0xFF4A5C7A);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.dmSans(size: 10.5, color: textCol, height: 1.4),
                children: [
                  TextSpan(text: '$strong ', style: AppTextStyles.dmSans(size: 10.5, color: isDark ? Colors.white : const Color(0xFF0B1D3A), weight: FontWeight.w800)),
                  TextSpan(text: normal),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter to draw a cumulative savings line chart
class RefiSavingsLineChartPainter extends CustomPainter {
  final double monthlySave;
  final double costs;
  final bool isDark;

  RefiSavingsLineChartPainter({required this.monthlySave, required this.costs, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (monthlySave <= 0) {
      _drawCenteredText(canvas, 'Rate increase — no refinance savings', size.width / 2, size.height / 2, 11, const Color(0xFFB91C1C), FontWeight.bold);
      return;
    }

    final double totalTermSavings = (monthlySave * 360) - costs;
    final int breakEvenMonths = (costs / monthlySave).ceil();

    final Paint borderPaint = Paint()
      ..color = const Color(0xFF15803D)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final Paint fillPaint = Paint()
      ..color = const Color(0xFF15803D).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    const double pad = 10;
    final double W = size.width;
    final double H = size.height;

    final List<Offset> points = [];
    final double maxSave = totalTermSavings;

    for (int m = 0; m <= 360; m += 12) {
      final double net = (monthlySave * m) - costs;
      final double x = pad + (m / 360.0) * (W - 2 * pad);
      final double y = H - pad - ((net - (-costs)) / (maxSave + costs)) * (H - 2 * pad);
      points.add(Offset(x, y.clamp(pad, H - pad)));
    }

    final Path path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final Path fillPath = Path.from(path);
    fillPath.lineTo(W - pad, H - pad);
    fillPath.lineTo(pad, H - pad);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, borderPaint);

    // Draw horizontal dashed break-even baseline (net = 0)
    final double baselineY = H - pad - ((0 - (-costs)) / (maxSave + costs)) * (H - 2 * pad);
    final Paint dashPaint = Paint()
      ..color = isDark ? Colors.white24 : const Color(0xFFEEF2F8)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    _drawDashedLine(canvas, pad, baselineY, W - pad, baselineY, dashPaint);

    // Draw vertical break-even marker
    if (breakEvenMonths <= 360) {
      final double beX = pad + (breakEvenMonths / 360.0) * (W - 2 * pad);
      final Paint beLinePaint = Paint()
        ..color = const Color(0xFFD97706)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      _drawDashedLine(canvas, beX, pad, beX, H - pad, beLinePaint);
      _drawCenteredText(canvas, 'Break-even', beX, pad + 6, 7, const Color(0xFFD97706), FontWeight.bold);
    }

    // Legend / axes labels
    _drawCenteredText(canvas, 'Yr 1', pad + 8, H - 2, 7.5, isDark ? Colors.white30 : const Color(0xFF4A5C7A), FontWeight.normal);
    _drawCenteredText(canvas, 'Yr 15', W / 2, H - 2, 7.5, isDark ? Colors.white30 : const Color(0xFF4A5C7A), FontWeight.normal);
    _drawCenteredText(canvas, 'Yr 30', W - pad - 12, H - 2, 7.5, isDark ? Colors.white30 : const Color(0xFF4A5C7A), FontWeight.normal);
    _drawCenteredText(canvas, '\$${(maxSave / 1000).toStringAsFixed(0)}K', W - pad - 12, pad + 8, 8, const Color(0xFF15803D), FontWeight.bold);
  }

  void _drawDashedLine(Canvas canvas, double x1, double y1, double x2, double y2, Paint paint) {
    const double dashWidth = 4;
    const double dashSpace = 3;
    double currentX = x1;
    double currentY = y1;
    final double dx = x2 - x1;
    final double dy = y2 - y1;
    final double length = sqrt(dx * dx + dy * dy);
    final double steps = length / (dashWidth + dashSpace);

    for (int i = 0; i < steps; i++) {
      final double progress = i / steps;
      final double nextX = x1 + dx * progress;
      final double nextY = y1 + dy * progress;
      canvas.drawLine(
        Offset(currentX, currentY),
        Offset(nextX + (dx / steps) * (dashWidth / (dashWidth + dashSpace)), nextY + (dy / steps) * (dashWidth / (dashWidth + dashSpace))),
        paint,
      );
      currentX = nextX;
      currentY = nextY;
    }
  }

  void _drawCenteredText(Canvas canvas, String text, double x, double y, double size, Color color, FontWeight weight) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          fontFamily: 'DM Sans',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom Painter to draw new payment breakdown donut chart
class RefiPaymentDonutPainter extends CustomPainter {
  final double pi;
  final double fee;
  final double tax;
  final double ins;
  final double total;
  final bool isDark;

  RefiPaymentDonutPainter({required this.pi, required this.fee, required this.tax, required this.ins, required this.total, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = min(size.width, size.height) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    const double strokeWidth = 14;

    final Paint bgPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEEF2F8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    if (total <= 0) return;

    final Paint p1 = Paint()
      ..color = const Color(0xFF15803D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final Paint p2 = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final Paint p3 = Paint()
      ..color = const Color(0xFF1B3F72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final Paint p4 = Paint()
      ..color = const Color(0xFFFCD34D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final double sweep1 = 2 * pi * (pi / total);
    final double sweep2 = 2 * pi * (fee / total);
    final double sweep3 = 2 * pi * (tax / total);
    final double sweep4 = 2 * pi * (ins / total);

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    double startAngle = -pi / 2;
    canvas.drawArc(rect, startAngle, sweep1 - 0.03, false, p1);
    startAngle += sweep1;
    canvas.drawArc(rect, startAngle, sweep2 - 0.03, false, p2);
    startAngle += sweep2;
    canvas.drawArc(rect, startAngle, sweep3 - 0.03, false, p3);
    startAngle += sweep3;
    canvas.drawArc(rect, startAngle, sweep4 - 0.03, false, p4);

    _drawCenteredText(canvas, '\$${total.toStringAsFixed(0)}', center.dx, center.dy - 8, 11.5, isDark ? Colors.white : const Color(0xFF0B1D3A), FontWeight.bold);
    _drawCenteredText(canvas, '/mo', center.dx, center.dy + 6, 8, isDark ? Colors.white60 : const Color(0xFF4A5C7A), FontWeight.normal);
  }

  void _drawCenteredText(Canvas canvas, String text, double x, double y, double size, Color color, FontWeight weight) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          fontFamily: 'DM Sans',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
