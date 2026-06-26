// lib/features/europe/tools/eu_mortgage_calc.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/europe_rates_provider.dart';
import '../../../shared/models/saved_calc.dart';

class EUMortgageCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;

  const EUMortgageCalc({
    super.key,
    required this.theme,
    this.savedCalc,
  });

  @override
  ConsumerState<EUMortgageCalc> createState() => _EUMortgageCalcState();
}

class _EUMortgageCalcState extends ConsumerState<EUMortgageCalc> {
  String _countryCode = 'DE';
  String _mortgageType = 'repayment'; // repayment, interest, endowment
  String _chartView = 'bar'; // bar, balance

  double _propValue = 420000;
  double _depositPct = 20;
  int _termYears = 20;
  double _rate = 3.85;

  // State variables for calculate-on-demand
  bool _hasCalculated = false;
  bool _isDirty = true;

  double _calculatedMonthly = 0.0;
  double _calculatedLoan = 0.0;
  double _calculatedTotalRepaid = 0.0;
  double _calculatedTotalInterest = 0.0;
  double _calculatedLtv = 0.0;
  int? _calculatedBEvenYr;
  double _calculatedInterestRatio = 0.0;
  double _calculatedMonthlyInt = 0.0;
  final List<Map<String, String>> _calculatedInsights = [];

