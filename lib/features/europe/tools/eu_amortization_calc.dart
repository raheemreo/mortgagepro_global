// lib/features/europe/tools/eu_amortization_calc.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/europe_rates_provider.dart';
import '../../../shared/models/saved_calc.dart';

class EUAmortizationCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;

  const EUAmortizationCalc({
    super.key,
    required this.theme,
    this.savedCalc,
  });

  @override
  ConsumerState<EUAmortizationCalc> createState() => _EUAmortizationCalcState();
}

class _EUAmortizationCalcState extends ConsumerState<EUAmortizationCalc> {
  final _resultsKey = GlobalKey();
  final Map<String, dynamic> _calcSnapshot = {};

  String _countryCode = 'DE';
  String _rateType = 'fixed'; // fixed, variable
  double _loanAmount = 336000;
  double _rate = 3.85;
  int _termYears = 20;
  String _startMonth = '2026-01'; // YYYY-MM

  bool _hasCalculated = false;
  bool _showAllYears = false;

  final Map<String, Map<String, double>> _rates = {
    'DE': {'fixed': 3.85, 'variable': 3.42 + 1.5},
    'FR': {'fixed': 3.60, 'variable': 3.42 + 1.2},
    'ES': {'fixed': 4.10, 'variable': 3.42 + 1.8},
    'IT': {'fixed': 4.25, 'variable': 3.42 + 2.0},
    'NL': {'fixed': 3.75, 'variable': 3.42 + 1.3},
    'PT': {'fixed': 4.30, 'variable': 3.42 + 2.2}
  };

  final List<Map<String, String>> _startMonths = [
    {'value': '2025-07', 'label': 'Jul 2025'},
    {'value': '2025-08', 'label': 'Aug 2025'},
    {'value': '2025-09', 'label': 'Sep 2025'},
    {'value': '2025-10', 'label': 'Oct 2025'},
    {'value': '2025-11', 'label': 'Nov 2025'},
    {'value': '2025-12', 'label': 'Dec 2025'},
    {'value': '2026-01', 'label': 'Jan 2026'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _loanAmount = inputs['loanAmount'] ?? 336000;
      _rate = inputs['rate'] ?? 3.85;
      _termYears = (inputs['termYears'] ?? 20).toInt();
      _countryCode = widget.savedCalc!.label.split(' - ').last;

      _calcSnapshot['loanAmount'] = _loanAmount;
      _calcSnapshot['rate'] = _rate;
      _calcSnapshot['termYears'] = _termYears;
      _calcSnapshot['countryCode'] = _countryCode;
      _calcSnapshot['rateType'] = _rateType;
      _calcSnapshot['startMonth'] = _startMonth;

      _hasCalculated = true;
    }
  }

  void _updateRate() {
    setState(() {
      _rate = _rates[_countryCode]?[_rateType] ?? 3.85;
    });
  }

