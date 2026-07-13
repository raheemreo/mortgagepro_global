// lib/features/usa/screens/usa_jumbo_arm_options_screen.dart

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

class USAJumboArmOptionsScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAJumboArmOptionsScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAJumboArmOptionsScreen> createState() => _USAJumboArmOptionsScreenState();
}

class _USAJumboArmOptionsScreenState extends ConsumerState<USAJumboArmOptionsScreen> {
  static const _theme = CountryThemes.usa;

  final _resultsKey = GlobalKey();
  final Map<String, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};

  // Controllers
  final _loanAmtController = TextEditingController(text: '1200000');
  final _armRateController = TextEditingController(text: '6.38');
  final _fixedRateController = TextEditingController(text: '7.04');
  final _rateCapController = TextEditingController(text: '11.38');
  final _horizonController = TextEditingController(text: '7');

  int _selectedTerm = 30;
  int _selectedArmYrs = 7;
  String _selectedArmLabel = '7/1 ARM';
  bool _calculated = false;



  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _loanAmtController.text = (inputs['loanAmt'] ?? 1200000.0).toStringAsFixed(0);
      _armRateController.text = (inputs['armRate'] ?? 6.38).toStringAsFixed(2);
      _fixedRateController.text = (inputs['fixedRate'] ?? 7.04).toStringAsFixed(2);
      _rateCapController.text = (inputs['rateCap'] ?? 11.38).toStringAsFixed(2);
      _horizonController.text = (inputs['horizon'] ?? 7.0).toStringAsFixed(0);
      _selectedTerm = (inputs['term'] ?? 30.0).toInt();
      _selectedArmYrs = (inputs['armYrs'] ?? 7.0).toInt();
      _selectedArmLabel = _selectedArmYrs == 5
          ? '5/1 ARM'
          : _selectedArmYrs == 7
              ? '7/1 ARM'
              : _selectedArmYrs == 10
                  ? '10/1 ARM'
                  : '3/1 ARM';
      _calculate();
    }
  }

  @override
  void dispose() {
    _loanAmtController.dispose();
    _armRateController.dispose();
    _fixedRateController.dispose();
    _rateCapController.dispose();
    _horizonController.dispose();
    super.dispose();
  }

  void _selectArm(int years, double defaultRate, String label) {
    setState(() {
      _selectedArmYrs = years;
      _selectedArmLabel = label;
      _armRateController.text = defaultRate.toStringAsFixed(2);
      _rateCapController.text = (defaultRate + 5.0).toStringAsFixed(2);
    });
  }

  void _calculate() {
    final errors = <String, String>{};
    final loan = double.tryParse(_loanAmtController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final arRate = double.tryParse(_armRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final frRate = double.tryParse(_fixedRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final capRate = double.tryParse(_rateCapController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final horizonVal = double.tryParse(_horizonController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    if (loan <= 0) errors['loan'] = 'Enter positive loan amount';
    if (arRate <= 0) errors['armRate'] = 'Enter positive rate';
    if (frRate <= 0) errors['fixedRate'] = 'Enter positive rate';
    if (capRate <= 0) errors['rateCap'] = 'Enter positive rate';
    if (horizonVal <= 0) errors['horizon'] = 'Enter positive years';

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) {
      setState(() {
        _calculated = false;
      });
      return;
    }

    final ar = arRate / 100;
    final fr = frRate / 100;
    final cap = capRate / 100;
    final horizon = horizonVal.toInt();
    final months = _selectedTerm * 12;

    final armPmtVal = MortgageMath.monthlyPayment(principal: loan, annualRatePercent: ar * 100, termYears: _selectedTerm);
    final fixedPmtVal = MortgageMath.monthlyPayment(principal: loan, annualRatePercent: fr * 100, termYears: _selectedTerm);
    final worstPmtVal = MortgageMath.monthlyPayment(principal: loan, annualRatePercent: cap * 100, termYears: _selectedTerm);

    final monthlySave = fixedPmtVal - armPmtVal;
    final totalSave = monthlySave * min(horizon * 12.0, months.toDouble());
    final spreadPercent = (fr - ar) * 100;

    // Break-even math matches JS code
    final armFixedYrs = _selectedArmYrs == 0 ? 3 : _selectedArmYrs; // 3/1 is years 3
    final breakEvenVal = armFixedYrs + ((monthlySave * armFixedYrs * 12) / (worstPmtVal - fixedPmtVal == 0 ? 1 : worstPmtVal - fixedPmtVal)) / 12;

    setState(() {
      _calcSnapshot['loanAmt'] = loan;
      _calcSnapshot['armRate'] = arRate;
      _calcSnapshot['fixedRate'] = frRate;
      _calcSnapshot['rateCap'] = capRate;
      _calcSnapshot['horizon'] = horizonVal;
      _calcSnapshot['term'] = _selectedTerm;
      _calcSnapshot['armYrs'] = _selectedArmYrs;
      _calcSnapshot['armLabel'] = _selectedArmLabel;
      _calcSnapshot['armPmt'] = armPmtVal;
      _calcSnapshot['fixedPmt'] = fixedPmtVal;
      _calcSnapshot['worstPmt'] = worstPmtVal;
      _calcSnapshot['monthlySave'] = monthlySave;
      _calcSnapshot['totalSave'] = totalSave;
      _calcSnapshot['rateSpread'] = spreadPercent;
      _calcSnapshot['breakEvenYr'] = breakEvenVal.isInfinite || breakEvenVal.isNaN ? 30 : breakEvenVal.round().clamp(1, 30);

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

    final loan = _calcSnapshot['loanAmt'] ?? 1200000.0;
    final ar = _calcSnapshot['armRate'] ?? 6.38;
    final fr = _calcSnapshot['fixedRate'] ?? 7.04;
    final cap = _calcSnapshot['rateCap'] ?? 11.38;
    final horizon = _calcSnapshot['horizon'] ?? 7.0;
    final term = _calcSnapshot['term'] ?? 30;
    final armYrs = _calcSnapshot['armYrs'] ?? 7;
    final armLabel = _calcSnapshot['armLabel'] ?? '7/1 ARM';

    final snapMonthlySave = _calcSnapshot['monthlySave'] ?? 0.0;
    final snapTotalSave = _calcSnapshot['totalSave'] ?? 0.0;
    final snapWorstPmt = _calcSnapshot['worstPmt'] ?? 0.0;

    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'Jumbo ARM Options',
      label: 'ARM Savings: ${CurrencyFormatter.format(snapMonthlySave, symbol: '\$').split('.').first}/mo ($armLabel)',
      currencyCode: 'USD',
      inputs: {
        'loanAmt': loan,
        'armRate': ar,
        'fixedRate': fr,
        'rateCap': cap,
        'horizon': horizon,
        'term': term.toDouble(),
        'armYrs': armYrs.toDouble(),
      },
      results: {
        'MonthlySave': snapMonthlySave,
        'TotalSave': snapTotalSave,
        'WorstCasePmt': snapWorstPmt,
      },
    );

    ref.read(savedProvider.notifier).save(calc);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ ARM calculation saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDirty = _calculated && (
      (double.tryParse(_loanAmtController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['loanAmt'] ?? 0.0) ||
      (double.tryParse(_armRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['armRate'] ?? 0.0) ||
      (double.tryParse(_fixedRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['fixedRate'] ?? 0.0) ||
      (double.tryParse(_rateCapController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['rateCap'] ?? 0.0) ||
      (double.tryParse(_horizonController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['horizon'] ?? 0.0) ||
      _selectedTerm != (_calcSnapshot['term'] ?? 30) ||
      _selectedArmYrs != (_calcSnapshot['armYrs'] ?? 7)
    );

    final cardBg = _theme.getCardColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);
    final borderCol = _theme.getBorderColor(context);
    final bgCol = _theme.getBgColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final snapArmPmt = _calcSnapshot['armPmt'] ?? 0.0;
    final snapFixedPmt = _calcSnapshot['fixedPmt'] ?? 0.0;
    final snapWorstPmt = _calcSnapshot['worstPmt'] ?? 0.0;
    final snapMonthlySave = _calcSnapshot['monthlySave'] ?? 0.0;
    final snapTotalSave = _calcSnapshot['totalSave'] ?? 0.0;
    final snapRateSpread = _calcSnapshot['rateSpread'] ?? 0.0;
    final snapBreakEvenYr = _calcSnapshot['breakEvenYr'] ?? 30;
    final snapArmLabel = _calcSnapshot['armLabel'] ?? '7/1 ARM';
    final snapArmRate = _calcSnapshot['armRate'] ?? 0.0;
    final snapFixedRate = _calcSnapshot['fixedRate'] ?? 0.0;
    final snapRateCap = _calcSnapshot['rateCap'] ?? 0.0;
    final snapHorizon = _calcSnapshot['horizon'] ?? 0.0;

    final arStr = snapArmRate.toStringAsFixed(2);
    final frStr = snapFixedRate.toStringAsFixed(2);
    final capStr = snapRateCap.toStringAsFixed(2);
    final horizonStr = snapHorizon.toStringAsFixed(0);

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
                    colors: [Color(0xFF0B1D3A), Color(0xFF334155), Color(0xFF1E293B)],
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
                      Text('Jumbo ARM Options',
                          style: AppTextStyles.playfair(
                              size: 17,
                              color: Colors.white,
                              weight: FontWeight.w800)),
                      Text('Adjustable-Rate Mortgages · Above \$766,550',
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
                    child: _buildStripItem('5/1 ARM', '6.21%', 'Initial', isDark),
                  ),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(
                    child: _buildStripItem('7/1 ARM', '6.38%', 'Initial', isDark, isGold: true),
                  ),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(
                    child: _buildStripItem('10/1 ARM', '6.55%', 'Initial', isDark),
                  ),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(
                    child: _buildStripItem('30-Yr Fixed', '7.04%', 'Savings vs', isDark),
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
                _buildSectionHeader('Select ARM Type'),

                // ARM Type Selector
                Row(
                  children: [
                    Expanded(child: _buildArmTab(5, 6.21, '5/1 ARM', 'Save \$521/mo')),
                    const SizedBox(width: 6),
                    Expanded(child: _buildArmTab(7, 6.38, '7/1 ARM', 'Save \$380/mo')),
                    const SizedBox(width: 6),
                    Expanded(child: _buildArmTab(10, 6.55, '10/1 ARM', 'Save \$219/mo')),
                    const SizedBox(width: 6),
                    // 3/1 is indexed as 0 or 3
                    Expanded(child: _buildArmTab(3, 6.08, '3/1 ARM', 'Save \$645/mo')),
                  ],
                ),

                const SizedBox(height: 16),
                _buildSectionHeader('Loan Details'),

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
                          Expanded(child: _buildInputField('Loan Amount (\$)', _loanAmtController, errorText: _errors['loan'])),
                          const SizedBox(width: 10),
                          Expanded(child: _buildInputField('ARM Initial Rate (%)', _armRateController, errorText: _errors['armRate'])),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildInputField('Fixed 30-Yr Rate (%)', _fixedRateController, errorText: _errors['fixedRate'])),
                          const SizedBox(width: 10),
                          Expanded(child: _buildInputField('Expected Rate Cap (%)', _rateCapController, hint: 'Typical: initial + 5%', errorText: _errors['rateCap'])),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildInputField('Plans to Sell/Refi (Yrs)', _horizonController, errorText: _errors['horizon'])),
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
                            '🔄 Calculate ARM Savings',
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
                        const Text('🔄', style: TextStyle(fontSize: 28)),
                        const SizedBox(height: 8),
                        Text(
                          'View ARM Savings Results',
                          style: AppTextStyles.playfair(size: 13, color: textCol, weight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enter your loan details above, then tap "Calculate ARM Savings" to view details.',
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
                                    'Inputs have changed. Tap "Calculate ARM Savings" to update results.',
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
                  _buildSectionHeader('ARM vs Fixed Comparison'),

                  // Result Hero Card
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
                        Text('SIDE-BY-SIDE PAYMENT ANALYSIS',
                            style: AppTextStyles.dmSans(
                                size: 8.5,
                                color: Colors.white54,
                                weight: FontWeight.w700,
                                letterSpacing: 0.8)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ARM Monthly Payment', style: AppTextStyles.dmSans(size: 9.5, color: Colors.white54)),
                                  const SizedBox(height: 3),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: CurrencyFormatter.format(snapArmPmt, symbol: '\$').split('.').first,
                                          style: AppTextStyles.playfair(size: 26, color: const Color(0xFF86EFAC), weight: FontWeight.w800),
                                        ),
                                        TextSpan(text: ' /mo', style: AppTextStyles.dmSans(size: 11, color: Colors.white60)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text('$snapArmLabel @ $arStr%', style: AppTextStyles.dmSans(size: 8.5, color: Colors.white38)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Fixed 30-Yr Payment', style: AppTextStyles.dmSans(size: 9.5, color: Colors.white54)),
                                  const SizedBox(height: 3),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: CurrencyFormatter.format(snapFixedPmt, symbol: '\$').split('.').first,
                                          style: AppTextStyles.playfair(size: 26, color: Colors.white, weight: FontWeight.w800),
                                        ),
                                        TextSpan(text: ' /mo', style: AppTextStyles.dmSans(size: 11, color: Colors.white60)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text('30-Yr Fixed @ $frStr%', style: AppTextStyles.dmSans(size: 8.5, color: Colors.white38)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706).withValues(alpha: 0.2),
                            border: Border.all(color: const Color(0xFFFCD34D).withValues(alpha: 0.4)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '💚 Save ${CurrencyFormatter.format(snapMonthlySave, symbol: '\$').split('.').first}/mo · ${CurrencyFormatter.format(snapTotalSave, symbol: '\$').split('.').first} over $horizonStr yrs',
                            style: AppTextStyles.dmSans(size: 11, color: const Color(0xFFFCD34D), weight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 14),
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
                              '🔖 Save Calculation',
                              style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  _buildSectionHeader('Monthly Payment Through Loan Life'),

                  // Phase Chart Card
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
                        Text('📊 Monthly Payment Through Loan Life',
                            style: AppTextStyles.playfair(size: 12, color: textCol, weight: FontWeight.w800)),
                        Text('Fixed vs ARM across all rate scenarios',
                            style: AppTextStyles.dmSans(size: 9.5, color: mutedCol)),
                        const SizedBox(height: 16),
                        
                        // Custom Graph Bars
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildChartCol('ARM Fixed', snapArmPmt, const Color(0xFF15803D)),
                            _buildChartCol('Adj+1', snapArmPmt * 1.015, const Color(0xFFD97706)),
                            _buildChartCol('Adj+2', snapArmPmt * 1.03, const Color(0xFFB45309)),
                            _buildChartCol('Fixed', snapFixedPmt, const Color(0xFF0B1D3A)),
                            _buildChartCol('Cap', snapWorstPmt, const Color(0xFFB91C1C)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildChartLegendItem('Fixed Rate', const Color(0xFF0B1D3A)),
                        _buildChartLegendItem('ARM (Initial Fixed)', const Color(0xFF15803D)),
                        _buildChartLegendItem('ARM (After Adjustment)', const Color(0xFFD97706)),
                        _buildChartLegendItem('ARM (Worst Case Cap)', const Color(0xFFB91C1C)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  _buildSectionHeader('Key Figures'),

                  // Breakdown Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.45,
                    mainAxisSpacing: 9,
                    crossAxisSpacing: 9,
                    children: [
                      _buildBkCard('💰', 'Monthly Savings', CurrencyFormatter.format(snapMonthlySave, symbol: '\$').split('.').first, 'ARM vs 30-yr fixed'),
                      _buildBkCard('📅', 'Total Savings', CurrencyFormatter.format(snapTotalSave, symbol: '\$').split('.').first, 'Over $horizonStr years'),
                      _buildBkCard('📈', 'Rate Spread', '${snapRateSpread.toStringAsFixed(2)}%', 'ARM vs 30-yr fixed'),
                      _buildBkCard('⚠️', 'Worst-Case Pmt', CurrencyFormatter.format(snapWorstPmt, symbol: '\$').split('.').first, 'At $capStr% cap'),
                      _buildBkCard('🎯', 'Break-Even Point', 'Yr $snapBreakEvenYr', 'ARM costs more after'),
                      _buildBkCard('🔒', 'Adjustment Caps', '2/2/5', 'Annual/Period/Lifetime'),
                    ],
                  ),

                  const SizedBox(height: 20),
                  // Risk checklist card
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
                        Text('⚖️ Jumbo ARM Risk Profile Check',
                            style: AppTextStyles.playfair(size: 12, color: textCol, weight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        _buildRiskRow('Worst-Case Payment Increase', '+${((snapWorstPmt - snapArmPmt) / (snapArmPmt == 0 ? 1 : snapArmPmt) * 100).toStringAsFixed(0)}%'),
                        _buildRiskRow('Worst-Case Monthly Add', CurrencyFormatter.format(snapWorstPmt - snapArmPmt, symbol: '\$').split('.').first),
                        _buildRiskRow('Initial Fixed Period', '$snapArmLabel'),
                        _buildRiskRow('Maximum Interest Rate Cap', '$capStr%'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Cap Structure Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border.all(color: borderCol),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('⚠️ Jumbo ARM Cap Structure (Standard 2025)',
                            style: AppTextStyles.playfair(size: 12, color: const Color(0xFF92400E), weight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        _buildRiskRow('Initial Cap (First Adjustment)', '+2%'),
                        _buildRiskRow('Subsequent Adjustment Cap', '+2% per year'),
                        _buildRiskRow('Lifetime Cap Over Initial Rate', '+5%'),
                        _buildRiskRow('Index (Most Lenders)', 'SOFR'),
                        _buildRiskRow('Current SOFR Rate (Jun 2025)', '5.31%'),
                        _buildRiskRow('Typical Margin', '2.25%–2.75%'),
                        _buildRiskRow('Negative Amortization', 'None (Standard)', isGreenValue: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Benefits Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFF334155)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('✅ Who Benefits Most from a Jumbo ARM?',
                            style: AppTextStyles.playfair(size: 12, color: const Color(0xFFFCD34D), weight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        _buildBenefitItem('🏡', 'Short-Term Owners:', 'Planning to sell or move within 5–10 years. You leave before rates adjust.'),
                        _buildBenefitItem('💼', 'High-Income Earners:', 'Income growth outpaces potential rate increases. Payment increase is manageable.'),
                        _buildBenefitItem('📈', 'Rate-Drop Believers:', 'Expect Fed to cut rates before your fixed period ends. ARM starts lower and may fall further.'),
                        _buildBenefitItem('🔄', 'Refi-Savvy Borrowers:', 'Plan to refinance into a fixed rate if rates drop before adjustment kicks in.'),
                        _buildBenefitItem('⚠️', 'Caution:', 'If rates rise to cap, a \$1.2M ARM can cost \$3,700+/mo more than today. Ensure reserves cover worst-case scenario.'),
                      ],
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArmTab(int years, double rate, String label, String saveText) {
    final active = _selectedArmYrs == years;
    final textCol = _theme.getTextColor(context);
    return GestureDetector(
      onTap: () => _selectArm(years, rate, label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0B1D3A) : _theme.getCardColor(context),
          border: Border.all(color: active ? const Color(0xFF0B1D3A) : _theme.getBorderColor(context), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(years == 3 ? '3/1' : years == 5 ? '5/1' : years == 7 ? '7/1' : '10/1',
                style: AppTextStyles.playfair(size: 13, color: active ? Colors.white : textCol, weight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text('$rate%', style: AppTextStyles.dmSans(size: 10, color: const Color(0xFF15803D), weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(saveText, style: AppTextStyles.dmSans(size: 7, color: active ? Colors.white60 : _theme.getMutedColor(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {String? hint, String? errorText}) {
    const theme = _theme;
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasError ? '${label.toUpperCase()} - $errorText' : label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8.5,
            weight: FontWeight.w700,
            color: hasError ? Colors.red : theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            border: Border.all(
              color: hasError ? Colors.red : theme.getBorderColor(context),
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
              weight: FontWeight.w800,
              color: theme.getTextColor(context),
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        if (hint != null && !hasError) ...[
          const SizedBox(height: 3),
          Text(hint, style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context))),
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

  Widget _buildChartCol(String phase, double payment, Color color) {
    final double snapFixedPmt = _calcSnapshot['fixedPmt'] ?? 0.0;
    final double snapWorstPmt = _calcSnapshot['worstPmt'] ?? 0.0;
    // scale max height = 110
    final double maxVal = max<double>(snapFixedPmt, snapWorstPmt) * 1.05;
    final double h = max(10.0, (payment / (maxVal == 0 ? 1.0 : maxVal)) * 100);
    return Column(
      children: [
        Text(CurrencyFormatter.compact(payment, symbol: '\$'),
            style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: _theme.getTextColor(context))),
        const SizedBox(height: 4),
        Container(
          width: 32,
          height: h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        const SizedBox(height: 6),
        Text(phase, style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w700, color: _theme.getMutedColor(context))),
      ],
    );
  }

  Widget _buildChartLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.dmSans(size: 9.5, color: _theme.getMutedColor(context))),
        ],
      ),
    );
  }

  Widget _buildBkCard(String emoji, String label, String value, String sub) {
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _theme.getBorderColor(context)),
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
                child: Text(label.toUpperCase(),
                    style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w700, color: mutedCol, letterSpacing: 0.3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.playfair(size: 16, weight: FontWeight.w800, color: textCol)),
          const SizedBox(height: 2),
          Text(sub, style: AppTextStyles.dmSans(size: 8, color: mutedCol), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }



  Widget _buildRiskRow(String label, String value, {bool isGreenValue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 10, color: const Color(0xFF92400E), weight: FontWeight.w600)),
          Text(value,
              style: AppTextStyles.dmSans(
                  size: 10,
                  color: isGreenValue ? const Color(0xFF15803D) : const Color(0xFFB45309),
                  weight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String emoji, String strongText, String normalText) {
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
                style: AppTextStyles.dmSans(size: 10, color: Colors.white70, height: 1.4),
                children: [
                  TextSpan(text: '$strongText ', style: AppTextStyles.dmSans(size: 10, color: Colors.white, weight: FontWeight.w800)),
                  TextSpan(text: normalText),
                ],
              ),
            ),
          ),
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
