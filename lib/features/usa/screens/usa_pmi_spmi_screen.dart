// lib/features/usa/screens/usa_pmi_spmi_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAPmiSpmiScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAPmiSpmiScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAPmiSpmiScreen> createState() => _USAPmiSpmiScreenState();
}

class _USAPmiSpmiScreenState extends ConsumerState<USAPmiSpmiScreen> {
  static const _theme = CountryThemes.usa;

  final _resultsKey = GlobalKey();
  final Map<String, dynamic> _calcSnapshot = {};

  double _loanAmount = 350000;
  double _spmiRate = 2.0;
  String _payMethod = 'cash'; // 'cash' or 'financed'
  double _mortgageRate = 6.75;

  bool _calculating = false;
  bool _showResults = false;
  bool _isCalcDirty = false;

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _loanAmount = inputs['LoanAmt'] ?? 350000;
      _spmiRate = inputs['SpmiRate'] ?? 2.0;
      final method = inputs['PayMethod'];
      _payMethod = method == 1.0 ? 'financed' : 'cash';
      _mortgageRate = inputs['MtgRate'] ?? 6.75;
      _calcSnapshot['LoanAmt'] = _loanAmount;
      _calcSnapshot['SpmiRate'] = _spmiRate;
      _calcSnapshot['PayMethod'] = _payMethod;
      _calcSnapshot['MtgRate'] = _mortgageRate;
      _showResults = true;
    }
  }

  void _markDirty() {
    if (!_isCalcDirty) {
      setState(() {
        _isCalcDirty = true;
      });
    }
  }

  void _resetInputs() {
    setState(() {
      _loanAmount = 350000;
      _spmiRate = 2.0;
      _payMethod = 'cash';
      _mortgageRate = 6.75;
      _showResults = false;
      _isCalcDirty = false;
      _calcSnapshot.clear();
    });
  }

  void _calculate() async {
    setState(() {
      _calculating = true;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _calculating = false;
      _calcSnapshot['LoanAmt'] = _loanAmount;
      _calcSnapshot['SpmiRate'] = _spmiRate;
      _calcSnapshot['PayMethod'] = _payMethod;
      _calcSnapshot['MtgRate'] = _mortgageRate;
      _showResults = true;
      _isCalcDirty = false;
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

  void _saveCalculation() async {
    final loanAmt = _calcSnapshot['LoanAmt'] ?? _loanAmount;
    final spmiRate = _calcSnapshot['SpmiRate'] ?? _spmiRate;
    final payMethod = _calcSnapshot['PayMethod'] ?? _payMethod;
    final mortgageRate = _calcSnapshot['MtgRate'] ?? _mortgageRate;

    final spmiAmount = loanAmt * spmiRate / 100;
    final equivBpmiMonthly = (loanAmt * 0.0075) / 12;
    final breakEvenMonths = spmiAmount / equivBpmiMonthly;

    double financedMonthlyAdd = 0.0;
    if (payMethod == 'financed') {
      final newLoan = loanAmt + spmiAmount;
      final monthlyRate = mortgageRate / 100 / 12;
      const n = 360;
      final fullPmt = newLoan * (monthlyRate * pow(1 + monthlyRate, n)) / (pow(1 + monthlyRate, n) - 1);
      final basePmt = loanAmt * (monthlyRate * pow(1 + monthlyRate, n)) / (pow(1 + monthlyRate, n) - 1);
      financedMonthlyAdd = fullPmt - basePmt;
    }

    final labelCtrl = TextEditingController(text: 'SPMI Single Premium PMI');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_pmi_spmi_screen/save'),
      builder: (context) => AlertDialog(
        backgroundColor: _theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Calculation',
            style: AppTextStyles.playfair(
                size: 16, color: _theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: Premium: ${CurrencyFormatter.compact(spmiAmount, symbol: r'$')} · Loan: ${CurrencyFormatter.compact(_loanAmount, symbol: r'$')} · ${_payMethod.toUpperCase()}',
              style: AppTextStyles.dmSans(
                  size: 11, color: _theme.getMutedColor(context)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: _theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My SPMI)',
                hintStyle: AppTextStyles.dmSans(size: 13, color: Colors.grey),
                filled: true,
                fillColor: _theme.getBgColor(context),
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
              backgroundColor: _theme.primaryColor,
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
          : 'SPMI Single Premium PMI';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'SPMI Single Premium PMI',
        inputs: {
          'LoanAmt': loanAmt,
          'SpmiRate': spmiRate,
          'PayMethod': payMethod == 'financed' ? 1.0 : 0.0,
          'MtgRate': mortgageRate,
        },
        results: {
          'Single Premium': spmiAmount,
          'vs. BPMI Monthly': equivBpmiMonthly,
          'Break-Even Months': breakEvenMonths,
          'Financed Monthly': financedMonthlyAdd,
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
            backgroundColor: const Color(0xFF6D28D9),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = _theme.getCardColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);
    final borderCol = _theme.getBorderColor(context);
    final bgCol = _theme.getBgColor(context);

    // Compute active calculation from snapshot or default to current values when not calculated yet
    final double snapLoanAmount = _calcSnapshot['LoanAmt'] ?? _loanAmount;
    final double snapSpmiRate = _calcSnapshot['SpmiRate'] ?? _spmiRate;
    final String snapPayMethod = _calcSnapshot['PayMethod'] ?? _payMethod;
    final double snapMortgageRate = _calcSnapshot['MtgRate'] ?? _mortgageRate;

    final spmiAmount = snapLoanAmount * snapSpmiRate / 100;
    final equivBpmiMonthly = (snapLoanAmount * 0.0075) / 12;
    final breakEvenMonths = spmiAmount / equivBpmiMonthly;

    double financedMonthlyAdd = 0.0;
    if (snapPayMethod == 'financed') {
      final newLoan = snapLoanAmount + spmiAmount;
      final monthlyRate = snapMortgageRate / 100 / 12;
      const n = 360;
      final fullPmt = newLoan * (monthlyRate * pow(1 + monthlyRate, n)) / (pow(1 + monthlyRate, n) - 1);
      final basePmt = snapLoanAmount * (monthlyRate * pow(1 + monthlyRate, n)) / (pow(1 + monthlyRate, n) - 1);
      financedMonthlyAdd = fullPmt - basePmt;
    }

    final isDirty = _showResults && (
      _loanAmount != snapLoanAmount ||
      _spmiRate != snapSpmiRate ||
      _payMethod != snapPayMethod ||
      _mortgageRate != snapMortgageRate
    );

    // Rate strip values
    final rateStats = [
      {'label': 'Upfront Cost', 'value': '1.0–3.0%', 'note': 'Of loan amount'},
      {'label': 'Monthly PMI', 'value': '\$0', 'note': 'Eliminated'},
      {'label': 'Refund on Sale?', 'value': 'No', 'note': 'Non-refundable'},
    ];

    return Scaffold(
      backgroundColor: bgCol,
      body: CustomScrollView(
        slivers: [
          // Header with gradient
          SliverAppBar(
            expandedHeight: 155,
            pinned: true,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72), Color(0xFF6D28D9)],
                        stops: [0.0, 0.55, 1.0],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 50,
                    child: Opacity(
                      opacity: 0.07,
                      child: Text(
                        '💵',
                        style: TextStyle(
                          fontSize: 72,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => context.pop(),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text('←', style: TextStyle(color: Colors.white, fontSize: 16)),
                                ),
                              ),
                              Column(
                                children: [
                                  const Text('💵', style: TextStyle(fontSize: 24)),
                                  Text(
                                    'SPMI – Single Premium',
                                    style: AppTextStyles.playfair(size: 16, color: Colors.white, weight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 36), // Balance
                            ],
                          ),
                          const Spacer(),
                          Center(
                            child: Text(
                              'One Upfront Payment · No Monthly Premium',
                              style: AppTextStyles.dmSans(size: 9.5, color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Rate Strip Block
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFF1B3F72),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: rateStats.map((stat) {
                  final idx = rateStats.indexOf(stat);
                  final isLast = idx == rateStats.length - 1;
                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : Border(
                                right: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    width: 1),
                              ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            stat['label']!,
                            style: AppTextStyles.dmSans(
                                size: 8.5, weight: FontWeight.w700, color: Colors.white54),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stat['value']!,
                            style: AppTextStyles.playfair(
                              size: 14,
                              weight: FontWeight.w800,
                              color: stat['label'] == 'Upfront Cost' ? const Color(0xFFFCD34D) : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            stat['note']!,
                            style: AppTextStyles.dmSans(
                                size: 7.5, color: Colors.white38),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Content body
          SliverList(
            delegate: SliverChildListDelegate([
              // What is SPMI
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 12, 15, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'WHAT IS SPMI?',
                      style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Lump Sum',
                        style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w700, color: const Color(0xFF6D28D9)),
                      ),
                    ),
                  ],
                ),
              ),

              // Hero Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                padding: const EdgeInsets.all(19),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0B1D3A).withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Single Premium Private Mortgage Insurance',
                      style: AppTextStyles.dmSans(size: 9.5, color: Colors.white60, weight: FontWeight.w700, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 5),
                    RichText(
                      text: TextSpan(
                        text: 'Pay all your PMI ',
                        style: AppTextStyles.playfair(size: 16.5, color: Colors.white, weight: FontWeight.w700),
                        children: const [
                          TextSpan(
                            text: 'at closing — once',
                            style: TextStyle(color: Color(0xFFFCD34D)),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildHeroBox('Upfront Cost', '1–3% of loan', isGold: true),
                        const SizedBox(width: 8),
                        _buildHeroBox('Monthly Cost', '\$0'),
                        const SizedBox(width: 8),
                        _buildHeroBox('Can Finance It?', 'Often Yes', isPurple: true),
                      ],
                    )
                  ],
                ),
              ),

              // Calculator
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 18, 15, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SPMI COST CALCULATOR',
                      style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                    ),
                    GestureDetector(
                      onTap: _resetInputs,
                      child: Text(
                        'Reset',
                        style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w700, color: _theme.primaryColor),
                      ),
                    ),
                  ],
                ),
              ),

              // Input Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderCol),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💵 Calculate Your Upfront Premium',
                        style: AppTextStyles.playfair(size: 12, weight: FontWeight.w800, color: textCol)),
                    const SizedBox(height: 14),

                    // Loan Amount Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Loan Amount'.toUpperCase(),
                            style: AppTextStyles.dmSans(
                                size: 9.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 0.5)),
                        Text(CurrencyFormatter.format(_loanAmount, symbol: r'$'),
                            style: AppTextStyles.playfair(
                                size: 13.5, weight: FontWeight.w800, color: _theme.primaryColor)),
                      ],
                    ),
                    Slider(
                      value: _loanAmount,
                      min: 100000,
                      max: 1200000,
                      divisions: 220,
                      activeColor: _theme.primaryColor,
                      inactiveColor: Colors.grey.withValues(alpha: 0.2),
                      onChanged: (val) {
                        setState(() {
                          _loanAmount = val;
                          _markDirty();
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('\$100K', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('\$500K', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('\$1M', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('\$1.2M', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Single Premium Rate Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Single Premium Rate'.toUpperCase(),
                            style: AppTextStyles.dmSans(
                                size: 9.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 0.5)),
                        Text('${_spmiRate.toStringAsFixed(1)}%',
                            style: AppTextStyles.playfair(
                                size: 13.5, weight: FontWeight.w800, color: _theme.primaryColor)),
                      ],
                    ),
                    Slider(
                      value: _spmiRate,
                      min: 1.0,
                      max: 3.0,
                      divisions: 20,
                      activeColor: _theme.primaryColor,
                      inactiveColor: Colors.grey.withValues(alpha: 0.2),
                      onChanged: (val) {
                        setState(() {
                          _spmiRate = val;
                          _markDirty();
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('1.0%', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('1.5%', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('2.0%', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('2.5%', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('3.0%', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Payment Method Toggle
                    Text('Payment Method'.toUpperCase(),
                        style: AppTextStyles.dmSans(
                            size: 9.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildMethodBtn('Pay Cash at Closing', 'cash'),
                        const SizedBox(width: 8),
                        _buildMethodBtn('Finance into Loan', 'financed'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Financed Rate Group
                    if (_payMethod == 'financed') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Mortgage Rate (if financed)'.toUpperCase(),
                              style: AppTextStyles.dmSans(
                                  size: 9.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 0.5)),
                          Text('${_mortgageRate.toStringAsFixed(2)}%',
                              style: AppTextStyles.playfair(
                                  size: 13.5, weight: FontWeight.w800, color: _theme.primaryColor)),
                        ],
                      ),
                      Slider(
                        value: _mortgageRate,
                        min: 5.0,
                        max: 8.5,
                        divisions: 70,
                        activeColor: _theme.primaryColor,
                        inactiveColor: Colors.grey.withValues(alpha: 0.2),
                        onChanged: (val) {
                          setState(() {
                            _mortgageRate = val;
                            _markDirty();
                          });
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('5%', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                          Text('6.75%', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                          Text('8.5%', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _calculate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6D28D9),
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
                                    'Calculate SPMI Cost',
                                    style: AppTextStyles.playfair(size: 13.5, weight: FontWeight.w800),
                                  ),
                          ),
                        ),
                        if (_showResults) ...[
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _saveCalculation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cardBg,
                              foregroundColor: const Color(0xFF6D28D9),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(color: Color(0xFF6D28D9), width: 1.5),
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

              // Result Hero Card
              if (_showResults) ...[
                if (isDirty) ...[
                  const SizedBox(height: 12),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15),
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
                const SizedBox(height: 10),
                Container(
                  key: _resultsKey,
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6D28D9), Color(0xFF5B21B6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6D28D9).withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Single Premium Due at Closing',
                        style: AppTextStyles.dmSans(size: 9.5, color: Colors.white70, weight: FontWeight.w600, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(spmiAmount, symbol: r'$'),
                        style: AppTextStyles.playfair(size: 32, weight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${snapSpmiRate.toStringAsFixed(1)}% of ${CurrencyFormatter.format(snapLoanAmount, symbol: r'$')} loan · Paid once, no monthly PMI',
                        style: AppTextStyles.dmSans(size: 10, color: Colors.white.withValues(alpha: 0.7)),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _buildResultBox('vs. BPMI Monthly (Est)', CurrencyFormatter.format(equivBpmiMonthly, symbol: r'$')),
                          const SizedBox(width: 8),
                          _buildResultBox('Break-Even Point', '~${breakEvenMonths.round()} mo'),
                          const SizedBox(width: 8),
                          _buildResultBox('If Financed: +Monthly', snapPayMethod == 'financed' ? '+${CurrencyFormatter.format(financedMonthlyAdd, symbol: r'$')}/mo' : 'N/A (cash)'),
                        ],
                      )
                    ],
                  ),
                ),

                // Loan Impact Breakdown Card (Donut Chart)
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 18, 15, 8),
                  child: Text(
                    'LOAN IMPACT BREAKDOWN',
                    style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                  ),
                ),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol),
                  ),
                  child: Row(
                    children: [
                      // Donut graphic
                      SizedBox(
                        height: 108,
                        width: 108,
                        child: CustomPaint(
                          painter: _SpmiDonutPainter(
                            spmiPct: snapSpmiRate,
                            textColor: textCol,
                            mutedColor: mutedCol,
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      // Legend
                      Expanded(
                        child: Column(
                          children: [
                            _buildLegendRow('Base Loan Amount', snapLoanAmount, const Color(0xFF1B3F72)),
                            const SizedBox(height: 9),
                            _buildLegendRow('SPMI Premium', spmiAmount, const Color(0xFF6D28D9)),
                            const SizedBox(height: 9),
                            _buildLegendRow('Total if Financed', snapLoanAmount + spmiAmount, const Color(0xFFD97706)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Key Facts
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 18, 15, 8),
                child: Text(
                  'SPMI KEY FACTS',
                  style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  children: [
                    _buildFactCard('💰', 'No Monthly PMI Line Item', 'Your mortgage statement shows P&I only — no separate PMI charge to track or cancel later.', 'Simpler Statement', const Color(0xFFF0FDF4), const Color(0xFF15803D), cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildFactCard('🏠', 'Best for Long-Term Holders', 'If you plan to keep the loan 5+ years, paying upfront often beats years of monthly BPMI premiums.', 'Buy & Hold', const Color(0xFFF5F3FF), const Color(0xFF6D28D9), cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildFactCard('⚠️', 'Non-Refundable if You Sell Early', 'Unlike BPMI which simply stops, SPMI paid upfront is not refunded if you sell or refinance quickly.', 'Sunk Cost Risk', const Color(0xFFFEF2F2), const Color(0xFFB91C1C), cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildFactCard('🏦', 'Can Be Financed Into the Loan', 'Rolling SPMI into your mortgage avoids cash at closing, but you\'ll pay mortgage interest on it too.', 'Cash-Flow Friendly', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8), cardBg, textCol, mutedCol, borderCol),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBox(String label, String val, {bool isGold = false, bool isPurple = false}) {
    Color col = Colors.white;
    if (isGold) {
      col = const Color(0xFFFCD34D);
    } else if (isPurple) {
      col = const Color(0xFFC4B5FD);
    }
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54, weight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
              val,
              style: AppTextStyles.playfair(
                size: 13,
                weight: FontWeight.w800,
                color: col,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodBtn(String label, String code) {
    final isSelected = _payMethod == code;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _payMethod = code;
            _markDirty();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6D28D9) : _theme.getBgColor(context),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: isSelected ? const Color(0xFF6D28D9) : _theme.getBorderColor(context),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
              size: 11.5,
              weight: FontWeight.w700,
              color: isSelected ? Colors.white : _theme.getMutedColor(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultBox(String label, String val) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white60)),
            const SizedBox(height: 2),
            Text(
              val,
              style: AppTextStyles.playfair(size: 13, weight: FontWeight.w800, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendRow(String name, double val, Color color) {
    final textColor = _theme.getTextColor(context);
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
        Expanded(child: Text(name, style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w700, color: textColor), overflow: TextOverflow.ellipsis)),
        Text(
          CurrencyFormatter.format(val, symbol: r'$'),
          style: AppTextStyles.playfair(size: 11.5, weight: FontWeight.w800, color: textColor),
        ),
      ],
    );
  }

  Widget _buildFactCard(
      String icon,
      String title,
      String subtitle,
      String? badgeText,
      Color? badgeBg,
      Color? badgeTextCol,
      Color cardBg,
      Color textCol,
      Color mutedCol,
      Color borderCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol),
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
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _theme.getBgColor(context),
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
                  style: AppTextStyles.playfair(size: 12.5, weight: FontWeight.w800, color: textCol),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.dmSans(size: 9.5, color: mutedCol, height: 1.4),
                ),
                if (badgeText != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badgeText,
                      style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w700, color: badgeTextCol ?? Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpmiDonutPainter extends CustomPainter {
  final double spmiPct;
  final Color textColor;
  final Color mutedColor;

  const _SpmiDonutPainter({
    required this.spmiPct,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 6;
    const strokeWidth = 10.0;

    // Background track circle
    final bgPaint = Paint()
      ..color = const Color(0xFFEEF2FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Calculate angles: SPMI covers spmiPct of the donut (roughly amplified visually or direct percentage scale)
    // In HTML: spmiPct / 100 * 2pi is the sweep.
    final spmiSweep = (spmiPct / 100.0) * 2 * pi;
    final loanSweep = 2 * pi - spmiSweep;

    // Base Loan arc
    final loanPaint = Paint()
      ..color = const Color(0xFF1B3F72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      loanSweep,
      false,
      loanPaint,
    );

    // SPMI arc
    final spmiPaint = Paint()
      ..color = const Color(0xFF6D28D9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2 + loanSweep,
      spmiSweep,
      false,
      spmiPaint,
    );

    // Inner Text
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: '${spmiPct.toStringAsFixed(1)}%',
      style: AppTextStyles.playfair(size: 13.5, weight: FontWeight.w800, color: textColor),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2 - 4));

    textPainter.text = TextSpan(
      text: 'of Loan',
      style: AppTextStyles.dmSans(size: 7.5, color: mutedColor, weight: FontWeight.w700),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2 + 8));
  }

  @override
  bool shouldRepaint(covariant _SpmiDonutPainter oldDelegate) {
    return oldDelegate.spmiPct != spmiPct ||
        oldDelegate.textColor != textColor ||
        oldDelegate.mutedColor != mutedColor;
  }
}
