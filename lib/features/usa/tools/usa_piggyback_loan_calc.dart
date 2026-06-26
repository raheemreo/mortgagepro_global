// lib/features/usa/tools/usa_piggyback_loan_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAPiggybackLoanCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;
  const USAPiggybackLoanCalc({
    super.key,
    this.theme = CountryThemes.usa,
    this.savedCalc,
  });

  @override
  ConsumerState<USAPiggybackLoanCalc> createState() => _USAPiggybackLoanCalcState();
}

class _USAPiggybackLoanCalcState extends ConsumerState<USAPiggybackLoanCalc> {
  // Inputs & State
  double _price = 450000;
  double _downPct = 10;
  double _rate1 = 6.82;
  double _rate2 = 8.65;
  double _fico = 720;
  String _structure = '80/10/10';

  bool _isCalcDirty = false;

  final Map<String, Map<String, double>> _pmiTable = {
    '95': {'low': 1.25, 'mid': 0.78, 'high': 0.55},
    '90': {'low': 0.85, 'mid': 0.58, 'high': 0.38},
    '85': {'low': 0.65, 'mid': 0.40, 'high': 0.24},
    '80': {'low': 0.35, 'mid': 0.22, 'high': 0.17}
  };

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      _loadSaved(widget.savedCalc!);
    }
  }

  void _loadSaved(SavedCalc calc) {
    setState(() {
      _price = (calc.inputs['Price'] ?? 450000.0).toDouble();
      _downPct = (calc.inputs['DownPct'] ?? 10.0).toDouble();
      _rate1 = (calc.inputs['Rate1'] ?? 6.82).toDouble();
      _rate2 = (calc.inputs['Rate2'] ?? 8.65).toDouble();
      _fico = (calc.inputs['CreditScore'] ?? 720.0).toDouble();
      final structVal = (calc.inputs['Structure'] ?? 0.0).toDouble();
      if (structVal == 1.0) {
        _structure = '80/15/5';
      } else if (structVal == 2.0) {
        _structure = '80/5/15';
      } else {
        _structure = '80/10/10';
      }
      _isCalcDirty = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded saved calculation!',
                style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: widget.theme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void _resetInputs() {
    setState(() {
      _price = 450000;
      _downPct = 10;
      _rate1 = 6.82;
      _rate2 = 8.65;
      _fico = 720;
      _structure = '80/10/10';
      _isCalcDirty = false;
    });
  }

  void _markDirty() {
    if (!_isCalcDirty) {
      setState(() {
        _isCalcDirty = true;
      });
    }
  }

  double _monthlyPayment(double principal, double annualRatePercent, int termYears) {
    if (principal <= 0) return 0;
    final r = annualRatePercent / 100 / 12;
    final n = termYears * 12;
    if (r == 0) return principal / n;
    return principal * (r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
  }

  String _getScoreBand(double score) {
    if (score < 680) return 'low';
    if (score < 760) return 'mid';
    return 'high';
  }

  String _fmt(double n) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String str = n.round().toString();
    return '\$${str.replaceAllMapped(formatter, (Match m) => '${m[1]},')}';
  }

  String _fmtK(double n) {
    if (n >= 1000) {
      return '\$${(n / 1000).toStringAsFixed(0)}K';
    } else {
      return '\$${n.round()}';
    }
  }

  void _selectStructure(String s) {
    setState(() {
      _structure = s;
      if (s == '80/15/5') {
        _downPct = 5;
      } else if (s == '80/10/10') {
        _downPct = 10;
      } else if (s == '80/5/15') {
        _downPct = 15;
      }
      _isCalcDirty = false;
    });
  }

  Map<String, dynamic> _computeResults() {
    final downAmt = _price * _downPct / 100;
    final firstLoanAmt = _price * 0.8;
    final secondLoanAmt = max(0.0, _price - firstLoanAmt - downAmt);

    final pmt1 = _monthlyPayment(firstLoanAmt, _rate1, 30);
    final pmt2 = secondLoanAmt > 0 ? _monthlyPayment(secondLoanAmt, _rate2, 10) : 0.0;
    final totalPmt = pmt1 + pmt2;

    final convLtv = (1 - _downPct / 100) * 100;
    String band = _getScoreBand(_fico);

    double pmiRate = 0.0;
    if (convLtv > 90) {
      pmiRate = _pmiTable['95']?[band] ?? 0.0;
    } else if (convLtv > 85) {
      pmiRate = _pmiTable['90']?[band] ?? 0.0;
    } else if (convLtv > 80) {
      pmiRate = _pmiTable['85']?[band] ?? 0.0;
    } else if (convLtv > 78) {
      pmiRate = _pmiTable['80']?[band] ?? 0.0;
    }

    final convLoanAmt = _price * (1 - _downPct / 100);
    final pmiMonthly = convLoanAmt * pmiRate / 100 / 12;
    final convMonthlyBase = _monthlyPayment(convLoanAmt, _rate1, 30);
    final convPmt = convMonthlyBase + pmiMonthly;

    final targetBal = _price * 0.8;
    final mr = _rate1 / 100 / 12;
    double bal = convLoanAmt;
    int months = 0;
    while (bal > targetBal && months < 360) {
      bal = bal * (1 + mr) - convMonthlyBase;
      months++;
    }
    final totalPmiSaved = pmiMonthly * months;

    final total2ndPaid = pmt2 * 120;
    final total2ndInterest = max(0.0, total2ndPaid - secondLoanAmt);

    final piggybackTotal10 = totalPmt * 120;
    final convTotal10 = convPmt * 120;
    final net10 = convTotal10 - piggybackTotal10;

    final breakeven = pmiMonthly > 0 ? (total2ndInterest / pmiMonthly).round() : 0;

    return {
      'downAmt': downAmt,
      'firstLoanAmt': firstLoanAmt,
      'secondLoanAmt': secondLoanAmt,
      'pmt1': pmt1,
      'pmt2': pmt2,
      'totalPmt': totalPmt,
      'convLtv': convLtv,
      'pmiRate': pmiRate,
      'convLoanAmt': convLoanAmt,
      'pmiMonthly': pmiMonthly,
      'convMonthlyBase': convMonthlyBase,
      'convPmt': convPmt,
      'months': months,
      'totalPmiSaved': totalPmiSaved,
      'total2ndInterest': total2ndInterest,
      'net10': net10,
      'breakeven': breakeven,
    };
  }

  void _saveCalculation() async {
    final res = _computeResults();
    final pmt1 = res['pmt1'] as double;
    final pmt2 = res['pmt2'] as double;
    final pmiMonthly = res['pmiMonthly'] as double;
    final totalPmiSaved = res['totalPmiSaved'] as double;
    final net10 = res['net10'] as double;

    final labelCtrl = TextEditingController(text: 'Piggyback Loan');
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
              'Saving: Combined Payment: ${_fmt(pmt1 + pmt2)}/mo · Structure: $_structure · Price: ${_fmt(_price)}',
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
                hintText: 'Label (e.g. My Piggyback Calc)',
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
          : 'Piggyback Loan';

      double structVal = 0.0;
      if (_structure == '80/15/5') {
        structVal = 1.0;
      } else if (_structure == '80/5/15') {
        structVal = 2.0;
      }

      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'Piggyback Loan',
        inputs: {
          'Price': _price,
          'DownPct': _downPct,
          'Rate1': _rate1,
          'Rate2': _rate2,
          'CreditScore': _fico,
          'Structure': structVal,
        },
        results: {
          'CombinedPayment': pmt1 + pmt2,
          'FirstPayment': pmt1,
          'SecondPayment': pmt2,
          'PmiAvoided': pmiMonthly,
          'TotalPmiSaved': totalPmiSaved,
          'Net10YrSaved': net10,
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

    // Dynamic Calculations
    final res = _computeResults();
    final double downAmt = res['downAmt'];
    final double firstLoanAmt = res['firstLoanAmt'];
    final double secondLoanAmt = res['secondLoanAmt'];
    final double pmt1 = res['pmt1'];
    final double pmt2 = res['pmt2'];
    final double totalPmt = res['totalPmt'];
    final double pmiRate = res['pmiRate'];
    final double pmiMonthly = res['pmiMonthly'];
    final double convMonthlyBase = res['convMonthlyBase'];
    final double convPmt = res['convPmt'];
    final int months = res['months'];
    final double totalPmiSaved = res['totalPmiSaved'];
    final double total2ndInterest = res['total2ndInterest'];
    final double net10 = res['net10'];
    final int breakeven = res['breakeven'];

    // Milestones Key Dates calculations
    final now = DateTime.now();
    final payoff2ndDate = DateTime(now.year + 10, now.month);
    final singlePayoffDate = DateTime(now.year + 10, now.month + 1);
    final payoff1stDate = DateTime(now.year + 30, now.month);

    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final str2ndPayoff = '~${monthNames[payoff2ndDate.month - 1]} ${payoff2ndDate.year}';
    final strSinglePayoff = '~${monthNames[singlePayoffDate.month - 1]} ${singlePayoffDate.year}';
    final str1stPayoff = '${monthNames[payoff1stDate.month - 1]} ${payoff1stDate.year}';

    // Rate Stats for Rate Strip
    final rateStats = [
      {'label': '1st Loan', 'value': '${_rate1.toStringAsFixed(2)}%', 'note': '30yr Fixed Avg'},
      {'label': '2nd Loan', 'value': '${_rate2.toStringAsFixed(2)}%', 'note': 'HELOC/2nd Avg', 'up': true},
      {'label': 'PMI Saved', 'value': '0.58%', 'note': 'Avg PMI Rate', 'up': true},
      {'label': 'Structure', 'value': _structure, 'note': 'Selected Layout'},
    ];

    // Fetch saved calculations from Riverpod to render bottom history list
    final savedCalcs = ref.watch(savedProvider)
        .where((c) => c.country == 'USA' && c.calcType == 'Piggyback Loan')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Widget
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

        // Strategy Overview Card
        _buildSectionHeader('Strategy Overview', onReset: null),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D7B6B), Color(0xFF065F52)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D7B6B).withValues(alpha: 0.28),
                blurRadius: 20,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🏦', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Piggyback Loan Strategy',
                      style: AppTextStyles.playfair(
                          size: 13, weight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Take two mortgages simultaneously to avoid PMI. The 1st covers 80% of the price; the 2nd "piggybacks" the gap.',
                      style: AppTextStyles.dmSans(
                          size: 9.5, color: Colors.white.withValues(alpha: 0.65)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '✅ Zero PMI · Requires Only 5–10% Down',
                        style: AppTextStyles.dmSans(
                            size: 9, weight: FontWeight.w800, color: Colors.white),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Results Hero Box
        _buildSectionHeader('Your Piggyback Result', onReset: null),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF061528), Color(0xFF0F2D6B)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF061528).withValues(alpha: 0.3),
                blurRadius: 28,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Combined Monthly Payment',
                style: AppTextStyles.dmSans(
                    size: 9.5, color: Colors.white.withValues(alpha: 0.55), letterSpacing: 0.8, weight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                _fmt(totalPmt),
                style: AppTextStyles.playfair(
                    size: 32, weight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                '$_structure Structure · \$0 PMI · Saves ${_fmt(pmiMonthly)}/mo vs conventional',
                style: AppTextStyles.dmSans(
                    size: 10, color: Colors.white.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildHeroBottomBox('1st Loan Pmt', _fmt(pmt1), isTeal: true),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroBottomBox('2nd Loan Pmt', _fmt(pmt2), isGold: true),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroBottomBox('PMI Saved/mo', _fmt(pmiMonthly), isLightTeal: true),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Inputs Card
        _buildSectionHeader('Loan Details', onReset: _resetInputs),
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
              // Purchase Price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Home Purchase Price'.toUpperCase(),
                      style: AppTextStyles.dmSans(
                          size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
                  Text(_fmt(_price),
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
                  Text('\$100K', style: AppTextStyles.dmSans(size: 8, color: mutedColor, weight: FontWeight.w600)),
                  Text('\$500K', style: AppTextStyles.dmSans(size: 8, color: mutedColor, weight: FontWeight.w600)),
                  Text('\$1M', style: AppTextStyles.dmSans(size: 8, color: mutedColor, weight: FontWeight.w600)),
                  Text('\$1.5M', style: AppTextStyles.dmSans(size: 8, color: mutedColor, weight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 14),

              // Down Payment
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Down Payment %'.toUpperCase(),
                      style: AppTextStyles.dmSans(
                          size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
                  Text('${_downPct.toStringAsFixed(0)}%',
                      style: AppTextStyles.playfair(
                          size: 13, weight: FontWeight.w800, color: primaryColor)),
                ],
              ),
              Slider(
                value: _downPct,
                min: 5,
                max: 19,
                divisions: 14,
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
                  Text('5%', style: AppTextStyles.dmSans(size: 8, color: mutedColor, weight: FontWeight.w600)),
                  Text('10%', style: AppTextStyles.dmSans(size: 8, color: mutedColor, weight: FontWeight.w600)),
                  Text('15%', style: AppTextStyles.dmSans(size: 8, color: mutedColor, weight: FontWeight.w600)),
                  Text('19%', style: AppTextStyles.dmSans(size: 8, color: mutedColor, weight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 14),

              // 1st Loan Rate
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('1st Loan Rate (30yr Fixed)'.toUpperCase(),
                      style: AppTextStyles.dmSans(
                          size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
                  Text('${_rate1.toStringAsFixed(2)}%',
                      style: AppTextStyles.playfair(
                          size: 13, weight: FontWeight.w800, color: primaryColor)),
                ],
              ),
              Slider(
                value: _rate1,
                min: 5.0,
                max: 9.0,
                divisions: 80,
                activeColor: primaryColor,
                inactiveColor: Colors.grey.withValues(alpha: 0.2),
                onChanged: (val) {
                  setState(() {
                    _rate1 = val;
                    _markDirty();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('5.0%', style: AppTextStyles.dmSans(size: 8, color: mutedColor, weight: FontWeight.w600)),
                  Text('6.5%', style: AppTextStyles.dmSans(size: 8, color: mutedColor, weight: FontWeight.w600)),
                  Text('7.5%', style: AppTextStyles.dmSans(size: 8, color: mutedColor, weight: FontWeight.w600)),
                  Text('9.0%', style: AppTextStyles.dmSans(size: 8, color: mutedColor, weight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 14),

              // 2nd Loan Rate
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('2nd Loan Rate (HELOC/Fixed)'.toUpperCase(),
                      style: AppTextStyles.dmSans(
                          size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
                  Text('${_rate2.toStringAsFixed(2)}%',
                      style: AppTextStyles.playfair(
                          size: 13, weight: FontWeight.w800, color: primaryColor)),
                ],
              ),
              Slider(
                value: _rate2,
                min: 6.0,
                max: 12.0,
                divisions: 120,
                activeColor: primaryColor,
                inactiveColor: Colors.grey.withValues(alpha: 0.2),
                onChanged: (val) {
                  setState(() {
                    _rate2 = val;
                    _markDirty();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('6.0%', style: AppTextStyles.dmSans(size: 8, color: mutedColor, weight: FontWeight.w600)),
                  Text('8.0%', style: AppTextStyles.dmSans(size: 8, color: mutedColor, weight: FontWeight.w600)),
                  Text('10.0%', style: AppTextStyles.dmSans(size: 8, color: mutedColor, weight: FontWeight.w600)),
                  Text('12.0%', style: AppTextStyles.dmSans(size: 8, color: mutedColor, weight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 14),

              // Structure selector pills
              Text('Piggyback Structure'.toUpperCase(),
                  style: AppTextStyles.dmSans(
                      size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStructurePill('80/10/10', '10% down', cardColor, borderColor),
                  const SizedBox(width: 8),
                  _buildStructurePill('80/15/5', '5% down', cardColor, borderColor),
                  const SizedBox(width: 8),
                  _buildStructurePill('80/5/15', '15% down', cardColor, borderColor),
                ],
              ),
              const SizedBox(height: 14),

              // Credit Score FICO
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Credit Score'.toUpperCase(),
                      style: AppTextStyles.dmSans(
                          size: 9, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5)),
                  Text('${_fico.toInt()}',
                      style: AppTextStyles.playfair(
                          size: 13, weight: FontWeight.w800, color: primaryColor)),
                ],
              ),
              Slider(
                value: _fico,
                min: 620,
                max: 850,
                divisions: 23,
                activeColor: primaryColor,
                inactiveColor: Colors.grey.withValues(alpha: 0.2),
                onChanged: (val) {
                  setState(() {
                    _fico = val;
                    _markDirty();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('620', style: AppTextStyles.dmSans(size: 8, color: mutedColor, weight: FontWeight.w600)),
                  Text('680', style: AppTextStyles.dmSans(size: 8, color: mutedColor, weight: FontWeight.w600)),
                  Text('720', style: AppTextStyles.dmSans(size: 8, color: mutedColor, weight: FontWeight.w600)),
                  Text('780', style: AppTextStyles.dmSans(size: 8, color: mutedColor, weight: FontWeight.w600)),
                  Text('850', style: AppTextStyles.dmSans(size: 8, color: mutedColor, weight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 16),

              // Button actions row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isCalcDirty = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D7B6B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      child: Text(
                        'Calculate Piggyback',
                        style: AppTextStyles.playfair(
                            size: 13, weight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _saveCalculation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cardColor,
                      foregroundColor: const Color(0xFF0D7B6B),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xFF0D7B6B), width: 1.5),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('💾', style: TextStyle(fontSize: 19)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // PMI Savings Card
        _buildSectionHeader('PMI Savings Over Life of Loan', onReset: null),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D7B6B), Color(0xFF065F52)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D7B6B).withValues(alpha: 0.28),
                blurRadius: 28,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total PMI Avoided',
                style: AppTextStyles.dmSans(
                    size: 9.5, color: Colors.white.withValues(alpha: 0.55), letterSpacing: 0.8, weight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                _fmt(totalPmiSaved),
                style: AppTextStyles.playfair(
                    size: 36, weight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                'vs. Conventional Loan with ${_downPct.toStringAsFixed(0)}% Down · ${pmiRate.toStringAsFixed(2)}% PMI · ~${(months / 12).toStringAsFixed(1)} yrs',
                style: AppTextStyles.dmSans(
                    size: 10, color: Colors.white.withValues(alpha: 0.60)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildHeroBottomBox('Monthly Saving', _fmt(pmiMonthly)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroBottomBox('Break-even Point', '~$breakeven mo'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroBottomBox('Net 10yr Saving', _fmt(net10.abs())),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Monthly Payment Breakdown Bars
        _buildSectionHeader('Monthly Payment Breakdown', onReset: null),
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
              _buildBreakdownBarRow('1st Mortgage (80%)', pmt1, const Color(0xFF1B3F72),
                  '${_rate1.toStringAsFixed(2)}% · 30yr fixed · ${_fmt(firstLoanAmt)}', totalPmt),
              const SizedBox(height: 14),
              _buildBreakdownBarRow('2nd Loan (Piggyback)', pmt2, const Color(0xFF0D7B6B),
                  '${_rate2.toStringAsFixed(2)}% · 10yr fixed · ${_fmt(secondLoanAmt)}', totalPmt),
              const SizedBox(height: 14),
              _buildBreakdownBarRow('Down Payment', downAmt, const Color(0xFFD97706),
                  '${_downPct.toStringAsFixed(0)}% of purchase price', _price),
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: borderColor)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(color: const Color(0xFFB91C1C), borderRadius: BorderRadius.circular(3)),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'PMI (Avoided!)',
                              style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: const Color(0xFFB91C1C)),
                            )
                          ],
                        ),
                        Text(
                          _fmt(pmiMonthly),
                          style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: const Color(0xFFB91C1C))
                              .copyWith(fontFamily: 'Georgia', decoration: TextDecoration.lineThrough),
                        )
                      ],
                    ),
                    const SizedBox(height: 6),
                    LayoutBuilder(builder: (context, constraints) {
                      final pct = totalPmt > 0 ? (pmiMonthly / totalPmt) : 0.0;
                      return Container(
                        height: 9,
                        width: double.infinity,
                        decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(5)),
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 9,
                          width: constraints.maxWidth * min(0.95, pct),
                          decoration: BoxDecoration(color: const Color(0xFFB91C1C).withValues(alpha: 0.35), borderRadius: BorderRadius.circular(5)),
                        ),
                      );
                    }),
                    const SizedBox(height: 3),
                    Text(
                      '✅ \$0 PMI with Piggyback structure',
                      style: AppTextStyles.dmSans(size: 9, color: const Color(0xFF0D7B6B), weight: FontWeight.w600),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Loan Composition Donut Card
        _buildSectionHeader('Loan Composition', onReset: null),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
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
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 108,
                    height: 108,
                    child: CustomPaint(
                      painter: _PiggybackDonutPainter(
                        pct1: 80.0,
                        pct2: 100.0 - 80.0 - _downPct,
                        downPct: _downPct,
                        firstColor: const Color(0xFF1B3F72),
                        secondColor: const Color(0xFF0D7B6B),
                        downColor: const Color(0xFFD97706),
                        bgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '80/${(20 - _downPct).round()}',
                        style: AppTextStyles.dmSans(
                          size: 15,
                          weight: FontWeight.w800,
                          color: textColor,
                        ).copyWith(fontFamily: 'Georgia'),
                      ),
                      Text(
                        'Structure',
                        style: AppTextStyles.dmSans(
                          size: 8,
                          weight: FontWeight.w600,
                          color: mutedColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    _buildLegendRow('1st Mortgage', firstLoanAmt, const Color(0xFF1B3F72)),
                    const SizedBox(height: 9),
                    _buildLegendRow('2nd Loan', secondLoanAmt, const Color(0xFF0D7B6B)),
                    const SizedBox(height: 9),
                    _buildLegendRow('Down Payment', downAmt, const Color(0xFFD97706)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 10-Year Cost Comparison Bar Chart
        _buildSectionHeader('10-Year Cost Comparison', onReset: null),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Piggyback vs Conventional with PMI',
                style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: textColor).copyWith(fontFamily: 'Georgia'),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [1, 3, 5, 10].map((yr) {
                  final pig = totalPmt * 12 * yr;
                  final conv = convPmt * 12 * yr;
                  final maxVal = max(totalPmt, convPmt) * 12 * 10;
                  const maxH = 100.0;

                  final h1 = (pmt1 * 12 * yr) / maxVal * maxH;
                  final h2 = (pmt2 * 12 * yr) / maxVal * maxH;
                  final hconv = (convMonthlyBase * 12 * yr) / maxVal * maxH;
                  final hpmi = (pmiMonthly * 12 * yr) / maxVal * maxH;

                  return Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Piggyback group
                            Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(_fmtK(pig), style: AppTextStyles.dmSans(size: 7.5, color: const Color(0xFF0D7B6B), weight: FontWeight.w800).copyWith(fontFamily: 'Georgia')),
                                const SizedBox(height: 2),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      width: 10,
                                      height: max(2.0, h1),
                                      decoration: const BoxDecoration(color: Color(0xFF1B3F72), borderRadius: BorderRadius.vertical(top: Radius.circular(3))),
                                    ),
                                    const SizedBox(width: 1),
                                    Container(
                                      width: 10,
                                      height: max(2.0, h2),
                                      decoration: const BoxDecoration(color: Color(0xFF0D7B6B), borderRadius: BorderRadius.vertical(top: Radius.circular(3))),
                                    ),
                                  ],
                                )
                              ],
                            ),
                            const SizedBox(width: 4),
                            // Conventional group
                            Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(_fmtK(conv), style: AppTextStyles.dmSans(size: 7.5, color: const Color(0xFFB91C1C), weight: FontWeight.w800).copyWith(fontFamily: 'Georgia')),
                                const SizedBox(height: 2),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      width: 10,
                                      height: max(2.0, hconv),
                                      decoration: const BoxDecoration(color: Color(0xFF475569), borderRadius: BorderRadius.vertical(top: Radius.circular(3))),
                                    ),
                                    const SizedBox(width: 1),
                                    Container(
                                      width: 10,
                                      height: max(2.0, hpmi),
                                      decoration: BoxDecoration(color: const Color(0xFFB91C1C).withValues(alpha: 0.75), borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${yr}yr',
                          style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w700, color: mutedColor),
                        )
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendDotIndicator('1st Mortgage', const Color(0xFF1B3F72)),
                  const SizedBox(width: 12),
                  _buildLegendDotIndicator('2nd Loan', const Color(0xFF0D7B6B)),
                  const SizedBox(width: 12),
                  _buildLegendDotIndicator('PMI (Conv.)', const Color(0xFFB91C1C)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Key Milestones Timeline
        _buildSectionHeader('Key Milestones', onReset: null),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          child: Column(
            children: [
              _buildMilestoneRow('🏁 2nd Loan Payoff Date', str2ndPayoff, isTeal: true),
              _buildMilestoneRow('📉 Combined = 1 Payment After', strSinglePayoff, isTeal: true),
              _buildMilestoneRow('🏠 1st Loan Payoff (30yr)', str1stPayoff),
              _buildMilestoneRow('💰 Total 2nd Loan Interest', _fmt(total2ndInterest), isRed: true),
              _buildMilestoneRow('📊 2nd Loan Fully Amortized', '10-year term'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Side-by-Side Comparison
        _buildSectionHeader('Side-by-Side Comparison', onReset: null),
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
                  _buildTableHeaderCell('Feature'),
                  _buildTableHeaderCell('Piggyback'),
                  _buildTableHeaderCell('Conv. PMI'),
                  _buildTableHeaderCell('20% Down'),
                ],
              ),
              _buildTableRow('Monthly PMI', '\$0 ✅', _fmt(pmiMonthly), '\$0 ✅', highlight: true, bestIndex: [1, 3], badIndex: [2]),
              _buildTableRow('Down Payment', _fmt(downAmt), _fmt(downAmt), _fmt(_price * 0.2), badIndex: [3]),
              _buildTableRow('Monthly Pmt', _fmt(totalPmt), _fmt(convPmt), _fmt(_monthlyPayment(_price * 0.80, _rate1, 30)), bestIndex: [3], badIndex: [2]),
              _buildTableRow('No PMI', '✓', '✗', '✓', isCheckMark: true),
              _buildTableRow('2nd Mortgage', 'Yes', 'No', 'No', isCheckMark: true, badIndex: [1]),
              _buildTableRow('Tax Deductible', 'Both int.', '1st only', 'Yes'),
              _buildTableRow('Best For', 'Low down, no PMI', 'Simplicity', 'Best rate', size: 9),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Saved list
        if (savedCalcs.isNotEmpty) ...[
          _buildSectionHeader(
            'Saved Calculations',
            onReset: () async {
              final messenger = ScaffoldMessenger.of(context);
              for (final calc in savedCalcs) {
                await ref.read(savedProvider.notifier).delete(calc.id);
              }
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('All saved calculations cleared!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            resetLabel: 'Clear All',
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: savedCalcs.length,
            itemBuilder: (context, index) {
              final calc = savedCalcs[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: cardColor,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07), blurRadius: 14, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _loadSaved(calc),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              calc.label,
                              style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: textColor).copyWith(fontFamily: 'Georgia'),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Price: ${_fmtK(calc.inputs['Price'] ?? 0.0)} · Down: ${(calc.inputs['DownPct'] ?? 0.0).toStringAsFixed(0)}% · ${calc.inputs['Structure'] ?? '80/10/10'}',
                              style: AppTextStyles.dmSans(size: 9.0, color: mutedColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _fmt(calc.results['CombinedPayment'] ?? 0.0),
                      style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: primaryColor).copyWith(fontFamily: 'Georgia'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      color: mutedColor.withValues(alpha: 0.5),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await ref.read(savedProvider.notifier).delete(calc.id);
                        if (mounted) {
                          messenger.showSnackBar(
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
          const SizedBox(height: 20),
        ],

        // How It Works Details
        _buildSectionHeader('How Piggyback Works', onReset: null),
        const SizedBox(height: 8),
        Column(
          children: [
            _buildHowItWorksCard('1️⃣', 'First Mortgage — 80%', 'Conventional loan at market rate (${_rate1.toStringAsFixed(2)}% avg). LTV = 80%, so NO PMI required by lender.'),
            const SizedBox(height: 9),
            _buildHowItWorksCard('2️⃣', 'Second Loan — 10% (or 5/15%)', 'HELOC or fixed second mortgage covers the gap. Higher rate but eliminates PMI requirement.'),
            const SizedBox(height: 9),
            _buildHowItWorksCard('3️⃣', 'Your Down Payment — 10%', 'You bring the remaining down payment. Together: 80 + 10 + 10 = 100% purchase price covered.'),
            const SizedBox(height: 9),
            _buildHowItWorksCard('4️⃣', 'Pay Off 2nd, Simplify', 'Most piggyback 2nd loans are 10-year terms. Once paid off, you have one clean mortgage payment.'),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onReset, String resetLabel = 'Reset'}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        if (onReset != null)
          GestureDetector(
            onTap: onReset,
            child: Text(
              '$resetLabel →',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF93C5FD)
                    : const Color(0xFF1E4FBF),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeroBottomBox(String label, String value, {bool isTeal = false, bool isGold = false, bool isLightTeal = false}) {
    Color valColor = Colors.white;
    if (isTeal) {
      valColor = const Color(0xFF5EEAD4);
    } else if (isGold) {
      valColor = const Color(0xFFFCD34D);
    } else if (isLightTeal) {
      valColor = const Color(0xFF5EEAD4);
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(size: 8.5, color: Colors.white.withValues(alpha: 0.5)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: valColor).copyWith(fontFamily: 'Georgia'),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStructurePill(String struct, String subtitle, Color cardBg, Color borderCol) {
    final active = _structure == struct;
    final pillBg = active ? const Color(0xFFF0FDF9) : cardBg;
    final pillBorder = active ? const Color(0xFF0D7B6B) : borderCol;
    final textCol = active ? const Color(0xFF0D7B6B) : widget.theme.getTextColor(context);

    return Expanded(
      child: GestureDetector(
        onTap: () => _selectStructure(struct),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: pillBg,
            border: Border.all(color: pillBorder, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                struct,
                style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textCol).copyWith(fontFamily: 'Georgia'),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdownBarRow(String label, double val, Color color, String sub, double baseTotal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: widget.theme.getTextColor(context)),
                )
              ],
            ),
            Text(
              _fmt(val),
              style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: widget.theme.getTextColor(context)).copyWith(fontFamily: 'Georgia'),
            )
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(builder: (context, constraints) {
          final pct = baseTotal > 0 ? (val / baseTotal) : 0.0;
          return Container(
            height: 9,
            width: double.infinity,
            decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(5)),
            alignment: Alignment.centerLeft,
            child: Container(
              height: 9,
              width: constraints.maxWidth * min(0.95, pct),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
            ),
          );
        }),
        const SizedBox(height: 3),
        Text(
          sub,
          style: AppTextStyles.dmSans(size: 9, color: widget.theme.getMutedColor(context)),
        )
      ],
    );
  }

  Widget _buildLegendRow(String name, double val, Color color) {
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
        Text(
          name,
          style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: textColor),
        ),
        const Spacer(),
        Text(
          _fmt(val),
          style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: textColor).copyWith(fontFamily: 'Georgia'),
        ),
      ],
    );
  }

  Widget _buildLegendDotIndicator(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w700, color: widget.theme.getMutedColor(context)),
        )
      ],
    );
  }

  Widget _buildMilestoneRow(String label, String val, {bool isTeal = false, bool isRed = false}) {
    Color valCol = widget.theme.accentColor;
    if (isTeal) {
      valCol = const Color(0xFF0D7B6B);
    } else if (isRed) {
      valCol = const Color(0xFFB91C1C);
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: widget.theme.getBorderColor(context), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: widget.theme.getTextColor(context)),
          ),
          Text(
            val,
            style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: valCol).copyWith(fontFamily: 'Georgia'),
          )
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
        textAlign: text == 'Feature' ? TextAlign.left : TextAlign.center,
      ),
    );
  }

  TableRow _buildTableRow(
    String feature,
    String pigVal,
    String convVal,
    String dpVal, {
    bool highlight = false,
    List<int>? bestIndex, // 1 for Piggyback, 2 for Conv. PMI, 3 for 20% Down
    List<int>? badIndex,
    bool isCheckMark = false,
    double size = 11,
  }) {
    final textColor = widget.theme.getTextColor(context);
    final mutedColor = widget.theme.getMutedColor(context);
    final borderColor = widget.theme.getBorderColor(context);

    Widget buildCellWidget(String val, int index) {
      Color c = textColor;
      FontWeight fw = FontWeight.w700;
      if (bestIndex != null && bestIndex.contains(index)) {
        c = const Color(0xFF0D7B6B);
        fw = FontWeight.w800;
      } else if (badIndex != null && badIndex.contains(index)) {
        c = const Color(0xFFB91C1C);
      }

      if (isCheckMark) {
        if (val == '✓') {
          return const Text('✓', style: TextStyle(color: Color(0xFF0D7B6B), fontWeight: FontWeight.w900, fontSize: 13), textAlign: TextAlign.center);
        } else if (val == '✗') {
          return const Text('✗', style: TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w900, fontSize: 13), textAlign: TextAlign.center);
        }
      }

      return Text(val,
          style: AppTextStyles.dmSans(size: size, weight: fw, color: c),
          textAlign: TextAlign.center);
    }

    return TableRow(
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFF0FDF9) : Colors.transparent,
        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
          child: Text(
            feature,
            style: AppTextStyles.dmSans(size: 10.5, color: mutedColor, weight: FontWeight.w600),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: buildCellWidget(pigVal, 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: buildCellWidget(convVal, 2),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: buildCellWidget(dpVal, 3),
        ),
      ],
    );
  }

  Widget _buildHowItWorksCard(String emoji, String title, String description) {
    final cardBg = widget.theme.getCardColor(context);
    final borderCol = widget.theme.getBorderColor(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderCol),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.playfair(size: 12.5, weight: FontWeight.w800, color: widget.theme.getTextColor(context)),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTextStyles.dmSans(size: 9.5, color: widget.theme.getMutedColor(context)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// Donut Composition Painter
class _PiggybackDonutPainter extends CustomPainter {
  final double pct1;
  final double pct2;
  final double downPct;
  final Color firstColor;
  final Color secondColor;
  final Color downColor;
  final Color bgColor;

  const _PiggybackDonutPainter({
    required this.pct1,
    required this.pct2,
    required this.downPct,
    required this.firstColor,
    required this.secondColor,
    required this.downColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 6;
    const strokeWidth = 10.0;

    // Draw background circle
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    final total = pct1 + pct2 + downPct;
    if (total == 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // 1st Mortgage arc (80%)
    final sweep1 = (pct1 / total) * 2 * pi;
    final paint1 = Paint()
      ..color = firstColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -pi / 2, sweep1, false, paint1);

    // 2nd Loan arc (HELOC)
    final sweep2 = (pct2 / total) * 2 * pi;
    final paint2 = Paint()
      ..color = secondColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -pi / 2 + sweep1, sweep2, false, paint2);

    // Down Payment arc
    final sweep3 = (downPct / total) * 2 * pi;
    final paint3 = Paint()
      ..color = downColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -pi / 2 + sweep1 + sweep2, sweep3, false, paint3);
  }

  @override
  bool shouldRepaint(covariant _PiggybackDonutPainter oldDelegate) {
    return oldDelegate.pct1 != pct1 ||
        oldDelegate.pct2 != pct2 ||
        oldDelegate.downPct != downPct ||
        oldDelegate.firstColor != firstColor ||
        oldDelegate.secondColor != secondColor ||
        oldDelegate.downColor != downColor ||
        oldDelegate.bgColor != bgColor;
  }
}
