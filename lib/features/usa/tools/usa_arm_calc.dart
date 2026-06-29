// lib/features/usa/tools/usa_arm_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../shared/widgets/live_rate_banner.dart';
import '../../../providers/usa_rates_provider.dart';

class USAArmCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;
  const USAArmCalc({super.key, this.theme = CountryThemes.usa, this.savedCalc});

  @override
  ConsumerState<USAArmCalc> createState() => _USAArmCalcState();
}

class _USAArmCalcState extends ConsumerState<USAArmCalc> {
  // Input controllers
  final _homePriceController = TextEditingController(text: '450000');
  final _downPctController = TextEditingController(text: '20');
  final _initRateController = TextEditingController(text: '6.05');
  final _adjRateController = TextEditingController(text: '7.50');
  final _initCapController = TextEditingController(text: '2.0');
  final _perCapController = TextEditingController(text: '2.0');
  final _lifeCapController = TextEditingController(text: '5.0');
  final _sofrController = TextEditingController(text: '5.33');

  int _fixedYrs = 5;
  String _armLabel = '5/1';
  bool _showResults = false;
  bool _isCalcDirty = true;
  bool _calculating = false;

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _homePriceController.text = (inputs['HomePrice'] ?? 450000.0).toStringAsFixed(0);
      _downPctController.text = (inputs['DownPct'] ?? 20.0).toStringAsFixed(1);
      _initRateController.text = (inputs['InitRate'] ?? 6.05).toStringAsFixed(2);
      _adjRateController.text = (inputs['AdjRate'] ?? 7.50).toStringAsFixed(2);
      _initCapController.text = (inputs['InitCap'] ?? 2.0).toStringAsFixed(2);
      _perCapController.text = (inputs['PerCap'] ?? 2.0).toStringAsFixed(2);
      _lifeCapController.text = (inputs['LifeCap'] ?? 5.0).toStringAsFixed(2);
      _sofrController.text = (inputs['Sofr'] ?? 5.33).toStringAsFixed(2);
      _fixedYrs = (inputs['FixedYrs'] ?? 5.0).toInt();
      if (_fixedYrs == 5) {
        _armLabel = '5/1';
      } else if (_fixedYrs == 7) {
        _armLabel = '7/1';
      } else if (_fixedYrs == 10) {
        _armLabel = '10/1';
      }
      _showResults = true;
      _isCalcDirty = false;
    }
    final listeners = [
      _homePriceController,
      _downPctController,
      _initRateController,
      _adjRateController,
      _initCapController,
      _perCapController,
      _lifeCapController,
      _sofrController,
    ];
    for (final controller in listeners) {
      controller.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    final listeners = [
      _homePriceController,
      _downPctController,
      _initRateController,
      _adjRateController,
      _initCapController,
      _perCapController,
      _lifeCapController,
      _sofrController,
    ];
    for (final controller in listeners) {
      controller.removeListener(_markDirty);
      controller.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_isCalcDirty) {
      setState(() {
        _isCalcDirty = true;
      });
    }
  }

  double _val(TextEditingController c) => double.tryParse(c.text) ?? 0.0;

  void _selectArm(String label, double rate, int yrs) {
    setState(() {
      _armLabel = label;
      _fixedYrs = yrs;
      _initRateController.text = rate.toStringAsFixed(2);
      _isCalcDirty = true;
    });
  }

  // Unused methods removed to prevent analyzer warnings.

  double _pmtCalc(double loan, double annualRate, int months) {
    final mr = annualRate / 12;
    if (mr == 0) return loan / months;
    return loan * (mr * pow(1 + mr, months)) / (pow(1 + mr, months) - 1);
  }

  void _calculate() async {
    setState(() {
      _calculating = true;
    });
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() {
      _calculating = false;
      _showResults = true;
      _isCalcDirty = false;
    });
  }

  void _saveCalculation() async {
    final price = _val(_homePriceController);
    final downPct = _val(_downPctController) / 100;
    final initRate = _val(_initRateController) / 100;
    final adjRate = _val(_adjRateController) / 100;
    final lifeCap = _val(_lifeCapController);

    final loanAmt = price * (1 - downPct);
    const totalMonths = 360;
    final fixedMonths = _fixedYrs * 12;

    final initPI = _pmtCalc(loanAmt, initRate, totalMonths);

    // Balance after fixed period
    double bal = loanAmt;
    final mr0 = initRate / 12;
    for (int i = 0; i < fixedMonths; i++) {
      final interest = bal * mr0;
      bal -= (initPI - interest);
    }
    final remMonths = totalMonths - fixedMonths;
    final adjPI = _pmtCalc(bal, adjRate, remMonths);
    final maxRateVal = initRate + lifeCap / 100;
    final worstPI = _pmtCalc(bal, maxRateVal, remMonths);

    final labelCtrl = TextEditingController(text: 'ARM Calculator');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_arm_calc/save'),
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
              'Saving: Initial P&I: ${CurrencyFormatter.compact(initPI, symbol: r'$')}/mo · Adj. Est: ${CurrencyFormatter.compact(adjPI, symbol: r'$')}/mo',
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
                hintText: 'Label (e.g. My ARM Calc)',
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
          : 'ARM Calculator';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'ARM Calculator',
        inputs: {
          'HomePrice': price,
          'DownPct': _val(_downPctController),
          'InitRate': _val(_initRateController),
          'AdjRate': _val(_adjRateController),
          'InitCap': _val(_initCapController),
          'PerCap': _val(_perCapController),
          'LifeCap': lifeCap,
          'Sofr': _val(_sofrController),
          'FixedYrs': _fixedYrs.toDouble(),
          'ArmLabel': _fixedYrs.toDouble(),
        },
        results: {
          'Init P&I': initPI,
          'Adj. Est. P&I': adjPI,
          'Worst P&I': worstPI,
          'Loan Amount': loanAmt,
          'Max Cap Rate': maxRateVal * 100,
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

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final cardColor = theme.getCardColor(context);
    final textColor = theme.getTextColor(context);
    final mutedColor = theme.getMutedColor(context);
    final borderColor = theme.getBorderColor(context);

    // Rate stats now provided by live LightRateStripBanner

    // Compute active calculation
    final price = _val(_homePriceController);
    final downPct = _val(_downPctController) / 100;
    final initRate = _val(_initRateController) / 100;
    final adjRate = _val(_adjRateController) / 100;
    final lifeCap = _val(_lifeCapController);

    final loanAmt = price * (1 - downPct);
    const totalMonths = 360;
    final fixedMonths = _fixedYrs * 12;

    final initPI = _pmtCalc(loanAmt, initRate, totalMonths);

    double bal = loanAmt;
    final mr0 = initRate / 12;
    for (int i = 0; i < fixedMonths; i++) {
      final interest = bal * mr0;
      bal -= (initPI - interest);
    }
    final remMonths = totalMonths - fixedMonths;
    final adjPI = _pmtCalc(bal, adjRate, remMonths);
    final maxRateVal = initRate + lifeCap / 100;
    final worstPI = _pmtCalc(bal, maxRateVal, remMonths);

    // Comparative calculations
    final fixedCompPmt = _pmtCalc(loanAmt, 0.0682, totalMonths);
    final bestRate = max(0.001, initRate - 0.01);
    final bestPI = _pmtCalc(bal, bestRate, remMonths);

    final savingsVal = fixedCompPmt - initPI;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip header — Live FRED/SOFR data
        LightRateStripBanner(
          items: [
            RateStripItem(label: '5/1 ARM\n(SOFR)', provider: fredSofrProvider, fallback: 5.33),
            RateStripItem(label: '30-Yr Fixed', provider: fredMortgage30Provider, fallback: 6.82),
            RateStripItem(label: '15-Yr Fixed', provider: fredMortgage15Provider, fallback: 6.11),
            RateStripItem(label: 'Fed Funds', provider: fredFedFundsProvider, fallback: 5.33, isGold: true),
          ],
        ),

        // Select ARM Type Grid
        Text(
          'Select ARM Type',
          style: AppTextStyles.playfair(
              size: 13, weight: FontWeight.w700, color: textColor),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _ArmSelectorButton(
              label: '5/1 ARM',
              sub: 'Fixed 5 yrs',
              isActive: _armLabel == '5/1',
              onTap: () => _selectArm('5/1', 6.05, 5),
              theme: theme,
            ),
            const SizedBox(width: 8),
            _ArmSelectorButton(
              label: '7/1 ARM',
              sub: 'Fixed 7 yrs',
              isActive: _armLabel == '7/1',
              onTap: () => _selectArm('7/1', 6.28, 7),
              theme: theme,
            ),
            const SizedBox(width: 8),
            _ArmSelectorButton(
              label: '10/1 ARM',
              sub: 'Fixed 10 yrs',
              isActive: _armLabel == '10/1',
              onTap: () => _selectArm('10/1', 6.55, 10),
              theme: theme,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Inputs Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            _buildInputCard('Home Price (\$)', _homePriceController,
                keyboardType: TextInputType.number),
            _buildInputCard('Down Payment (%)', _downPctController,
                keyboardType: TextInputType.number),
            _buildInputCard('Initial Rate (%)', _initRateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                hint: 'Fixed during initial term'),
            _buildInputCard('Expected Adj. Rate (%)', _adjRateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                hint: 'After fixed period ends'),
            _buildInputCard('Initial Cap', _initCapController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                hint: 'Max 1st adjustment'),
            _buildInputCard('Periodic Cap', _perCapController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                hint: 'Max per adjustment'),
            _buildInputCard('Lifetime Cap', _lifeCapController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                hint: 'Max over loan life'),
            _buildInputCard('Index (SOFR) (%)', _sofrController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                hint: 'Current SOFR Jun 2025'),
          ],
        ),
        const SizedBox(height: 16),

        // Calculate & Save Row
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.accentColor, // Teal-ish / Gold-ish accent
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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
                        '🔁 Calculate ARM Payments',
                        style: AppTextStyles.playfair(
                            size: 13, weight: FontWeight.w800),
                      ),
              ),
            ),
            if (_showResults && !_isCalcDirty) ...[
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saveCalculation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cardColor,
                  foregroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: primaryColor, width: 2),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '🔖 Save',
                  style: AppTextStyles.dmSans(
                      size: 12, weight: FontWeight.w700, color: primaryColor),
                ),
              ),
            ]
          ],
        ),
        const SizedBox(height: 20),

        if (_showResults && !_isCalcDirty) ...[
          // Results Panel
          Text(
            'Payment Summary',
            style: AppTextStyles.playfair(
                size: 13, weight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 8),

          // Hero Result Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.primaryColor, theme.accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INITIAL MONTHLY PAYMENT (FIXED PERIOD)',
                  style: AppTextStyles.dmSans(
                      size: 8,
                      weight: FontWeight.w700,
                      color: Colors.white70,
                      letterSpacing: 0.6),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      CurrencyFormatter.format(initPI, symbol: r'$'),
                      style: AppTextStyles.playfair(
                          size: 32, weight: FontWeight.w800, color: Colors.white),
                    ),
                    Text(
                      ' /mo',
                      style: AppTextStyles.dmSans(
                          size: 14, color: Colors.white60),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Loan: ${CurrencyFormatter.compact(loanAmt, symbol: r'$')} · $_fixedYrs-yr fixed @ ${(_val(_initRateController)).toStringAsFixed(2)}% · Adj. est: ${CurrencyFormatter.format(adjPI, symbol: r'$')}/mo',
                  style: AppTextStyles.dmSans(
                      size: 9.5, color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Breakdown Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _buildBreakdownCard(
                  '📌', 'Initial P&I', CurrencyFormatter.format(initPI, symbol: r'$'), 'Fixed period payment'),
              _buildBreakdownCard(
                  '🔄', 'Adj. Est. P&I', CurrencyFormatter.format(adjPI, symbol: r'$'), 'After fixed period'),
              _buildBreakdownCard(
                  '⬆️', 'Max Cap Rate', '${maxRateVal.toStringAsFixed(2)}%', 'Initial + lifetime cap'),
              _buildBreakdownCard(
                  '🚨', 'Worst Case P&I', CurrencyFormatter.format(worstPI, symbol: r'$'), 'At max lifetime cap'),
              _buildBreakdownCard(
                  '💵', '30-Yr Fixed Pmt', CurrencyFormatter.format(fixedCompPmt, symbol: r'$'), 'At 6.82% (comparison)'),
              _buildBreakdownCard(
                  '💰', 'Initial Period Savings',
                  '${savingsVal >= 0 ? '+' : '-'}${CurrencyFormatter.format(savingsVal.abs(), symbol: r'$')}/mo',
                  'vs 30-yr fixed'),
            ],
          ),
          const SizedBox(height: 20),

          // Payment Scenarios Bar Chart
          Text(
            'Payment Scenarios Chart',
            style: AppTextStyles.playfair(
                size: 13, weight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📊 Monthly Payment by Scenario',
                  style: AppTextStyles.playfair(
                      size: 12, weight: FontWeight.w700, color: textColor),
                ),
                const SizedBox(height: 12),
                _buildBarRow('Fixed (Init)', initPI, max(1.0, worstPI), const Color(0xFF0F766E)),
                const SizedBox(height: 8),
                _buildBarRow('Adj. Rate', adjPI, max(1.0, worstPI), initPI > adjPI ? const Color(0xFF15803D) : const Color(0xFFD97706)),
                const SizedBox(height: 8),
                _buildBarRow('30-Yr Comp', fixedCompPmt, max(1.0, worstPI), const Color(0xFF1B3F72)),
                const SizedBox(height: 8),
                _buildBarRow('Worst Case', worstPI, max(1.0, worstPI), const Color(0xFFB91C1C)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Rate Timeline Chart
          Text(
            'Rate Timeline',
            style: AppTextStyles.playfair(
                size: 13, weight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📈 Rate Over Loan Life',
                  style: AppTextStyles.playfair(
                      size: 12, weight: FontWeight.w700, color: textColor),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _TimelinePainter(
                      initR: _val(_initRateController),
                      adjR: _val(_adjRateController),
                      maxR: maxRateVal * 100,
                      fixedYrs: _fixedYrs,
                      isDark: isDark,
                      textColor: textColor,
                      mutedColor: mutedColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildLegendItem(const Color(0xFF0F766E), 'Fixed Period'),
                    const SizedBox(width: 12),
                    _buildLegendItem(const Color(0xFFD97706), 'Adj. Period'),
                    const SizedBox(width: 12),
                    _buildLegendItem(const Color(0xFFB91C1C), 'Worst Case', dashed: true),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Table scenarios
          Text(
            'Rate Scenarios',
            style: AppTextStyles.playfair(
                size: 13, weight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📊 ARM Payment Scenarios After Fixed Period',
                  style: AppTextStyles.playfair(
                      size: 12, weight: FontWeight.w700, color: textColor),
                ),
                const SizedBox(height: 10),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2.2),
                    1: FlexColumnWidth(1.2),
                    2: FlexColumnWidth(1.5),
                    3: FlexColumnWidth(1.3),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: borderColor, width: 2)),
                      ),
                      children: [
                        _buildTableHeaderCell('Scenario'),
                        _buildTableHeaderCell('Rate'),
                        _buildTableHeaderCell('Monthly P&I'),
                        _buildTableHeaderCell('vs Fixed'),
                      ],
                    ),
                    _buildTableDataRow('Best Case', '${bestRate * 100.0}%', CurrencyFormatter.format(bestPI, symbol: r'$'),
                        _calcVsFixedDiff(bestPI, fixedCompPmt), const Color(0xFF15803D)),
                    _buildTableDataRow('Base Case', '${adjRate * 100.0}%', CurrencyFormatter.format(adjPI, symbol: r'$'),
                        _calcVsFixedDiff(adjPI, fixedCompPmt), const Color(0xFFD97706)),
                    _buildTableDataRow('Worst Case (Cap)', '${maxRateVal * 100.0}%', CurrencyFormatter.format(worstPI, symbol: r'$'),
                        _calcVsFixedDiff(worstPI, fixedCompPmt), const Color(0xFFB91C1C)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Explanations Card
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF063E2B), const Color(0xFF042B1D)]
                    : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isDark ? const Color(0xFF047857) : const Color(0xFF6EE7B7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🛡️ $_fixedYrs/2/5 Cap Structure (Most Common)',
                  style: AppTextStyles.playfair(
                      size: 13, weight: FontWeight.w800, color: isDark ? const Color(0xFFD1FAE5) : const Color(0xFF064E3B)),
                ),
                const SizedBox(height: 8),
                _buildExplainRow('Initial Cap (${_val(_initCapController).toStringAsFixed(1)})', 'Max ${_val(_initCapController)}% increase at 1st adjustment', isDark),
                _buildExplainRow('Periodic Cap (${_val(_perCapController).toStringAsFixed(1)})', 'Max ${_val(_perCapController)}% increase each subsequent adj.', isDark),
                _buildExplainRow('Lifetime Cap (${lifeCap.toStringAsFixed(1)})', 'Max $lifeCap% above initial rate, ever', isDark),
                _buildExplainRow('Index Used', 'SOFR (replaced LIBOR in 2023)', isDark),
                _buildExplainRow('Margin', 'Typically 2.25–2.75% added to index', isDark),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Resources list
        Text(
          'ARM Resources',
          style: AppTextStyles.playfair(
              size: 13, weight: FontWeight.w700, color: textColor),
        ),
        const SizedBox(height: 8),
        _buildInfoCard('📋', 'ARM vs Fixed Breakeven', 'Calculate how long to stay in home to benefit from ARM', textColor, mutedColor, borderColor, cardColor, () {
          context.push('/usa/arm-vs-fixed-breakeven');
        }),
        _buildInfoCard('📈', 'SOFR Rate History', 'NY Fed SOFR data · Current: 3.63% (Jun 2026)', textColor, mutedColor, borderColor, cardColor, () {
          context.push('/usa/sofr-history');
        }),
        _buildInfoCard('🔄', 'Refinancing from ARM', 'When to refi to fixed · Break-even analysis', textColor, mutedColor, borderColor, cardColor, () {
          context.push('/usa/refinance-arm');
        }),
        _buildInfoCard('⚠️', 'ARM Risk Factors', 'Payment shock · Negative amortization · Rate volatility', textColor, mutedColor, borderColor, cardColor, () {
          context.push('/usa/arm-risk-factors');
        }),
      ],
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(
        text,
        style: AppTextStyles.dmSans(
            size: 9.5, weight: FontWeight.w800, color: widget.theme.getMutedColor(context)),
      ),
    );
  }

  TableRow _buildTableDataRow(
      String scenario, String rate, String monthly, String vsFixed, Color color) {
    final textColor = widget.theme.getTextColor(context);
    final borderColor = widget.theme.getBorderColor(context);
    return TableRow(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(scenario,
              style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: textColor)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(rate,
              style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: color)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(monthly,
              style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: color)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(vsFixed,
              style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: color)),
        ),
      ],
    );
  }

  String _calcVsFixedDiff(double pmt, double fixedPmt) {
    final diff = pmt - fixedPmt;
    if (diff == 0) return '\$0';
    final sign = diff > 0 ? '+' : '-';
    return '$sign${CurrencyFormatter.format(diff.abs(), symbol: r'$')}';
  }

  Widget _buildExplainRow(String key, String val, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key,
              style: AppTextStyles.dmSans(
                  size: 10.5,
                  weight: FontWeight.w700,
                  color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46))),
          Text(val,
              style: AppTextStyles.dmSans(
                  size: 10,
                  weight: FontWeight.w600,
                  color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857))),
        ],
      ),
    );
  }

  Widget _buildBarRow(String label, double val, double maxVal, Color color) {
    final widthPct = (val / maxVal).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
                size: 9.5, weight: FontWeight.w700, color: widget.theme.getMutedColor(context)),
          ),
        ),
        Expanded(
          child: Container(
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: widthPct,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  CurrencyFormatter.format(val, symbol: r'$'),
                  style: AppTextStyles.dmSans(
                      size: 9, weight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text, {bool dashed = false}) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 3,
          decoration: BoxDecoration(
            color: dashed ? null : color,
            borderRadius: BorderRadius.circular(2),
            border: dashed ? Border.all(color: color, style: BorderStyle.solid) : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(text, style: AppTextStyles.dmSans(size: 9, color: widget.theme.getMutedColor(context))),
      ],
    );
  }

  Widget _buildBreakdownCard(String icon, String label, String value, String sub) {
    final cardColor = widget.theme.getCardColor(context);
    final borderColor = widget.theme.getBorderColor(context);
    final textColor = widget.theme.getTextColor(context);
    final mutedColor = widget.theme.getMutedColor(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(label.toUpperCase(),
              style: AppTextStyles.dmSans(
                  size: 8, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.4)),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.playfair(
                  size: 14.5, weight: FontWeight.w800, color: textColor)),
          const Spacer(),
          Text(sub, style: AppTextStyles.dmSans(size: 8, color: mutedColor)),
        ],
      ),
    );
  }

  Widget _buildInputCard(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, String? hint}) {
    final cardColor = widget.theme.getCardColor(context);
    final borderColor = widget.theme.getBorderColor(context);
    final textColor = widget.theme.getTextColor(context);
    final mutedColor = widget.theme.getMutedColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.dmSans(
                size: 8, weight: FontWeight.w800, color: mutedColor, letterSpacing: 0.5),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: AppTextStyles.playfair(
                  size: 15, weight: FontWeight.w800, color: textColor),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (hint != null)
            Text(hint,
                style: AppTextStyles.dmSans(size: 8, color: mutedColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String icon, String title, String subtitle, Color textColor,
      Color mutedColor, Color borderColor, Color cardColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
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
              child: Text(icon, style: const TextStyle(fontSize: 17)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.playfair(
                        size: 12, weight: FontWeight.w800, color: textColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.dmSans(size: 9, color: mutedColor),
                  ),
                ],
              ),
            ),
            Text('›', style: TextStyle(fontSize: 16, color: mutedColor)),
          ],
        ),
      ),
    );
  }
}