  final Map<String, List<Map<String, dynamic>>> _lenders = {
    'DE': [
      {'name': 'Deutsche Bank', 'rate': 3.85, 'type': '10yr Fixed'},
      {'name': 'Commerzbank', 'rate': 3.92, 'type': '10yr Fixed'},
      {'name': 'DZ Bank', 'rate': 3.78, 'type': '5yr Fixed'},
      {'name': 'ING Germany', 'rate': 3.70, 'type': '5yr Fixed'}
    ],
    'FR': [
      {'name': 'BNP Paribas', 'rate': 3.60, 'type': '20yr Fixed'},
      {'name': 'Crédit Agricole', 'rate': 3.55, 'type': '20yr Fixed'},
      {'name': 'Société Générale', 'rate': 3.65, 'type': '15yr Fixed'},
      {'name': 'LCL', 'rate': 3.50, 'type': '15yr Fixed'}
    ],
    'ES': [
      {'name': 'Santander ES', 'rate': 4.10, 'type': 'Variable+0.6'},
      {'name': 'BBVA', 'rate': 3.95, 'type': 'Variable+0.5'},
      {'name': 'CaixaBank', 'rate': 4.00, 'type': 'Variable+0.55'},
      {'name': 'Sabadell', 'rate': 3.90, 'type': '1yr Fixed'}
    ],
    'IT': [
      {'name': 'Intesa Sanpaolo', 'rate': 3.95, 'type': '20yr Fixed'},
      {'name': 'UniCredit', 'rate': 4.05, 'type': 'Variable'},
      {'name': 'Mediobanca', 'rate': 3.85, 'type': '10yr Fixed'},
      {'name': 'BNL', 'rate': 3.80, 'type': '10yr Fixed'}
    ],
    'NL': [
      {'name': 'ING Netherlands', 'rate': 3.75, 'type': '10yr Fixed'},
      {'name': 'ABN AMRO', 'rate': 3.80, 'type': '10yr Fixed'},
      {'name': 'Rabobank', 'rate': 3.72, 'type': '10yr Fixed'},
      {'name': 'Aegon', 'rate': 3.65, 'type': '5yr Fixed'}
    ],
    'PT': [
      {'name': 'Caixa Geral', 'rate': 3.50, 'type': '30yr Fixed'},
      {'name': 'Millennium BCP', 'rate': 3.55, 'type': 'Variable'},
      {'name': 'Novo Banco', 'rate': 3.60, 'type': '10yr Fixed'},
      {'name': 'Santander PT', 'rate': 3.48, 'type': '5yr Fixed'}
    ]
  };

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _propValue = inputs['propValue'] ?? 420000;
      _depositPct = inputs['depositPct'] ?? 20;
      _termYears = (inputs['termYears'] ?? 20).toInt();
      _rate = inputs['rate'] ?? 3.85;
      final typeVal = inputs['mortgageType'] ?? 0.0;
      _mortgageType = typeVal == 0.0
          ? 'repayment'
          : typeVal == 1.0
              ? 'interest'
              : 'endowment';
      _countryCode = widget.savedCalc!.label.split(' - ').last;
      _calculate();
      _hasCalculated = true;
      _isDirty = false;
    }
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() {
        _isDirty = true;
      });
    }
  }

  void _calculate() {
    final deposit = _propValue * (_depositPct / 100);
    final loan = _propValue - deposit;
    final n = _termYears * 12;
    final r = (_rate / 100) / 12;

    double monthly = 0;
    double totalRepaid = 0;
    double totalInterest = 0;

    if (_mortgageType == 'interest') {
      monthly = loan * r;
      totalInterest = monthly * n;
      totalRepaid = totalInterest + loan;
    } else {
      monthly = r == 0
          ? loan / n
          : loan * (r * math.pow(1 + r, n)) / (math.pow(1 + r, n) - 1);
      totalRepaid = monthly * n;
      totalInterest = totalRepaid - loan;
    }

    final ltv = (loan / _propValue) * 100;

    // Break-even year calculation
    int? bEvenYr;
    if (_mortgageType != 'interest') {
      double cumP = 0;
      double cumI = 0;
      double bal = loan;
      for (int m = 1; m <= n; m++) {
        final interest = bal * r;
        final principal = monthly - interest;
        cumI += interest;
        cumP += principal;
        bal = math.max(0, bal - principal);
        if (bEvenYr == null && cumP >= cumI) {
          bEvenYr = (m / 12).ceil();
        }
      }
    }

    _calculatedInsights.clear();
    if (ltv > 80) {
      _calculatedInsights.add({'icon': '⚠️', 'text': 'LTV >80% — lenders may require PMI'});
    }
    if (_rate > 5.0) {
      _calculatedInsights.add({'icon': '📉', 'text': 'Rate above 5% — consider fixed-rate protection'});
    }
    if (loan > 0 && totalInterest / loan > 0.6) {
      _calculatedInsights.add({'icon': '💡', 'text': 'Interest >60% of loan — consider shorter term'});
    }
    if (_depositPct >= 20.0) {
      _calculatedInsights.add({'icon': '✅', 'text': '20%+ deposit — best rate tier'});
    }

    _calculatedMonthly = monthly;
    _calculatedLoan = loan;
    _calculatedTotalRepaid = totalRepaid;
    _calculatedTotalInterest = totalInterest;
    _calculatedLtv = ltv;
    _calculatedBEvenYr = bEvenYr;
    _calculatedInterestRatio = totalRepaid > 0 ? (totalInterest / totalRepaid) * 100 : 0.0;
    _calculatedMonthlyInt = loan * r;
  }

  void _runCalc() {
    setState(() {
      _calculate();
      _hasCalculated = true;
      _isDirty = false;
    });
  }

  void _saveCalculation() async {
    if (_isDirty || !_hasCalculated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('⚠️ Calculate first, then save!',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final labelCtrl = TextEditingController(text: 'Europe Mortgage');
    final confirmed = await showDialog<bool>(
      context: context,
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
              'Saving: Price ${CurrencyFormatter.compact(_propValue, symbol: '€')} · Payment: ${CurrencyFormatter.compact(_calculatedMonthly, symbol: '€')}/mo',
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
                hintText: 'Label (e.g. Berlin Apartment)',
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
            child: const Text('Save',
                style: TextStyle(
                    fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final label = labelCtrl.text.trim().isNotEmpty
          ? labelCtrl.text.trim()
          : 'Europe Mortgage';
      final calc = SavedCalc.create(
        country: 'Europe',
        calcType: 'Mortgage Calc',
        inputs: {
          'propValue': _propValue,
          'depositPct': _depositPct,
          'termYears': _termYears.toDouble(),
          'rate': _rate,
          'mortgageType': _mortgageType == 'repayment'
              ? 0.0
              : _mortgageType == 'interest'
                  ? 1.0
                  : 2.0,
        },
        results: {
          'Payment': _calculatedMonthly,
          'Loan Amount': _calculatedLoan,
          'Total Repaid': _calculatedTotalRepaid,
          'Total Interest': _calculatedTotalInterest,
          'LTV': _calculatedLtv,
        },
        label: '$label - $_countryCode',
        currencyCode: 'EUR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Calculation saved!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            backgroundColor: widget.theme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _shareCalculation() {
    if (_isDirty || !_hasCalculated) return;
    final text = 'Mortgage: ${CurrencyFormatter.format(_calculatedMonthly, symbol: '€')}/mo | $_countryCode · $_termYears yr · ${_rate.toStringAsFixed(2)}% · ${CurrencyFormatter.format(_calculatedLoan, symbol: '€')} loan';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('📋 Copied description to clipboard!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: widget.theme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final cardBg = theme.getCardColor(context);
    final borderCol = theme.getBorderColor(context);
    final textColor = theme.getTextColor(context);
    final mutedText = theme.getMutedColor(context);

    final currentDeposit = _propValue * (_depositPct / 100);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sliderActiveColor = isDark ? theme.accentColor : theme.primaryColor;
    final sliderInactiveColor = (isDark ? theme.accentColor : theme.primaryColor).withValues(alpha: 0.15);

    // Live ECB rates context
    final ratesAsync = ref.watch(europeRatesProvider);
    final liveRates = ratesAsync.valueOrNull;
    final liveEcb = liveRates?.ecbRate.value ?? 4.00;
    final liveEu6m = liveRates?.euribor6m.value ?? 3.42;
    final isLive = liveRates?.isLive == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Live Rate Strip ──
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
              _rateStripItem('🇩🇪 10yr Fix', '${(liveEcb + 0.85).toStringAsFixed(2)}%', 'Germany', mutedText, textColor),
              Container(width: 0.5, height: 26, color: borderCol),
              _rateStripItem('🇫🇷 20yr Fix', '${(liveEcb + 0.60).toStringAsFixed(2)}%', 'France', mutedText, textColor),
              Container(width: 0.5, height: 26, color: borderCol),
              _rateStripItem('🇪🇸 Var', '${(liveEu6m + 1.10).toStringAsFixed(2)}%', 'Spain', mutedText, const Color(0xFFFF8A9A)),
              Container(width: 0.5, height: 26, color: borderCol),
              _rateStripItem('ECB${isLive ? ' 🟢' : ''}', '${liveEcb.toStringAsFixed(2)}%', 'Rate', mutedText, const Color(0xFFFFD700)),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Select Country Pills
        Text('SELECT COUNTRY', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: mutedText, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _countryPill('DE', '🇩🇪 Germany', 3.85),
              const SizedBox(width: 8),
              _countryPill('FR', '🇫🇷 France', 3.60),
              const SizedBox(width: 8),
              _countryPill('ES', '🇪🇸 Spain', 4.10),
              const SizedBox(width: 8),
              _countryPill('IT', '🇮🇹 Italy', 3.95),
              const SizedBox(width: 8),
              _countryPill('NL', '🇳🇱 Netherlands', 3.75),
              const SizedBox(width: 8),
              _countryPill('PT', '🇵🇹 Portugal', 3.50),
            ],
          ),
        ),
        const SizedBox(height: 16),

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
                            // Property Value
              _sliderHeader('Property Value', CurrencyFormatter.format(_propValue, symbol: '€')),
              Slider(
                value: _propValue,
                min: 50000,
                max: 2000000,
                divisions: 390,
                activeColor: sliderActiveColor,
                inactiveColor: sliderInactiveColor,
                onChanged: (v) {
                  setState(() {
                    _propValue = v;
                    _markDirty();
                  });
                },
              ),

              // Deposit
              _sliderHeader('Deposit / Down Payment', '${_depositPct.toInt()}%'),
              Slider(
                value: _depositPct,
                min: 5,
                max: 60,
                divisions: 55,
                activeColor: sliderActiveColor,
                inactiveColor: sliderInactiveColor,
                onChanged: (v) {
                  setState(() {
                    _depositPct = v;
                    _markDirty();
                  });
                },
              ),

              // Term
              _sliderHeader('Loan Term', '$_termYears years'),
              Slider(
                value: _termYears.toDouble(),
                min: 5,
                max: 30,
                divisions: 25,
                activeColor: sliderActiveColor,
                inactiveColor: sliderInactiveColor,
                onChanged: (v) {
                  setState(() {
                    _termYears = v.toInt();
                    _markDirty();
                  });
                },
              ),

              // Rate
              _sliderHeader('Interest Rate (Annual)', '${_rate.toStringAsFixed(2)}%'),
              Slider(
                value: _rate,
                min: 1,
                max: 10,
                divisions: 180,
                activeColor: sliderActiveColor,
                inactiveColor: sliderInactiveColor,
                onChanged: (v) {
                  setState(() {
                    _rate = v;
                    _markDirty();
                  });
                },
              ),

              // Mortgage Type
              const SizedBox(height: 8),
              Text('MORTGAGE TYPE', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: mutedText, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _typeButton('repayment', 'Repayment'),
                  const SizedBox(width: 4),
                  _typeButton('interest', 'Interest Only'),
                  const SizedBox(width: 4),
                  _typeButton('endowment', 'Endowment'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Primary Calculate button
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFCC00), Color(0xFFF59E0B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFCC00).withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: ElevatedButton(
            onPressed: _runCalc,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🧮', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  'Calculate Mortgage',
                  style: AppTextStyles.playfair(size: 15, color: const Color(0xFF1A0040), weight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Results Section (Calculate-on-demand pending overlay style)
        Stack(
          children: [
            Opacity(
              opacity: (!_hasCalculated || _isDirty) ? 0.35 : 1.0,
              child: IgnorePointer(
                ignoring: !_hasCalculated || _isDirty,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Result Panel Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: theme.headerGradient,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Monthly Payment', style: AppTextStyles.dmSans(size: 11, color: Colors.white70, weight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(_calculatedMonthly, symbol: '€'),
                            style: AppTextStyles.playfair(size: 38, color: const Color(0xFFFFCC00), weight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_countryCode · $_termYears yr · ${_rate.toStringAsFixed(2)}% · ${CurrencyFormatter.format(_calculatedLoan, symbol: '€')} loan',
                            style: AppTextStyles.dmSans(size: 11, color: Colors.white54),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _resultMiniBox('Total Repaid', CurrencyFormatter.format(_calculatedTotalRepaid, symbol: '€')),
                              _resultMiniBox('Total Interest', CurrencyFormatter.format(_calculatedTotalInterest, symbol: '€')),
                              _resultMiniBox('LTV Ratio', '${_calculatedLtv.toStringAsFixed(0)}%'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(height: 0.5, color: Colors.white12),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _saveCalculation,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFCC00).withValues(alpha: 0.18),
                                      border: Border.all(color: const Color(0xFFFFCC00).withValues(alpha: 0.45)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text('💾 Save Calculation', style: AppTextStyles.dmSans(size: 12, color: const Color(0xFFFFCC00), weight: FontWeight.w800)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _shareCalculation,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text('📤 Share', style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w800)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Smart Insights Badges List
                    if (_calculatedInsights.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _calculatedInsights.map((ins) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              border: Border.all(color: Colors.blue.shade200),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(ins['icon']!, style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(ins['text']!, style: AppTextStyles.dmSans(size: 10, color: Colors.blue.shade900, weight: FontWeight.w700)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Payment Breakdown Donut Card
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
                          Text('💰 Payment Breakdown', style: AppTextStyles.cardTitle(textColor)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              SizedBox(
                                width: 90,
                                height: 90,
                                child: CustomPaint(
                                  painter: DonutChartPainter(
                                    _calculatedLoan / math.max(1.0, _calculatedLoan + _calculatedTotalInterest + currentDeposit),
                                    _calculatedTotalInterest / math.max(1.0, _calculatedLoan + _calculatedTotalInterest + currentDeposit),
                                    currentDeposit / math.max(1.0, _calculatedLoan + _calculatedTotalInterest + currentDeposit),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${(_calculatedTotalRepaid > 0 ? (_calculatedLoan / _calculatedTotalRepaid * 100) : 0).toStringAsFixed(0)}%',
                                          style: AppTextStyles.playfair(size: 13, color: textColor, weight: FontWeight.w900),
                                        ),
                                        Text('Principal', style: AppTextStyles.dmSans(size: 8, color: mutedText)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  children: [
                                    _legendRow(const Color(0xFF003399), 'Principal', CurrencyFormatter.format(_calculatedLoan, symbol: '€')),
                                    const SizedBox(height: 6),
                                    _legendRow(const Color(0xFFFFCC00), 'Interest', CurrencyFormatter.format(_calculatedTotalInterest, symbol: '€')),
                                    const SizedBox(height: 6),
                                    _legendRow(const Color(0xFFE0E7FF), 'Deposit', CurrencyFormatter.format(currentDeposit, symbol: '€')),
                                  ],
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _statCell('Interest Ratio', '${_calculatedInterestRatio.toStringAsFixed(0)}%'),
                              _statCell('Monthly Int.', CurrencyFormatter.format(_calculatedMonthlyInt, symbol: '€')),
                              _statCell('Break-Even Yr', _calculatedBEvenYr != null ? 'Yr $_calculatedBEvenYr' : 'N/A'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amortization Analysis tabs (Bar Chart vs Balance Curve)
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('📈 Amortization Analysis', style: AppTextStyles.cardTitle(textColor)),
                              Row(
                                children: [
                                  _chartTabButton('bar', 'Bar'),
                                  const SizedBox(width: 4),
                                  _chartTabButton('balance', 'Curve'),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (_chartView == 'bar')
                            _buildAmortizationBars(_calculatedLoan, _calculatedMonthly, (_rate / 100) / 12)
                          else
                            _buildAmortizationCurve(_calculatedLoan, _calculatedMonthly, (_rate / 100) / 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Current Lender Rates
                    Text('🏦 CURRENT LENDER RATES', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: mutedText, letterSpacing: 1.0)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: (_lenders[_countryCode] ?? []).length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final lender = _lenders[_countryCode]![idx];
                          return Container(
                            width: 130,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderCol),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(lender['name'], style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textColor)),
                                const Spacer(),
                                Text('${lender['rate'].toStringAsFixed(2)}%', style: AppTextStyles.playfair(size: 18, color: theme.primaryColor, weight: FontWeight.w900)),
                                const SizedBox(height: 2),
                                Text(lender['type'], style: AppTextStyles.dmSans(size: 10, color: mutedText)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!_hasCalculated || _isDirty)
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: cardBg.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderCol),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          !_hasCalculated
                              ? '⬆️ Tap Calculate Mortgage to see your results'
                              : '🔄 Inputs changed. Tap Calculate Mortgage to refresh',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.dmSans(
                            size: 12,
                            weight: FontWeight.w700,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _countryPill(String code, String name, double rate) {
    final active = _countryCode == code;
    return GestureDetector(
      onTap: () {
        setState(() {
          _countryCode = code;
          _rate = rate;
          _markDirty();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? widget.theme.primaryColor : widget.theme.getCardColor(context),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: active ? widget.theme.primaryColor : widget.theme.getBorderColor(context),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          name,
          style: AppTextStyles.dmSans(
            size: 12,
            weight: FontWeight.w700,
            color: active ? widget.theme.accentColor : widget.theme.getMutedColor(context),
          ),
        ),
      ),
    );
  }

  Widget _sliderHeader(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: widget.theme.getMutedColor(context))),
          Text(value, style: AppTextStyles.playfair(
              size: 13,
              color: Theme.of(context).brightness == Brightness.dark
                  ? widget.theme.accentColor
                  : widget.theme.primaryColor,
              weight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _typeButton(String type, String label) {
    final active = _mortgageType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _mortgageType = type;
            _markDirty();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? widget.theme.primaryColor : widget.theme.getCardColor(context),
            border: Border.all(color: active ? widget.theme.primaryColor : widget.theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
              size: 11,
              weight: FontWeight.w700,
              color: active ? const Color(0xFFFFCC00) : widget.theme.getTextColor(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chartTabButton(String view, String label) {
    final active = _chartView == view;
    return GestureDetector(
      onTap: () => setState(() => _chartView = view),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? widget.theme.primaryColor : widget.theme.getBgColor(context),
          border: Border.all(color: active ? widget.theme.primaryColor : widget.theme.getBorderColor(context)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.w700,
            color: active ? const Color(0xFFFFCC00) : widget.theme.getTextColor(context),
          ),
        ),
      ),
    );
  }

  Widget _resultMiniBox(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 9, color: Colors.white60)),
            const SizedBox(height: 2),
            Text(value, style: AppTextStyles.playfair(size: 12, color: Colors.white, weight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _legendRow(Color color, String label, String value) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
        const Spacer(),
        Text(value, style: AppTextStyles.playfair(size: 12, weight: FontWeight.w800, color: widget.theme.getTextColor(context))),
      ],
    );
  }

  Widget _statCell(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: widget.theme.getBgColor(context),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 9, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 2),
            Text(value, style: AppTextStyles.playfair(
                size: 13,
                color: Theme.of(context).brightness == Brightness.dark
                    ? widget.theme.accentColor
                    : widget.theme.primaryColor,
                weight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _rateStripItem(String label, String val, String note, Color mutedText, Color valColor) {
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

  Widget _buildAmortizationBars(double loan, double monthly, double r) {
    final List<int> checkYears = [5, 10, 15, 20, 25, 30].where((y) => y <= _termYears).toList();
    final maxPay = monthly * 12;
    double bal = loan;
    final List<Widget> bars = [];

    for (final yr in checkYears) {
      double paidP = 0;
      double paidI = 0;
      for (int m = 0; m < 12; m++) {
        final interest = bal * r;
        final principal = monthly - interest;
        paidI += interest;
        paidP += principal;
        bal = math.max(0, bal - principal);
      }
      final double pW = maxPay > 0 ? (paidP / maxPay) : 0;
      final double iW = maxPay > 0 ? (paidI / maxPay) : 0;

      bars.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              SizedBox(width: 34, child: Text('Yr $yr', style: AppTextStyles.dmSans(size: 10, color: widget.theme.getMutedColor(context)))),
              Expanded(
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(5)),
                  clipBehavior: Clip.hardEdge,
                  child: Row(
                    children: [
                      Flexible(flex: (pW * 100).round(), child: Container(color: const Color(0xFF003399))),
                      Flexible(flex: (iW * 100).round(), child: Container(color: const Color(0xFFFFCC00))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                CurrencyFormatter.format(paidP + paidI, symbol: '€'),
                style: AppTextStyles.playfair(
                    size: 10,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? widget.theme.accentColor
                        : widget.theme.primaryColor,
                    weight: FontWeight.w800),
              )
            ],
          ),
        ),
      );
    }
    return Column(children: bars);
  }

  Widget _buildAmortizationCurve(double loan, double monthly, double r) {
    return SizedBox(
      height: 140,
      width: double.infinity,
      child: CustomPaint(
        painter: AmortizationCurvePainter(
          loan: loan,
          monthly: monthly,
          r: r,
          termYears: _termYears,
          theme: widget.theme,
          isDark: Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final double pPct, iPct, dPct;
  DonutChartPainter(this.pPct, this.iPct, this.dPct);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -math.pi / 2;

    // Draw principal arc
    paint.color = const Color(0xFF003399);
    final sweepP = pPct * 2 * math.pi;
    canvas.drawArc(rect, startAngle, sweepP, false, paint);
    startAngle += sweepP;

    // Draw interest arc
    paint.color = const Color(0xFFFFCC00);
    final sweepI = iPct * 2 * math.pi;
    canvas.drawArc(rect, startAngle, sweepI, false, paint);
    startAngle += sweepI;

    // Draw deposit arc
    paint.color = const Color(0xFFE0E7FF);
    final sweepD = dPct * 2 * math.pi;
    canvas.drawArc(rect, startAngle, sweepD, false, paint);
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) =>
      oldDelegate.pPct != pPct || oldDelegate.iPct != iPct || oldDelegate.dPct != dPct;
}

class AmortizationCurvePainter extends CustomPainter {
  final double loan;
  final double monthly;
  final double r;
  final int termYears;
  final CountryTheme theme;
  final bool isDark;

  AmortizationCurvePainter({
    required this.loan,
    required this.monthly,
    required this.r,
    required this.termYears,
    required this.theme,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round
      ..color = isDark ? theme.accentColor : const Color(0xFF003399);

    final fillPaint = Paint()
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final n = termYears * 12;
    final double maxVal = loan;
    final w = size.width;
    final h = size.height;

    double bal = loan;
    final List<Offset> points = [];

    points.add(Offset(0, h * (1 - bal / maxVal)));
    for (int m = 1; m <= n; m++) {
      final interest = bal * r;
      bal = math.max(0, bal - (monthly - interest));
      final double x = (m / n) * w;
      final double y = h * (1 - bal / maxVal);
      points.add(Offset(x, y));
    }

    path.moveTo(points.first.dx, points.first.dy);
    fillPath.moveTo(0, h);
    fillPath.lineTo(points.first.dx, points.first.dy);

    for (final pt in points) {
      path.lineTo(pt.dx, pt.dy);
      fillPath.lineTo(pt.dx, pt.dy);
    }

    fillPath.lineTo(w, h);
    fillPath.close();

    // Fill area under curve
    final curveColor = isDark ? theme.accentColor : const Color(0xFF003399);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [curveColor.withValues(alpha: 0.25), curveColor.withValues(alpha: 0.02)],
    );
    fillPaint.shader = gradient.createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, fillPaint);

    // Draw lines
    canvas.drawPath(path, paint);

    // Draw axis lines
    final axisPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;
    for (int i = 1; i < 4; i++) {
      final y = h * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(w, y), axisPaint);
    }
  }

  @override
  bool shouldRepaint(covariant AmortizationCurvePainter oldDelegate) =>
      oldDelegate.loan != loan || oldDelegate.monthly != monthly || oldDelegate.r != r || oldDelegate.termYears != termYears;
}
