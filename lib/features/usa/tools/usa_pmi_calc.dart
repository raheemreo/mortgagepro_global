// lib/features/usa/tools/usa_pmi_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAPmiCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const USAPmiCalc({super.key, this.theme = CountryThemes.usa});

  @override
  ConsumerState<USAPmiCalc> createState() => _USAPmiCalcState();
}

class _USAPmiCalcState extends ConsumerState<USAPmiCalc> {
  double _price = 450000;
  double _downPct = 10;
  double _creditScore = 720;
  int _loanTerm = 30;

  bool _showResults = false;
  bool _isCalcDirty = true;
  bool _calculating = false;

  final Map<String, Map<String, double>> _pmiTable = {
    '95': {'low': 1.25, 'mid': 0.78, 'high': 0.55},
    '90': {'low': 0.85, 'mid': 0.58, 'high': 0.38},
    '85': {'low': 0.65, 'mid': 0.40, 'high': 0.24},
    '80': {'low': 0.35, 'mid': 0.22, 'high': 0.17}
  };

  void _markDirty() {
    if (!_isCalcDirty) {
      setState(() {
        _isCalcDirty = true;
      });
    }
  }

  void _resetInputs() {
    setState(() {
      _price = 450000;
      _downPct = 10;
      _creditScore = 720;
      _loanTerm = 30;
      _showResults = false;
      _isCalcDirty = true;
    });
  }

  // Unused: _loadSavedCalculation removed to resolve analyzer warnings.

