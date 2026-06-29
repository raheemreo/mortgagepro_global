// lib/features/usa/tools/usa_fix_flip_calc.dart

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

class USAFixFlipCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const USAFixFlipCalc({super.key, this.theme = CountryThemes.usa});

  @override
  ConsumerState<USAFixFlipCalc> createState() => _USAFixFlipCalcState();
}

class _USAFixFlipCalcState extends ConsumerState<USAFixFlipCalc> {
  final _arvController = TextEditingController(text: '425000');
  final _purchaseController = TextEditingController(text: '240000');
  final _rehabController = TextEditingController(text: '55000');
  final _holdMonthsController = TextEditingController(text: '5');
  final _hardRateController = TextEditingController(text: '12');
  final _loanPctController = TextEditingController(text: '80');
  final _buyCloseController = TextEditingController(text: '2');
  final _sellCloseController = TextEditingController(text: '8');
  final _holdCostsController = TextEditingController(text: '1200');
  final _miscController = TextEditingController(text: '5000');

  bool _showResults = false;
  bool _isCalcDirty = true;
  bool _calculating = false;

  @override
  void initState() {
    super.initState();
    final controllers = [
      _arvController,
      _purchaseController,
      _rehabController,
      _holdMonthsController,
      _hardRateController,
      _loanPctController,
      _buyCloseController,
      _sellCloseController,
      _holdCostsController,
      _miscController
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
    _arvController.dispose();
    _purchaseController.dispose();
    _rehabController.dispose();
    _holdMonthsController.dispose();
    _hardRateController.dispose();
    _loanPctController.dispose();
    _buyCloseController.dispose();
    _sellCloseController.dispose();
    _holdCostsController.dispose();
    _miscController.dispose();
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

  Map<String, dynamic> _computeFlip() {
    final arv = _val(_arvController);
    final purchasePrice = _val(_purchaseController);
    final rehab = _val(_rehabController);
    final holdMonths = max(1.0, _val(_holdMonthsController));
    final hardRate = _val(_hardRateController) / 100;
    final loanPct = _val(_loanPctController) / 100;
    final buyClosePct = _val(_buyCloseController) / 100;
    final sellClosePct = _val(_sellCloseController) / 100;
    final holdCostsM = _val(_holdCostsController);
    final misc = _val(_miscController);

    final loanAmt = purchasePrice * loanPct;
    final financing = loanAmt * hardRate * (holdMonths / 12);
    final buyClosing = purchasePrice * buyClosePct;
    final sellClosing = arv * sellClosePct;
    final holdTotal = holdCostsM * holdMonths;
    final totalCost = purchasePrice + rehab + financing + buyClosing + sellClosing + holdTotal + misc;
    final netProfit = arv - totalCost;
    final cashInvested = purchasePrice * (1 - loanPct) + rehab + buyClosing + misc;
    final roi = cashInvested > 0 ? (netProfit / cashInvested) * 100 : 0.0;
    final annRoi = roi / (holdMonths / 12);
    final profitMo = netProfit / holdMonths;
    final otherCosts = financing + buyClosing + sellClosing + holdTotal + misc;

    // 70% rule
    final mao = arv * 0.70 - rehab;

    return {
      'arv': arv,
      'purchasePrice': purchasePrice,
      'rehab': rehab,
      'holdMonths': holdMonths,
      'financing': financing,
      'buyClosing': buyClosing,
      'sellClosing': sellClosing,
      'holdTotal': holdTotal,
      'misc': misc,
      'otherCosts': otherCosts,
      'totalCost': totalCost,
      'netProfit': netProfit,
      'cashInvested': cashInvested,
      'roi': roi,
      'annRoi': annRoi,
      'profitMo': profitMo,
      'mao': mao,
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
    final arv = _val(_arvController);
    if (arv <= 0) return;

    final data = _computeFlip();
    final netProfit = data['netProfit'] as double;
    final roi = data['roi'] as double;

    final label = 'Fix & Flip (Profit: ${CurrencyFormatter.compact(netProfit, symbol: r'$')})';
    final labelCtrl = TextEditingController(text: label);

    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_fix_flip_calc'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Deal Analysis',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: Profit: ${CurrencyFormatter.compact(netProfit, symbol: r'$')} · ROI: ${roi.toStringAsFixed(1)}%',
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
        calcType: 'Fix & Flip Calc',
        inputs: {
          'ARV': arv,
          'Purchase': data['purchasePrice'] as double,
          'Rehab': data['rehab'] as double,
          'Hold': data['holdMonths'] as double,
        },
        results: {
          'Net Profit': netProfit,
          'ROI': roi,
          'Annualized ROI': data['annRoi'] as double,
          'All-In Cost': data['totalCost'] as double,
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

    final data = _computeFlip();
    final arv = data['arv'] as double;
    final purchasePrice = data['purchasePrice'] as double;
    final rehab = data['rehab'] as double;
    final financing = data['financing'] as double;
    final buyClosing = data['buyClosing'] as double;
    final sellClosing = data['sellClosing'] as double;
    final holdTotal = data['holdTotal'] as double;
    final misc = data['misc'] as double;
    final totalCost = data['totalCost'] as double;
    final netProfit = data['netProfit'] as double;
    final roi = data['roi'] as double;
    final annRoi = data['annRoi'] as double;
    final profitMo = data['profitMo'] as double;
    final otherCosts = data['otherCosts'] as double;
    final mao = data['mao'] as double;

    final isWin = netProfit >= 40000.0;
    final isLoss = netProfit < 0.0;

    final List<Map<String, dynamic>> costItems = [
      {'label': 'Purchase Price', 'val': purchasePrice, 'color': const Color(0xFF334155)},
      {'label': 'Rehab Costs', 'val': rehab, 'color': const Color(0xFFD97706)},
      {'label': 'Selling Costs', 'val': sellClosing, 'color': const Color(0xFFB91C1C)},
      {'label': 'Financing', 'val': financing, 'color': const Color(0xFF6D28D9)},
      {'label': 'Holding Costs', 'val': holdTotal, 'color': const Color(0xFF0F766E)},
      {'label': 'Buy Close + Misc', 'val': buyClosing + misc, 'color': const Color(0xFF64748B)},
    ];

    final double maxCost = costItems.isNotEmpty
        ? costItems.map((c) => c['val'] as double).reduce((a, b) => a > b ? a : b)
        : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Header — Live hard money / FRED rates
        LightRateStripBanner(items: [
          RateStripItem(label: 'Hard Money\n(Avg 12%)', provider: fredPrimeProvider, fallback: 12.0),
          RateStripItem(label: 'VNQ ETF\n(RE Market)', provider: vnqPriceProvider, fallback: 92.50, suffix: '', isDollar: true),
          RateStripItem(label: 'Prime Rate', provider: fredPrimeProvider, fallback: 8.50),
          RateStripItem(label: 'Fed Funds', provider: fredFedFundsProvider, fallback: 5.33, isGold: true),
        ]),
        const SizedBox(height: 16),

        Text('DEAL DETAILS', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
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
                  Expanded(child: _buildTextField('After Repair Value (ARV) (\$)', _arvController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Purchase Price (\$)', _purchaseController)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Rehab / Repair Cost (\$)', _rehabController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Hold Period (months)', _holdMonthsController)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Hard Money Rate (%/yr)', _hardRateController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Loan % of Purchase (%)', _loanPctController)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Closing Costs Buy (%)', _buyCloseController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Selling Costs % ARV (%)', _sellCloseController)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Holding Costs/mo (\$)', _holdCostsController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Misc / Contingency (\$)', _miscController)),
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
                          colors: [Color(0xFF334155), Color(0xFF1E293B)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _calculate,
                        child: _calculating
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text('🔨 Analyze Fix & Flip Deal', style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.bold)),
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
                        color: _showResults ? const Color(0xFF15803D) : theme.getBgColor(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.getBorderColor(context)),
                      ),
                      alignment: Alignment.center,
                      child: Text('💾 Save',
                          style: AppTextStyles.dmSans(
                              size: 13,
                              color: _showResults ? Colors.white : theme.getMutedColor(context),
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
          // Deal Verdict Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLoss
                    ? [const Color(0xFFB91C1C), const Color(0xFF991B1B)]
                    : isWin
                        ? [const Color(0xFF15803D), const Color(0xFF166534)]
                        : [const Color(0xFFD97706), const Color(0xFFB45309)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NET PROFIT', style: AppTextStyles.dmSans(size: 10, color: Colors.white60, weight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(CurrencyFormatter.format(netProfit, symbol: r'$'),
                    style: AppTextStyles.playfair(size: 40, color: const Color(0xFFFCD34D), weight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  netProfit >= 50000.0
                      ? '✓ Strong deal — ${roi.toStringAsFixed(1)}% ROI on cash invested'
                      : netProfit >= 0
                          ? '⚠️ Thin margin — ${roi.toStringAsFixed(1)}% ROI on cash invested'
                          : '✗ Loss — renegotiate purchase price or rehab details',
                  style: AppTextStyles.dmSans(size: 11, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildVerdictGridItem('ROI on Cash', '${roi.toStringAsFixed(1)}%', isString: true),
                    _buildVerdictGridItem('Annualized ROI', '${annRoi.toStringAsFixed(1)}%', isString: true),
                    _buildVerdictGridItem('All-In Cost', totalCost),
                    _buildVerdictGridItem('Profit/Month', '${CurrencyFormatter.compact(profitMo, symbol: r"$")}/mo', isString: true),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Cost Breakdown vs ARV Donut Chart Card
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
                Text('🍩 Cost Breakdown vs ARV', style: AppTextStyles.playfair(size: 12.5, color: theme.getTextColor(context), weight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      height: 90,
                      width: 90,
                      child: CustomPaint(
                        painter: _FlipDonutPainter(
                          buy: purchasePrice,
                          rehab: rehab,
                          other: otherCosts,
                          profit: max(0.0, netProfit),
                          arv: arv,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _buildDonutRow(const Color(0xFF334155), 'Purchase', purchasePrice),
                          const SizedBox(height: 6),
                          _buildDonutRow(const Color(0xFFD97706), 'Rehab', rehab),
                          const SizedBox(height: 6),
                          _buildDonutRow(const Color(0xFFB91C1C), 'Other Costs', otherCosts),
                          const SizedBox(height: 6),
                          _buildDonutRow(const Color(0xFF6EE7B7), 'Net Profit', max(0.0, netProfit)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Text('📐 Scenario Comparison', style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context), weight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildScenarioCard('Conservative', arv * 0.90, arv * 0.90 - totalCost, const Color(0xFFB91C1C)),
                    const SizedBox(width: 6),
                    _buildScenarioCard('Base Case', arv, netProfit, const Color(0xFF334155)),
                    const SizedBox(width: 6),
                    _buildScenarioCard('Optimistic', arv * 1.10, arv * 1.10 - totalCost, const Color(0xFF15803D)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Horizontal cost bars
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
                Text('📊 Cost Breakdown details', style: AppTextStyles.playfair(size: 12.5, color: theme.getTextColor(context), weight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...costItems.map((bar) {
                  final double val = bar['val'] as double;
                  final double pct = val / maxCost;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(bar['label'] as String, style: AppTextStyles.dmSans(size: 10.5, color: theme.getTextColor(context), weight: FontWeight.bold)),
                            Text(CurrencyFormatter.format(val, symbol: r'$'), style: AppTextStyles.playfair(size: 11, color: bar['color'] as Color, weight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 10,
                          width: double.infinity,
                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(5)),
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: pct.clamp(0.05, 1.0),
                            child: Container(
                              decoration: BoxDecoration(color: bar['color'] as Color, borderRadius: BorderRadius.circular(5)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Profit Waterfall List
          Text('PROFIT WATERFALL', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              children: [
                _buildWaterfallRow('After Repair Value (ARV)', arv, isPos: true),
                _buildWaterfallRow('(-) Purchase Price', purchasePrice, isPos: false),
                _buildWaterfallRow('(-) Rehab Costs', rehab, isPos: false),
                _buildWaterfallRow('(-) Financing / Interest', financing, isPos: false),
                _buildWaterfallRow('(-) Buying Closing Costs', buyClosing, isPos: false),
                _buildWaterfallRow('(-) Selling Costs', sellClosing, isPos: false),
                _buildWaterfallRow('(-) Holding Costs', holdTotal, isPos: false),
                _buildWaterfallRow('(-) Misc / Contingency', misc, isPos: false),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFF0B1D3A), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Net Profit (Pre-Tax)', style: AppTextStyles.dmSans(size: 11, color: Colors.white70, weight: FontWeight.bold)),
                      Text(CurrencyFormatter.format(netProfit, symbol: r'$'), style: AppTextStyles.playfair(size: 17, color: const Color(0xFFFCD34D), weight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 70% Rule Check
          Text('70% RULE CHECK', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
              border: Border.all(color: const Color(0xFFF59E0B)),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📐 The 70% Rule', style: AppTextStyles.playfair(size: 12.5, color: const Color(0xFF92400E), weight: FontWeight.bold)),
                Text('Maximum allowable offer = 70% of ARV minus repair costs', style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFB45309))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  width: double.infinity,
                  decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10)),
                  child: Center(
                    child: Text(
                      'Max Offer = (ARV × 70%) − Rehab = ${CurrencyFormatter.compact(mao, symbol: r"$")}',
                      style: AppTextStyles.playfair(size: 11.5, color: const Color(0xFF92400E), weight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Max Allowable Offer', style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFB45309), weight: FontWeight.bold)),
                        Text(CurrencyFormatter.format(mao, symbol: r'$'), style: AppTextStyles.playfair(size: 18, color: const Color(0xFF92400E), weight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Purchase Price', style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFB45309), weight: FontWeight.bold)),
                        Text(CurrencyFormatter.format(purchasePrice, symbol: r'$'), style: AppTextStyles.playfair(size: 18, color: const Color(0xFF92400E), weight: FontWeight.bold)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: purchasePrice <= mao ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        purchasePrice <= mao ? '✓ Under MAO' : '✗ Over MAO',
                        style: AppTextStyles.dmSans(size: 10, color: Colors.white, weight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Advisor Tips
        Text('FLIP TIPS & MARKET DATA', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildGuideCard('Best Flip Markets 2024', 'Pittsburgh · Baltimore · Memphis · Detroit (highest average ROI)'),
        _buildGuideCard('Rehab Cost Guide (Per Sq Ft)', 'Cosmetic \$15–\$40 · Mid \$40–\$80 · Full gut \$80–\$150+/sqft'),
        _buildGuideCard('Speed = Profit', 'Every extra month costs holding + financing fees of \$2K–\$5K+'),
        _buildGuideCard('Short-Term Capital Gains Tax', 'Held <1 yr taxed as ordinary income (up to 37% federal rate)'),
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

  Widget _buildVerdictGridItem(String label, dynamic value, {bool isString = false, bool isPct = false}) {
    final String display = isString
        ? value.toString()
        : isPct
            ? '${(value as double).toStringAsFixed(1)}%'
            : CurrencyFormatter.format(value as double, symbol: r'$');
    return Column(
      children: [
        Text(display, style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white70)),
      ],
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

  Widget _buildScenarioCard(String label, double arvVal, double profitVal, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 9, color: Colors.white70, weight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(CurrencyFormatter.format(profitVal, symbol: r'$'), style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text('${CurrencyFormatter.compact(arvVal, symbol: r"$")} ARV', style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterfallRow(String name, double val, {required bool isPos}) {
    final theme = widget.theme;
    final String sign = isPos ? '' : '-';
    final Color col = isPos ? const Color(0xFF15803D) : const Color(0xFFB91C1C);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.getBorderColor(context)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.w600)),
          Text(
            '$sign${CurrencyFormatter.format(val, symbol: r'$')}',
            style: AppTextStyles.playfair(size: 12.5, color: col, weight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(String title, String desc) {
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
            decoration: BoxDecoration(color: theme.getBgColor(context), borderRadius: BorderRadius.circular(11)),
            alignment: Alignment.center,
            child: const Text('🔨', style: TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.playfair(size: 12.5, color: theme.getTextColor(context), weight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(desc, style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlipDonutPainter extends CustomPainter {
  final double buy;
  final double rehab;
  final double other;
  final double profit;
  final double arv;
  final bool isDark;

  _FlipDonutPainter({
    required this.buy,
    required this.rehab,
    required this.other,
    required this.profit,
    required this.arv,
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
      ..strokeWidth = 13
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

    if (arv <= 0) return;

    final double buyAngle = (buy / arv) * 2 * pi;
    final double rehabAngle = (rehab / arv) * 2 * pi;
    final double otherAngle = (other / arv) * 2 * pi;
    final double profitAngle = (profit / arv) * 2 * pi;

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

    drawArcSegment(buyAngle, const Color(0xFF334155));
    drawArcSegment(rehabAngle, const Color(0xFFD97706));
    drawArcSegment(otherAngle, const Color(0xFFB91C1C));
    drawArcSegment(profitAngle, const Color(0xFF6EE7B7));

    // Center ROI text
    final double cashInvested = buy * 0.20 + rehab + buy * 0.02 + 5000; // conservative check
    final double roi = cashInvested > 0 ? (profit / cashInvested) * 100 : 0.0;

    final textPainter = TextPainter(
      text: TextSpan(
        text: '${roi.toStringAsFixed(0)}%',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFF0B1D3A),
          fontFamily: 'Georgia',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - 10));

    final subPainter = TextPainter(
      text: const TextSpan(
        text: 'ROI',
        style: TextStyle(
          fontSize: 7.5,
          color: Colors.grey,
          fontFamily: 'DMSans',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    subPainter.layout();
    subPainter.paint(canvas, Offset(center.dx - subPainter.width / 2, center.dy + 4));
  }

  @override
  bool shouldRepaint(covariant _FlipDonutPainter oldDelegate) {
    return oldDelegate.buy != buy || oldDelegate.rehab != rehab || oldDelegate.other != other || oldDelegate.profit != profit || oldDelegate.arv != arv || oldDelegate.isDark != isDark;
  }
}


