// lib/features/usa/screens/usa_refinancing_arm_screen.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USARefinancingArmScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USARefinancingArmScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USARefinancingArmScreen> createState() => _USARefinancingArmScreenState();
}

class _USARefinancingArmScreenState extends ConsumerState<USARefinancingArmScreen> {
  static const _theme = CountryThemes.usa;

  // Controllers
  final _curBalanceController = TextEditingController(text: '340000');
  final _curRateController = TextEditingController(text: '7.25');
  final _newRateController = TextEditingController(text: '6.47');
  int _termYears = 30;
  final _closingPctController = TextEditingController(text: '3');

  // Checklist states
  final Set<int> _checkedIndices = {};

  // Outputs
  bool _calculated = false;
  double _oldPI = 0.0;
  double _newPI = 0.0;
  double _monthlySavings = 0.0;
  double _closingCosts = 0.0;
  double _newLoanAmt = 0.0;
  double _rateDrop = 0.0;
  double _breakEvenMonths = 0.0;
  double _fiveYrSavings = 0.0;

  final List<Map<String, String>> _checklistItems = [
    {
      'label': 'Staying past your break-even month',
      'note': 'If you\'ll move/sell sooner, refinancing usually doesn\'t pay off'
    },
    {
      'label': 'ARM adjustment is approaching or has hit',
      'note': 'Refinancing before a steep reset can avoid payment shock'
    },
    {
      'label': 'You want payment certainty over savings',
      'note': 'A fixed rate trades potential upside for predictability'
    },
    {
      'label': 'You have funds (or equity) to cover closing costs',
      'note': 'Or you\'re comfortable with a slightly higher no-cost rate'
    },
    {
      'label': 'Your credit & DTI still qualify you',
      'note': 'A refi is a brand-new loan — full underwriting usually applies'
    },
  ];

