// lib/features/canada/tools/ca_mortgage_calc.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/result_panel.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/canada_rates_provider.dart';
import '../../../shared/models/saved_calc.dart';

// ── CMHC insurance rate lookup ────────────────────────────────────────────────
double _cmhcRate(double downPct) {
  if (downPct >= 20.0) return 0.0;
  if (downPct >= 15.0) return 0.028;
  if (downPct >= 10.0) return 0.031;
  return 0.04;
}

// Minimum required down payment in Canada
double _calculateMinDownPayment(double price) {
  if (price <= 500000) {
    return price * 0.05;
  } else if (price < 1000000) {
    return 25000 + (price - 500000) * 0.10;
  } else {
    return price * 0.20;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  🍁  CANADIAN MORTGAGE CALCULATOR FULL SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class CAMortgageCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;
  const CAMortgageCalc({super.key, required this.theme, this.savedCalc});

  @override
  ConsumerState<CAMortgageCalc> createState() => _CAMortgageCalcState();
}

class _CAMortgageCalcState extends ConsumerState<CAMortgageCalc> {
  final _priceController = TextEditingController(text: '650000');
  final _downController = TextEditingController(text: '65000');
  final _rateController = TextEditingController(text: '4.99');

  double _homePrice = 650000;
  double _downAmt = 65000;
  double _downPct = 10.0;
  double _rate = 4.99;
  int _amort = 25;
  String _freq = 'biweekly'; // weekly, biweekly, monthly
  bool _hasCalculated = false;

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _homePrice = inputs['price'] ?? 650000.0;
      _downAmt = inputs['down'] ?? 65000.0;
      _rate = inputs['rate'] ?? 4.99;
      _amort = (inputs['amort'] ?? 25.0).toInt();
      final freqVal = inputs['freq'] ?? 1.0;
      _freq = freqVal == 0.0
          ? 'weekly'
          : freqVal == 1.0
              ? 'biweekly'
              : 'monthly';

      _priceController.text = _homePrice.toStringAsFixed(0);
      _downController.text = _downAmt.toStringAsFixed(0);
      _rateController.text = _rate.toString();
      _downPct = _homePrice > 0 ? (_downAmt / _homePrice * 100) : 10.0;
      _hasCalculated = true;
    } else {
      _syncDown('pct');
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _downController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _syncDown(String from) {
    setState(() {
      _homePrice = double.tryParse(_priceController.text) ?? 0;
      if (from == 'pct') {
        _downAmt = (_homePrice * _downPct / 100).roundToDouble();
        _downController.text = _downAmt.toStringAsFixed(0);
      } else {
        _downAmt = double.tryParse(_downController.text) ?? 0;
        _downPct = _homePrice > 0 ? (_downAmt / _homePrice * 100) : 0;
      }
      _rate = double.tryParse(_rateController.text) ?? 4.99;
    });
  }

  void _saveCalculation() async {
    final double baseLoan = _homePrice - _downAmt;
    final double cmhc = baseLoan * _cmhcRate(_downPct);
    final double loan = baseLoan + cmhc;
    final double ea = math.pow(1 + _rate / 200, 2) - 1;
    final double r = _freq == 'monthly'
        ? ea / 12
        : _freq == 'biweekly'
            ? ea / 26
            : ea / 52;
    final double n = _amort *
        (_freq == 'monthly'
            ? 12
            : _freq == 'biweekly'
                ? 26
                : 52);
    final double pmt = loan * r / (1 - math.pow(1 + r, -n));

    final labelCtrl = TextEditingController(text: 'Canada Mortgage');
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
              'Saving: Price ${CurrencyFormatter.compact(_homePrice, symbol: 'CA\$')} · Payment: ${CurrencyFormatter.compact(pmt, symbol: 'CA\$')}/${_freq == 'monthly' ? 'mo' : _freq == 'biweekly' ? 'bi-wk' : 'wk'}',
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
                hintText: 'Label (e.g. Dream House)',
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
          : 'Canada Mortgage';
      final calc = SavedCalc.create(
        country: 'Canada',
        calcType: 'Mortgage Calc',
        inputs: {
          'price': _homePrice,
          'down': _downAmt,
          'rate': _rate,
          'amort': _amort.toDouble(),
          'freq': _freq == 'weekly'
              ? 0.0
              : _freq == 'biweekly'
                  ? 1.0
                  : 2.0,
        },
        results: {
          'Payment': pmt,
          'Loan Amount': loan,
          'CMHC Premium': cmhc,
          'Total Interest': (pmt * n) - loan,
          'Total Cost': (pmt * n) + _downAmt,
        },
        label: label,
        currencyCode: 'CAD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Calculation saved!',
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
    final cardBg = theme.getCardColor(context);
    final borderCol = theme.getBorderColor(context);
    final textThemeColor = theme.getTextColor(context);

    // Watch live rates to auto-populate if not set
    final ratesAsync = ref.watch(canadaCalculatedRatesProvider);
    final live5yr = ratesAsync.valueOrNull?.rate5yrFixed ?? 4.99;
    final liveVar = ratesAsync.valueOrNull?.rateVariable ?? 5.95;
    final liveStress = ratesAsync.valueOrNull?.stressTestRate ?? 7.00;

    // Calculation math
    final double minDown = _calculateMinDownPayment(_homePrice);
    final bool isDownWarning = _downAmt < minDown;

    final double baseLoan = _homePrice - _downAmt;
    final double cmhc = baseLoan * _cmhcRate(_downPct);
    final double loan = baseLoan + cmhc;
    final double ea = math.pow(1 + _rate / 200, 2) - 1;

    double pmt = 0;
    double periods = 0;
    String freqLabel = 'Bi-Weekly';
    String freqSub = 'Every 2 weeks';

    if (_freq == 'monthly') {
      final double r = ea / 12;
      periods = _amort * 12;
      pmt = loan * r / (1 - math.pow(1 + r, -periods));
      freqLabel = 'Monthly';
      freqSub = 'Every month';
    } else if (_freq == 'biweekly') {
      final double r = ea / 26;
      periods = _amort * 26;
      pmt = loan * r / (1 - math.pow(1 + r, -periods));
      freqLabel = 'Bi-Weekly';
      freqSub = 'Every 2 weeks';
    } else {
      final double r = ea / 52;
      periods = _amort * 52;
      pmt = loan * r / (1 - math.pow(1 + r, -periods));
      freqLabel = 'Weekly';
      freqSub = 'Every week';
    }

    final double totalPaid = pmt * periods;
    final double totalInterest = totalPaid - baseLoan - cmhc;
    final double totalCost = totalPaid + _downAmt;

    // Monthly housing summary
    final double moEquiv = _freq == 'monthly'
        ? pmt
        : _freq == 'biweekly'
            ? pmt * 26 / 12
            : pmt * 52 / 12;

    // Visual breakdown segments
    final double bkTotal = baseLoan + totalInterest + cmhc + _downAmt;

    // Fetch saved calcs
    final savedList = ref
        .watch(savedProvider)
        .where((c) =>
            c.country.toLowerCase() == 'canada' &&
            c.calcType == 'Mortgage Calc')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderCol),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _rateStripCell('5-Yr Fixed', '${live5yr.toStringAsFixed(2)}%',
                  '↓ -0.1 wk', const Color(0xFFFF8A9A)),
              _divider(),
              _rateStripCell('Variable', '${liveVar.toStringAsFixed(2)}%',
                  'Prime−0.5', textThemeColor),
              _divider(),
              _rateStripCell('Stress Test', '${liveStress.toStringAsFixed(2)}%',
                  'Min rate', const Color(0xFFF59E0B)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'LOAN DETAILS',
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w700,
            color: theme.getMutedColor(context),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),

        // Inputs Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Home Price Input & Slider
              _buildInputLabel('Home Price'),
              _buildRowField(
                prefix: 'CA\$',
                controller: _priceController,
                onChanged: (v) {
                  _syncDown('pct');
                  setState(() => _hasCalculated = false);
                },
              ),
              _buildSlider(
                value: _homePrice,
                min: 100000,
                max: 2000000,
                divisions: 380,
                onChanged: (v) {
                  setState(() {
                    _homePrice = v;
                    _priceController.text = v.toStringAsFixed(0);
                    _syncDown('pct');
                    _hasCalculated = false;
                  });
                },
              ),
              const SizedBox(height: 14),

              // Down Payment Input & Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInputLabel('Down Payment'),
                  Text(
                    '${_downPct.toStringAsFixed(1)}%',
                    style: AppTextStyles.dmSans(
                        size: 11,
                        weight: FontWeight.bold,
                        color: theme.primaryColor),
                  ),
                ],
              ),
              _buildRowField(
                prefix: 'CA\$',
                controller: _downController,
                onChanged: (v) {
                  _syncDown('amt');
                  setState(() => _hasCalculated = false);
                },
              ),
              _buildSlider(
                value: _downPct,
                min: 5,
                max: 50,
                divisions: 90,
                onChanged: (v) {
                  setState(() {
                    _downPct = v;
                    _syncDown('pct');
                    _hasCalculated = false;
                  });
                },
              ),
              if (isDownWarning)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: Text(
                    '⚠️ Min down payment required: CA\$${minDown.toStringAsFixed(0)}',
                    style: AppTextStyles.dmSans(
                        size: 10,
                        color: const Color(0xFFC8102E),
                        weight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 14),

              // Interest Rate Input
              _buildInputLabel('Interest Rate'),
              _buildRowField(
                suffix: '% / yr',
                controller: _rateController,
                onChanged: (v) {
                  setState(() {
                    _rate = double.tryParse(v) ?? 4.99;
                    _hasCalculated = false;
                  });
                },
              ),
              const SizedBox(height: 14),

              // Amortization Period Toggles
              _buildInputLabel('Amortization Period'),
              Row(
                children: [15, 20, 25, 30].map((yr) {
                  final active = _amort == yr;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _tabButton(
                        label: '$yr yr',
                        active: active,
                        onTap: () => setState(() {
                          _amort = yr;
                          _hasCalculated = false;
                        }),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Payment Frequency Toggles
              _buildInputLabel('Payment Frequency'),
              Row(
                children: [
                  _freqToggleItem('weekly', 'Weekly'),
                  _freqToggleItem('biweekly', 'Bi-wkly'),
                  _freqToggleItem('monthly', 'Monthly'),
                ],
              ),
              const SizedBox(height: 14),

              // Calculate Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC8102E),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13)),
                  ),
                  onPressed: () {
                    _syncDown('amt');
                    setState(() => _hasCalculated = true);
                  },
                  child: Text(
                    '🍁 Calculate Payment',
                    style: AppTextStyles.dmSans(
                        size: 14, color: Colors.white, weight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_hasCalculated) ...[
          // Your Result Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YOUR RESULT',
                style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.w700,
                  color: theme.getMutedColor(context),
                  letterSpacing: 1.0,
                ),
              ),
              GestureDetector(
                onTap: _saveCalculation,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A5C35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bookmark_border,
                          color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Save',
                        style: AppTextStyles.dmSans(
                            size: 10,
                            weight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Main Result Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A2E1A), Color(0xFF1A5C35)],
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
                Text(
                  'Estimated $freqLabel Payment',
                  style: AppTextStyles.dmSans(
                      size: 10,
                      weight: FontWeight.w700,
                      color: Colors.white60,
                      letterSpacing: 0.7),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'CA\$ ',
                      style: AppTextStyles.dmSans(
                          size: 18,
                          weight: FontWeight.w600,
                          color: Colors.white),
                    ),
                    Text(
                      CurrencyFormatter.format(pmt, symbol: '')
                          .split('.')
                          .first,
                      style: AppTextStyles.playfair(
                          size: 38,
                          weight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  ],
                ),
                Text(
                  '$freqSub · $_amort-year amortization',
                  style: AppTextStyles.dmSans(size: 11, color: Colors.white54),
                ),
                if (_downPct < 20.0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Text(
                      '⚠️ CMHC Insurance Required (<20% down)',
                      style: AppTextStyles.dmSans(
                        size: 9.5,
                        weight: FontWeight.bold,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 2.1,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    _resBox('Loan Amount',
                        CurrencyFormatter.format(loan, symbol: 'CA\$')),
                    _resBox(
                        'CMHC Premium',
                        cmhc > 0
                            ? CurrencyFormatter.format(cmhc, symbol: 'CA\$')
                            : 'None',
                        isGreen: cmhc == 0),
                    _resBox('Total Interest',
                        CurrencyFormatter.format(totalInterest, symbol: 'CA\$'),
                        isWarn: true),
                    _resBox('Total Cost',
                        CurrencyFormatter.format(totalCost, symbol: 'CA\$')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Monthly Cost Summary Card
          Text(
            'MONTHLY COST SUMMARY',
            style: AppTextStyles.dmSans(
              size: 11,
              weight: FontWeight.w700,
              color: theme.getMutedColor(context),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What You Actually Pay Each Month',
                  style: AppTextStyles.playfair(
                      size: 13, weight: FontWeight.bold, color: textThemeColor),
                ),
                const SizedBox(height: 12),
                _monthlyCostRow('Mortgage payment (equiv)',
                    CurrencyFormatter.format(moEquiv, symbol: 'CA\$'),
                    isBig: true),
                const Divider(height: 18, thickness: 0.5),
                _monthlyCostRow('Estimated property tax', '~CA\$400'),
                const Divider(height: 18, thickness: 0.5),
                _monthlyCostRow('Estimated heating', '~CA\$150'),
                const Divider(height: 18, thickness: 0.5),
                _monthlyCostRow(
                    'Total housing cost (GDS)',
                    CurrencyFormatter.format(moEquiv + 400 + 150,
                        symbol: 'CA\$'),
                    isRed: true),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Payment Breakdown Stacked Bar
          Text(
            'PAYMENT BREAKDOWN',
            style: AppTextStyles.dmSans(
              size: 11,
              weight: FontWeight.w700,
              color: theme.getMutedColor(context),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              children: [
                _buildStackedBar(
                    baseLoan, totalInterest, cmhc, _downAmt, bkTotal),
                const SizedBox(height: 14),
                _breakdownRow(const Color(0xFF1A5C35), 'Principal', baseLoan,
                    baseLoan / bkTotal * 100),
                _breakdownRow(const Color(0xFFC8102E), 'Total Interest',
                    totalInterest, totalInterest / bkTotal * 100),
                _breakdownRow(const Color(0xFFF59E0B), 'CMHC Insurance', cmhc,
                    cmhc / bkTotal * 100),
                _breakdownRow(const Color(0xFF4A7C5F), 'Down Payment', _downAmt,
                    _downAmt / bkTotal * 100),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Saved Calculations section
        if (savedList.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📌 SAVED CALCULATIONS',
                style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.w700,
                  color: theme.getMutedColor(context),
                  letterSpacing: 1.0,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: cardBg,
                      title: Text('Clear All Saved',
                          style: AppTextStyles.playfair(
                              size: 16, color: textThemeColor)),
                      content: Text('Delete all saved Canadian calculators?',
                          style: AppTextStyles.dmSans(
                              size: 12, color: theme.getMutedColor(context))),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel',
                              style: AppTextStyles.dmSans(
                                  size: 12,
                                  color: Colors.grey,
                                  weight: FontWeight.bold)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Clear All',
                              style: AppTextStyles.dmSans(
                                  size: 12,
                                  color: const Color(0xFFC8102E),
                                  weight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    for (final item in savedList) {
                      await ref.read(savedProvider.notifier).delete(item.id);
                    }
                  }
                },
                child: Text(
                  'Clear All',
                  style: AppTextStyles.dmSans(
                      size: 11,
                      weight: FontWeight.bold,
                      color: theme.getMutedColor(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: savedList.length.clamp(0, 5),
            itemBuilder: (context, idx) {
              final calc = savedList[idx];
              final pVal = calc.inputs['price'] ?? 0.0;
              final rVal = calc.inputs['rate'] ?? 0.0;
              final aVal = calc.inputs['amort'] ?? 0.0;
              final pmtVal = calc.results['Payment'] ?? 0.0;
              final labelSub = calc.label;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderCol),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CA\$${pVal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} · ${rVal.toStringAsFixed(2)}% · ${aVal.toStringAsFixed(0)}yr',
                            style: AppTextStyles.dmSans(
                                size: 12,
                                weight: FontWeight.bold,
                                color: textThemeColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            labelSub,
                            style: AppTextStyles.dmSans(
                                size: 10, color: theme.getMutedColor(context)),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'CA\$${pmtVal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                              style: AppTextStyles.playfair(
                                  size: 14,
                                  weight: FontWeight.w800,
                                  color: theme.primaryColor),
                            ),
                            Text(
                              '/payment',
                              style: AppTextStyles.dmSans(
                                  size: 9, color: theme.getMutedColor(context)),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () =>
                              ref.read(savedProvider.notifier).delete(calc.id),
                          child: const Icon(Icons.close,
                              color: Colors.grey, size: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  // ── Sub widgets ────────────────────────────────────────────────────────────

  Widget _rateStripCell(
      String label, String value, String note, Color valueColor) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
              size: 8,
              color: widget.theme.getMutedColor(context),
              weight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.playfair(
              size: 15, weight: FontWeight.w800, color: valueColor),
        ),
        Text(
          note,
          style: AppTextStyles.dmSans(
              size: 8.5, color: widget.theme.getMutedColor(context)),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 30,
      color: widget.theme.getBorderColor(context),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.dmSans(
          size: 8.5,
          weight: FontWeight.w700,
          color: widget.theme.getMutedColor(context),
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildRowField({
    String? prefix,
    String? suffix,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    final theme = widget.theme;
    return Container(
      decoration: BoxDecoration(
        color: theme.getBgColor(context),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: theme.getBorderColor(context), width: 1.5),
      ),
      child: Row(
        children: [
          if (prefix != null)
            Padding(
              padding: const EdgeInsets.only(left: 11),
              child: Text(
                prefix,
                style: AppTextStyles.dmSans(
                    size: 13,
                    weight: FontWeight.bold,
                    color: theme.primaryColor),
              ),
            ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: AppTextStyles.dmSans(
                  size: 15,
                  weight: FontWeight.bold,
                  color: theme.getTextColor(context)),
              onChanged: onChanged,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                isDense: true,
              ),
            ),
          ),
          if (suffix != null)
            Padding(
              padding: const EdgeInsets.only(right: 11),
              child: Text(
                suffix,
                style: AppTextStyles.dmSans(
                    size: 11,
                    weight: FontWeight.bold,
                    color: theme.getMutedColor(context)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: widget.theme.primaryColor,
        inactiveTrackColor: widget.theme.primaryColor.withValues(alpha: 0.15),
        thumbColor: Colors.white,
        overlayColor: widget.theme.primaryColor.withValues(alpha: 0.1),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(
            enabledThumbRadius: 9.0, pressedElevation: 10),
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }

  Widget _tabButton(
      {required String label,
      required bool active,
      required VoidCallback onTap}) {
    final theme = widget.theme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? theme.primaryColor : theme.getBgColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color:
                  active ? theme.primaryColor : theme.getBorderColor(context)),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: theme.primaryColor.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 12,
            weight: FontWeight.w700,
            color: active ? Colors.white : theme.getMutedColor(context),
          ),
        ),
      ),
    );
  }

  Widget _freqToggleItem(String value, String label) {
    final active = _freq == value;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: _tabButton(
          label: label,
          active: active,
          onTap: () => setState(() {
            _freq = value;
            _hasCalculated = false;
          }),
        ),
      ),
    );
  }

  Widget _resBox(String label, String value,
      {bool isGreen = false, bool isWarn = false}) {
    final valCol = isGreen
        ? const Color(0xFF6EDFA0)
        : isWarn
            ? const Color(0xFFFF8A9A)
            : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.dmSans(
                size: 8.5, color: Colors.white60, weight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.playfair(
                size: 13, weight: FontWeight.w800, color: valCol),
          ),
        ],
      ),
    );
  }

  Widget _monthlyCostRow(String label, String value,
      {bool isBig = false, bool isRed = false}) {
    final theme = widget.theme;
    final valCol = isRed
        ? const Color(0xFFC8102E)
        : isBig
            ? theme.primaryColor
            : theme.getTextColor(context);
    final valWeight = isBig || isRed ? FontWeight.bold : FontWeight.w500;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.dmSans(
              size: 12,
              color: theme.getMutedColor(context),
              weight: FontWeight.w500),
        ),
        Text(
          value,
          style: AppTextStyles.playfair(
              size: isBig ? 16 : 13, weight: valWeight, color: valCol),
        ),
      ],
    );
  }

  Widget _buildStackedBar(double baseLoan, double interest, double cmhc,
      double down, double total) {
    if (total <= 0) return const SizedBox(height: 16);

    final fPrin = baseLoan / total;
    final fInt = interest / total;
    final fCmhc = cmhc / total;
    final fDown = down / total;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 16,
        child: Row(
          children: [
            if (fPrin > 0)
              Expanded(
                flex: (fPrin * 1000).round(),
                child: Container(color: const Color(0xFF1A5C35)),
              ),
            if (fInt > 0)
              Expanded(
                flex: (fInt * 1000).round(),
                child: Container(color: const Color(0xFFC8102E)),
              ),
            if (fCmhc > 0)
              Expanded(
                flex: (fCmhc * 1000).round(),
                child: Container(color: const Color(0xFFF59E0B)),
              ),
            if (fDown > 0)
              Expanded(
                flex: (fDown * 1000).round(),
                child: Container(color: const Color(0xFF4A7C5F)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _breakdownRow(Color dotColor, String label, double value, double pct) {
    final theme = widget.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.dmSans(
                  size: 12,
                  weight: FontWeight.w600,
                  color: theme.getTextColor(context)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(value, symbol: 'CA\$')
                    .split('.')
                    .first,
                style: AppTextStyles.playfair(
                    size: 13,
                    weight: FontWeight.bold,
                    color: theme.getTextColor(context)),
              ),
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: AppTextStyles.dmSans(
                    size: 9, color: theme.getMutedColor(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  🍁  CANADIAN MORTGAGE CALCULATOR MODAL BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class CAMortgageCalcSheet extends ConsumerStatefulWidget {
  final double homePrice;
  final double downPercent;
  final double? defaultContractRate;

  const CAMortgageCalcSheet({
    super.key,
    this.homePrice = 650000,
    this.downPercent = 10,
    this.defaultContractRate,
  });

  @override
  ConsumerState<CAMortgageCalcSheet> createState() =>
      _CAMortgageCalcSheetState();
}

class _CAMortgageCalcSheetState extends ConsumerState<CAMortgageCalcSheet> {
  static const _theme = CountryThemes.canada;
  late double _price;
  late double _downPct;
  late double _downAmt;
  late double _rate;
  int _amort = 25;
  String _freq = 'biweekly';

  @override
  void initState() {
    super.initState();
    _price = widget.homePrice;
    _downPct = widget.downPercent;
    _rate = widget.defaultContractRate ?? 4.99;
    _syncDown('pct');
  }

  void _syncDown(String from) {
    setState(() {
      if (from == 'pct') {
        _downAmt = (_price * _downPct / 100).roundToDouble();
      } else {
        _downPct = _price > 0 ? (_downAmt / _price * 100) : 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double minDown = _calculateMinDownPayment(_price);
    final bool isDownWarning = _downAmt < minDown;

    final double baseLoan = _price - _downAmt;
    final double cmhc = baseLoan * _cmhcRate(_downPct);
    final double loan = baseLoan + cmhc;
    final double ea = math.pow(1 + _rate / 200, 2) - 1;

    double pmt = 0;
    double periods = 0;
    String freqLabel = 'Bi-Weekly';

    if (_freq == 'monthly') {
      final double r = ea / 12;
      periods = _amort * 12;
      pmt = loan * r / (1 - math.pow(1 + r, -periods));
      freqLabel = 'Monthly';
    } else if (_freq == 'biweekly') {
      final double r = ea / 26;
      periods = _amort * 26;
      pmt = loan * r / (1 - math.pow(1 + r, -periods));
      freqLabel = 'Bi-Weekly';
    } else {
      final double r = ea / 52;
      periods = _amort * 52;
      pmt = loan * r / (1 - math.pow(1 + r, -periods));
      freqLabel = 'Weekly';
    }

    final double totalPaid = pmt * periods;
    final double totalInterest = totalPaid - baseLoan - cmhc;
    final double totalCost = totalPaid + _downAmt;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      maxChildSize: 0.94,
      minChildSize: 0.5,
      expand: false,
      builder: (context, sc) => Container(
        decoration: BoxDecoration(
            color: _theme.getBgColor(context),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24))),
        child: ListView(
          controller: sc,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🍁 Canadian Mortgage Calculator',
                        style: AppTextStyles.dmSans(
                            size: 16,
                            weight: FontWeight.w800,
                            color: _theme.getTextColor(context))),
                    Text('CMHC insurance & payment options',
                        style: AppTextStyles.dmSans(
                            size: 10, color: _theme.getMutedColor(context))),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 20),

            // Form inputs
            _row(
                'Home Price',
                CurrencyFormatter.format(_price, symbol: 'CA\$')
                    .split('.')
                    .first),
            _slider(_price, 100000, 2000000, 380, (v) {
              setState(() {
                _price = v;
                _syncDown('pct');
              });
            }),

            _row(
                'Down Payment (${_downPct.toStringAsFixed(1)}%)',
                CurrencyFormatter.format(_downAmt, symbol: 'CA\$')
                    .split('.')
                    .first),
            _slider(_downPct, 5, 50, 90, (v) {
              setState(() {
                _downPct = v;
                _syncDown('pct');
              });
            }),
            if (isDownWarning)
              Padding(
                padding: const EdgeInsets.only(left: 14, bottom: 8),
                child: Text(
                  '⚠️ Min down payment required: CA\$${minDown.toStringAsFixed(0)}',
                  style: AppTextStyles.dmSans(
                      size: 9.5,
                      color: const Color(0xFFC8102E),
                      weight: FontWeight.bold),
                ),
              ),

            _row('Contract Interest Rate', '${_rate.toStringAsFixed(2)}%'),
            _slider(_rate, 1.0, 12.0, 110, (v) => setState(() => _rate = v)),

            // Amortization row toggles
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Amortization',
                      style: AppTextStyles.dmSans(
                          size: 11,
                          weight: FontWeight.w700,
                          color: _theme.getMutedColor(context))),
                  Row(
                    children: [15, 20, 25, 30].map((yr) {
                      final active = _amort == yr;
                      return Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: InkWell(
                          onTap: () => setState(() => _amort = yr),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: active
                                  ? _theme.primaryColor
                                  : _theme.getBgColor(context),
                              border: Border.all(
                                  color: active
                                      ? _theme.primaryColor
                                      : _theme.getBorderColor(context)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$yr yr',
                              style: AppTextStyles.dmSans(
                                size: 10,
                                weight: FontWeight.bold,
                                color: active
                                    ? Colors.white
                                    : _theme.getMutedColor(context),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )
                ],
              ),
            ),

            // Frequency row toggles
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Frequency',
                      style: AppTextStyles.dmSans(
                          size: 11,
                          weight: FontWeight.w700,
                          color: _theme.getMutedColor(context))),
                  Row(
                    children: [
                      ('weekly', 'Weekly'),
                      ('biweekly', 'Bi-Weekly'),
                      ('monthly', 'Monthly')
                    ].map((item) {
                      final active = _freq == item.$1;
                      return Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: InkWell(
                          onTap: () => setState(() => _freq = item.$1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: active
                                  ? _theme.primaryColor
                                  : _theme.getBgColor(context),
                              border: Border.all(
                                  color: active
                                      ? _theme.primaryColor
                                      : _theme.getBorderColor(context)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.$2,
                              style: AppTextStyles.dmSans(
                                size: 10,
                                weight: FontWeight.bold,
                                color: active
                                    ? Colors.white
                                    : _theme.getMutedColor(context),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Result Display Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A2E1A), Color(0xFF1A5C35)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estimated $freqLabel Payment',
                      style: AppTextStyles.dmSans(
                          size: 9.5, color: Colors.white70)),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(pmt, symbol: 'CA\$'),
                    style: AppTextStyles.playfair(
                        size: 28, weight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  if (_downPct < 20.0)
                    Text(
                        '⚠️ Insured mortgage (CMHC Premium: CA\$${cmhc.toStringAsFixed(0)})',
                        style: AppTextStyles.dmSans(
                            size: 9.5,
                            color: const Color(0xFFFFCC00),
                            weight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            ResultPanel(
              primaryColor: _theme.primaryColor,
              rows: [
                ResultRow(
                    label: 'Loan Amount', value: loan, currencyCode: 'CAD'),
                ResultRow(
                    label: 'CMHC Premium', value: cmhc, currencyCode: 'CAD'),
                ResultRow(
                    label: 'Total Interest',
                    value: totalInterest,
                    currencyCode: 'CAD',
                    isHighlighted: true),
                ResultRow(
                    label: 'Total Cost', value: totalCost, currencyCode: 'CAD'),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/tool/canada/mortgage',
                    extra: SavedCalc.create(
                      country: 'Canada',
                      calcType: 'Mortgage Calc',
                      inputs: {
                        'price': _price,
                        'down': _downAmt,
                        'rate': _rate,
                        'amort': _amort.toDouble(),
                        'freq': _freq == 'weekly'
                            ? 0.0
                            : _freq == 'biweekly'
                                ? 1.0
                                : 2.0,
                      },
                      results: {
                        'Payment': pmt,
                        'Loan Amount': loan,
                        'CMHC Premium': cmhc,
                        'Total Interest': totalInterest,
                        'Total Cost': totalCost,
                      },
                      label: 'Estimate for CA\$${_price.toStringAsFixed(0)}',
                      currencyCode: 'CAD',
                    ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _theme.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('Open Advanced Calculator →',
                  style: AppTextStyles.dmSans(
                      size: 12, color: Colors.white, weight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 2, left: 14, right: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l,
                style: AppTextStyles.dmSans(
                    size: 11,
                    weight: FontWeight.bold,
                    color: _theme.getMutedColor(context))),
            Text(v,
                style: AppTextStyles.dmSans(
                    size: 13,
                    weight: FontWeight.bold,
                    color: _theme.primaryColor)),
          ],
        ),
      );

  Widget _slider(double val, double min, double max, int div,
          ValueChanged<double> cb) =>
      SliderTheme(
        data: SliderThemeData(
            activeTrackColor: _theme.primaryColor,
            thumbColor: _theme.primaryColor,
            inactiveTrackColor: _theme.primaryColor.withValues(alpha: 0.15),
            trackHeight: 3),
        child: Slider(
            value: val.clamp(min, max),
            min: min,
            max: max,
            divisions: div,
            onChanged: cb),
      );
}