  void _runCalc() {
    setState(() {
      _calcSnapshot['loanAmount'] = _loanAmount;
      _calcSnapshot['rate'] = _rate;
      _calcSnapshot['termYears'] = _termYears;
      _calcSnapshot['countryCode'] = _countryCode;
      _calcSnapshot['rateType'] = _rateType;
      _calcSnapshot['startMonth'] = _startMonth;
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

  void _reset() {
    setState(() {
      _loanAmount = 336000;
      _rate = 3.85;
      _termYears = 20;
      _countryCode = 'DE';
      _rateType = 'fixed';
      _startMonth = '2026-01';
      _hasCalculated = false;
      _calcSnapshot.clear();
    });
  }

  void _saveCalculation() async {
    final double loanAmount = _calcSnapshot['loanAmount'] ?? _loanAmount;
    final double rate = _calcSnapshot['rate'] ?? _rate;
    final int termYears = _calcSnapshot['termYears'] ?? _termYears;
    final String countryCode = _calcSnapshot['countryCode'] ?? _countryCode;

    final double P = loanAmount;
    final double annualR = rate / 100;
    final double r = annualR / 12;
    final int n = termYears * 12;

    final double monthly = P * (r * math.pow(1 + r, n)) / (math.pow(1 + r, n) - 1);
    final double totalPay = monthly * n;
    final double totalInt = totalPay - P;

    final labelCtrl = TextEditingController(text: 'Europe Amortization');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/eu_amortization_calc'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Amortization',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: Loan ${CurrencyFormatter.compact(loanAmount, symbol: '€')} · Monthly: ${CurrencyFormatter.compact(monthly, symbol: '€')}',
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
                hintText: 'Label (e.g. 20-Year Amortization)',
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
          : 'Europe Amortization';
      final calc = SavedCalc.create(
        country: 'Europe',
        calcType: 'Amortization Calc',
        inputs: {
          'loanAmount': loanAmount,
          'rate': rate,
          'termYears': termYears.toDouble(),
        },
        results: {
          'Payment': monthly,
          'Total Paid': totalPay,
          'Total Interest': totalInt,
        },
        label: '$label - $countryCode',
        currencyCode: 'EUR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Calculation saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: widget.theme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final cardBg = theme.getCardColor(context);
    final borderCol = theme.getBorderColor(context);
    final textColor = theme.getTextColor(context);
    final mutedText = theme.getMutedColor(context);

    final double snapLoanAmount = _calcSnapshot['loanAmount'] ?? _loanAmount;
    final double snapRate = _calcSnapshot['rate'] ?? _rate;
    final int snapTermYears = _calcSnapshot['termYears'] ?? _termYears;
    final String snapCountryCode = _calcSnapshot['countryCode'] ?? _countryCode;
    final String snapRateType = _calcSnapshot['rateType'] ?? _rateType;
    final String snapStartMonth = _calcSnapshot['startMonth'] ?? _startMonth;

    // Calc math
    final double P = snapLoanAmount;
    final double annualR = snapRate / 100;
    final double r = annualR / 12;
    final int n = snapTermYears * 12;

    final double monthly = P * (r * math.pow(1 + r, n)) / (math.pow(1 + r, n) - 1);
    final double totalPay = monthly * n;
    final double totalInt = totalPay - P;
    final double intPct = totalPay > 0 ? (totalInt / totalPay * 100) : 0;

    // Payoff Date calculation
    final parts = snapStartMonth.split('-');
    final startYear = int.parse(parts[0]);
    final startMonthNum = int.parse(parts[1]);
    final payoffDateTime = DateTime(startYear, startMonthNum - 1 + snapTermYears * 12);
    final payoffDateStr = DateFormat('MMM yyyy').format(payoffDateTime);

    // Generating schedule list
    final List<Map<String, dynamic>> yearlyData = [];
    double bal = P;
    for (int yr = 1; yr <= snapTermYears; yr++) {
      double yearPrin = 0;
      double yearInt = 0;
      double yearPay = 0;
      for (int mo = 0; mo < 12; mo++) {
        if (bal <= 0) break;
        final iAmt = bal * r;
        final pAmt = math.min(monthly - iAmt, bal);
        yearInt += iAmt;
        yearPrin += pAmt;
        yearPay += monthly;
        bal = math.max(0, bal - pAmt);
      }
      yearlyData.add({
        'year': startYear + yr - 1,
        'principal': yearPrin,
        'interest': yearInt,
        'paid': yearPay,
        'balance': bal,
      });
    }

    final visRows = _showAllYears ? snapTermYears : 5;

    final isDirty = _hasCalculated && (
      _loanAmount != snapLoanAmount ||
      _rate != snapRate ||
      _termYears != snapTermYears ||
      _countryCode != snapCountryCode ||
      _rateType != snapRateType ||
      _startMonth != snapStartMonth
    );

    // Live ECB rates
    final ratesAsync = ref.watch(europeRatesProvider);
    final liveEcb = ratesAsync.valueOrNull?.ecbRate.value ?? 4.00;
    final liveEu6m = ratesAsync.valueOrNull?.euribor6m.value ?? 3.42;
    final isLive = ratesAsync.valueOrNull?.isLive == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Rate Strip ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.primaryColor.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _rateStrip('🇩🇪 DE Fixed', '${(liveEcb + 0.85).toStringAsFixed(2)}%', '10yr avg', mutedText, textColor),
              Container(width: 0.5, height: 26, color: borderCol),
              _rateStrip('🇫🇷 FR Fixed', '${(liveEcb + 0.60).toStringAsFixed(2)}%', '20yr avg', mutedText, textColor),
              Container(width: 0.5, height: 26, color: borderCol),
              _rateStrip('Euribor', '${liveEu6m.toStringAsFixed(2)}%', '6-month', mutedText, const Color(0xFFFFCC00)),
              Container(width: 0.5, height: 26, color: borderCol),
              _rateStrip('ECB${isLive ? ' 🟢' : ''}', '${liveEcb.toStringAsFixed(2)}%', 'Current', mutedText, const Color(0xFFFFD700)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('LOAN DETAILS', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: mutedText, letterSpacing: 1.0)),
            GestureDetector(
              onTap: _reset,
              child: Text('Reset', style: AppTextStyles.dmSans(size: 11, color: theme.primaryColor, weight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Inputs Card
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
              // Row 1: Country & Rate Type
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('COUNTRY', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: mutedText)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: theme.getBgColor(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderCol),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _countryCode,
                              dropdownColor: cardBg,
                              style: AppTextStyles.dmSans(size: 13, color: textColor, weight: FontWeight.bold),
                              items: const [
                                DropdownMenuItem(value: 'DE', child: Text('🇩🇪 Germany')),
                                DropdownMenuItem(value: 'FR', child: Text('🇫🇷 France')),
                                DropdownMenuItem(value: 'ES', child: Text('🇪🇸 Spain')),
                                DropdownMenuItem(value: 'IT', child: Text('🇮🇹 Italy')),
                                DropdownMenuItem(value: 'NL', child: Text('🇳🇱 Netherlands')),
                                DropdownMenuItem(value: 'PT', child: Text('🇵🇹 Portugal')),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _countryCode = v;
                                    _updateRate();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RATE TYPE', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: mutedText)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: theme.getBgColor(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderCol),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _rateType,
                              dropdownColor: cardBg,
                              style: AppTextStyles.dmSans(size: 13, color: textColor, weight: FontWeight.bold),
                              items: const [
                                DropdownMenuItem(value: 'fixed', child: Text('Fixed')),
                                DropdownMenuItem(value: 'variable', child: Text('Variable (Euribor)')),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _rateType = v;
                                    _updateRate();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Row 2: Loan Amount & Interest Rate
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LOAN AMOUNT (€)', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: mutedText)),
                        const SizedBox(height: 4),
                        TextField(
                          keyboardType: TextInputType.number,
                          style: AppTextStyles.dmSans(size: 13, color: textColor, weight: FontWeight.bold),
                          decoration: InputDecoration(
                            fillColor: theme.getBgColor(context),
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          controller: TextEditingController(text: _loanAmount.toStringAsFixed(0))
                            ..selection = TextSelection.collapsed(offset: _loanAmount.toStringAsFixed(0).length),
                          onChanged: (v) => _loanAmount = double.tryParse(v) ?? 0,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('INTEREST RATE (%)', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: mutedText)),
                        const SizedBox(height: 4),
                        TextField(
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: AppTextStyles.dmSans(size: 13, color: textColor, weight: FontWeight.bold),
                          decoration: InputDecoration(
                            fillColor: theme.getBgColor(context),
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          controller: TextEditingController(text: _rate.toString())
                            ..selection = TextSelection.collapsed(offset: _rate.toString().length),
                          onChanged: (v) => _rate = double.tryParse(v) ?? 0,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Row 3: Term & Start Month
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TERM', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: mutedText)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: theme.getBgColor(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderCol),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _termYears,
                              dropdownColor: cardBg,
                              style: AppTextStyles.dmSans(size: 13, color: textColor, weight: FontWeight.bold),
                              items: const [
                                DropdownMenuItem(value: 10, child: Text('10 years')),
                                DropdownMenuItem(value: 15, child: Text('15 years')),
                                DropdownMenuItem(value: 20, child: Text('20 years')),
                                DropdownMenuItem(value: 25, child: Text('25 years')),
                                DropdownMenuItem(value: 30, child: Text('30 years')),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _termYears = v);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('START MONTH', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: mutedText)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: theme.getBgColor(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderCol),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _startMonth,
                              dropdownColor: cardBg,
                              style: AppTextStyles.dmSans(size: 13, color: textColor, weight: FontWeight.bold),
                              items: _startMonths.map((it) {
                                return DropdownMenuItem(value: it['value']!, child: Text(it['label']!));
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _startMonth = v);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: _runCalc,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF003399), Color(0xFF1A0040)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF003399).withValues(alpha: 0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📅', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text('Generate Amortization Schedule',
                          style: AppTextStyles.dmSans(
                              size: 13, weight: FontWeight.w800, color: const Color(0xFFFFCC00))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_hasCalculated) ...[
          Column(
            key: _resultsKey,
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
              // Summary boxes
              Text('SUMMARY', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: mutedText, letterSpacing: 1.0)),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: theme.headerGradient,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Monthly Payment', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text(CurrencyFormatter.format(monthly, symbol: '€'), style: AppTextStyles.playfair(size: 18, color: const Color(0xFFFFCC00), weight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        const Text('Fixed instalment', style: TextStyle(color: Colors.white38, fontSize: 8)),
                      ],
                    ),
                  ),
                  _summaryBox('Total Payment', CurrencyFormatter.format(totalPay, symbol: '€'), 'Over full term'),
                  _summaryBox('Total Interest', CurrencyFormatter.format(totalInt, symbol: '€'), '${intPct.toStringAsFixed(1)}% of loan'),
                  _summaryBox('Payoff Date', payoffDateStr, '$snapTermYears years term'),
                ],
              ),
              const SizedBox(height: 16),

              // Stacked Bar visual
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
                    Text('Composition Breakdown', style: AppTextStyles.cardTitle(textColor)),
                    const SizedBox(height: 12),
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                      clipBehavior: Clip.hardEdge,
                      child: Row(
                        children: [
                          Expanded(
                            flex: (P / totalPay * 100).round(),
                            child: Container(color: const Color(0xFF003399)),
                          ),
                          Expanded(
                            flex: (totalInt / totalPay * 100).round(),
                            child: Container(color: const Color(0xFFFFCC00)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _legendRow(const Color(0xFF003399), 'Principal ${CurrencyFormatter.format(P, symbol: '€')} (${(P / totalPay * 100).toStringAsFixed(1)}%)'),
                    const SizedBox(height: 6),
                    _legendRow(const Color(0xFFFFCC00), 'Interest ${CurrencyFormatter.format(totalInt, symbol: '€')} (${(totalInt / totalPay * 100).toStringAsFixed(1)}%)'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Save Schedule Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: borderCol),
                ),
                child: Row(
                  children: [
                    const Text('💾', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Save this Schedule', style: AppTextStyles.dmSans(size: 13, weight: FontWeight.bold, color: textColor)),
                          Text('Store calculation for later reference', style: AppTextStyles.dmSans(size: 10, color: mutedText)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _saveCalculation,
                      child: Text('Save ✓', style: AppTextStyles.dmSans(size: 11, color: const Color(0xFFFFCC00), weight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Yearly table list
              Text('YEARLY AMORTIZATION TABLE', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: mutedText, letterSpacing: 1.0)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol),
                ),
                clipBehavior: Clip.hardEdge,
                child: Column(
                  children: [
                    Container(
                      color: theme.primaryColor.withValues(alpha: 0.05),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _headerCell('Yr'),
                          _headerCell('Principal'),
                          _headerCell('Interest'),
                          _headerCell('Total Paid'),
                          _headerCell('Balance'),
                        ],
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: visRows,
                      separatorBuilder: (_, __) => Divider(height: 1, thickness: 0.5, color: borderCol),
                      itemBuilder: (context, idx) {
                        final data = yearlyData[idx];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _cellText(data['year'].toString(), isBold: true, color: Theme.of(context).brightness == Brightness.dark ? theme.accentColor : theme.primaryColor),
                              _cellText(CurrencyFormatter.format(data['principal'], symbol: '€')),
                              _cellText(CurrencyFormatter.format(data['interest'], symbol: '€'), color: Theme.of(context).brightness == Brightness.dark ? Colors.orangeAccent : Colors.orange.shade800),
                              _cellText(CurrencyFormatter.format(data['paid'], symbol: '€')),
                              _cellText(CurrencyFormatter.format(data['balance'], symbol: '€'), color: Theme.of(context).brightness == Brightness.dark ? Colors.purple.shade200 : Colors.purple.shade900),
                            ],
                          ),
                        );
                      },
                    ),
                    if (snapTermYears > 5 && !_showAllYears)
                      GestureDetector(
                        onTap: () => setState(() => _showAllYears = true),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          color: theme.primaryColor.withValues(alpha: 0.05),
                          alignment: Alignment.center,
                          child: Text('Show all $snapTermYears years ↓', style: AppTextStyles.dmSans(size: 12, color: Theme.of(context).brightness == Brightness.dark ? theme.accentColor : theme.primaryColor, weight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }



  Widget _summaryBox(String label, String value, String sub) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.theme.getCardColor(context),
        border: Border.all(color: widget.theme.getBorderColor(context)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 9, color: widget.theme.getMutedColor(context), weight: FontWeight.bold)),
          const Spacer(),
          Text(value, style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context), weight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(sub, style: AppTextStyles.dmSans(size: 8, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.dmSans(size: 11, color: widget.theme.getTextColor(context))),
      ],
    );
  }

  Widget _headerCell(String label) {
    return Expanded(
      child: Text(
        label,
        style: AppTextStyles.dmSans(size: 9, weight: FontWeight.bold, color: widget.theme.getMutedColor(context)),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _cellText(String label, {bool isBold = false, Color? color}) {
    return Expanded(
      child: Text(
        label,
        style: AppTextStyles.dmSans(
          size: 10.5,
          weight: isBold ? FontWeight.bold : FontWeight.w500,
          color: color ?? widget.theme.getTextColor(context),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _rateStrip(String label, String val, String note, Color mutedText, Color valColor) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: mutedText)),
        const SizedBox(height: 2),
        Text(val, style: AppTextStyles.playfair(size: 13, weight: FontWeight.bold, color: valColor)),
        const SizedBox(height: 1),
        Text(note, style: AppTextStyles.dmSans(size: 8, color: mutedText)),
      ],
    );
  }
}