  final _resultsKey = GlobalKey();
  final Map<String, dynamic> _calcSnapshot = {};

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _curBalanceController.text = (inputs['curBalance'] ?? 340000.0).toStringAsFixed(0);
      _curRateController.text = (inputs['curRate'] ?? 7.25).toStringAsFixed(2);
      _newRateController.text = (inputs['newRate'] ?? 6.47).toStringAsFixed(2);
      _termYears = (inputs['termYears'] ?? 30.0).toInt();
      _closingPctController.text = (inputs['closingPct'] ?? 3.0).toStringAsFixed(1);
      _calcSnapshot['curBalance'] = double.tryParse(_curBalanceController.text) ?? 0.0;
      _calcSnapshot['curRate'] = double.tryParse(_curRateController.text) ?? 0.0;
      _calcSnapshot['newRate'] = double.tryParse(_newRateController.text) ?? 0.0;
      _calcSnapshot['termYears'] = _termYears;
      _calcSnapshot['closingPct'] = double.tryParse(_closingPctController.text) ?? 0.0;
      _calculate();
    }
  }

  @override
  void dispose() {
    _curBalanceController.dispose();
    _curRateController.dispose();
    _newRateController.dispose();
    _closingPctController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _curBalanceController.text = '340000';
      _curRateController.text = '7.25';
      _newRateController.text = '6.47';
      _termYears = 30;
      _closingPctController.text = '3';
      _calculated = false;
      _calcSnapshot.clear();
    });
  }

  double _pmtFor(double principal, double annualRatePercent, int months) {
    final mr = (annualRatePercent / 100) / 12;
    if (mr == 0 || mr.isNaN) return principal / months;
    return principal * (mr * pow(1 + mr, months)) / (pow(1 + mr, months) - 1);
  }

  void _calculate() {
    final balance = double.tryParse(_curBalanceController.text) ?? 0.0;
    final curRate = double.tryParse(_curRateController.text) ?? 0.0;
    final newRate = double.tryParse(_newRateController.text) ?? 0.0;
    final closingPct = double.tryParse(_closingPctController.text) ?? 0.0;
    final months = _termYears * 12;

    final closingCosts = balance * (closingPct / 100);
    final newLoanAmt = balance; // assume costs paid out of pocket

    final oldPI = _pmtFor(balance, curRate, months);
    final newPI = _pmtFor(newLoanAmt, newRate, months);
    final monthlySavings = oldPI - newPI;

    final breakEvenMonths = monthlySavings > 0 ? closingCosts / monthlySavings : double.infinity;
    final fiveYrSavings = (monthlySavings * 60) - closingCosts;

    setState(() {
      _calcSnapshot['curBalance'] = balance;
      _calcSnapshot['curRate'] = curRate;
      _calcSnapshot['newRate'] = newRate;
      _calcSnapshot['termYears'] = _termYears;
      _calcSnapshot['closingPct'] = closingPct;

      _oldPI = oldPI;
      _newPI = newPI;
      _monthlySavings = monthlySavings;
      _closingCosts = closingCosts;
      _newLoanAmt = newLoanAmt;
      _rateDrop = newRate - curRate;
      _breakEvenMonths = breakEvenMonths;
      _fiveYrSavings = fiveYrSavings;
      _calculated = true;
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

  void _saveCalc() {
    if (!_calculated) return;

    final balance = _calcSnapshot['curBalance'] ?? 340000.0;
    final curRate = _calcSnapshot['curRate'] ?? 7.25;
    final newRate = _calcSnapshot['newRate'] ?? 6.47;
    final termYears = _calcSnapshot['termYears'] ?? 30;
    final closingPct = _calcSnapshot['closingPct'] ?? 3.0;

    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'Refinancing from ARM',
      label: 'ARM Refi: \$${CurrencyFormatter.compact(balance, symbol: "")} @ Fixed ${newRate.toStringAsFixed(2)}% · Recoup: ${_breakEvenMonths.isInfinite ? "N/A" : "${_breakEvenMonths.ceil()}mo"}',
      currencyCode: 'USD',
      inputs: {
        'curBalance': balance,
        'curRate': curRate,
        'newRate': newRate,
        'termYears': termYears.toDouble(),
        'closingPct': closingPct,
      },
      results: {
        'MonthlySavings': _monthlySavings,
        'ClosingCosts': _closingCosts,
        'RecoupMonths': _breakEvenMonths.isInfinite ? 999.0 : _breakEvenMonths,
      },
    );

    ref.read(savedProvider.notifier).save(calc);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ ARM refinance scenario saved!'),
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

    final snapBalance = _calcSnapshot['curBalance'] ?? 0.0;
    final snapCurRate = _calcSnapshot['curRate'] ?? 0.0;
    final snapNewRate = _calcSnapshot['newRate'] ?? 0.0;
    final snapTermYears = _calcSnapshot['termYears'] ?? 0;
    final snapClosingPct = _calcSnapshot['closingPct'] ?? 0.0;

    final currentBalance = double.tryParse(_curBalanceController.text) ?? 0.0;
    final currentCurRate = double.tryParse(_curRateController.text) ?? 0.0;
    final currentNewRate = double.tryParse(_newRateController.text) ?? 0.0;
    final currentClosingPct = double.tryParse(_closingPctController.text) ?? 0.0;

    final isDirty = _calculated && (
      currentBalance != snapBalance ||
      currentCurRate != snapCurRate ||
      currentNewRate != snapNewRate ||
      _termYears != snapTermYears ||
      currentClosingPct != snapClosingPct
    );

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
                    colors: [Color(0xFF0B1D3A), Color(0xFF0F766E), Color(0xFF0D9488)],
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
                      Text('Refinancing from ARM',
                          style: AppTextStyles.playfair(
                              size: 17, color: Colors.white, weight: FontWeight.w800)),
                      Text('When to refi to fixed · Break-even',
                          style: AppTextStyles.dmSans(size: 9.5, color: Colors.white60)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Summary Strip
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
                  Expanded(child: _buildStripItem('30-Yr Refi Rate', '6.75%', 'Avg Today', isDark, isGold: true)),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(child: _buildStripItem('Closing Costs', '2–6%', 'Of Loan Amt', isDark)),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(child: _buildStripItem('Typical Break-Even', '22–58 mo', 'Cost-Dependent', isDark)),
                ],
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Alert Note Strip
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.08),
                    border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📌 ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: Text(
                          'The math is simple: divide your total refinance cost by your monthly savings. The result is your break-even month — how long you need to stay to make refinancing worth it.',
                          style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF92400E), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

                _buildSectionHeader('Your Refinance Scenario'),

                // Input Card
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
                      _buildInputField('Current ARM Balance (\$)', _curBalanceController),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildInputField('Current ARM Rate (%)', _curRateController, hint: 'At/near adjustment')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildInputField('New Fixed Rate (%)', _newRateController, hint: 'Today\'s 30-yr fixed ~6.47%')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField<int>(
                              label: 'Remaining Term',
                              value: _termYears,
                              items: const [
                                DropdownMenuItem(value: 30, child: Text('30 Years')),
                                DropdownMenuItem(value: 25, child: Text('25 Years')),
                                DropdownMenuItem(value: 20, child: Text('20 Years')),
                                DropdownMenuItem(value: 15, child: Text('15 Years')),
                              ],
                               onChanged: (val) {
                                if (val != null) {
                                  setState(() => _termYears = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInputField('Closing Costs (%)', _closingPctController, hint: 'Typical: 2%–6%'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Calculate & Reset Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _calculate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        child: Text(
                          'Calculate fixed refi savings',
                          style: AppTextStyles.playfair(size: 13.5, weight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _reset,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cardBg,
                        foregroundColor: textCol,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: borderCol, width: 1.5),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Reset',
                        style: AppTextStyles.playfair(size: 13.5, weight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Results section or placeholder
                if (!_calculated) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border.all(color: borderCol),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text('💵', style: TextStyle(fontSize: 28)),
                        const SizedBox(height: 8),
                        Text(
                          'View Fixed Rate Refinance Savings',
                          style: AppTextStyles.playfair(size: 13, color: textCol, weight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enter your loan details above, then tap "Calculate fixed refi savings" to see monthly savings, break-even timeline, and detailed breakdown.',
                          style: AppTextStyles.dmSans(size: 10.5, color: mutedCol),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    key: _resultsKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isDirty) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              border: Border.all(color: const Color(0xFFFCD34D)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Text('⚠️', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Inputs have changed. Calculate again to update results.',
                                    style: AppTextStyles.dmSans(
                                      size: 11.5,
                                      color: const Color(0xFFB45309),
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Result Hero Card
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0B1D3A), Color(0xFF0F766E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
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
                                  Text('RECOUP BREAK-EVEN POINT',
                                      style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54, weight: FontWeight.w700, letterSpacing: 0.8)),
                                  const SizedBox(height: 6),
                                  Text(
                                    _breakEvenMonths.isInfinite ? '—' : '${_breakEvenMonths.ceil()} mo',
                                    style: AppTextStyles.playfair(size: 32, color: Colors.white, weight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 2),
                                  Text('to recoup refinance costs',
                                      style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFFCD34D), weight: FontWeight.w700)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Monthly savings: \$${_monthlySavings.round().abs()} · Total refi cost: \$${_closingCosts.round()}',
                                    style: AppTextStyles.dmSans(size: 9.5, color: Colors.white70),
                                  ),
                                ],
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _saveCalc,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      border: Border.all(color: Colors.white24),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.bookmark_border, color: Colors.white, size: 12),
                                        const SizedBox(width: 4),
                                        Text('Save', style: AppTextStyles.dmSans(size: 9.5, color: Colors.white, weight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        _buildSectionHeader('10-Year Cumulative Savings vs. Refi Cost'),

                        // Chart Card
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
                              Text('📊 Cumulative savings compared to initial refinance cost',
                                  style: AppTextStyles.playfair(size: 11.5, color: textCol, weight: FontWeight.w800)),
                              const SizedBox(height: 14),
                              SizedBox(
                                height: 120,
                                width: double.infinity,
                                child: CustomPaint(
                                  painter: RefiBreakEvenChartPainter(
                                    totalCost: _closingCosts,
                                    monthlySavings: _monthlySavings,
                                    isDark: isDark,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Now', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                                  Text('5 Yrs', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                                  Text('10 Yrs', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatColumn('Break-Even', _breakEvenMonths.isInfinite ? 'N/A' : '${_breakEvenMonths.ceil()} mo', textCol, mutedCol),
                                  _buildStatColumn('Total Refi Cost', '\$${_closingCosts.round()}', textCol, mutedCol),
                                  _buildStatColumn('5-Yr Net Savings', '${_fiveYrSavings >= 0 ? '+' : '-'}\$${_fiveYrSavings.abs().round()}', textCol, mutedCol),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        _buildSectionHeader('Key Scenario Stats'),

                        // Breakdown Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.4,
                          children: [
                            _buildBreakdownCard('💵', 'New Fixed P&I', '\$${_newPI.round()}', 'Locked for fixed term', textCol, mutedCol),
                            _buildBreakdownCard('📉', 'Current ARM P&I', '\$${_oldPI.round()}', 'At adjusted ARM rate', textCol, mutedCol),
                            _buildBreakdownCard('💰', 'Monthly Savings', '\$${_monthlySavings.round()}', 'Right after refi', textCol, mutedCol),
                            _buildBreakdownCard('💳', 'Est. Closing Costs', '\$${_closingCosts.round()}', '% of new loan balance', textCol, mutedCol),
                            _buildBreakdownCard('📦', 'New Loan Amount', '\$${_newLoanAmt.round()}', 'Paid out of pocket', textCol, mutedCol),
                            _buildBreakdownCard('📅', 'Rate Improvement', '${_rateDrop.toStringAsFixed(2)}%', 'ARM vs. New Fixed', _rateDrop < 0 ? const Color(0xFF15803D) : const Color(0xFFB91C1C), mutedCol),
                          ],
                        ),

                        const SizedBox(height: 20),
                        _buildSectionHeader('Refinance Cost Ranges (2026)'),

                        // Cost Guide Card
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
                              Text('💳 Typical Refinance Closing Costs',
                                  style: AppTextStyles.playfair(size: 11.5, color: textCol, weight: FontWeight.w800)),
                              const SizedBox(height: 12),
                              _buildGuideRow('Closing Cost Range', '2%–6% of loan amount', textCol),
                              _buildGuideRow('On a \$300,000 Refi', '~\$6,000–\$18,000', textCol),
                              _buildGuideRow('No-Closing-Cost Option', 'Higher rate instead of fees', textCol),
                              _buildGuideRow('Rule of Thumb to Refi Again', '≥ 0.5%–0.75% rate drop', textCol),
                              _buildGuideRow('Current 30-Yr Refi Avg', '6.75% (Jun 2026)', textCol, isGold: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                _buildSectionHeader('Should You Refinance? Checklist'),

                // Eligibility Checklist Card
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
                      Text('📋 Decision Checklist',
                          style: AppTextStyles.playfair(size: 11.5, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      for (int i = 0; i < _checklistItems.length; i++)
                        _buildDocChecklistRow(
                          i,
                          _checklistItems[i]['label'] ?? '',
                          _checklistItems[i]['note'] ?? '',
                          _checkedIndices.contains(i),
                          textCol,
                          mutedCol,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                // Footer helper note strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.08),
                    border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡 ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: Text(
                          'Each refinance resets your amortization schedule — early payments go mostly to interest again. Refinancing repeatedly for marginal savings can leave you worse off even if each individual move looks attractive on paper.',
                          style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF92400E), height: 1.4),
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
        style: AppTextStyles.sectionLabel(_theme.getMutedColor(context)),
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
            onChanged: (val) => setState(() {}),
            style: AppTextStyles.dmSans(
              size: 13,
              weight: FontWeight.w800,
              color: theme.getTextColor(context),
            ).copyWith(fontFamily: 'Georgia'),
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
              ).copyWith(fontFamily: 'Georgia'),
              dropdownColor: theme.getCardColor(context),
              icon: Icon(Icons.arrow_drop_down, color: theme.getMutedColor(context)),
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownCard(String emoji, String label, String value, String sub, Color valColor, Color mutedCol) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _theme.getCardColor(context),
        border: Border.all(color: _theme.getBorderColor(context)),
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
                  style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w700, color: mutedCol, letterSpacing: 0.3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.playfair(size: 15.5, color: valColor, weight: FontWeight.w800)),
          const SizedBox(height: 1),
          Text(sub, style: AppTextStyles.dmSans(size: 8.5, color: mutedCol), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String val, Color textCol, Color mutedCol) {
    return Column(
      children: [
        Text(val, style: AppTextStyles.playfair(size: 14.5, color: textCol, weight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label.toUpperCase(), style: AppTextStyles.dmSans(size: 8, color: mutedCol, weight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildGuideRow(String key, String val, Color textCol, {bool isGold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _theme.getBorderColor(context), width: 0.8))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w600, color: textCol)),
          Text(val, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: isGold ? const Color(0xFFD97706) : textCol)),
        ],
      ),
    );
  }



  Widget _buildDocChecklistRow(int index, String name, String note, bool isChecked, Color textCol, Color mutedCol) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isChecked) {
            _checkedIndices.remove(index);
          } else {
            _checkedIndices.add(index);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _theme.getBorderColor(context))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isChecked ? const Color(0xFF15803D) : Colors.transparent,
                border: Border.all(color: isChecked ? const Color(0xFF15803D) : _theme.getBorderColor(context), width: 1.5),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: isChecked ? const Icon(Icons.check, color: Colors.white, size: 10) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.dmSans(size: 11, color: textCol, weight: FontWeight.w700)),
                  Text(note, style: AppTextStyles.dmSans(size: 9, color: mutedCol)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter to draw Year 1-10 vertical bar charts comparing net recoup values
class RefiBreakEvenChartPainter extends CustomPainter {
  final double totalCost;
  final double monthlySavings;
  final bool isDark;

  RefiBreakEvenChartPainter({
    required this.totalCost,
    required this.monthlySavings,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double W = size.width;
    final double H = size.height;

    const int yearsToShow = 10;
    final double maxVal = max(max(totalCost, (monthlySavings * 12 * yearsToShow).abs()), 1000.0);

    const double barGap = 6.0;
    final double totalBarsWidth = W - (barGap * (yearsToShow - 1));
    final double barWidth = totalBarsWidth / yearsToShow;

    final Paint borderPaint = Paint()
      ..color = isDark ? Colors.white12 : const Color(0xFFEEF2F8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int y = 1; y <= yearsToShow; y++) {
      final double cumSavings = monthlySavings * 12 * y;
      final double netPosition = cumSavings - totalCost;
      final double heightPct = (netPosition.abs() / maxVal).clamp(0.02, 1.0);
      final double barHeight = heightPct * H;
      final bool isOver = netPosition >= 0;

      final double x = (y - 1) * (barWidth + barGap);
      final double yPos = H - barHeight;

      final RRect rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, yPos, barWidth, barHeight),
        const Radius.circular(3),
      );

      final Paint barPaint = Paint();
      if (isOver) {
        barPaint.shader = const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(x, yPos, barWidth, barHeight));
      } else {
        barPaint.shader = const LinearGradient(
          colors: [Color(0xFFFCD34D), Color(0xFFD97706)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(x, yPos, barWidth, barHeight));
      }

      canvas.drawRRect(rrect, barPaint);
      canvas.drawRRect(rrect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RefiBreakEvenChartPainter oldDelegate) => true;
}
