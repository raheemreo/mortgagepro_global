// lib/features/canada/tools/ca_affordability.dart

import 'dart:math' as dm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/cmhc_calculator.dart';
import '../../../providers/canada_rates_provider.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class CAAffordability extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const CAAffordability({super.key, required this.theme});

  @override
  ConsumerState<CAAffordability> createState() => _CAAffordabilityState();
}

class _CAAffordabilityState extends ConsumerState<CAAffordability> {
  final _incomeController = TextEditingController(text: '130000');
  final _downController = TextEditingController(text: '80000');
  final _debtsController = TextEditingController(text: '500');
  final _amortController = TextEditingController(text: '25');
  final _rateController = TextEditingController(text: '4.99');

  static const List<Map<String, dynamic>> _cities = [
    {'name': 'Toronto, ON', 'emoji': '🏙️', 'price': 1110000.0},
    {'name': 'Vancouver, BC', 'emoji': '🌊', 'price': 1190000.0},
    {'name': 'Calgary, AB', 'emoji': '🏔️', 'price': 587000.0},
    {'name': 'Ottawa, ON', 'emoji': '🏛️', 'price': 671000.0},
    {'name': 'Montreal, QC', 'emoji': '⚜️', 'price': 538000.0},
    {'name': 'Edmonton, AB', 'emoji': '🛢️', 'price': 408000.0},
    {'name': 'Halifax, NS', 'emoji': '⚓', 'price': 498000.0},
  ];

