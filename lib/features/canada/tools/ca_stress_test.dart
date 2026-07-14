// lib/features/canada/tools/ca_stress_test.dart

import 'dart:math' as dm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/cmhc_calculator.dart';
import '../../../core/utils/mortgage_math.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/result_panel.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/canada_rates_provider.dart';
import '../../../shared/models/saved_calc.dart';

class CAStressTestSheet extends StatefulWidget {
  final double homePrice;
  final double downPercent;
  final double? defaultContractRate;

  const CAStressTestSheet(
      {super.key, this.homePrice = 650000, this.downPercent = 10, this.defaultContractRate});

  @override
  State<CAStressTestSheet> createState() => _CAStressTestSheetState();
}

class _CAStressTestSheetState extends State<CAStressTestSheet> {
  late double _income, _contractRate, _price, _downPct;
  static const _theme = CountryThemes.canada;

  @override
  void initState() {
    super.initState();
    _income = 120000;
    _contractRate = widget.defaultContractRate ?? 4.99;
    _price = widget.homePrice;
    _downPct = widget.downPercent;
  }

  double get _stressRate => CMHCCalculator.stressTestRate(_contractRate);
  double get _loan => _price * (1 - _downPct / 100);
  double get _stressPayment => MortgageMath.canadianMonthlyPayment(
      principal: _loan, annualRatePercent: _stressRate, termYears: 25);
  double get _gds => CMHCCalculator.gdsRatio(
      monthlyMortgage: _stressPayment,
      monthlyPropertyTax: _price * 0.01 / 12,
      monthlyHeating: 200,
      grossMonthlyIncome: _income / 12);
  bool get _passes => _gds <= 39;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.90,
      minChildSize: 0.4,
      expand: false,
      builder: (context, sc) => Container(
        decoration: BoxDecoration(
            color: _theme.getBgColor(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: ListView(
          controller: sc,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('🧪 Mortgage Stress Test',
                style:
                    AppTextStyles.dmSans(size: 18, weight: FontWeight.w800, color: _theme.getTextColor(context))),
            Text('Qualify at max(contract+2%, 5.25%)',
                style:
                    AppTextStyles.dmSans(size: 10, color: _theme.getMutedColor(context))),
            const SizedBox(height: 20),
            _row('Annual Gross Income',
                CurrencyFormatter.compact(_income, symbol: 'CA\$')),
            _slider(_income, 30000, 500000, 470,
                (v) => setState(() => _income = v)),
            _row('Contract Rate', '${_contractRate.toStringAsFixed(2)}%'),
            _slider(_contractRate, 1, 12, 110,
                (v) => setState(() => _contractRate = v)),
            _row('Home Price',
                CurrencyFormatter.compact(_price, symbol: 'CA\$')),
            _slider(_price, 100000, 2000000, 190,
                (v) => setState(() => _price = v)),
            _row('Down Payment', '${_downPct.toInt()}%'),
            _slider(_downPct, 5, 50, 45, (v) => setState(() => _downPct = v)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    _passes ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _passes
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  Text(_passes ? '✅' : '❌',
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            _passes
                                ? 'PASSES Stress Test'
                                : 'FAILS Stress Test',
                            style: AppTextStyles.dmSans(
                                size: 16,
                                weight: FontWeight.w800,
                                color: _passes
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFFB91C1C))),
                        Text(
                            'GDS Ratio: ${_gds.toStringAsFixed(1)}% (limit 39%)',
                            style: AppTextStyles.dmSans(
                                size: 11,
                                color: _passes
                                    ? const Color(0xFF166534)
                                    : const Color(0xFF991B1B))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ResultPanel(
              primaryColor: _theme.primaryColor,
              rows: [
                ResultRow(
                    label: 'Stress Test Rate',
                    value: _stressRate,
                    isPercent: true,
                    isHighlighted: true),
                ResultRow(
                    label: 'Stress Payment/mo',
                    value: _stressPayment,
                    currencyCode: 'CAD'),
                ResultRow(label: 'GDS Ratio', value: _gds, isPercent: true),
                ResultRow(
                    label: 'Contract Rate',
                    value: _contractRate,
                    isPercent: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l,
                style: AppTextStyles.dmSans(
                    size: 11,
                    weight: FontWeight.w600,
                    color: const Color(0xFF5B6E8F))),
            Text(v,
                style: AppTextStyles.dmSans(
                    size: 13, weight: FontWeight.w700, color: _theme.primaryColor)),
          ],
        ),
      );

  Widget _slider(double val, double min, double max, int div,
          ValueChanged<double> cb) =>
      SliderTheme(
        data: SliderThemeData(
            activeTrackColor: _theme.primaryColor,
            thumbColor: _theme.primaryColor,
            inactiveTrackColor: _theme.primaryColor.withValues(alpha: 0.20),
            trackHeight: 3),
        child: Slider(
            value: val.clamp(min, max),
            min: min,
            max: max,
            divisions: div,
            onChanged: cb),
      );
}

// ════════════════════════════════════════════════════════════════════════════
//  🧪  CANADIAN MORTGAGE STRESS TEST TOOL SCREEN
// ════════════════════════════════════════════════════════════════════════════
class CAStressTest extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const CAStressTest({super.key, required this.theme});

  @override
  ConsumerState<CAStressTest> createState() => _CAStressTestState();
}

class _CAStressTestState extends ConsumerState<CAStressTest> {
  final _incomeController = TextEditingController(text: '120000');
  final _rateController = TextEditingController(text: '4.99');
  final _downController = TextEditingController(text: '100000');
  final _debtsController = TextEditingController(text: '500');

  final _resultsKey = GlobalKey();
  bool _showResults = false;
  final Map<dynamic, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};

  @override
  void dispose() {
    _incomeController.dispose();
    _rateController.dispose();
    _downController.dispose();
    _debtsController.dispose();
    super.dispose();
  }

  double _monthlyPayment(double loan, double rate, double years) {
    if (loan <= 0 || rate <= 0 || years <= 0) return 0;
    final ea = dm.pow(1 + rate / 200, 2) - 1;
    final r = ea / 12;
    final n = years * 12;
    return loan * r / (1 - dm.pow(1 + r, -n));
  }

  double _maxLoan(double income, double debts, double rate, double years) {
    final monthlyIncome = income / 12;
    final maxDebt = monthlyIncome * 0.44 - debts - 400 - 150;
    if (maxDebt <= 0) return 0;
    double lo = 0;
    double hi = 5000000;
    for (int i = 0; i < 50; i++) {
      final mid = (lo + hi) / 2;
      final p = _monthlyPayment(mid, rate, years);
      if (p < maxDebt) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  double _val(TextEditingController c, double defaultVal) {
    if (_showResults && _calcSnapshot.containsKey(c)) {
      return _calcSnapshot[c]!;
    }
    return double.tryParse(c.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? defaultVal;
  }

  void _calculate() {
    final errors = <String, String>{};

    final income = double.tryParse(_incomeController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (income <= 0) errors['income'] = 'Enter gross annual income';

    final contract = double.tryParse(_rateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (contract <= 0 || contract > 25) errors['rate'] = 'Enter interest rate (0.1% - 25%)';

    final down = double.tryParse(_downController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (down < 0) errors['down'] = 'Enter a valid down payment';

    final otherDebts = double.tryParse(_debtsController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (otherDebts < 0) errors['debts'] = 'Enter valid monthly debts';

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) return;

    setState(() {
      _calcSnapshot[_incomeController] = income;
      _calcSnapshot[_rateController] = contract;
      _calcSnapshot[_downController] = down;
      _calcSnapshot[_debtsController] = otherDebts;
      _showResults = true;
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

  void _resetInputs() {
    setState(() {
      _incomeController.text = '120000';
      _rateController.text = '4.99';
      _downController.text = '100000';
      _debtsController.text = '500';
      _calcSnapshot.clear();
      _errors.clear();
      _showResults = false;
    });
  }

  void _saveCalculation() async {
    final double income = _val(_incomeController, 120000);
    final double contract = _val(_rateController, 4.99);
    final double down = _val(_downController, 100000);
    final double otherDebts = _val(_debtsController, 500);

    final double qualRate = CMHCCalculator.stressTestRate(contract);
    final double maxLoanAmt = _maxLoan(income, otherDebts, qualRate, 25);
    final double maxPrice = maxLoanAmt + down;

    final labelCtrl = TextEditingController(text: 'Stress Test Result');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/ca_stress_test/save'),
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
              'Saving: Max Price ${CurrencyFormatter.compact(maxPrice, symbol: 'CA\$')} · Income: ${CurrencyFormatter.compact(income, symbol: 'CA\$')}',
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
                hintText: 'Label (e.g. Qualification Run)',
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
          : 'Stress Test';
      final calc = SavedCalc.create(
        country: 'Canada',
        calcType: 'Stress Test',
        inputs: {
          'Income': income,
          'Contract': contract,
          'Down': down,
          'Debts': otherDebts,
        },
        results: {
          'MaxPrice': maxPrice,
          'MaxLoan': maxLoanAmt,
          'QualifyingRate': qualRate,
        },
        label: label,
        currencyCode: 'CAD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Stress Test calculation saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: widget.theme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  bool _rateInitialized = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    // Watch rates provider to initialize default contract rate
    final ratesAsync = ref.watch(canadaCalculatedRatesProvider);
    if (ratesAsync.hasValue && !_rateInitialized) {
      final defaultRate = ratesAsync.value!.rate5yrFixed;
      _rateController.text = defaultRate.toStringAsFixed(2);
      _rateInitialized = true;
    }

    final double income = _val(_incomeController, 120000);
    final double contract = _val(_rateController, 4.99);
    final double down = _val(_downController, 100000);
    final double otherDebts = _val(_debtsController, 500);

    final double cPlus2 = contract + 2.0;
    const double floor = 5.25;
    final double qualRate = CMHCCalculator.stressTestRate(contract);
    final bool usingFloor = qualRate == floor;

    final double maxLoanAmt = _maxLoan(income, otherDebts, qualRate, 25);
    final double maxPrice = maxLoanAmt + down;
    final double stressPmt = _monthlyPayment(maxLoanAmt, qualRate, 25);
    final double contractPmt = _monthlyPayment(maxLoanAmt, contract, 25);

    final double monthlyIncome = income / 12;
    final double gds = monthlyIncome > 0 ? ((stressPmt + 400 + 150) / monthlyIncome * 100) : 0;
    final double tds = monthlyIncome > 0 ? (gds + (otherDebts / monthlyIncome * 100)) : 0;

    final bool qualifies = gds <= 39 && tds <= 44 && maxLoanAmt > 0;

    final double gdsW = (gds / 39 * 100).clamp(0, 100);
    final double tdsW = (tds / 44 * 100).clamp(0, 100);

    final isDirty = _showResults && (
      (double.tryParse(_incomeController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_incomeController] ?? 0.0) ||
      (double.tryParse(_rateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_rateController] ?? 0.0) ||
      (double.tryParse(_downController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_downController] ?? 0.0) ||
      (double.tryParse(_debtsController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_debtsController] ?? 0.0)
    );

    Color getStatusColor(double val, double limit) {
      if (val > limit) return const Color(0xFFC8102E);
      if (val > limit * 0.85) return const Color(0xFFF59E0B);
      return const Color(0xFF1A5C35);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'YOUR DETAILS',
              style: AppTextStyles.dmSans(
                size: 10,
                weight: FontWeight.bold,
                color: theme.getMutedColor(context),
                letterSpacing: 0.6,
              ),
            ),
            GestureDetector(
              onTap: _resetInputs,
              child: Text(
                'Reset',
                style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Input card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [
              _buildInputField(
                label: 'Gross Annual Household Income',
                prefix: 'CA\$',
                suffix: '/yr',
                controller: _incomeController,
                errorText: _errors['income'],
              ),
              const SizedBox(height: 12),
              _buildInputField(
                label: 'Contract Mortgage Rate',
                suffix: '% / yr',
                controller: _rateController,
                errorText: _errors['rate'],
              ),
              const SizedBox(height: 12),
              _buildInputField(
                label: 'Down Payment',
                prefix: 'CA\$',
                controller: _downController,
                errorText: _errors['down'],
              ),
              const SizedBox(height: 12),
              _buildInputField(
                label: 'Other Monthly Debts',
                prefix: 'CA\$',
                suffix: '/mo',
                controller: _debtsController,
                errorText: _errors['debts'],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _calculate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC8102E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        '🧪 Run Stress Test',
                        style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (_showResults) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _saveCalculation,
                      child: Container(
                        width: 50,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B3F72),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text('💾', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_showResults) ...[
          if (isDirty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Text('⚠️ ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(
                      'Inputs have changed. Tap Calculate to refresh results.',
                      style: AppTextStyles.dmSans(size: 11, color: Colors.amber[800], weight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            key: _resultsKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Qualifying rate comparator
                Text(
                  'QUALIFYING RATE USED',
                  style: AppTextStyles.dmSans(
                    size: 10,
                    weight: FontWeight.bold,
                    color: theme.getMutedColor(context),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.getCardColor(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.getBorderColor(context)),
                  ),
                  child: Column(
                    children: [
                      _buildRateRow('Contract Rate + 2%', '${cPlus2.toStringAsFixed(2)}%', !usingFloor, theme),
                      const Divider(height: 16, thickness: 0.5),
                      _buildRateRow('Regulatory Floor Rate', '${floor.toStringAsFixed(2)}%', usingFloor, theme),
                      const Divider(height: 16, thickness: 0.5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Qualifying Rate',
                            style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: theme.getTextColor(context)),
                          ),
                          Text(
                            '${qualRate.toStringAsFixed(2)}%',
                            style: AppTextStyles.playfair(size: 16, weight: FontWeight.bold, color: const Color(0xFFC8102E)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Result Card
                Text(
                  'STRESS TEST RESULT',
                  style: AppTextStyles.dmSans(
                    size: 10,
                    weight: FontWeight.bold,
                    color: theme.getMutedColor(context),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A2E1A), Color(0xFF1A5C35)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: qualifies ? const Color(0xFF6EDFA0) : const Color(0xFFFF8A9A),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              qualifies ? '✓' : '✗',
                              style: AppTextStyles.playfair(size: 24, weight: FontWeight.w900, color: const Color(0xFF0A2E1A)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  qualifies ? 'You Qualify' : 'Does Not Qualify',
                                  style: AppTextStyles.playfair(size: 20, weight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  qualifies
                                      ? 'Max home: ${CurrencyFormatter.format(maxPrice, symbol: 'CA\$')} at stress rate'
                                      : 'Reduce debts or increase income to qualify',
                                  style: AppTextStyles.dmSans(size: 10.5, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 2.2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        children: [
                          _resBox('Max Home Price', CurrencyFormatter.format(maxPrice, symbol: 'CA\$'), const Color(0xFF6EDFA0)),
                          _resBox('Stress Payment/mo', CurrencyFormatter.format(stressPmt, symbol: 'CA\$'), const Color(0xFFFF8A9A)),
                          _resBox('GDS at Stress', '${gds.toStringAsFixed(1)}%', Colors.white),
                          _resBox('TDS at Stress', '${tds.toStringAsFixed(1)}%', Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Visual Analysis (Utilization Ranges)
                Text(
                  'VISUAL ANALYSIS',
                  style: AppTextStyles.dmSans(
                    size: 10,
                    weight: FontWeight.bold,
                    color: theme.getMutedColor(context),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.getCardColor(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.getBorderColor(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Qualifying Ratio Gauges',
                        style: AppTextStyles.playfair(size: 13, weight: FontWeight.bold, color: theme.getTextColor(context)),
                      ),
                      const SizedBox(height: 16),
                      _buildProgressTrack('GDS Utilization', '${gds.toStringAsFixed(1)}% / 39% Limit', gdsW / 100, getStatusColor(gds, 39)),
                      const SizedBox(height: 16),
                      _buildProgressTrack('TDS Utilization', '${tds.toStringAsFixed(1)}% / 44% Limit', tdsW / 100, getStatusColor(tds, 44)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Contract vs Stress payment comparison
                Text(
                  'CONTRACT VS. STRESS PAYMENT',
                  style: AppTextStyles.dmSans(
                    size: 10,
                    weight: FontWeight.bold,
                    color: theme.getMutedColor(context),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.getCardColor(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.getBorderColor(context)),
                  ),
                  child: Column(
                    children: [
                      _compareRow('At Contract Rate', '${contract.toStringAsFixed(2)}% — your actual payment', CurrencyFormatter.format(contractPmt, symbol: 'CA\$'), const Color(0xFF1A5C35)),
                      const Divider(height: 20, thickness: 0.5),
                      _compareRow('At Stress Rate', '${qualRate.toStringAsFixed(2)}% — qualifying test', CurrencyFormatter.format(stressPmt, symbol: 'CA\$'), const Color(0xFFC8102E)),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '+${CurrencyFormatter.format(stressPmt - contractPmt, symbol: 'CA\$')}/mo difference at stress rate',
                          style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context), weight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    String? prefix,
    String? suffix,
    required TextEditingController controller,
    String? errorText,
  }) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 9,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null ? Colors.red : theme.getBorderColor(context),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              if (prefix != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(prefix, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.bold, color: theme.primaryColor)),
                ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  onChanged: (val) => setState(() {}),
                  style: AppTextStyles.dmSans(
                    size: 16,
                    weight: FontWeight.bold,
                    color: theme.getTextColor(context),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                  ),
                ),
              ),
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(suffix, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w600, color: theme.getMutedColor(context))),
                ),
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: AppTextStyles.dmSans(size: 10, color: Colors.red, weight: FontWeight.w500),
          ),
        ],
      ],
    );
  }

  Widget _buildRateRow(String label, String rate, bool active, CountryTheme theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: theme.getTextColor(context))),
            Text(
              active ? 'Used in calculation' : 'Not used',
              style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context)),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFFE4E8) : theme.getBgColor(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? const Color(0xFFC8102E) : theme.getBorderColor(context)),
          ),
          child: Text(
            rate,
            style: AppTextStyles.playfair(
              size: 13,
              weight: FontWeight.bold,
              color: active ? const Color(0xFFC8102E) : theme.getTextColor(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _resBox(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.dmSans(
              size: 8,
              color: Colors.white60,
              weight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.playfair(
              size: 13,
              weight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTrack(String label, String val, double pct, Color color) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: theme.getTextColor(context))),
            Text(val, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: theme.getBgColor(context),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _compareRow(String title, String subtitle, String value, Color valColor) {
    final theme = widget.theme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: theme.getTextColor(context))),
            Text(subtitle, style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context))),
          ],
        ),
        Text(
          value,
          style: AppTextStyles.playfair(size: 16, weight: FontWeight.bold, color: valColor),
        ),
      ],
    );
  }
}
