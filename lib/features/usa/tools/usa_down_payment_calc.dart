// lib/features/usa/tools/usa_down_payment_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/mortgage_math.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USADownPaymentCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const USADownPaymentCalc({super.key, this.theme = CountryThemes.usa});

  @override
  ConsumerState<USADownPaymentCalc> createState() => _USADownPaymentCalcState();
}

class _USADownPaymentCalcState extends ConsumerState<USADownPaymentCalc> {
  // Input Controllers
  final _homePriceController = TextEditingController(text: '450000');
  final _rateController = TextEditingController(text: '6.82');
  final _savingsController = TextEditingController(text: '1500');
  final _curSavingsController = TextEditingController(text: '40000');

  double _downPct = 20.0;

  @override
  void dispose() {
    _homePriceController.dispose();
    _rateController.dispose();
    _savingsController.dispose();
    _curSavingsController.dispose();
    super.dispose();
  }

  double _val(TextEditingController c) => double.tryParse(c.text) ?? 0.0;

  double _pmiPerMonth(double loan, double pct) {
    if (pct >= 20.0) return 0.0;
    final rate = pct < 5.0 ? 0.85 : (pct < 10.0 ? 0.65 : 0.50);
    return loan * rate / 100 / 12;
  }

  void _resetInputs() {
    setState(() {
      _homePriceController.text = '450000';
      _rateController.text = '6.82';
      _savingsController.text = '1500';
      _curSavingsController.text = '40000';
      _downPct = 20.0;
    });
  }

