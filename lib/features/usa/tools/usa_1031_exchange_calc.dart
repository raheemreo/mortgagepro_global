// lib/features/usa/tools/usa_1031_exchange_calc.dart

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

class USA1031ExchangeCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const USA1031ExchangeCalc({super.key, this.theme = CountryThemes.usa});

  @override
  ConsumerState<USA1031ExchangeCalc> createState() => _USA1031ExchangeCalcState();
}

class _USA1031ExchangeCalcState extends ConsumerState<USA1031ExchangeCalc> {
  final _salePriceController = TextEditingController(text: '850000');
  final _costBasisController = TextEditingController(text: '400000');
  final _depreciationController = TextEditingController(text: '80000');
  final _replacePriceController = TextEditingController(text: '950000');

  String _filingStatus = 'married'; // 'single', 'married', 'corp'
  double _stateTaxRate = 0.0725; // default CA

  bool _showResults = false;
  bool _isCalcDirty = true;
  bool _calculating = false;

  final Map<double, String> _stateOptions = {
    0.0: 'No State Tax (TX/FL)',
    0.0725: 'CA — 7.25%',
    0.0685: 'NY — 6.85%',
    0.0499: 'OR — 4.99%',
    0.0330: 'CO — 3.30%',
    0.0575: 'VA — 5.75%',
  };

