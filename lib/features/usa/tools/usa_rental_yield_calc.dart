// lib/features/usa/tools/usa_rental_yield_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../shared/widgets/live_rate_banner.dart';
import '../../../providers/usa_rates_provider.dart';

class USARentalYieldCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const USARentalYieldCalc({super.key, this.theme = CountryThemes.usa});

  @override
  ConsumerState<USARentalYieldCalc> createState() => _USARentalYieldCalcState();
}

class _USARentalYieldCalcState extends ConsumerState<USARentalYieldCalc> {
  final _priceController = TextEditingController(text: '380000');
  final _rentController = TextEditingController(text: '2600');
  final _downController = TextEditingController(text: '25');
  final _mRateController = TextEditingController(text: '7.25');
  final _taxController = TextEditingController(text: '4500');
  final _insController = TextEditingController(text: '1800');
  final _mgmtController = TextEditingController(text: '8');
  final _vacancyController = TextEditingController(text: '7');
  final _maintController = TextEditingController(text: '3000');
  final _otherController = TextEditingController(text: '500');

  bool _showResults = false;
  bool _isCalcDirty = true;
  bool _calculating = false;

  @override
  void initState() {
    super.initState();
    final controllers = [
      _priceController,
      _rentController,
      _downController,
      _mRateController,
      _taxController,
      _insController,
      _mgmtController,
      _vacancyController,
      _maintController,
      _otherController
    ];
    for (final c in controllers) {
      c.addListener(_markDirty);
    }
    // Auto-calculate on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculate();
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _rentController.dispose();
    _downController.dispose();
    _mRateController.dispose();
    _taxController.dispose();
    _insController.dispose();
    _mgmtController.dispose();
    _vacancyController.dispose();
    _maintController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isCalcDirty) {
      setState(() {
        _isCalcDirty = true;
      });
    }
  }

  double _val(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

  Map<String, dynamic> _computeReturns() {
    final price = _val(_priceController);
    final monthlyRent = _val(_rentController);
    final downPct = _val(_downController) / 100;
    final mRate = _val(_mRateController) / 100;
    final propTax = _val(_taxController);
    final insurance = _val(_insController);
    final mgmtPct = _val(_mgmtController) / 100;
    final vacancyPct = _val(_vacancyController) / 100;
    final maintenance = _val(_maintController);
    final other = _val(_otherController);

    final down = price * downPct;
    final loan = price - down;
    final mRateM = mRate / 12;
    const n = 30 * 12; // 30 year standard mortgage term
    final double pi = (loan > 0 && mRateM > 0)
        ? (loan * mRateM * pow(1 + mRateM, n)) / (pow(1 + mRateM, n) - 1)
        : (loan > 0 ? loan / n : 0.0);
    final annualDebt = pi * 12;

    final grossIncome = monthlyRent * 12;
    final vacancyLoss = grossIncome * vacancyPct;
    final egi = grossIncome - vacancyLoss;
    final mgmtFee = egi * mgmtPct;
    final totalOpEx = propTax + insurance + mgmtFee + maintenance + other;
    final noi = egi - totalOpEx;
    final annualCF = noi - annualDebt;
    final monthlyCF = annualCF / 12;

    final capRate = price > 0 ? (noi / price * 100) : 0.0;
    final grossYield = price > 0 ? (grossIncome / price * 100) : 0.0;
    final grm = grossIncome > 0 ? (price / grossIncome) : 0.0;
    final coc = down > 0 ? (annualCF / down * 100) : 0.0;
    final ruleCheck = price > 0 ? (monthlyRent / price * 100) : 0.0;
    final dscr = annualDebt > 0 ? (noi / annualDebt) : 0.0;

    return {
      'price': price,
      'monthlyRent': monthlyRent,
      'downPct': downPct,
      'mRate': mRate,
      'propTax': propTax,
      'insurance': insurance,
      'mgmtPct': mgmtPct,
      'vacancyPct': vacancyPct,
      'maintenance': maintenance,
      'other': other,
      'down': down,
      'loan': loan,
      'pi': pi,
      'annualDebt': annualDebt,
      'grossIncome': grossIncome,
      'vacancyLoss': vacancyLoss,
      'egi': egi,
      'mgmtFee': mgmtFee,
      'totalOpEx': totalOpEx,
      'noi': noi,
      'annualCF': annualCF,
      'monthlyCF': monthlyCF,
      'capRate': capRate,
      'grossYield': grossYield,
      'grm': grm,
      'coc': coc,
      'ruleCheck': ruleCheck,
      'dscr': dscr,
    };
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
    final price = _val(_priceController);
    if (price <= 0) return;

    final data = _computeReturns();
    final capRate = data['capRate'] as double;
    final noi = data['noi'] as double;

    final label = 'Rental Yield (${capRate.toStringAsFixed(1)}% Cap · ${CurrencyFormatter.compact(price, symbol: r'$')})';
    final labelCtrl = TextEditingController(text: label);

    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_rental_yield_calc'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Rental Analysis',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: Cap Rate: ${capRate.toStringAsFixed(1)}% · NOI: ${CurrencyFormatter.compact(noi, symbol: r'$')}',
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
                hintText: 'Label',
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
      final savedLabel =
          labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : label;
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'Rental Yield Calc',
        inputs: {
          'Price': price,
          'Rent': data['monthlyRent'] as double,
          'DownPct': (data['downPct'] as double) * 100,
          'Rate': (data['mRate'] as double) * 100,
          'Tax': data['propTax'] as double,
          'Insurance': data['insurance'] as double,
          'Mgmt': (data['mgmtPct'] as double) * 100,
          'Vacancy': (data['vacancyPct'] as double) * 100,
          'Maint': data['maintenance'] as double,
          'Other': data['other'] as double,
        },
        results: {
          'Cap Rate': capRate,
          'Gross Yield': data['grossYield'] as double,
          'NOI': noi,
          'Cash Flow': data['monthlyCF'] as double,
          'GRM': data['grm'] as double,
        },
        label: savedLabel,
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

    final data = _computeReturns();
    final annualDebt = data['annualDebt'] as double;
    final grossIncome = data['grossIncome'] as double;
    final vacancyLoss = data['vacancyLoss'] as double;
    final egi = data['egi'] as double;
    final mgmtFee = data['mgmtFee'] as double;
    final totalOpEx = data['totalOpEx'] as double;
    final noi = data['noi'] as double;
    final annualCF = data['annualCF'] as double;
    final monthlyCF = data['monthlyCF'] as double;
    final capRate = data['capRate'] as double;
    final grossYield = data['grossYield'] as double;
    final grm = data['grm'] as double;
    final coc = data['coc'] as double;
    final ruleCheck = data['ruleCheck'] as double;
    final dscr = data['dscr'] as double;

    final propTax = data['propTax'] as double;
    final insurance = data['insurance'] as double;
    final maintenance = data['maintenance'] as double;
    final other = data['other'] as double;

    final markerPct = (capRate / 10.0 * 100.0).clamp(5.0, 95.0);

    final String verdictText = capRate >= 7.0
        ? '🌟 Great · Strong investor return'
        : capRate >= 5.0
            ? '✓ Good · Above US average of 5.1%'
            : capRate >= 3.0
                ? '⚠️ Fair · Below average — negotiate price'
                : '✗ Poor · Reconsider or renegotiate';

    final String badgeText = capRate >= 7.0
        ? '🌟 Great Cap Rate'
        : capRate >= 5.0
            ? '✓ Good Cap Rate'
            : capRate >= 3.0
                ? '⚠️ Fair Cap Rate'
                : '✗ Poor Cap Rate';

    final Color badgeColor = capRate >= 7.0
        ? const Color(0xFFCCFBF1)
        : capRate >= 5.0
            ? const Color(0xFFD1FAE5)
            : capRate >= 3.0
                ? const Color(0xFFFEF3C7)
                : const Color(0xFFFEE2E2);

    final Color badgeTextColor = capRate >= 7.0
        ? const Color(0xFF0F766E)
        : capRate >= 5.0
            ? const Color(0xFF15803D)
            : capRate >= 3.0
                ? const Color(0xFF92400E)
                : const Color(0xFFB91C1C);

    final totalExpSum = totalOpEx + annualDebt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Header — Live VNQ ETF + FRED
        LightRateStripBanner(items: [
          RateStripItem(label: 'VNQ ETF\n(Real Est.)', provider: vnqPriceProvider, fallback: 92.50, suffix: '', isDollar: true),
          RateStripItem(label: 'Investor 30yr', provider: fredMortgage30Provider, fallback: 7.25),
          RateStripItem(label: 'Median Home', provider: censusMedianHomeValueProvider, fallback: 412000, isDollar: true, suffix: ''),
          RateStripItem(label: 'Fed Funds', provider: fredFedFundsProvider, fallback: 5.33, isGold: true),
        ]),
        const SizedBox(height: 16),

        Text('PROPERTY DETAILS',
            style: AppTextStyles.dmSans(
                size: 11,
                color: theme.getMutedColor(context),
                weight: FontWeight.bold)),
        const SizedBox(height: 8),

        // Inputs Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildTextField('Purchase Price (\$)', _priceController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Monthly Rent (\$)', _rentController)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Down Payment (%)', _downController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Mortgage Rate (%)', _mRateController)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Property Tax/yr (\$)', _taxController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Insurance/yr (\$)', _insController)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Mgmt Fee (%/rent)', _mgmtController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Vacancy Rate (%)', _vacancyController)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Maintenance/yr (\$)', _maintController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Other Expenses/yr (\$)', _otherController)),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF15803D), Color(0xFF166534)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _calculate,
                        child: _calculating
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text('🏘️ Calculate Returns',
                                style: AppTextStyles.dmSans(
                                    size: 13,
                                    color: Colors.white,
                                    weight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _showResults ? _saveCalculation : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: _showResults
                            ? const Color(0xFF1B3F72)
                            : theme.getBgColor(context),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: theme.getBorderColor(context)),
                      ),
                      alignment: Alignment.center,
                      child: Text('💾 Save',
                          style: AppTextStyles.dmSans(
                              size: 13,
                              color: _showResults
                                  ? Colors.white
                                  : theme.getMutedColor(context),
                              weight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_showResults) ...[
          // Result Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF15803D), Color(0xFF166534)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CAP RATE (NET)',
                    style: AppTextStyles.dmSans(
                        size: 10, color: Colors.white60, weight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('${capRate.toStringAsFixed(1)}%',
                    style: AppTextStyles.playfair(
                        size: 42,
                        color: const Color(0xFFFCD34D),
                        weight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(verdictText,
                    style:
                        AppTextStyles.dmSans(size: 11, color: Colors.white70)),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildHeroResult('Gross Yield', '${grossYield.toStringAsFixed(1)}%'),
                    _buildHeroResult('NOI (Annual)', CurrencyFormatter.compact(noi, symbol: r'$')),
                    _buildHeroResult('Monthly Cash Flow', '${CurrencyFormatter.compact(monthlyCF, symbol: r'$')}/mo'),
                    _buildHeroResult('GRM', grm.toStringAsFixed(1)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Rating Bar
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cap Rate vs Market Benchmark',
                    style: AppTextStyles.playfair(
                        size: 12,
                        color: theme.getTextColor(context),
                        weight: FontWeight.bold)),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double width = constraints.maxWidth;
                    final double leftOffset =
                        (markerPct / 100.0 * width).clamp(10.0, width - 10.0);
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFB91C1C), // Poor
                                Color(0xFFD97706), // Fair
                                Color(0xFF15803D), // Good
                                Color(0xFF0F766E), // Great
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: leftOffset - 10,
                          top: -4,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: theme.getTextColor(context), width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
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
                    Text('Poor <3%',
                        style: AppTextStyles.dmSans(
                            size: 9, color: theme.getMutedColor(context))),
                    Text('Fair 3-5%',
                        style: AppTextStyles.dmSans(
                            size: 9, color: theme.getMutedColor(context))),
                    Text('Good 5-7%',
                        style: AppTextStyles.dmSans(
                            size: 9, color: theme.getMutedColor(context))),
                    Text('Great 7%+',
                        style: AppTextStyles.dmSans(
                            size: 9, color: theme.getMutedColor(context))),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(badgeText,
                        style: AppTextStyles.dmSans(
                            size: 11,
                            color: badgeTextColor,
                            weight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // KPI Strip
          Row(
            children: [
              Expanded(
                child: _buildKpiCard('💵', '${coc.toStringAsFixed(1)}%', 'Cash-on-Cash',
                    coc >= 8 ? Colors.green : (coc >= 4 ? Colors.black : Colors.red)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKpiCard('📐', '${ruleCheck.toStringAsFixed(1)}%', '1% Rule',
                    ruleCheck >= 1 ? Colors.green : Colors.red),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKpiCard('📊', '${dscr.toStringAsFixed(2)}x', 'DSCR Ratio',
                    dscr >= 1.25 ? Colors.green : (dscr >= 1.0 ? Colors.black : Colors.red)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Donut Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🥧 Expense Breakdown',
                    style: AppTextStyles.playfair(
                        size: 12.5,
                        color: theme.getTextColor(context),
                        weight: FontWeight.bold)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    SizedBox(
                      height: 100,
                      width: 100,
                      child: CustomPaint(
                        painter: _RentalYieldDonutPainter(
                          debt: annualDebt,
                          tax: propTax,
                          ins: insurance,
                          mgmt: mgmtFee,
                          maint: maintenance,
                          other: other + vacancyLoss,
                          total: totalExpSum,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _buildDonutRow(const Color(0xFFB91C1C), 'Debt Service', annualDebt),
                          const SizedBox(height: 4),
                          _buildDonutRow(const Color(0xFFD97706), 'Property Tax', propTax),
                          const SizedBox(height: 4),
                          _buildDonutRow(const Color(0xFF1B3F72), 'Insurance', insurance),
                          const SizedBox(height: 4),
                          _buildDonutRow(const Color(0xFF15803D), 'Management', mgmtFee),
                          const SizedBox(height: 4),
                          _buildDonutRow(const Color(0xFF0F766E), 'Maintenance', maintenance),
                          const SizedBox(height: 4),
                          _buildDonutRow(const Color(0xFF9333EA), 'Other/Vacancy', other + vacancyLoss),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bar Chart Comparison Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📊 Income vs Expense Comparison',
                    style: AppTextStyles.playfair(
                        size: 12.5,
                        color: theme.getTextColor(context),
                        weight: FontWeight.bold)),
                const SizedBox(height: 14),
                _buildBarRow('Gross Income', grossIncome, grossIncome, const Color(0xFF15803D)),
                const SizedBox(height: 9),
                _buildBarRow('Total Expenses', totalOpEx, grossIncome, const Color(0xFFB91C1C)),
                const SizedBox(height: 9),
                _buildBarRow('Debt Service', annualDebt, grossIncome, const Color(0xFFD97706)),
                const SizedBox(height: 9),
                _buildBarRow('Net Cash Flow', annualCF.abs(), grossIncome,
                    annualCF >= 0 ? const Color(0xFF0F766E) : const Color(0xFFB91C1C),
                    customLabel: annualCF < 0 ? 'Net Loss' : null,
                    customValue: CurrencyFormatter.format(annualCF, symbol: r'$')),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Cash Flow Statement
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('📋 Annual Cash Flow Statement',
                        style: AppTextStyles.playfair(
                            size: 12.5,
                            color: theme.getTextColor(context),
                            weight: FontWeight.bold)),
                    GestureDetector(
                      onTap: _saveCalculation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: theme.getBgColor(context),
                          border: Border.all(
                              color: theme.getBorderColor(context), width: 1.5),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          children: [
                            Text('🔖', style: TextStyle(fontSize: 10, color: theme.primaryColor)),
                            const SizedBox(width: 4),
                            Text('Save Statement',
                                style: AppTextStyles.dmSans(
                                    size: 10,
                                    weight: FontWeight.w700,
                                    color: theme.primaryColor)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStatementRow('Gross Rental Income', grossIncome, isPos: true),
                _buildStatementRow('(-) Vacancy Loss', vacancyLoss, isPos: false),
                _buildStatementRow('Effective Gross Income', egi, isPos: true, isBoldLabel: true),
                _buildStatementRow('(-) Property Tax', propTax, isPos: false),
                _buildStatementRow('(-) Insurance', insurance, isPos: false),
                _buildStatementRow('(-) Mgmt Fee', mgmtFee, isPos: false),
                _buildStatementRow('(-) Maintenance', maintenance, isPos: false),
                _buildStatementRow('(-) Other Expenses', other, isPos: false),
                _buildStatementRow('NOI (Net Operating Income)', noi, isPos: true, isHeader: true),
                _buildStatementRow('(-) Annual Debt Service', annualDebt, isPos: false),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF15803D), Color(0xFF166534)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Annual Cash Flow',
                          style: AppTextStyles.dmSans(
                              size: 11,
                              color: Colors.white.withValues(alpha: 0.7),
                              weight: FontWeight.bold)),
                      Text(CurrencyFormatter.format(annualCF, symbol: r'$'),
                          style: AppTextStyles.playfair(
                              size: 16,
                              color: annualCF >= 0
                                  ? const Color(0xFFFCD34D)
                                  : const Color(0xFFFCA5A5),
                              weight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Markets Section
        Text('TOP RENTAL MARKETS 2024',
            style: AppTextStyles.dmSans(
                size: 11,
                color: theme.getMutedColor(context),
                weight: FontWeight.bold)),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.4,
          children: [
            _buildMarketCard('🌇', 'Austin, TX', 'Cap 5.8% · Rent \$2,140',
                bgColor: const Color(0xFF15803D), isDarkText: false),
            _buildMarketCard('🌴', 'Tampa, FL', 'Cap 6.1% · Rent \$2,020'),
            _buildMarketCard('☀️', 'Phoenix, AZ', 'Cap 5.9% · Rent \$1,980'),
            _buildMarketCard('🏔️', 'Charlotte, NC', 'Cap 6.3% · Rent \$1,850',
                bgColor: const Color(0xFF0F766E), isDarkText: false),
            _buildMarketCard('🎭', 'Nashville, TN', 'Cap 5.5% · Rent \$2,200',
                bgColor: const Color(0xFF0B1D3A), isDarkText: false),
            _buildMarketCard('🌻', 'Indianapolis, IN', 'Cap 7.1% · Rent \$1,450',
                bgColor: const Color(0xFFD97706), isDarkText: false),
          ],
        ),
        const SizedBox(height: 16),

        // Tips Section
        Text('INVESTOR TIPS',
            style: AppTextStyles.dmSans(
                size: 11,
                color: theme.getMutedColor(context),
                weight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildGuideCard('📏', '1% Rule Quick Check',
            'Monthly rent ≥ 1% of purchase price signals good deal'),
        _buildGuideCard('🏦', 'DSCR Loans for Investors',
            'Qualify on rent income, not W-2 · Min 1.25x DSCR ratio'),
        _buildGuideCard('📉', 'Depreciation Tax Shield',
            'Deduct 1/27.5 of building value per year · IRS Schedule E'),
        _buildGuideCard('🔍', 'Due Diligence Checklist',
            'Inspection · title · rent rolls · leases · utility bills'),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            border: Border.all(color: theme.getBorderColor(context), width: 1.5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            style: AppTextStyles.dmSans(size: 13, color: theme.getTextColor(context), weight: FontWeight.bold),
            decoration: const InputDecoration(border: InputBorder.none, isDense: true),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroResult(String label, String value) {
    final theme = widget.theme;
    return Column(
      children: [
        Text(value, style: AppTextStyles.playfair(size: 16, color: theme.getTextColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildKpiCard(String emoji, String value, String label, [Color? valueColor]) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.playfair(size: 15, color: valueColor ?? theme.getTextColor(context), weight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildDonutRow(Color color, String label, double value) {
    final theme = widget.theme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 6),
            Text(label, style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context), weight: FontWeight.w600)),
          ],
        ),
        Text(CurrencyFormatter.format(value, symbol: r'$'), style: AppTextStyles.playfair(size: 9.5, color: theme.getTextColor(context), weight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBarRow(String label, double amt, double maxVal, Color fillCol,
      {String? customLabel, String? customValue}) {
    final theme = widget.theme;
    final double pct = maxVal > 0 ? (amt / maxVal).clamp(0.01, 1.0) : 0.01;
    final displayLabel = customLabel ?? label;
    final displayValue =
        customValue ?? CurrencyFormatter.compact(amt, symbol: r'$');

    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(displayLabel,
              style: AppTextStyles.dmSans(
                  size: 10,
                  color: theme.getMutedColor(context),
                  weight: FontWeight.w600),
              textAlign: TextAlign.right),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              color: theme.getBgColor(context),
              borderRadius: BorderRadius.circular(5),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: pct,
              child: Container(
                decoration: BoxDecoration(
                  color: fillCol,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 54,
          child: Text(displayValue,
              style: AppTextStyles.playfair(
                  size: 10,
                  color: theme.getTextColor(context),
                  weight: FontWeight.bold),
              textAlign: TextAlign.right),
        ),
      ],
    );
  }

  Widget _buildStatementRow(String name, double val,
      {required bool isPos,
      bool isBoldLabel = false,
      bool isHeader = false}) {
    final theme = widget.theme;
    final String sign = isPos ? '' : '-';
    final Color valColor = isPos ? const Color(0xFF15803D) : const Color(0xFFB91C1C);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.getBorderColor(context))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name,
              style: AppTextStyles.dmSans(
                  size: isHeader ? 12 : 11,
                  color: isHeader ? theme.getTextColor(context) : theme.getMutedColor(context),
                  weight: (isBoldLabel || isHeader) ? FontWeight.bold : FontWeight.normal)),
          Text(
            '$sign${CurrencyFormatter.format(val, symbol: r'$')}',
            style: AppTextStyles.playfair(
                size: isHeader ? 14 : 11.5,
                color: isHeader ? theme.getTextColor(context) : valColor,
                weight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketCard(String emoji, String name, String details,
      {Color? bgColor, bool isDarkText = true}) {
    final theme = widget.theme;
    final cardBg = bgColor ?? theme.getCardColor(context);
    final txtColor = isDarkText ? theme.getTextColor(context) : Colors.white;
    final subTxtColor =
        isDarkText ? theme.getMutedColor(context) : Colors.white60;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: bgColor != null ? Colors.transparent : theme.getBorderColor(context)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: bgColor != null
                  ? Colors.white.withValues(alpha: 0.15)
                  : theme.getBgColor(context),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(height: 8),
          Text(name,
              style: AppTextStyles.playfair(
                  size: 12.5, color: txtColor, weight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(details, style: AppTextStyles.dmSans(size: 9.5, color: subTxtColor)),
        ],
      ),
    );
  }

  Widget _buildGuideCard(String emoji, String title, String desc) {
    final theme = widget.theme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: theme.getBgColor(context),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.playfair(
                        size: 12.5,
                        color: theme.getTextColor(context),
                        weight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(desc,
                    style: AppTextStyles.dmSans(
                        size: 9.5, color: theme.getMutedColor(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RentalYieldDonutPainter extends CustomPainter {
  final double debt;
  final double tax;
  final double ins;
  final double mgmt;
  final double maint;
  final double other;
  final double total;
  final bool isDark;

  _RentalYieldDonutPainter({
    required this.debt,
    required this.tax,
    required this.ins,
    required this.mgmt,
    required this.maint,
    required this.other,
    required this.total,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = min(size.width, size.height) / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw background circle
    final bgPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFEFF6FF)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

    if (total <= 0) return;

    final double debtAngle = (debt / total) * 2 * pi;
    final double taxAngle = (tax / total) * 2 * pi;
    final double insAngle = (ins / total) * 2 * pi;
    final double mgmtAngle = (mgmt / total) * 2 * pi;
    final double maintAngle = (maint / total) * 2 * pi;
    final double otherAngle = (other / total) * 2 * pi;

    double startAngle = -pi / 2;
    void drawArcSegment(double angle, Color color) {
      if (angle <= 0) return;
      final p = Paint()
        ..color = color
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, angle, false, p);
      startAngle += angle;
    }

    drawArcSegment(debtAngle, const Color(0xFFB91C1C));
    drawArcSegment(taxAngle, const Color(0xFFD97706));
    drawArcSegment(insAngle, const Color(0xFF1B3F72));
    drawArcSegment(mgmtAngle, const Color(0xFF15803D));
    drawArcSegment(maintAngle, const Color(0xFF0F766E));
    drawArcSegment(otherAngle, const Color(0xFF9333EA));

    // Center text
    final textPainter = TextPainter(
      text: TextSpan(
        text: CurrencyFormatter.compact(total, symbol: r'$'),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFF0B1D3A),
          fontFamily: 'Georgia',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset(center.dx - textPainter.width / 2, center.dy - 10));

    final subPainter = TextPainter(
      text: const TextSpan(
        text: 'Expenses',
        style: TextStyle(
          fontSize: 7.5,
          color: Colors.grey,
          fontFamily: 'DMSans',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    subPainter.layout();
    subPainter.paint(
        canvas, Offset(center.dx - subPainter.width / 2, center.dy + 3));
  }

  @override
  bool shouldRepaint(covariant _RentalYieldDonutPainter oldDelegate) {
    return oldDelegate.debt != debt ||
        oldDelegate.tax != tax ||
        oldDelegate.ins != ins ||
        oldDelegate.mgmt != mgmt ||
        oldDelegate.maint != maint ||
        oldDelegate.other != other ||
        oldDelegate.total != total ||
        oldDelegate.isDark != isDark;
  }
}


