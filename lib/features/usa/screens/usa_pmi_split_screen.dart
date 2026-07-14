// lib/features/usa/screens/usa_pmi_split_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAPmiSplitScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAPmiSplitScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAPmiSplitScreen> createState() => _USAPmiSplitScreenState();
}

class _USAPmiSplitScreenState extends ConsumerState<USAPmiSplitScreen> {
  static const _theme = CountryThemes.usa;

  final _resultsKey = GlobalKey();
  final Map<String, dynamic> _calcSnapshot = {};

  double _loanAmount = 350000;
  double _bpmiRate = 0.75;
  double _splitPct = 35.0;

  bool _calculating = false;
  bool _showResults = false;
  bool _isCalcDirty = false;

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _loanAmount = inputs['LoanAmt'] ?? 350000;
      _bpmiRate = inputs['BpmiRate'] ?? 0.75;
      _splitPct = inputs['SplitPct'] ?? 35.0;
      _calcSnapshot['LoanAmt'] = _loanAmount;
      _calcSnapshot['BpmiRate'] = _bpmiRate;
      _calcSnapshot['SplitPct'] = _splitPct;
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
      _bpmiRate = 0.75;
      _splitPct = 35.0;
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
      _calcSnapshot['BpmiRate'] = _bpmiRate;
      _calcSnapshot['SplitPct'] = _splitPct;
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
    final bpmiRate = _calcSnapshot['BpmiRate'] ?? _bpmiRate;
    final splitPct = _calcSnapshot['SplitPct'] ?? _splitPct;

    final fullBpmiAnnual = loanAmt * bpmiRate / 100;
    final fullBpmiMonthly = fullBpmiAnnual / 12;
    final totalPremiumValue = fullBpmiAnnual * 5;
    final upfrontAmount = totalPremiumValue * (splitPct / 100);
    final remainingMonthlyFactor = 1.0 - (splitPct / 100) * 0.9;
    final monthlyAmount = fullBpmiMonthly * remainingMonthlyFactor;

