import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/mortgage_math.dart';
import '../../../core/utils/pmi_calculator.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/result_panel.dart';
import '../../../shared/widgets/amortization_chart.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../shared/widgets/live_rate_banner.dart';
import '../../../providers/usa_rates_provider.dart';

class USAMortgageCalcSheet extends StatefulWidget {
  final double homePrice;
  final double downPercent;
  final int termYears;
  final double rate;

  const USAMortgageCalcSheet({
    super.key,
    this.homePrice = 450000,
    this.downPercent = 20,
    this.termYears = 30,
    this.rate = 6.82,
  });

  @override
  State<USAMortgageCalcSheet> createState() => _USAMortgageCalcSheetState();
}

class _USAMortgageCalcSheetState extends State<USAMortgageCalcSheet> {
  late double _homePrice;
  late double _downPct;
  late int _termYears;
  late double _rate;
  late double _propertyTaxRate;
  late double _insuranceRate;
  bool _showAmortization = false;

  @override
  void initState() {
    super.initState();
    _homePrice = widget.homePrice;
    _downPct = widget.downPercent;
    _termYears = widget.termYears;
    _rate = widget.rate;
    _propertyTaxRate = 1.1; // 1.1% national average
    _insuranceRate = 0.5; // 0.5% annual
  }

  double get _loanAmount => _homePrice * (1 - _downPct / 100);
  double get _ltv => MortgageMath.ltv(_loanAmount, _homePrice);

  double get _monthlyPI => MortgageMath.monthlyPayment(
        principal: _loanAmount,
        annualRatePercent: _rate,
        termYears: _termYears,
      );

  double get _monthlyTax => _homePrice * (_propertyTaxRate / 100) / 12;
  double get _monthlyInsurance => _homePrice * (_insuranceRate / 100) / 12;

  double get _monthlyPMI => PMICalculator.monthlyPMI(
        loanAmount: _loanAmount,
        ltvPercent: _ltv,
      );

  double get _totalMonthly =>
      _monthlyPI + _monthlyTax + _monthlyInsurance + _monthlyPMI;

  List<AmortizationEntry> get _schedule => MortgageMath.amortizationSchedule(
        principal: _loanAmount,
        annualRatePercent: _rate,
        termYears: _termYears,
      );

