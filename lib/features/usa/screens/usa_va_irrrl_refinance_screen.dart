// lib/features/usa/screens/usa_va_irrrl_refinance_screen.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAVaIrrrlRefinanceScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAVaIrrrlRefinanceScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAVaIrrrlRefinanceScreen> createState() => _USAVaIrrrlRefinanceScreenState();
}

class _USAVaIrrrlRefinanceScreenState extends ConsumerState<USAVaIrrrlRefinanceScreen> {
  static const _theme = CountryThemes.usa;

  final _resultsKey = GlobalKey();
  final Map<String, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};

  // Controllers
  final _curBalanceController = TextEditingController(text: '380000');
  final _curRateController = TextEditingController(text: '7.00');
  final _newRateController = TextEditingController(text: '5.96');
  int _termYears = 30;
  String _selectedExempt = 'no'; // no, yes
  final _closingCostsController = TextEditingController(text: '2500');

  // Outputs
  bool _calculated = false;
  double _monthlySavings = 312.0;
  double _newPI = 2520.0;
  double _oldPI = 2832.0;
  double _fundingFee = 1900.0;
  double _newLoanAmt = 381900.0;
  double _lifetimeSavings = 48300.0;
  double _rateDrop = -1.04;
  double _totalRefiCost = 4400.0;
  double _breakEvenMonths = 9.0;
  double _fiveYrSavings = 14200.0;
  bool _ntbMet = true;

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _curBalanceController.text = (inputs['curBalance'] ?? 380000.0).toStringAsFixed(0);
      _curRateController.text = (inputs['curRate'] ?? 7.00).toStringAsFixed(2);
      _newRateController.text = (inputs['newRate'] ?? 5.96).toStringAsFixed(2);
      _termYears = (inputs['termYears'] ?? 30.0).toInt();
      _selectedExempt = (inputs['exempt'] ?? 0.0) == 0.0 ? 'no' : 'yes';
      _closingCostsController.text = (inputs['closingCosts'] ?? 2500.0).toStringAsFixed(0);
      _calculate();
    }
  }

  @override
  void dispose() {
    _curBalanceController.dispose();
    _curRateController.dispose();
    _newRateController.dispose();
    _closingCostsController.dispose();
    super.dispose();
  }

  double _pmtFor(double principal, double annualRate, int months) {
    final mr = annualRate / 12;
    if (mr == 0) return principal / months;
    return principal * (mr * pow(1 + mr, months)) / (pow(1 + mr, months) - 1);
  }

  void _calculate() {
    final errors = <String, String>{};
    final balance = double.tryParse(_curBalanceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final curRateVal = double.tryParse(_curRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final newRateVal = double.tryParse(_newRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final closingCosts = double.tryParse(_closingCostsController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    if (balance <= 0) {
      errors['balance'] = 'Enter positive balance';
    }
    if (curRateVal <= 0) {
      errors['curRate'] = 'Enter positive rate';
    }
    if (newRateVal <= 0) {
      errors['newRate'] = 'Enter positive rate';
    }
    if (closingCosts < 0) {
      errors['closingCosts'] = 'Enter valid closing costs';
    }

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) {
      setState(() {
        _calculated = false;
      });
      return;
    }

    final curRate = curRateVal / 100;
    final newRate = newRateVal / 100;
    final exempt = _selectedExempt == 'yes';
    final months = _termYears * 12;

    final ffRate = exempt ? 0.0 : 0.005;
    final fundingFee = balance * ffRate;
    final newLoanAmt = balance + fundingFee;

    final oldPI = _pmtFor(balance, curRate, months);
    final newPI = _pmtFor(newLoanAmt, newRate, months);
    final monthlySavings = oldPI - newPI;

    final totalRefiCost = fundingFee + closingCosts;
    final breakEvenMonths = monthlySavings > 0 ? (totalRefiCost / monthlySavings) : double.infinity;

    final lifetimeOld = oldPI * months;
    final lifetimeNew = newPI * months;
    final lifetimeSavings = lifetimeOld - lifetimeNew - totalRefiCost;
    final fiveYrSavings = (monthlySavings * 60) - totalRefiCost;

    setState(() {
      _calcSnapshot['curBalance'] = balance;
      _calcSnapshot['curRate'] = curRateVal;
      _calcSnapshot['newRate'] = newRateVal;
      _calcSnapshot['termYears'] = _termYears;
      _calcSnapshot['exempt'] = _selectedExempt;
      _calcSnapshot['closingCosts'] = closingCosts;

      _monthlySavings = monthlySavings;
      _newPI = newPI;
      _oldPI = oldPI;
      _fundingFee = fundingFee;
      _newLoanAmt = newLoanAmt;
      _lifetimeSavings = lifetimeSavings;
      _rateDrop = (newRate - curRate) * 100;
      _totalRefiCost = totalRefiCost;
      _breakEvenMonths = breakEvenMonths;
      _fiveYrSavings = fiveYrSavings;
      _ntbMet = newRate < curRate && monthlySavings > 0;
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

    final balance = _calcSnapshot['curBalance'] ?? 380000.0;
    final curRate = _calcSnapshot['curRate'] ?? 7.00;
    final newRate = _calcSnapshot['newRate'] ?? 5.96;
    final term = _calcSnapshot['termYears'] ?? 30;
    final exempt = _calcSnapshot['exempt'] ?? 'no';
    final exemptIdx = exempt == 'no' ? 0.0 : 1.0;
    final closingCosts = _calcSnapshot['closingCosts'] ?? 2500.0;

    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'VA IRRRL Streamline Refi',
      label: 'VA IRRRL: \$${CurrencyFormatter.compact(balance, symbol: "")} @ ${newRate.toStringAsFixed(2)}%',
      currencyCode: 'USD',
      inputs: {
        'curBalance': balance,
        'curRate': curRate,
        'newRate': newRate,
        'termYears': term.toDouble(),
        'exempt': exemptIdx,
        'closingCosts': closingCosts,
      },
      results: {
        'MonthlySavings': _monthlySavings,
        'NewPI': _newPI,
        'FundingFee': _fundingFee,
        'LifetimeSavings': _lifetimeSavings,
        'BreakEvenMonths': _breakEvenMonths.isInfinite ? 999.0 : _breakEvenMonths,
      },
    );

    ref.read(savedProvider.notifier).save(calc);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ IRRRL streamline scenario saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDirty = _calculated && (
      (double.tryParse(_curBalanceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['curBalance'] ?? 0.0) ||
      (double.tryParse(_curRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['curRate'] ?? 0.0) ||
      (double.tryParse(_newRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['newRate'] ?? 0.0) ||
      _termYears != (_calcSnapshot['termYears'] ?? 30) ||
      _selectedExempt != (_calcSnapshot['exempt'] ?? 'no') ||
      (double.tryParse(_closingCostsController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['closingCosts'] ?? 0.0)
    );

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
                    colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72), Color(0xFF4C1D95)],
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
                      Text('VA IRRRL Streamline Refi',
                          style: AppTextStyles.playfair(
                              size: 17, color: Colors.white, weight: FontWeight.w800)),
                      Text('Lower your rate · Less paperwork',
                          style: AppTextStyles.dmSans(size: 9.5, color: Colors.white60)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // summary strip
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
                  Expanded(child: _buildStripItem('Funding Fee', '0.5%', 'vs 2.15%+ New', isDark, isGold: true)),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(child: _buildStripItem('Appraisal', 'None', 'Usually Skipped', isDark)),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(child: _buildStripItem('Avg. Refi Rate', '5.96%', '30-Yr Today', isDark)),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(child: _buildStripItem('Close Time', '15–30d', 'Faster Than New', isDark)),
                ],
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Alert Strip
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F).withValues(alpha: 0.08),
                    border: Border.all(color: const Color(0xFF1E3A5F).withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🔄 ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: Text(
                          'IRRRL = Interest Rate Reduction Refinance Loan. It only refinances an existing VA loan to a new VA loan — usually no appraisal, no income verification, and a funding fee of just 0.5%.',
                          style: AppTextStyles.dmSans(size: 9.5, color: isDark ? Colors.white70 : const Color(0xFF1E3A5F), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

                _buildSectionHeader('Your Current VA Loan'),

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
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField('Current Loan Balance (\$)', _curBalanceController, errorText: _errors['balance']),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInputField('Current Rate (%)', _curRateController, errorText: _errors['curRate']),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField('New IRRRL Rate (%)', _newRateController, hint: '30-yr VA refi ~5.96%', errorText: _errors['newRate']),
                          ),
                          const SizedBox(width: 10),
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
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField<String>(
                              label: 'Disability Exempt?',
                              value: _selectedExempt,
                              items: const [
                                DropdownMenuItem(value: 'no', child: Text('No (pay 0.5% fee)')),
                                DropdownMenuItem(value: 'yes', child: Text('Yes (fee exempt)')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedExempt = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInputField('Est. Closing Costs (\$)', _closingCostsController, hint: 'Excl. funding fee', errorText: _errors['closingCosts']),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Result Hero Card
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
                          'View IRRRL Streamline Refinance Estimate',
                          style: AppTextStyles.playfair(size: 13, color: textCol, weight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enter your loan details above, then tap "Calculate Refi Savings" to see monthly savings, break-even timeline, and detailed breakdown.',
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
                                    'Inputs have changed. Tap "Calculate Refi Savings" to update results.',
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
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
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
                            Text('ESTIMATED MONTHLY SAVINGS',
                                style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54, weight: FontWeight.w700, letterSpacing: 0.8)),
                            const SizedBox(height: 6),
                            Text(
                              (_monthlySavings >= 0 ? '\$' : '-\$') + _monthlySavings.abs().round().toString(),
                              style: AppTextStyles.playfair(size: 32, color: Colors.white, weight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text('New P&I: \$${_newPI.round()}/mo · Old P&I: \$${_oldPI.round()}/mo',
                                style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFFCD34D), weight: FontWeight.w700)),
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
                  const SizedBox(height: 8),

                  // Net Tangible Benefit Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _ntbMet ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                      border: Border.all(color: _ntbMet ? const Color(0xFF86EFAC) : const Color(0xFFFCD34D)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(_ntbMet ? '🎯' : '⚠️', style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _ntbMet ? 'Net Tangible Benefit: Likely Met' : 'Net Tangible Benefit: Needs Review',
                                style: AppTextStyles.dmSans(size: 10.5, color: _ntbMet ? const Color(0xFF14532D) : const Color(0xFF92400E), weight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _ntbMet
                                    ? 'Rate drops ${_rateDrop.abs().toStringAsFixed(2)}% — meets VA\'s lower-rate benefit test'
                                    : 'New rate isn\'t lower — VA still allows ARM→fixed conversions as a qualifying benefit',
                                style: AppTextStyles.dmSans(size: 9, color: _ntbMet ? const Color(0xFF15803D) : const Color(0xFFB45309)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  _buildSectionHeader('Break-Even Timeline (Total Cost vs. Savings)'),

                  // Chart card
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
                        Text('📈 Break-Even Timeline',
                            style: AppTextStyles.playfair(size: 11.5, color: textCol, weight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 100,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: IrrrlBreakEvenChartPainter(
                              monthlySavings: _monthlySavings,
                              totalCost: _totalRefiCost,
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
                            _buildChartStatBox('Break-Even', _monthlySavings > 0 && !_breakEvenMonths.isInfinite ? '${_breakEvenMonths.ceil()} mo' : 'N/A', textCol, mutedCol),
                            _buildChartStatBox('Total Refi Cost', CurrencyFormatter.format(_totalRefiCost, symbol: '\$').split('.').first, textCol, mutedCol),
                            _buildChartStatBox('5-Yr Net Savings', CurrencyFormatter.format(_fiveYrSavings, symbol: '\$').split('.').first, textCol, mutedCol),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Breakdown Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.4,
                    children: [
                      _buildBreakdownCard('💵', 'New Monthly P&I', '\$${_newPI.round()}', 'At new rate', textCol, mutedCol),
                      _buildBreakdownCard('📉', 'Old Monthly P&I', '\$${_oldPI.round()}', 'At current rate', textCol, mutedCol),
                      _buildBreakdownCard('⚡', 'IRRRL Funding Fee', _selectedExempt == 'yes' ? 'Exempt' : '\$${_fundingFee.round()}', '0.5% — often financed', textCol, mutedCol),
                      _buildBreakdownCard('📦', 'New Loan Amount', '\$${_newLoanAmt.round()}', 'Balance + financed fee', textCol, mutedCol),
                      _buildBreakdownCard('💰', 'Lifetime Interest Saved', (_lifetimeSavings >= 0 ? '\$' : '-\$') + _lifetimeSavings.abs().round().toString(), 'Over remaining term*', textCol, mutedCol),
                      _buildBreakdownCard('📅', 'Rate Improvement', '${_rateDrop.toStringAsFixed(2)}%', 'Old vs. new rate', _rateDrop < 0 ? const Color(0xFF15803D) : const Color(0xFFB91C1C), mutedCol),
                    ],
                  ),
                ],

                const SizedBox(height: 20),
                _buildSectionHeader('IRRRL Funding Fee & Rules'),

                // Table limits
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
                      Text('⚡ VA IRRRL Funding Fee Schedule',
                          style: AppTextStyles.playfair(size: 11.5, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      _buildLimitRow('Standard IRRRL Fee (all borrowers)', '0.50%', textCol),
                      _buildLimitRow('10%+ Service-Connected Disability', 'EXEMPT (\$0)', textCol, isGreen: true),
                      _buildLimitRow('Surviving Spouse (qualifying)', 'EXEMPT (\$0)', textCol, isGreen: true),
                      _buildLimitRow('New VA Purchase Loan Fee (comparison)', '2.15%–3.30%', textCol),
                      _buildLimitRow('Min. Wait Since First Payment', '210 days', textCol),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('IRRRL Eligibility Checklist'),

                // Rules
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildCompareRow('Existing VA Loan', '✅ Required — VA-to-VA only', textCol),
                      _buildCompareRow('On-Time Payment History', '✅ 6 consecutive on-time pmts', textCol),
                      _buildCompareRow('Loan Seasoning', '✅ 210 days min. since 1st payment', textCol),
                      _buildCompareRow('Net Tangible Benefit', '⚡ Lower rate or ARM→fixed', textCol, isGold: true),
                      _buildCompareRow('Appraisal / Income Docs', '✅ Usually not required', textCol),
                      _buildCompareRow('Payment Jumps 20%+', '⚡ Triggers income verification', textCol, isGold: true),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                // Footer note
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
                          'No limit on how many times you can use an IRRRL — but each refinance must clear the 210-day seasoning rule and deliver a genuine net tangible benefit. *Interest savings are an estimate; actual totals depend on final rate, fees, and loan terms at closing.',
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

  Widget _buildChartStatBox(String label, String val, Color textCol, Color mutedCol) {
    return Column(
      children: [
        Text(val, style: AppTextStyles.playfair(size: 15, color: textCol, weight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label.toUpperCase(), style: AppTextStyles.dmSans(size: 8, color: mutedCol, weight: FontWeight.w700)),
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

  Widget _buildLimitRow(String key, String val, Color textCol, {bool isGreen = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _theme.getBorderColor(context), width: 0.8))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w600, color: textCol)),
          Text(val, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: isGreen ? const Color(0xFF15803D) : textCol)),
        ],
      ),
    );
  }

  Widget _buildCompareRow(String label, String value, Color textCol, {bool isGold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _theme.getBorderColor(context)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 11, color: textCol, weight: FontWeight.w700).copyWith(fontFamily: 'Georgia')),
          Text(value, style: AppTextStyles.dmSans(size: 10.5, color: isGold ? const Color(0xFFD97706) : const Color(0xFF15803D), weight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// Custom Painter to draw a vertical bar chart of Year 1-10 net positions
class IrrrlBreakEvenChartPainter extends CustomPainter {
  final double monthlySavings;
  final double totalCost;
  final bool isDark;

  IrrrlBreakEvenChartPainter({required this.monthlySavings, required this.totalCost, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final double W = size.width;
    final double H = size.height;

    // Calculate net positions for years 1 to 10
    const int years = 10;
    final List<double> netPositions = [];
    double maxAbsVal = 1000.0; // default baseline

    for (int y = 1; y <= years; y++) {
      final double cumSavings = monthlySavings * 12 * y;
      final double net = cumSavings - totalCost;
      netPositions.add(net);
      if (net.abs() > maxAbsVal) {
        maxAbsVal = net.abs();
      }
    }

    const double barGap = 6;
    final double totalBarsWidth = W - (barGap * (years - 1));
    final double barWidth = totalBarsWidth / years;

    final Paint borderPaint = Paint()
      ..color = isDark ? Colors.white12 : const Color(0xFFEEF2F8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw baseline at net position = 0
    // We want the chart to display from H-2 down to H*0.1 (all positive or negative)
    // To display standard (negative) and over (positive) correctly, we need the zero line.
    // If the zero line lies between the min and max:
    // Zero line Y location:
    // Let's assume the bottom of the chart is H. The height of the bar is calculated relative to maxAbsVal.
    // In the HTML, it sets heightPct = Math.min(100, Math.max(2, (Math.abs(netPosition)/maxVal)*100*2.2));
    // Since it's a bottom-aligned bar chart in HTML, let's represent standard vertical bars.
    // A premium design in Flutter:
    // If netPosition < 0, let's draw standard bar.
    // If netPosition >= 0, let's draw over bar.
    // Let's make bars start from the bottom line H, with height proportional to absolute net position.
    
    for (int i = 0; i < years; i++) {
      final net = netPositions[i];
      final isOver = net >= 0;

      // Scale height from 4px to H
      final double ratio = maxAbsVal > 0 ? (net.abs() / maxAbsVal) : 0.0;
      final double barHeight = (ratio * H).clamp(4.0, H);

      final double x = i * (barWidth + barGap);
      final double y = H - barHeight;

      final RRect rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(3),
      );

      final Paint barPaint = Paint();
      if (isOver) {
        barPaint.shader = const LinearGradient(
          colors: [Color(0xFFFCD34D), Color(0xFFD97706)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(x, y, barWidth, barHeight));
      } else {
        barPaint.shader = const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF1B3F72)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(x, y, barWidth, barHeight));
      }

      canvas.drawRRect(rrect, barPaint);
      canvas.drawRRect(rrect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
