// lib/features/usa/screens/usa_jumbo_vs_conforming_screen.dart

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

class USAJumboVsConformingScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAJumboVsConformingScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAJumboVsConformingScreen> createState() => _USAJumboVsConformingScreenState();
}

class _USAJumboVsConformingScreenState extends ConsumerState<USAJumboVsConformingScreen> {
  static const _theme = CountryThemes.usa;
  static const double _confLimit = 766550.0;

  // Controllers
  final _homePriceController = TextEditingController(text: '1200000');
  final _downPctController = TextEditingController(text: '20');
  final _jumboRateController = TextEditingController(text: '7.04');
  final _confRateController = TextEditingController(text: '6.74');
  final _incomeController = TextEditingController(text: '350000');

  int _selectedTerm = 30;
  bool _calculated = false;

  // Outputs
  double _loanAmt = 0;
  double _confLoan = 0;
  double _jumboPmt = 0;
  double _confPmt = 0;
  double _jumboTotalInt = 0;
  double _confTotalInt = 0;
  double _paymentDiff = 0;
  double _extraDownNeeded = 0;
  bool _isJumbo = true;

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _homePriceController.text = (inputs['homePrice'] ?? 1200000.0).toStringAsFixed(0);
      _downPctController.text = (inputs['downPct'] ?? 20.0).toStringAsFixed(0);
      _jumboRateController.text = (inputs['jumboRate'] ?? 7.04).toStringAsFixed(2);
      _confRateController.text = (inputs['confRate'] ?? 6.74).toStringAsFixed(2);
      _incomeController.text = (inputs['income'] ?? 350000.0).toStringAsFixed(0);
      _selectedTerm = (inputs['term'] ?? 30.0).toInt();
      _calculate();
    } else {
      _calculate();
    }
  }

  @override
  void dispose() {
    _homePriceController.dispose();
    _downPctController.dispose();
    _jumboRateController.dispose();
    _confRateController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  void _calculate() {
    final price = double.tryParse(_homePriceController.text) ?? 0.0;
    final down = (double.tryParse(_downPctController.text) ?? 0.0) / 100;
    final jr = (double.tryParse(_jumboRateController.text) ?? 0.0) / 100;
    final cr = (double.tryParse(_confRateController.text) ?? 0.0) / 100;
    final months = _selectedTerm * 12;

    final loanAmtVal = price * (1.0 - down);
    final isJumboVal = loanAmtVal > _confLimit;

    final jumboPmtVal = MortgageMath.monthlyPayment(principal: loanAmtVal, annualRatePercent: jr * 100, termYears: _selectedTerm);
    final jumboTotalIntVal = (jumboPmtVal * months) - loanAmtVal;

    final confLoanVal = min(loanAmtVal, _confLimit);
    final confPmtVal = MortgageMath.monthlyPayment(principal: confLoanVal, annualRatePercent: cr * 100, termYears: _selectedTerm);
    final confTotalIntVal = (confPmtVal * months) - confLoanVal;

    final diff = jumboPmtVal - confPmtVal;
    final extraDown = loanAmtVal - _confLimit;

    setState(() {
      _loanAmt = loanAmtVal;
      _confLoan = confLoanVal;
      _isJumbo = isJumboVal;
      _jumboPmt = jumboPmtVal;
      _jumboTotalInt = jumboTotalIntVal;
      _confPmt = confPmtVal;
      _confTotalInt = confTotalIntVal;
      _paymentDiff = diff;
      _extraDownNeeded = extraDown;
      _calculated = true;
    });
  }

  void _saveCalc() {
    if (!_calculated) return;
    final price = double.tryParse(_homePriceController.text) ?? 0.0;
    final down = double.tryParse(_downPctController.text) ?? 0.0;
    final jr = double.tryParse(_jumboRateController.text) ?? 0.0;
    final cr = double.tryParse(_confRateController.text) ?? 0.0;
    final income = double.tryParse(_incomeController.text) ?? 0.0;

    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'Jumbo vs Conforming',
      label: 'Jumbo vs Conf: \$${(price/1000).toStringAsFixed(0)}K home · $down% down',
      currencyCode: 'USD',
      inputs: {
        'homePrice': price,
        'downPct': down,
        'jumboRate': jr,
        'confRate': cr,
        'term': _selectedTerm.toDouble(),
        'income': income,
      },
      results: {
        'jumboPmt': _jumboPmt,
        'confPmt': _confPmt,
        'paymentDiff': _paymentDiff,
      },
    );

    ref.read(savedProvider.notifier).save(calc);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Comparison saved!'),
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

    final jrStr = _jumboRateController.text;
    final crStr = _confRateController.text;

    // Dual bar percentages
    final double maxIntVal = max(_jumboTotalInt, _confTotalInt);
    final double jIntWidthFactor = maxIntVal == 0 ? 0.0 : (_jumboTotalInt / maxIntVal);
    final double cIntWidthFactor = 1.0 - jIntWidthFactor;

    final double maxPmtVal = max(_jumboPmt, _confPmt);
    final double jPmtWidthFactor = maxPmtVal == 0 ? 0.0 : (_jumboPmt / maxPmtVal);
    final double cPmtWidthFactor = 1.0 - jPmtWidthFactor;

    return Scaffold(
      backgroundColor: bgCol,
      body: CustomScrollView(
        slivers: [
          // App Bar Header
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
                    colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('⚖️', style: TextStyle(fontSize: 26)),
                      const SizedBox(height: 2),
                      Text('Jumbo vs. Conforming',
                          style: AppTextStyles.playfair(
                              size: 17,
                              color: Colors.white,
                              weight: FontWeight.w800)),
                      Text('Side-by-Side Loan Comparison · 2025',
                          style: AppTextStyles.dmSans(
                              size: 9.5, color: Colors.white60)),
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
                  Expanded(
                    child: _buildStripItem('Jumbo 30-Yr', '$jrStr%', 'Jun 2025', isDark, isGold: true),
                  ),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(
                    child: _buildStripItem('Conf. 30-Yr', '$crStr%', 'Jun 2025', isDark),
                  ),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(
                    child: _buildStripItem('Rate Spread', '+0.30%', 'Jumbo-Conf', isDark),
                  ),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(
                    child: _buildStripItem('Conf. Limit', '\$766K', '2025 FHFA', isDark),
                  ),
                ],
              ),
            ),
          ),

          // Scrollable Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader('June 2025 Rates'),

                // Comparison Cards Hero
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFF334155)]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFFCD34D).withValues(alpha: 0.25), borderRadius: BorderRadius.circular(6)),
                              child: Text('JUMBO', style: AppTextStyles.dmSans(size: 8, color: const Color(0xFFFCD34D), weight: FontWeight.w800)),
                            ),
                            const SizedBox(height: 6),
                            Text('30-Yr Fixed', style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54)),
                            Text('$jrStr%', style: AppTextStyles.playfair(size: 24, color: Colors.white, weight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text('Above \$766,550 (standard)\nAbove \$1,149,825 (high-cost)', style: AppTextStyles.dmSans(size: 7.5, color: Colors.white54)),
                            const SizedBox(height: 6),
                            Text('Non-GSE · Portfolio Loan', style: AppTextStyles.dmSans(size: 8.5, color: const Color(0xFFFCD34D), weight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(6)),
                              child: Text('CONFORMING', style: AppTextStyles.dmSans(size: 8, color: Colors.white, weight: FontWeight.w800)),
                            ),
                            const SizedBox(height: 6),
                            Text('30-Yr Fixed', style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54)),
                            Text('$crStr%', style: AppTextStyles.playfair(size: 24, color: Colors.white, weight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text('Up to \$766,550 (standard)\nFannie/Freddie backed', style: AppTextStyles.dmSans(size: 7.5, color: Colors.white54)),
                            const SizedBox(height: 6),
                            Text('GSE-Backed · Tradeable', style: AppTextStyles.dmSans(size: 8.5, color: Colors.white70, weight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Interactive Calculator'),

                // Inputs Card
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
                      Row(
                        children: [
                          Expanded(child: _buildInputField('Home Price (\$)', _homePriceController)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildInputField('Down Payment (%)', _downPctController)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildInputField('Jumbo Rate (%)', _jumboRateController)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildInputField('Conf. Rate (%)', _confRateController)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildInputField('Annual Income (\$)', _incomeController)),
                          const SizedBox(width: 10),
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
                                  setState(() => _selectedTerm = val);
                                  _calculate();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _calculate,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF334155), Color(0xFF1E293B)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '⚖️ Compare Loan Types',
                            style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Payment Comparison'),

                // Results Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B1D3A), Color(0xFF334155)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MONTHLY PRINCIPAL & INTEREST',
                          style: AppTextStyles.dmSans(
                              size: 8.5,
                              color: Colors.white54,
                              weight: FontWeight.w700,
                              letterSpacing: 0.8)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text('🏢 Jumbo', style: AppTextStyles.dmSans(size: 9.5, color: Colors.white54)),
                                const SizedBox(height: 3),
                                Text(CurrencyFormatter.format(_jumboPmt, symbol: '\$').split('.').first,
                                    style: AppTextStyles.playfair(size: 22, color: const Color(0xFFFCD34D), weight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text('${CurrencyFormatter.compact(_loanAmt, symbol: '\$')} loan', style: AppTextStyles.dmSans(size: 8.5, color: Colors.white38)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                            child: Column(
                              children: [
                                Text('VS', style: AppTextStyles.dmSans(size: 11, color: Colors.white, weight: FontWeight.w800)),
                                Text('${_paymentDiff >= 0 ? '+' : ''}${CurrencyFormatter.format(_paymentDiff, symbol: '\$').split('.').first}/mo',
                                    style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text('🏠 Conforming', style: AppTextStyles.dmSans(size: 9.5, color: Colors.white54)),
                                const SizedBox(height: 3),
                                Text(CurrencyFormatter.format(_confPmt, symbol: '\$').split('.').first,
                                    style: AppTextStyles.playfair(size: 22, color: const Color(0xFF86EFAC), weight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text('${CurrencyFormatter.compact(_confLoan, symbol: '\$')} loan', style: AppTextStyles.dmSans(size: 8.5, color: Colors.white38)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                        child: RichText(
                          text: TextSpan(
                            style: AppTextStyles.dmSans(size: 10, color: Colors.white70, height: 1.4),
                            children: [
                              const TextSpan(text: 'Your situation: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              TextSpan(
                                text: _isJumbo
                                    ? 'Loan of ${CurrencyFormatter.compact(_loanAmt, symbol: '\$')} qualifies as jumbo. To use conforming, increase down payment by ${CurrencyFormatter.compact(max(0, _extraDownNeeded), symbol: '\$')} or consider an 80-10-10 piggyback structure.'
                                    : 'Loan of ${CurrencyFormatter.compact(_loanAmt, symbol: '\$')} is within conforming limit. Conforming loan available — no jumbo pricing.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _saveCalc,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.13),
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '🔖 Save Comparison',
                            style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Lifetime Cost Analysis'),

                // Lifetime Cost Analysis Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('💸 Lifetime Cost Analysis',
                          style: AppTextStyles.playfair(size: 12, color: textCol, weight: FontWeight.w800)),
                      Text('Total paid over full loan term (P+I only)',
                          style: AppTextStyles.dmSans(size: 9.5, color: mutedCol)),
                      const SizedBox(height: 16),

                      // Interest dual bar
                      _buildDualBar(
                        'Total Interest Paid',
                        '${CurrencyFormatter.compact(_jumboTotalInt, symbol: '\$')} vs ${CurrencyFormatter.compact(_confTotalInt, symbol: '\$')}',
                        jIntWidthFactor,
                        cIntWidthFactor,
                        'Jumbo Interest',
                        'Conforming Interest',
                        const Color(0xFFD97706),
                        const Color(0xFF15803D),
                      ),

                      const SizedBox(height: 16),

                      // Monthly payment dual bar
                      _buildDualBar(
                        'Monthly Payment',
                        '${CurrencyFormatter.format(_jumboPmt, symbol: '\$').split('.').first} vs ${CurrencyFormatter.format(_confPmt, symbol: '\$').split('.').first}',
                        jPmtWidthFactor,
                        cPmtWidthFactor,
                        'Jumbo Monthly P&I',
                        'Conforming Monthly P&I',
                        const Color(0xFF0B1D3A),
                        const Color(0xFF1B3F72),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Full Feature Comparison'),

                // Table
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0B1D3A),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 14, child: Text('FEATURE', style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54, weight: FontWeight.w700))),
                            Expanded(flex: 10, child: Text('🏢 JUMBO', style: AppTextStyles.dmSans(size: 8.5, color: const Color(0xFFFCD34D), weight: FontWeight.w800), textAlign: TextAlign.center)),
                            Expanded(flex: 10, child: Text('🏠 CONFORMING', style: AppTextStyles.dmSans(size: 8.5, color: const Color(0xFF86EFAC), weight: FontWeight.w800), textAlign: TextAlign.center)),
                          ],
                        ),
                      ),
                      _buildComparisonRow('Loan Limit', '>\$766,550', '≤\$766,550', isJumboAlert: true),
                      _buildComparisonRow('High-Cost Limit', '>\$1,149,825', '≤\$1,149,825', isJumboAlert: true),
                      _buildComparisonRow('GSE Backing', '❌ None', '✅ Yes', isConfAlert: true),
                      _buildComparisonRow('Min. Credit Score', '700–720+', '620+', isJumboAlert: true),
                      _buildComparisonRow('Min. Down Payment', '10–20%', '3–5%', isJumboAlert: true),
                      _buildComparisonRow('PMI Required', 'Rarely', 'Yes (<20%)', isConfAlert: true),
                      _buildComparisonRow('DTI Maximum', '43%', '45–50%', isJumboAlert: true),
                      _buildComparisonRow('Cash Reserves', '12–18 Mo', '2–6 Mo', isJumboAlert: true),
                      _buildComparisonRow('Appraisals', '1–2 (>\$2M)', '1 (standard)', isJumboAlert: true),
                      _buildComparisonRow('Rate vs Conforming', '+0.30%', 'Benchmark', isJumboAlert: true),
                      _buildComparisonRow('Self-Employed OK', '✅ Yes', 'Limited', isConfAlert: true),
                      _buildComparisonRow('Closing Timeline', '38–45 days', '28–35 days', isJumboAlert: true),
                      _buildComparisonRow('Lender Holds Loan', '✅ Portfolio', 'Sold to GSE', isConfAlert: true),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('2025 FHFA Loan Limits', badgeText: 'Official'),

                // Limits Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📋 FHFA 2025 Conforming Limits — Where Jumbo Begins',
                          style: AppTextStyles.playfair(size: 12, color: const Color(0xFF92400E), weight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      _buildLimitItem('Standard 1-Unit (most counties)', '\$766,550'),
                      _buildLimitItem('High-Cost 1-Unit (CA, NY, DC, HI)', '\$1,149,825'),
                      _buildLimitItem('Standard 2-Unit (duplex)', '\$981,500'),
                      _buildLimitItem('Standard 3-Unit (triplex)', '\$1,186,350'),
                      _buildLimitItem('Standard 4-Unit (fourplex)', '\$1,474,400'),
                      _buildLimitItem('Alaska / Hawaii 1-Unit', '\$1,149,825'),
                      _buildLimitItem('Anything above → Jumbo', 'Non-conforming'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Which Loan Is Right for You?'),

                // Decision guide
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🎯 Decision Guide', style: AppTextStyles.playfair(size: 12, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      _buildDecisionBox(
                        '🏢 Choose Jumbo When…',
                        'Loan exceeds \$766,550 · Strong income (>\$200K) · Excellent credit (720+) · Large liquid reserves · Buying in high-cost market (CA, NY, WA) · Self-employed with 2+ yrs returns',
                        const Color(0xFFFEF3C7),
                        const Color(0xFFF59E0B),
                      ),
                      const SizedBox(height: 10),
                      _buildDecisionBox(
                        '🏠 Choose Conforming When…',
                        'Loan below \$766,550 · Building credit (620–720 range) · Lower down payment available (3–5%) · Prefer simpler underwriting · Want faster closing (28–35 days) · Piggyback loan available to stay conforming',
                        const Color(0xFFF0FDF4),
                        const Color(0xFFBBF7D0),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: bgCol, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('💡 Piggyback Strategy', style: AppTextStyles.dmSans(size: 11, color: textCol, weight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(
                              'If your loan is close to the conforming limit, consider an 80-10-10 split: 80% conforming first mortgage + 10% HELOC or second mortgage + 10% down payment. This avoids jumbo pricing, PMI, and stricter underwriting.',
                              style: AppTextStyles.dmSans(size: 9.5, color: mutedCol, height: 1.5),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildInputField(String label, TextEditingController controller) {
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
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
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
                size: 13,
                weight: FontWeight.w800,
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

  Widget _buildDualBar(
    String label,
    String values,
    double fillJ,
    double fillC,
    String legendJ,
    String legendC,
    Color colorJ,
    Color colorC,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: _theme.getTextColor(context))),
            Text(values, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: _theme.getMutedColor(context))),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: 28,
          decoration: BoxDecoration(
            color: _theme.getBgColor(context),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            children: [
              if (fillJ > 0)
                Expanded(
                  flex: (fillJ * 100).round().clamp(1, 99),
                  child: Container(
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: colorJ,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 8),
                    child: Text('${(fillJ * 100).round()}%',
                        style: AppTextStyles.dmSans(size: 9.5, color: Colors.white, weight: FontWeight.w800)),
                  ),
                ),
              if (fillC > 0)
                Expanded(
                  flex: (fillC * 100).round().clamp(1, 99),
                  child: Container(
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: colorC,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 8),
                    child: Text('${(fillC * 100).round()}%',
                        style: AppTextStyles.dmSans(size: 9.5, color: Colors.white, weight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildLegendItem(legendJ, colorJ),
            const SizedBox(width: 14),
            _buildLegendItem(legendC, colorC),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.dmSans(size: 8.5, color: _theme.getMutedColor(context))),
      ],
    );
  }

  Widget _buildComparisonRow(String feature, String valJumbo, String valConf, {bool isJumboAlert = false, bool isConfAlert = false}) {
    final borderCol = _theme.getBorderColor(context);
    final textCol = _theme.getTextColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderCol))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 14,
            child: Text(feature, style: AppTextStyles.dmSans(size: 10.5, color: textCol, weight: FontWeight.w700)),
          ),
          Expanded(
            flex: 10,
            child: Text(
              valJumbo,
              style: AppTextStyles.dmSans(
                size: 10,
                color: isJumboAlert ? const Color(0xFFD97706) : textCol,
                weight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 10,
            child: Text(
              valConf,
              style: AppTextStyles.dmSans(
                size: 10,
                color: isConfAlert ? const Color(0xFF15803D) : textCol,
                weight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFFDE68A)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 10, color: const Color(0xFF92400E), weight: FontWeight.w600)),
          Text(value, style: AppTextStyles.dmSans(size: 10, color: const Color(0xFFB45309), weight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildDecisionBox(String title, String desc, Color bg, Color border) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.playfair(size: 11, color: const Color(0xFF0B1D3A), weight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(desc, style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF4A5C7A), height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? badgeText}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.dmSans(
              size: 10,
              weight: FontWeight.w800,
              color: _theme.getMutedColor(context),
              letterSpacing: 1.0,
            ),
          ),
          if (badgeText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF5D4017) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badgeText,
                style: AppTextStyles.dmSans(
                  size: 8.5,
                  weight: FontWeight.w700,
                  color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
                ),
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
                color: isDark ? Colors.white54 : _theme.getMutedColor(context),
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
}