  @override
  Widget build(BuildContext context) {
    const theme = CountryThemes.usa;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? Theme.of(context).scaffoldBackgroundColor
                : const Color(0xFFEEF3FF),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // Handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const Text('🦅 ', style: TextStyle(fontSize: 20)),
                          Text(
                            'USA Mortgage (PITI)',
                            style: AppTextStyles.dmSans(
                              size: 18,
                              weight: FontWeight.w800,
                              color: theme.textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Sliders
                    _SliderSection(
                      label: 'Home Price',
                      value: _homePrice,
                      min: 50000,
                      max: 3000000,
                      divisions: 590,
                      displayValue: CurrencyFormatter.compact(_homePrice),
                      primaryColor: theme.primaryColor,
                      onChanged: (v) => setState(() => _homePrice = v),
                    ),
                    _SliderSection(
                      label: 'Down Payment',
                      value: _downPct,
                      min: 3,
                      max: 50,
                      divisions: 47,
                      displayValue: '${_downPct.toInt()}%',
                      primaryColor: theme.primaryColor,
                      onChanged: (v) => setState(() => _downPct = v),
                    ),
                    _SliderSection(
                      label: 'Interest Rate',
                      value: _rate,
                      min: 2,
                      max: 15,
                      divisions: 130,
                      displayValue: '${_rate.toStringAsFixed(2)}%',
                      primaryColor: theme.primaryColor,
                      onChanged: (v) => setState(() => _rate = v),
                    ),
                    _TermSelector(
                      selected: _termYears,
                      primaryColor: theme.primaryColor,
                      onChanged: (v) => setState(() => _termYears = v),
                    ),
                    const SizedBox(height: 16),
                    // Results
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ResultPanel(
                        primaryColor: theme.primaryColor,
                        rows: [
                          ResultRow(
                            label: 'Total Monthly (PITI)',
                            value: _totalMonthly,
                            currencyCode: 'USD',
                            isHighlighted: true,
                          ),
                          ResultRow(
                              label: 'Principal & Interest',
                              value: _monthlyPI,
                              currencyCode: 'USD'),
                          ResultRow(
                              label: 'Property Tax (est.)',
                              value: _monthlyTax,
                              currencyCode: 'USD'),
                          ResultRow(
                              label: 'Home Insurance (est.)',
                              value: _monthlyInsurance,
                              currencyCode: 'USD'),
                          if (_monthlyPMI > 0)
                            ResultRow(
                                label: 'PMI (LTV: ${_ltv.toStringAsFixed(1)}%)',
                                value: _monthlyPMI,
                                currencyCode: 'USD'),
                          ResultRow(
                              label: 'Total Interest Paid',
                              value: MortgageMath.totalInterest(
                                  principal: _loanAmount,
                                  annualRatePercent: _rate,
                                  termYears: _termYears),
                              currencyCode: 'USD'),
                          ResultRow(
                              label: 'Loan Amount',
                              value: _loanAmount,
                              currencyCode: 'USD'),
                          ResultRow(
                              label: 'LTV Ratio', value: _ltv, isPercent: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Amortization toggle
                    GestureDetector(
                      onTap: () => setState(
                          () => _showAmortization = !_showAmortization),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color:
                                    theme.primaryColor.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _showAmortization
                                ? '▲ Hide Amortization Chart'
                               : '📅 Show Amortization Chart',
                            style: AppTextStyles.dmSans(
                              size: 12,
                              weight: FontWeight.w700,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_showAmortization) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AmortizationChart(
                          schedule: _schedule,
                          theme: theme,
                          currencyCode: 'USD',
                        ),
                      ),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SliderSection extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final Color primaryColor;
  final ValueChanged<double> onChanged;

  const _SliderSection({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.primaryColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.dmSans(
                  size: 12,
                  weight: FontWeight.w600,
                  color: const Color(0xFF5B6E8F),
                ),
              ),
              Text(
                displayValue,
                style: AppTextStyles.dmSans(
                  size: 14,
                  weight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: primaryColor,
              thumbColor: primaryColor,
              inactiveTrackColor: primaryColor.withValues(alpha: 0.20),
              overlayColor: primaryColor.withValues(alpha: 0.15),
              trackHeight: 3,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _TermSelector extends StatelessWidget {
  final int selected;
  final Color primaryColor;
  final ValueChanged<int> onChanged;

  const _TermSelector({
    required this.selected,
    required this.primaryColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Loan Term',
            style: AppTextStyles.dmSans(
              size: 12,
              weight: FontWeight.w600,
              color: const Color(0xFF5B6E8F),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [10, 15, 20, 25, 30].map((term) {
              final isActive = term == selected;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(term),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive
                            ? primaryColor
                            : primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${term}yr',
                      style: AppTextStyles.dmSans(
                        size: 11,
                        weight: FontWeight.w700,
                        color: isActive ? Colors.white : primaryColor,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Full Screen USA Mortgage Calculator ────────────────────────────
class USAMortgageCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const USAMortgageCalc({super.key, this.theme = CountryThemes.usa});

  @override
  ConsumerState<USAMortgageCalc> createState() => _USAMortgageCalcState();
}

class _USAMortgageCalcState extends ConsumerState<USAMortgageCalc> {
  double _homePrice = 420000.0;
  double _downPct = 20.0;
  double _rate = 6.82;
  int _selectedTerm = 30;

  final _resultsKey = GlobalKey();
  bool _showResults = false;
  final Map<dynamic, dynamic> _calcSnapshot = {};

  void _calculate() {
    setState(() {
      _calcSnapshot['_homePrice'] = _homePrice;
      _calcSnapshot['_downPct'] = _downPct;
      _calcSnapshot['_rate'] = _rate;
      _calcSnapshot['_selectedTerm'] = _selectedTerm;
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

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final calcHomePrice = _showResults ? (_calcSnapshot['_homePrice'] ?? _homePrice) : _homePrice;
    final calcDownPct = _showResults ? (_calcSnapshot['_downPct'] ?? _downPct) : _downPct;
    final calcRate = _showResults ? (_calcSnapshot['_rate'] ?? _rate) : _rate;
    final calcSelectedTerm = _showResults ? (_calcSnapshot['_selectedTerm'] ?? _selectedTerm) : _selectedTerm;

    final isDirty = _showResults && (
      _homePrice != _calcSnapshot['_homePrice'] ||
      _downPct != _calcSnapshot['_downPct'] ||
      _rate != _calcSnapshot['_rate'] ||
      _selectedTerm != _calcSnapshot['_selectedTerm']
    );

    // Calculations
    final downAmt = calcHomePrice * calcDownPct / 100;
    final loanAmt = calcHomePrice - downAmt;
    final ltv = calcHomePrice > 0 ? (loanAmt / calcHomePrice * 100) : 0.0;

    final monthlyPI = MortgageMath.monthlyPayment(
      principal: loanAmt,
      annualRatePercent: calcRate,
      termYears: calcSelectedTerm,
    );

    // Payments for active chips
    final pmt30 = MortgageMath.monthlyPayment(principal: loanAmt, annualRatePercent: 6.82, termYears: 30);
    final pmt15 = MortgageMath.monthlyPayment(principal: loanAmt, annualRatePercent: 6.11, termYears: 15);
    final pmt10 = MortgageMath.monthlyPayment(principal: loanAmt, annualRatePercent: calcRate, termYears: 10);

    // Comparison grid interest amounts
    final int10 = (pmt10 * 120) - loanAmt;
    final int30 = (pmt30 * 360) - loanAmt;
    final int15 = (pmt15 * 180) - loanAmt;

    // Metrics
    final totalInterest = (monthlyPI * calcSelectedTerm * 12) - loanAmt;
    final totalCost = loanAmt + totalInterest;

    // Saved Calculations watch
    final savedCalcs = ref.watch(savedProvider).where((c) => c.country == 'USA' && c.calcType == 'Mortgage Calculator').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip — Live FRED data
        LightRateStripBanner(items: [
          RateStripItem(label: '30-Yr Fixed', provider: fredMortgage30Provider, fallback: 6.82),
          RateStripItem(label: '15-Yr Fixed', provider: fredMortgage15Provider, fallback: 6.11),
          RateStripItem(label: '5/1 ARM', provider: fredSofrProvider, fallback: 5.33),
          RateStripItem(label: 'Fed Funds', provider: fredFedFundsProvider, fallback: 5.33, isGold: true),
        ]),
        const SizedBox(height: 20),

        _buildSectionHeader('Adjust Loan', onReset: _resetInputs),
        const SizedBox(height: 8),

        // Slider Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 36,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🧮 USA MORTGAGE CALCULATOR',
                style: AppTextStyles.dmSans(
                  size: 9.5,
                  weight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.48),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),

              // Result display
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
                    CurrencyFormatter.format(monthlyPI, symbol: '').split('.').first,
                    style: AppTextStyles.dmSans(
                      size: 38,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ).copyWith(fontFamily: 'Georgia'),
                  ),
                  Text(
                    '/mo',
                    style: AppTextStyles.dmSans(
                      size: 13,
                      weight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.50),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Home Price Slider
              _buildSliderSection(
                label: 'Home Price',
                value: _homePrice,
                min: 100000,
                max: 2000000,
                divisions: 380, // 5k steps
                displayValue: CurrencyFormatter.format(_homePrice, symbol: '\$').split('.').first,
                onChanged: (v) => setState(() => _homePrice = v),
              ),

              // Down Payment Slider
              _buildSliderSection(
                label: 'Down Payment',
                value: _downPct,
                min: 3,
                max: 50,
                divisions: 47,
                displayValue: '${_downPct.toInt()}% · ${CurrencyFormatter.format(downAmt, symbol: '\$').split('.').first}',
                onChanged: (v) => setState(() => _downPct = v),
              ),

              // Interest Rate Slider
              _buildSliderSection(
                label: 'Interest Rate',
                value: _rate,
                min: 2,
                max: 12,
                divisions: 1000,
                displayValue: '${_rate.toStringAsFixed(2)}%',
                onChanged: (v) => setState(() => _rate = v),
              ),
              const SizedBox(height: 12),

              // Term selectors
              Row(
                children: [
                  Expanded(
                    child: _buildTermBox(
                      label: '30-Year Fixed',
                      value: pmt30,
                      isActive: _selectedTerm == 30,
                      onTap: () => setState(() => _selectedTerm = 30),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTermBox(
                      label: '15-Year Fixed',
                      value: pmt15,
                      isActive: _selectedTerm == 15,
                      onTap: () => setState(() => _selectedTerm = 15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Calculate Button
              GestureDetector(
                onTap: _calculate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB91C1C), Color(0xFF991B1B)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB91C1C).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '🧮 Calculate Payment',
                    style: AppTextStyles.dmSans(
                      size: 13,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ).copyWith(fontFamily: 'Georgia'),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Save Button (Transparent Outline style)
              GestureDetector(
                onTap: _showResults ? _saveCalculation : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: _showResults ? 0.10 : 0.05),
                    border: Border.all(color: Colors.white.withValues(alpha: _showResults ? 0.25 : 0.10), width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('💾', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: _showResults ? 1.0 : 0.4))),
                      const SizedBox(width: 8),
                      Text(
                        'Save This Calculation',
                        style: AppTextStyles.dmSans(
                          size: 13,
                          weight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: _showResults ? 1.0 : 0.4),
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

        if (_showResults) ...[
          Container(
            key: _resultsKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDirty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      border: Border.all(color: Colors.amber),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Inputs have changed. Tap "Calculate" to update results.',
                            style: AppTextStyles.dmSans(size: 11, color: isDark ? Colors.white70 : const Color(0xFF0B1D3A), weight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Term Comparison Card
                _buildSectionHeader('Loan Term Comparison', onReset: null),
        const SizedBox(height: 8),

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Monthly Payment by Term',
                    style: AppTextStyles.dmSans(
                      size: 12.5,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context),
                    ).copyWith(fontFamily: 'Georgia'),
                  ),
                  Text(
                    'Same rate',
                    style: AppTextStyles.dmSans(
                      size: 10,
                      weight: FontWeight.w500,
                      color: const Color(0xFF1B3F72),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildComparisonItem(
                      term: '10 Year',
                      payment: pmt10,
                      rate: _rate,
                      interest: int10,
                      isHighlighted: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildComparisonItem(
                      term: '⭐ 30 Year',
                      payment: pmt30,
                      rate: 6.82,
                      interest: int30,
                      isHighlighted: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildComparisonItem(
                      term: '15 Year',
                      payment: pmt15,
                      rate: 6.11,
                      interest: int15,
                      isHighlighted: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Key Metrics Section
        _buildSectionHeader('Key Metrics', onReset: null),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(16),
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
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 84,
                    height: 84,
                    child: CustomPaint(
                      painter: _MortgageDonutPainter(
                        loanPct: totalCost > 0 ? loanAmt / totalCost : 0.0,
                        interestPct: totalCost > 0 ? totalInterest / totalCost : 0.0,
                        isDark: isDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      children: [
                        _buildDonutLegendRow(
                          color: const Color(0xFF1B3F72),
                          label: 'Loan Principal',
                          value: '${((totalCost > 0 ? loanAmt / totalCost : 0.0) * 100).toStringAsFixed(0)}%',
                          textColor: theme.getTextColor(context),
                        ),
                        const SizedBox(height: 7),
                        _buildDonutLegendRow(
                          color: const Color(0xFFB91C1C),
                          label: 'Total Interest',
                          value: '${((totalCost > 0 ? totalInterest / totalCost : 0.0) * 100).toStringAsFixed(0)}%',
                          textColor: theme.getTextColor(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricBox(
                      label: 'Loan Amount',
                      value: CurrencyFormatter.format(loanAmt, symbol: '\$').split('.').first,
                      sub: 'After down payment',
                      color1: const Color(0xFF0B1D3A),
                      color2: const Color(0xFF1B3F72),
                      isLight: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricBox(
                      label: 'Total Interest',
                      value: CurrencyFormatter.format(totalInterest, symbol: '\$').split('.').first,
                      sub: 'Over loan life',
                      color1: const Color(0xFFB91C1C),
                      color2: const Color(0xFF991B1B),
                      isLight: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricBox(
                      label: 'Total Cost',
                      value: CurrencyFormatter.format(totalCost, symbol: '\$').split('.').first,
                      sub: 'Principal + interest',
                      color1: Colors.transparent,
                      color2: Colors.transparent,
                      isLight: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricBox(
                      label: 'Loan-to-Value',
                      value: '${ltv.toStringAsFixed(1)}%',
                      sub: 'PMI threshold: 80%',
                      color1: Colors.transparent,
                      color2: Colors.transparent,
                      isLight: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Today's Best Rates comparison list
        _buildSectionHeader("Today's Best Rates", onReset: null),
        const SizedBox(height: 8),

        Column(
          children: [
            _buildLenderCard(
              icon: '🚀',
              lender: 'Rocket Mortgage',
              desc: '30-yr fixed · largest US lender',
              rate: 6.75,
              monthlyEst: MortgageMath.monthlyPayment(principal: loanAmt, annualRatePercent: 6.75, termYears: 30),
              isUp: true,
            ),
            const SizedBox(height: 9),
            _buildLenderCard(
              icon: '🏦',
              lender: 'Wells Fargo',
              desc: '30-yr fixed · \$1.9T assets',
              rate: 6.88,
              monthlyEst: MortgageMath.monthlyPayment(principal: loanAmt, annualRatePercent: 6.88, termYears: 30),
            ),
            const SizedBox(height: 9),
            _buildLenderCard(
              icon: '🏛️',
              lender: 'Chase Bank',
              desc: '30-yr fixed · DreamMaker 3%',
              rate: 6.90,
              monthlyEst: MortgageMath.monthlyPayment(principal: loanAmt, annualRatePercent: 6.90, termYears: 30),
            ),
            const SizedBox(height: 9),
            _buildLenderCard(
              icon: '📊',
              lender: 'Freddie Mac Avg',
              desc: 'National weekly avg (PMMS)',
              rate: 6.82,
              monthlyEst: MortgageMath.monthlyPayment(principal: loanAmt, annualRatePercent: 6.82, termYears: 30),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Rate Tip Banner
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF2C200F), const Color(0xFF1E160A)]
                  : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
            ),
            border: Border.all(
              color: isDark
                  ? const Color(0xFFD97706).withValues(alpha: 0.5)
                  : const Color(0xFFF59E0B),
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('💡 ', style: TextStyle(fontSize: 14)),
                  Text(
                    'Rate Tip',
                    style: AppTextStyles.dmSans(
                      size: 11.5,
                      weight: FontWeight.w800,
                      color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E),
                    ).copyWith(fontFamily: 'Georgia'),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                'A 0.5% rate drop on a \$336K loan saves ~\$112/month and \$40,000+ over 30 years. Shop at least 3 lenders — studies show borrowers who compare save an avg of \$1,500 per year (CFPB 2024).',
                style: AppTextStyles.dmSans(
                  size: 10,
                  weight: FontWeight.w500,
                  color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 20),

      // Saved Calculations list at bottom
      _buildSectionHeader('Saved Calculations', onReset: null),
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
                      'No saved calculations yet. Tap "Save This Calculation" above.',
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
                    final downVal = calc.inputs['DownPct'] ?? 0.0;
                    final termVal = (calc.inputs['Term'] ?? 30.0).toInt();
                    final rateVal = calc.inputs['Rate'] ?? 0.0;
                    final pmtVal = calc.results['MonthlyPI'] ?? 0.0;

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
                              onTap: () {
                                setState(() {
                                  _homePrice = priceVal;
                                  _downPct = downVal;
                                  _rate = rateVal;
                                  _selectedTerm = termVal;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Loaded saved calculation!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
                                    backgroundColor: theme.primaryColor,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '\$${CurrencyFormatter.format(pmtVal, symbol: '').split('.').first}/mo · ${termVal}yr @ ${rateVal.toStringAsFixed(2)}%',
                                    style: AppTextStyles.dmSans(
                                      size: 12,
                                      weight: FontWeight.w800,
                                      color: theme.getTextColor(context),
                                    ).copyWith(fontFamily: 'Georgia'),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Price ${CurrencyFormatter.compact(priceVal, symbol: '\$')} · ${downVal.toStringAsFixed(0)}% down',
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

  Widget _buildSectionHeader(String title, {VoidCallback? onReset}) {
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
              'Reset',
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

  void _saveCalculation() async {
    final price = _calcSnapshot['_homePrice'] ?? _homePrice;
    final downPct = _calcSnapshot['_downPct'] ?? _downPct;
    final down = price * downPct / 100;
    final loan = price - down;
    final rate = _calcSnapshot['_rate'] ?? _rate;
    final term = (_calcSnapshot['_selectedTerm'] ?? _selectedTerm).toInt();

    final monthlyPI = MortgageMath.monthlyPayment(
      principal: loan,
      annualRatePercent: rate,
      termYears: term,
    );

    final totalInterest = (monthlyPI * term * 12) - loan;
    final totalCost = loan + totalInterest;

    final labelCtrl = TextEditingController(text: 'Mortgage Calculator');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_mortgage_calc/save'),
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
              'Saving: P&I ${CurrencyFormatter.compact(monthlyPI, symbol: '\$')} · Price: ${CurrencyFormatter.compact(price, symbol: '\$')} · Down: ${_downPct.toStringAsFixed(0)}%',
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
                hintText: 'Label (e.g. My Mortgage Calc)',
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
          : 'Mortgage Calculator';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'Mortgage Calculator',
        inputs: {
          'Price': price,
          'DownPct': _downPct,
          'Rate': rate,
          'Term': term.toDouble(),
        },
        results: {
          'MonthlyPI': monthlyPI,
          'TotalInterest': totalInterest,
          'TotalCost': totalCost,
          'LoanAmount': loan,
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

  void _resetInputs() {
    setState(() {
      _homePrice = 420000.0;
      _downPct = 20.0;
      _rate = 6.82;
      _selectedTerm = 30;
      _calcSnapshot.clear();
      _showResults = false;
    });
  }

  Widget _buildSliderSection({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.dmSans(
                  size: 9.5,
                  weight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.55),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                displayValue,
                style: AppTextStyles.dmSans(
                  size: 13,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFFFCD34D),
              thumbColor: const Color(0xFFFCD34D),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
              overlayColor: const Color(0xFFFCD34D).withValues(alpha: 0.15),
              trackHeight: 3,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermBox({
    required String label,
    required double value,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFB91C1C).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.09),
          border: Border.all(
            color: isActive ? const Color(0xFFB91C1C).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.14),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(11),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(
              label,
              style: AppTextStyles.dmSans(
                size: 8.5,
                weight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              CurrencyFormatter.format(value, symbol: '\$').split('.').first,
              style: AppTextStyles.dmSans(
                size: 14,
                weight: FontWeight.w800,
                color: Colors.white,
              ).copyWith(fontFamily: 'Georgia'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonItem({
    required String term,
    required double payment,
    required double rate,
    required double interest,
    required bool isHighlighted,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
      decoration: BoxDecoration(
        color: isHighlighted
            ? const Color(0xFF0B1D3A)
            : isDark
                ? widget.theme.getCardColor(context)
                : const Color(0xFFEEF3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? Colors.transparent : widget.theme.getBorderColor(context),
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(
            term,
            style: AppTextStyles.dmSans(
              size: 9,
              weight: FontWeight.w800,
              color: isHighlighted ? Colors.white70 : widget.theme.getMutedColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(payment, symbol: '\$').split('.').first,
            style: AppTextStyles.dmSans(
              size: 16,
              weight: FontWeight.w800,
              color: isHighlighted ? Colors.white : widget.theme.getTextColor(context),
            ).copyWith(fontFamily: 'Georgia'),
          ),
          const SizedBox(height: 2),
          Text(
            '${rate.toStringAsFixed(2)}%',
            style: AppTextStyles.dmSans(
              size: 9,
              color: isHighlighted ? Colors.white60 : widget.theme.getMutedColor(context),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${CurrencyFormatter.format(interest, symbol: '\$').split('.').first} int',
            style: AppTextStyles.dmSans(
              size: 9,
              weight: FontWeight.w700,
              color: isHighlighted ? const Color(0xFFFCA5A5) : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox({
    required String label,
    required String value,
    required String sub,
    required Color color1,
    required Color color2,
    required bool isLight,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final decoration = isLight
        ? BoxDecoration(
            color: isDark ? widget.theme.getBgColor(context) : const Color(0xFFEEF3FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.theme.getBorderColor(context)),
          )
        : BoxDecoration(
            gradient: LinearGradient(colors: [color1, color2]),
            borderRadius: BorderRadius.circular(12),
          );

    final titleColor = isLight
        ? (isDark ? Colors.white70 : widget.theme.getMutedColor(context))
        : Colors.white70;

    final valColor = isLight
        ? (isDark ? Colors.white : widget.theme.getTextColor(context))
        : Colors.white;

    final subColor = isLight
        ? (isDark ? Colors.white38 : widget.theme.getMutedColor(context))
        : Colors.white.withValues(alpha: 0.50);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.dmSans(
              size: 9,
              weight: FontWeight.w700,
              color: titleColor,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTextStyles.dmSans(
              size: 16,
              weight: FontWeight.w800,
              color: valColor,
            ).copyWith(fontFamily: 'Georgia'),
          ),
          const SizedBox(height: 3),
          Text(
            sub,
            style: AppTextStyles.dmSans(
              size: 9,
              color: subColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLenderCard({
    required String icon,
    required String lender,
    required String desc,
    required double rate,
    required double monthlyEst,
    bool isUp = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: isDark ? widget.theme.getCardColor(context) : Colors.white,
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
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF3FF),
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
                  lender,
                  style: AppTextStyles.dmSans(
                    size: 12.5,
                    weight: FontWeight.w800,
                    color: widget.theme.getTextColor(context),
                  ).copyWith(fontFamily: 'Georgia'),
                ),
                Text(
                  desc,
                  style: AppTextStyles.dmSans(
                    size: 9.5,
                    color: widget.theme.getMutedColor(context),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(
                    '${rate.toStringAsFixed(2)}%',
                    style: AppTextStyles.dmSans(
                      size: 16,
                      weight: FontWeight.w800,
                      color: widget.theme.getTextColor(context),
                    ).copyWith(fontFamily: 'Georgia'),
                  ),
                  if (isUp)
                    const Text('↑', style: TextStyle(fontSize: 10, color: Color(0xFF15803D)))
                ],
              ),
              Text(
                '~${CurrencyFormatter.format(monthlyEst, symbol: '\$').split('.').first}/mo',
                style: AppTextStyles.dmSans(
                  size: 9.5,
                  color: widget.theme.getMutedColor(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonutLegendRow({
    required Color color,
    required String label,
    required String value,
    required Color textColor,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.dmSans(
              size: 10.5,
              weight: FontWeight.w500,
              color: widget.theme.getMutedColor(context),
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.dmSans(
            size: 11.5,
            weight: FontWeight.w800,
            color: textColor,
          ).copyWith(fontFamily: 'Georgia'),
        ),
      ],
    );
  }
}

class _MortgageDonutPainter extends CustomPainter {
  final double loanPct;
  final double interestPct;
  final bool isDark;

  _MortgageDonutPainter({
    required this.loanPct,
    required this.interestPct,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const strokeWidth = 13.0;

    final paintBg = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F4FF)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, paintBg);

    if (loanPct <= 0 && interestPct <= 0) return;

    double startAngle = -pi / 2;

    if (loanPct > 0) {
      final sweep = 2 * pi * loanPct;
      final paintLoan = Paint()
        ..color = const Color(0xFF1B3F72)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, sweep - 0.03, false, paintLoan);
      startAngle += sweep;
    }

    if (interestPct > 0) {
      final sweep = 2 * pi * interestPct;
      final paintInt = Paint()
        ..color = const Color(0xFFB91C1C)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, sweep, false, paintInt);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