  @override
  void initState() {
    super.initState();
    final controllers = [
      _salePriceController,
      _costBasisController,
      _depreciationController,
      _replacePriceController
    ];
    for (final c in controllers) {
      c.addListener(_markDirty);
    }
    // Auto calculate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculate();
    });
  }

  @override
  void dispose() {
    _salePriceController.dispose();
    _costBasisController.dispose();
    _depreciationController.dispose();
    _replacePriceController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isCalcDirty) {
      setState(() {
        _isCalcDirty = true;
      });
    }
  }

  double _val(TextEditingController c) => double.tryParse(c.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

  Map<String, dynamic> _computeExchange() {
    final sale = _val(_salePriceController);
    final basis = _val(_costBasisController);
    final depr = _val(_depreciationController);
    final replace = _val(_replacePriceController);
    final stateRate = _stateTaxRate;

    final double adjBasis = basis - depr;
    final double totalGain = sale - adjBasis;

    final double deprRecapture = min(depr, max(0.0, totalGain));
    final double ltGain = max(0.0, totalGain - deprRecapture);

    const double ltRate = 0.20;
    const double deprRate = 0.25;
    const double niitRate = 0.038;

    final double fedTax = (ltGain * (ltRate + niitRate)) + (deprRecapture * deprRate);
    final double stateTax = max(0.0, totalGain) * stateRate;
    final double totalTaxWithout = fedTax + stateTax;

    final double boot = max(0.0, sale - replace);
    final double bootTax = boot > 0 ? (boot * (ltRate + niitRate + stateRate)) : 0.0;
    final double totalTaxWith = bootTax;
    final double savings = max(0.0, totalTaxWithout - totalTaxWith);
    final double newBasis = max(adjBasis, basis + (replace - sale));

    // Compounding over 10 years at 7%
    final List<double> compoundVals = [];
    for (int y = 1; y <= 10; y++) {
      compoundVals.add(savings * pow(1.07, y));
    }

    return {
      'sale': sale,
      'basis': basis,
      'depr': depr,
      'replace': replace,
      'totalGain': totalGain,
      'deprRecapture': deprRecapture,
      'ltGain': ltGain,
      'totalTaxWithout': totalTaxWithout,
      'totalTaxWith': totalTaxWith,
      'savings': savings,
      'boot': boot,
      'newBasis': newBasis,
      'compoundVals': compoundVals,
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
    final sale = _val(_salePriceController);
    if (sale <= 0) return;

    final data = _computeExchange();
    final savings = data['savings'] as double;
    final replace = data['replace'] as double;

    final label = '1031 Exchange (${CurrencyFormatter.compact(sale, symbol: r'$')} Sale)';
    final labelCtrl = TextEditingController(text: label);

    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_1031_exchange_calc'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Exchange Result',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: Sale: ${CurrencyFormatter.compact(sale, symbol: r'$')} · Tax Saved: ${CurrencyFormatter.compact(savings, symbol: r'$')}',
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
      final savedLabel = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : label;
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: '1031 Exchange',
        inputs: {
          'Sale': sale,
          'Basis': data['basis'] as double,
          'Replace': replace,
          'StateRate': _stateTaxRate,
        },
        results: {
          'Total Gain': data['totalGain'] as double,
          'Savings': savings,
          'Tax With 1031': data['totalTaxWith'] as double,
          'Tax Without 1031': data['totalTaxWithout'] as double,
          'Boot': data['boot'] as double,
          'Deferred Basis': data['newBasis'] as double,
        },
        label: savedLabel,
        currencyCode: 'USD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Calculation saved successfully!',
                style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
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

    final data = _computeExchange();
    final totalGain = data['totalGain'] as double;
    final totalTaxWithout = data['totalTaxWithout'] as double;
    final totalTaxWith = data['totalTaxWith'] as double;
    final savings = data['savings'] as double;
    final boot = data['boot'] as double;
    final newBasis = data['newBasis'] as double;
    final List<double> compoundVals = data['compoundVals'] as List<double>;

    final double maxTax = totalTaxWithout > 0 ? totalTaxWithout : 1.0;
    final double pctWith = (totalTaxWith / maxTax).clamp(0.0, 1.0);
    final double pctSavings = (savings / maxTax).clamp(0.0, 1.0);

    final String resultNote = (data['replace'] as double) >= (data['sale'] as double)
        ? '✅ Full deferral: Replacement ≥ Sale Price. All taxes deferred. Step-up basis at death eliminates gain for heirs.'
        : '⚠️ Partial exchange: Boot of ${CurrencyFormatter.format(boot, symbol: r"$")} is taxable. Increase replacement value to defer all taxes.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Header — Live FRED + tax reference
        LightRateStripBanner(items: [
          RateStripItem(label: 'LT Cap Gains\n(20% rate)', provider: fredFedFundsProvider, fallback: 20, suffix: ''),
          RateStripItem(label: 'Depreciation\nRecapture', provider: fredMortgage30Provider, fallback: 25, suffix: '', isGold: true),
          RateStripItem(label: 'NIIT\n(Net Inv. Inc.)', provider: fredFedFundsProvider, fallback: 3.8),
          RateStripItem(label: 'Fed Funds', provider: fredFedFundsProvider, fallback: 5.33),
        ]),
        const SizedBox(height: 16),

        Text('EXCHANGE CALCULATOR', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 8),

        // Inputs Card (Hero Styling)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFF15803D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TAX DEFERRAL ESTIMATOR · IRC §1031', style: AppTextStyles.dmSans(size: 8.5, color: Colors.white70, weight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Calculate Your Tax Savings', style: AppTextStyles.playfair(size: 18, color: Colors.white, weight: FontWeight.bold)),
              Text('on Like-Kind Exchange', style: AppTextStyles.dmSans(size: 11, color: Colors.white60)),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(child: _buildHeroTextField('Relinquished Sale \$', _salePriceController)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildHeroTextField('Original Cost Basis \$', _costBasisController)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildHeroTextField('Depreciation Claimed \$', _depreciationController)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildHeroTextField('Replacement Property \$', _replacePriceController)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FILING STATUS', style: AppTextStyles.dmSans(size: 8.5, color: Colors.white70, weight: FontWeight.bold)),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(color: Colors.white12, border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(10)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _filingStatus,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF0B1D3A),
                              style: AppTextStyles.dmSans(size: 11, color: Colors.white, weight: FontWeight.bold),
                              onChanged: (v) {
                                setState(() {
                                  _filingStatus = v!;
                                  _markDirty();
                                });
                              },
                              items: const [
                                DropdownMenuItem(value: 'single', child: Text('Single (20% LT rate)')),
                                DropdownMenuItem(value: 'married', child: Text('Married Filing Joint')),
                                DropdownMenuItem(value: 'corp', child: Text('Corporation')),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('STATE TAX ADD-ON', style: AppTextStyles.dmSans(size: 8.5, color: Colors.white70, weight: FontWeight.bold)),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(color: Colors.white12, border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(10)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<double>(
                              value: _stateTaxRate,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF0B1D3A),
                              style: AppTextStyles.dmSans(size: 11, color: Colors.white, weight: FontWeight.bold),
                              onChanged: (v) {
                                setState(() {
                                  _stateTaxRate = v!;
                                  _markDirty();
                                });
                              },
                              items: _stateOptions.entries.map((e) {
                                return DropdownMenuItem<double>(value: e.key, child: Text(e.value));
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF15803D),
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _calculate,
                child: _calculating
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🔄', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text('Calculate 1031 Tax Deferral', style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.bold)),
                        ],
                      ),
              ),

              if (_showResults) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white10, border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📊 EXCHANGE ANALYSIS RESULTS', style: AppTextStyles.dmSans(size: 9.5, color: Colors.white60, weight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildResGridItem('Capital Gain', totalGain),
                          _buildResGridItem('Tax w/out 1031', totalTaxWithout, color: const Color(0xFFFCA5A5)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildResGridItem('Tax With 1031', totalTaxWith, color: const Color(0xFF6EE7B7)),
                          _buildResGridItem('Tax Savings', savings, color: const Color(0xFFFCD34D)),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildResGridItem('Boot (Taxable)', boot),
                          _buildResGridItem('Deferred Basis', newBasis),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 20),
                      Text(resultNote, style: AppTextStyles.dmSans(size: 9, color: Colors.white70), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_showResults) ...[
          // Save Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)]),
              border: Border.all(color: const Color(0xFF86EFAC)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text('💾', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Save This Exchange Analysis', style: AppTextStyles.playfair(size: 12, color: const Color(0xFF15803D), weight: FontWeight.bold)),
                      Text('${CurrencyFormatter.compact(data['sale'] as double, symbol: r"$")} sale · ${CurrencyFormatter.compact(savings, symbol: r"$")} deferred', style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF166534))),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _saveCalculation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Save', style: AppTextStyles.dmSans(size: 11, color: Colors.white, weight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tax Impact Analysis Bars
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
                Text('📊 Tax Comparison: With vs Without 1031', style: AppTextStyles.playfair(size: 12.5, color: theme.getTextColor(context), weight: FontWeight.bold)),
                const SizedBox(height: 14),

                _buildTaxBarItem('Without 1031', totalTaxWithout, 1.0, const Color(0xFFB91C1C)),
                const SizedBox(height: 10),
                _buildTaxBarItem('Boot Tax (With)', totalTaxWith, pctWith, const Color(0xFFD97706)),
                const SizedBox(height: 10),
                _buildTaxBarItem('Tax Deferred 💡', savings, pctSavings, const Color(0xFF15803D)),

                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFFF0FDF4), border: Border.all(color: const Color(0xFF86EFAC)), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('💡 Total Tax Deferred', style: AppTextStyles.dmSans(size: 11, color: const Color(0xFF15803D), weight: FontWeight.bold)),
                      Text(CurrencyFormatter.format(savings, symbol: r'$'), style: AppTextStyles.playfair(size: 15, color: const Color(0xFF15803D), weight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Gain Composition Donut
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
                Text('🍩 Capital Gain Breakdown', style: AppTextStyles.playfair(size: 12.5, color: theme.getTextColor(context), weight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      height: 90,
                      width: 90,
                      child: CustomPaint(
                        painter: _ExchangeDonutPainter(
                          ltGain: data['ltGain'] as double,
                          deprRec: data['deprRecapture'] as double,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _buildDonutRow(const Color(0xFFB91C1C), 'LT Capital Gain', data['ltGain'] as double),
                          const SizedBox(height: 6),
                          _buildDonutRow(const Color(0xFFD97706), 'Depr. Recapture', data['deprRecapture'] as double),
                          const SizedBox(height: 6),
                          _buildDonutRow(const Color(0xFF6EE7B7), 'Deferred via 1031', savings),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Gain Composition', style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context), weight: FontWeight.bold)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 16,
                    color: theme.getBgColor(context),
                    child: Row(
                      children: [
                        if (totalGain > 0 && (data['ltGain'] as double) > 0)
                          Expanded(
                            flex: ((data['ltGain'] as double) / totalGain * 100).round(),
                            child: Container(
                              color: const Color(0xFFB91C1C),
                              alignment: Alignment.center,
                              child: const Text('LT Gain', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        if (totalGain > 0 && (data['deprRecapture'] as double) > 0)
                          Expanded(
                            flex: ((data['deprRecapture'] as double) / totalGain * 100).round(),
                            child: Container(
                              color: const Color(0xFFD97706),
                              alignment: Alignment.center,
                              child: const Text('Depr.', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Compound wealth growth card
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
                Text('📈 Deferred Tax Compounding (10 yrs @ 7%)', style: AppTextStyles.playfair(size: 12.5, color: theme.getTextColor(context), weight: FontWeight.bold)),
                Text('What the saved tax amount could grow to if reinvested', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
                const SizedBox(height: 14),
                // Render bar chart
                SizedBox(
                  height: 65,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: compoundVals.asMap().entries.map((entry) {
                      final int idx = entry.key;
                      final double val = entry.value;
                      final double maxCompound = compoundVals.last;
                      final double hFactor = maxCompound > 0 ? (val / maxCompound) : 0.05;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: idx == 9
                                          ? [const Color(0xFF15803D), const Color(0xFF166534)]
                                          : [const Color(0xFF6EE7B7), const Color(0xFF34D399)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                  ),
                                  height: max(4.0, hFactor * 52.0),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('Yr${idx + 1}', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context), weight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('10-yr Compounded Value', style: AppTextStyles.dmSans(size: 11, color: const Color(0xFF15803D), weight: FontWeight.bold)),
                      Text(CurrencyFormatter.format(compoundVals.last, symbol: r'$'), style: AppTextStyles.playfair(size: 14, color: const Color(0xFF15803D), weight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Deadlines Timeline
        Text('CRITICAL DEADLINES', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 8),
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
              Text('⏱️ 1031 Exchange Timeline (IRS Rules)', style: AppTextStyles.playfair(size: 13, color: theme.getTextColor(context), weight: FontWeight.bold)),
              const SizedBox(height: 14),
              _buildTimelineStep('1', 'Day 0', 'Close Relinquished Property', 'Sale of your existing property closes. Proceeds must go directly to a Qualified Intermediary (QI) — never touch the funds.', '⚠️ Do NOT receive proceeds', const Color(0xFF0B1D3A)),
              _buildTimelineStep('2', 'Day 1–45', 'Identification Period', 'Identify up to 3 replacement properties (3-Property Rule) OR any number if total value ≤ 200% of relinquished (200% Rule). Must be in writing to QI.', '⏰ Hard Deadline — No Extensions', const Color(0xFFD97706)),
              _buildTimelineStep('3', 'Day 46–180', 'Exchange Period', 'Must close on identified replacement property within 180 days of relinquished closing OR tax return due date (including extensions), whichever is earlier.', '✅ 180-Day Window', const Color(0xFF15803D)),
              _buildTimelineStep('4', 'Post-Close', 'Report on IRS Form 8824', 'File Form 8824 with your federal tax return. Report like-kind exchange details, boot received, deferred gain, and new adjusted basis.', '📋 Form 8824 Required', const Color(0xFF1B3F72), isLast: true),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // IRS Rules Grid (Using local widgets for look and feel)
        Text('IRS QUALIFICATION RULES', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.35,
          children: [
            _buildRuleCard('🏘️', 'Like-Kind Property', 'Real property for real property in the US', 'IRC §1031(a)', const Color(0xFF0B1D3A)),
            _buildRuleCard('🔁', 'Trade Up Rule', 'Replace with equal or greater value property', 'Fully Deferred', const Color(0xFF15803D)),
            _buildRuleCard('⚖️', 'Boot Rules', 'Cash or unlike property received is taxable "boot"', 'Taxable portion', const Color(0xFFD97706)),
            _buildRuleCard('🏢', 'Held for Investment', 'Must be held for investment or business use', 'Not Personal', Colors.blueGrey),
          ],
        ),
        const SizedBox(height: 16),

        // Disclaimer
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
            border: Border.all(color: const Color(0xFFF59E0B)),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Consult a Qualified Tax Advisor', style: AppTextStyles.playfair(size: 12, color: const Color(0xFF92400E), weight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Text(
                      '1031 Exchange rules are complex. Deadlines are strict and non-extendable. Always work with a licensed CPA, tax attorney, and a Qualified Intermediary (QI). This tool is for educational estimation only.',
                      style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFB45309)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white70, weight: FontWeight.bold)),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white12,
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.bold),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResGridItem(String label, double val, {Color? color}) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white60)),
        const SizedBox(height: 2),
        Text(CurrencyFormatter.format(val, symbol: r'$'), style: AppTextStyles.playfair(size: 14, color: color ?? Colors.white, weight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTaxBarItem(String label, double val, double pct, Color color) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 10.5, color: theme.getTextColor(context), weight: FontWeight.bold)),
            Text(CurrencyFormatter.format(val, symbol: r'$'), style: AppTextStyles.playfair(size: 11, color: color, weight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 11,
          width: double.infinity,
          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: pct.clamp(0.05, 1.0),
            child: Container(
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDonutRow(Color color, String label, double val) {
    final theme = widget.theme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 11, height: 11, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.dmSans(size: 10.5, color: theme.getTextColor(context), weight: FontWeight.bold)),
          ],
        ),
        Text(CurrencyFormatter.format(val, symbol: r'$'), style: AppTextStyles.playfair(size: 10.5, color: theme.getMutedColor(context), weight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTimelineStep(String step, String day, String title, String desc, String badge, Color color, {bool isLast = false}) {
    final theme = widget.theme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(step, style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.bold)),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: theme.getBorderColor(context),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(day, style: AppTextStyles.dmSans(size: 9, color: const Color(0xFFD97706), weight: FontWeight.bold)),
                Text(title, style: AppTextStyles.playfair(size: 12.5, color: theme.getTextColor(context), weight: FontWeight.bold)),
                Text(desc, style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context)), maxLines: 3),
                Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: theme.getBgColor(context), borderRadius: BorderRadius.circular(20)),
                  child: Text(badge, style: AppTextStyles.dmSans(size: 8, color: theme.getTextColor(context), weight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRuleCard(String icon, String title, String desc, String badge, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(11)),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(height: 6),
          Text(title, style: AppTextStyles.playfair(size: 12.5, color: Colors.white, weight: FontWeight.bold)),
          Text(desc, style: AppTextStyles.dmSans(size: 9.5, color: Colors.white60), maxLines: 2),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(20)),
            child: Text(badge, style: AppTextStyles.dmSans(size: 8, color: Colors.white70, weight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ExchangeDonutPainter extends CustomPainter {
  final double ltGain;
  final double deprRec;
  final bool isDark;

  _ExchangeDonutPainter({
    required this.ltGain,
    required this.deprRec,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double total = ltGain + deprRec;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = min(size.width, size.height) / 2 - 6;

    // Background circle
    final bgPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFEFF6FF)
      ..strokeWidth = 13
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

    if (total <= 0) return;

    final double ltAngle = (ltGain / total) * 2 * pi;
    final double deprAngle = (deprRec / total) * 2 * pi;

    final rect = Rect.fromCircle(center: center, radius: radius);
    double startAngle = -pi / 2;

    void drawArcSegment(double angle, Color color) {
      if (angle <= 0) return;
      final p = Paint()
        ..color = color
        ..strokeWidth = 13
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, angle, false, p);
      startAngle += angle;
    }

    drawArcSegment(ltAngle, const Color(0xFFB91C1C));
    drawArcSegment(deprAngle, const Color(0xFFD97706));

    // Center text
    final textPainter = TextPainter(
      text: TextSpan(
        text: CurrencyFormatter.compact(total, symbol: r'$'),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF0B1D3A),
          fontFamily: 'DMSans',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - 9));

    final subPainter = TextPainter(
      text: const TextSpan(
        text: 'Total Gain',
        style: TextStyle(
          fontSize: 7.5,
          color: Colors.grey,
          fontFamily: 'DMSans',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    subPainter.layout();
    subPainter.paint(canvas, Offset(center.dx - subPainter.width / 2, center.dy + 3));
  }

  @override
  bool shouldRepaint(covariant _ExchangeDonutPainter oldDelegate) {
    return oldDelegate.ltGain != ltGain || oldDelegate.deprRec != deprRec || oldDelegate.isDark != isDark;
  }
}

