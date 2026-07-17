// ignore_for_file: no_leading_underscores_for_local_identifiers, non_constant_identifier_names, unused_local_variable, unnecessary_this, prefer_final_fields
// lib/features/usa/tools/usa_refinance_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../../widgets/ads/native_ad_widget.dart';
import '../../../shared/widgets/live_rate_banner.dart';
import '../../../providers/usa_rates_provider.dart';

class USARefinanceCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const USARefinanceCalc({super.key, this.theme = CountryThemes.usa});

  @override
  ConsumerState<USARefinanceCalc> createState() => _USARefinanceCalcState();
}

class _USARefinanceCalcState extends ConsumerState<USARefinanceCalc> {
  final _resultsKey = GlobalKey();
  Map<String, String?> _errors = {};
  final Map<dynamic, dynamic> _calcSnapshot = {};
  // Input Controllers
  final _curBalanceController = TextEditingController(text: '320000');
  final _curRateController = TextEditingController(text: '7.50');
  final _curTermController = TextEditingController(text: '25');
  final _curPaymentController = TextEditingController(text: '2237');

  final _newRateController = TextEditingController(text: '6.82');
  final _closingCostsController = TextEditingController(text: '6400');

  int _selectedTerm = 20;
  bool _rollClosing = false;
  bool _showResults = false;
  bool _isCalcDirty = true;

  @override
  void initState() {
    super.initState();
    _curBalanceController.addListener(() => setState(() {}));
    _curRateController.addListener(() => setState(() {}));
    _curTermController.addListener(() => setState(() {}));
    _curPaymentController.addListener(() => setState(() {}));
    _newRateController.addListener(() => setState(() {}));
    _closingCostsController.addListener(() => setState(() {}));

    _curBalanceController.addListener(_markDirty);
    _curRateController.addListener(_markDirty);
    _curTermController.addListener(_markDirty);
    _curPaymentController.addListener(_markDirty);
    _newRateController.addListener(_markDirty);
    _closingCostsController.addListener(_markDirty);
  }

