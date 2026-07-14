// lib/features/newzealand/tools/nz_mortgage_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../providers/nz_rates_provider.dart';
import '../../../services/remote_config_service.dart';

class NZMortgageCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZMortgageCalc({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZMortgageCalc> createState() => _NZMortgageCalcState();
}

class _NZMortgageCalcState extends ConsumerState<NZMortgageCalc> {
  double _propVal = 850000;
  double _deposit = 170000;
  double _rate = 5.59;
  int _termYears = 30;
  String _repayType = 'PI';

  bool _showResults = false;
  final Map<String, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};
  final _resultsKey = GlobalKey();

  final List<Map<String, dynamic>> _banks = [
    {'name': 'Kiwibank', 'icon': '🥝', 'rate': 5.55},
    {'name': 'ANZ', 'icon': '🏦', 'rate': 5.59},
    {'name': 'ASB', 'icon': '🏦', 'rate': 5.59},
    {'name': 'BNZ', 'icon': '🏦', 'rate': 5.59},
    {'name': 'Westpac', 'icon': '🏦', 'rate': 5.65},
    {'name': 'SBS Bank', 'icon': '🏦', 'rate': 5.70},
  ];

  @override
  void initState() {
    super.initState();
    final saved = ref.read(settingsProvider.notifier).getCalculatorInputs('NewZealand', 'mortgage');
    if (saved != null) {
      _propVal = (saved['propVal'] as num?)?.toDouble() ?? 850000.0;
      _deposit = (saved['deposit'] as num?)?.toDouble() ?? 170000.0;
      _rate = (saved['rate'] as num?)?.toDouble() ?? 5.59;
      _termYears = (saved['term'] as num?)?.toInt() ?? 30;
      _repayType = saved['repayType'] as String? ?? 'PI';
    }
    _showResults = false;
  }

  void _persistInputs() {
    ref.read(settingsProvider.notifier).saveCalculatorInput('NewZealand', 'mortgage', {
      'propVal': _propVal,
      'deposit': _deposit,
      'rate': _rate,
      'term': _termYears,
      'repayType': _repayType,
      'showResults': _showResults,
    });
  }

  void _reset() {
    setState(() {
      _propVal = 850000;
      _deposit = 170000;
      _rate = 5.59;
      _termYears = 30;
      _repayType = 'PI';
      _showResults = false;
      _calcSnapshot.clear();
      _errors.clear();
    });
    _persistInputs();
  }

  void _calculate() {
    final errors = <String, String>{};

    if (_propVal <= 0) {
      errors['propVal'] = 'Enter valid property value';
    }
    if (_deposit < 0) {
      errors['deposit'] = 'Deposit cannot be negative';
    } else if (_deposit >= _propVal && _propVal > 0) {
      errors['deposit'] = 'Deposit must be less than property value';
    }
    if (_rate <= 0 || _rate > 25) {
      errors['rate'] = 'Enter rate between 0.1% and 25%';
    }
    if (_termYears <= 0 || _termYears > 50) {
      errors['term'] = 'Enter term between 1 and 50 years';
    }

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) return;

    setState(() {
      _calcSnapshot['propVal'] = _propVal;
      _calcSnapshot['deposit'] = _deposit;
      _calcSnapshot['rate'] = _rate;
      _calcSnapshot['term'] = _termYears;
      _calcSnapshot['repayType'] = _repayType;
      _showResults = true;
    });
    _persistInputs();

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

  void _saveCalculation() async {
    final snapPropVal = _calcSnapshot['propVal'] ?? _propVal;
    final snapDeposit = _calcSnapshot['deposit'] ?? _deposit;
    final snapRate = _calcSnapshot['rate'] ?? _rate;
    final snapTerm = _calcSnapshot['term'] ?? _termYears;
    final snapRepayType = _calcSnapshot['repayType'] ?? _repayType;

    final loanAmt = snapPropVal - snapDeposit;
    if (loanAmt <= 0) return;

    final lvr = (loanAmt / snapPropVal) * 100;
    final monthlyRate = snapRate / 100 / 12;
    final n = snapTerm * 12;

    double monthly;
    double totalInterest;
    double totalPaid;

    if (snapRepayType == 'PI') {
      if (monthlyRate == 0) {
        monthly = loanAmt / n;
      } else {
        monthly = loanAmt *
            (monthlyRate * pow(1 + monthlyRate, n)) /
            (pow(1 + monthlyRate, n) - 1);
      }
      totalPaid = monthly * n;
      totalInterest = totalPaid - loanAmt;
    } else {
      monthly = loanAmt * monthlyRate;
      totalInterest = monthly * n;
      totalPaid = loanAmt + totalInterest;
    }

    final labelCtrl = TextEditingController(text: 'NZ Dream Home');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/nz_mortgage_calc/save'),
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
                'Saving: ${CurrencyFormatter.compact(loanAmt, symbol: 'NZ\$')} loan @ $snapRate% → ${CurrencyFormatter.compact(monthly, symbol: 'NZ\$')}/mo',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Auckland Property)',
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
              backgroundColor: const Color(0xFF1A6B4A),
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
          : 'Mortgage Calc';
      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'Mortgage Calc',
        inputs: <String, double>{
          'propertyValue': snapPropVal,
          'deposit': snapDeposit,
          'rate': snapRate,
          'termYears': snapTerm.toDouble(),
          'repayType': snapRepayType == 'PI' ? 0.0 : 1.0,
        },
        results: <String, double>{
          'monthly': monthly,
          'totalInterest': totalInterest,
          'totalRepaid': totalPaid,
          'lvr': lvr,
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Calculation saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF1A6B4A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    // Live NZ rates
    final nzRates = ref.watch(nzRatesProvider).valueOrNull;
    final f1 = nzRates?.fixed1yr.value ?? 5.59;
    final f2 = nzRates?.fixed2yr.value ?? 5.29;
    final f3 = nzRates?.fixed3yr.value ?? 5.19;
    final f5 = nzRates?.fixed5yr.value ?? 5.09;
    final fl = nzRates?.floating.value ?? 7.24;
    final isLive = nzRates?.isLive == true;
    final rc = RemoteConfigService.instance;
    final ocr = double.tryParse(rc.nzOcrRate) ?? 2.25;

    // Update bank rates if live
    if (isLive) {
      _banks[0]['rate'] = nzRates?.kiwibank1yr ?? 5.55;
      _banks[1]['rate'] = nzRates?.anz1yr      ?? 5.59;
      _banks[2]['rate'] = nzRates?.asb1yr      ?? 5.59;
      _banks[3]['rate'] = nzRates?.bnz1yr      ?? 5.59;
      _banks[4]['rate'] = nzRates?.westpac1yr  ?? 5.65;
    }

    final double rawPropVal = _propVal;
    final double rawDeposit = _deposit;
    final double rawRate = _rate;
    final int rawTerm = _termYears;
    final String rawRepayType = _repayType;

    final double propVal = _showResults ? (_calcSnapshot['propVal'] ?? rawPropVal) : rawPropVal;
    final double deposit = _showResults ? (_calcSnapshot['deposit'] ?? rawDeposit) : rawDeposit;
    final double rate = _showResults ? (_calcSnapshot['rate'] ?? rawRate) : rawRate;
    final int termYears = _showResults ? (_calcSnapshot['term'] ?? rawTerm) : rawTerm;
    final String repayType = _showResults ? (_calcSnapshot['repayType'] ?? rawRepayType) : rawRepayType;

    // Calculations
    final loanAmt = propVal - deposit;
    final lvr = propVal > 0 ? (loanAmt / propVal) * 100 : 0.0;
    final monthlyRate = rate / 100 / 12;
    final n = termYears * 12;

    double monthly;
    double totalInterest;
    double totalPaid;

    if (repayType == 'PI') {
      if (monthlyRate == 0) {
        monthly = loanAmt / n;
      } else {
        monthly = loanAmt *
            (monthlyRate * pow(1 + monthlyRate, n)) /
            (pow(1 + monthlyRate, n) - 1);
      }
      totalPaid = monthly * n;
      totalInterest = totalPaid - loanAmt;
    } else {
      monthly = loanAmt * monthlyRate;
      totalInterest = monthly * n;
      totalPaid = loanAmt + totalInterest;
    }

    final fortnightly = monthly / 2;
    final weekly = monthly / 4.333;

    // Donut chart percentages
    final donutTotal = loanAmt + totalInterest;
    final principalPct = donutTotal > 0 ? loanAmt / donutTotal : 0.0;
    final interestPct = donutTotal > 0 ? totalInterest / donutTotal : 0.0;

    final isDirty = _showResults && (
      _propVal != (_calcSnapshot['propVal'] ?? 0.0) ||
      _deposit != (_calcSnapshot['deposit'] ?? 0.0) ||
      _rate != (_calcSnapshot['rate'] ?? 0.0) ||
      _termYears != (_calcSnapshot['term'] ?? 0) ||
      _repayType != (_calcSnapshot['repayType'] ?? '')
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A0F0D), Color(0xFF0D3B2E)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('New Zealand Mortgage Details',
                      style: AppTextStyles.dmSans(
                          size: 10,
                          color: Colors.white54,
                          weight: FontWeight.w600)),
                  GestureDetector(
                    onTap: _reset,
                    child: Text('Reset ↺',
                        style: AppTextStyles.dmSans(
                            size: 11,
                            color: const Color(0xFFF5D060),
                            weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Calculate NZ Home Loan',
                  style: AppTextStyles.playfair(
                      size: 18, color: Colors.white, weight: FontWeight.w800)),
              const SizedBox(height: 16),

              // Inputs Grid
              Row(
                children: [
                  Expanded(
                    child: _buildInputBox(
                      label: 'Property Value',
                      prefix: 'NZD \$',
                      value: _propVal,
                      errorText: _errors['propVal'],
                      onChanged: (val) => setState(() {
                        _propVal = val;
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputBox(
                      label: 'Deposit',
                      prefix: 'NZD \$',
                      value: _deposit,
                      errorText: _errors['deposit'],
                      onChanged: (val) => setState(() {
                        _deposit = val;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildInputBox(
                      label: 'Interest Rate %',
                      prefix: '',
                      value: _rate,
                      isPercent: true,
                      errorText: _errors['rate'],
                      onChanged: (val) => setState(() {
                        _rate = val;
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputBox(
                      label: 'Loan Term (yrs)',
                      prefix: '',
                      value: _termYears.toDouble(),
                      isInteger: true,
                      errorText: _errors['term'],
                      onChanged: (val) => setState(() {
                        _termYears = val.toInt();
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Quick Rate Pills
              Text('NZ Lender Rates${isLive ? " 🟢 Live" : " (2025 Est.)"}',
                  style: AppTextStyles.dmSans(
                      size: 9, color: Colors.white54, weight: FontWeight.w600)),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildRatePill('1-yr Fixed ${f1.toStringAsFixed(2)}%', f1),
                    const SizedBox(width: 6),
                    _buildRatePill('2-yr Fixed ${f2.toStringAsFixed(2)}%', f2),
                    const SizedBox(width: 6),
                    _buildRatePill('3-yr Fixed ${f3.toStringAsFixed(2)}%', f3),
                    const SizedBox(width: 6),
                    _buildRatePill('5-yr Fixed ${f5.toStringAsFixed(2)}%', f5),
                    const SizedBox(width: 6),
                    _buildRatePill('Floating ${fl.toStringAsFixed(2)}%', fl),
                    const SizedBox(width: 6),
                    _buildRatePill('OCR ${ocr.toStringAsFixed(2)}%', ocr),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Repayment Type Dropdown
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _repayType,
                    dropdownColor: const Color(0xFF0A0F0D),
                    style: AppTextStyles.dmSans(
                        size: 13, color: Colors.white, weight: FontWeight.w700),
                    items: const [
                      DropdownMenuItem(
                          value: 'PI', child: Text('Principal & Interest')),
                      DropdownMenuItem(
                          value: 'IO', child: Text('Interest Only')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _repayType = val;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Calculate Button
              ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A6B4A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 44),
                  elevation: 4,
                ),
                child: Text('🌿 Calculate NZ Mortgage',
                    style: AppTextStyles.dmSans(
                        size: 14,
                        color: Colors.white,
                        weight: FontWeight.w800)),
              ),
            ],
          ),
        ),

        // Results Section
        if (_showResults) ...[
          if (isDirty) ...[
            const SizedBox(height: 12),
            Container(
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
                      'Inputs have changed. Tap Calculate NZ Mortgage to refresh results.',
                      style: AppTextStyles.dmSans(size: 11, color: Colors.amber[800], weight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Container(
            key: _resultsKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Results',
                        style: AppTextStyles.playfair(
                            size: 15, color: theme.getTextColor(context))),
                    Text(
                      'LVR: ${lvr.toStringAsFixed(1)}% ${lvr > 80 ? "⚠️ High" : "✅ OK"}',
                      style: AppTextStyles.dmSans(
                        size: 11,
                        weight: FontWeight.w700,
                        color: lvr > 80
                            ? const Color(0xFFC0392B)
                            : const Color(0xFF1A6B4A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Monthly Repayment Hero
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.getCardColor(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.getBorderColor(context)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        repayType == 'PI'
                            ? 'MONTHLY PRINCIPAL & INTEREST'
                            : 'MONTHLY INTEREST ONLY PAYMENT',
                        style: AppTextStyles.dmSans(
                          size: 9.5,
                          color: theme.getMutedColor(context),
                          weight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(CurrencyFormatter.format(monthly, currencyCode: 'NZD'),
                          style: AppTextStyles.playfair(
                              size: 32,
                              color: const Color(0xFF1A6B4A),
                              weight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildFreqCol('Weekly', weekly, theme),
                          Container(
                              height: 24,
                              width: 1,
                              color: theme.getBorderColor(context)),
                          _buildFreqCol('Fortnightly', fortnightly, theme),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Stats breakdown
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.getCardColor(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.getBorderColor(context)),
                  ),
                  child: Column(
                    children: [
                      _buildBreakdownRow('Loan Amount', loanAmt, theme),
                      const Divider(height: 20),
                      _buildBreakdownRow('Total Interest Paid', totalInterest, theme),
                      const Divider(height: 20),
                      _buildBreakdownRow('Total Cost of Loan', totalPaid, theme),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Donut Chart Visual
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.getCardColor(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.getBorderColor(context)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CustomPaint(
                          painter: _NZMortgageDonutPainter(
                              pPct: principalPct, iPct: interestPct),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLegendItem('Principal', principalPct,
                                const Color(0xFF1A6B4A), theme),
                            const SizedBox(height: 6),
                            _buildLegendItem('Total Interest', interestPct,
                                const Color(0xFFD4A017), theme),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Real estate list / Save Report Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.getCardColor(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.getBorderColor(context)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('💾 Save this comparison',
                              style: AppTextStyles.dmSans(
                                  size: 11,
                                  weight: FontWeight.w800,
                                  color: theme.getTextColor(context))),
                          Text('Keep record in your portfolio',
                              style: AppTextStyles.dmSans(
                                  size: 9, color: theme.getMutedColor(context))),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _saveCalculation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        child: Text('Save',
                            style: AppTextStyles.dmSans(
                                size: 11,
                                color: Colors.white,
                                weight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Bank comparison table
                Text('Estimated NZ Bank Comparison',
                    style: AppTextStyles.playfair(
                        size: 14, color: theme.getTextColor(context))),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: theme.getCardColor(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.getBorderColor(context)),
                  ),
                  child: Column(
                    children: _banks.map((b) {
                      final bRate = b['rate'] as double;
                      final bPmt = _calcMonthlyPmt(loanAmt, bRate, termYears, repayType);
                      final diff = bPmt - monthly;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: theme.getBorderColor(context),
                                  width: b == _banks.last ? 0 : 1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(b['icon'] as String,
                                    style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 10),
                                Text(b['name'] as String,
                                    style: AppTextStyles.dmSans(
                                        size: 12,
                                        weight: FontWeight.w700,
                                        color: theme.getTextColor(context))),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                    '${CurrencyFormatter.compact(bPmt, symbol: "NZ\$")}/mo',
                                    style: AppTextStyles.dmSans(
                                        size: 12,
                                        weight: FontWeight.w800,
                                        color: theme.getTextColor(context))),
                                Text(
                                  '${bRate.toStringAsFixed(2)}% · ${diff == 0 ? "current" : (diff > 0 ? "+${CurrencyFormatter.compact(diff)}/mo" : "${CurrencyFormatter.compact(diff)}/mo")}',
                                  style: AppTextStyles.dmSans(
                                      size: 9,
                                      color: diff > 0
                                          ? const Color(0xFFC0392B)
                                          : (diff < 0
                                              ? const Color(0xFF1A6B4A)
                                              : theme.getMutedColor(context)),
                                      weight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  double _calcMonthlyPmt(double loanAmt, double rRate, int term, String type) {
    final monthlyRate = rRate / 100 / 12;
    final n = term * 12;
    if (type == 'PI') {
      if (monthlyRate == 0) return loanAmt / n;
      return loanAmt *
          (monthlyRate * pow(1 + monthlyRate, n)) /
          (pow(1 + monthlyRate, n) - 1);
    } else {
      return loanAmt * monthlyRate;
    }
  }

  Widget _buildInputBox({
    required String label,
    required String prefix,
    required double value,
    bool isPercent = false,
    bool isInteger = false,
    required ValueChanged<double> onChanged,
    String? errorText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: errorText != null ? Colors.red : Colors.white.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 8.5, color: Colors.white54, weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (prefix.isNotEmpty)
                Text('$prefix ',
                    style: AppTextStyles.dmSans(
                        size: 11,
                        color: Colors.white54,
                        weight: FontWeight.w700)),
              Expanded(
                child: TextFormField(
                  key: ValueKey(value),
                  initialValue:
                      isInteger ? value.toInt().toString() : value.toString(),
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.playfair(
                      size: 15, color: Colors.white, weight: FontWeight.w800),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  onChanged: (val) {
                    final d = double.tryParse(val) ?? 0.0;
                    onChanged(d);
                  },
                ),
              ),
              if (isPercent)
                Text('%',
                    style: AppTextStyles.dmSans(
                        size: 11,
                        color: Colors.white54,
                        weight: FontWeight.w700)),
            ],
          ),
          if (errorText != null) ...[
            const SizedBox(height: 2),
            Text(errorText, style: AppTextStyles.dmSans(size: 8, color: Colors.red, weight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }

  Widget _buildRatePill(String label, double rateVal) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _rate = rateVal;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          border: Border.all(
              color: _rate == rateVal
                  ? const Color(0xFFF5D060)
                  : Colors.white.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 9,
            color: _rate == rateVal ? const Color(0xFFF5D060) : Colors.white70,
            weight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildFreqCol(String freq, double val, CountryTheme theme) {
    return Column(
      children: [
        Text(freq,
            style: AppTextStyles.dmSans(
                size: 9,
                color: theme.getMutedColor(context),
                weight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(CurrencyFormatter.format(val, currencyCode: 'NZD'),
            style: AppTextStyles.dmSans(
                size: 13,
                color: theme.getTextColor(context),
                weight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildBreakdownRow(String label, double val, CountryTheme theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.dmSans(
                size: 11,
                color: theme.getMutedColor(context),
                weight: FontWeight.w600)),
        Text(CurrencyFormatter.format(val, currencyCode: 'NZD'),
            style: AppTextStyles.dmSans(
                size: 12,
                color: theme.getTextColor(context),
                weight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildLegendItem(
      String label, double pct, Color color, CountryTheme theme) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label (${(pct * 100).toStringAsFixed(0)}%)',
          style: AppTextStyles.dmSans(
            size: 11,
            color: theme.getTextColor(context),
            weight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _NZMortgageDonutPainter extends CustomPainter {
  final double pPct;
  final double iPct;

  _NZMortgageDonutPainter({required this.pPct, required this.iPct});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    const strokeWidth = 10.0;

    final paintP = Paint()
      ..color = const Color(0xFF1A6B4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final paintI = Paint()
      ..color = const Color(0xFFD4A017)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final pAngle = pPct * 2 * pi;
    final iAngle = iPct * 2 * pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -pi / 2,
      pAngle,
      false,
      paintP,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -pi / 2 + pAngle,
      iAngle,
      false,
      paintI,
    );
  }

  @override
  bool shouldRepaint(covariant _NZMortgageDonutPainter oldDelegate) {
    return oldDelegate.pPct != pPct || oldDelegate.iPct != iPct;
  }
}
