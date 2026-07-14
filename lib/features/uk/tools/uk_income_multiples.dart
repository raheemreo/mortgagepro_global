// lib/features/uk/tools/uk_income_multiples.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/uk_rates_provider.dart';
import '../../../shared/models/saved_calc.dart';


class UKIncomeMultiples extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;
  const UKIncomeMultiples({super.key, required this.theme, this.savedCalc});

  @override
  ConsumerState<UKIncomeMultiples> createState() => _UKIncomeMultiplesState();
}

class _UKIncomeMultiplesState extends ConsumerState<UKIncomeMultiples> {
  String _appType = 'solo'; // solo, joint

  final _sal1Controller = TextEditingController(text: '60000');
  final _sal2Controller = TextEditingController(text: '40000');
  final _bonusController = TextEditingController(text: '10000');
  final _targetPriceController = TextEditingController(text: '350000');
  final _depController = TextEditingController(text: '50000');

  bool _hasCalculated = false;
  final Map<dynamic, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};
  final _resultsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _sal1Controller.text = (inputs['sal1'] ?? 60000.0).toStringAsFixed(0);
      final double s2 = inputs['sal2'] ?? 0.0;
      _sal2Controller.text = s2.toStringAsFixed(0);
      _bonusController.text = (inputs['bonus'] ?? 10000.0).toStringAsFixed(0);
      _targetPriceController.text = (inputs['targetPrice'] ?? 350000.0).toStringAsFixed(0);
      _depController.text = (inputs['dep'] ?? 50000.0).toStringAsFixed(0);
      _appType = s2 > 0.0 ? 'joint' : 'solo';
      _calculate();
    }
  }

  @override
  void dispose() {
    _sal1Controller.dispose();
    _sal2Controller.dispose();
    _bonusController.dispose();
    _targetPriceController.dispose();
    _depController.dispose();
    super.dispose();
  }

  double _val(TextEditingController c, double defaultVal) {
    if (_hasCalculated && _calcSnapshot.containsKey(c)) {
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

    final bonus = double.tryParse(_bonusController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (bonus < 0) errors['bonus'] = 'Enter valid bonus';

    final targetPrice = double.tryParse(_targetPriceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (targetPrice <= 0) errors['targetPrice'] = 'Enter valid property price';

    final dep = double.tryParse(_depController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (dep < 0) errors['dep'] = 'Enter valid deposit';

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) return;

    setState(() {
      _calcSnapshot[_sal1Controller] = sal1;
      _calcSnapshot[_sal2Controller] = sal2;
      _calcSnapshot[_bonusController] = bonus;
      _calcSnapshot[_targetPriceController] = targetPrice;
      _calcSnapshot[_depController] = dep;
      _calcSnapshot['_appType'] = _appType;
      _hasCalculated = true;
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
      _sal1Controller.text = '60000';
      _sal2Controller.text = '40000';
      _bonusController.text = '10000';
      _targetPriceController.text = '350000';
      _depController.text = '50000';
      _appType = 'solo';
      _calcSnapshot.clear();
      _errors.clear();
      _hasCalculated = false;
    });
  }

  final List<Map<String, dynamic>> lenders = const [
    {
      'name': 'Halifax',
      'multiple': 4.75,
      'note': 'Standard applicants',
      'badge': 'badge-std',
      'type': 'std'
    },
    {
      'name': 'Nationwide',
      'multiple': 4.5,
      'note': 'Standard',
      'badge': 'badge-std',
      'type': 'std'
    },
    {
      'name': 'Barclays',
      'multiple': 4.75,
      'note': 'Mortgage Plus',
      'badge': 'badge-std',
      'type': 'std'
    },
    {
      'name': 'NatWest',
      'multiple': 4.5,
      'note': 'Standard',
      'badge': 'badge-std',
      'type': 'std'
    },
    {
      'name': 'HSBC',
      'multiple': 4.75,
      'note': 'Standard',
      'badge': 'badge-std',
      'type': 'std'
    },
    {
      'name': 'Santander',
      'multiple': 4.45,
      'note': 'Standard',
      'badge': 'badge-std',
      'type': 'std'
    },
    {
      'name': 'Lloyds',
      'multiple': 5.0,
      'note': '>£50k income',
      'badge': 'badge-cond',
      'type': 'cond'
    },
    {
      'name': 'Virgin Money',
      'multiple': 5.0,
      'note': 'Salary conditions',
      'badge': 'badge-cond',
      'type': 'cond'
    },
    {
      'name': 'Kensington',
      'multiple': 5.5,
      'note': 'Specialist lender',
      'badge': 'badge-top',
      'type': 'top'
    },
    {
      'name': 'Accord',
      'multiple': 5.5,
      'note': 'Broker only',
      'badge': 'badge-top',
      'type': 'top'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final double sal1Val = _val(_sal1Controller, 60000);
    final String activeAppType = _hasCalculated ? (_calcSnapshot['_appType'] ?? _appType) : _appType;
    final double sal2Val = activeAppType == 'joint' ? _val(_sal2Controller, 40000) : 0.0;
    final double bonusVal = _val(_bonusController, 10000);
    final double targetPriceVal = _val(_targetPriceController, 350000);
    final double depVal = _val(_depController, 50000);

    final totalIncome = sal1Val + sal2Val + (bonusVal * 0.5);
    final reqBorrow = targetPriceVal - depVal;
    final stdBorrow = totalIncome * 4.5;
    final shortfall = reqBorrow - stdBorrow;
    final multUsed = totalIncome > 0 ? (reqBorrow / totalIncome) : 0.0;
    final maxBorrow = totalIncome * 5.5;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF141C33) : Colors.white;
    final textThemeColor = isDark ? Colors.white : const Color(0xFF0D0D2B);
    final borderCol = isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0x161A1A5E);

    // Live BoE base rate for context
    final ukRates = ref.watch(ukRatesProvider).valueOrNull;
    final boeBase  = ukRates?.boeBase.value ?? 4.25;
    final isLive   = ukRates?.isLive == true;

    final isDirty = _hasCalculated && (
      (double.tryParse(_sal1Controller.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_sal1Controller] ?? 0.0) ||
      (_appType == 'joint' && (double.tryParse(_sal2Controller.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_sal2Controller] ?? 0.0)) ||
      (double.tryParse(_bonusController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_bonusController] ?? 0.0) ||
      (double.tryParse(_targetPriceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_targetPriceController] ?? 0.0) ||
      (double.tryParse(_depController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_depController] ?? 0.0) ||
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
              Expanded(child: _rateCell('Standard', '4–4.5×', 'Most lenders', textThemeColor)),
              _divider(),
              Expanded(child: _rateCell('Higher LTI', '4.5–5×', 'FCA limit', isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309))),
              _divider(),
              Expanded(child: _rateCell('Maximum', '5–5.5×', 'Specialist', isDark ? const Color(0xFF34D399) : const Color(0xFF059669))),
              _divider(),
              Expanded(child: _rateCell('BoE Base', '${boeBase.toStringAsFixed(2)}%${isLive ? ' 🟢' : ''}', 'Mortgage ref', textThemeColor)),
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
                color: widget.theme.mutedColor,
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

        // Income Card
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
                    size: 8.5,
                    weight: FontWeight.w700,
                    color: widget.theme.mutedColor,
                    letterSpacing: 0.5),
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
              _inputField(label: 'Bonus / Other Income (50% counted) (£)', controller: _bonusController, errorText: _errors['bonus']),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Text(
          'PROPERTY & DEPOSIT',
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w700,
            color: widget.theme.mutedColor,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),

        // Property Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            children: [
              _inputField(label: 'Target Property Price (£)', controller: _targetPriceController, errorText: _errors['targetPrice']),
              const SizedBox(height: 12),
              _inputField(label: 'Deposit Available (£)', controller: _depController, errorText: _errors['dep']),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC8102E),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                  onPressed: _calculate,
                  child: Text(
                    '📋 Check Income Multiples',
                    style: AppTextStyles.dmSans(size: 14, color: Colors.white, weight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_hasCalculated) ...[
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
                      'Inputs have changed. Tap Check Income Multiples to refresh results.',
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
                // Result Hero Card
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
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STANDARD BORROWING (4.5×)',
                        style: AppTextStyles.dmSans(
                            size: 10,
                            weight: FontWeight.w700,
                            color: Colors.white60,
                            letterSpacing: 0.7),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            CurrencyFormatter.format(stdBorrow, symbol: '£')
                                .split('.')
                                .first,
                            style: AppTextStyles.dmSans(
                                    size: 34,
                                    weight: FontWeight.w800,
                                    color: Colors.white)
                                .copyWith(fontFamily: 'Georgia'),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final calc = SavedCalc.create(
                                country: 'UK',
                                calcType: 'Income Multiples',
                                inputs: {
                                  'sal1': sal1Val,
                                  'sal2': sal2Val,
                                  'bonus': bonusVal,
                                  'targetPrice': targetPriceVal,
                                  'dep': depVal,
                                },
                                results: {
                                  'Standard Borrowing': stdBorrow,
                                  'Required Borrowing': reqBorrow,
                                  'Shortfall': shortfall,
                                  'Multiple Used': multUsed,
                                },
                                label:
                                    '${CurrencyFormatter.compact(stdBorrow, symbol: '£')} std borrow · ${multUsed.toStringAsFixed(1)}x multiple',
                                currencyCode: 'GBP',
                              );
                              final messenger = ScaffoldMessenger.of(context);
                              await ref.read(savedProvider.notifier).save(calc);
                              messenger.showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('✓ Income Multiple calculation saved'),
                                  backgroundColor: Color(0xFF0D9488),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.save,
                                      color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text('Save',
                                      style: AppTextStyles.dmSans(
                                          size: 11,
                                          weight: FontWeight.w800,
                                          color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Combined income: ${CurrencyFormatter.format(totalIncome, symbol: '£').split('.').first} p.a.',
                        style: AppTextStyles.dmSans(size: 11, color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Column(
                                children: [
                                  Text('Required',
                                      style: AppTextStyles.dmSans(
                                          size: 9, color: Colors.white54)),
                                  const SizedBox(height: 2),
                                  Text(
                                    CurrencyFormatter.format(reqBorrow, symbol: '£')
                                        .split('.')
                                        .first,
                                    style: AppTextStyles.dmSans(
                                        size: 13,
                                        weight: FontWeight.w800,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Column(
                                children: [
                                  Text('Shortfall',
                                      style: AppTextStyles.dmSans(
                                          size: 9, color: Colors.white54)),
                                  const SizedBox(height: 2),
                                  Text(
                                    shortfall > 0
                                        ? '-${CurrencyFormatter.format(shortfall, symbol: '£').split('.').first}'
                                        : '+${CurrencyFormatter.format(shortfall.abs(), symbol: '£').split('.').first}',
                                    style: AppTextStyles.dmSans(
                                        size: 13,
                                        weight: FontWeight.w800,
                                        color: shortfall > 0
                                            ? Colors.redAccent
                                            : const Color(0xFF90EE90)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Column(
                                children: [
                                  Text('Multiple Req',
                                      style: AppTextStyles.dmSans(
                                          size: 9, color: Colors.white54)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${multUsed.toStringAsFixed(2)}x',
                                    style: AppTextStyles.dmSans(
                                        size: 13,
                                        weight: FontWeight.w800,
                                        color: multUsed > 4.75
                                            ? Colors.redAccent
                                            : const Color(0xFFFFD700)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // LTV alert / warning
                if (shortfall > 0 && reqBorrow > maxBorrow)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('⚠️', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shortfall Exceeds Maximum Borrowing',
                                style: AppTextStyles.dmSans(
                                    size: 13,
                                    weight: FontWeight.w800,
                                    color: Colors.redAccent),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Your required borrowing of ${CurrencyFormatter.format(reqBorrow, symbol: '£').split('.').first} exceeds the absolute maximum 5.5× multiple of ${CurrencyFormatter.format(maxBorrow, symbol: '£').split('.').first}. You will need a larger deposit of at least ${CurrencyFormatter.format(reqBorrow - maxBorrow + depVal, symbol: '£').split('.').first} to buy this property.',
                                style: AppTextStyles.dmSans(
                                    size: 10.5,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                    height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else if (shortfall > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      border:
                          Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ℹ️', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shortfall Detected (Standard 4.5×)',
                                style: AppTextStyles.dmSans(
                                    size: 13,
                                    weight: FontWeight.w800,
                                    color: isDark
                                        ? const Color(0xFFFBBF24)
                                        : const Color(0xFFB45309)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'A standard 4.5× mortgage results in a shortfall of ${CurrencyFormatter.format(shortfall, symbol: '£').split('.').first}. However, your required multiple is ${multUsed.toStringAsFixed(2)}x, which is within the 5.5× maximum. You may qualify for high-LTI or specialist lending schemes.',
                                style: AppTextStyles.dmSans(
                                    size: 10.5,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                    height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.15),
                      border: Border.all(
                          color: const Color(0xFF059669).withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('✅', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Standard Borrowing Confirmed',
                                style: AppTextStyles.dmSans(
                                    size: 13,
                                    weight: FontWeight.w800,
                                    color: const Color(0xFF059669)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Great news! Your required borrowing is within the standard 4.5× multiple. Most high-street banks in the UK will support this application.',
                                style: AppTextStyles.dmSans(
                                    size: 10.5,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                    height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Lenders List Card
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
                        'UK Lenders & Multiples Matcher',
                        style: AppTextStyles.dmSans(
                            size: 12,
                            weight: FontWeight.w800,
                            color: textThemeColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Matches your required ${multUsed.toStringAsFixed(2)}x multiple against typical UK lender caps',
                        style: AppTextStyles.dmSans(
                            size: 9.5, color: widget.theme.mutedColor),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('LENDER',
                              style: AppTextStyles.dmSans(
                                  size: 8.5,
                                  weight: FontWeight.w800,
                                  color: widget.theme.mutedColor)),
                          Text('STATUS & CAP',
                              style: AppTextStyles.dmSans(
                                  size: 8.5,
                                  weight: FontWeight.w800,
                                  color: widget.theme.mutedColor)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...lenders.map((l) {
                        final double multCap = l['multiple'] as double;
                        final double amt = totalIncome * multCap;
                        final bool match = multUsed <= multCap;

                        final statusColor = match
                            ? (isDark
                                ? const Color(0xFF34D399)
                                : const Color(0xFF065F46))
                            : (isDark
                                ? const Color(0xFFFCA5A5)
                                : const Color(0xFF991B1B));
                        final statusBg = match
                            ? (isDark
                                ? const Color(0xFF065F46)
                                : const Color(0xFFD1FAE5))
                            : (isDark
                                ? const Color(0xFF991B1B)
                                : const Color(0xFFFEE2E2));

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.02)
                                : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: isDark ? Colors.white12 : Colors.black12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l['name'] as String,
                                    style: AppTextStyles.dmSans(
                                        size: 11.5,
                                        weight: FontWeight.w800,
                                        color: textThemeColor),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${l['note']} (${multCap.toStringAsFixed(1)}x)',
                                    style: AppTextStyles.dmSans(
                                        size: 9, color: widget.theme.mutedColor),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Text(
                                      match ? 'Match' : 'Shortfall',
                                      style: AppTextStyles.dmSans(
                                          size: 9,
                                          weight: FontWeight.w800,
                                          color: statusColor),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    width: 70,
                                    child: Text(
                                      CurrencyFormatter.format(amt, symbol: '£')
                                          .split('.')
                                          .first,
                                      style: AppTextStyles.dmSans(
                                          size: 11,
                                          weight: FontWeight.w800,
                                          color: textThemeColor),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
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

  Widget _tabButton(
      {required String label,
      required bool active,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF0D0D2B)
              : (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF5F5F8)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? const Color(0xFF0D0D2B)
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 12,
            weight: FontWeight.w800,
            color: active ? const Color(0xFFFFD700) : widget.theme.mutedColor,
          ),
        ),
      ),
    );
  }

  Widget _rateCell(String label, String value, String note, Color valueColor) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
              size: 8, color: widget.theme.mutedColor, weight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.dmSans(
              size: 13, weight: FontWeight.w800, color: valueColor),
        ),
        Text(
          note,
          style: AppTextStyles.dmSans(size: 8, color: widget.theme.mutedColor),
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

  Widget _inputField(
      {required String label, required TextEditingController controller, String? errorText}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8.5,
            weight: FontWeight.w700,
            color: widget.theme.mutedColor,
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF5F5F8),
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