  @override
  void dispose() {
    _incomeController.dispose();
    _downController.dispose();
    _debtsController.dispose();
    _amortController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  double _monthlyPayment(double loan, double rate, double years) {
    if (loan <= 0 || rate <= 0 || years <= 0) return 0;
    final ea = dm.pow(1 + rate / 200, 2) - 1;
    final r = ea / 12;
    final n = years * 12;
    return loan * r / (1 - dm.pow(1 + r, -n));
  }

  double _minDown(double price) {
    if (price <= 500000) return price * 0.05;
    if (price <= 999999) return 25000 + (price - 500000) * 0.10;
    return price * 0.20;
  }

  double _maxAffordable(double income, double debts, double stressRate, double amort, double down) {
    final mi = income / 12;
    double lo = 0;
    double hi = 3000000;
    for (int i = 0; i < 60; i++) {
      final mid = (lo + hi) / 2;
      final loan = mid - down;
      if (loan <= 0) {
        hi = mid;
        continue;
      }
      final pmt = _monthlyPayment(loan, stressRate, amort);
      final gds = (pmt + 400 + 150) / mi;
      final tds = gds + debts / mi;
      if (tds <= 0.44 && gds <= 0.39) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return (lo / 1000).floor() * 1000.0;
  }

  void _saveCalculation() async {
    final double income = double.tryParse(_incomeController.text) ?? 130000;
    final double down = double.tryParse(_downController.text) ?? 80000;
    final double debts = double.tryParse(_debtsController.text) ?? 500;
    final double amort = double.tryParse(_amortController.text) ?? 25;
    final double rate = double.tryParse(_rateController.text) ?? 4.99;
    final double stressRate = CMHCCalculator.stressTestRate(rate);

    final double maxP = _maxAffordable(income, debts, stressRate, amort, down);

    final labelCtrl = TextEditingController(text: 'Home Budget');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/ca_affordability/save'),
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
              'Saving: Max Price ${CurrencyFormatter.compact(maxP, symbol: 'CA\$')} · Down Saved: ${CurrencyFormatter.compact(down, symbol: 'CA\$')}',
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
                hintText: 'Label (e.g. Dream House Run)',
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
          : 'Affordability';
      final calc = SavedCalc.create(
        country: 'Canada',
        calcType: 'Affordability',
        inputs: {
          'Income': income,
          'Down': down,
          'Debts': debts,
          'Amort': amort,
          'Rate': rate,
        },
        results: {
          'MaxPrice': maxP,
          'Loan': maxP - down,
          'MinDown': _minDown(maxP),
        },
        label: label,
        currencyCode: 'CAD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Budget calculation saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: widget.theme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  bool _rateInitialized = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    // Watch rates provider to initialize default contract rate
    final ratesAsync = ref.watch(canadaCalculatedRatesProvider);
    if (ratesAsync.hasValue && !_rateInitialized) {
      final defaultRate = ratesAsync.value!.rate5yrFixed;
      _rateController.text = defaultRate.toStringAsFixed(2);
      _rateInitialized = true;
    }

    final double income = double.tryParse(_incomeController.text) ?? 130000;
    final double down = double.tryParse(_downController.text) ?? 80000;
    final double debts = double.tryParse(_debtsController.text) ?? 500;
    final double amort = double.tryParse(_amortController.text) ?? 25;
    final double rate = double.tryParse(_rateController.text) ?? 4.99;
    final double stressRate = CMHCCalculator.stressTestRate(rate);

    final double maxP = _maxAffordable(income, debts, stressRate, amort, down);
    final double loan = maxP - down;

    final double cPmt = loan > 0 ? _monthlyPayment(loan, rate, amort) : 0;
    final double sPmt = loan > 0 ? _monthlyPayment(loan, stressRate, amort) : 0;
    final double md = _minDown(maxP);
    final double ds = down - md;

    final double meterPct = (maxP / 1500000).clamp(0.01, 1.0);

    // Filter saved calcs locally
    final saved = ref.watch(savedProvider);
    final localSaved = saved
        .where((c) =>
            c.country.toLowerCase() == 'canada' &&
            c.calcType.toLowerCase() == 'affordability')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Text(
          'YOUR FINANCES',
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),

        // Input card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [
              _buildInputField('Annual Household Income', _incomeController, prefix: 'CA\$', suffix: '/yr'),
              const SizedBox(height: 8),
              Slider(
                value: income.clamp(40000, 500000),
                min: 40000,
                max: 500000,
                activeColor: theme.primaryColor,
                inactiveColor: theme.getBorderColor(context),
                onChanged: (val) {
                  setState(() {
                    _incomeController.text = val.round().toString();
                  });
                },
              ),
              const SizedBox(height: 12),
              _buildInputField('Down Payment Saved', _downController, prefix: 'CA\$'),
              const SizedBox(height: 12),
              _buildInputField('Monthly Debts', _debtsController, prefix: 'CA\$', suffix: '/mo'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField('Amortization', _amortController, suffix: 'yrs'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputField('Interest Rate', _rateController, suffix: '%'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() {}),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC8102E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        '💰 Calculate Affordability',
                        style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _saveCalculation,
                    child: Container(
                      width: 50,
                      height: 46,
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text('💾', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Result Card
        Text(
          'MAXIMUM AFFORDABLE PRICE',
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A2E1A), Color(0xFF1A5C35)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MAXIMUM HOME PRICE (STRESS-TESTED)',
                style: AppTextStyles.dmSans(
                  size: 9,
                  color: Colors.white60,
                  weight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(maxP, symbol: 'CA\$'),
                style: AppTextStyles.playfair(
                  size: 34,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Qualified at ${stressRate.toStringAsFixed(2)}% stress rate · ${amort.toInt()}-yr amort',
                style: AppTextStyles.dmSans(
                  size: 10.5,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  _resBox('Contract Payment/mo', CurrencyFormatter.format(cPmt, symbol: 'CA\$'), const Color(0xFF6EDFA0)),
                  _resBox('Stress Payment/mo', CurrencyFormatter.format(sPmt, symbol: 'CA\$'), const Color(0xFFFF8A9A)),
                  _resBox('Min Down Required', CurrencyFormatter.format(md, symbol: 'CA\$'), Colors.white),
                  _resBox(
                    ds >= 0 ? 'Your Down Surplus' : 'Your Down Deficit',
                    ds >= 0 ? CurrencyFormatter.format(ds, symbol: 'CA\$') : 'Need ${CurrencyFormatter.format(-ds, symbol: 'CA\$')}',
                    ds >= 0 ? const Color(0xFF6EDFA0) : const Color(0xFFFF8A9A),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Buying Power Meter
        Text(
          'BUYING POWER METER',
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Your Affordability vs. National Average',
                  style: AppTextStyles.playfair(size: 13, weight: FontWeight.bold, color: theme.getTextColor(context)),
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: SizedBox(
                  height: 14,
                  child: LinearProgressIndicator(
                    value: meterPct,
                    backgroundColor: theme.getBgColor(context),
                    valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('CA\$0', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context))),
                  Text('\$500K', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context))),
                  Text('\$1M', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context))),
                  Text('\$1.5M+', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context))),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Your max ${CurrencyFormatter.compact(maxP, symbol: 'CA\$')} · National avg CA\$703K',
                style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // City Comparison
        Text(
          'CANADIAN CITY COMPARISON (MAY 2025)',
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cities.length,
            itemBuilder: (context, idx) {
              final c = _cities[idx];
              final double cPrice = c['price'];
              final bool canAfford = maxP >= cPrice;
              final double pct = (maxP / cPrice) * 100;
              final double fillPct = (maxP / cPrice).clamp(0.01, 1.0);

              final barColor = canAfford
                  ? const Color(0xFF1A5C35)
                  : (pct > 80 ? const Color(0xFFF59E0B) : const Color(0xFFC8102E));

              final statusText = canAfford
                  ? '✓ Afford'
                  : (pct > 80 ? 'Close' : '✗ Over');

              final statusColor = canAfford
                  ? const Color(0xFFDCF4E8)
                  : (pct > 80 ? const Color(0xFFFEF3C7) : const Color(0xFFFFE4E8));

              final statusTextCol = canAfford
                  ? const Color(0xFF1A5C35)
                  : (pct > 80 ? const Color(0xFF92400E) : const Color(0xFFC8102E));

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: theme.getBorderColor(context), width: idx == _cities.length - 1 ? 0 : 0.5)),
                ),
                child: Row(
                  children: [
                    Text(c['emoji'], style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(c['name'], style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.bold, color: theme.getTextColor(context))),
                              Text(
                                '${(cPrice / 1000000).toStringAsFixed(2)}M avg · ${pct.round()}% of budget',
                                style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: SizedBox(
                              height: 6,
                              child: LinearProgressIndicator(
                                value: fillPct,
                                backgroundColor: theme.getBgColor(context),
                                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        statusText,
                        style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.bold, color: statusTextCol),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Down Payment Rules Table
        Text(
          'MINIMUM DOWN PAYMENT RULES',
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                color: theme.getBgColor(context),
                child: Row(
                  children: [
                    Expanded(child: Text('Purchase Price', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.bold, color: theme.getMutedColor(context)))),
                    Expanded(child: Text('Min. Down', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.bold, color: theme.getMutedColor(context)))),
                    Expanded(child: Text('Min. Amount', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.bold, color: theme.getMutedColor(context)))),
                  ],
                ),
              ),
              _ruleRow('Up to CA\$500K', '5%', 'CA\$25,000', isBold: true),
              const Divider(height: 1, thickness: 0.5),
              _ruleRow('CA\$500K–\$999K', '5%+10%', 'CA\$25K–\$74.9K'),
              const Divider(height: 1, thickness: 0.5),
              _ruleRow('CA\$1M–\$1.5M', '20%', 'CA\$200K+'),
              const Divider(height: 1, thickness: 0.5),
              _ruleRow('Over CA\$1.5M', '20%+', 'No CMHC'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Local saved calcs
        if (localSaved.isNotEmpty) ...[
          Text(
            'SAVED CALCULATIONS',
            style: AppTextStyles.dmSans(
              size: 10,
              weight: FontWeight.bold,
              color: theme.getMutedColor(context),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: localSaved.length,
            itemBuilder: (context, idx) {
              final c = localSaved[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.getCardColor(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.getBorderColor(context)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Income CA\$${((c.inputs['Income'] ?? 0) / 1000).round()}K · Down CA\$${((c.inputs['Down'] ?? 0) / 1000).round()}K',
                            style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: theme.getTextColor(context)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Saved ${c.savedAt.day}/${c.savedAt.month}/${c.savedAt.year} · ${c.inputs['Rate']}% rate',
                            style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(c.results['MaxPrice'] ?? 0, symbol: 'CA\$'),
                      style: AppTextStyles.playfair(size: 14, weight: FontWeight.bold, color: theme.primaryColor),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => ref.read(savedProvider.notifier).delete(c.id),
                      child: const Text('✕', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {String? prefix, String? suffix}) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 9,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
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
                  child: Text(prefix, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.bold, color: theme.primaryColor)),
                ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  onChanged: (val) => setState(() {}),
                  style: AppTextStyles.dmSans(
                    size: 16,
                    weight: FontWeight.bold,
                    color: theme.getTextColor(context),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 11, vertical: 12),
                    isDense: true,
                  ),
                ),
              ),
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.only(right: 11),
                  child: Text(suffix, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w600, color: theme.getMutedColor(context))),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _resBox(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.dmSans(
              size: 8,
              color: Colors.white60,
              weight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.playfair(
              size: 13,
              weight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ruleRow(String price, String down, String amt, {bool isBold = false}) {
    final theme = widget.theme;
    final style = AppTextStyles.dmSans(
        size: 12,
        weight: isBold ? FontWeight.bold : FontWeight.w600,
        color: isBold ? theme.primaryColor : theme.getTextColor(context));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      color: isBold ? theme.primaryColor.withValues(alpha: 0.05) : Colors.transparent,
      child: Row(
        children: [
          Expanded(child: Text(price, style: style)),
          Expanded(child: Text(down, style: style)),
          Expanded(child: Text(amt, style: style)),
        ],
      ),
    );
  }
}