class _ArmSelectorButton extends StatelessWidget {
  final String label;
  final String sub;
  final bool isActive;
  final VoidCallback onTap;
  final CountryTheme theme;

  const _ArmSelectorButton({
    required this.label,
    required this.sub,
    required this.isActive,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = theme.accentColor;
    final inactiveBg = theme.getCardColor(context);
    final activeBorder = theme.accentColor;
    final inactiveBorder = theme.getBorderColor(context);
    const activeText = Colors.white;
    final inactiveText = theme.getTextColor(context);
    const activeSubText = Colors.white70;
    final inactiveSubText = theme.getMutedColor(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isActive ? activeBorder : inactiveBorder, width: 2),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: AppTextStyles.playfair(
                  size: 12,
                  weight: FontWeight.w800,
                  color: isActive ? activeText : inactiveText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: AppTextStyles.dmSans(
                  size: 8,
                  color: isActive ? activeSubText : inactiveSubText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Painter for Rate Timeline Chart
class _TimelinePainter extends CustomPainter {
  final double initR;
  final double adjR;
  final double maxR;
  final int fixedYrs;
  final bool isDark;
  final Color textColor;
  final Color mutedColor;

  const _TimelinePainter({
    required this.initR,
    required this.adjR,
    required this.maxR,
    required this.fixedYrs,
    required this.isDark,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 32.0;
    const rightPad = 10.0;
    const topPad = 15.0;
    const botPad = 20.0;

    final plotW = size.width - leftPad - rightPad;
    final plotH = size.height - topPad - botPad;

    final rates = [initR, adjR, maxR];
    final minR = max(0.0, rates.reduce(min) - 1.0);
    final maxRv = rates.reduce(max) + 1.0;

    double toX(double yr) => (yr / 30.0) * plotW + leftPad;
    double toY(double r) => (1.0 - (r - minR) / (maxRv - minR)) * plotH + topPad;

    final axisPaint = Paint()
      ..color = textColor.withValues(alpha: 0.12)
      ..strokeWidth = 1.0;

    // Draw Axes
    canvas.drawLine(const Offset(leftPad, topPad), Offset(leftPad, size.height - botPad), axisPaint);
    canvas.drawLine(Offset(leftPad, size.height - botPad), Offset(size.width - rightPad, size.height - botPad), axisPaint);

    // Draw Horizontal Gridlines & Y-Axis Labels
    final yLabels = [initR, adjR, maxR];
    yLabels.sort();
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final r in yLabels) {
      final y = toY(r);
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(size.width - rightPad, y),
        Paint()
          ..color = textColor.withValues(alpha: 0.05)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke,
      );

      // Label text
      textPainter.text = TextSpan(
        text: '${r.toStringAsFixed(1)}%',
        style: AppTextStyles.dmSans(size: 7.5, color: mutedColor),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(leftPad - textPainter.width - 4, y - textPainter.height / 2));
    }

    // Draw Year labels on X axis
    final years = [0, 10, 20, 30];
    for (final yr in years) {
      final x = toX(yr.toDouble());
      textPainter.text = TextSpan(
        text: 'Yr$yr',
        style: AppTextStyles.dmSans(size: 7.5, color: mutedColor),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(x - textPainter.width / 2, size.height - botPad + 4));
    }

    // Draw fixed yrs label specifically
    final xFix = toX(fixedYrs.toDouble());
    textPainter.text = TextSpan(
      text: 'Yr $fixedYrs',
      style: AppTextStyles.dmSans(size: 7.5, color: const Color(0xFF0F766E), weight: FontWeight.w700),
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset(xFix - textPainter.width / 2, size.height - botPad + 12));

    // Paint for curves
    final fixedLinePaint = Paint()
      ..color = const Color(0xFF0F766E)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final adjLinePaint = Paint()
      ..color = const Color(0xFFD97706)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Fixed period line
    final pStart = Offset(toX(0), toY(initR));
    final pFix = Offset(toX(fixedYrs.toDouble()), toY(initR));
    canvas.drawLine(pStart, pFix, fixedLinePaint);

    // Transition vertical dotted line to adjusted rate
    final pAdj = Offset(toX(fixedYrs.toDouble()), toY(adjR));
    _drawDottedLine(canvas, pFix, pAdj, const Color(0xFFD97706), 1.5);

    // Adjusted period line to Year 30
    final pEndAdj = Offset(toX(30), toY(adjR));
    canvas.drawLine(pAdj, pEndAdj, adjLinePaint);

    // Worst case curve from transition (pFix/pAdj) to max cap rate (Year 30)
    final pWorstEnd = Offset(toX(30), toY(maxR));
    _drawDottedLine(canvas, pAdj, pWorstEnd, const Color(0xFFB91C1C), 1.5);

    // Transition marker dot at Year Fixed
    canvas.drawCircle(pFix, 4.0, Paint()..color = const Color(0xFF0F766E));
    canvas.drawCircle(pFix, 2.0, Paint()..color = Colors.white);
  }

  void _drawDottedLine(Canvas canvas, Offset p1, Offset p2, Color color, double strokeWidth) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 3.0;

    final totalDistance = (p2 - p1).distance;
    final direction = (p2 - p1) / totalDistance;
    double currentDistance = 0.0;

    while (currentDistance < totalDistance) {
      final start = p1 + direction * currentDistance;
      double nextDistance = currentDistance + dashWidth;
      if (nextDistance > totalDistance) {
        nextDistance = totalDistance;
      }
      final end = p1 + direction * nextDistance;
      canvas.drawLine(start, end, paint);
      currentDistance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) {
    return oldDelegate.initR != initR ||
        oldDelegate.adjR != adjR ||
        oldDelegate.maxR != maxR ||
        oldDelegate.fixedYrs != fixedYrs ||
        oldDelegate.isDark != isDark;
  }
}

