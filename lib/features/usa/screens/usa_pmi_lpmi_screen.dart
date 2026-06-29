// lib/features/usa/screens/usa_pmi_lpmi_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAPmiLpmiScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAPmiLpmiScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAPmiLpmiScreen> createState() => _USAPmiLpmiScreenState();
}

class _USAPmiLpmiScreenState extends ConsumerState<USAPmiLpmiScreen> {
  static const _theme = CountryThemes.usa;

  double _loanAmount = 380000;
  double _bpmiMonthly = 216;
  double _rateIncrease = 0.375;
  int _stayYears = 10;

  bool _calculating = false;
  bool _showResults = true;
  bool _isCalcDirty = false;

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _loanAmount = inputs['LoanAmt'] ?? 380000;
      _bpmiMonthly = inputs['BpmiMonthly'] ?? 216;
      _rateIncrease = inputs['RateIncrease'] ?? 0.375;
      _stayYears = (inputs['StayYears'] ?? 10.0).toInt();
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
      _loanAmount = 380000;
      _bpmiMonthly = 216;
      _rateIncrease = 0.375;
      _stayYears = 10;
      _showResults = true;
      _isCalcDirty = false;
    });
  }

  void _calculate() async {
    setState(() {
      _calculating = true;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _calculating = false;
      _showResults = true;
      _isCalcDirty = false;
    });
  }

  void _saveCalculation() async {
    final lpmiMonthlyExtra = (_loanAmount * (_rateIncrease / 100)) / 12;
    const bpmiCancelMonths = 84;
    final bpmiMonthsActive = min(_stayYears * 12, bpmiCancelMonths);
    final bpmiTotalCost = _bpmiMonthly * bpmiMonthsActive;
    final lpmiTotalCost = lpmiMonthlyExtra * _stayYears * 12;
    final recommendation = bpmiTotalCost < lpmiTotalCost ? 'BPMI Wins' : 'LPMI Wins';

    final labelCtrl = TextEditingController(text: 'LPMI Lender-Paid PMI');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_pmi_lpmi_screen'),
      builder: (context) => AlertDialog(
        backgroundColor: _theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Comparison',
            style: AppTextStyles.playfair(
                size: 16, color: _theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: Recommendation: $recommendation · Loan: ${CurrencyFormatter.compact(_loanAmount, symbol: r'$')}',
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
                hintText: 'Label (e.g. LPMI Comparison)',
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
          : 'LPMI Lender-Paid PMI';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'LPMI Lender-Paid PMI',
        inputs: {
          'LoanAmt': _loanAmount,
          'BpmiMonthly': _bpmiMonthly,
          'RateIncrease': _rateIncrease,
          'StayYears': _stayYears.toDouble(),
        },
        results: {
          'LPMI Monthly Extra': lpmiMonthlyExtra,
          'BPMI Total Cost': bpmiTotalCost,
          'LPMI Total Cost': lpmiTotalCost,
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
            backgroundColor: const Color(0xFFD97706),
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

    // Compute active calculation
    final lpmiMonthlyExtra = (_loanAmount * (_rateIncrease / 100)) / 12;
    const bpmiCancelMonths = 84;
    final bpmiMonthsActive = min(_stayYears * 12, bpmiCancelMonths);
    final bpmiTotalCost = _bpmiMonthly * bpmiMonthsActive;
    final lpmiTotalCost = lpmiMonthlyExtra * _stayYears * 12;
    final bpmiWins = bpmiTotalCost < lpmiTotalCost;

    // Chart Year Calculations
    final y3bpmi = _bpmiMonthly * 36;
    final y3lpmi = lpmiMonthlyExtra * 36;

    final y7bpmi = _bpmiMonthly * 84;
    final y7lpmi = lpmiMonthlyExtra * 84;

    final y15bpmi = _bpmiMonthly * 84; // assumes cancelled
    final y15lpmi = lpmiMonthlyExtra * 180;

    // Rate strip values
    final rateStats = [
      {'label': 'Rate Increase', 'value': '+0.25–0.50%', 'note': 'vs. market rate'},
      {'label': 'Cancellable?', 'value': 'Never', 'note': 'Refinance only', 'red': true},
      {'label': 'Break-Even', 'value': '~7 Years', 'note': 'Typical hold period'},
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
                        colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72), Color(0xFFD97706)],
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
                        '🏦',
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
                                  const Text('🏦', style: TextStyle(fontSize: 24)),
                                  Text(
                                    'LPMI – Lender-Paid PMI',
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
                              'Higher Rate · No Monthly Premium · Not Cancellable',
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
                  Color valColor = Colors.white;
                  if (stat['red'] == true) {
                    valColor = const Color(0xFFFCA5A5);
                  } else if (stat['label'] == 'Rate Increase') {
                    valColor = const Color(0xFFFCD34D);
                  }
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
                            stat['label'] as String,
                            style: AppTextStyles.dmSans(
                                size: 8.5, weight: FontWeight.w700, color: Colors.white54),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stat['value'] as String,
                            style: AppTextStyles.playfair(
                              size: 14,
                              weight: FontWeight.w800,
                              color: valColor,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            stat['note'] as String,
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
              // What is LPMI
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 12, 15, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'WHAT IS LPMI?',
                      style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBF0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Permanent Cost',
                        style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w700, color: const Color(0xFF991B1B)),
                      ),
                    ),
                  ],
                ),
              ),

              // Hero card
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
                      'Lender-Paid Private Mortgage Insurance',
                      style: AppTextStyles.dmSans(size: 9.5, color: Colors.white60, weight: FontWeight.w700, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 5),
                    RichText(
                      text: TextSpan(
                        text: 'Lender covers PMI upfront — ',
                        style: AppTextStyles.playfair(size: 16.5, color: Colors.white, weight: FontWeight.w700),
                        children: const [
                          TextSpan(
                            text: 'you pay forever via rate',
                            style: TextStyle(color: Color(0xFFFCD34D)),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildHeroBox('Upfront Cost', '\$0 to you'),
                        const SizedBox(width: 8),
                        _buildHeroBox('Payment Style', 'Built into rate'),
                        const SizedBox(width: 8),
                        _buildHeroBox('Cancellable?', 'No — ever', isRed: true),
                      ],
                    )
                  ],
                ),
              ),

              // Comparison Side by Side
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 18, 15, 8),
                child: Text(
                  'LPMI VS. BPMI — SIDE BY SIDE',
                  style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                ),
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // BPMI card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF15803D), Color(0xFF166534)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF15803D).withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('BPMI', style: AppTextStyles.playfair(size: 14.5, weight: FontWeight.w800, color: Colors.white)),
                            Text('Borrower-Paid (Standard)', style: AppTextStyles.dmSans(size: 8, color: Colors.white54)),
                            const SizedBox(height: 12),
                            _buildCompCol('Initial Monthly Cost', 'Higher (separate line item)'),
                            _buildCompCol('Long-Term (10+ yrs)', 'Usually cheaper overall'),
                            _buildCompCol('Removable?', 'Yes, at 80% LTV'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    // LPMI card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD97706), Color(0xFFB45309)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD97706).withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('LPMI', style: AppTextStyles.playfair(size: 14.5, weight: FontWeight.w800, color: Colors.white)),
                            Text('Lender-Paid (Rate-Based)', style: AppTextStyles.dmSans(size: 8, color: Colors.white54)),
                            const SizedBox(height: 12),
                            _buildCompCol('Initial Monthly Cost', 'Lower (hidden in rate)'),
                            _buildCompCol('Long-Term (10+ yrs)', 'Usually more expensive'),
                            _buildCompCol('Removable?', 'No — refinance only'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Break-Even Calculator Section
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 18, 15, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'BREAK-EVEN CALCULATOR',
                      style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                    ),
                    GestureDetector(
                      onTap: _resetInputs,
                      child: Text(
                        'Reset',
                        style: AppTextStyles.dmSans(size: 11, color: _theme.primaryColor, weight: FontWeight.w700),
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
                    Text('⚖️ Should You Choose LPMI?',
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

                    // BPMI Monthly Premium Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('BPMI Monthly Premium'.toUpperCase(),
                            style: AppTextStyles.dmSans(
                                size: 9.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 0.5)),
                        Text(CurrencyFormatter.format(_bpmiMonthly, symbol: r'$'),
                            style: AppTextStyles.playfair(
                                size: 13.5, weight: FontWeight.w800, color: _theme.primaryColor)),
                      ],
                    ),
                    Slider(
                      value: _bpmiMonthly,
                      min: 50,
                      max: 800,
                      divisions: 150,
                      activeColor: _theme.primaryColor,
                      inactiveColor: Colors.grey.withValues(alpha: 0.2),
                      onChanged: (val) {
                        setState(() {
                          _bpmiMonthly = val;
                          _markDirty();
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('\$50', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('\$300', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('\$550', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('\$800', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // LPMI Rate Increase Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('LPMI Rate Increase'.toUpperCase(),
                            style: AppTextStyles.dmSans(
                                size: 9.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 0.5)),
                        Text('${_rateIncrease.toStringAsFixed(3)}%',
                            style: AppTextStyles.playfair(
                                size: 13.5, weight: FontWeight.w800, color: _theme.primaryColor)),
                      ],
                    ),
                    Slider(
                      value: _rateIncrease,
                      min: 0.25,
                      max: 0.50,
                      divisions: 10,
                      activeColor: _theme.primaryColor,
                      inactiveColor: Colors.grey.withValues(alpha: 0.2),
                      onChanged: (val) {
                        setState(() {
                          _rateIncrease = val;
                          _markDirty();
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0.25%', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('0.375%', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('0.50%', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Years to stay Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Years You Plan to Stay'.toUpperCase(),
                            style: AppTextStyles.dmSans(
                                size: 9.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 0.5)),
                        Text('$_stayYears yrs',
                            style: AppTextStyles.playfair(
                                size: 13.5, weight: FontWeight.w800, color: _theme.primaryColor)),
                      ],
                    ),
                    Slider(
                      value: _stayYears.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      activeColor: _theme.primaryColor,
                      inactiveColor: Colors.grey.withValues(alpha: 0.2),
                      onChanged: (val) {
                        setState(() {
                          _stayYears = val.toInt();
                          _markDirty();
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('1 yr', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('10 yrs', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('20 yrs', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('30 yrs', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _calculate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD97706),
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
                                    'Compare LPMI vs BPMI',
                                    style: AppTextStyles.playfair(size: 13.5, weight: FontWeight.w800),
                                  ),
                          ),
                        ),
                        if (_showResults && !_isCalcDirty) ...[
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _saveCalculation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cardBg,
                              foregroundColor: const Color(0xFFD97706),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(color: Color(0xFFD97706), width: 1.5),
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
              if (_showResults && !_isCalcDirty) ...[
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0B1D3A).withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommendation',
                        style: AppTextStyles.dmSans(size: 9.5, color: Colors.white70, weight: FontWeight.w600, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bpmiWins ? 'BPMI Wins' : 'LPMI Wins',
                        style: AppTextStyles.playfair(size: 26, weight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bpmiWins
                            ? 'Over $_stayYears years, BPMI saves you ${CurrencyFormatter.format(lpmiTotalCost - bpmiTotalCost, symbol: r'$')} since it cancels around year 7'
                            : 'Over $_stayYears years, LPMI saves you ${CurrencyFormatter.format(bpmiTotalCost - lpmiTotalCost, symbol: r'$')} for your shorter hold period',
                        style: AppTextStyles.dmSans(size: 10, color: Colors.white.withValues(alpha: 0.8)),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _buildResultBox('LPMI Monthly Extra', CurrencyFormatter.format(lpmiMonthlyExtra, symbol: r'$'), isGold: true),
                          const SizedBox(width: 8),
                          _buildResultBox('BPMI Total Cost', CurrencyFormatter.format(bpmiTotalCost, symbol: r'$')),
                          const SizedBox(width: 8),
                          _buildResultBox('LPMI Total Cost', CurrencyFormatter.format(lpmiTotalCost, symbol: r'$')),
                        ],
                      )
                    ],
                  ),
                ),

                // Cost Over Time Chart Card
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 18, 15, 8),
                  child: Text(
                    'CUMULATIVE COST OVER TIME',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📈 BPMI vs LPMI — Total Cost by Year',
                        style: AppTextStyles.playfair(size: 12, weight: FontWeight.w800, color: textCol),
                      ),
                      const SizedBox(height: 16),
                      // Bar Year 3
                      _buildCostBarRow('Year 3', y3bpmi < y3lpmi ? 'BPMI lower: ${CurrencyFormatter.format(y3bpmi, symbol: r'$')}' : 'LPMI lower: ${CurrencyFormatter.format(y3lpmi, symbol: r'$')}', y3lpmi < y3bpmi ? 35 : 65, const Color(0xFFD97706), const Color(0xFFB45309), y3lpmi < y3bpmi ? 'LPMI ahead' : 'BPMI ahead'),
                      const SizedBox(height: 12),
                      // Bar Year 7
                      _buildCostBarRow('Year 7 (Typical Breakeven)', 'BPMI: ${CurrencyFormatter.format(y7bpmi, symbol: r'$')} · LPMI: ${CurrencyFormatter.format(y7lpmi, symbol: r'$')}', 50, const Color(0xFF1B3F72), const Color(0xFF0B1D3A), 'Crossover'),
                      const SizedBox(height: 12),
                      // Bar Year 15
                      _buildCostBarRow('Year 15', 'BPMI: ${CurrencyFormatter.format(y15bpmi, symbol: r'$')} · LPMI: ${CurrencyFormatter.format(y15lpmi, symbol: r'$')}', 78, const Color(0xFF15803D), const Color(0xFF166534), 'BPMI ahead'),
                      const SizedBox(height: 14),
                      Text(
                        'Assumes BPMI cancels at 80% LTV around year 7; LPMI rate premium continues for life of loan unless refinanced.',
                        style: AppTextStyles.dmSans(size: 9, color: mutedCol, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],

              // Key Facts
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 18, 15, 8),
                child: Text(
                  'LPMI KEY FACTS',
                  style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  children: [
                    _buildFactCard('🚫', 'Cannot Be Cancelled', 'The rate increase is baked into your note rate for the life of the loan — only a full refinance removes it.', 'Permanent', const Color(0xFFFEF2F2), const Color(0xFFB91C1C), cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildFactCard('💸', 'Lower Payment Up Front', 'No separate PMI line item can help you qualify for more home or keep payments lower initially.', 'Qualification Boost', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8), cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildFactCard('📉', 'Costs More If You Stay Long-Term', 'Once BPMI borrowers hit 80% LTV (~year 7-9) and cancel, LPMI borrowers keep paying the higher rate.', null, null, null, cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildFactCard('🔁', 'Best If You\'ll Refinance/Sell Soon', 'If you expect to move or refinance within 5-7 years, LPMI\'s lower monthly cost often wins.', 'Short-Term Play', const Color(0xFFF0FDF4), const Color(0xFF15803D), cardBg, textCol, mutedCol, borderCol),
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

  Widget _buildHeroBox(String label, String val, {bool isRed = false}) {
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
                color: isRed ? const Color(0xFFFCA5A5) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompCol(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.dmSans(size: 8, color: Colors.white54, weight: FontWeight.w800, letterSpacing: 0.3)),
          const SizedBox(height: 1),
          Text(val, style: AppTextStyles.dmSans(size: 10.5, color: Colors.white, weight: FontWeight.w700, height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildResultBox(String label, String val, {bool isGold = false}) {
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
              style: AppTextStyles.playfair(
                size: 13,
                weight: FontWeight.w800,
                color: isGold ? const Color(0xFFFCD34D) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostBarRow(String label, String sideLabel, double widthPct, Color barCol1, Color barCol2, String barText) {
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: textCol)),
            Text(sideLabel, style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w600, color: mutedCol)),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 22,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.72 * (widthPct / 100.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [barCol1, barCol2]),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  barText,
                  style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ),
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
