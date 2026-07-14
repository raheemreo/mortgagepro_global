// lib/features/canada/tools/ca_cmhc_insurance.dart

import 'dart:math' as dm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/canada_rates_provider.dart';
import '../../../shared/models/saved_calc.dart';

class CACmhcInsurance extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const CACmhcInsurance({super.key, required this.theme});

  @override
  ConsumerState<CACmhcInsurance> createState() => _CACmhcInsuranceState();
}

class _CACmhcInsuranceState extends ConsumerState<CACmhcInsurance> {
  final _priceController = TextEditingController(text: '650000');
  final _downController = TextEditingController(text: '65000');

  final _resultsKey = GlobalKey();
  bool _showResults = false;
  final Map<dynamic, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};

  @override
  void dispose() {
    _priceController.dispose();
    _downController.dispose();
    super.dispose();
  }

  double _cmhcRate(double downPct) {
    if (downPct >= 20.0) return 0.0;
    if (downPct >= 15.0) return 0.028;
    if (downPct >= 10.0) return 0.031;
    if (downPct >= 5.0) return 0.040;
    return 0.040;
  }

  double _minDown(double price) {
    if (price <= 500000) return price * 0.05;
    if (price <= 1499999) return 25000 + (price - 500000) * 0.10;
    return price * 0.20;
  }

  double _val(TextEditingController c) {
    if (_showResults && _calcSnapshot.containsKey(c)) {
      return _calcSnapshot[c]!;
    }
    double defaultVal = 0.0;
    if (c == _priceController) {
      defaultVal = 650000.0;
    } else if (c == _downController) {
      defaultVal = 65000.0;
    }
    return double.tryParse(c.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? defaultVal;
  }

  void _calculate() {
    final errors = <String, String>{};
    final price = double.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (price <= 0) errors['price'] = 'Enter a valid purchase price';

    final down = double.tryParse(_downController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (down < 0) {
      errors['down'] = 'Enter a valid down payment';
    } else if (price > 0) {
      final minD = _minDown(price);
      if (down < minD) {
        errors['down'] = 'Min. down payment required is ${CurrencyFormatter.format(minD, symbol: 'CA\$')}';
      }
    }

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) return;

    setState(() {
      _calcSnapshot[_priceController] = price;
      _calcSnapshot[_downController] = down;
      _showResults = true;
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

  void _resetInputs() {
    setState(() {
      _priceController.text = '650000';
      _downController.text = '65000';
      _calcSnapshot.clear();
      _errors.clear();
      _showResults = false;
    });
  }

  void _saveCalculation() async {
    final double price = _val(_priceController);
    final double down = _val(_downController);
    final double downPct = price > 0 ? (down / price * 100) : 0;
    final double baseLoan = price - down;
    final double rate = _cmhcRate(downPct);
    final double premium = baseLoan * rate;

    final labelCtrl = TextEditingController(text: 'CMHC Premium');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/ca_cmhc_insurance/save'),
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
              'Saving: Premium ${CurrencyFormatter.compact(premium, symbol: 'CA\$')} · Price: ${CurrencyFormatter.compact(price, symbol: 'CA\$')}',
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
                hintText: 'Label (e.g. My Premium)',
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
          : 'CMHC Premium';
      final calc = SavedCalc.create(
        country: 'Canada',
        calcType: 'CMHC Insurance',
        inputs: {
          'Price': price,
          'Down': down,
        },
        results: {
          'Premium': premium,
          'BaseLoan': baseLoan,
          'TotalLoan': baseLoan + premium,
          'DownPct': downPct,
        },
        label: label,
        currencyCode: 'CAD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Premium calculation saved!',
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

    final double price = _val(_priceController);
    final double down = _val(_downController);
    final double downPct = price > 0 ? (down / price * 100) : 0;
    final double baseLoan = price - down;
    final double rate = _cmhcRate(downPct);
    final double premium = baseLoan * rate;
    final double totalLoan = baseLoan + premium;

    final double currentPrice = double.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 650000.0;
    final double currentDown = double.tryParse(_downController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 65000.0;
    final double currentDownPct = currentPrice > 0 ? (currentDown / currentPrice * 100) : 0.0;

    final isDirty = _showResults && (
      (double.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_priceController] ?? 0.0) ||
      (double.tryParse(_downController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_downController] ?? 0.0)
    );

    // Premium impact values
    final p1 = baseLoan * 0.04;
    final p2 = baseLoan * 0.031;
    final p3 = baseLoan * 0.028;
    final maxP = p1 > 0 ? p1 : 1.0;

    // Filter saved calcs locally
    final saved = ref.watch(savedProvider);
    final localSaved = saved
        .where((c) =>
            c.country.toLowerCase() == 'canada' &&
            c.calcType.toLowerCase() == 'cmhc insurance')
        .toList();

    // Live BoC rates for display context
    final ratesAsync = ref.watch(canadaCalculatedRatesProvider);
    final live5yr = ratesAsync.valueOrNull?.rate5yrFixed ?? 4.99;
    final liveStress = ratesAsync.valueOrNull?.stressTestRate ?? 7.00;
    final isLive = ratesAsync.valueOrNull?.isLive == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live rate context banner
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _liveRateChip('5-Yr Fixed', '${live5yr.toStringAsFixed(2)}%', isLive),
              Container(width: 1, height: 28, color: theme.getBorderColor(context)),
              _liveRateChip('Stress Test', '${liveStress.toStringAsFixed(2)}%', isLive),
              Container(width: 1, height: 28, color: theme.getBorderColor(context)),
              _liveRateChip('Source', isLive ? '🟢 Live BoC' : 'Estimated', isLive),
            ],
          ),
        ),
        // Section label
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PROPERTY DETAILS',
              style: AppTextStyles.dmSans(
                size: 10,
                weight: FontWeight.bold,
                color: theme.getMutedColor(context),
                letterSpacing: 0.6,
              ),
            ),
            GestureDetector(
              onTap: _resetInputs,
              child: Text(
                'Reset',
                style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Input Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [
              _buildInputField(
                label: 'Purchase Price',
                prefix: 'CA\$',
                controller: _priceController,
                errorText: _errors['price'],
                onChanged: (val) {
                  final double pr = double.tryParse(val.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
                  setState(() {
                    _downController.text = (pr * currentDownPct / 100).round().toString();
                  });
                },
              ),
              const SizedBox(height: 8),
              Slider(
                value: currentPrice.clamp(100000, 1500000),
                min: 100000,
                max: 1500000,
                activeColor: theme.primaryColor,
                inactiveColor: theme.getBorderColor(context),
                onChanged: (val) {
                  setState(() {
                    _priceController.text = val.round().toString();
                    _downController.text = (val * currentDownPct / 100).round().toString();
                  });
                },
              ),
              const SizedBox(height: 12),
              _buildInputField(
                label: 'Down Payment',
                prefix: 'CA\$',
                suffix: '${currentDownPct.toStringAsFixed(1)}%',
                controller: _downController,
                errorText: _errors['down'],
                onChanged: (val) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
              Slider(
                value: currentDownPct.clamp(5, 25),
                min: 5,
                max: 25,
                activeColor: theme.primaryColor,
                inactiveColor: theme.getBorderColor(context),
                onChanged: (val) {
                  setState(() {
                    _downController.text = (currentPrice * val / 100).round().toString();
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _calculate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC8102E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        '🛡️ Calculate CMHC Premium',
                        style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (_showResults) ...[
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
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_showResults) ...[
          if (isDirty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Text('⚠️ ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(
                      'Inputs have changed. Tap Calculate to refresh results.',
                      style: AppTextStyles.dmSans(size: 11, color: Colors.amber[800], weight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            key: _resultsKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Result Card
                Text(
                  'CMHC PREMIUM RESULT',
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
                        'CMHC INSURANCE PREMIUM',
                        style: AppTextStyles.dmSans(
                          size: 9,
                          color: Colors.white60,
                          weight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rate > 0 ? CurrencyFormatter.format(premium, symbol: 'CA\$') : 'CA\$0 — Not Required',
                        style: AppTextStyles.playfair(
                          size: 32,
                          weight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rate > 0
                            ? '${(rate * 100).toStringAsFixed(2)}% of ${CurrencyFormatter.format(baseLoan, symbol: 'CA\$')} insured loan · Added to mortgage'
                            : '20%+ down payment — no CMHC insurance needed',
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
                          _resBox('Down Payment', CurrencyFormatter.format(down, symbol: 'CA\$'), const Color(0xFF6EDFA0)),
                          _resBox('Down %', '${downPct.toStringAsFixed(1)}%', Colors.white),
                          _resBox('Base Loan', CurrencyFormatter.format(baseLoan, symbol: 'CA\$'), Colors.white),
                          _resBox('Total Insured Loan', CurrencyFormatter.format(totalLoan, symbol: 'CA\$'), const Color(0xFFFF8A9A)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Cost Breakdown Donut
                Text(
                  'COST BREAKDOWN',
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
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CustomPaint(
                          painter: _CmhcDonutPainter(
                            down: down,
                            loan: baseLoan,
                            premium: premium,
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          children: [
                            _legendItem('Down Payment', down, downPct, const Color(0xFF1A5C35)),
                            const Divider(height: 14, thickness: 0.5),
                            _legendItem('Base Loan', baseLoan, 100 - downPct, const Color(0xFF4A7C5F)),
                            const Divider(height: 14, thickness: 0.5),
                            _legendItem('CMHC Premium', premium, rate * 100, const Color(0xFFC8102E)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Premium Impact Analysis
                Text(
                  'PREMIUM IMPACT ANALYSIS',
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How Down Payment Affects Your Premium',
                        style: AppTextStyles.playfair(
                          size: 13,
                          weight: FontWeight.bold,
                          color: theme.getTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _impactRow('5–9.99% down → 4.00% premium', p1, 1.0, const Color(0xFFC8102E)),
                      const SizedBox(height: 12),
                      _impactRow('10–14.99% down → 3.10% premium', p2, p2 / maxP, const Color(0xFFF59E0B)),
                      const SizedBox(height: 12),
                      _impactRow('15–19.99% down → 2.80% premium', p3, p3 / maxP, const Color(0xFF4A7C5F)),
                      const SizedBox(height: 12),
                      _impactRow('20%+ down → No CMHC premium', 0, 0.03, const Color(0xFF1A5C35)),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.getBgColor(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          rate > 0
                              ? '💡 Your scenario: At ${downPct.toStringAsFixed(1)}% down you pay ${CurrencyFormatter.format(premium, symbol: 'CA\$')} in CMHC. Increasing to 20% down saves the full premium.'
                              : 'Great! At ${downPct.toStringAsFixed(1)}% down, no CMHC premium is required — you saved ${CurrencyFormatter.format(p2, symbol: 'CA\$')} vs 10% down.',
                          style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context), weight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // PST Warning Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ Ontario & Quebec PST on CMHC',
                        style: AppTextStyles.dmSans(size: 11.5, color: const Color(0xFF92400E), weight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ontario adds 8% PST and Quebec adds 9% QST on the CMHC premium — this must be paid upfront and cannot be rolled into the mortgage. Other provinces have no additional tax.',
                        style: AppTextStyles.dmSans(size: 10, color: const Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Rules Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.getCardColor(context),
                    border: Border.all(color: theme.getBorderColor(context)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✅ CMHC Insurance Eligibility Rules',
                        style: AppTextStyles.dmSans(size: 11, color: theme.primaryColor, weight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _bullet('Purchase price must be under CA\$1,500,000 (effective Dec 15, 2024)'),
                      _bullet('Minimum 5% down for homes under CA\$500K'),
                      _bullet('5% on first CA\$500K + 10% on remainder up to CA\$999,999'),
                      _bullet('Amortization max 25 years (30 yr for first-time buyers, new builds)'),
                      _bullet('Property must be owner-occupied in Canada'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],

        // Saved List Local
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
                            '${CurrencyFormatter.format(c.inputs['Price'] ?? 0, symbol: 'CA\$')} home · ${(c.results['DownPct'] ?? 0).toStringAsFixed(1)}% down',
                            style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: theme.getTextColor(context)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Saved ${c.savedAt.day}/${c.savedAt.month}/${c.savedAt.year} · ${(c.results['DownPct']! < 20) ? 'Insured' : 'Conventional'}',
                            style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(c.results['Premium'] ?? 0, symbol: 'CA\$'),
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

  Widget _buildInputField({
    required String label,
    String? prefix,
    String? suffix,
    required TextEditingController controller,
    required String? errorText,
    required ValueChanged<String> onChanged,
  }) {
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
            border: Border.all(
              color: errorText != null ? Colors.red : theme.getBorderColor(context),
              width: 1.5,
            ),
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
                  onChanged: onChanged,
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
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: AppTextStyles.dmSans(size: 10, color: Colors.red, weight: FontWeight.w500),
          ),
        ],
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

  Widget _legendItem(String label, double val, double pct, Color dotColor) {
    final theme = widget.theme;
    return Row(
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: theme.getTextColor(context))),
            Text('${pct.toStringAsFixed(1)}%', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context))),
          ],
        ),
        const Spacer(),
        Text(
          CurrencyFormatter.format(val, symbol: 'CA\$'),
          style: AppTextStyles.playfair(size: 12, weight: FontWeight.bold, color: theme.getTextColor(context)),
        ),
      ],
    );
  }

  Widget _impactRow(String label, double val, double fillPct, Color color) {
    final theme = widget.theme;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: theme.getTextColor(context))),
            Text(
              val > 0 ? CurrencyFormatter.format(val, symbol: 'CA\$') : 'CA\$0',
              style: AppTextStyles.playfair(size: 12, weight: FontWeight.bold, color: theme.getTextColor(context)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: LinearProgressIndicator(
              value: fillPct.clamp(0, 1),
              backgroundColor: theme.getBgColor(context),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bullet(String text) {
    final theme = widget.theme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5, right: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: theme.accentColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(text, style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context))),
          ),
        ],
      ),
    );
  }

  Widget _liveRateChip(String label, String value, bool isLive) {
    final theme = widget.theme;
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.dmSans(
            size: 8.5,
            color: theme.getMutedColor(context),
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.dmSans(
            size: 12,
            weight: FontWeight.w800,
            color: isLive ? theme.primaryColor : theme.getMutedColor(context),
          ),
        ),
      ],
    );
  }
}

class _CmhcDonutPainter extends CustomPainter {
  final double down, loan, premium;
  _CmhcDonutPainter({required this.down, required this.loan, required this.premium});

  @override
  void paint(Canvas canvas, Size size) {
    final double total = down + loan + premium;
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const double strokeWidth = 14.0;

    final paintBg = Paint()
      ..color = const Color(0xFFEEF6F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, paintBg);

    const double startAngle = -dm.pi / 2;
    final double downSweep = (down / total) * 2 * dm.pi;
    final double loanSweep = (loan / total) * 2 * dm.pi;
    final double premSweep = (premium / total) * 2 * dm.pi;

    final rect = Rect.fromCircle(center: center, radius: radius);

    final paintDown = Paint()
      ..color = const Color(0xFF1A5C35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, startAngle, downSweep, false, paintDown);

    final paintLoan = Paint()
      ..color = const Color(0xFF4A7C5F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, startAngle + downSweep, loanSweep, false, paintLoan);

    if (premium > 0) {
      final paintPrem = Paint()
        ..color = const Color(0xFFC8102E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(rect, startAngle + downSweep + loanSweep, premSweep, false, paintPrem);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
