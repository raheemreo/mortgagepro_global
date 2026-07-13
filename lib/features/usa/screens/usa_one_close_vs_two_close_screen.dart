// lib/features/usa/screens/usa_one_close_vs_two_close_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAOneCloseVsTwoCloseScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAOneCloseVsTwoCloseScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAOneCloseVsTwoCloseScreen> createState() => _USAOneCloseVsTwoCloseScreenState();
}

class _USAOneCloseVsTwoCloseScreenState extends ConsumerState<USAOneCloseVsTwoCloseScreen> {
  static const _theme = CountryThemes.usa;

  final _resultsKey = GlobalKey();
  final Map<String, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};

  // Inputs
  final _constAmtController = TextEditingController(text: '400000');
  final _permAmtController = TextEditingController(text: '400000');
  final _costRateController = TextEditingController(text: '3.0');
  final _riskBpsController = TextEditingController(text: '0.5');

  bool _calculated = false;



  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _constAmtController.text = (inputs['ConstLoanAmt'] ?? 400000.0).toStringAsFixed(0);
      _permAmtController.text = (inputs['PermLoanAmt'] ?? 400000.0).toStringAsFixed(0);
      _costRateController.text = (inputs['CostRate'] ?? 3.0).toStringAsFixed(2);
      _riskBpsController.text = (inputs['RateRiseRisk'] ?? 0.5).toStringAsFixed(3);
      _calculate();
    }
  }

  @override
  void dispose() {
    _constAmtController.dispose();
    _permAmtController.dispose();
    _costRateController.dispose();
    _riskBpsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final errors = <String, String>{};
    final constAmt = double.tryParse(_constAmtController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final permAmt = double.tryParse(_permAmtController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final costRateVal = double.tryParse(_costRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final riskBpsVal = double.tryParse(_riskBpsController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    if (constAmt <= 0) errors['constAmt'] = 'Enter positive construction amount';
    if (permAmt <= 0) errors['permAmt'] = 'Enter permanent amount';
    if (costRateVal <= 0) errors['costRate'] = 'Enter positive cost rate';
    if (riskBpsVal < 0) errors['riskBps'] = 'Enter non-negative rate';

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) {
      setState(() {
        _calculated = false;
      });
      return;
    }

    final costRate = costRateVal / 100;
    final riskPct = riskBpsVal / 100;

    final constClose = constAmt * costRate;
    final permClose = permAmt * costRate;
    const double modFee = 500;

    final oneCloseTotal = constClose + modFee;
    final twoCloseTotal = constClose + permClose;
    final savings = twoCloseTotal - oneCloseTotal;

    // Rate risk estimate on a 30-yr amortizing mortgage
    const int months = 360;
    double extraMonthly = 0;
    if (permAmt > 0 && riskPct > 0) {
      const double baseRate = 0.0682 / 12;
      final double basePI = permAmt * (baseRate * pow(1 + baseRate, months)) / (pow(1 + baseRate, months) - 1);
      final double higherRate = (0.0682 + riskPct) / 12;
      final double higherPI = permAmt * (higherRate * pow(1 + higherRate, months)) / (pow(1 + higherRate, months) - 1);
      extraMonthly = higherPI - basePI;
    }
    final extraTotal = extraMonthly * months;

    setState(() {
      _calcSnapshot['ConstLoanAmt'] = constAmt;
      _calcSnapshot['PermLoanAmt'] = permAmt;
      _calcSnapshot['CostRate'] = costRateVal;
      _calcSnapshot['RateRiseRisk'] = riskBpsVal;

      _calcSnapshot['ConstClose'] = constClose;
      _calcSnapshot['PermClose'] = permClose;
      _calcSnapshot['ModFee'] = modFee;
      _calcSnapshot['OneCloseTotal'] = oneCloseTotal;
      _calcSnapshot['TwoCloseTotal'] = twoCloseTotal;
      _calcSnapshot['Savings'] = savings;
      _calcSnapshot['ExtraMonthlyPayment'] = extraMonthly;
      _calcSnapshot['ExtraTotalInterest'] = extraTotal;

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

    final constAmt = _calcSnapshot['ConstLoanAmt'] ?? 400000.0;
    final permAmt = _calcSnapshot['PermLoanAmt'] ?? 400000.0;
    final costRate = _calcSnapshot['CostRate'] ?? 3.0;
    final riskBps = _calcSnapshot['RateRiseRisk'] ?? 0.5;

    final snapOneCloseTotal = _calcSnapshot['OneCloseTotal'] ?? 0.0;
    final snapTwoCloseTotal = _calcSnapshot['TwoCloseTotal'] ?? 0.0;
    final snapSavings = _calcSnapshot['Savings'] ?? 0.0;
    final snapExtraMonthly = _calcSnapshot['ExtraMonthlyPayment'] ?? 0.0;
    final snapExtraTotal = _calcSnapshot['ExtraTotalInterest'] ?? 0.0;

    final formattedSavings = CurrencyFormatter.format(snapSavings, symbol: '\$').split('.').first;
    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'Construction One-Close vs. Two-Close',
      label: 'One-Close vs. Two-Close ($formattedSavings Saved)',
      currencyCode: 'USD',
      inputs: {
        'ConstLoanAmt': constAmt,
        'PermLoanAmt': permAmt,
        'CostRate': costRate,
        'RateRiseRisk': riskBps,
      },
      results: {
        'OneCloseTotal': snapOneCloseTotal,
        'TwoCloseTotal': snapTwoCloseTotal,
        'Savings': snapSavings,
        'ExtraMonthlyPayment': snapExtraMonthly,
        'ExtraTotalInterest': snapExtraTotal,
      },
    );

    ref.read(savedProvider.notifier).save(calc);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Calculation saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDirty = _calculated && (
      (double.tryParse(_constAmtController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['ConstLoanAmt'] ?? 0.0) ||
      (double.tryParse(_permAmtController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['PermLoanAmt'] ?? 0.0) ||
      (double.tryParse(_costRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['CostRate'] ?? 0.0) ||
      (double.tryParse(_riskBpsController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['RateRiseRisk'] ?? 0.0)
    );

    final cardBg = _theme.getCardColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);
    final borderCol = _theme.getBorderColor(context);
    final bgCol = _theme.getBgColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final snapConstClose = _calcSnapshot['ConstClose'] ?? 0.0;
    final snapPermClose = _calcSnapshot['PermClose'] ?? 0.0;
    final snapModFee = _calcSnapshot['ModFee'] ?? 0.0;
    final snapOneCloseTotal = _calcSnapshot['OneCloseTotal'] ?? 0.0;
    final snapTwoCloseTotal = _calcSnapshot['TwoCloseTotal'] ?? 0.0;
    final snapSavings = _calcSnapshot['Savings'] ?? 0.0;
    final snapExtraMonthly = _calcSnapshot['ExtraMonthlyPayment'] ?? 0.0;
    final snapExtraTotal = _calcSnapshot['ExtraTotalInterest'] ?? 0.0;
    final snapRiskBps = _calcSnapshot['RateRiseRisk'] ?? 0.0;

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
                    colors: [Color(0xFF0B1D3A), Color(0xFFB91C1C), Color(0xFF991B1B)],
                    stops: [0.0, 0.55, 1.0],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🔁', style: TextStyle(fontSize: 26)),
                      const SizedBox(height: 2),
                      Text('One-Close vs. Two-Close',
                          style: AppTextStyles.dmSans(
                              size: 17,
                              color: Colors.white,
                              weight: FontWeight.w800)),
                      Text('Construction Loan Structure Comparison',
                          style: AppTextStyles.dmSans(
                              size: 9.5, color: Colors.white54)),
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
                    child: _buildStripItem('Closings', '1×', 'one-close', isDark),
                  ),
                  Container(width: 1, height: 26, color: isDark ? Colors.white12 : Colors.black12),
                  Expanded(
                    child: _buildStripItem('Vs.', '2×', 'two-close', isDark),
                  ),
                  Container(width: 1, height: 26, color: isDark ? Colors.white12 : Colors.black12),
                  Expanded(
                    child: _buildStripItem('Avg Cost/Close', '2–5%', 'of loan amt', isDark, isGold: true),
                  ),
                  Container(width: 1, height: 26, color: isDark ? Colors.white12 : Colors.black12),
                  Expanded(
                    child: _buildStripItem('Rate Lock', 'Upfront', 'one-close only', isDark),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader('Closing Cost Comparison'),

                // Inputs Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField('Construction Loan (\$)', _constAmtController, hint: 'Build phase loan amount', errorText: _errors['constAmt']),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInputField('Permanent Loan (\$)', _permAmtController, hint: 'Take-out mortgage amount', errorText: _errors['permAmt']),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField('Avg. Closing Cost (%)', _costRateController, hint: 'Typical range: 2%–5%', errorText: _errors['costRate']),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInputField('Rate Rise Risk (%)', _riskBpsController, hint: 'Possible rate increase', errorText: _errors['riskBps']),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: _calculate,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFB91C1C), Color(0xFF991B1B)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '🔁 Compare Closing Structures',
                            style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                      // Results Hero Panel
                if (!_calculated) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border.all(color: borderCol),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text('🏗️', style: TextStyle(fontSize: 28)),
                        const SizedBox(height: 8),
                        Text(
                          'View Closing Cost Comparison Results',
                          style: AppTextStyles.playfair(size: 13, color: textCol, weight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enter your loan details above, then tap "Compare Closing Structures" to compare One-Close vs. Two-Close structures.',
                          style: AppTextStyles.dmSans(size: 10.5, color: mutedCol),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 20),
                  Container(
                    key: _resultsKey,
                    child: Column(
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
                                    'Inputs have changed. Tap "Compare Closing Structures" to update results.',
                                    style: TextStyle(fontSize: 11, color: textCol, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildSectionHeader('Potential Savings'),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0B1D3A), Color(0xFFB91C1C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('One-Close Savings vs. Two-Close'.toUpperCase(),
                            style: AppTextStyles.dmSans(
                                size: 8.5,
                                color: Colors.white54,
                                weight: FontWeight.w700,
                                letterSpacing: 0.8)),
                        const SizedBox(height: 5),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(CurrencyFormatter.format(max(snapSavings, 0.0), symbol: '\$').split('.').first,
                                style: AppTextStyles.dmSans(
                                    size: 32, color: Colors.white, weight: FontWeight.w800)),
                            const SizedBox(width: 4),
                            Text('saved', style: AppTextStyles.dmSans(size: 14, color: const Color(0xFFFCD34D), weight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'One closing: ${CurrencyFormatter.format(snapOneCloseTotal, symbol: '\$').split('.').first} · Two closings: ${CurrencyFormatter.format(snapTwoCloseTotal, symbol: '\$').split('.').first}',
                          style: AppTextStyles.dmSans(size: 10, color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _saveCalc,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
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

                  // Total Cost side by side chart
                  _buildSectionHeader('Total Cost: Side by Side'),
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
                        Text('📊 Total Closing Costs Comparison',
                            style: AppTextStyles.dmSans(size: 12, color: textCol, weight: FontWeight.w800)),
                        const SizedBox(height: 20),
                        _buildSideBarChart(snapOneCloseTotal, snapTwoCloseTotal, textCol, mutedCol),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Cost details grid
                  _buildSectionHeader('Cost Detail'),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.25,
                    children: [
                      _buildMetricCard('🏗️', 'Construction Closing', CurrencyFormatter.format(snapConstClose), 'Paid once, either way', textCol, mutedCol, borderCol, cardBg),
                      _buildMetricCard('🏠', 'Permanent Closing', CurrencyFormatter.format(snapPermClose), 'Two-close only', textCol, mutedCol, borderCol, cardBg),
                      _buildMetricCard('📝', 'Modification Fee', CurrencyFormatter.format(snapModFee), 'One-close conversion', textCol, mutedCol, borderCol, cardBg),
                      _buildMetricCard('💰', 'Total Savings', CurrencyFormatter.format(max(snapSavings, 0.0)), 'Choosing one-close', textCol, mutedCol, borderCol, cardBg),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Rate Risk Alert Banner
                  if (snapExtraMonthly > 0)
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF3B1E1E) : const Color(0xFFFEF2F2),
                        border: Border.all(color: isDark ? const Color(0xFF991B1B).withValues(alpha: 0.4) : const Color(0xFFFCA5A5)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('⚠️ Two-Close Rate Risk',
                              style: AppTextStyles.dmSans(
                                  size: 12,
                                  color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF7F1D1D),
                                  weight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(
                            'If mortgage rates rise ${snapRiskBps.toStringAsFixed(2)}% between your construction closing and your permanent closing, that\'s roughly '
                            '${CurrencyFormatter.format(snapExtraMonthly, symbol: '\$').split('.').first}/mo more — about '
                            '${CurrencyFormatter.format(snapExtraTotal, symbol: '\$').split('.').first} in added interest over 30 years. '
                            'One-close locks your permanent rate upfront, removing this risk entirely.',
                            style: AppTextStyles.dmSans(
                                size: 10,
                                color: isDark ? const Color(0xFFFCA5A5).withValues(alpha: 0.8) : const Color(0xFF991B1B),
                                height: 1.4),
                          ),
                        ],
                      ),
                    ),
                ],
                _buildSectionHeader('Side-by-Side Breakdown'),
                Column(
                  children: [
                    _buildComparisonCard(
                      title: '🔂 One-Time Close',
                      badge: 'Recommended for most',
                      isFeatured: true,
                      bullets: const [
                        'Single loan covers land, construction, and the permanent mortgage',
                        'One closing = one set of closing costs and fees',
                        'Permanent rate is locked before construction begins',
                        'No re-qualification needed after the build is done',
                        'Fewer lenders offer it; builder must be lender-approved upfront',
                        'Harder to change scope, budget, or builder mid-project',
                      ],
                      cardBg: cardBg,
                      textCol: textCol,
                      mutedCol: mutedCol,
                      borderCol: borderCol,
                    ),
                    const SizedBox(height: 12),
                    _buildComparisonCard(
                      title: '🔁 Two-Time Close',
                      badge: 'Two-Time Close',
                      isFeatured: false,
                      bullets: const [
                        'More flexibility to shop the permanent mortgage separately',
                        'Easier to change plans, budget or builder mid-build',
                        'Wider lender pool for the construction-only phase',
                        'Two full closings = two full sets of closing costs',
                        'Permanent rate isn\'t locked — exposed to rate moves during build',
                        'Must re-qualify (income, credit, appraisal) at the second closing',
                      ],
                      cardBg: cardBg,
                      textCol: textCol,
                      mutedCol: mutedCol,
                      borderCol: borderCol,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Decision guide advice
                _buildSectionHeader('Which Should You Choose?'),
                Column(
                  children: [
                    _buildDecisionRow('🔂', 'Choose One-Close if...', 'You want rate certainty, fewer fees, and a simpler single-approval process from land to move-in.', cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 9),
                    _buildDecisionRow('🔁', 'Choose Two-Close if...', 'Your builder isn\'t lender-approved for one-close programs, or you expect rates to fall and want to shop the permanent loan later.', cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 9),
                    _buildDecisionRow('🏦', 'Ask Every Lender', 'Whether their one-close program locks the permanent rate at construction closing, and what the conversion/modification fee is.', cardBg, textCol, mutedCol, borderCol),
                  ],
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
                color: isDark ? Colors.white54 : _theme.getMutedColor(context),
                letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyles.dmSans(
                size: 13,
                weight: FontWeight.w800,
                color: isGold ? const Color(0xFFFCD34D) : (isDark ? Colors.white : _theme.getTextColor(context)))),
        const SizedBox(height: 1),
        Text(sub,
            style: AppTextStyles.dmSans(
                size: 7.5, color: isDark ? Colors.white30 : _theme.getMutedColor(context).withValues(alpha: 0.6))),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 12),
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

  Widget _buildInputField(String label, TextEditingController controller, {String? hint, String? errorText}) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasError ? '${label.toUpperCase()} - $errorText' : label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8.5,
            weight: FontWeight.w700,
            color: hasError ? Colors.red : _theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: _theme.getBgColor(context),
            border: Border.all(
              color: hasError ? Colors.red : _theme.getBorderColor(context),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => setState(() {}),
            style: AppTextStyles.dmSans(
              size: 13,
              weight: FontWeight.w700,
              color: _theme.getTextColor(context),
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 3),
          Text(hint, style: AppTextStyles.dmSans(size: 8, color: _theme.getMutedColor(context))),
        ],
      ],
    );
  }

  Widget _buildSideBarChart(double oneClose, double twoClose, Color textCol, Color mutedCol) {
    final maxVal = max(oneClose, twoClose);
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxBarWidth = constraints.maxWidth - 100;
        final double oneCloseW = maxVal > 0 ? (oneClose / maxVal) * maxBarWidth : 0;
        final double twoCloseW = maxVal > 0 ? (twoClose / maxVal) * maxBarWidth : 0;

        return Column(
          children: [
            _buildChartRow('One-Close', oneClose, oneCloseW, const Color(0xFFD97706), textCol),
            const SizedBox(height: 12),
            _buildChartRow('Two-Close', twoClose, twoCloseW, const Color(0xFFB91C1C), textCol),
          ],
        );
      },
    );
  }

  Widget _buildChartRow(String label, double value, double width, Color color, Color textCol) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: textCol)),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              height: 20,
              width: max(width, 10.0),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                CurrencyFormatter.format(value, symbol: '\$').split('.').first,
                style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String emoji, String label, String value, String sub, Color textCol, Color mutedCol, Color borderCol, Color cardBg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol),
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
                  style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w700, color: mutedCol, letterSpacing: 0.3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value.split('.').first,
            style: AppTextStyles.dmSans(size: 15, weight: FontWeight.w800, color: textCol),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: AppTextStyles.dmSans(size: 8, color: mutedCol),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard({
    required String title,
    required String badge,
    required bool isFeatured,
    required List<String> bullets,
    required Color cardBg,
    required Color textCol,
    required Color mutedCol,
    required Color borderCol,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isFeatured ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E2638) : const Color(0xFFFFFBEB)) : cardBg,
        border: Border.all(color: isFeatured ? const Color(0xFFD97706) : borderCol, width: isFeatured ? 1.5 : 1.0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: textCol)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isFeatured ? const Color(0xFFD97706) : mutedCol.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(badge, style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w800, color: isFeatured ? Colors.white : textCol)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...bullets.map((b) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.startsWith('Choose') || b.startsWith('Single') || b.startsWith('One') || b.startsWith('Permanent') || b.startsWith('No') || b.startsWith('More') || b.startsWith('Easier') || b.startsWith('Wider') ? '✅' : '⚠️', style: const TextStyle(fontSize: 10)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(b, style: AppTextStyles.dmSans(size: 9.5, color: textCol, height: 1.35)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildDecisionRow(String emoji, String title, String subtitle, Color cardBg, Color textCol, Color mutedCol, Color borderCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _theme.getBgColor(context),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textCol)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.dmSans(size: 9.5, color: mutedCol, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