    final labelCtrl = TextEditingController(text: 'Split Premium PMI');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_pmi_split_screen/save'),
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
              'Saving: Upfront: ${CurrencyFormatter.compact(upfrontAmount, symbol: r'$')} + ${CurrencyFormatter.compact(monthlyAmount, symbol: r'$')}/mo · Loan: ${CurrencyFormatter.compact(_loanAmount, symbol: r'$')}',
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
                hintText: 'Label (e.g. My Split PMI)',
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
          : 'Split Premium PMI';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'Split Premium PMI',
        inputs: {
          'LoanAmt': _loanAmount,
          'BpmiRate': _bpmiRate,
          'SplitPct': _splitPct,
        },
        results: {
          'Upfront Split': upfrontAmount,
          'Monthly Split': monthlyAmount,
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
            backgroundColor: const Color(0xFF0D9488),
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
    final double snapBpmiRate = _calcSnapshot['BpmiRate'] ?? _bpmiRate;
    final double snapSplitPct = _calcSnapshot['SplitPct'] ?? _splitPct;

    final fullBpmiAnnual = snapLoanAmount * snapBpmiRate / 100;
    final fullBpmiMonthly = fullBpmiAnnual / 12;

    // Total premium value approximated as 5x annual premium
    final totalPremiumValue = fullBpmiAnnual * 5;
    final upfrontAmount = totalPremiumValue * (snapSplitPct / 100);
    final remainingMonthlyFactor = 1.0 - (snapSplitPct / 100) * 0.9;
    final monthlyAmount = fullBpmiMonthly * remainingMonthlyFactor;
    final monthlySavings = fullBpmiMonthly - monthlyAmount;

    final isDirty = _showResults && (
      _loanAmount != snapLoanAmount ||
      _bpmiRate != snapBpmiRate ||
      _splitPct != snapSplitPct
    );

    // Rate strip values
    final rateStats = [
      {'label': 'Typical Upfront', 'value': '0.5–1.0%', 'note': 'Of loan amount'},
      {'label': 'Reduced Monthly', 'value': '~40–60%', 'note': 'Of full BPMI'},
      {'label': 'Cancellable?', 'value': 'Yes', 'note': 'At 80% LTV'},
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
                        colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72), Color(0xFF0D9488)],
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
                        '🔀',
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
                                  const Text('🔀', style: TextStyle(fontSize: 24)),
                                  Text(
                                    'Split Premium PMI',
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
                              'Partial Upfront + Reduced Monthly · Flexible',
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
                              color: stat['label'] == 'Typical Upfront' ? const Color(0xFFFCD34D) : stat['label'] == 'Reduced Monthly' ? const Color(0xFF5EEAD4) : Colors.white,
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
              // What is Split Premium
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 12, 15, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'WHAT IS SPLIT PREMIUM?',
                      style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDFA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Hybrid Option',
                        style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w700, color: const Color(0xFF0D9488)),
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
                      'Split Premium Private Mortgage Insurance',
                      style: AppTextStyles.dmSans(size: 9.5, color: Colors.white60, weight: FontWeight.w700, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 5),
                    RichText(
                      text: TextSpan(
                        text: 'A ',
                        style: AppTextStyles.playfair(size: 16.5, color: Colors.white, weight: FontWeight.w700),
                        children: const [
                          TextSpan(text: 'hybrid', style: TextStyle(color: Color(0xFFFCD34D))),
                          TextSpan(text: ' — some cash now, lower payments later')
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildHeroBox('Upfront Portion', '0.5–1.0%', isGold: true),
                        const SizedBox(width: 8),
                        _buildHeroBox('Monthly Portion', 'Reduced'),
                        const SizedBox(width: 8),
                        _buildHeroBox('Cancellable?', 'Yes', isTeal: true),
                      ],
                    )
                  ],
                ),
              ),

              // How Premium Splits Visual Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
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
                      '🔀 How Your Premium Splits',
                      style: AppTextStyles.playfair(size: 12, weight: FontWeight.w800, color: textCol),
                    ),
                    const SizedBox(height: 12),
                    // Split bar
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        children: [
                          Expanded(
                            flex: _splitPct.round(),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0F766E)]),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${_splitPct.round()}% Upfront',
                                style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: Colors.white),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: (100.0 - _splitPct).round(),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [Color(0xFFD97706), Color(0xFFB45309)]),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${(100.0 - _splitPct).round()}% Monthly',
                                style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Paid at closing (one-time)', style: AppTextStyles.dmSans(size: 9, color: mutedCol, weight: FontWeight.w700)),
                        Text('Paid monthly (cancellable)', style: AppTextStyles.dmSans(size: 9, color: mutedCol, weight: FontWeight.w700)),
                      ],
                    )
                  ],
                ),
              ),

              // Split Premium Calculator
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 12, 15, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SPLIT PREMIUM CALCULATOR',
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
                    Text('🔀 Customize Your Split',
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

                    // Full BPMI Equivalent Rate Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Full BPMI Equivalent Rate'.toUpperCase(),
                            style: AppTextStyles.dmSans(
                                size: 9.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 0.5)),
                        Text('${_bpmiRate.toStringAsFixed(2)}%',
                            style: AppTextStyles.playfair(
                                size: 13.5, weight: FontWeight.w800, color: _theme.primaryColor)),
                      ],
                    ),
                    Slider(
                      value: _bpmiRate,
                      min: 0.3,
                      max: 1.5,
                      divisions: 24,
                      activeColor: _theme.primaryColor,
                      inactiveColor: Colors.grey.withValues(alpha: 0.2),
                      onChanged: (val) {
                        setState(() {
                          _bpmiRate = val;
                          _markDirty();
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0.3%', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('0.75%', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('1.5%', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Upfront Split Percentage Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Upfront Split Percentage'.toUpperCase(),
                            style: AppTextStyles.dmSans(
                                size: 9.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 0.5)),
                        Text('${_splitPct.round()}%',
                            style: AppTextStyles.playfair(
                                size: 13.5, weight: FontWeight.w800, color: _theme.primaryColor)),
                      ],
                    ),
                    Slider(
                      value: _splitPct,
                      min: 10,
                      max: 75,
                      divisions: 13,
                      activeColor: _theme.primaryColor,
                      inactiveColor: Colors.grey.withValues(alpha: 0.2),
                      onChanged: (val) {
                        setState(() {
                          _splitPct = val;
                          _markDirty();
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('10%', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('35%', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('50%', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('75%', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
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
                              backgroundColor: const Color(0xFF0D9488),
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
                                    'Calculate Split Premium',
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
                              foregroundColor: const Color(0xFF0D9488),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
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
                      colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Split Premium Structure',
                        style: AppTextStyles.dmSans(size: 9.5, color: Colors.white70, weight: FontWeight.w600, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(upfrontAmount, symbol: r'$'),
                        style: AppTextStyles.playfair(size: 32, weight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Upfront (${_splitPct.round()}% split of total premium value) + reduced monthly payment',
                        style: AppTextStyles.dmSans(size: 10, color: Colors.white.withValues(alpha: 0.7)),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _buildResultBox('Monthly Payment', '${CurrencyFormatter.format(monthlyAmount, symbol: r'$')}/mo'),
                          const SizedBox(width: 8),
                          _buildResultBox('vs Full BPMI', '${CurrencyFormatter.format(fullBpmiMonthly, symbol: r'$')}/mo'),
                          const SizedBox(width: 8),
                          _buildResultBox('Monthly Savings', '${CurrencyFormatter.format(monthlySavings, symbol: r'$')}/mo'),
                        ],
                      )
                    ],
                  ),
                ),

                // All PMI Types Comparison Chart Card
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 18, 15, 8),
                  child: Text(
                    'ALL PMI TYPES — MONTHLY COST COMPARED',
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
                        '📊 Initial Monthly Cost by PMI Type',
                        style: AppTextStyles.playfair(size: 12, weight: FontWeight.w800, color: textCol),
                      ),
                      const SizedBox(height: 16),
                      // Bar 1: BPMI
                      _buildCompareBarRow('BPMI (Full Monthly)', '${CurrencyFormatter.format(fullBpmiMonthly, symbol: r'$')}/mo', 100, const Color(0xFFB91C1C), const Color(0xFF991B1B), CurrencyFormatter.format(fullBpmiMonthly, symbol: r'$')),
                      const SizedBox(height: 10),
                      // Bar 2: Split Premium
                      _buildCompareBarRow('Split Premium (This Page)', '${CurrencyFormatter.format(monthlyAmount, symbol: r'$')}/mo', (monthlyAmount / fullBpmiMonthly * 100.0), const Color(0xFF0D9488), const Color(0xFF0F766E), CurrencyFormatter.format(monthlyAmount, symbol: r'$')),
                      const SizedBox(height: 10),
                      // Bar 3: LPMI
                      _buildCompareBarRow('LPMI (Rate-Based Equivalent)', '\$0/mo + higher rate', 0, const Color(0xFFD97706), const Color(0xFFB45309), '\$0 direct'),
                      const SizedBox(height: 10),
                      // Bar 4: SPMI
                      _buildCompareBarRow('SPMI (Single Premium)', '\$0/mo, paid upfront', 0, const Color(0xFF6D28D9), const Color(0xFF5B21B6), '\$0 direct'),
                      const SizedBox(height: 14),
                      Text(
                        'LPMI and SPMI show \$0 monthly because their cost is paid via rate increase or upfront lump sum respectively.',
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
                  'SPLIT PREMIUM KEY FACTS',
                  style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  children: [
                    _buildFactCard('⚖️', 'Best of Both Worlds', 'Lower monthly payment than full BPMI, less cash needed upfront than full SPMI.', 'Balanced', const Color(0xFFF0FDFA), const Color(0xFF0D9488), cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildFactCard('✅', 'Still Cancellable at 80% LTV', 'Unlike LPMI, the ongoing monthly portion of split premium can be cancelled once you reach 20% equity.', 'Borrower-Friendly', const Color(0xFFF0FDF4), const Color(0xFF15803D), cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildFactCard('💡', 'Good for Tight Cash Budgets', 'If you can\'t afford a full single premium but want lower monthly payments, split premium bridges the gap.', 'Flexible Closing Costs', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8), cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildFactCard('📉', 'Upfront Portion Non-Refundable', 'Similar to SPMI, the lump-sum part paid at closing typically isn\'t refunded if you sell or refinance early.', null, null, null, cardBg, textCol, mutedCol, borderCol),
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

  Widget _buildHeroBox(String label, String val, {bool isGold = false, bool isTeal = false}) {
    Color col = Colors.white;
    if (isGold) {
      col = const Color(0xFFFCD34D);
    } else if (isTeal) {
      col = const Color(0xFF5EEAD4);
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

  Widget _buildCompareBarRow(String label, String sideLabel, double widthPct, Color barCol1, Color barCol2, String barText) {
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
              if (widthPct > 0)
                Container(
                  width: max(MediaQuery.of(context).size.width * 0.72 * (widthPct / 100.0), 30.0),
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
                )
              else
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Center(
                    child: Text(
                      barText,
                      style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: mutedCol),
                    ),
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
