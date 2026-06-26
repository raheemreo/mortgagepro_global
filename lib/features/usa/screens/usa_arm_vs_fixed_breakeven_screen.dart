// lib/features/usa/screens/usa_arm_vs_fixed_breakeven_screen.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAArmVsFixedBreakevenScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAArmVsFixedBreakevenScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAArmVsFixedBreakevenScreen> createState() => _USAArmVsFixedBreakevenScreenState();
}

class _USAArmVsFixedBreakevenScreenState extends ConsumerState<USAArmVsFixedBreakevenScreen> {
  static const _theme = CountryThemes.usa;

  // Controllers
  final _loanAmtController = TextEditingController(text: '360000');
  final _armRateController = TextEditingController(text: '5.81');
  int _armYrs = 5;
  final _fixedRateController = TextEditingController(text: '6.47');
  final _adjRateController = TextEditingController(text: '7.00');
  final _yearsInHomeController = TextEditingController(text: '7');

  // Outputs
  bool _calculated = false;
  double _armPI = 0.0;
  double _fixedPI = 0.0;
  double _monthlySave = 0.0;
  double _armAdjPI = 0.0;
  double _breakevenYears = 0.0;
  String _breakevenSub = '';
  double _netAtStay = 0.0;
  String _atYourStay = 'ARM Wins';

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _loanAmtController.text = (inputs['loanAmt'] ?? 360000.0).toStringAsFixed(0);
      _armRateController.text = (inputs['armRate'] ?? 5.81).toStringAsFixed(2);
      _armYrs = (inputs['armYrs'] ?? 5.0).toInt();
      _fixedRateController.text = (inputs['fixedRate'] ?? 6.47).toStringAsFixed(2);
      _adjRateController.text = (inputs['adjRate'] ?? 7.00).toStringAsFixed(2);
      _yearsInHomeController.text = (inputs['yearsInHome'] ?? 7.0).toStringAsFixed(0);
      _calculate();
    } else {
      _calculate();
    }
  }

  @override
  void dispose() {
    _loanAmtController.dispose();
    _armRateController.dispose();
    _fixedRateController.dispose();
    _adjRateController.dispose();
    _yearsInHomeController.dispose();
    super.dispose();
  }

  double _pmtCalc(double loan, double annualRatePercent, int months) {
    final mr = (annualRatePercent / 100) / 12;
    if (mr == 0 || mr.isNaN) return loan / months;
    return loan * (mr * pow(1 + mr, months)) / (pow(1 + mr, months) - 1);
  }

  // cumulative cost calc, year by year (P&I paid, simplified, ignoring principal differences for cash-flow comparison)
  double _cumulativeCost(double years, double armPI, double armAdjPI, int fixedMonths) {
    const totalMonths = 360;
    final months = min(years * 12, totalMonths.toDouble()).toInt();
    if (months <= fixedMonths) {
      return armPI * months;
    } else {
      return (armPI * fixedMonths) + (armAdjPI * (months - fixedMonths));
    }
  }

  double _fixedCumulativeCost(double years, double fixedPI) {
    const totalMonths = 360;
    final months = min(years * 12, totalMonths.toDouble()).toInt();
    return fixedPI * months;
  }

  void _calculate() {
    final loanAmt = double.tryParse(_loanAmtController.text) ?? 0.0;
    final armRate = double.tryParse(_armRateController.text) ?? 0.0;
    final fixedRate = double.tryParse(_fixedRateController.text) ?? 0.0;
    final adjRate = double.tryParse(_adjRateController.text) ?? 0.0;
    final yearsInHome = double.tryParse(_yearsInHomeController.text) ?? 1.0;

    const totalMonths = 360;
    final fixedMonths = _armYrs * 12;

    final armPI = _pmtCalc(loanAmt, armRate, totalMonths);
    final fixedPI = _pmtCalc(loanAmt, fixedRate, totalMonths);

    // Remaining balance after fixed period
    double bal = loanAmt;
    final mr0 = (armRate / 100) / 12;
    for (int i = 0; i < fixedMonths; i++) {
      final interest = bal * mr0;
      bal -= (armPI - interest);
    }
    final remMonths = totalMonths - fixedMonths;
    final armAdjPI = _pmtCalc(bal, adjRate, remMonths);

    // Scan for breakeven year
    double breakevenYears = 30.0;
    for (double y = 0.5; y <= 30.0; y += 0.1) {
      final armC = _cumulativeCost(y, armPI, armAdjPI, fixedMonths);
      final fixC = _fixedCumulativeCost(y, fixedPI);
      if (armC >= fixC) {
        breakevenYears = y;
        break;
      }
    }

    final netAtStay = _fixedCumulativeCost(yearsInHome, fixedPI) -
        _cumulativeCost(yearsInHome, armPI, armAdjPI, fixedMonths);

    setState(() {
      _armPI = armPI;
      _fixedPI = fixedPI;
      _monthlySave = fixedPI - armPI;
      _armAdjPI = armAdjPI;
      _breakevenYears = breakevenYears;
      _breakevenSub = breakevenYears >= 29.5
          ? 'ARM stays cheaper for the entire loan term in this scenario'
          : 'Staying past year ${breakevenYears.toStringAsFixed(1)}, the fixed loan becomes cheaper overall';
      _netAtStay = netAtStay;
      _atYourStay = netAtStay >= 0 ? 'ARM Wins' : 'Fixed Wins';
      _calculated = true;
    });
  }

  void _saveCalc() {
    if (!_calculated) return;

    final loanAmt = double.tryParse(_loanAmtController.text) ?? 0.0;
    final armRate = double.tryParse(_armRateController.text) ?? 0.0;
    final fixedRate = double.tryParse(_fixedRateController.text) ?? 0.0;
    final adjRate = double.tryParse(_adjRateController.text) ?? 0.0;
    final yearsInHome = double.tryParse(_yearsInHomeController.text) ?? 1.0;

    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'ARM vs Fixed Breakeven',
      label: '$_armYrs/1 ARM vs Fixed: \$${CurrencyFormatter.compact(loanAmt, symbol: "")} · BE: ${_breakevenYears.toStringAsFixed(1)}y',
      currencyCode: 'USD',
      inputs: {
        'loanAmt': loanAmt,
        'armRate': armRate,
        'armYrs': _armYrs.toDouble(),
        'fixedRate': fixedRate,
        'adjRate': adjRate,
        'yearsInHome': yearsInHome,
      },
      results: {
        'BreakevenYears': _breakevenYears,
        'MonthlySave': _monthlySave,
        'NetAtStay': _netAtStay,
      },
    );

    ref.read(savedProvider.notifier).save(calc);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ ARM vs Fixed breakeven scenario saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = _theme.getCardColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);
    final borderCol = _theme.getBorderColor(context);
    final bgCol = _theme.getBgColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final yearsInHome = double.tryParse(_yearsInHomeController.text) ?? 7.0;
    final fixedMonths = _armYrs * 12;

    // bar chart horizons
    final horizons = [3.0, 5.0, yearsInHome, 10.0, 15.0];
    final labels = ['3 years', '5 years', 'Your stay', '10 years', '15 years'];
    final diffs = horizons.map((h) =>
        _fixedCumulativeCost(h, _fixedPI) -
        _cumulativeCost(h, _armPI, _armAdjPI, fixedMonths)).toList();
    final maxAbs = diffs.map((d) => d.abs()).reduce(max);
    final maxScale = max(maxAbs, 1000.0);

    return Scaffold(
      backgroundColor: bgCol,
      body: CustomScrollView(
        slivers: [
          // App Bar
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
                    colors: [Color(0xFF0B1D3A), Color(0xFF0F766E), Color(0xFF0D9488)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📋', style: TextStyle(fontSize: 26)),
                      const SizedBox(height: 2),
                      Text('ARM vs Fixed Breakeven',
                          style: AppTextStyles.playfair(
                              size: 17, color: Colors.white, weight: FontWeight.w800)),
                      Text('How long to stay to benefit from an ARM',
                          style: AppTextStyles.dmSans(size: 9.5, color: Colors.white60)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Summary Strip
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
                  Expanded(child: _buildStripItem('$_armYrs/1 ARM', '${double.tryParse(_armRateController.text) ?? 5.81}%', 'Avg Today', isDark, isGold: true)),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(child: _buildStripItem('30-Yr Fixed', '${double.tryParse(_fixedRateController.text) ?? 6.47}%', 'Freddie Mac', isDark)),
                  Container(width: 1, height: 26, color: Colors.white24),
                  Expanded(
                    child: _buildStripItem(
                      'Rate Gap',
                      '${((double.tryParse(_fixedRateController.text) ?? 6.47) - (double.tryParse(_armRateController.text) ?? 5.81)).toStringAsFixed(2)}%',
                      'ARM Discount',
                      isDark,
                    ),
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
                // Explanatory Note Strip
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.08),
                    border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📌 ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: Text(
                          'The breakeven point is when the cumulative savings from an ARM\'s lower initial payments are wiped out by higher payments after the rate adjusts. Stay shorter than that, and the ARM wins.',
                          style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF92400E), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

                _buildSectionHeader('Compare Your Two Loans'),

                // Input Card
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
                      _buildInputField('Loan Amount (\$)', _loanAmtController),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField('ARM Initial Rate (%)', _armRateController),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildDropdownField<int>(
                              label: 'ARM Fixed Period',
                              value: _armYrs,
                              items: const [
                                DropdownMenuItem(value: 5, child: Text('5 Years (5/1)')),
                                DropdownMenuItem(value: 7, child: Text('7 Years (7/1)')),
                                DropdownMenuItem(value: 10, child: Text('10 Years (10/1)')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _armYrs = val);
                                  _calculate();
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
                            child: _buildInputField('Fixed Loan Rate (%)', _fixedRateController),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInputField('Expected ARM Adj. Rate (%)', _adjRateController),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInputField('Planned Years in Home', _yearsInHomeController, hint: 'Check the cumulative result over different stays'),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Result Hero Card
                if (_calculated) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0B1D3A), Color(0xFF0F766E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('BREAKEVEN POINT (ARM STOPS WINNING)',
                                style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54, weight: FontWeight.w700, letterSpacing: 0.8)),
                            const SizedBox(height: 6),
                            Text(
                              '${_breakevenYears.toStringAsFixed(1)} yrs',
                              style: AppTextStyles.playfair(size: 32, color: Colors.white, weight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text('from closing',
                                style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFFCD34D), weight: FontWeight.w700)),
                            const SizedBox(height: 12),
                            Text(_breakevenSub,
                                style: AppTextStyles.dmSans(size: 9.5, color: Colors.white70)),
                          ],
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _saveCalc,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                border: Border.all(color: Colors.white24),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.bookmark_border, color: Colors.white, size: 12),
                                  const SizedBox(width: 4),
                                  Text('Save', style: AppTextStyles.dmSans(size: 9.5, color: Colors.white, weight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                _buildSectionHeader('Key Scenario Stats'),

                // Breakdown Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.4,
                  children: [
                    _buildBreakdownCard('💵', 'ARM Initial P&I', '\$${_armPI.round()}', 'During fixed period', textCol, mutedCol),
                    _buildBreakdownCard('🏛️', 'Fixed-Rate P&I', '\$${_fixedPI.round()}', 'Same every month', textCol, mutedCol),
                    _buildBreakdownCard('💰', 'Monthly Savings (ARM)', '\$${_monthlySave.round()}', 'During fixed years', textCol, mutedCol),
                    _buildBreakdownCard('📈', 'ARM P&I After Adj.', '\$${_armAdjPI.round()}', 'Estimated reset payment', textCol, mutedCol),
                    _buildBreakdownCard('🏁', 'At Your Planned Stay', _atYourStay, 'After $yearsInHome years in home', _netAtStay >= 0 ? const Color(0xFF15803D) : const Color(0xFFB91C1C), mutedCol),
                    _buildBreakdownCard('💸', 'Net \$ at Your Stay', '${_netAtStay >= 0 ? '+\$' : '-\$'}${_netAtStay.abs().round()}', 'Cumulative ARM advantage', _netAtStay >= 0 ? const Color(0xFF15803D) : const Color(0xFFB91C1C), mutedCol),
                  ],
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Cumulative Cost Comparison (15-Yr View)'),

                // Line Chart Card
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
                      Text('📈 Cumulative Cost over 15 Years',
                          style: AppTextStyles.playfair(size: 11.5, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 130,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: BreakevenLineChartPainter(
                            armPI: _armPI,
                            fixedPI: _fixedPI,
                            armAdjPI: _armAdjPI,
                            fixedMonths: fixedMonths,
                            breakeven: _breakevenYears,
                            isDark: isDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Year 0', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                          Text('Year 5', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                          Text('Year 10', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                          Text('Year 15', style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _buildLegendDot(const Color(0xFF0F766E), 'ARM Cumulative Cost', mutedCol),
                          const SizedBox(width: 14),
                          _buildLegendDot(const Color(0xFF1B3F72), 'Fixed Cumulative Cost', mutedCol),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn('Breakeven', '${_breakevenYears.toStringAsFixed(1)} yrs', textCol, mutedCol),
                          _buildStatColumn('Savings @ 5 Yrs', '\$${(_fixedCumulativeCost(5, _fixedPI) - _cumulativeCost(5, _armPI, _armAdjPI, fixedMonths)).round()}', textCol, mutedCol),
                          _buildStatColumn('Savings @ 10 Yrs', '\$${(_fixedCumulativeCost(10, _fixedPI) - _cumulativeCost(10, _armPI, _armAdjPI, fixedMonths)).round()}', textCol, mutedCol),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Interest Savings by Holding Period'),

                // Bar Chart Card
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
                      Text('📊 Cumulative Cost Advantage by Year Held',
                          style: AppTextStyles.playfair(size: 11.5, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      for (int i = 0; i < horizons.length; i++)
                        _buildHorizonBarRow(labels[i], diffs[i], maxScale, textCol),
                      const SizedBox(height: 6),
                      Text('Green = ARM wins (savings)  |  Red = Fixed wins',
                          style: AppTextStyles.dmSans(size: 8, color: mutedCol)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader('Advantage Snapshot'),

                // Table snapshot Card
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
                      Text('📊 Holding Period Cost Matrix',
                          style: AppTextStyles.playfair(size: 11.5, color: textCol, weight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      _buildMatrixRow('3 Years', 3, textCol),
                      _buildMatrixRow('5 Years', 5, textCol),
                      _buildMatrixRow('10 Years', 10, textCol),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                // Footer helper note strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B3F72).withValues(alpha: 0.08),
                    border: Border.all(color: const Color(0xFF1B3F72).withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡 ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: Text(
                          'This is a simplified P&I-only comparison — it excludes closing costs, taxes, insurance, and the chance that the adjusted ARM rate will land above or below your estimate. Use it to frame the conversation with your lender.',
                          style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF1B3F72), height: 1.4),
                        ),
                      ),
                    ],
                  ),
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
                color: isDark ? Colors.white54 : const Color(0xFF4A5C7A),
                letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyles.playfair(
                size: 13,
                weight: FontWeight.w800,
                color: isGold ? const Color(0xFFFCD34D) : Colors.white)),
        const SizedBox(height: 1),
        Text(sub,
            style: AppTextStyles.dmSans(
                size: 7.5, color: isDark ? Colors.white30 : Colors.white60)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 18),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.sectionLabel(_theme.getMutedColor(context)),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {String? hint}) {
    const theme = _theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8.5,
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
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => _calculate(),
            style: AppTextStyles.dmSans(
              size: 13,
              weight: FontWeight.w800,
              color: theme.getTextColor(context),
            ).copyWith(fontFamily: 'Georgia'),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: AppTextStyles.dmSans(size: 11.5, color: theme.getMutedColor(context).withValues(alpha: 0.4)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    const theme = _theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8.5,
            weight: FontWeight.w700,
            color: theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            border: Border.all(color: theme.getBorderColor(context), width: 1.5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              style: AppTextStyles.dmSans(
                size: 13,
                weight: FontWeight.w800,
                color: theme.getTextColor(context),
              ).copyWith(fontFamily: 'Georgia'),
              dropdownColor: theme.getCardColor(context),
              icon: Icon(Icons.arrow_drop_down, color: theme.getMutedColor(context)),
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String text, Color labelColor) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text(text, style: AppTextStyles.dmSans(size: 9.5, color: labelColor, weight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildBreakdownCard(String emoji, String label, String value, String sub, Color valColor, Color mutedCol) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _theme.getCardColor(context),
        border: Border.all(color: _theme.getBorderColor(context)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 15)),
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
          Text(value, style: AppTextStyles.playfair(size: 15.5, color: valColor, weight: FontWeight.w800)),
          const SizedBox(height: 1),
          Text(sub, style: AppTextStyles.dmSans(size: 8.5, color: mutedCol), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String val, Color textCol, Color mutedCol) {
    return Column(
      children: [
        Text(val, style: AppTextStyles.playfair(size: 14.5, color: textCol, weight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label.toUpperCase(), style: AppTextStyles.dmSans(size: 8, color: mutedCol, weight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildHorizonBarRow(String label, double val, double maxScale, Color textCol) {
    final isSave = val >= 0;
    final widthPct = (val.abs() / maxScale).clamp(0.04, 1.0);
    final color = isSave ? const Color(0xFF15803D) : const Color(0xFFB91C1C);

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label, style: AppTextStyles.dmSans(size: 9.5, color: textCol, weight: FontWeight.w700)),
          ),
          Expanded(
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: widthPct,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    '${isSave ? '+' : '-'}\$${val.abs().round()}',
                    style: AppTextStyles.dmSans(size: 8, color: Colors.white, weight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixRow(String text, double y, Color textCol) {
    final fixedMonths = _armYrs * 12;
    final armC = _cumulativeCost(y, _armPI, _armAdjPI, fixedMonths);
    final fixC = _fixedCumulativeCost(y, _fixedPI);
    final diff = fixC - armC;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _theme.getBorderColor(context), width: 0.8))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: textCol)),
          Text('\$${armC.round()}', style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w600, color: textCol)),
          Text('\$${fixC.round()}', style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w600, color: textCol)),
          Text(
            '${diff >= 0 ? '+\$' : '-\$'}${diff.abs().round()}',
            style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: diff >= 0 ? const Color(0xFF15803D) : const Color(0xFFB91C1C)),
          ),
        ],
      ),
    );
  }
}

// Custom painter to draw cumulative cost lines and breakeven point
class BreakevenLineChartPainter extends CustomPainter {
  final double armPI;
  final double fixedPI;
  final double armAdjPI;
  final int fixedMonths;
  final double breakeven;
  final bool isDark;

  BreakevenLineChartPainter({
    required this.armPI,
    required this.fixedPI,
    required this.armAdjPI,
    required this.fixedMonths,
    required this.breakeven,
    required this.isDark,
  });

  double _cumulativeCost(double years) {
    const totalMonths = 360;
    final months = min(years * 12, totalMonths.toDouble()).toInt();
    if (months <= fixedMonths) {
      return armPI * months;
    } else {
      return (armPI * fixedMonths) + (armAdjPI * (months - fixedMonths));
    }
  }

  double _fixedCumulativeCost(double years) {
    const totalMonths = 360;
    final months = min(years * 12, totalMonths.toDouble()).toInt();
    return fixedPI * months;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double W = size.width;
    final double H = size.height;
    const double pad = 10.0;

    const double yearsRange = 15.0;
    final List<double> armPts = [];
    final List<double> fixPts = [];
    double maxVal = 1000.0;

    for (double y = 0.0; y <= yearsRange; y += 0.5) {
      final a = _cumulativeCost(y);
      final f = _fixedCumulativeCost(y);
      armPts.add(a);
      fixPts.add(f);
      maxVal = max(maxVal, max(a, f));
    }

    final int n = armPts.length;

    Offset toXY(int i, double val) {
      final x = pad + (i / (n - 1)) * (W - pad * 2);
      final y = H - pad - (val / maxVal) * (H - pad * 2);
      return Offset(x, y);
    }

    // Draw lines
    final armPath = Path();
    final fixPath = Path();

    for (int i = 0; i < n; i++) {
      final pArm = toXY(i, armPts[i]);
      final pFix = toXY(i, fixPts[i]);
      if (i == 0) {
        armPath.moveTo(pArm.dx, pArm.dy);
        fixPath.moveTo(pFix.dx, pFix.dy);
      } else {
        armPath.lineTo(pArm.dx, pArm.dy);
        fixPath.lineTo(pFix.dx, pFix.dy);
      }
    }

    final Paint armPaint = Paint()
      ..color = const Color(0xFF0F766E)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint fixPaint = Paint()
      ..color = const Color(0xFF1B3F72)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(fixPath, fixPaint);
    canvas.drawPath(armPath, armPaint);

    // Draw vertical breakeven line if applicable
    if (breakeven <= yearsRange) {
      final double idx = (breakeven / yearsRange) * (n - 1);
      final double beX = pad + (idx / (n - 1)) * (W - pad * 2);

      final Paint dashPaint = Paint()
        ..color = const Color(0xFFD97706)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      // Draw dashed line
      const double dashHeight = 4.0;
      const double dashSpace = 3.0;
      double currY = 0.0;
      while (currY < H) {
        canvas.drawLine(
          Offset(beX, currY),
          Offset(beX, min(currY + dashHeight, H)),
          dashPaint,
        );
        currY += dashHeight + dashSpace;
      }

      // Draw a marker dot at intersection
      final double beVal = _cumulativeCost(breakeven);
      final double beY = H - pad - (beVal / maxVal) * (H - pad * 2);
      canvas.drawCircle(Offset(beX, beY), 5.0, Paint()..color = const Color(0xFFD97706));
      canvas.drawCircle(Offset(beX, beY), 2.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant BreakevenLineChartPainter oldDelegate) => true;
}
