// lib/features/usa/screens/usa_fha_203k_alternative_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAFha203kAlternativeScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAFha203kAlternativeScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAFha203kAlternativeScreen> createState() => _USAFha203kAlternativeScreenState();
}

class _USAFha203kAlternativeScreenState extends ConsumerState<USAFha203kAlternativeScreen> {
  static const _theme = CountryThemes.usa;

  // Constants
  static const double _fhaFloor = 541287;
  static const double _fhaCeiling = 1249125;

  final _resultsKey = GlobalKey();
  final Map<String, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};

  // Controllers
  final _purchasePriceController = TextEditingController(text: '280000');
  final _renoCostController = TextEditingController(text: '60000');
  final _kRateController = TextEditingController(text: '7.25');
  final _contPctController = TextEditingController(text: '15');

  String _kType = 'limited'; // limited, standard
  String _creditTier = '580+'; // 580+, 500-579

  bool _calculated = false;



  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _purchasePriceController.text = (inputs['PurchasePrice'] ?? 280000.0).toStringAsFixed(0);
      _renoCostController.text = (inputs['RenoCost'] ?? 60000.0).toStringAsFixed(0);
      _kType = (inputs['KType'] ?? 0.0) == 0.0 ? 'limited' : 'standard';
      _creditTier = (inputs['CreditTier'] ?? 0.0) == 0.0 ? '580+' : '500-579';
      _kRateController.text = (inputs['Rate'] ?? 7.25).toStringAsFixed(2);
      _contPctController.text = (inputs['ContPct'] ?? 15.0).toStringAsFixed(0);
      _calculate();
    }
  }

  @override
  void dispose() {
    _purchasePriceController.dispose();
    _renoCostController.dispose();
    _kRateController.dispose();
    _contPctController.dispose();
    super.dispose();
  }

  void _calculate() {
    final errors = <String, String>{};
    final purchase = double.tryParse(_purchasePriceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final reno = double.tryParse(_renoCostController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final rateVal = double.tryParse(_kRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final contPctVal = double.tryParse(_contPctController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    if (purchase <= 0) errors['purchase'] = 'Enter positive purchase price';
    if (reno <= 0) errors['reno'] = 'Enter positive renovation cost';
    if (rateVal <= 0) errors['rate'] = 'Enter positive rate';
    if (contPctVal < 0 || contPctVal >= 100) errors['contPct'] = 'Enter valid percentage (0-99)';

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) {
      setState(() {
        _calculated = false;
      });
      return;
    }

    final rate = rateVal / 100;
    final contPct = contPctVal / 100;

    final contAmt = reno * contPct;
    final rehabBudget = reno + contAmt;
    final totalProject = purchase + rehabBudget;

    final downPct = _creditTier == '580+' ? 0.035 : 0.10;
    final downAmt = totalProject * downPct;
    final baseLoan = totalProject - downAmt;

    final ufmip = baseLoan * 0.0175;
    final financedLoan = baseLoan + ufmip;

    final annualMipRate = downPct >= 0.10 ? 0.0050 : 0.0055;
    final monthlyMip = financedLoan * annualMipRate / 12;

    const int months = 360;
    final double mr = rate / 12;
    final monthlyPI = mr == 0
        ? financedLoan / months
        : financedLoan * (mr * pow(1 + mr, months)) / (pow(1 + mr, months) - 1);

    final totalMonthly = monthlyPI + monthlyMip;
    final originationFee = max(350.0, baseLoan * 0.015);

    final capExceeded = _kType == 'limited' && rehabBudget > 75000;

    setState(() {
      _calcSnapshot['PurchasePrice'] = purchase;
      _calcSnapshot['RenoCost'] = reno;
      _calcSnapshot['Rate'] = rateVal;
      _calcSnapshot['ContPct'] = contPctVal;
      _calcSnapshot['KType'] = _kType;
      _calcSnapshot['CreditTier'] = _creditTier;

      _calcSnapshot['ContAmt'] = contAmt;
      _calcSnapshot['TotalProject'] = totalProject;
      _calcSnapshot['DownPct'] = downPct;
      _calcSnapshot['DownAmt'] = downAmt;
      _calcSnapshot['BaseLoan'] = baseLoan;
      _calcSnapshot['Ufmip'] = ufmip;
      _calcSnapshot['FinancedLoan'] = financedLoan;
      _calcSnapshot['AnnualMipRate'] = annualMipRate;
      _calcSnapshot['MonthlyMip'] = monthlyMip;
      _calcSnapshot['MonthlyPI'] = monthlyPI;
      _calcSnapshot['TotalMonthly'] = totalMonthly;
      _calcSnapshot['OriginationFee'] = originationFee;
      _calcSnapshot['CapExceeded'] = capExceeded;

      _calculated = true;
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

  void _saveCalc() {
    if (!_calculated) return;

    final purchase = _calcSnapshot['PurchasePrice'] ?? 280000.0;
    final reno = _calcSnapshot['RenoCost'] ?? 60000.0;
    final rate = _calcSnapshot['Rate'] ?? 7.25;
    final contPct = _calcSnapshot['ContPct'] ?? 15.0;
    final kTypeVal = _calcSnapshot['KType'] ?? 'limited';
    final creditTierVal = _calcSnapshot['CreditTier'] ?? '580+';

    final snapTotalMonthly = _calcSnapshot['TotalMonthly'] ?? 0.0;
    final snapDownAmt = _calcSnapshot['DownAmt'] ?? 0.0;
    final snapFinancedLoan = _calcSnapshot['FinancedLoan'] ?? 0.0;
    final snapBaseLoan = _calcSnapshot['BaseLoan'] ?? 0.0;
    final snapUfmip = _calcSnapshot['Ufmip'] ?? 0.0;
    final snapMonthlyMip = _calcSnapshot['MonthlyMip'] ?? 0.0;
    final snapMonthlyPI = _calcSnapshot['MonthlyPI'] ?? 0.0;
    final snapOriginationFee = _calcSnapshot['OriginationFee'] ?? 0.0;

    final formattedPayment = CurrencyFormatter.format(snapTotalMonthly, symbol: '\$').split('.').first;
    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'FHA 203k Alternative',
      label: '203(k) Alternative ($formattedPayment/mo)',
      currencyCode: 'USD',
      inputs: {
        'PurchasePrice': purchase,
        'RenoCost': reno,
        'KType': kTypeVal == 'limited' ? 0.0 : 1.0,
        'CreditTier': creditTierVal == '580+' ? 0.0 : 1.0,
        'Rate': rate,
        'ContPct': contPct,
      },
      results: {
        'MonthlyPayment': snapTotalMonthly,
        'DownPaymentAmt': snapDownAmt,
        'FinancedLoanAmt': snapFinancedLoan,
        'BaseLoanAmt': snapBaseLoan,
        'UpfrontMip': snapUfmip,
        'MonthlyMip': snapMonthlyMip,
        'MonthlyPI': snapMonthlyPI,
        'OriginationFee': snapOriginationFee,
      },
    );

    ref.read(savedProvider.notifier).save(calc);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Calculation saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDirty = _calculated && (
      (double.tryParse(_purchasePriceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['PurchasePrice'] ?? 0.0) ||
      (double.tryParse(_renoCostController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['RenoCost'] ?? 0.0) ||
      (double.tryParse(_kRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['Rate'] ?? 0.0) ||
      (double.tryParse(_contPctController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot['ContPct'] ?? 0.0) ||
      _kType != (_calcSnapshot['KType'] ?? 'limited') ||
      _creditTier != (_calcSnapshot['CreditTier'] ?? '580+')
    );

    final cardBg = _theme.getCardColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);
    final borderCol = _theme.getBorderColor(context);
    final bgCol = _theme.getBgColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final snapPurchase = _calcSnapshot['PurchasePrice'] ?? 0.0;
    final snapReno = _calcSnapshot['RenoCost'] ?? 0.0;
    final snapKType = _calcSnapshot['KType'] ?? 'limited';

    final snapContAmt = _calcSnapshot['ContAmt'] ?? 0.0;
    final snapTotalProject = _calcSnapshot['TotalProject'] ?? 0.0;
    final snapDownPct = _calcSnapshot['DownPct'] ?? 0.0;
    final snapDownAmt = _calcSnapshot['DownAmt'] ?? 0.0;
    final snapBaseLoan = _calcSnapshot['BaseLoan'] ?? 0.0;
    final snapUfmip = _calcSnapshot['Ufmip'] ?? 0.0;
    final snapFinancedLoan = _calcSnapshot['FinancedLoan'] ?? 0.0;
    final snapAnnualMipRate = _calcSnapshot['AnnualMipRate'] ?? 0.0;
    final snapMonthlyMip = _calcSnapshot['MonthlyMip'] ?? 0.0;
    final snapMonthlyPI = _calcSnapshot['MonthlyPI'] ?? 0.0;
    final snapTotalMonthly = _calcSnapshot['TotalMonthly'] ?? 0.0;
    final snapOriginationFee = _calcSnapshot['OriginationFee'] ?? 0.0;
    final snapCapExceeded = _calcSnapshot['CapExceeded'] ?? false;

    // Percentages for Donut Painter
    final purchasePct = snapTotalProject > 0 ? snapPurchase / snapTotalProject : 0.0;
    final renoPct = snapTotalProject > 0 ? snapReno / snapTotalProject : 0.0;
    final contPctAlloc = snapTotalProject > 0 ? snapContAmt / snapTotalProject : 0.0;
    final downPctAlloc = snapTotalProject > 0 ? snapDownAmt / snapTotalProject : 0.0;

    return Scaffold(
      backgroundColor: bgCol,
      body: CustomScrollView(
        slivers: [
          // App Bar Header
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                ),
                alignment: Alignment.center,
                child: const Text('←', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0B1D3A), Color(0xFFB91C1C), Color(0xFF991B1B)],
                    stops: [0.0, 0.55, 1.0],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🔄', style: TextStyle(fontSize: 26)),
                      const SizedBox(height: 2),
                      Text('FHA 203(k) Loan',
                          style: AppTextStyles.dmSans(
                              size: 17,
                              color: Colors.white,
                              weight: FontWeight.w800)),
                      Text('Renovation + Purchase Financing Alternative',
                          style: AppTextStyles.dmSans(
                              size: 9.5, color: Colors.white60)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Rate Strip
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141C33) : Colors.white.withValues(alpha: 0.10),
                border: Border.all(color: borderCol),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStripItem('Min. Down', '3.5%', '580+ credit', isDark),
                  ),
                  Container(width: 1, height: 26, color: isDark ? Colors.white12 : Colors.black12),
                  Expanded(
                    child: _buildStripItem('Min. Credit', '500', 'FHA floor', isDark, isGold: true),
                  ),
                  Container(width: 1, height: 26, color: isDark ? Colors.white12 : Colors.black12),
                  Expanded(
                    child: _buildStripItem('Upfront MIP', '1.75%', 'financed in', isDark),
                  ),
                  Container(width: 1, height: 26, color: isDark ? Colors.white12 : Colors.black12),
                  Expanded(
                    child: _buildStripItem('Loan Cap', '\$1.25M', 'high-cost area', isDark),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader('Purchase & Renovation Details'),

                // Inputs Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField('Purchase Price (\$)', _purchasePriceController, hint: 'Property "as-is" price', errorText: _errors['purchase']),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInputField('Renovation Cost (\$)', _renoCostController, hint: 'Contractor repair estimate', errorText: _errors['reno']),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField<String>(
                              label: '203(k) Type',
                              value: _kType,
                              items: const [
                                DropdownMenuItem(value: 'limited', child: Text('Limited (≤\$75k)')),
                                DropdownMenuItem(value: 'standard', child: Text('Standard (Major)')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _kType = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildDropdownField<String>(
                              label: 'Credit Tier',
                              value: _creditTier,
                              items: const [
                                DropdownMenuItem(value: '580+', child: Text('580+ (3.5% down)')),
                                DropdownMenuItem(value: '500-579', child: Text('500–579 (10% down)')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _creditTier = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField('Mortgage Rate (%)', _kRateController, hint: 'FHA fixed rate', errorText: _errors['rate']),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInputField('Contingency (%)', _contPctController, hint: 'Typical: 10%–20%', errorText: _errors['contPct']),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: _calculate,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFB91C1C), Color(0xFF991B1B)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '🔄 Calculate 203(k) Payment',
                            style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                      // Hero Card Results
                if (!_calculated) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border.all(color: borderCol),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text('🏗️', style: TextStyle(fontSize: 28)),
                        const SizedBox(height: 8),
                        Text(
                          'View 203(k) Loan Alternative Results',
                          style: AppTextStyles.playfair(size: 13, color: textCol, weight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enter your project and loan details above, then tap "Calculate 203(k) Payment" to estimate your monthly structure.',
                          style: AppTextStyles.dmSans(size: 10.5, color: mutedCol),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 20),
                  Container(
                    key: _resultsKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isDirty) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              border: Border.all(color: Colors.amber),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Inputs have changed. Tap "Calculate 203(k) Payment" to update results.',
                                    style: TextStyle(fontSize: 11, color: textCol, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        _buildSectionHeader('Estimated Monthly Payment'),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0B1D3A), Color(0xFFB91C1C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Monthly Payment (P&I + MIP)'.toUpperCase(),
                                  style: AppTextStyles.dmSans(
                                      size: 8.5,
                                      color: Colors.white54,
                                      weight: FontWeight.w700,
                                      letterSpacing: 0.8)),
                              const SizedBox(height: 5),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(CurrencyFormatter.format(snapTotalMonthly, symbol: '\$').split('.').first,
                                      style: AppTextStyles.dmSans(
                                          size: 32, color: Colors.white, weight: FontWeight.w800)),
                                  const SizedBox(width: 4),
                                  Text('/mo', style: AppTextStyles.dmSans(size: 14, color: const Color(0xFFFCD34D), weight: FontWeight.w700)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Loan: ${CurrencyFormatter.format(snapFinancedLoan, symbol: '\$').split('.').first} · Down: ${CurrencyFormatter.format(snapDownAmt, symbol: '\$').split('.').first} · ${snapKType == 'limited' ? 'Limited' : 'Standard'} 203(k)',
                                style: AppTextStyles.dmSans(size: 10, color: Colors.white70),
                              ),
                              if (snapCapExceeded) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    border: Border.all(color: const Color(0xFFFCD34D)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '⚠️ Rehab budget exceeds the \$75,000 Limited 203(k) cap — switch to Standard 203(k).',
                                    style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFFCD34D), height: 1.35),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: _saveCalc,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    border: Border.all(color: Colors.white24),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '🔖 Save Calculation',
                                    style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Allocation Donut Chart
                        _buildSectionHeader('Project Cost Breakdown'),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            border: Border.all(color: borderCol),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('📊 Total Project Allocation',
                                  style: AppTextStyles.dmSans(size: 12, color: textCol, weight: FontWeight.w800)),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CustomPaint(
                                        size: const Size(100, 100),
                                        painter: _DonutChartPainter(
                                          purchasePct: purchasePct,
                                          renoPct: renoPct,
                                          contPct: contPctAlloc,
                                          downPct: downPctAlloc,
                                          isDark: isDark,
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Project', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: textCol)),
                                          Text('\$${(snapTotalProject / 1000).toStringAsFixed(0)}K', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: mutedCol)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        _buildLegendRow(const Color(0xFF0B1D3A), 'Purchase Price', '\$${(snapPurchase / 1000).toStringAsFixed(0)}K', textCol),
                                        const SizedBox(height: 6),
                                        _buildLegendRow(const Color(0xFFB91C1C), 'Renovation', '\$${(snapReno / 1000).toStringAsFixed(0)}K', textCol),
                                        const SizedBox(height: 6),
                                        _buildLegendRow(const Color(0xFFD97706), 'Contingency', '\$${(snapContAmt / 1000).toStringAsFixed(0)}K', textCol),
                                        const SizedBox(height: 6),
                                        _buildLegendRow(const Color(0xFFFCD34D), 'Down Payment', '\$${(snapDownAmt / 1000).toStringAsFixed(1)}K', textCol),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Key Figures grid
                        _buildSectionHeader('Key Figures'),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.25,
                          children: [
                            _buildMetricCard('💵', 'Down Payment', CurrencyFormatter.format(snapDownAmt), '${(snapDownPct * 100).toStringAsFixed(1)}% of total project', textCol, mutedCol, borderCol, cardBg),
                            _buildMetricCard('🏦', 'Base Loan Amount', CurrencyFormatter.format(snapBaseLoan), 'Before UFMIP added', textCol, mutedCol, borderCol, cardBg),
                            _buildMetricCard('🧾', 'Upfront MIP', CurrencyFormatter.format(snapUfmip), '1.75%, financed in', textCol, mutedCol, borderCol, cardBg),
                            _buildMetricCard('📅', 'Monthly MIP', CurrencyFormatter.format(snapMonthlyMip), '${(snapAnnualMipRate * 100).toStringAsFixed(2)}% annual rate', textCol, mutedCol, borderCol, cardBg),
                            _buildMetricCard('🏠', 'Monthly P&I', CurrencyFormatter.format(snapMonthlyPI), '30-yr fixed', textCol, mutedCol, borderCol, cardBg),
                            _buildMetricCard('📝', 'Est. Origination Fee', CurrencyFormatter.format(snapOriginationFee), 'Greater of \$350 or 1.5%', textCol, mutedCol, borderCol, cardBg),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Payment Composition bar chart
                        _buildSectionHeader('Payment Composition'),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            border: Border.all(color: borderCol),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('📈 Monthly Payment: P&I vs. MIP vs. Total',
                                  style: AppTextStyles.dmSans(size: 11.5, color: textCol, weight: FontWeight.w800)),
                              const SizedBox(height: 20),
                              _buildCompositionChart(snapMonthlyPI, snapMonthlyMip, snapTotalMonthly, textCol, mutedCol),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // FHA limits gauge card
                        _buildSectionHeader('Loan Amount vs. FHA Limits'),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: cardBg,
                            border: Border.all(color: borderCol),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('📏 Where Your Loan Falls (2026 1-Unit Limits)',
                                  style: AppTextStyles.dmSans(size: 12, color: textCol, weight: FontWeight.w800)),
                              const SizedBox(height: 14),
                              LayoutBuilder(builder: (context, constraints) {
                                final width = constraints.maxWidth;
                                const double maxScale = _fhaCeiling * 1.1;
                                final double fillPct = (snapFinancedLoan / maxScale).clamp(0.0, 1.0);
                                final double fillWidth = fillPct * width;

                                return Column(
                                  children: [
                                    Container(
                                      height: 14,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFEEF2F8),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        width: max(fillWidth, 8.0),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFB91C1C)]),
                                          borderRadius: BorderRadius.circular(7),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('\$0', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                                        Text('Floor \$${(_fhaFloor / 1000).toStringAsFixed(0)}K', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                                        Text('Ceiling \$${(_fhaCeiling / 1000000).toStringAsFixed(2)}M', style: AppTextStyles.dmSans(size: 8.5, color: mutedCol)),
                                      ],
                                    ),
                                  ],
                                );
                              }),
                              const SizedBox(height: 10),
                              Text(
                                snapFinancedLoan > _fhaCeiling
                                    ? '⚠️ Your financed loan amount (${CurrencyFormatter.format(snapFinancedLoan, symbol: '\$').split('.').first}) exceeds the 2026 FHA national ceiling of ${CurrencyFormatter.format(_fhaCeiling, symbol: '\$').split('.').first} — you may need a jumbo or conventional renovation loan instead.'
                                    : (snapFinancedLoan < _fhaFloor
                                        ? 'Your financed loan amount (${CurrencyFormatter.format(snapFinancedLoan, symbol: '\$').split('.').first}) is below the FHA floor — you\'re well within limits nationwide.'
                                        : 'Your financed loan amount (${CurrencyFormatter.format(snapFinancedLoan, symbol: '\$').split('.').first}) fits within the 2026 FHA limits for most counties. High-cost areas allow up to ${CurrencyFormatter.format(_fhaCeiling, symbol: '\$').split('.').first}.'),
                                style: AppTextStyles.dmSans(size: 9.5, color: textCol, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Limited vs Standard side by side compare
                _buildSectionHeader('Limited vs. Standard 203(k)'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildCompareCard(
                        title: 'Limited 203(k)',
                        badge: 'Faster & Simpler',
                        isFeatured: true,
                        details: const {
                          'Max repair budget': '\$75,000',
                          'Structural work': 'Not allowed',
                          'HUD consultant': 'Not required',
                          'Completion window': 'Up to 6 months',
                          'Best for': 'Kitchens, baths, cosmetic',
                        },
                        cardBg: cardBg,
                        textCol: textCol,
                        mutedCol: mutedCol,
                        borderCol: borderCol,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompareCard(
                        title: 'Standard 203(k)',
                        badge: 'Major Rehab',
                        isFeatured: false,
                        details: const {
                          'Max repair budget': 'Up to FHA limit',
                          'Structural work': 'Allowed',
                          'HUD consultant': 'Required (~\$400–\$1K)',
                          'Completion window': 'Up to 12 months',
                          'Best for': 'Additions, structural fixes',
                        },
                        cardBg: cardBg,
                        textCol: textCol,
                        mutedCol: mutedCol,
                        borderCol: borderCol,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Timeline Card
                _buildSectionHeader('203(k) Process Timeline'),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3B1E1E) : const Color(0xFFFEF2F2),
                    border: Border.all(color: isDark ? const Color(0xFF991B1B).withValues(alpha: 0.4) : const Color(0xFFFCA5A5)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🗓️ From Pre-Approval to Move-In',
                          style: AppTextStyles.dmSans(
                              size: 12.5,
                              color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF7F1D1D),
                              weight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      _buildTimelineRow('Pre-Approval', '1–3 days', isDark),
                      _buildTimelineRow('Contractor Bids', '1–2 weeks', isDark),
                      _buildTimelineRow('Underwriting', '3–4 weeks', isDark),
                      _buildTimelineRow('Closing', '45–60 days from contract', isDark),
                      _buildTimelineRow('Renovation Period', _kType == 'limited' ? 'Up to 6 months' : 'Up to 12 months', isDark),
                      _buildTimelineRow('Work Must Start By', '30 days post-closing', isDark),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Is there a better fit?
                _buildSectionHeader('Is There a Better Fit?'),
                Column(
                  children: [
                    _buildDecisionRow('🏠', 'Conventional HomeStyle Renovation', 'If you have 620+ credit and 10%+ down, this avoids FHA\'s lifetime mortgage insurance.', cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 9),
                    _buildDecisionRow('🎖️', 'VA Renovation Loan', 'Eligible veterans and service members may qualify for 0% down renovation financing.', cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 9),
                    _buildDecisionRow('🏗️', 'Standard Construction Loan', 'For ground-up new builds rather than renovating an existing structure, see the main calculator.', cardBg, textCol, mutedCol, borderCol),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStripItem(String label, String value, String sub, bool isDark, {bool isGold = false}) {
    return Column(
      children: [
        Text(label.toUpperCase(),
            style: AppTextStyles.dmSans(
                size: 8,
                weight: FontWeight.w700,
                color: isDark ? Colors.white54 : _theme.getMutedColor(context),
                letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyles.dmSans(
                size: 12.5,
                weight: FontWeight.w800,
                color: isGold ? const Color(0xFFFCD34D) : (isDark ? Colors.white : _theme.getTextColor(context)))),
        const SizedBox(height: 1),
        Text(sub,
            style: AppTextStyles.dmSans(
                size: 7.5, color: isDark ? Colors.white30 : _theme.getMutedColor(context).withValues(alpha: 0.6))),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 12),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.dmSans(
          size: 10,
          weight: FontWeight.w800,
          color: _theme.getMutedColor(context),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {String? hint, String? errorText}) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasError ? '${label.toUpperCase()} - $errorText' : label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8.5,
            weight: FontWeight.w700,
            color: hasError ? Colors.red : _theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: _theme.getBgColor(context),
            border: Border.all(
              color: hasError ? Colors.red : _theme.getBorderColor(context),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => setState(() {}),
            style: AppTextStyles.dmSans(
              size: 13,
              weight: FontWeight.w700,
              color: _theme.getTextColor(context),
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 3),
          Text(hint, style: AppTextStyles.dmSans(size: 8, color: _theme.getMutedColor(context))),
        ],
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8.5,
            weight: FontWeight.w700,
            color: _theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _theme.getBgColor(context),
            border: Border.all(color: _theme.getBorderColor(context), width: 1.5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              style: AppTextStyles.dmSans(
                size: 13,
                weight: FontWeight.w700,
                color: _theme.getTextColor(context),
              ),
              dropdownColor: _theme.getCardColor(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendRow(Color color, String label, String value, Color textCol) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: AppTextStyles.dmSans(size: 9.5, color: textCol, weight: FontWeight.w500)),
        ),
        Text(value, style: AppTextStyles.dmSans(size: 10, color: textCol, weight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMetricCard(String emoji, String label, String value, String sub, Color textCol, Color mutedCol, Color borderCol, Color cardBg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w700, color: mutedCol, letterSpacing: 0.3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value.split('.').first,
            style: AppTextStyles.dmSans(size: 15, weight: FontWeight.w800, color: textCol),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: AppTextStyles.dmSans(size: 8, color: mutedCol),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCompositionChart(double pi, double mip, double total, Color textCol, Color mutedCol) {
    final maxVal = total;
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth - 90;
      final piWidth = maxVal > 0 ? (pi / maxVal) * width : 0.0;
      final mipWidth = maxVal > 0 ? (mip / maxVal) * width : 0.0;
      final totalWidth = width;

      return Column(
        children: [
          _buildChartRow('P&I', pi, piWidth, const Color(0xFF0B1D3A), textCol),
          const SizedBox(height: 10),
          _buildChartRow('MIP', mip, mipWidth, const Color(0xFFD97706), textCol),
          const SizedBox(height: 10),
          _buildChartRow('Total', total, totalWidth, const Color(0xFFB91C1C), textCol),
        ],
      );
    });
  }

  Widget _buildChartRow(String label, double value, double width, Color color, Color textCol) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: textCol)),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              height: 18,
              width: max(width, 10.0),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                CurrencyFormatter.format(value, symbol: '\$').split('.').first,
                style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompareCard({
    required String title,
    required String badge,
    required bool isFeatured,
    required Map<String, String> details,
    required Color cardBg,
    required Color textCol,
    required Color mutedCol,
    required Color borderCol,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFeatured ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E2638) : const Color(0xFFFFFBEB)) : cardBg,
        border: Border.all(color: isFeatured ? const Color(0xFFD97706) : borderCol, width: isFeatured ? 1.5 : 1.0),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: textCol)),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: isFeatured ? const Color(0xFFD97706) : mutedCol.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(badge, style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w800, color: isFeatured ? Colors.white : textCol)),
          ),
          const SizedBox(height: 12),
          ...details.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.key.toUpperCase(), style: AppTextStyles.dmSans(size: 7.5, color: mutedCol, letterSpacing: 0.3)),
                    const SizedBox(height: 1),
                    Text(e.value, style: AppTextStyles.dmSans(size: 10, color: textCol, weight: FontWeight.bold)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(String key, String val, bool isDark) {
    final kColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B);
    final vColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C);
    final bColor = isDark ? const Color(0xFF991B1B).withValues(alpha: 0.3) : const Color(0xFFFEE2E2);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: bColor, width: 0.8))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w600, color: kColor)),
          Text(val, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: vColor)),
        ],
      ),
    );
  }

  Widget _buildDecisionRow(String emoji, String title, String subtitle, Color cardBg, Color textCol, Color mutedCol, Color borderCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _theme.getBgColor(context),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textCol)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.dmSans(size: 9.5, color: mutedCol, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final double purchasePct;
  final double renoPct;
  final double contPct;
  final double downPct;
  final bool isDark;

  _DonutChartPainter({
    required this.purchasePct,
    required this.renoPct,
    required this.contPct,
    required this.downPct,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const strokeWidth = 12.0;

    final bgPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEEF2F8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    const startAngle = -pi / 2;
    double currentStart = startAngle;

    void drawArcSegment(double pct, Color color) {
      if (pct <= 0) return;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = pct * 2 * pi;
      canvas.drawArc(rect, currentStart, sweepAngle, false, paint);
      currentStart += sweepAngle;
    }

    drawArcSegment(purchasePct, const Color(0xFF0B1D3A));
    drawArcSegment(renoPct, const Color(0xFFB91C1C));
    drawArcSegment(contPct, const Color(0xFFD97706));
    drawArcSegment(downPct, const Color(0xFFFCD34D));
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.purchasePct != purchasePct ||
        oldDelegate.renoPct != renoPct ||
        oldDelegate.contPct != contPct ||
        oldDelegate.downPct != downPct ||
        oldDelegate.isDark != isDark;
  }
}