  @override
  void dispose() {
    _curBalanceController.removeListener(_markDirty);
    _curRateController.removeListener(_markDirty);
    _curTermController.removeListener(_markDirty);
    _curPaymentController.removeListener(_markDirty);
    _newRateController.removeListener(_markDirty);
    _closingCostsController.removeListener(_markDirty);

    _curBalanceController.dispose();
    _curRateController.dispose();
    _curTermController.dispose();
    _curPaymentController.dispose();
    _newRateController.dispose();
    _closingCostsController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isCalcDirty) {
      setState(() {
        _isCalcDirty = true;
      });
    }
  }

  double _val(TextEditingController c) {
    if (_showResults && _calcSnapshot.containsKey(c)) {
      return _calcSnapshot[c]!;
    }
    return double.tryParse(c.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
  }

  double _monthlyPayment(double principal, double annualRate, int months) {
    final r = annualRate / 100 / 12;
    if (r == 0) return principal / months;
    return principal * r * pow(1 + r, months) / (pow(1 + r, months) - 1);
  }

  double _totalInterest(double principal, double annualRate, int months) {
    return _monthlyPayment(principal, annualRate, months) * months - principal;
  }

  void _resetInputs() {
    setState(() {
      _curBalanceController.clear();
      _curRateController.clear();
      _curTermController.clear();
      _curPaymentController.clear();
      _newRateController.clear();
      _closingCostsController.clear();
      _calcSnapshot.clear();
      _errors.clear();
      _showResults = false;
      _curBalanceController.text = '320000';
      _curRateController.text = '7.50';
      _curTermController.text = '25';
      _curPaymentController.text = '2237';
      _newRateController.text = '6.82';
      _closingCostsController.text = '6400';
      _selectedTerm = 20;
      _rollClosing = false;
      _showResults = false;
      _isCalcDirty = true;
    });
  }

  void _loadSavedCalculation(SavedCalc calc) {
    setState(() {
      _curBalanceController.text = (calc.inputs['CurBalance'] ?? 320000.0).toStringAsFixed(0);
      _curRateController.text = (calc.inputs['CurRate'] ?? 7.50).toStringAsFixed(2);
      _curTermController.text = (calc.inputs['CurTerm'] ?? 25.0).toStringAsFixed(0);
      _curPaymentController.text = (calc.inputs['CurPayment'] ?? 2237.0).toStringAsFixed(0);
      _newRateController.text = (calc.inputs['NewRate'] ?? 6.82).toStringAsFixed(2);
      _closingCostsController.text = (calc.inputs['ClosingCosts'] ?? 6400.0).toStringAsFixed(0);
      _selectedTerm = (calc.inputs['NewTerm'] ?? 20.0).toInt();
      _rollClosing = (calc.inputs['RollClosing'] ?? 0.0) == 1.0;
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
    final curBal = _val(_curBalanceController);
    final curRate = _val(_curRateController);
    final curTerm = _val(_curTermController).toInt();
    final curPmt = double.tryParse(_curPaymentController.text) ?? _monthlyPayment(curBal, curRate, curTerm * 12);
    final newRate = _val(_newRateController);
    final closing = _val(_closingCostsController);
    final calcSelectedTerm = _showResults ? (_calcSnapshot['_selectedTerm'] ?? _selectedTerm) : _selectedTerm;
    final calcRollClosing = _showResults ? (_calcSnapshot['_rollClosing'] ?? _rollClosing) : _rollClosing;
    final newTermMo = calcSelectedTerm * 12;

    final newPrincipal = calcRollClosing ? curBal + closing : curBal;
    final newPmt = _monthlyPayment(newPrincipal, newRate, newTermMo);
    final monthlySave = curPmt - newPmt;

    final breakEvenMonths = monthlySave > 0 ? (closing / monthlySave).ceil() : -1;

    final curTotalInt = _totalInterest(curBal, curRate, curTerm * 12);
    final newTotalInt = _totalInterest(newPrincipal, newRate, newTermMo);
    final totalSaved = (curTotalInt - newTotalInt) + (calcRollClosing ? 0.0 : -closing);

    final labelCtrl = TextEditingController(text: 'Refinance Analysis');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_refinance_calc/save'),
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
              'Saving: Monthly Save ${CurrencyFormatter.compact(monthlySave, symbol: '\$')} · Lifetime: ${CurrencyFormatter.compact(totalSaved, symbol: '\$')} · Break-even: $breakEvenMonths mo',
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
                hintText: 'Label (e.g. My Refinance)',
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
          : 'Refinance Analysis';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'Refinance Analysis',
        inputs: {
          'CurBalance': curBal,
          'CurRate': curRate,
          'CurTerm': curTerm.toDouble(),
          'CurPayment': curPmt,
          'NewRate': newRate,
          'ClosingCosts': closing,
          'NewTerm': calcSelectedTerm.toDouble(),
          'RollClosing': calcRollClosing ? 1.0 : 0.0,
        },
        results: {
          'NewPayment': newPmt,
          'MonthlySavings': monthlySave,
          'TotalSavings': totalSaved,
          'BreakEvenMonths': breakEvenMonths.toDouble(),
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

    void _calculate() {
    final errors = <String, String>{};
    final val_curBalance = double.tryParse(_curBalanceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (val_curBalance <= 0) errors['curBalance'] = 'Please enter a valid amount';
    final val_curRate = double.tryParse(_curRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (val_curRate <= 0) errors['curRate'] = 'Please enter a valid amount';
    final val_curTerm = double.tryParse(_curTermController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final val_curPayment = double.tryParse(_curPaymentController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final val_newRate = double.tryParse(_newRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (val_newRate <= 0) errors['newRate'] = 'Please enter a valid amount';
    final val_closingCosts = double.tryParse(_closingCostsController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) {
      return;
    }

    setState(() {
      _calcSnapshot[_curBalanceController] = val_curBalance;
      _calcSnapshot[_curRateController] = val_curRate;
      _calcSnapshot[_curTermController] = val_curTerm;
      _calcSnapshot[_curPaymentController] = val_curPayment;
      _calcSnapshot[_newRateController] = val_newRate;
      _calcSnapshot[_closingCostsController] = val_closingCosts;
      _calcSnapshot['_selectedTerm'] = _selectedTerm;
      _calcSnapshot['_rollClosing'] = _rollClosing;
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

  @override
  Widget build(BuildContext context) {
    final calcSelectedTerm = _showResults ? (_calcSnapshot['_selectedTerm'] ?? _selectedTerm) : _selectedTerm;
    final calcRollClosing = _showResults ? (_calcSnapshot['_rollClosing'] ?? _rollClosing) : _rollClosing;

    final isDirty = _showResults && (
      _selectedTerm != _calcSnapshot['_selectedTerm'] ||
      _rollClosing != _calcSnapshot['_rollClosing'] ||
      double.tryParse(_curBalanceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_curBalanceController] ?? 0.0) ||
      double.tryParse(_curRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_curRateController] ?? 0.0) ||
      double.tryParse(_curTermController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_curTermController] ?? 0.0) ||
      double.tryParse(_curPaymentController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_curPaymentController] ?? 0.0) ||
      double.tryParse(_newRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_newRateController] ?? 0.0) ||
      double.tryParse(_closingCostsController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_closingCostsController] ?? 0.0)
    );

    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Inputs
    final curBal = _val(_curBalanceController);
    final curRate = _val(_curRateController);
    final curTerm = _val(_curTermController).toInt();
    final curPmt = double.tryParse(_curPaymentController.text) ?? _monthlyPayment(curBal, curRate, curTerm * 12);
    final newRate = _val(_newRateController);
    final closing = _val(_closingCostsController);
    final int newTermMo = (calcSelectedTerm * 12).toInt();

    // Calculations
    final newPrincipal = calcRollClosing ? curBal + closing : curBal;
    final newPmt = _monthlyPayment(newPrincipal, newRate, newTermMo);
    final monthlySave = curPmt - newPmt;
    final breakEvenMonths = monthlySave > 0 ? (closing / monthlySave).ceil() : -1;

    final curTotalInt = _totalInterest(curBal, curRate, curTerm * 12);
    final newTotalInt = _totalInterest(newPrincipal, newRate, newTermMo);
    final totalSaved = (curTotalInt - newTotalInt) + (calcRollClosing ? 0.0 : -closing);
    final rateDiff = curRate - newRate;

    // Amortization snapshot
    final double r = newRate / 100 / 12;
    double bal = newPrincipal;
    final yearInterest = <double>[];
    final yearPrincipal = <double>[];
    for (int y = 1; y <= calcSelectedTerm; y++) {
      double yInt = 0.0;
      double yPrin = 0.0;
      for (int m = 0; m < 12; m++) {
        final intPart = bal * r;
        final prinPart = min(newPmt - intPart, bal);
        yInt += intPart;
        yPrin += prinPart;
        bal = max(0.0, bal - prinPart);
      }
      yearInterest.add(yInt);
      yearPrincipal.add(yPrin);
    }
    final maxVal = (yearPrincipal.isNotEmpty && yearInterest.isNotEmpty)
        ? max(yearPrincipal.reduce(max), yearInterest.reduce(max))
        : 1.0;

    final now = DateTime.now();
    final curPayoffDate = DateTime(now.year, now.month + curTerm * 12);
    final newPayoffDate = DateTime(now.year, now.month + newTermMo);

    // Watch saved refinance calculations
    final savedCalcs = ref.watch(savedProvider).where((c) => c.country == 'USA' && c.calcType == 'Refinance Analysis').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip — Live FRED data
        DarkRateStripBanner(items: [
          RateStripItem(label: '30-Yr Fixed', provider: fredMortgage30Provider, fallback: 6.82),
          RateStripItem(label: '15-Yr Fixed', provider: fredMortgage15Provider, fallback: 6.11),
          RateStripItem(label: '5/1 ARM', provider: fredSofrProvider, fallback: 5.33),
          RateStripItem(label: 'Fed Funds', provider: fredFedFundsProvider, fallback: 5.33, isGold: true),
        ]),
        const SizedBox(height: 20),

        // Section 1 header
        _buildSectionHeader('Current Loan Details', onReset: _resetInputs),
        const SizedBox(height: 8),

        // Current Loan Card
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07), blurRadius: 14, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🏠 ', style: TextStyle(fontSize: 18)),
                  Text(
                    'Your Existing Mortgage',
                    style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: theme.getTextColor(context)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInputField('Current Loan Balance', _curBalanceController, 'Remaining principal', errorText: _errors['curBalance']),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField('Current Rate', _curRateController, '', suffix: '%', errorText: _errors['curRate']),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputField('Remaining Term', _curTermController, '', suffix: 'yrs', errorText: _errors['curTerm']),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildInputField('Monthly Payment (P&I)', _curPaymentController, 'P&I payment', errorText: _errors['curPayment']),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _buildSectionHeader('New Loan Terms', onReset: null),
        const SizedBox(height: 8),

        // New Loan Card
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07), blurRadius: 14, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🔄 ', style: TextStyle(fontSize: 18)),
                  Text(
                    'Refinance Into',
                    style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: theme.getTextColor(context)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInputField('New Interest Rate', _newRateController, 'Today\'s avg: 6.82%', suffix: '%', errorText: _errors['newRate']),
              const SizedBox(height: 12),

              // Term selectors
              _buildSelectorRow<int>(
                label: 'New Loan Term',
                value: _selectedTerm,
                items: [10, 15, 20, 25, 30],
                labelBuilder: (v) => '$v yr',
                onChanged: (v) => setState(() {
                  this._selectedTerm = v;
                  _isCalcDirty = true;
                }),
              ),
              const SizedBox(height: 12),

              _buildInputField('Closing Costs', _closingCostsController, 'Typical: 2–3% of balance', errorText: _errors['closingCosts']),
              const SizedBox(height: 12),

              // Roll costs segment
              Text(
                'ROLL CLOSING COSTS INTO LOAN?',
                style: AppTextStyles.dmSans(
                  size: 9.5,
                  weight: FontWeight.w700,
                  color: theme.getMutedColor(context),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildSegButton('Pay Upfront', !_rollClosing, () => setState(() {
                      _rollClosing = false;
                      _isCalcDirty = true;
                    })),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSegButton('Roll Into Loan', _rollClosing, () => setState(() {
                      _rollClosing = true;
                      _isCalcDirty = true;
                    })),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              GestureDetector(
          onTap: _calculate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)]),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0B1D3A).withValues(alpha: _isCalcDirty ? 0.45 : 0.25),
                        blurRadius: _isCalcDirty ? 18 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '🔄 Calculate Refinance Savings',
                    style: AppTextStyles.dmSans(
                      size: 14,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _buildSectionHeader('Today\'s Refi Rates', onReset: null),
        const SizedBox(height: 8),

        // Horizontal scroll rates
        SizedBox(
          height: 98,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildRateCard('Rocket Mortgage', '6.74%', '30-Yr Fixed', 'Lowest', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
              _buildRateCard('United Wholesale', '6.78%', '30-Yr Fixed', 'Low', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
              _buildRateCard('Chase Bank', '6.82%', '30-Yr Fixed', 'Avg', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
              _buildRateCard('Wells Fargo', '6.88%', '30-Yr Fixed', 'Avg', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
              _buildRateCard('Bank of America', '6.05%', '15-Yr Fixed', 'Best 15yr', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
              _buildRateCard('Mr. Cooper', '6.92%', '30-Yr Fixed', 'Higher', const Color(0xFFFEF2F2), const Color(0xFFB91C1C)),
            ],
          ),
        ),

        const SizedBox(height: 20),

        if (!_showResults)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            alignment: Alignment.center,
            child: Column(
              children: [
                const Text('🔄', style: TextStyle(fontSize: 42)),
                const SizedBox(height: 10),
                Text(
                  'Enter Your Loan Details Above',
                  style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fill in both steps, then tap\nCalculate Refinance Savings to see your analysis.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.dmSans(size: 10.5, color: theme.getMutedColor(context)),
                ),
              ],
            ),
          )
        else ...[
          Container(
            key: _resultsKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                            'Inputs have changed. Tap "Calculate Refinance Savings" to update results.',
                            style: AppTextStyles.dmSans(size: 11, color: isDark ? Colors.white70 : const Color(0xFF0B1D3A), weight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                _buildSectionHeader('Refinance Analysis', onReset: null),
                const SizedBox(height: 8),

                // Quick Stats
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickStatBox(
                        icon: '📉',
                        label: 'Rate Drop',
                        value: '${(rateDiff >= 0 ? '-' : '+')}${rateDiff.abs().toStringAsFixed(2)}%',
                        valueColor: rateDiff >= 0 ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickStatBox(
                        icon: '⏱️',
                        label: 'Break-Even',
                        value: breakEvenMonths < 0 ? 'N/A' : '$breakEvenMonths mo',
                        valueColor: const Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickStatBox(
                        icon: '💵',
                        label: 'Monthly Save',
                        value: (monthlySave >= 0 ? '+' : '') + CurrencyFormatter.compact(monthlySave, symbol: '\$'),
                        valueColor: monthlySave >= 0 ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Savings Hero
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: totalSaved >= 0
                          ? [const Color(0xFF14532D), const Color(0xFF15803D)]
                          : [const Color(0xFF7F1D1D), const Color(0xFFB91C1C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL LIFETIME SAVINGS',
                        style: AppTextStyles.dmSans(size: 9, color: Colors.white70, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 6),
                      RichText(
                        text: TextSpan(
                          style: AppTextStyles.dmSans(size: 32, weight: FontWeight.w800, color: Colors.white),
                          children: [
                            TextSpan(text: CurrencyFormatter.compact(totalSaved.abs(), symbol: '\$')),
                            const TextSpan(text: ' '),
                            TextSpan(
                              text: totalSaved >= 0 ? 'saved' : 'more cost',
                              style: const TextStyle(fontSize: 16, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'vs. keeping current loan',
                        style: AppTextStyles.dmSans(size: 10, color: Colors.white60),
                      ),
                      const SizedBox(height: 14),

                      // Hero grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildHeroStatBox('Monthly Save', (monthlySave >= 0 ? '+' : '') + CurrencyFormatter.compact(monthlySave, symbol: '\$')),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildHeroStatBox('New Payment', CurrencyFormatter.compact(newPmt, symbol: '\$')),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildHeroStatBox('Rate Drop', '${(rateDiff >= 0 ? '-' : '+')}${rateDiff.abs().toStringAsFixed(2)}%'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Save Analysis Button
                      GestureDetector(
                        onTap: _saveCalculation,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.13),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.28), width: 1.5),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🔖 ', style: TextStyle(color: Colors.white, fontSize: 13)),
                              Text(
                                'Save This Analysis',
                                style: AppTextStyles.dmSans(
                                  size: 12,
                                  weight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Break even
                _buildBreakEvenCard(breakEvenMonths, monthlySave, closing),
                const SizedBox(height: 12),

                // Donut Card - Interest comparison
                _buildDonutCard(curTotalInt, newTotalInt, closing, totalSaved),
                const SizedBox(height: 12),

                // Cumulative Savings line chart
                _buildTimelineChartCard(monthlySave, closing, calcSelectedTerm),
                const SizedBox(height: 12),

                // Comparison Table
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.getCardColor(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.getBorderColor(context)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07), blurRadius: 14, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📊 Loan Comparison',
                        style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context)),
                      ),
                      const SizedBox(height: 12),

                      // Header
                      _buildCompRowHeader(),
                      const Divider(),

                      // Rows
                      _buildCompRow('Monthly P&I', CurrencyFormatter.format(curPmt), CurrencyFormatter.format(newPmt), curValColor: const Color(0xFFB91C1C), newValColor: const Color(0xFF15803D)),
                      _buildCompRow('Interest Rate', '${curRate.toStringAsFixed(2)}%', '${newRate.toStringAsFixed(2)}%', curValColor: const Color(0xFFB91C1C), newValColor: const Color(0xFF15803D)),
                      _buildCompRow('Total Interest', CurrencyFormatter.format(curTotalInt), CurrencyFormatter.format(newTotalInt), curValColor: const Color(0xFFB91C1C), newValColor: const Color(0xFF15803D)),
                      _buildCompRow('Total Cost', CurrencyFormatter.format(curBal + curTotalInt), CurrencyFormatter.format(newPrincipal + newTotalInt)),
                      _buildCompRow('Payoff Date', '${_getMonthName(curPayoffDate.month)} ${curPayoffDate.year}', '${_getMonthName(newPayoffDate.month)} ${newPayoffDate.year}', newValColor: const Color(0xFF15803D)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const NativeAdWidget(
                  screenName: 'usa_refinance_calc',
                  adType: 'mediumCard',
                ),
                const SizedBox(height: 20),

                // Amortization Snap
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.getCardColor(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.getBorderColor(context)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07), blurRadius: 14, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📈 Interest vs. Principal (New Loan)',
                        style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context)),
                      ),
                      const SizedBox(height: 12),

                      // Map snaps
                      ..._buildAmortBars([1, 5, 10, max(1, calcSelectedTerm ~/ 2), calcSelectedTerm], yearInterest, yearPrincipal, maxVal),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Saved Calculations Section
        if (savedCalcs.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildSectionHeader('🔖 Saved Analyses', onReset: null, countBadge: savedCalcs.length),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: savedCalcs.length,
            itemBuilder: (context, index) {
              final calc = savedCalcs[index];
              final calcSavedVal = calc.results['TotalSavings'] ?? 0.0;
              final isCalcSavedValPositive = calcSavedVal >= 0;

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
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F3A1D) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: const Text('💾', style: TextStyle(fontSize: 15)),
                    ),
                    const SizedBox(width: 12),
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
                              'Break-even: ${calc.results['BreakEvenMonths']?.toInt() ?? 0} mo · Rate: ${(calc.inputs['CurRate'] ?? 0.0).toStringAsFixed(2)}% → ${(calc.inputs['NewRate'] ?? 0.0).toStringAsFixed(2)}%',
                              style: AppTextStyles.dmSans(size: 9.0, color: theme.getMutedColor(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${isCalcSavedValPositive ? '+' : ''}${CurrencyFormatter.compact(calcSavedVal, symbol: '\$')}',
                      style: AppTextStyles.dmSans(
                        size: 13,
                        weight: FontWeight.w800,
                        color: isCalcSavedValPositive
                            ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
                            : (isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C)),
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
                        if (context.mounted) {
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
        ],

        // Insights Section
        const SizedBox(height: 20),
        _buildSectionHeader('💡 Refinance Insights', onReset: null),
        const SizedBox(height: 8),
        Column(
          children: [
            _buildTipCard('📉', 'The 1% Rule', 'Refinancing is generally worth it if your new rate is at least 1% lower. A ${(curRate - newRate).abs().toStringAsFixed(2)}% drop may still benefit you depending on loan size and how long you plan to stay.'),
            const SizedBox(height: 9),
            _buildTipCard('💳', 'Credit Score Impact', 'A 760+ FICO secures the best refi rates. Each 20-point drop can raise your rate ~0.125–0.25%. Check yours at annualcreditreport.com before applying.'),
            const SizedBox(height: 9),
            _buildTipCard('🏛️', 'FOMC Rate Outlook', 'The Fed held rates at 5.25–5.50% at the May 2026 meeting. Markets price in 2 cuts by end of 2026. Mortgage rates may ease to ~6.4% by Q4 2026.'),
            const SizedBox(height: 9),
            _buildTipCard('📋', 'Streamline Refinance', 'FHA Streamline Refi and VA IRRRL allow refinancing with minimal documentation and no appraisal. Ideal if you have an existing FHA or VA loan.'),
          ],
        ),

        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Rates sourced from Freddie Mac Primary Mortgage Market Survey and lender websites as of June 2026. Calculations are estimates for educational purposes. Consult a licensed mortgage professional for personalized advice.',
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans(
              size: 9.0,
              color: theme.getMutedColor(context),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onReset, int? countBadge}) {
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
                  color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$countBadge',
                  style: AppTextStyles.dmSans(
                    size: 9,
                    weight: FontWeight.w700,
                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8),
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
              'Reset',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E4FBF),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String hint, {String? suffix, String? errorText}) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              style: AppTextStyles.dmSans(
                size: 9.5,
                weight: FontWeight.w700,
                color: hasError ? Colors.red : theme.getMutedColor(context),
                letterSpacing: 0.5,
              ),
            ),
            if (hasError)
              Text(
                errorText,
                style: AppTextStyles.dmSans(
                  size: 9,
                  weight: FontWeight.w700,
                  color: Colors.red,
                ),
              )
            else if (hint.isNotEmpty)
              Text(
                hint,
                style: AppTextStyles.dmSans(
                  size: 9,
                  weight: FontWeight.w600,
                  color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E4FBF),
                ),
              ),
          ],
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
            style: AppTextStyles.dmSans(
              size: 14,
              weight: FontWeight.w700,
              color: theme.getTextColor(context),
            ),
            decoration: InputDecoration(
              prefixText: suffix == '%' ? null : '\$ ',
              suffixText: suffix != null ? ' $suffix' : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectorRow<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T> onChanged,
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
        const SizedBox(height: 6),
        Row(
          children: items.map((item) {
            final isActive = item == value;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(item),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF0B1D3A) : theme.getBgColor(context),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: isActive ? const Color(0xFF0B1D3A) : theme.getBorderColor(context),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labelBuilder(item),
                    style: AppTextStyles.dmSans(
                      size: 11,
                      weight: FontWeight.w700,
                      color: isActive ? Colors.white : theme.getMutedColor(context),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSegButton(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1B3F72) : widget.theme.getBgColor(context),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: AppTextStyles.dmSans(
            size: 10.5,
            weight: FontWeight.w700,
            color: isActive ? Colors.white : widget.theme.getMutedColor(context),
          ),
        ),
      ),
    );
  }

  Widget _buildRateCard(String bank, String rate, String type, String tag, Color tagBg, Color tagTextColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 115,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 11),
      decoration: BoxDecoration(
        color: widget.theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            bank,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w700, color: widget.theme.getMutedColor(context), letterSpacing: 0.4),
          ),
          Text(
            rate,
            style: AppTextStyles.dmSans(size: 18, weight: FontWeight.w800, color: widget.theme.getTextColor(context)),
          ),
          Text(
            type,
            style: AppTextStyles.dmSans(size: 9, color: widget.theme.getMutedColor(context)),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark
                  ? (tagBg == const Color(0xFFDCFCE7)
                      ? const Color(0xFF0F3A1D)
                      : (tagBg == const Color(0xFFEFF6FF) ? const Color(0xFF0B1E3F) : const Color(0xFF3F1616)))
                  : tagBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tag,
              style: AppTextStyles.dmSans(
                size: 8.5,
                weight: FontWeight.w700,
                color: isDark
                    ? (tagBg == const Color(0xFFDCFCE7)
                        ? const Color(0xFF4ADE80)
                        : (tagBg == const Color(0xFFEFF6FF) ? const Color(0xFF60A5FA) : const Color(0xFFF87171)))
                    : tagTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatBox({
    required String icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.getBorderColor(context)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context), weight: FontWeight.w700, letterSpacing: 0.4),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatBox(String label, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.dmSans(size: 8, color: Colors.white70, letterSpacing: 0.3),
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakEvenCard(int breakEven, double savings, double closing) {
    String badgeText;
    Color badgeColor;
    Color badgeBg;
    String descText;
    double progress = 0.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (breakEven < 0 || savings <= 0) {
      badgeText = 'Not Worth It';
      badgeColor = isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
      badgeBg = isDark ? const Color(0xFF3F1616) : const Color(0xFFFEF2F2);
      descText = 'Your new payment is not lower than current. Refinancing may not be beneficial.';
    } else {
      progress = (breakEven / 60.0).clamp(0.0, 1.0);
      if (breakEven <= 24) {
        badgeText = '✅ Great Deal';
        badgeColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
        badgeBg = isDark ? const Color(0xFF0F3A1D) : const Color(0xFFDCFCE7);
      } else if (breakEven <= 48) {
        badgeText = '⚠️ Moderate';
        badgeColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E);
        badgeBg = isDark ? const Color(0xFF2E1B0F) : const Color(0xFFFEF3C7);
      } else {
        badgeText = '✗ Long Payback';
        badgeColor = isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
        badgeBg = isDark ? const Color(0xFF3F1616) : const Color(0xFFFEF2F2);
      }
      descText = 'Closing costs of ${CurrencyFormatter.format(closing, symbol: '\$').split('.').first} are recovered in $breakEven months of monthly savings.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.theme.getCardColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: widget.theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '⏱️ Break-Even Point',
                style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: widget.theme.getTextColor(context)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  badgeText,
                  style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w700, color: badgeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: AppTextStyles.dmSans(size: 22, weight: FontWeight.w800, color: widget.theme.getTextColor(context)),
              children: [
                TextSpan(text: breakEven < 0 ? '—' : '$breakEven'),
                const TextSpan(text: ' '),
                TextSpan(text: 'months', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w600, color: widget.theme.getMutedColor(context))),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Progress bar
          LayoutBuilder(
            builder: (context, constraints) {
              final fillWidth = progress * constraints.maxWidth;
              return Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(color: widget.theme.getBgColor(context), borderRadius: BorderRadius.circular(8)),
                  ),
                  if (fillWidth > 0)
                    Container(
                      height: 10,
                      width: fillWidth,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFF59E0B)]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                ],
              );
            }
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0 mo', style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context))),
              Text(breakEven > 0 ? '${breakEven ~/ 2} mo' : '', style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context))),
              Text(breakEven > 0 ? '$breakEven mo' : '', style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context))),
            ],
          ),
          const SizedBox(height: 10),

          // Desc Row
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  descText,
                  style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompRowHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        const Expanded(flex: 12, child: SizedBox()),
        Expanded(
          flex: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFF1B3F72).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              'Current',
              style: AppTextStyles.dmSans(
                size: 9,
                weight: FontWeight.w800,
                color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1B3F72),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F3A1D) : const Color(0xFF15803D).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              'New Refi',
              style: AppTextStyles.dmSans(
                size: 9,
                weight: FontWeight.w800,
                color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompRow(String label, String curVal, String newVal, {Color? curValColor, Color? newValColor}) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color? finalCurColor = curValColor;
    Color? finalNewColor = newValColor;
    if (isDark) {
      if (curValColor == const Color(0xFFB91C1C)) {
        finalCurColor = const Color(0xFFF87171);
      }
      if (newValColor == const Color(0xFF15803D)) {
        finalNewColor = const Color(0xFF4ADE80);
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 12,
            child: Text(
              label,
              style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w700, color: theme.getTextColor(context)),
            ),
          ),
          Expanded(
            flex: 10,
            child: Text(
              curVal,
              textAlign: TextAlign.center,
              style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: finalCurColor ?? theme.getTextColor(context)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 10,
            child: Text(
              newVal,
              textAlign: TextAlign.center,
              style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: finalNewColor ?? theme.getTextColor(context)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAmortBars(List<int> years, List<double> yearInt, List<double> yearPrin, double maxVal) {
    final bars = <Widget>[];
    for (final y in years) {
      if (y > yearInt.length) continue;
      final idx = y - 1;
      final intW = (yearInt[idx] / maxVal).clamp(0.0, 1.0);
      final prinW = (yearPrin[idx] / maxVal).clamp(0.0, 1.0);

      bars.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 64,
                    child: Text(
                      'Yr $y Int',
                      style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w600, color: widget.theme.getMutedColor(context)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            Container(height: 9, decoration: BoxDecoration(color: widget.theme.getBgColor(context), borderRadius: BorderRadius.circular(6))),
                            Container(
                              height: 9,
                              width: constraints.maxWidth * intW,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFFB91C1C), Color(0xFFEF4444)]),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        );
                      }
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 60,
                    child: Text(
                      CurrencyFormatter.compact(yearInt[idx], symbol: '\$'),
                      textAlign: TextAlign.right,
                      style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: widget.theme.getTextColor(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  SizedBox(
                    width: 64,
                    child: Text(
                      'Yr $y Prin',
                      style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w600, color: widget.theme.getMutedColor(context)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            Container(height: 9, decoration: BoxDecoration(color: widget.theme.getBgColor(context), borderRadius: BorderRadius.circular(6))),
                            Container(
                              height: 9,
                              width: constraints.maxWidth * prinW,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF15803D), Color(0xFF22C55E)]),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        );
                      }
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 60,
                    child: Text(
                      CurrencyFormatter.compact(yearPrin[idx], symbol: '\$'),
                      textAlign: TextAlign.right,
                      style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: widget.theme.getTextColor(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      );
    }
    return bars;
  }

  Widget _buildTipCard(String icon, String title, String desc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: widget.theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.theme.getBorderColor(context)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07), blurRadius: 14, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.theme.getBgColor(context),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: widget.theme.getTextColor(context)),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: AppTextStyles.dmSans(size: 9.5, color: widget.theme.getMutedColor(context), height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildDonutCard(double curTotalInt, double newTotalInt, double closing, double totalSaved) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = widget.theme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.getBorderColor(context)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07), blurRadius: 14, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💰 Interest Cost Comparison',
            style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(120, 120),
                    painter: _RefiDonutPainter(
                      curTotalInt: curTotalInt,
                      newTotalInt: newTotalInt,
                      closing: closing,
                      isDark: isDark,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'You Save',
                        style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context), weight: FontWeight.w700),
                      ),
                      Text(
                        CurrencyFormatter.compact(totalSaved.abs(), symbol: '\$'),
                        style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: theme.getTextColor(context)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _buildDonutLegendRow(
                      color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C),
                      label: 'Current Loan',
                      sub: 'Total interest',
                      value: CurrencyFormatter.compact(curTotalInt, symbol: '\$'),
                      textColor: theme.getTextColor(context),
                    ),
                    const SizedBox(height: 9),
                    _buildDonutLegendRow(
                      color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
                      label: 'New Refi Loan',
                      sub: 'Total interest',
                      value: CurrencyFormatter.compact(newTotalInt, symbol: '\$'),
                      textColor: theme.getTextColor(context),
                    ),
                    const SizedBox(height: 9),
                    _buildDonutLegendRow(
                      color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                      label: 'Closing Costs',
                      sub: 'One-time upfront',
                      value: CurrencyFormatter.compact(closing, symbol: '\$'),
                      textColor: theme.getTextColor(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonutLegendRow({
    required Color color,
    required String label,
    required String sub,
    required String value,
    required Color textColor,
  }) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: textColor),
              ),
              Text(
                sub,
                style: AppTextStyles.dmSans(size: 9, color: widget.theme.getMutedColor(context)),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: textColor),
        ),
      ],
    );
  }

  Widget _buildTimelineChartCard(double monthlySave, double closing, int termYears) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = widget.theme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.getBorderColor(context)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07), blurRadius: 14, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📈 Cumulative Savings Over Time',
            style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context)),
          ),
          Text(
            'Monthly savings minus closing cost payback',
            style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 160,
            width: double.infinity,
            child: CustomPaint(
              painter: _SavingsTimelinePainter(
                monthlySave: monthlySave,
                closing: closing,
                termYears: termYears,
                isDark: isDark,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 9, height: 9,
                decoration: BoxDecoration(color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D), borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 6),
              Text(
                'Net Cumulative Savings',
                style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w600, color: theme.getMutedColor(context)),
              ),
              const SizedBox(width: 14),
              Container(
                width: 9, height: 9,
                decoration: BoxDecoration(
                  border: Border.all(color: isDark ? Colors.white38 : Colors.black38),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Break-Even Line',
                style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w600, color: theme.getMutedColor(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RefiDonutPainter extends CustomPainter {
  final double curTotalInt;
  final double newTotalInt;
  final double closing;
  final bool isDark;

  _RefiDonutPainter({
    required this.curTotalInt,
    required this.newTotalInt,
    required this.closing,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const strokeWidth = 13.0;

    final paintBg = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F4FF)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, paintBg);

    final total = curTotalInt + newTotalInt + closing;
    if (total <= 0) return;

    final curPct = curTotalInt / total;
    final newPct = newTotalInt / total;
    final closingPct = closing / total;

    double startAngle = -pi / 2;

    if (curPct > 0) {
      final sweep = 2 * pi * curPct;
      final paintCur = Paint()
        ..color = isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, sweep, false, paintCur);
      startAngle += sweep;
    }

    if (newPct > 0) {
      final sweep = 2 * pi * newPct;
      final paintNew = Paint()
        ..color = isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, sweep, false, paintNew);
      startAngle += sweep;
    }

    if (closingPct > 0) {
      final sweep = 2 * pi * closingPct;
      final paintClosing = Paint()
        ..color = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, sweep, false, paintClosing);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SavingsTimelinePainter extends CustomPainter {
  final double monthlySave;
  final double closing;
  final int termYears;
  final bool isDark;

  _SavingsTimelinePainter({
    required this.monthlySave,
    required this.closing,
    required this.termYears,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final months = termYears * 12;
    
    // Calculate values along the timeline
    final pts = <Offset>[];
    final step = max(1, months ~/ 60);
    for (int m = 0; m <= months; m += step) {
      pts.add(Offset(m.toDouble(), monthlySave * m - closing));
    }

    final double finalVal = monthlySave * months - closing;
    
    // Find min and max Y to correctly size the chart bounds
    double minY = -closing;
    double maxY = max(finalVal, 1000.0);
    for (final p in pts) {
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }

    const double paddingLeft = 10.0;
    const double paddingRight = 10.0;
    const double paddingTop = 10.0;
    const double paddingBottom = 20.0;

    final double cW = size.width - paddingLeft - paddingRight;
    final double cH = size.height - paddingTop - paddingBottom;
    final double range = maxY - minY != 0.0 ? maxY - minY : 1.0;

    double px(double m) => paddingLeft + (m / months) * cW;
    double py(double v) => paddingTop + cH - ((v - minY) / range) * cH;

    // Zero Line (Dashed)
    final zeroY = py(0.0);
    final paintZero = Paint()
      ..color = isDark ? Colors.white24 : Colors.black12
      ..strokeWidth = 1.0;
    
    // Custom dashed line drawing
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = paddingLeft;
    while (startX < paddingLeft + cW) {
      canvas.drawLine(Offset(startX, zeroY), Offset(startX + dashWidth, zeroY), paintZero);
      startX += dashWidth + dashSpace;
    }

    if (monthlySave <= 0) {
      // No savings, just draw negative area
      final pathNeg = Path()
        ..moveTo(px(0), zeroY)
        ..lineTo(px(0), py(-closing))
        ..lineTo(px(months.toDouble()), py(finalVal))
        ..lineTo(px(months.toDouble()), zeroY)
        ..close();
      canvas.drawPath(pathNeg, Paint()..color = isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.15) : const Color(0xFFFEF2F2));
      
      final paintLine = Paint()
        ..color = isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      
      final linePath = Path()
        ..moveTo(px(0), py(-closing))
        ..lineTo(px(months.toDouble()), py(finalVal));
      canvas.drawPath(linePath, paintLine);
    } else {
      final double breakEven = monthlySave > 0 ? closing / monthlySave : double.infinity;

      // Fill Negative Area (Red)
      if (breakEven > 0) {
        final double limitM = min(months.toDouble(), breakEven);
        final pathNeg = Path()
          ..moveTo(px(0), zeroY)
          ..lineTo(px(0), py(-closing));
        
        for (int m = 0; m <= limitM; m += step) {
          pathNeg.lineTo(px(m.toDouble()), py(monthlySave * m - closing));
        }
        pathNeg.lineTo(px(limitM), zeroY);
        pathNeg.close();
        canvas.drawPath(pathNeg, Paint()..color = isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.15) : const Color(0xFFFEF2F2));
      }

      // Fill Positive Area (Green Gradient)
      if (months > breakEven) {
        final pathPos = Path()
          ..moveTo(px(breakEven), zeroY);
        
        for (double m = breakEven; m <= months; m += step) {
          pathPos.lineTo(px(m), py(monthlySave * m - closing));
        }
        pathPos.lineTo(px(months.toDouble()), py(finalVal));
        pathPos.lineTo(px(months.toDouble()), zeroY);
        pathPos.close();

        final gradient = LinearGradient(
          colors: isDark
              ? [const Color(0xFF14532D).withValues(alpha: 0.35), const Color(0xFF14532D).withValues(alpha: 0.05)]
              : [const Color(0xFFDCFCE7), const Color(0xFFDCFCE7).withValues(alpha: 0.1)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        final paintGrad = Paint()
          ..shader = gradient.createShader(Rect.fromLTRB(px(breakEven), py(finalVal), px(months.toDouble()), zeroY));
        canvas.drawPath(pathPos, paintGrad);
      }

      // Draw Savings Line
      final paintLine = Paint()
        ..color = isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      
      final linePath = Path();
      linePath.moveTo(px(0), py(-closing));
      for (final p in pts) {
        linePath.lineTo(px(p.dx), py(p.dy));
      }
      canvas.drawPath(linePath, paintLine);
    }

    // Draw Year Labels on X-axis
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final textStyle = AppTextStyles.dmSans(size: 8.5, color: isDark ? Colors.white54 : const Color(0xFF4A5C7A), weight: FontWeight.w600);
    
    final int stepYears = max(1, termYears ~/ 4);
    for (int y = 0; y <= termYears; y += stepYears) {
      textPainter.text = TextSpan(text: 'Yr $y', style: textStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(px(y * 12.0) - textPainter.width / 2, size.height - 14));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