  void _calculate() async {
    setState(() {
      _calculating = true;
    });
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() {
      _calculating = false;
      _showResults = true;
      _isCalcDirty = false;
    });
  }

  void _saveCalculation() async {
    final downAmt = _price * _downPct / 100;
    final loanAmt = _price - downAmt;
    final ltv = (loanAmt / _price) * 100;

    String scoreBand = 'mid';
    if (_creditScore < 680) {
      scoreBand = 'low';
    } else if (_creditScore >= 760) {
      scoreBand = 'high';
    }

    String? ltvBand;
    if (ltv > 95) {
      ltvBand = '95';
    } else if (ltv > 90) {
      ltvBand = '95';
    } else if (ltv > 85) {
      ltvBand = '90';
    } else if (ltv > 80) {
      ltvBand = '85';
    } else if (ltv > 78) {
      ltvBand = '80';
    }

    double pmiRate = 0.0;
    if (ltvBand != null && ltv > 80.0) {
      pmiRate = _pmiTable[ltvBand]?[scoreBand] ?? 0.0;
    }

    final pmiAnnualAmt = loanAmt * pmiRate / 100;
    final pmiMonthlyAmt = pmiAnnualAmt / 12;

    final labelCtrl = TextEditingController(text: 'PMI Calculator');
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
              'Saving: Monthly PMI: ${CurrencyFormatter.compact(pmiMonthlyAmt, symbol: r'$')}/mo · LTV: ${ltv.toStringAsFixed(1)}%',
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
                hintText: 'Label (e.g. My PMI Calc)',
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
          : 'PMI Calculator';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'PMI Calculator',
        inputs: {
          'Price': _price,
          'DownPct': _downPct,
          'CreditScore': _creditScore,
          'LoanTermYrs': _loanTerm.toDouble(),
        },
        results: {
          'Monthly PMI': pmiMonthlyAmt,
          'Annual PMI': pmiAnnualAmt,
          'LTV Ratio': ltv,
          'Equity Needed': max(0.0, loanAmt - (_price * 0.80)),
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

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final cardColor = theme.getCardColor(context);
    final textColor = theme.getTextColor(context);
    final mutedColor = theme.getMutedColor(context);
    final borderColor = theme.getBorderColor(context);

    // Compute active calculation
    final downAmt = _price * _downPct / 100;
    final loanAmt = _price - downAmt;
    final ltv = (loanAmt / _price) * 100;

    String scoreBand = 'mid';
    if (_creditScore < 680) {
      scoreBand = 'low';
    } else if (_creditScore >= 760) {
      scoreBand = 'high';
    }

    String? ltvBand;
    if (ltv > 95) {
      ltvBand = '95';
    } else if (ltv > 90) {
      ltvBand = '95';
    } else if (ltv > 85) {
      ltvBand = '90';
    } else if (ltv > 80) {
      ltvBand = '85';
    } else if (ltv > 78) {
      ltvBand = '80';
    }

    double pmiRate = 0.0;
    if (ltvBand != null && ltv > 80.0) {
      pmiRate = _pmiTable[ltvBand]?[scoreBand] ?? 0.0;
    }

    final pmiAnnualAmt = loanAmt * pmiRate / 100;
    final pmiMonthlyAmt = pmiAnnualAmt / 12;

    // Equity needed to reach 80% LTV
    final targetLoan = _price * 0.80;
    final equityNeeded = max(0.0, loanAmt - targetLoan);

    // Amortization loop to reach 80% LTV
    const monthlyRate = 0.0682 / 12;
    double balance = loanAmt;
    int months = 0;
    final nPayments = _loanTerm * 12;
    final monthlyPayment = loanAmt * (monthlyRate * pow(1 + monthlyRate, nPayments)) / (pow(1 + monthlyRate, nPayments) - 1);
    while (balance > targetLoan && months < nPayments) {
      balance = balance * (1 + monthlyRate) - monthlyPayment;
      months++;
    }
    final double yearsToCancel = months / 12.0;
    final totalPMIPaid = pmiMonthlyAmt * months;

    // Estimated Cancel Date string
    final cancelDate = DateTime.now().add(Duration(days: (months * 30.4368).round()));
    const monthsStr = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final cancelStr = '${monthsStr[cancelDate.month - 1]} ${cancelDate.year}';

    // Rate strip values
    const rateStats = [
      {'label': 'PMI Low', 'value': '0.20%', 'note': 'Excellent LTV'},
      {'label': 'PMI Avg', 'value': '0.58%', 'note': 'National Avg', 'up': true},
      {'label': 'PMI High', 'value': '1.86%', 'note': 'High Risk LTV', 'rd': true},
      {'label': 'Removed At', 'value': '80% LTV', 'note': 'HPA 1998'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header rate strip
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F2547) : const Color(0xFFE2ECF7),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: rateStats.map((stat) {
              final idx = rateStats.indexOf(stat);
              final isLast = idx == rateStats.length - 1;
              Color valCol = textColor;
              if (stat['up'] == true) {
                valCol = const Color(0xFF10B981);
              } else if (stat['rd'] == true) {
                valCol = const Color(0xFFEF4444);
              }
              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(
                            right: BorderSide(
                                color: textColor.withValues(alpha: 0.12),
                                width: 1),
                          ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        stat['label'] as String,
                        style: AppTextStyles.dmSans(
                            size: 8.5, weight: FontWeight.w700, color: mutedColor),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            stat['value'] as String,
                            style: AppTextStyles.playfair(
                              size: 13,
                              weight: FontWeight.w800,
                              color: valCol,
                            ),
                          ),
                          if (stat['up'] == true)
                            const Text('↑', style: TextStyle(fontSize: 8, color: Color(0xFF10B981))),
                          if (stat['rd'] == true)
                            const Text('↓', style: TextStyle(fontSize: 8, color: Color(0xFFEF4444))),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        stat['note'] as String,
                        style: AppTextStyles.dmSans(
                            size: 7.5, color: mutedColor),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Main results hero panel
        Text(
          'Your PMI Estimate',
          style: AppTextStyles.playfair(
              size: 13, weight: FontWeight.w700, color: textColor),
        ),
        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B1D3A).withValues(alpha: 0.25),
                blurRadius: 15,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MONTHLY PMI PREMIUM',
                style: AppTextStyles.dmSans(
                    size: 8,
                    weight: FontWeight.w700,
                    color: Colors.white70,
                    letterSpacing: 0.6),
              ),
              const SizedBox(height: 4),
              Text(
                pmiRate == 0 ? '\$0' : CurrencyFormatter.format(pmiMonthlyAmt, symbol: r'$'),
                style: AppTextStyles.playfair(
                    size: 32, weight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                pmiRate == 0
                    ? '✅ No PMI — LTV ≤ 80%! You\'re in the clear.'
                    : '${pmiRate.toStringAsFixed(2)}%/yr · Borrower-Paid (BPMI) · Cancels in ~${yearsToCancel.toStringAsFixed(1)} yrs',
                style: AppTextStyles.dmSans(
                    size: 9.5, color: Colors.white.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildHeroBottomBox('Annual PMI', pmiRate == 0 ? '\$0' : CurrencyFormatter.format(pmiAnnualAmt, symbol: r'$')),
                  const SizedBox(width: 8),
                  _buildHeroBottomBox('LTV Ratio', '${ltv.toStringAsFixed(1)}%'),
                  const SizedBox(width: 8),
                  _buildHeroBottomBox('Equity Needed', CurrencyFormatter.format(equityNeeded, symbol: r'$')),
                ],
              )
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Inputs Card
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Loan Details',
              style: AppTextStyles.playfair(
                  size: 13, weight: FontWeight.w700, color: textColor),
            ),
            GestureDetector(
              onTap: _resetInputs,
              child: Text(
                'Reset',
                style: AppTextStyles.dmSans(
                    size: 11, color: primaryColor, weight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Purchase Price Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Home Purchase Price'.toUpperCase(),
                      style: AppTextStyles.dmSans(
                          size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
                  Text(CurrencyFormatter.format(_price, symbol: r'$'),
                      style: AppTextStyles.playfair(
                          size: 13, weight: FontWeight.w800, color: primaryColor)),
                ],
              ),
              Slider(
                value: _price,
                min: 100000,
                max: 1500000,
                divisions: 280,
                activeColor: primaryColor,
                inactiveColor: Colors.grey.withValues(alpha: 0.2),
                onChanged: (val) {
                  setState(() {
                    _price = val;
                    _markDirty();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('\$100K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$500K', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$1M', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('\$1.5M', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                ],
              ),
              const SizedBox(height: 16),

              // Down Payment % Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Down Payment %'.toUpperCase(),
                      style: AppTextStyles.dmSans(
                          size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
                  Text('${_downPct.toStringAsFixed(1)}%',
                      style: AppTextStyles.playfair(
                          size: 13, weight: FontWeight.w800, color: primaryColor)),
                ],
              ),
              Slider(
                value: _downPct,
                min: 3,
                max: 19,
                divisions: 32,
                activeColor: primaryColor,
                inactiveColor: Colors.grey.withValues(alpha: 0.2),
                onChanged: (val) {
                  setState(() {
                    _downPct = val;
                    _markDirty();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('3%', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('5%', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('10%', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('15%', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('19%', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                ],
              ),
              const SizedBox(height: 16),

              // Credit Score Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Credit Score'.toUpperCase(),
                      style: AppTextStyles.dmSans(
                          size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
                  Text('${_creditScore.toInt()}',
                      style: AppTextStyles.playfair(
                          size: 13, weight: FontWeight.w800, color: primaryColor)),
                ],
              ),
              Slider(
                value: _creditScore,
                min: 620,
                max: 850,
                divisions: 23,
                activeColor: primaryColor,
                inactiveColor: Colors.grey.withValues(alpha: 0.2),
                onChanged: (val) {
                  setState(() {
                    _creditScore = val;
                    _markDirty();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('620', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('680', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('720', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('780', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                  Text('850', style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
                ],
              ),
              const SizedBox(height: 16),

              // Loan Term Buttons
              Text('Loan Term'.toUpperCase(),
                  style: AppTextStyles.dmSans(
                      size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTermChoiceBtn('30 yr', 30),
                  const SizedBox(width: 8),
                  _buildTermChoiceBtn('20 yr', 20),
                  const SizedBox(width: 8),
                  _buildTermChoiceBtn('15 yr', 15),
                ],
              ),
              const SizedBox(height: 16),

              // Action buttons row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _calculate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB91C1C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      child: _calculating
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Calculate PMI',
                              style: AppTextStyles.playfair(
                                  size: 13, weight: FontWeight.w800),
                            ),
                    ),
                  ),
                  if (_showResults && !_isCalcDirty) ...[
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _saveCalculation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cardColor,
                        foregroundColor: const Color(0xFFB91C1C),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFB91C1C), width: 2),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('💾', style: TextStyle(fontSize: 19)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_showResults && !_isCalcDirty) ...[
          // Composition Donut Card
          Text(
            'Loan Composition',
            style: AppTextStyles.playfair(
                size: 13, weight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                // Custom Donut graphic
                SizedBox(
                  height: 108,
                  width: 108,
                  child: CustomPaint(
                    painter: _PmiDonutPainter(
                      ltv: ltv,
                      textColor: textColor,
                      mutedColor: mutedColor,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                // Legend
                Expanded(
                  child: Column(
                    children: [
                      _buildLegendRow('Loan Amount', loanAmt, const Color(0xFF1B3F72)),
                      const SizedBox(height: 9),
                      _buildLegendRow('Down Payment', downAmt, const Color(0xFFD97706)),
                      const SizedBox(height: 9),
                      _buildLegendRow('Est. Total PMI', pmiRate == 0 ? 0.0 : totalPMIPaid, const Color(0xFFB91C1C), prefixText: '~'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // PMI Rate Table
          Text(
            'PMI Rate Table',
            style: AppTextStyles.playfair(
                size: 13, weight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1.2),
                1: FlexColumnWidth(1.0),
                2: FlexColumnWidth(1.0),
                3: FlexColumnWidth(1.0),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)]),
                  ),
                  children: [
                    _buildTableHeaderCell('LTV Range'),
                    _buildTableHeaderCell('620–679'),
                    _buildTableHeaderCell('680–759'),
                    _buildTableHeaderCell('760+'),
                  ],
                ),
                _buildTableRow('row-95', '95–97% LTV', '1.25%', '0.78%', '0.55%', const Color(0xFFB91C1C), ltvBand == '95'),
                _buildTableRow('row-90', '90–95% LTV', '0.85%', '0.58%', '0.38%', const Color(0xFFD97706), ltvBand == '90'),
                _buildTableRow('row-85', '85–90% LTV', '0.65%', '0.40%', '0.24%', const Color(0xFFCA8A04), ltvBand == '85'),
                _buildTableRow('row-80', '80–85% LTV', '0.35%', '0.22%', '0.17%', const Color(0xFF15803D), ltvBand == '80'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // PMI Removal Timeline Card
          Text(
            'PMI Removal Timeline',
            style: AppTextStyles.playfair(
                size: 13, weight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto-Cancellation Date',
                          style: AppTextStyles.playfair(
                              size: 12.5, weight: FontWeight.w800, color: textColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Per Homeowners Protection Act of 1998',
                          style: AppTextStyles.dmSans(size: 9.5, color: mutedColor),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            pmiRate == 0 ? 'N/A' : '~$cancelStr',
                            style: AppTextStyles.playfair(
                                size: 15.5, weight: FontWeight.w800, color: const Color(0xFFB91C1C)),
                          ),
                          Text(
                            pmiRate == 0 ? 'LTV ≤ 80%' : 'Estimated',
                            style: AppTextStyles.dmSans(size: 8, color: const Color(0xFF991B1B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.getBgColor(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('📋 Request Cancellation',
                              style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: textColor)),
                          Text(
                            '80% LTV · ~${CurrencyFormatter.format(equityNeeded, symbol: r'$')} equity',
                            style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: const Color(0xFF1D4ED8)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('⚡ Auto-Cancel',
                              style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: textColor)),
                          Text('78% LTV (auto)',
                              style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: const Color(0xFF15803D))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('💰 Total PMI Paid',
                              style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: textColor)),
                          Text(
                            pmiRate == 0 ? '\$0' : '~${CurrencyFormatter.format(totalPMIPaid, symbol: r'$')}',
                            style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: const Color(0xFFB91C1C)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // PMI Types explained
        Text(
          'PMI Types Explained',
          style: AppTextStyles.playfair(
              size: 13, weight: FontWeight.w700, color: textColor),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => context.push('/usa/pmi-bpmi'),
          child: _buildInfoCard('💳', 'BPMI – Borrower-Paid PMI', 'Monthly premium · cancellable at 80% LTV · most common', textColor, mutedColor, borderColor, cardColor),
        ),
        GestureDetector(
          onTap: () => context.push('/usa/pmi-lpmi'),
          child: _buildInfoCard('🏦', 'LPMI – Lender-Paid PMI', 'Higher rate, no monthly premium · not cancellable', textColor, mutedColor, borderColor, cardColor),
        ),
        GestureDetector(
          onTap: () => context.push('/usa/pmi-spmi'),
          child: _buildInfoCard('💵', 'SPMI – Single Premium', 'One upfront payment at closing · avg 1.0–3.0%', textColor, mutedColor, borderColor, cardColor),
        ),
        GestureDetector(
          onTap: () => context.push('/usa/pmi-split'),
          child: _buildInfoCard('🔀', 'Split Premium PMI', 'Partial upfront + reduced monthly · flexible option', textColor, mutedColor, borderColor, cardColor),
        ),
        const SizedBox(height: 20),

        // Ways to Avoid PMI
        Text(
          'Ways to Avoid PMI',
          style: AppTextStyles.playfair(
              size: 13, weight: FontWeight.w700, color: textColor),
        ),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.25,
          children: [
            GestureDetector(
              onTap: () => context.push('/tool/usa/downpayment'),
              child: _buildAvoidCard('💰', '20% Down Payment', 'Avoid PMI entirely', 'Best Option', const Color(0xFFF0FDF4), const Color(0xFF15803D)),
            ),
            GestureDetector(
              onTap: () => context.push('/tool/usa/piggyback'),
              child: _buildAvoidCard('🔀', 'Piggyback Loan', '80/10/10 structure', 'No PMI', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
            ),
            GestureDetector(
              onTap: () => context.push('/tool/usa/va'),
              child: _buildAvoidCard('🎖️', 'VA Loan', '0% down · zero PMI', null, null, null, gold: true),
            ),
            GestureDetector(
              onTap: () => context.push('/tool/usa/usda'),
              child: _buildAvoidCard('🌾', 'USDA Loan', 'Guarantee fee only', null, null, null, standardCard: true),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvoidCard(String icon, String title, String desc, String? badgeText,
      Color? badgeBg, Color? badgeTextCol,
      {bool gold = false, bool standardCard = false}) {
    final theme = widget.theme;

    Color bg;
    Color titleCol = Colors.white;
    Color descCol = Colors.white70;

    if (gold) {
      bg = const Color(0xFFD97706);
    } else if (standardCard) {
      bg = theme.getCardColor(context);
      titleCol = theme.getTextColor(context);
      descCol = theme.getMutedColor(context);
    } else {
      bg = theme.primaryColor;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: bg == theme.getCardColor(context) ? Border.all(color: theme.getBorderColor(context)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: bg == theme.getCardColor(context) ? 0.08 : 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 6),
          Text(title,
              style: AppTextStyles.playfair(
                  size: 12.5, weight: FontWeight.w800, color: titleCol)),
          Text(desc,
              style: AppTextStyles.dmSans(
                  size: 8.5, color: descCol)),
          if (badgeText != null) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeBg ?? Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(badgeText,
                  style: AppTextStyles.dmSans(
                      size: 8, weight: FontWeight.w700, color: badgeTextCol ?? Colors.white)),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Text(
        text,
        style: AppTextStyles.dmSans(
            size: 9, weight: FontWeight.w800, color: Colors.white70),
        textAlign: text == 'LTV Range' ? TextAlign.left : TextAlign.center,
      ),
    );
  }

  TableRow _buildTableRow(String id, String ltvLabel, String val1, String val2, String val3, Color dotColor, bool active) {
    final textColor = widget.theme.getTextColor(context);
    final mutedColor = widget.theme.getMutedColor(context);
    final borderColor = widget.theme.getBorderColor(context);

    return TableRow(
      decoration: BoxDecoration(
        color: active ? const Color(0xFFEFF6FF) : Colors.transparent,
        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    text: ltvLabel,
                    style: AppTextStyles.dmSans(
                      size: 9.5,
                      weight: active ? FontWeight.w800 : FontWeight.w600,
                      color: active ? const Color(0xFF1D4ED8) : mutedColor,
                    ),
                    children: active
                        ? [
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDBEAFE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('Active',
                                    style: AppTextStyles.dmSans(size: 7, weight: FontWeight.w900, color: const Color(0xFF1D4ED8))),
                              ),
                            )
                          ]
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Text(val1,
              style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: textColor),
              textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Text(val2,
              style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: textColor),
              textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Text(val3,
              style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: textColor),
              textAlign: TextAlign.center),
        ),
      ],
    );
  }

  Widget _buildLegendRow(String name, double val, Color color, {String prefixText = ''}) {
    final textColor = widget.theme.getTextColor(context);
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
        Text(name, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: textColor)),
        const Spacer(),
        Text(
          '$prefixText${CurrencyFormatter.format(val, symbol: r'$')}',
          style: AppTextStyles.playfair(size: 11.5, weight: FontWeight.w800, color: textColor),
        ),
      ],
    );
  }

  Widget _buildTermChoiceBtn(String label, int yrs) {
    final sel = _loanTerm == yrs;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _loanTerm = yrs;
            _markDirty();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFFEFF6FF) : widget.theme.getBgColor(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? const Color(0xFF1B3F72) : widget.theme.getBorderColor(context), width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
                size: 12, weight: sel ? FontWeight.w800 : FontWeight.w700, color: sel ? const Color(0xFF1B3F72) : widget.theme.getMutedColor(context)),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBottomBox(String label, String val) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label,
                style: AppTextStyles.dmSans(
                    size: 8.5, color: Colors.white54, weight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(val,
                style: AppTextStyles.playfair(
                    size: 12.5,
                    weight: FontWeight.w800,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String icon, String title, String subtitle, Color textColor,
      Color mutedColor, Color borderColor, Color cardColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: widget.theme.getBgColor(context),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.playfair(
                      size: 12, weight: FontWeight.w800, color: textColor),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.dmSans(size: 9, color: mutedColor),
                ),
              ],
            ),
          ),
          Text('›', style: TextStyle(fontSize: 16, color: mutedColor)),
        ],
      ),
    );
  }
}

// Custom Painter for PMI LTV Donut Composition
class _PmiDonutPainter extends CustomPainter {
  final double ltv;
  final Color textColor;
  final Color mutedColor;

  const _PmiDonutPainter({
    required this.ltv,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 6;
    const strokeWidth = 10.0;

    // Track circle: down payment part (100% of circle)
    final downPaint = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, downPaint);

    // Loan amount part (ltv% of circle)
    final loanPaint = Paint()
      ..color = const Color(0xFF1B3F72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (ltv / 100.0) * 2 * pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      loanPaint,
    );

    // Draw central text
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: '${ltv.toStringAsFixed(1)}%',
      style: AppTextStyles.playfair(size: 13, weight: FontWeight.w800, color: textColor),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2 - 4));

    textPainter.text = TextSpan(
      text: 'LTV',
      style: AppTextStyles.dmSans(size: 7.5, color: mutedColor, weight: FontWeight.w700),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2 + 8));
  }

  @override
  bool shouldRepaint(covariant _PmiDonutPainter oldDelegate) {
    return oldDelegate.ltv != ltv ||
        oldDelegate.textColor != textColor ||
        oldDelegate.mutedColor != mutedColor;
  }
}