  void _clearAllSaved() async {
    final dpCalcs = ref.read(savedProvider).where((c) => c.country == 'USA' && c.calcType == 'Down Payment Plan').toList();
    for (final calc in dpCalcs) {
      await ref.read(savedProvider.notifier).delete(calc.id);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All saved calculations cleared', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _saveCalculation() async {
    final price = _val(_homePriceController);
    final rate = _val(_rateController);
    final savingsCapacity = _val(_savingsController);
    final curSavings = _val(_curSavingsController);

    final dpAmt = price * _downPct / 100;
    final loanAmt = max(0.0, price - dpAmt);
    final piAmt = MortgageMath.monthlyPayment(principal: loanAmt, annualRatePercent: rate, termYears: 30);
    final pmiAmt = _pmiPerMonth(loanAmt, _downPct);

    final labelCtrl = TextEditingController(text: 'Down Payment Plan');
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
              'Saving: Down Payment ${CurrencyFormatter.compact(dpAmt, symbol: '\$')} · Home Price: ${CurrencyFormatter.compact(price, symbol: '\$')} · Rate: ${rate.toStringAsFixed(2)}%',
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
                hintText: 'Label (e.g. My Down Payment Calc)',
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
          : 'Down Payment Plan';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'Down Payment Plan',
        inputs: {
          'Price': price,
          'Rate': rate,
          'SavingsCapacity': savingsCapacity,
          'CurrentSavings': curSavings,
          'DownPct': _downPct,
        },
        results: {
          'DownPaymentAmount': dpAmt,
          'LoanAmount': loanAmt,
          'MonthlyPMI': pmiAmt,
          'MonthlyPI': piAmt,
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

  void _loadSavedCalculation(SavedCalc calc) {
    setState(() {
      _homePriceController.text = (calc.inputs['Price'] ?? 450000.0).toStringAsFixed(0);
      _rateController.text = (calc.inputs['Rate'] ?? 6.82).toStringAsFixed(2);
      _savingsController.text = (calc.inputs['SavingsCapacity'] ?? 1500.0).toStringAsFixed(0);
      _curSavingsController.text = (calc.inputs['CurrentSavings'] ?? 40000.0).toStringAsFixed(0);
      _downPct = calc.inputs['DownPct'] ?? 20.0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded saved calculation!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
        backgroundColor: widget.theme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final price = _val(_homePriceController);
    final rate = _val(_rateController);
    final savingsCapacity = _val(_savingsController);
    final curSavings = _val(_curSavingsController);

    final dpAmt = price * _downPct / 100;
    final loanAmt = max(0.0, price - dpAmt);
    final piAmt = max(0.0, MortgageMath.monthlyPayment(principal: loanAmt, annualRatePercent: rate, termYears: 30));
    final pmiAmt = _pmiPerMonth(loanAmt, _downPct);

    // Savings Timeline targets
    final goal20 = price * 0.20;
    final needed20 = max(0.0, goal20 - curSavings);
    final months20 = savingsCapacity > 0 ? (needed20 / savingsCapacity).ceil() : 0;
    final progressPct = goal20 > 0 ? (curSavings / goal20 * 100).clamp(0.0, 100.0) : 0.0;

    final timelineTargets = [3.0, 5.0, 10.0, 20.0];

    // PMI impacts for warning card
    final pmi3Val = _pmiPerMonth(price * 0.97, 3.0);
    final pmi5Val = _pmiPerMonth(price * 0.95, 5.0);
    final pmi10Val = _pmiPerMonth(price * 0.90, 10.0);
    final totalPmiPaid = pmi3Val * 81; // ~6.8 years of PMI = 81 months

    // Watch saved down payment calculations
    final savedCalcs = ref.watch(savedProvider).where((c) => c.country == 'USA' && c.calcType == 'Down Payment Plan').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip
        Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFF1B3F72),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(child: _buildRsCell('Min Conv.', '3%', 'Conforming')),
              _buildRsDivider(),
              Expanded(child: _buildRsCell('No PMI', '20%', 'Threshold', isGold: true)),
              _buildRsDivider(),
              Expanded(child: _buildRsCell('FHA Min', '3.5%', '580 FICO')),
              _buildRsDivider(),
              Expanded(child: _buildRsCell('PMI Rate', '0.5–1.5%', 'Annual')),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _buildSectionHeader('Your Down Payment', onReset: _resetInputs, resetLabel: 'Recalculate'),
        const SizedBox(height: 8),

        // Result Hero
        Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF92400E), Color(0xFFD97706)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SELECTED DOWN PAYMENT AMOUNT',
                style: AppTextStyles.dmSans(
                  size: 9.5,
                  weight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.55),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$',
                    style: AppTextStyles.dmSans(
                      size: 18,
                      weight: FontWeight.w800,
                      color: const Color(0xFFFCD34D),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(dpAmt, symbol: '').split('.').first,
                    style: AppTextStyles.dmSans(
                      size: 38,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ).copyWith(fontFamily: 'Georgia'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${_downPct.toStringAsFixed(_downPct % 1 == 0 ? 0 : 1)}% of ${CurrencyFormatter.format(price, symbol: '\$').split('.').first} · ${_downPct >= 20.0 ? 'No PMI required · Saves ~\$340/mo' : 'PMI: ${CurrencyFormatter.format(pmiAmt, symbol: '\$').split('.').first}/mo'}',
                style: AppTextStyles.dmSans(
                  size: 10,
                  color: Colors.white.withValues(alpha: 0.60),
                ),
              ),
              const SizedBox(height: 14),

              // Hero Stat Cards
              Row(
                children: [
                  Expanded(
                    child: _buildHeroStat('Loan Amount', CurrencyFormatter.format(loanAmt, symbol: '\$').split('.').first, 'Principal'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroStat('Monthly PMI', pmiAmt > 0 ? '${CurrencyFormatter.format(pmiAmt, symbol: '\$').split('.').first}/mo' : '\$0', pmiAmt > 0 ? 'Annual PMI' : 'PMI eliminated'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroStat('Monthly P&I', CurrencyFormatter.format(piAmt, symbol: '\$').split('.').first, '30 yr @ ${rate.toStringAsFixed(2)}%'),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Donut Row
              Row(
                children: [
                  CustomPaint(
                    size: const Size(84, 84),
                    painter: _DownPaymentDonutPainter(
                      downPaymentPct: _downPct / 100.0,
                      loanPct: (100 - _downPct) / 100.0,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildHeroLegendRow(
                          color: const Color(0xFFFCD34D),
                          label: 'Down Payment',
                          value: '${_downPct.toStringAsFixed(_downPct % 1 == 0 ? 0 : 1)}%',
                        ),
                        const SizedBox(height: 8),
                        _buildHeroLegendRow(
                          color: Colors.white.withValues(alpha: 0.85),
                          label: 'Loan Amount',
                          value: '${(100 - _downPct).toStringAsFixed(_downPct % 1 == 0 ? 0 : 1)}%',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _buildSectionHeader('Home Details', onReset: _resetInputs, resetLabel: 'Reset'),
        const SizedBox(height: 8),

        // Inputs Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🔑 ', style: TextStyle(fontSize: 16)),
                  Text(
                    'Property & Loan Info',
                    style: AppTextStyles.dmSans(
                      size: 12.5,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context),
                    ).copyWith(fontFamily: 'Georgia'),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Purchase Price
              _buildInputField(
                label: 'Home Purchase Price',
                controller: _homePriceController,
                hint: 'US median: \$412,000 (2025)',
                prefix: '\$',
              ),
              const SizedBox(height: 12),

              // Down Payment Slider & Pills
              _buildSliderSection(
                label: 'Down Payment Percentage',
                value: _downPct,
                min: 3,
                max: 50,
                displayValue: '${_downPct.toStringAsFixed(_downPct % 1 == 0 ? 0 : 1)}%',
                onChanged: (v) => setState(() => _downPct = double.parse(v.toStringAsFixed(1))),
              ),
              const SizedBox(height: 6),
              _buildSelectorRow<double>(
                value: _downPct,
                items: [3, 3.5, 5, 10, 20, 25],
                labelBuilder: (v) => '${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)}%',
                onChanged: (v) => setState(() => _downPct = v),
              ),
              const SizedBox(height: 12),

              // Interest Rate
              _buildInputField(
                label: 'Interest Rate (30-yr fixed)',
                controller: _rateController,
                hint: '30-yr average: 6.82%',
                suffix: '%',
              ),
              const SizedBox(height: 12),

              // Savings Capacity
              _buildInputField(
                label: 'Monthly Savings Capacity',
                controller: _savingsController,
                hint: 'Amount you can set aside each month',
                prefix: '\$',
                suffix: '/mo',
              ),
              const SizedBox(height: 12),

              // Current Savings
              _buildInputField(
                label: 'Current Savings',
                controller: _curSavingsController,
                hint: 'Your cash reserves today',
                prefix: '\$',
              ),
              const SizedBox(height: 16),

              // Calculate Button inside Inputs Card
              GestureDetector(
                onTap: () => setState(() {}),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD97706), Color(0xFF92400E)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD97706).withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '🔑 Calculate Down Payment Plan',
                    style: AppTextStyles.dmSans(
                      size: 13,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ).copyWith(fontFamily: 'Georgia'),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Save Button inside Inputs Card (Green Gradient)
              GestureDetector(
                onTap: _saveCalculation,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF166534).withValues(alpha: 0.2) : const Color(0xFFDCFCE7),
                    border: Border.all(color: const Color(0xFF15803D), width: 1.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('💾', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Text(
                        'Save This Calculation',
                        style: AppTextStyles.dmSans(
                          size: 13,
                          weight: FontWeight.w800,
                          color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
                        ).copyWith(fontFamily: 'Georgia'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _buildSectionHeader('Down Payment Tiers', onReset: null),
        const SizedBox(height: 8),

        // Tier Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: AppTextStyles.dmSans(
                    size: 12.5,
                    weight: FontWeight.w800,
                    color: theme.getTextColor(context),
                  ).copyWith(fontFamily: 'Georgia'),
                  children: [
                    const TextSpan(text: 'Impact at Current Home Price — '),
                    TextSpan(
                      text: CurrencyFormatter.format(price, symbol: '\$').split('.').first,
                      style: const TextStyle(color: Color(0xFF1E4FBF)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Interactive Tier Rows
              _buildTierItem(
                pct: 3.0,
                label: '3% Conventional',
                desc: 'Fannie Mae HomeReady · 620+ FICO',
                badge: 'PMI Required',
                badgeBg: const Color(0xFFFEF2F2),
                badgeTextColor: const Color(0xFFB91C1C),
                price: price,
                rate: rate,
              ),
              _buildTierItem(
                pct: 3.5,
                label: '3.5% FHA',
                desc: '580+ FICO · MIP for loan life',
                badge: 'MIP Required',
                badgeBg: const Color(0xFFFFF7ED),
                badgeTextColor: const Color(0xFFB45309),
                price: price,
                rate: rate,
              ),
              _buildTierItem(
                pct: 5.0,
                label: '5% Conventional',
                desc: 'Standard conv. · PMI until 80% LTV',
                badge: 'PMI Required',
                badgeBg: const Color(0xFFFFF7ED),
                badgeTextColor: const Color(0xFFB45309),
                price: price,
                rate: rate,
              ),
              _buildTierItem(
                pct: 10.0,
                label: '10% Conventional',
                desc: 'Lower PMI · faster equity',
                badge: 'PMI Reduced',
                badgeBg: const Color(0xFFFFF7ED),
                badgeTextColor: const Color(0xFFB45309),
                price: price,
                rate: rate,
              ),
              _buildTierItem(
                pct: 20.0,
                label: '20% Conventional',
                desc: 'No PMI · best rates · ideal',
                badge: 'No PMI ✓',
                badgeBg: const Color(0xFFF0FDF4),
                badgeTextColor: const Color(0xFF15803D),
                price: price,
                rate: rate,
              ),
              _buildTierItem(
                pct: 25.0,
                label: '25% Conventional',
                desc: 'Investment property standard',
                badge: 'Best Terms',
                badgeBg: const Color(0xFFF0FDF4),
                badgeTextColor: const Color(0xFF15803D),
                price: price,
                rate: rate,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _buildSectionHeader('PMI Cost if < 20% Down', onReset: null),
        const SizedBox(height: 8),

        // PMI Cost Card
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF3F1616) : const Color(0xFFFEF2F2),
            border: Border.all(color: isDark ? const Color(0xFFB91C1C).withValues(alpha: 0.5) : const Color(0xFFFECACA)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⚠️ Private Mortgage Insurance (PMI)',
                style: AppTextStyles.dmSans(
                  size: 12,
                  weight: FontWeight.w800,
                  color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C),
                ).copyWith(fontFamily: 'Georgia'),
              ),
              const SizedBox(height: 10),
              _buildPmiRow('At 3% Down — Monthly PMI', pmi3Val),
              _buildPmiRow('At 5% Down — Monthly PMI', pmi5Val),
              _buildPmiRow('At 10% Down — Monthly PMI', pmi10Val),
              const SizedBox(height: 4),
              Divider(color: isDark ? const Color(0xFF5F2525) : const Color(0xFFFECACA)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PMI Removed at 80% LTV',
                    style: AppTextStyles.dmSans(
                      size: 10.5,
                      weight: FontWeight.w600,
                      color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                    ),
                  ),
                  Text(
                    '~6.8 yrs @ 3%',
                    style: AppTextStyles.dmSans(
                      size: 12,
                      weight: FontWeight.w800,
                      color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C),
                    ).copyWith(fontFamily: 'Georgia'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total PMI Paid (3% down)',
                    style: AppTextStyles.dmSans(
                      size: 10.5,
                      weight: FontWeight.w600,
                      color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                    ),
                  ),
                  Text(
                    '~${CurrencyFormatter.format(totalPmiPaid, symbol: '\$').split('.').first}',
                    style: AppTextStyles.dmSans(
                      size: 12,
                      weight: FontWeight.w800,
                      color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C),
                    ).copyWith(fontFamily: 'Georgia'),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _buildSectionHeader('Savings Timeline', onReset: null),
        const SizedBox(height: 8),

        // Savings Timeline Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Months to Reach Each Down Payment Goal',
                style: AppTextStyles.dmSans(
                  size: 12.5,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context),
                ).copyWith(fontFamily: 'Georgia'),
              ),
              const SizedBox(height: 12),

              // Blocks Row
              Row(
                children: timelineTargets.map((tgt) {
                  final targetAmt = price * tgt / 100;
                  final needed = max(0.0, targetAmt - curSavings);
                  final mo = savingsCapacity > 0 ? (needed / savingsCapacity).ceil() : 0;
                  final isReady = mo <= 0;

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 5),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      decoration: BoxDecoration(
                        color: theme.getBgColor(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${tgt.toInt()}% Down',
                            style: AppTextStyles.dmSans(
                              size: 8,
                              weight: FontWeight.w700,
                              color: theme.getMutedColor(context),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isReady ? '✓' : '$mo',
                            style: AppTextStyles.dmSans(
                              size: 17,
                              weight: FontWeight.w800,
                              color: isReady
                                  ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
                                  : theme.getTextColor(context),
                            ).copyWith(fontFamily: 'Georgia'),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            isReady ? 'Ready!' : '${mo}mo',
                            style: AppTextStyles.dmSans(
                              size: 8,
                              color: theme.getMutedColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Progress Bar
              Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final maxW = constraints.maxWidth;
                      final fillW = maxW * (progressPct / 100);
                      return Container(
                        height: 10,
                        width: fillW,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD97706), Color(0xFF92400E)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('\$0', style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w600, color: theme.getMutedColor(context))),
                  Text('Saved: ${CurrencyFormatter.format(curSavings, symbol: '\$').split('.').first}', style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w600, color: theme.getMutedColor(context))),
                  Text('Goal: ${CurrencyFormatter.format(goal20, symbol: '\$').split('.').first}', style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w600, color: theme.getMutedColor(context))),
                ],
              ),
              const SizedBox(height: 12),

              // Message Box
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.getBgColor(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Text('⏱️ ', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: AppTextStyles.dmSans(
                                size: 12,
                                weight: FontWeight.w800,
                                color: theme.getTextColor(context),
                              ).copyWith(fontFamily: 'Georgia'),
                              children: [
                                const TextSpan(text: 'At '),
                                TextSpan(text: CurrencyFormatter.format(savingsCapacity, symbol: '\$').split('.').first),
                                const TextSpan(text: '/mo savings → '),
                                TextSpan(
                                  text: months20 == 0 ? "You're there!" : '$months20 months to 20%',
                                  style: TextStyle(color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'You have ${CurrencyFormatter.format(curSavings, symbol: '\$').split('.').first} saved · ${needed20 > 0 ? '${CurrencyFormatter.format(needed20, symbol: '\$').split('.').first} more needed' : 'Goal reached!'}',
                            style: AppTextStyles.dmSans(
                              size: 9.5,
                              color: theme.getMutedColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _buildSectionHeader('Down Payment Programs', onReset: null),
        const SizedBox(height: 8),

        // Grid Programs
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.15,
          children: [
            GestureDetector(
              onTap: () => context.push('/tool/usa/huddpa'),
              child: _buildProgramCard(
                emoji: '🏠',
                title: 'HUD DPA Programs',
                desc: 'State & local grants up to \$25K',
                tag: 'Free Money',
                bg1: const Color(0xFF0B1D3A),
                bg2: const Color(0xFF1B3F72),
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/tool/usa/usda'),
              child: _buildProgramCard(
                emoji: '🌾',
                title: 'USDA 0% Down',
                desc: 'Rural areas · no down needed',
                bg1: const Color(0xFF14532D),
                bg2: const Color(0xFF15803D),
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/tool/usa/va'),
              child: _buildProgramCard(
                emoji: '🎖️',
                title: 'VA 0% Down',
                desc: 'Veterans · no PMI ever',
                tag: 'No PMI',
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/tool/usa/fha'),
              child: _buildProgramCard(
                emoji: '🏦',
                title: 'FHA 3.5% Down',
                desc: '580+ FICO · MIP required',
                bg1: const Color(0xFF92400E),
                bg2: const Color(0xFFD97706),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
        _buildSectionHeader('Don\'t Forget', onReset: null),
        const SizedBox(height: 8),

        // Reminders list
        Column(
          children: [
            GestureDetector(
              onTap: () => context.push('/tool/usa/closingcosts'),
              child: _buildReminderCard('📋', 'Closing Costs (2–5%)', '${CurrencyFormatter.format(price * 0.02, symbol: '\$').split('.').first} – ${CurrencyFormatter.format(price * 0.05, symbol: '\$').split('.').first} on a ${CurrencyFormatter.format(price, symbol: '\$').split('.').first} home'),
            ),
            const SizedBox(height: 9),
            GestureDetector(
              onTap: () => context.push('/usa/emergency-fund'),
              child: _buildReminderCard('🛡️', 'Emergency Fund (3–6 months)', 'Keep reserves after closing'),
            ),
            const SizedBox(height: 9),
            GestureDetector(
              onTap: () => context.push('/usa/home-maintenance-budget'),
              child: _buildReminderCard('🔧', 'Home Maintenance Budget', '1–2% of home value/yr · \$375–\$750/mo'),
            ),
            const SizedBox(height: 9),
            GestureDetector(
              onTap: () => context.push('/usa/fico-better-rate'),
              child: _buildReminderCard('💳', 'Boost FICO → Better Rate', '760+ unlocks best mortgage rates'),
            ),
          ],
        ),

        // Saved Calculations History Panel
        const SizedBox(height: 20),
        _buildSectionHeader(
          'Saved Calculations',
          onReset: savedCalcs.isNotEmpty ? _clearAllSaved : null,
          resetLabel: 'Clear All',
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: savedCalcs.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      'No saved calculations yet. Tap "Save This Calculation" above to bookmark a plan.',
                      style: AppTextStyles.dmSans(
                        size: 11,
                        color: theme.getMutedColor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: savedCalcs.map((calc) {
                    final isLast = savedCalcs.indexOf(calc) == savedCalcs.length - 1;
                    final priceVal = calc.inputs['Price'] ?? 0.0;
                    final rateVal = calc.inputs['Rate'] ?? 0.0;
                    final savingsVal = calc.inputs['SavingsCapacity'] ?? 0.0;
                    final curSavVal = calc.inputs['CurrentSavings'] ?? 0.0;
                    final dpVal = calc.inputs['DownPct'] ?? 20.0;
                    final dpAmtVal = calc.results['DownPaymentAmount'] ?? 0.0;

                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isLast
                                ? Colors.transparent
                                : theme.getBorderColor(context).withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _loadSavedCalculation(calc),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${CurrencyFormatter.compact(dpAmtVal, symbol: '\$')} Down (${dpVal.toStringAsFixed(1)}%)',
                                    style: AppTextStyles.dmSans(
                                      size: 12,
                                      weight: FontWeight.w800,
                                      color: theme.getTextColor(context),
                                    ).copyWith(fontFamily: 'Georgia'),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Home ${CurrencyFormatter.compact(priceVal, symbol: '\$')} · Rate ${rateVal.toStringAsFixed(2)}% · Saving ${CurrencyFormatter.compact(savingsVal, symbol: '\$')}/mo · Saved ${CurrencyFormatter.compact(curSavVal, symbol: '\$')}',
                                    style: AppTextStyles.dmSans(
                                      size: 9.5,
                                      color: theme.getMutedColor(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              await ref.read(savedProvider.notifier).delete(calc.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Removed saved calculation', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Text('🗑️', style: TextStyle(fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onReset, String? resetLabel}) {
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
              resetLabel ?? 'Reset →',
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

  Widget _buildHeroStat(String label, String value, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(
              size: 8,
              weight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.50),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.dmSans(
              size: 14,
              weight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            sub,
            style: AppTextStyles.dmSans(
              size: 8,
              color: Colors.white.withValues(alpha: 0.40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    String? prefix,
    String? suffix,
  }) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 9.5,
            weight: FontWeight.w700,
            color: theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            border: Border.all(color: theme.getBorderColor(context), width: 1.5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              if (prefix != null)
                Padding(
                  padding: const EdgeInsets.only(left: 13, right: 10),
                  child: Text(
                    prefix,
                    style: AppTextStyles.dmSans(
                      size: 14,
                      weight: FontWeight.w800,
                      color: theme.getMutedColor(context),
                    ),
                  ),
                ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTextStyles.dmSans(
                    size: 14,
                    weight: FontWeight.w700,
                    color: theme.getTextColor(context),
                  ).copyWith(fontFamily: 'Georgia'),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 11),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.only(right: 13, left: 10),
                  child: Text(
                    suffix,
                    style: AppTextStyles.dmSans(
                      size: 12,
                      weight: FontWeight.w700,
                      color: theme.getMutedColor(context),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (hint.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            hint,
            style: AppTextStyles.dmSans(
              size: 8.5,
              weight: FontWeight.w500,
              color: theme.getMutedColor(context).withValues(alpha: 0.75),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSliderSection({
    required String label,
    required double value,
    required double min,
    required double max,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              style: AppTextStyles.dmSans(
                size: 9.5,
                weight: FontWeight.w700,
                color: widget.theme.getMutedColor(context),
                letterSpacing: 0.5,
              ),
            ),
            Text(
              displayValue,
              style: AppTextStyles.dmSans(
                size: 12,
                weight: FontWeight.w800,
                color: widget.theme.getTextColor(context),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFFD97706),
            thumbColor: const Color(0xFFD97706),
            inactiveTrackColor: const Color(0xFFD97706).withValues(alpha: 0.15),
            overlayColor: const Color(0xFFD97706).withValues(alpha: 0.15),
            trackHeight: 3,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: 94, // (50 - 3) / 0.5 = 94 divisions
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${min.toStringAsFixed(0)}%',
              style: AppTextStyles.dmSans(
                size: 9,
                weight: FontWeight.w600,
                color: widget.theme.getMutedColor(context),
              ),
            ),
            Text(
              '${max.toStringAsFixed(0)}%',
              style: AppTextStyles.dmSans(
                size: 9,
                weight: FontWeight.w600,
                color: widget.theme.getMutedColor(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectorRow<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T> onChanged,
  }) {
    final theme = widget.theme;
    return Row(
      children: items.map((item) {
        final isActive = item == value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(item),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF0B1D3A) : theme.getBgColor(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? const Color(0xFF0B1D3A) : theme.getBorderColor(context),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                labelBuilder(item),
                style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.w700,
                  color: isActive ? Colors.white : theme.getMutedColor(context),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTierItem({
    required double pct,
    required String label,
    required String desc,
    required String badge,
    required Color badgeBg,
    required Color badgeTextColor,
    required double price,
    required double rate,
  }) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ta = price * pct / 100;
    final tl = price - ta;
    final tpi = max(0.0, MortgageMath.monthlyPayment(principal: tl, annualRatePercent: rate, termYears: 30));
    final tpmi = _pmiPerMonth(tl, pct);
    final isActive = (pct - _downPct).abs() < 0.1;

    Color finalBadgeBg = badgeBg;
    Color finalBadgeTextColor = badgeTextColor;
    if (isDark) {
      if (badgeBg == const Color(0xFFFEF2F2)) {
        finalBadgeBg = const Color(0xFF3F1616);
        finalBadgeTextColor = const Color(0xFFF87171);
      } else if (badgeBg == const Color(0xFFFFF7ED)) {
        finalBadgeBg = const Color(0xFF2E1B0F);
        finalBadgeTextColor = const Color(0xFFFBBF24);
      } else if (badgeBg == const Color(0xFFF0FDF4)) {
        finalBadgeBg = const Color(0xFF0F3A1D);
        finalBadgeTextColor = const Color(0xFF4ADE80);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF0F4FF).withValues(alpha: 0.6))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? theme.primaryColor.withValues(alpha: 0.3) : Colors.transparent,
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF0B1D3A) : theme.getBgColor(context),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                '${pct.toStringAsFixed(pct % 1 == 0 ? 0 : 1)}%',
                style: AppTextStyles.dmSans(
                  size: 13,
                  weight: FontWeight.w800,
                  color: isActive ? Colors.white : theme.getTextColor(context),
                ).copyWith(fontFamily: 'Georgia'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.dmSans(
                      size: 12,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context),
                    ).copyWith(fontFamily: 'Georgia'),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: AppTextStyles.dmSans(
                      size: 9.5,
                      color: theme.getMutedColor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: finalBadgeBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: AppTextStyles.dmSans(
                        size: 8.5,
                        weight: FontWeight.w700,
                        color: finalBadgeTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(ta, symbol: '\$').split('.').first,
                  style: AppTextStyles.dmSans(
                    size: 13,
                    weight: FontWeight.w800,
                    color: theme.getTextColor(context),
                  ).copyWith(fontFamily: 'Georgia'),
                ),
                const SizedBox(height: 2),
                Text(
                  '${CurrencyFormatter.format(tpi, symbol: '\$').split('.').first}/mo P&I',
                  style: AppTextStyles.dmSans(
                    size: 9.5,
                    color: theme.getMutedColor(context),
                  ),
                ),
                if (tpmi > 0) ...[
                  const SizedBox(height: 1),
                  Text(
                    '+${CurrencyFormatter.format(tpmi, symbol: '\$').split('.').first} PMI',
                    style: AppTextStyles.dmSans(
                      size: 9.5,
                      weight: FontWeight.w600,
                      color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPmiRow(String key, double val) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            key,
            style: AppTextStyles.dmSans(
              size: 10.5,
              weight: FontWeight.w600,
              color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
            ),
          ),
          Text(
            '${CurrencyFormatter.format(val, symbol: '\$').split('.').first}/mo',
            style: AppTextStyles.dmSans(
              size: 12,
              weight: FontWeight.w800,
              color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C),
            ).copyWith(fontFamily: 'Georgia'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramCard({
    required String emoji,
    required String title,
    required String desc,
    String? tag,
    Color? bg1,
    Color? bg2,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGrd = bg1 != null && bg2 != null;
    final dec = isGrd
        ? BoxDecoration(
            gradient: LinearGradient(colors: [bg1, bg2]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          )
        : BoxDecoration(
            color: widget.theme.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.theme.getBorderColor(context)),
          );

    final titleColor = isGrd ? Colors.white : widget.theme.getTextColor(context);
    final descColor = isGrd ? Colors.white70 : widget.theme.getMutedColor(context);
    final arrowColor = isGrd ? Colors.white.withValues(alpha: 0.22) : widget.theme.getMutedColor(context).withValues(alpha: 0.16);

    Color tagBg = tag == 'Free Money' ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF);
    Color tagText = tag == 'Free Money' ? const Color(0xFF15803D) : const Color(0xFF1D4ED8);
    if (isDark) {
      tagBg = tag == 'Free Money' ? const Color(0xFF0F3A1D) : const Color(0xFF0B1E3F);
      tagText = tag == 'Free Money' ? const Color(0xFF4ADE80) : const Color(0xFF60A5FA);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: dec,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isGrd ? Colors.white.withValues(alpha: 0.14) : widget.theme.getBgColor(context),
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 17)),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTextStyles.dmSans(
                  size: 12.5,
                  weight: FontWeight.w800,
                  color: titleColor,
                ).copyWith(fontFamily: 'Georgia'),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: AppTextStyles.dmSans(
                  size: 9.5,
                  color: descColor,
                ),
              ),
              if (tag != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: tagBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: AppTextStyles.dmSans(
                      size: 8.5,
                      weight: FontWeight.w700,
                      color: tagText,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Text(
              '›',
              style: TextStyle(
                fontSize: 20,
                color: arrowColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(String emoji, String title, String subtitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: widget.theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.theme.getBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
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
            child: Text(emoji, style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.dmSans(
                    size: 12.5,
                    weight: FontWeight.w800,
                    color: widget.theme.getTextColor(context),
                  ).copyWith(fontFamily: 'Georgia'),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.dmSans(
                    size: 9.5,
                    color: widget.theme.getMutedColor(context),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: widget.theme.getMutedColor(context).withValues(alpha: 0.18),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroLegendRow({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.dmSans(size: 10.5, color: Colors.white.withValues(alpha: 0.65)),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildRsCell(String label, String value, String note, {bool isGold = false}) {
    final textColor = isGold ? const Color(0xFFFCD34D) : Colors.white;
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8.5,
            color: Colors.white.withValues(alpha: 0.48),
            weight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.dmSans(
            size: 15,
            weight: FontWeight.w800,
            color: textColor,
          ).copyWith(fontFamily: 'Georgia'),
        ),
        const SizedBox(height: 2),
        Text(
          note,
          style: AppTextStyles.dmSans(
            size: 8,
            color: Colors.white.withValues(alpha: 0.38),
          ),
        ),
      ],
    );
  }

  Widget _buildRsDivider() {
    return Container(
      width: 1,
      height: 25,
      color: Colors.white.withValues(alpha: 0.14),
    );
  }
}

class _DownPaymentDonutPainter extends CustomPainter {
  final double downPaymentPct;
  final double loanPct;
  final bool isDark;

  _DownPaymentDonutPainter({
    required this.downPaymentPct,
    required this.loanPct,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const strokeWidth = 13.0;

    final paintBg = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, paintBg);

    final total = downPaymentPct + loanPct;
    if (total <= 0) return;

    final normDP = downPaymentPct / total;
    final normLoan = loanPct / total;

    double startAngle = -pi / 2;

    if (normDP > 0) {
      final sweep = 2 * pi * normDP;
      final paintDP = Paint()
        ..color = const Color(0xFFFCD34D)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, sweep, false, paintDP);
      startAngle += sweep;
    }

    if (normLoan > 0) {
      final sweep = 2 * pi * normLoan;
      final paintLoan = Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, sweep, false, paintLoan);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

