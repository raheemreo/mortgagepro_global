// lib/features/usa/tools/usa_cash_on_cash_calc.dart

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

class USACashOnCashCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const USACashOnCashCalc({super.key, this.theme = CountryThemes.usa});

  @override
  ConsumerState<USACashOnCashCalc> createState() => _USACashOnCashCalcState();
}

class _USACashOnCashCalcState extends ConsumerState<USACashOnCashCalc> {
  final _cashInController = TextEditingController(text: '95000');
  final _grossRentController = TextEditingController(text: '31200');
  final _vacancyController = TextEditingController(text: '7');
  final _opExController = TextEditingController(text: '9800');
  final _debtServiceController = TextEditingController(text: '14400');
  final _holdController = TextEditingController(text: '5');
  final _appRateController = TextEditingController(text: '4');
  final _purchasePriceController = TextEditingController(text: '380000');

  bool _showResults = false;
  bool _isCalcDirty = true;
  bool _calculating = false;

  @override
  void initState() {
    super.initState();
    final controllers = [
      _cashInController,
      _grossRentController,
      _vacancyController,
      _opExController,
      _debtServiceController,
      _holdController,
      _appRateController,
      _purchasePriceController
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
    _cashInController.dispose();
    _grossRentController.dispose();
    _vacancyController.dispose();
    _opExController.dispose();
    _debtServiceController.dispose();
    _holdController.dispose();
    _appRateController.dispose();
    _purchasePriceController.dispose();
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

  Map<String, dynamic> _computeReturn() {
    final cashIn = _val(_cashInController);
    final grossRent = _val(_grossRentController);
    final vacPct = _val(_vacancyController) / 100;
    final opEx = _val(_opExController);
    final debtService = _val(_debtServiceController);
    final hold = _val(_holdController).toInt().clamp(1, 30);
    final appRate = _val(_appRateController) / 100;
    final purchasePrice = _val(_purchasePriceController);

    final double egi = grossRent * (1 - vacPct);
    final double annualCF = egi - opEx - debtService;
    final double cocVal = cashIn > 0 ? (annualCF / cashIn) * 100 : 0.0;
    final double totalReturnVal = cocVal + appRate * 100;

    final double salePrice = purchasePrice * pow(1 + appRate, hold);
    final double totalCashFlow = annualCF * hold;
    final double equity = salePrice - purchasePrice;
    final double totalReturn5 = totalCashFlow + equity;
    final double eqMultiple = cashIn > 0 ? (cashIn + totalReturn5) / cashIn : 1.0;
    final double totalCashBack = cashIn + totalReturn5;

    // Year by year cash flows (compounded rents and opex)
    final int maxYears = min(hold, 10);
    final List<double> yearCFs = [];
    for (int y = 1; y <= maxYears; y++) {
      yearCFs.add(annualCF * pow(1 + appRate * 0.5, y - 1));
    }

    return {
      'cashIn': cashIn,
      'grossRent': grossRent,
      'vacPct': vacPct,
      'opEx': opEx,
      'debtService': debtService,
      'hold': hold,
      'appRate': appRate,
      'purchasePrice': purchasePrice,
      'annualCF': annualCF,
      'cocVal': cocVal,
      'totalReturnVal': totalReturnVal,
      'eqMultiple': eqMultiple,
      'totalCashBack': totalCashBack,
      'totalReturn5': totalReturn5,
      'yearCFs': yearCFs,
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
    final cashIn = _val(_cashInController);
    if (cashIn <= 0) return;

    final data = _computeReturn();
    final cocVal = data['cocVal'] as double;
    final annualCF = data['annualCF'] as double;
    final hold = data['hold'] as int;

    final label = 'CoC Return (${cocVal.toStringAsFixed(1)}% · $hold yrs)';
    final labelCtrl = TextEditingController(text: label);

    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_cash_on_cash_calc'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save CoC Return Analysis',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: Cash Invested: ${CurrencyFormatter.compact(cashIn, symbol: r'$')} · CoC Return: ${cocVal.toStringAsFixed(1)}%',
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
        calcType: 'Cash-on-Cash Return',
        inputs: {
          'CashIn': cashIn,
          'GrossRent': data['grossRent'] as double,
          'OpEx': data['opEx'] as double,
          'DebtService': data['debtService'] as double,
          'Hold': hold.toDouble(),
        },
        results: {
          'CoC Return': cocVal,
          'Annual Cash Flow': annualCF,
          'Total Return5': data['totalReturn5'] as double,
          'Equity Multiple': data['eqMultiple'] as double,
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

    final data = _computeReturn();
    final cashIn = data['cashIn'] as double;
    final annualCF = data['annualCF'] as double;
    final cocVal = data['cocVal'] as double;
    final totalReturnVal = data['totalReturnVal'] as double;
    final eqMultiple = data['eqMultiple'] as double;
    final totalCashBack = data['totalCashBack'] as double;
    final totalReturn5 = data['totalReturn5'] as double;
    final hold = data['hold'] as int;
    final List<double> yearCFs = data['yearCFs'] as List<double>;

    final String verdictLabel = cocVal >= 15
        ? '🌟 Exceptional — top-tier investor return'
        : cocVal >= 10
            ? '⭐ Great — exceeds most investor benchmarks'
            : cocVal >= 6
                ? '✓ Good — meets 6–8% investor threshold'
                : cocVal >= 4
                    ? '⚠️ Acceptable — below typical investor target'
                    : '✗ Poor — below minimum investment threshold';

    final maxReturnBarScale = max(cocVal, max(totalReturnVal, 10.0));

    // Proportional bars data
    final List<Map<String, dynamic>> barItems = [
      {'label': 'Cash-on-Cash Return', 'val': cocVal, 'color': const Color(0xFF334155)},
      {'label': 'Appreciation Return', 'val': _val(_appRateController), 'color': const Color(0xFFD97706)},
      {'label': 'Total Blended Return', 'val': totalReturnVal, 'color': const Color(0xFF15803D)},
    ];

    // Year by year cash flows projection calculations
    final double maxCF = yearCFs.isNotEmpty
        ? yearCFs.map((v) => v.abs()).reduce((a, b) => a > b ? a : b)
        : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Header — Live VNQ ETF + FRED rates
        LightRateStripBanner(items: [
          RateStripItem(label: 'VNQ ETF\n(RE Market)', provider: vnqPriceProvider, fallback: 92.50, suffix: '', isDollar: true),
          RateStripItem(label: 'Investor 30yr', provider: fredMortgage30Provider, fallback: 7.25),
          RateStripItem(label: 'Fed Funds', provider: fredFedFundsProvider, fallback: 5.33),
          RateStripItem(label: 'Min Target', provider: fredMortgage30Provider, fallback: 8.0, suffix: '%+', isGold: true),
        ]),
        const SizedBox(height: 16),

        Text('INVESTMENT INPUTS', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
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
              _buildTextField('Total Cash Invested (All-In) (\$)', _cashInController),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Gross Annual Rent (\$)', _grossRentController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Vacancy Rate (%)', _vacancyController)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Annual Operating Exp (\$)', _opExController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Annual Debt Service (\$)', _debtServiceController)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Hold Period (years)', _holdController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Appreciation/yr (%)', _appRateController)),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField('Purchase Price (\$)', _purchasePriceController),
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
                            : Text('📊 Calculate Cash-on-Cash', style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.bold)),
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
          // Results Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF334155), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CASH-ON-CASH RETURN (YEAR 1)', style: AppTextStyles.dmSans(size: 10, color: Colors.white60, weight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('${cocVal.toStringAsFixed(1)}%',
                    style: AppTextStyles.playfair(size: 46, color: const Color(0xFFFCD34D), weight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(verdictLabel, style: AppTextStyles.dmSans(size: 11, color: Colors.white70)),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildHeroResult('Annual Cash Flow', annualCF),
                    _buildHeroResult('Monthly Cash Flow', annualCF / 12, suffix: '/mo'),
                    _buildHeroResult('Total Return', totalReturnVal, isPct: true),
                    _buildHeroResult('Equity Mult.', eqMultiple, isMult: true),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Return Analysis Gauge + Component Bars
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
                Text('🎯 CoC Return Gauge', style: AppTextStyles.playfair(size: 12.5, color: theme.getTextColor(context), weight: FontWeight.bold)),
                const SizedBox(height: 12),
                Center(
                  child: SizedBox(
                    height: 100,
                    width: 180,
                    child: CustomPaint(
                      painter: _CocGaugePainter(
                        coc: cocVal,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Component bars
                ...barItems.map((bar) {
                  final double val = bar['val'] as double;
                  final double pct = val / maxReturnBarScale;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(bar['label'] as String, style: AppTextStyles.dmSans(size: 10.5, color: theme.getTextColor(context), weight: FontWeight.bold)),
                            Text('${val.toStringAsFixed(1)}%', style: AppTextStyles.playfair(size: 11, color: bar['color'] as Color, weight: FontWeight.bold)),
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

          // Year-by-Year Cash Flow Projection
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
                Text('📈 Year-by-Year Cash Flow Projections', style: AppTextStyles.playfair(size: 12.5, color: theme.getTextColor(context), weight: FontWeight.bold)),
                const SizedBox(height: 14),
                // Projection bars
                SizedBox(
                  height: 70,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: yearCFs.asMap().entries.map((entry) {
                      final int idx = entry.key;
                      final double val = entry.value;
                      final double hFactor = val.abs() / maxCF;
                      final Color col = val >= 0
                          ? (idx == yearCFs.length - 1 ? const Color(0xFF15803D) : const Color(0xFF6EE7B7))
                          : const Color(0xFFFCA5A5);

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Container(
                                  height: max(4.0, hFactor * 62.0),
                                  decoration: BoxDecoration(color: col, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('Y${idx + 1}', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context), weight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: theme.getBgColor(context), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('Peak Yr CF', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(CurrencyFormatter.format(yearCFs.last, symbol: r'$'), style: AppTextStyles.playfair(size: 14, color: const Color(0xFF334155), weight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        children: [
                          Text('Equity Multiple', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('${eqMultiple.toStringAsFixed(2)}×', style: AppTextStyles.playfair(size: 14, color: const Color(0xFF334155), weight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Investment Summary (Yellow Banner)
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
                Text('💼 $hold-Year Investment Summary', style: AppTextStyles.playfair(size: 12.5, color: const Color(0xFF92400E), weight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Cash Invested', cashIn),
                    _buildSummaryItem('Total Cash Back', totalCashBack),
                    _buildSummaryItem('Net Profit', totalReturn5),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Benchmark Table
        Text('COC RETURN BENCHMARKS', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [
              _buildBenchmarkRow('Poor', 'Below 4%', 'Avoid', const Color(0xFFFEE2E2), const Color(0xFFB91C1C), isActive: _showResults && cocVal < 4.0),
              _buildBenchmarkRow('Acceptable', '4% – 6%', 'Low Bar', const Color(0xFFFEF3C7), const Color(0xFF92400E), isActive: _showResults && cocVal >= 4.0 && cocVal < 6.0),
              _buildBenchmarkRow('Good', '6% – 10%', 'Target', const Color(0xFFD1FAE5), const Color(0xFF15803D), isActive: _showResults && cocVal >= 6.0 && cocVal < 10.0),
              _buildBenchmarkRow('Great', '10% – 15%', 'Excellent', const Color(0xFFCCFBF1), const Color(0xFF0F766E), isActive: _showResults && cocVal >= 10.0 && cocVal < 15.0),
              _buildBenchmarkRow('Exceptional', '15%+', 'Rare Find', const Color(0xFFEDE9FE), const Color(0xFF6D28D9), isActive: _showResults && cocVal >= 15.0),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // What Pros Look For
        Text('WHAT PROS LOOK FOR', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildGuideCard('CoC vs Cap Rate', 'CoC measures YOUR cash return · Cap Rate is property-level regardless of financing'),
        _buildGuideCard('Leverage Boosts CoC', 'Using debt amplifies CoC — but also increases risk if rents fall'),
        _buildGuideCard('Force Appreciation', 'BRRRR strategy: Buy · Rehab · Rent · Refi · Repeat to pull cash out'),
        _buildGuideCard('Rising Rates Impact', '7%+ investor mortgages compress CoC returns vs historical averages'),
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

  Widget _buildHeroResult(String label, double val, {String suffix = '', bool isPct = false, bool isMult = false}) {
    final String display = isPct
        ? '${val.toStringAsFixed(1)}%'
        : isMult
            ? '${val.toStringAsFixed(2)}x'
            : '${CurrencyFormatter.compact(val, symbol: r'$')}$suffix';
    return Column(
      children: [
        Text(display, style: AppTextStyles.playfair(size: 14, color: Colors.white, weight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white70)),
      ],
    );
  }

  Widget _buildSummaryItem(String label, double val) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 8.5, color: const Color(0xFFB45309), weight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text(CurrencyFormatter.compact(val, symbol: r'$'), style: AppTextStyles.playfair(size: 16, color: const Color(0xFF92400E), weight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBenchmarkRow(String name, String range, String badgeLabel, Color badgeBg, Color badgeFg, {required bool isActive}) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: isActive ? theme.primaryColor.withValues(alpha: 0.08) : null,
        borderRadius: isActive ? BorderRadius.circular(8) : null,
        border: isActive ? Border.all(color: theme.primaryColor.withValues(alpha: 0.15)) : Border(bottom: BorderSide(color: theme.getBorderColor(context))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isActive ? '$name (Your Property)' : name,
                style: AppTextStyles.dmSans(size: 11.5, color: theme.getTextColor(context), weight: isActive ? FontWeight.bold : FontWeight.w600),
              ),
              Text(range, style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context))),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
            child: Text(badgeLabel, style: AppTextStyles.dmSans(size: 9.5, color: badgeFg, weight: FontWeight.bold)),
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
            child: const Text('📊', style: TextStyle(fontSize: 17)),
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

class _CocGaugePainter extends CustomPainter {
  final double coc;
  final bool isDark;

  _CocGaugePainter({
    required this.coc,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height - 10);
    final double radius = size.height - 15;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw background track
    final trackPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFEFF6FF)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, pi, pi, false, trackPaint);

    // Draw arcs for different return categories:
    // Let's divide 180 degrees (pi) for the return zones:
    // Zone 1: Poor (<4%) -> 4/20 of 180 degrees = 36 degrees
    // Zone 2: Acceptable (4%-6%) -> 2/20 = 18 degrees
    // Zone 3: Good (6%-10%) -> 4/20 = 36 degrees
    // Zone 4: Exceptional/Great (10%-20%) -> 10/20 = 90 degrees
    final p = Paint()
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double startAngle = pi;
    void drawZone(double pctAngle, Color col) {
      p.color = col;
      canvas.drawArc(rect, startAngle, pi * pctAngle, false, p);
      startAngle += pi * pctAngle;
    }

    drawZone(4 / 20, const Color(0xFFFEE2E2)); // red
    drawZone(2 / 20, const Color(0xFFFEF3C7)); // orange/yellow
    drawZone(4 / 20, const Color(0xFFD1FAE5)); // green
    drawZone(10 / 20, const Color(0xFFCCFBF1)); // teal

    // Needle rotation (0 to 20% -> -90 to +90 degrees)
    final double clampedCoc = coc.clamp(0.0, 20.0);
    final double needleAngle = pi + (clampedCoc / 20.0) * pi;

    final double needleLen = radius - 10;
    final Offset needleTarget = Offset(
      center.dx + needleLen * cos(needleAngle),
      center.dy + needleLen * sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleTarget, needlePaint);

    // Center pin
    final pinPaint = Paint()..color = const Color(0xFF334155);
    canvas.drawCircle(center, 5, pinPaint);

    // Value text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${coc.toStringAsFixed(1)}%',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0B1D3A), fontFamily: 'Georgia'),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - 28));

    // Label text
    final labelPainter = TextPainter(
      text: const TextSpan(
        text: 'Cash-on-Cash',
        style: TextStyle(fontSize: 9, color: Colors.grey, fontFamily: 'DMSans'),
      ),
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout();
    labelPainter.paint(canvas, Offset(center.dx - labelPainter.width / 2, center.dy - 10));
  }

  @override
  bool shouldRepaint(covariant _CocGaugePainter oldDelegate) {
    return oldDelegate.coc != coc || oldDelegate.isDark != isDark;
  }
}


