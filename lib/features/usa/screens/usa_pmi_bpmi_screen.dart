// lib/features/usa/screens/usa_pmi_bpmi_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAPmiBpmiScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAPmiBpmiScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAPmiBpmiScreen> createState() => _USAPmiBpmiScreenState();
}

class _USAPmiBpmiScreenState extends ConsumerState<USAPmiBpmiScreen> {
  static const _theme = CountryThemes.usa;

  double _price = 400000;
  double _downPct = 5.0;
  double _creditScore = 700;

  bool _calculating = false;
  bool _showResults = true;
  bool _isCalcDirty = false;

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _price = inputs['Price'] ?? 400000;
      _downPct = inputs['DownPct'] ?? 5.0;
      _creditScore = inputs['CreditScore'] ?? 700;
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
      _price = 400000;
      _downPct = 5.0;
      _creditScore = 700;
      _showResults = true;
      _isCalcDirty = false;
    });
  }

  double _getBpmiRate(double ltv, double score) {
    double band = 0.0;
    if (ltv > 95) {
      band = 1.50;
    } else if (ltv > 90) {
      band = score >= 760 ? 0.55 : score >= 680 ? 0.85 : 1.25;
    } else if (ltv > 85) {
      band = score >= 760 ? 0.38 : score >= 680 ? 0.58 : 0.85;
    } else if (ltv > 80) {
      band = score >= 760 ? 0.24 : score >= 680 ? 0.40 : 0.65;
    } else if (ltv > 78) {
      band = score >= 760 ? 0.17 : score >= 680 ? 0.22 : 0.35;
    } else {
      band = 0.0;
    }

    if (ltv > 95) {
      band = score >= 760 ? 0.80 : score >= 680 ? 1.10 : 1.50;
    }
    return band;
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
    final downAmt = _price * _downPct / 100;
    final loanAmt = _price - downAmt;
    final ltv = (loanAmt / _price) * 100;
    final rate = _getBpmiRate(ltv, _creditScore);
    final annualPmi = loanAmt * rate / 100;
    final monthlyPmi = rate > 0 ? (annualPmi / 12) : 0.0;

    final labelCtrl = TextEditingController(text: 'BPMI Borrower-Paid PMI');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_pmi_bpmi_screen/save'),
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
              'Saving: Monthly BPMI: ${CurrencyFormatter.compact(monthlyPmi, symbol: r'$')}/mo · LTV: ${ltv.toStringAsFixed(1)}%',
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
                hintText: 'Label (e.g. My BPMI)',
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
          : 'BPMI Borrower-Paid PMI';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'BPMI Borrower-Paid PMI',
        inputs: {
          'Price': _price,
          'DownPct': _downPct,
          'CreditScore': _creditScore,
        },
        results: {
          'Monthly BPMI': monthlyPmi,
          'Annual BPMI': annualPmi,
          'LTV Ratio': ltv,
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
            backgroundColor: const Color(0xFF15803D),
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
    final downAmt = _price * _downPct / 100;
    final loanAmt = _price - downAmt;
    final ltv = (loanAmt / _price) * 100;
    final rate = _getBpmiRate(ltv, _creditScore);
    final annualPmi = loanAmt * rate / 100;
    final monthlyPmi = rate > 0 ? (annualPmi / 12) : 0.0;

    // Years to 80% LTV (PMI cancellation timeline)
    const monthlyRate = 0.0682 / 12;
    final targetLoan = _price * 0.80;
    double balance = loanAmt;
    int months = 0;
    const nPayments = 360;
    final mp = loanAmt * (monthlyRate * pow(1 + monthlyRate, nPayments)) / (pow(1 + monthlyRate, nPayments) - 1);
    while (balance > targetLoan && months < nPayments) {
      balance = balance * (1 + monthlyRate) - mp;
      months++;
    }
    final double yearsTo80 = months / 12.0;

    // Rate strip values
    final rateStats = [
      {'label': 'Avg Annual Rate', 'value': '0.5–1.5%', 'note': 'Of loan amount'},
      {'label': 'Auto-Cancel', 'value': '78% LTV', 'note': 'By federal law'},
      {'label': 'Request at', 'value': '80% LTV', 'note': 'Borrower-initiated'},
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
                        colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72), Color(0xFFB91C1C)],
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
                        '💳',
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
                                  const Text('💳', style: TextStyle(fontSize: 24)),
                                  Text(
                                    'BPMI – Borrower-Paid PMI',
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
                              'Monthly Premium · Cancellable · Most Common',
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
                              color: stat['label'] == 'Avg Annual Rate' ? const Color(0xFFFCD34D) : Colors.white,
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
              // What is BPMI
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 12, 15, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'WHAT IS BPMI?',
                      style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Most Common Type',
                        style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w700, color: const Color(0xFF15803D)),
                      ),
                    ),
                  ],
                ),
              ),

              // Hero explaining BPMI
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
                      'Borrower-Paid Private Mortgage Insurance',
                      style: AppTextStyles.dmSans(size: 9.5, color: Colors.white60, weight: FontWeight.w700, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 5),
                    RichText(
                      text: TextSpan(
                        text: 'The default PMI — paid monthly, ',
                        style: AppTextStyles.playfair(size: 16.5, color: Colors.white, weight: FontWeight.w700),
                        children: const [
                          TextSpan(
                            text: 'cancellable at 20% equity',
                            style: TextStyle(color: Color(0xFFFCD34D)),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildHeroBox('Upfront Cost', '\$0', isGreen: true),
                        const SizedBox(width: 8),
                        _buildHeroBox('Payment Style', 'Monthly'),
                        const SizedBox(width: 8),
                        _buildHeroBox('Cancellable?', 'Yes', isGreen: true),
                      ],
                    )
                  ],
                ),
              ),

              // Calculator Section
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 18, 15, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'BPMI COST CALCULATOR',
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
                    // Price Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Home Purchase Price'.toUpperCase(),
                            style: AppTextStyles.dmSans(
                                size: 9.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 0.5)),
                        Text(CurrencyFormatter.format(_price, symbol: r'$'),
                            style: AppTextStyles.playfair(
                                size: 13.5, weight: FontWeight.w800, color: _theme.primaryColor)),
                      ],
                    ),
                    Slider(
                      value: _price,
                      min: 100000,
                      max: 1500000,
                      divisions: 280,
                      activeColor: _theme.primaryColor,
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
                        Text('\$100K', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('\$500K', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('\$1M', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('\$1.5M', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Down Payment Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Down Payment %'.toUpperCase(),
                            style: AppTextStyles.dmSans(
                                size: 9.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 0.5)),
                        Text('${_downPct.toStringAsFixed(1)}%',
                            style: AppTextStyles.playfair(
                                size: 13.5, weight: FontWeight.w800, color: _theme.primaryColor)),
                      ],
                    ),
                    Slider(
                      value: _downPct,
                      min: 3,
                      max: 19,
                      divisions: 32,
                      activeColor: _theme.primaryColor,
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
                        Text('3%', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('5%', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('10%', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('15%', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('19%', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Credit Score Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Credit Score'.toUpperCase(),
                            style: AppTextStyles.dmSans(
                                size: 9.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 0.5)),
                        Text('${_creditScore.toInt()}',
                            style: AppTextStyles.playfair(
                                size: 13.5, weight: FontWeight.w800, color: _theme.primaryColor)),
                      ],
                    ),
                    Slider(
                      value: _creditScore,
                      min: 620,
                      max: 850,
                      divisions: 23,
                      activeColor: _theme.primaryColor,
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
                        Text('620', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('680', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('720', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('780', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        Text('850', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
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
                              backgroundColor: const Color(0xFF15803D),
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
                                    'Calculate BPMI',
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
                              foregroundColor: const Color(0xFF15803D),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(color: Color(0xFF15803D), width: 1.5),
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

              // Result hero Card
              if (_showResults && !_isCalcDirty) ...[
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF15803D), Color(0xFF166534)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF15803D).withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly BPMI Premium',
                        style: AppTextStyles.dmSans(size: 9.5, color: Colors.white70, weight: FontWeight.w600, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rate > 0 ? CurrencyFormatter.format(monthlyPmi, symbol: r'$') : '\$0',
                        style: AppTextStyles.playfair(size: 34, weight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rate > 0
                            ? '${rate.toStringAsFixed(2)}%/yr · Added to mortgage payment'
                            : '✅ No PMI required — LTV ≤ 80%',
                        style: AppTextStyles.dmSans(size: 10, color: Colors.white.withValues(alpha: 0.7)),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _buildResultBox('Annual BPMI', rate > 0 ? CurrencyFormatter.format(annualPmi, symbol: r'$') : '\$0'),
                          const SizedBox(width: 8),
                          _buildResultBox('LTV Ratio', '${ltv.toStringAsFixed(1)}%'),
                          const SizedBox(width: 8),
                          _buildResultBox('Years to 80% LTV', ltv <= 80 ? 'Already there!' : '~${yearsTo80.toStringAsFixed(1)} yrs'),
                        ],
                      )
                    ],
                  ),
                ),

                // LTV Progress Chart
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 18, 15, 8),
                  child: Text(
                    'PATH TO CANCELLATION',
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
                        '📊 Your LTV Position',
                        style: AppTextStyles.playfair(size: 12, weight: FontWeight.w800, color: textCol),
                      ),
                      const SizedBox(height: 16),
                      // Custom painter tracking track
                      SizedBox(
                        height: 26,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _LtvPositionPainter(
                            ltv: ltv,
                            isDark: isDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Track Labels
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('100%', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                          Text('90%', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                          Text('80%', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                          Text('70%', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                          Text('60%', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Current LTV fill indicator bar
                      _buildProgressIndicatorRow('Current LTV', ltv, const Color(0xFFB91C1C), const Color(0xFF991B1B)),
                      const SizedBox(height: 10),
                      _buildProgressIndicatorRow('Target: Request Cancellation (80% LTV)', 80, const Color(0xFFD97706), const Color(0xFFB45309)),
                      const SizedBox(height: 10),
                      _buildProgressIndicatorRow('Target: Auto-Cancel (78% LTV)', 78, const Color(0xFF15803D), const Color(0xFF166534)),
                    ],
                  ),
                ),
              ],

              // Key Facts
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 18, 15, 8),
                child: Text(
                  'BPMI KEY FACTS',
                  style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  children: [
                    _buildFactCard('✅', 'Cancel Anytime at 80% LTV', 'Request removal once your loan balance hits 80% of original value — no refinance needed.', 'Borrower-Initiated', const Color(0xFFF0FDF4), const Color(0xFF15803D), cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildFactCard('⚡', 'Auto-Terminates at 78% LTV', 'Federal Homeowners Protection Act of 1998 requires automatic cancellation if payments are current.', 'By Law', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8), cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildFactCard('📈', 'New Appraisal Can Speed It Up', 'If your home appreciated, an appraisal may prove 80% LTV sooner than scheduled payments alone.', null, null, null, cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 8),
                    _buildFactCard('💰', '2026 Tax Deduction Restored', 'The One Big Beautiful Bill Act (2025) permanently restored the PMI deduction starting tax year 2026, phasing out above \$100K AGI.', 'Tax Year 2026+', const Color(0xFFF0FDF4), const Color(0xFF15803D), cardBg, textCol, mutedCol, borderCol),
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

  Widget _buildHeroBox(String label, String val, {bool isGreen = false}) {
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
                color: isGreen ? const Color(0xFF86EFAC) : Colors.white,
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

  Widget _buildProgressIndicatorRow(String title, double value, Color color1, Color color2) {
    final textCol = _theme.getTextColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: textCol)),
            Text('${value.toStringAsFixed(1)}%', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: textCol)),
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
                width: MediaQuery.of(context).size.width * 0.72 * (value / 100.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color1, color2]),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  '${value.toStringAsFixed(0)}%',
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

class _LtvPositionPainter extends CustomPainter {
  final double ltv;
  final bool isDark;

  _LtvPositionPainter({required this.ltv, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 5, size.width, 16);
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // LinearGradient for the background track
    // Colors match the HTML specification:
    // Red: 100% LTV to 80% LTV -> Left 0% to 50%
    // Yellow: 80% to 78% LTV -> Left 50% to 55%
    // Green: 78% to 60% LTV -> Left 55% to 100%
    final trackPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFEE2E2), // Red Zone
          Color(0xFFFEE2E2),
          Color(0xFFFEF3C7), // Yellow Zone
          Color(0xFFFEF3C7),
          Color(0xFFDCFCE7), // Green Zone
          Color(0xFFDCFCE7),
        ],
        stops: [0.0, 0.50, 0.50, 0.55, 0.55, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rRect, trackPaint);

    // Calculate current LTV position:
    // 100% is on the left, 60% is on the right.
    // Position offset goes linearly from 0.0 (100% LTV) to 1.0 (60% LTV).
    final pctOffset = ((100.0 - ltv) / 40.0).clamp(0.0, 1.0);
    final markerX = pctOffset * size.width;

    // Draw the indicator marker
    final markerPaint = Paint()
      ..color = isDark ? Colors.white : const Color(0xFF0B1D3A)
      ..style = PaintingStyle.fill;

    // Draw vertical marker bar
    final markerRect = Rect.fromLTWH(markerX - 1.5, 0, 3, 26);
    canvas.drawRRect(RRect.fromRectAndRadius(markerRect, const Radius.circular(1.5)), markerPaint);
  }

  @override
  bool shouldRepaint(covariant _LtvPositionPainter oldDelegate) {
    return oldDelegate.ltv != ltv || oldDelegate.isDark != isDark;
  }
}
