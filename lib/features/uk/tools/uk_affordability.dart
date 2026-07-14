// lib/features/uk/tools/uk_affordability.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/result_panel.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/uk_rates_provider.dart';
import '../../../shared/models/saved_calc.dart';
import 'dart:math' as math;

class UKAffordability extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;
  const UKAffordability({super.key, required this.theme, this.savedCalc});

  @override
  ConsumerState<UKAffordability> createState() => _UKAffordabilityState();
}

class _UKAffordabilityState extends ConsumerState<UKAffordability> {
  String _appType = 'solo'; // solo, joint

  final _sal1Controller = TextEditingController(text: '55000');
  final _sal2Controller = TextEditingController(text: '35000');
  final _otherIncController = TextEditingController(text: '0');
  final _debtController = TextEditingController(text: '200');
  final _livingController = TextEditingController(text: '1500');
  final _depositController = TextEditingController(text: '50000');
  final _rateController = TextEditingController(text: '4.75');

  bool _showResults = false;
  final Map<dynamic, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};
  final _resultsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _sal1Controller.text = (inputs['sal1'] ?? 55000.0).toStringAsFixed(0);
      final double s2 = inputs['sal2'] ?? 0.0;
      _sal2Controller.text = s2.toStringAsFixed(0);
      _otherIncController.text = (inputs['otherInc'] ?? 0.0).toStringAsFixed(0);
      _debtController.text = (inputs['debt'] ?? 200.0).toStringAsFixed(0);
      _livingController.text = (inputs['living'] ?? 1500.0).toStringAsFixed(0);
      _depositController.text = (inputs['deposit'] ?? 50000.0).toStringAsFixed(0);
      _rateController.text = (inputs['rate'] ?? 4.75).toString();
      _appType = s2 > 0.0 ? 'joint' : 'solo';
      _calculate();
    }
  }

  @override
  void dispose() {
    _sal1Controller.dispose();
    _sal2Controller.dispose();
    _otherIncController.dispose();
    _debtController.dispose();
    _livingController.dispose();
    _depositController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  double _val(TextEditingController c, double defaultVal) {
    if (_showResults && _calcSnapshot.containsKey(c)) {
      return _calcSnapshot[c]!;
    }
    return double.tryParse(c.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? defaultVal;
  }

  void _calculate() {
    final errors = <String, String>{};

    final sal1 = double.tryParse(_sal1Controller.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (sal1 <= 0) errors['sal1'] = 'Enter salary for Applicant 1';

    double sal2 = 0;
    if (_appType == 'joint') {
      sal2 = double.tryParse(_sal2Controller.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      if (sal2 <= 0) errors['sal2'] = 'Enter salary for Applicant 2';
    }

    final otherInc = double.tryParse(_otherIncController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (otherInc < 0) errors['otherInc'] = 'Enter valid other income';

    final debt = double.tryParse(_debtController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (debt < 0) errors['debt'] = 'Enter valid debt payments';

    final living = double.tryParse(_livingController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (living < 0) errors['living'] = 'Enter valid living costs';

    final deposit = double.tryParse(_depositController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (deposit < 0) errors['deposit'] = 'Enter valid deposit';

    final rate = double.tryParse(_rateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (rate <= 0 || rate > 25) errors['rate'] = 'Enter interest rate (0.1% - 25%)';

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) return;

    setState(() {
      _calcSnapshot[_sal1Controller] = sal1;
      _calcSnapshot[_sal2Controller] = sal2;
      _calcSnapshot[_otherIncController] = otherInc;
      _calcSnapshot[_debtController] = debt;
      _calcSnapshot[_livingController] = living;
      _calcSnapshot[_depositController] = deposit;
      _calcSnapshot[_rateController] = rate;
      _calcSnapshot['_appType'] = _appType;
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
      _sal1Controller.text = '55000';
      _sal2Controller.text = '35000';
      _otherIncController.text = '0';
      _debtController.text = '200';
      _livingController.text = '1500';
      _depositController.text = '50000';
      _rateController.text = '4.75';
      _appType = 'solo';
      _calcSnapshot.clear();
      _errors.clear();
      _showResults = false;
    });
  }

  double _pmt(double r, double n, double pv) {
    if (r == 0) return pv / n;
    return pv * (r * math.pow(1 + r, n)) / (math.pow(1 + r, n) - 1);
  }

  @override
  Widget build(BuildContext context) {
    final double sal1Val = _val(_sal1Controller, 55000);
    final String activeAppType = _showResults ? (_calcSnapshot['_appType'] ?? _appType) : _appType;
    final double sal2Val = activeAppType == 'joint' ? _val(_sal2Controller, 35000) : 0.0;
    final double otherIncVal = _val(_otherIncController, 0);
    final double debtVal = _val(_debtController, 200);
    final double livingVal = _val(_livingController, 1500);
    final double depositVal = _val(_depositController, 50000);
    final double rateVal = _val(_rateController, 4.75);

    final totalIncome = sal1Val + sal2Val + (otherIncVal * 0.6);
    final maxBorrow = totalIncome * 4.5;
    final maxProp = maxBorrow + depositVal;
    final mult = totalIncome > 0 ? (maxBorrow / totalIncome) : 0.0;
    final ltv = maxProp > 0 ? (maxBorrow / maxProp * 100) : 0.0;

    final rMo = rateVal / 100 / 12;
    final monthlyPmt = _pmt(rMo, 300, maxBorrow);

    final grossMo = totalIncome / 12;
    final taxMo = grossMo * 0.28;
    final netMo = grossMo - taxMo;
    final remaining = netMo - debtVal - livingVal - monthlyPmt;

    // Stress test calculations
    const stressRate = 8.0;
    final stressPmt = _pmt(stressRate / 100 / 12, 300, maxBorrow);
    final stressMax = netMo - debtVal - livingVal;
    final capacityPct = stressMax > 0 ? (stressPmt / stressMax * 100).clamp(0.0, 100.0) : 100.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = widget.theme.getCardColor(context);
    final textThemeColor = isDark ? Colors.white : const Color(0xFF0D0D2B);
    final borderCol = widget.theme.getBorderColor(context);

    // Live BoE rates
    final ukRates = ref.watch(ukRatesProvider).valueOrNull;
    final boeBase  = ukRates?.boeBase.value  ?? 4.25;
    final fixed2yr = ukRates?.fixed2yr.value ?? 4.75;
    final isLive   = ukRates?.isLive == true;

    final isDirty = _showResults && (
      (double.tryParse(_sal1Controller.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_sal1Controller] ?? 0.0) ||
      (_appType == 'joint' && (double.tryParse(_sal2Controller.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_sal2Controller] ?? 0.0)) ||
      (double.tryParse(_otherIncController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_otherIncController] ?? 0.0) ||
      (double.tryParse(_debtController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_debtController] ?? 0.0) ||
      (double.tryParse(_livingController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_livingController] ?? 0.0) ||
      (double.tryParse(_depositController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_depositController] ?? 0.0) ||
      (double.tryParse(_rateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_rateController] ?? 0.0) ||
      _appType != (_calcSnapshot['_appType'] ?? '')
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.theme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderCol),
          ),
          child: Row(
            children: [
              Expanded(child: _rateCell('4× Salary', 'Standard', 'Most lenders', textThemeColor)),
              _divider(),
              Expanded(child: _rateCell('4.5× Salary', 'Common', 'Many banks', textThemeColor)),
              _divider(),
              Expanded(child: _rateCell('5× Salary', 'Max', 'High earners', textThemeColor)),
              _divider(),
              Expanded(child: _rateCell('BoE Base', '${boeBase.toStringAsFixed(2)}%${isLive ? ' 🟢' : ''}', '2-Yr: ${fixed2yr.toStringAsFixed(2)}%', Colors.redAccent)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'INCOME DETAILS',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w700,
                color: widget.theme.getMutedColor(context),
                letterSpacing: 1.0,
              ),
            ),
            GestureDetector(
              onTap: _resetInputs,
              child: Text(
                'Reset',
                style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.bold,
                  color: widget.theme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Income Details Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'APPLICATION TYPE',
                style: AppTextStyles.dmSans(
                  size: 9,
                  weight: FontWeight.w700,
                  color: widget.theme.getMutedColor(context),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _tabButton(
                      label: '👤 Solo',
                      active: _appType == 'solo',
                      onTap: () => setState(() {
                        _appType = 'solo';
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _tabButton(
                      label: '👫 Joint',
                      active: _appType == 'joint',
                      onTap: () => setState(() {
                        _appType = 'joint';
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _inputField(label: 'Annual Salary (Applicant 1) (£)', controller: _sal1Controller, errorText: _errors['sal1']),
              if (_appType == 'joint') ...[
                const SizedBox(height: 12),
                _inputField(label: 'Annual Salary (Applicant 2) (£)', controller: _sal2Controller, errorText: _errors['sal2']),
              ],
              const SizedBox(height: 12),
              _inputField(label: 'Other Income (bonus, rental, etc.) (£)', controller: _otherIncController, errorText: _errors['otherInc']),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'COMMITMENTS & DEPOSIT',
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w700,
            color: widget.theme.getMutedColor(context),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),

        // Commitments Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            children: [
              _inputField(label: 'Monthly Debt Payments (£)', controller: _debtController, errorText: _errors['debt']),
              const SizedBox(height: 12),
              _inputField(label: 'Monthly Living Costs (£)', controller: _livingController, errorText: _errors['living']),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _inputField(label: 'Deposit Available (£)', controller: _depositController, errorText: _errors['deposit'])),
                  const SizedBox(width: 10),
                  Expanded(child: _inputField(label: 'Interest Rate (%)', controller: _rateController, errorText: _errors['rate'])),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _calculate,
                  child: Text(
                    'Calculate Affordability',
                    style: AppTextStyles.dmSans(size: 14, color: Colors.white, weight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

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
                      'Inputs have changed. Tap Calculate Affordability to refresh results.',
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
                // Result Hero
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D0D2B), Color(0xFF1A1A5E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MAXIMUM BORROWING',
                        style: AppTextStyles.dmSans(
                          size: 10,
                          weight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.5),
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            CurrencyFormatter.format(maxBorrow, symbol: '£').split('.').first,
                            style: AppTextStyles.dmSans(
                              size: 38,
                              weight: FontWeight.w800,
                              color: const Color(0xFFFFD700),
                            ).copyWith(fontFamily: 'Georgia'),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final calc = SavedCalc.create(
                                country: 'UK',
                                calcType: 'Affordability',
                                inputs: {
                                  'sal1': sal1Val,
                                  'sal2': sal2Val,
                                  'otherInc': otherIncVal,
                                  'debt': debtVal,
                                  'living': livingVal,
                                  'deposit': depositVal,
                                  'rate': rateVal,
                                },
                                results: {
                                  'Max Borrowing': maxBorrow,
                                  'Max Property': maxProp,
                                  'Monthly Payment': monthlyPmt,
                                  'Income Multiple': mult,
                                  'LTV Ratio': ltv,
                                },
                                label: '${CurrencyFormatter.compact(maxBorrow, symbol: '£')} max borrow · ${mult.toStringAsFixed(1)}x multiple',
                                currencyCode: 'GBP',
                              );
                              final messenger = ScaffoldMessenger.of(context);
                              await ref.read(savedProvider.notifier).save(calc);
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('✓ Affordability calculation saved'),
                                  backgroundColor: Color(0xFF0D9488),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.save, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text('Save', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Max property: ${CurrencyFormatter.format(maxProp, symbol: '£').split('.').first} with ${CurrencyFormatter.format(depositVal, symbol: '£').split('.').first} deposit',
                        style: AppTextStyles.dmSans(size: 11, color: Colors.white.withValues(alpha: 0.7)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Income Multiple: ${mult.toStringAsFixed(1)}x · LTV: ${ltv.toStringAsFixed(0)}%',
                          style: AppTextStyles.dmSans(
                            size: 11,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Metrics Grid
                ResultPanel(
                  primaryColor: widget.theme.primaryColor,
                  rows: [
                    ResultRow(label: 'Max Property', value: maxProp, currencyCode: 'GBP'),
                    ResultRow(label: 'Monthly Payment', value: monthlyPmt, currencyCode: 'GBP'),
                    ResultRow(label: 'Income Multiple', value: mult, isPercent: false, isHighlighted: true),
                    ResultRow(label: 'LTV Ratio', value: ltv / 100, isPercent: true),
                  ],
                ),
                const SizedBox(height: 16),

                // Gauge Chart Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Borrowing vs. Stress-Test Capacity',
                        style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textThemeColor),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: SizedBox(
                          width: 250,
                          height: 130,
                          child: CustomPaint(
                            painter: AffordabilityGaugePainter(
                              capacityPct: capacityPct,
                              isDark: isDark,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '${capacityPct.toInt()}%',
                                    style: AppTextStyles.dmSans(size: 24, weight: FontWeight.w800, color: textThemeColor).copyWith(fontFamily: 'Georgia'),
                                  ),
                                  Text(
                                    'of max capacity used',
                                    style: AppTextStyles.dmSans(size: 9.5, color: widget.theme.getMutedColor(context)),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Low', style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF059669), weight: FontWeight.w800)),
                          Text('Medium', style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFB45309), weight: FontWeight.w800)),
                          Text('High', style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFC8102E), weight: FontWeight.w800)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Lender Borrowing Bands
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lender Borrowing Bands',
                        style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textThemeColor),
                      ),
                      const SizedBox(height: 12),
                      _bandRow(
                        'Conservative (4×)',
                        totalIncome * 4,
                        isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.25) : const Color(0xFFFEF2F2),
                        isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E),
                        'Halifax, HSBC (standard)',
                      ),
                      const SizedBox(height: 8),
                      _bandRow(
                        'Standard (4.5×)',
                        totalIncome * 4.5,
                        isDark ? const Color(0xFF1E1B4B).withValues(alpha: 0.35) : const Color(0xFFEEF2FF),
                        isDark ? const Color(0xFFC7D2FE) : const Color(0xFF1A1A6B),
                        'Nationwide, Barclays',
                      ),
                      const SizedBox(height: 8),
                      _bandRow(
                        'Maximum (5×)',
                        totalIncome * 5,
                        isDark ? const Color(0xFF064E3B).withValues(alpha: 0.25) : const Color(0xFFF0FDF4),
                        isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669),
                        'Specialist / high earner',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Monthly Budget Check
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: isDark ? [const Color(0xFF1E1B4B), const Color(0xFF121230)] : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF4338CA).withValues(alpha: 0.5) : const Color(0xFFA5B4FC)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💰 Monthly Budget Check',
                        style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1E1B4B)),
                      ),
                      const SizedBox(height: 12),
                      _budgetRow('Gross Monthly Income', grossMo, false),
                      _budgetRow('Tax & NI (est. 28%)', taxMo, true),
                      _budgetRow('Net Monthly Income', netMo, false, isBold: true),
                      _budgetRow('Debt Payments', debtVal, true),
                      _budgetRow('Living Costs', livingVal, true),
                      _budgetRow('Mortgage Payment', monthlyPmt, true),
                      Divider(color: isDark ? const Color(0xFF4338CA).withValues(alpha: 0.4) : const Color(0xFFA5B4FC), height: 16),
                      _budgetRow('Remaining', remaining.abs(), remaining < 0, isBold: true, labelSuffix: remaining >= 0 ? '' : ' (Over budget)'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _tabButton({required String label, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF0D0D2B)
              : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F8)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? const Color(0xFF0D0D2B) : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 12,
            weight: FontWeight.w800,
            color: active ? const Color(0xFFFFD700) : widget.theme.getMutedColor(context),
          ),
        ),
      ),
    );
  }

  Widget _bandRow(String label, double val, Color bg, Color textCol, String note) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w700, color: textCol)),
              const SizedBox(height: 2),
              Text(note, style: AppTextStyles.dmSans(size: 9.5, color: textCol.withValues(alpha: 0.7))),
            ],
          ),
          Text(
            CurrencyFormatter.format(val, symbol: '£').split('.').first,
            style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: textCol),
          ),
        ],
      ),
    );
  }

  Widget _budgetRow(String label, double val, bool isNegative, {bool isBold = false, String labelSuffix = ''}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label + labelSuffix,
            style: AppTextStyles.dmSans(
              size: 11,
              weight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: isDark ? const Color(0xFFC7D2FE) : const Color(0xFF4338CA),
            ),
          ),
          Text(
            (isNegative ? '-' : '') + CurrencyFormatter.format(val, symbol: '£').split('.').first,
            style: AppTextStyles.dmSans(
              size: 11,
              weight: isBold ? FontWeight.w800 : FontWeight.w700,
              color: isNegative
                  ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E))
                  : (isDark ? Colors.white : const Color(0xFF0D0D2B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rateCell(String label, String value, String note, Color valueColor) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(size: 8, color: widget.theme.getMutedColor(context), weight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: valueColor),
        ),
        Text(
          note,
          style: AppTextStyles.dmSans(size: 8, color: widget.theme.getMutedColor(context)),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.grey.withValues(alpha: 0.2),
    );
  }

  Widget _inputField({required String label, required TextEditingController controller, String? errorText}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8.5,
            weight: FontWeight.w700,
            color: widget.theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) {
            setState(() {});
          },
          style: AppTextStyles.dmSans(
            size: 13,
            weight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0D0D2B),
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F8),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: errorText != null ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none,
            ),
            enabledBorder: errorText != null ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ) : null,
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(errorText, style: AppTextStyles.dmSans(size: 10, color: Colors.red, weight: FontWeight.w500)),
        ],
      ],
    );
  }
}

class AffordabilityGaugePainter extends CustomPainter {
  final double capacityPct;
  final bool isDark;

  AffordabilityGaugePainter({
    required this.capacityPct,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 12;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    // Background semi-circle
    canvas.drawArc(rect, math.pi, math.pi, false, bgPaint);

    const gradient = LinearGradient(
      colors: [Color(0xFF059669), Color(0xFFB45309), Color(0xFFC8102E)],
    );

    final gradientPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    // We draw the arc based on capacityPct
    final sweepAngle = math.pi * (capacityPct / 100);
    if (sweepAngle > 0) {
      canvas.drawArc(rect, math.pi, sweepAngle, false, gradientPaint);
    }
  }

  @override
  bool shouldRepaint(covariant AffordabilityGaugePainter oldDelegate) {
    return oldDelegate.capacityPct != capacityPct || oldDelegate.isDark != isDark;
  }
}
