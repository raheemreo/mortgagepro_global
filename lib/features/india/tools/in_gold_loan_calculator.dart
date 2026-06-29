// lib/features/india/tools/in_gold_loan_calculator.dart

import 'package:flutter/material.dart';
import 'dart:math' show max, min, pow;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../core/utils/compat.dart';

class INGoldLoanCalculator extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INGoldLoanCalculator({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INGoldLoanCalculator> createState() =>
      _INGoldLoanCalculatorState();
}

class _INGoldLoanCalculatorState extends ConsumerState<INGoldLoanCalculator> {
  // Input states
  int _purity = 22; // 18, 22, 24
  double _weight = 50.0;
  double _ltv = 75.0; // 60, 65, 75
  double _rate = 9.5;
  int _tenure = 12; // 3, 6, 12, 24
  String _repaymentMode =
      'Regular EMI'; // 'Regular EMI', 'Monthly Interest', 'Bullet Repayment'

  // Controllers
  late TextEditingController _weightCtrl;
  late TextEditingController _rateCtrl;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultsKey = GlobalKey();

  static const Map<int, double> _goldPrices = {
    18: 71415.0,
    22: 87285.0,
    24: 95220.0,
  };

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(text: _weight.toStringAsFixed(0));
    _rateCtrl = TextEditingController(text: _rate.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _rateCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _purity = 22;
      _weight = 50.0;
      _ltv = 75.0;
      _rate = 9.5;
      _tenure = 12;
      _repaymentMode = 'Regular EMI';

      _weightCtrl.text = '50';
      _rateCtrl.text = '9.5';
    });
  }

  String _fmt(double n) {
    return '₹${n.round().toLocaleString()}';
  }

  String _fmtShort(double n) {
    if (n >= 10000000) return '${(n / 10000000).toStringAsFixed(1)}Cr';
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    return n.round().toLocaleString();
  }

  void _saveCalculation() async {
    final pricePerGram = (_goldPrices[_purity] ?? 87285) / 10.0;
    final goldValue = _weight * pricePerGram;
    final loanAmt = goldValue * (_ltv / 100.0);

    double emi = 0.0;
    double totalPay = 0.0;
    double totalInt = 0.0;
    final mRate = _rate / 1200.0;

    if (_repaymentMode == 'Regular EMI') {
      emi = mRate > 0
          ? loanAmt *
              (mRate * pow(1 + mRate, _tenure)) /
              (pow(1 + mRate, _tenure) - 1)
          : loanAmt / _tenure;
      totalPay = emi * _tenure;
      totalInt = totalPay - loanAmt;
    } else if (_repaymentMode == 'Monthly Interest') {
      emi = loanAmt * mRate;
      totalInt = emi * _tenure;
      totalPay = loanAmt + totalInt;
    } else {
      totalPay = loanAmt * pow(1 + mRate, _tenure);
      totalInt = totalPay - loanAmt;
      emi = 0.0;
    }

    final labelCtrl = TextEditingController(text: 'Gold Loan');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/in_gold_loan_calculator/save'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Gold Loan Calculation',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving: Loan ${_fmt(loanAmt)} · Weight ${_weight}g',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My Gold Loan)',
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
              backgroundColor: const Color(0xFFD4AF37),
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
          : 'Gold Loan';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'Gold Loan Calculator',
        inputs: {
          'purity': _purity.toDouble(),
          'weight': _weight,
          'ltv': _ltv,
          'rate': _rate,
          'tenure': _tenure.toDouble(),
          'mode': _repaymentMode == 'Regular EMI'
              ? 1.0
              : (_repaymentMode == 'Monthly Interest' ? 2.0 : 3.0),
        },
        results: {
          'loanAmt': loanAmt,
          'goldValue': goldValue,
          'emi': emi,
          'totalInterest': totalInt,
          'totalPayable': totalPay,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Gold loan saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFFD4AF37),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _scrollToResults() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _resultsKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(context,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculations
    final pricePerGram = (_goldPrices[_purity] ?? 87285) / 10.0;
    final goldValue = _weight * pricePerGram;
    final loanAmt = goldValue * (_ltv / 100.0);
    final perGramVal = pricePerGram * (_ltv / 100.0);

    double emi = 0.0;
    double totalPay = 0.0;
    double totalInt = 0.0;
    final List<Map<String, dynamic>> schedule = [];
    final mRate = _rate / 1200.0;

    if (_repaymentMode == 'Regular EMI') {
      emi = mRate > 0
          ? loanAmt *
              (mRate * pow(1 + mRate, _tenure)) /
              (pow(1 + mRate, _tenure) - 1)
          : loanAmt / _tenure;
      totalPay = emi * _tenure;
      totalInt = totalPay - loanAmt;

      double tempBal = loanAmt;
      for (int i = 1; i <= min(_tenure, 12); i++) {
        final interest = tempBal * mRate;
        final principal = emi - interest;
        tempBal = max(0.0, tempBal - principal);
        schedule.add({
          'month': i,
          'interest': interest,
          'principal': principal,
          'balance': tempBal,
        });
      }
    } else if (_repaymentMode == 'Monthly Interest') {
      emi = loanAmt * mRate;
      totalInt = emi * _tenure;
      totalPay = loanAmt + totalInt;

      for (int i = 1; i <= min(_tenure, 12); i++) {
        final isLast = i == _tenure;
        schedule.add({
          'month': i,
          'interest': emi,
          'principal': isLast ? loanAmt : 0.0,
          'balance': isLast ? 0.0 : loanAmt,
        });
      }
    } else {
      // Bullet Repayment
      totalPay = loanAmt * pow(1 + mRate, _tenure);
      totalInt = totalPay - loanAmt;
      emi = 0.0;

      double tempInt = 0.0;
      for (int i = 1; i <= min(_tenure, 12); i++) {
        final isLast = i == _tenure;
        final interestThisMonth = (loanAmt + tempInt) * mRate;
        tempInt += interestThisMonth;
        schedule.add({
          'month': i,
          'interest': interestThisMonth,
          'principal': isLast ? loanAmt : 0.0,
          'balance': isLast ? 0.0 : (loanAmt + tempInt),
        });
      }
    }

    // LTV Warning text
    final String ltvWarningText = _ltv >= 75
        ? '⚠️ At RBI maximum LTV. Lender may ask for top-up margin if gold price drops.'
        : _ltv >= 65
            ? '✅ Moderate LTV. Good cushion for price fluctuations.'
            : '✅ Conservative LTV. Safe borrowing position.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Info
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF78350F).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoCell('24K / 10g', _fmt(95220), 'MCX Jun 25', context),
              _verticalDivider(),
              _infoCell('22K / 10g', _fmt(87285), 'Hallmark', context),
              _verticalDivider(),
              _infoCell('Max LTV', '75%', 'RBI Norm', context, isGreen: true),
              _verticalDivider(),
              _infoCell('Best Rate', '8.50%', 'SBI', context),
            ],
          ),
        ),

        // Live Gold Ticker Card
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF78350F), Color(0xFF92400E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              const Text('🥇', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MCX GOLD SPOT · 24 KARAT',
                        style: AppTextStyles.dmSans(
                            size: 8,
                            color: Colors.white60,
                            weight: FontWeight.w700,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        text: '${_fmt(95220)} ',
                        style: AppTextStyles.dmSans(
                            size: 20,
                            color: const Color(0xFFFFDEA0),
                            weight: FontWeight.w800),
                        children: [
                          TextSpan(
                            text: '/ 10g',
                            style: AppTextStyles.dmSans(
                                size: 11,
                                color: const Color(0xFFFFDEA0)
                                    .withValues(alpha: 0.7)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('Updated: June 2025 · MCX India',
                        style: AppTextStyles.dmSans(
                            size: 8, color: Colors.white38)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  border: Border.all(
                      color: Colors.greenAccent.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('↑ +1.2%',
                    style: AppTextStyles.dmSans(
                        size: 11,
                        color: Colors.greenAccent,
                        weight: FontWeight.w800)),
              ),
            ],
          ),
        ),

        // Gold Pledge Details Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('GOLD PLEDGE DETAILS',
                style: AppTextStyles.dmSans(
                    size: 10.5,
                    color: theme.getMutedColor(context),
                    weight: FontWeight.w800,
                    letterSpacing: 0.8)),
            Text('RBI Max LTV 75% ⓘ',
                style: AppTextStyles.dmSans(
                    size: 11,
                    color: const Color(0xFFB8960C),
                    weight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 10),

        // Calculator Inputs Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('CALCULATOR INPUTS',
                      style: AppTextStyles.dmSans(
                          size: 9.5,
                          color: theme.getMutedColor(context),
                          weight: FontWeight.w800,
                          letterSpacing: 0.5)),
                  GestureDetector(
                    onTap: _reset,
                    child: Text('Reset ↺',
                        style: AppTextStyles.dmSans(
                            size: 11,
                            color: const Color(0xFFFF6B00),
                            weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Repayment Scheme Selector
              Text('REPAYMENT SCHEME',
                  style: AppTextStyles.dmSans(
                      size: 8.5,
                      color: theme.getMutedColor(context),
                      weight: FontWeight.w800)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _modeButton('Regular EMI'),
                  const SizedBox(width: 4),
                  _modeButton('Monthly Interest'),
                  const SizedBox(width: 4),
                  _modeButton('Bullet Repayment'),
                ],
              ),
              const SizedBox(height: 16),

              // Gold Purity Selector
              Text('GOLD PURITY',
                  style: AppTextStyles.dmSans(
                      size: 8.5,
                      color: theme.getMutedColor(context),
                      weight: FontWeight.w800)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _purityButton(18, '18K'),
                  const SizedBox(width: 8),
                  _purityButton(22, '22K'),
                  const SizedBox(width: 8),
                  _purityButton(24, '24K'),
                ],
              ),
              const SizedBox(height: 16),

              // Synced input-slider: Gold Weight
              _buildSyncedInputRow(
                label: 'GOLD WEIGHT (GRAMS)',
                controller: _weightCtrl,
                value: _weight,
                min: 1.0,
                max: 500.0,
                suffix: ' grams',
                onChangedText: (val) {
                  setState(() {
                    _weight = val;
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _weight = val;
                    _weightCtrl.text = val.toStringAsFixed(0);
                  });
                },
              ),
              const SizedBox(height: 16),

              // LTV Toggle
              Text('LTV (LOAN-TO-VALUE RATIO)',
                  style: AppTextStyles.dmSans(
                      size: 8.5,
                      color: theme.getMutedColor(context),
                      weight: FontWeight.w800)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _ltvButton(60.0, '60%'),
                  const SizedBox(width: 8),
                  _ltvButton(65.0, '65%'),
                  const SizedBox(width: 8),
                  _ltvButton(75.0, '75% Max'),
                ],
              ),
              const SizedBox(height: 16),

              // Synced input-slider: Interest Rate
              _buildSyncedInputRow(
                label: 'INTEREST RATE (P.A.)',
                controller: _rateCtrl,
                value: _rate,
                min: 7.0,
                max: 30.0,
                suffix: '% p.a.',
                onChangedText: (val) {
                  setState(() {
                    _rate = val;
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _rate = val;
                    _rateCtrl.text = val.toStringAsFixed(1);
                  });
                },
              ),
              const SizedBox(height: 16),

              // Loan Tenure
              Text('LOAN TENURE',
                  style: AppTextStyles.dmSans(
                      size: 8.5,
                      color: theme.getMutedColor(context),
                      weight: FontWeight.w800)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _tenureButton(3, '3 mo'),
                  const SizedBox(width: 6),
                  _tenureButton(6, '6 mo'),
                  const SizedBox(width: 6),
                  _tenureButton(12, '1 yr'),
                  const SizedBox(width: 6),
                  _tenureButton(24, '2 yr'),
                ],
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _scrollToResults,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: Text('🥇 Calculate Gold Loan',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        color: Colors.white,
                        weight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Result Hero Card
        Container(
          key: _resultsKey,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF78350F), Color(0xFF92400E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
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
              Text('MAXIMUM LOAN AMOUNT',
                  style: AppTextStyles.dmSans(
                      size: 9,
                      color: Colors.white60,
                      weight: FontWeight.w700,
                      letterSpacing: 0.8)),
              const SizedBox(height: 4),
              Text(
                _fmt(loanAmt),
                style: AppTextStyles.playfair(
                    size: 34,
                    color: const Color(0xFFFFDEA0),
                    weight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 9,
                crossAxisSpacing: 9,
                childAspectRatio: 2.2,
                children: [
                  _resultBox('Gold Market Value', _fmt(goldValue),
                      isGold: true),
                  _resultBox(
                      _repaymentMode == 'Bullet Repayment'
                          ? 'Lump Sum Payout'
                          : 'Monthly Payment',
                      _repaymentMode == 'Bullet Repayment'
                          ? _fmt(totalPay)
                          : '${_fmt(emi)}/mo'),
                  _resultBox('Total Interest', _fmt(totalInt), isRed: true),
                  _resultBox('Per-Gram Loan Value', _fmt(perGramVal),
                      isGreen: true),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _saveCalculation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11)),
                  minimumSize: const Size(double.infinity, 42),
                ),
                child: Text('📥 Save Calculation',
                    style: AppTextStyles.dmSans(
                        size: 13, weight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // LTV Risk Meter
        Text('LTV Risk Meter',
            style: AppTextStyles.playfair(
                size: 15,
                color: theme.getTextColor(context),
                weight: FontWeight.w800)),
        const SizedBox(height: 10),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Loan-to-Value Ratio',
                      style: AppTextStyles.dmSans(
                          size: 12,
                          weight: FontWeight.w800,
                          color: theme.getTextColor(context))),
                  Text('${_ltv.toInt()}%',
                      style: AppTextStyles.dmSans(
                          size: 12,
                          weight: FontWeight.w800,
                          color: const Color(0xFFD4AF37))),
                ],
              ),
              const SizedBox(height: 12),

              // Custom Linear Gradient bar for LTV
              LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final ratio = min(1.0, _ltv / 90.0);
                  final markerLeft = totalWidth * ratio;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 18,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF86EFAC),
                              Color(0xFFFCD34D),
                              Color(0xFFEF4444),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: markerLeft - 2,
                        top: -2,
                        child: Container(
                          width: 4,
                          height: 22,
                          decoration: BoxDecoration(
                            color: theme.getTextColor(context),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0% Safe',
                      style: AppTextStyles.dmSans(
                          size: 8, color: theme.getMutedColor(context))),
                  Text('50% Moderate',
                      style: AppTextStyles.dmSans(
                          size: 8, color: theme.getMutedColor(context))),
                  Text('75% Max',
                      style: AppTextStyles.dmSans(
                          size: 8, color: theme.getMutedColor(context))),
                  Text('90% Risky',
                      style: AppTextStyles.dmSans(
                          size: 8, color: theme.getMutedColor(context))),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                ltvWarningText,
                style: AppTextStyles.dmSans(
                    size: 10,
                    color: theme.getMutedColor(context),
                    weight: FontWeight.w600,
                    height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // EMI Schedule
        Text(
            _repaymentMode == 'Regular EMI'
                ? 'EMI Schedule'
                : 'Repayment Schedule',
            style: AppTextStyles.playfair(
                size: 15,
                color: theme.getTextColor(context),
                weight: FontWeight.w800)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF78350F), Color(0xFF92400E)]),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                child: Row(
                  children: [
                    Expanded(
                        child: Text('Month',
                            style: AppTextStyles.dmSans(
                                size: 9,
                                weight: FontWeight.w800,
                                color: Colors.white70))),
                    Expanded(
                        child: Text('Principal',
                            style: AppTextStyles.dmSans(
                                size: 9,
                                weight: FontWeight.w800,
                                color: Colors.white70))),
                    Expanded(
                        child: Text('Interest',
                            style: AppTextStyles.dmSans(
                                size: 9,
                                weight: FontWeight.w800,
                                color: Colors.white70))),
                    Expanded(
                        child: Text('Balance',
                            style: AppTextStyles.dmSans(
                                size: 9,
                                weight: FontWeight.w800,
                                color: Colors.white70))),
                  ],
                ),
              ),
              ...schedule.map((row) {
                final isEven = row['month'] % 2 == 0;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: isEven
                        ? theme.getBgColor(context).withValues(alpha: 0.3)
                        : null,
                    border: Border(
                        bottom:
                            BorderSide(color: theme.getBorderColor(context))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text('Mo ${row['month']}',
                              style: AppTextStyles.dmSans(
                                  size: 10.5,
                                  color: theme.getTextColor(context),
                                  weight: FontWeight.w700))),
                      Expanded(
                          child: Text(
                              row['principal'] > 0
                                  ? _fmtShort(row['principal'])
                                  : '₹0',
                              style: AppTextStyles.dmSans(
                                  size: 10.5,
                                  weight: FontWeight.w700,
                                  color: row['principal'] > 0
                                      ? Colors.green
                                      : theme.getMutedColor(context)))),
                      Expanded(
                          child: Text(
                              row['interest'] > 0
                                  ? _fmtShort(row['interest'])
                                  : '₹0',
                              style: AppTextStyles.dmSans(
                                  size: 10.5,
                                  weight: FontWeight.w700,
                                  color: row['interest'] > 0
                                      ? Colors.red
                                      : theme.getMutedColor(context)))),
                      Expanded(
                          child: Text(_fmtShort(row['balance']),
                              style: AppTextStyles.dmSans(
                                  size: 10.5,
                                  color: theme.getTextColor(context)))),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Gold Loan Lenders Compare List
        Text('Gold Loan Lenders 2025',
            style: AppTextStyles.playfair(
                size: 15,
                color: theme.getTextColor(context),
                weight: FontWeight.w800)),
        const SizedBox(height: 10),
        _lenderRow('🏦', 'SBI Gold Loan', 'PSU Bank · Online & Branch', '8.50%',
            context),
        _lenderRow('⚡', 'Muthoot Finance', 'NBFC · 4,400+ branches', '10–26%',
            context),
        _lenderRow('🌿', 'Manappuram Gold', 'NBFC · 5,000+ branches', '9.90%',
            context),
        _lenderRow(
            '🏛️', 'HDFC Bank', 'Private Bank · Doorstep', '9.50%', context),
        _lenderRow('💼', 'ICICI Bank', 'Private Bank · 30-min disbursal',
            '10.00%', context),
        _lenderRow(
            '🔶', 'Bajaj Finance', 'NBFC · 60-min disbursal', '9.50%', context),
      ],
    );
  }

  Widget _infoCell(
      String label, String value, String note, BuildContext context,
      {bool isGreen = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 8,
                  color: widget.theme.getMutedColor(context),
                  weight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTextStyles.dmSans(
              size: 12.5,
              weight: FontWeight.w800,
              color: isGreen ? Colors.green : const Color(0xFFFFDEA0),
            ),
          ),
          const SizedBox(height: 2),
          Text(note,
              style: AppTextStyles.dmSans(
                  size: 8,
                  color: widget.theme
                      .getMutedColor(context)
                      .withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.grey.withValues(alpha: 0.2),
    );
  }

  Widget _modeButton(String mode) {
    final active = _repaymentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _repaymentMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFFD4AF37)
                : widget.theme.getBgColor(context),
            border: Border.all(
                color: active
                    ? const Color(0xFFD4AF37)
                    : widget.theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            mode,
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans(
              size: 9.5,
              weight: FontWeight.w800,
              color:
                  active ? Colors.white : widget.theme.getMutedColor(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _purityButton(int val, String label) {
    final active = _purity == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _purity = val),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFFD4AF37)
                : widget.theme.getBgColor(context),
            border: Border.all(
                color: active
                    ? const Color(0xFFD4AF37)
                    : widget.theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
              size: 11,
              weight: FontWeight.w800,
              color:
                  active ? Colors.white : widget.theme.getMutedColor(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ltvButton(double val, String label) {
    final active = _ltv == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _ltv = val),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFFD4AF37)
                : widget.theme.getBgColor(context),
            border: Border.all(
                color: active
                    ? const Color(0xFFD4AF37)
                    : widget.theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
              size: 11,
              weight: FontWeight.w800,
              color:
                  active ? Colors.white : widget.theme.getMutedColor(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tenureButton(int val, String label) {
    final active = _tenure == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tenure = val),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFFD4AF37)
                : widget.theme.getBgColor(context),
            border: Border.all(
                color: active
                    ? const Color(0xFFD4AF37)
                    : widget.theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
              size: 11,
              weight: FontWeight.w800,
              color:
                  active ? Colors.white : widget.theme.getMutedColor(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSyncedInputRow({
    required String label,
    required TextEditingController controller,
    required double value,
    required double min,
    required double max,
    String prefix = '',
    String suffix = '',
    required ValueChanged<double> onChangedText,
    required ValueChanged<double> onChangedSlider,
  }) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTextStyles.dmSans(
                    size: 8.5,
                    color: theme.getMutedColor(context),
                    weight: FontWeight.w800)),
            Text('$prefix${_fmtShort(value)}$suffix',
                style: AppTextStyles.dmSans(
                    size: 11.5,
                    weight: FontWeight.w800,
                    color: theme.getTextColor(context))),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.04),
            border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(11),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: AppTextStyles.dmSans(
                size: 13,
                color: theme.getTextColor(context),
                weight: FontWeight.w800),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
            ),
            onChanged: (v) {
              final parsed = double.tryParse(v);
              if (parsed != null && parsed >= min && parsed <= max) {
                onChangedText(parsed);
              }
            },
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFD4AF37),
            inactiveTrackColor: const Color(0xFFD4AF37).withValues(alpha: 0.15),
            thumbColor: const Color(0xFFFFDEA0),
            overlayColor: const Color(0xFFD4AF37).withValues(alpha: 0.24),
            trackHeight: 3.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChangedSlider,
          ),
        ),
      ],
    );
  }

  Widget _resultBox(String label, String value,
      {bool isRed = false, bool isGreen = false, bool isGold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(size: 8.5, color: Colors.white60),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.dmSans(
              size: 11.5,
              weight: FontWeight.w800,
              color: isRed
                  ? const Color(0xFFFCA5A5)
                  : isGreen
                      ? const Color(0xFF86EFAC)
                      : isGold
                          ? const Color(0xFFFFDEA0)
                          : Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _lenderRow(String icon, String name, String type, String rate,
      BuildContext context) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        border: Border.all(color: theme.getBorderColor(context)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.dmSans(
                        size: 12,
                        weight: FontWeight.w800,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 2),
                Text(type,
                    style: AppTextStyles.dmSans(
                        size: 9, color: theme.getMutedColor(context))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rate,
                  style: AppTextStyles.dmSans(
                      size: 14,
                      weight: FontWeight.w800,
                      color: const Color(0xFFB8960C))),
              Text('LTV up to 75%',
                  style: AppTextStyles.dmSans(
                      size: 8, color: theme.getMutedColor(context))),
            ],
          ),
        ],
      ),
    );
  }
}
