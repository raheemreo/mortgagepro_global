// lib/features/usa/screens/usa_hoa_fee_increases_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAHoaFeeIncreasesScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAHoaFeeIncreasesScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAHoaFeeIncreasesScreen> createState() => _USAHoaFeeIncreasesScreenState();
}

class _USAHoaFeeIncreasesScreenState extends ConsumerState<USAHoaFeeIncreasesScreen> {
  static const _theme = CountryThemes.usa;

  final _currentHoaController = TextEditingController(text: '350');
  final _increaseRateController = TextEditingController(text: '4.2');
  final _projYearsController = TextEditingController(text: '10');
  final _monthlyIncomeController = TextEditingController(text: '8500');
  final _incomeGrowthController = TextEditingController(text: '3.0');

  bool _showResults = false;
  bool _isCalcDirty = true;

  @override
  void initState() {
    super.initState();
    final list = [
      _currentHoaController,
      _increaseRateController,
      _projYearsController,
      _monthlyIncomeController,
      _incomeGrowthController,
    ];
    for (final controller in list) {
      controller.addListener(_markDirty);
    }

    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _currentHoaController.text = (inputs['CurrentHoa'] ?? 350.0).toStringAsFixed(0);
      _increaseRateController.text = (inputs['IncreaseRate'] ?? 4.2).toStringAsFixed(1);
      _projYearsController.text = (inputs['ProjYears'] ?? 10.0).toStringAsFixed(0);
      _monthlyIncomeController.text = (inputs['MonthlyIncome'] ?? 8500.0).toStringAsFixed(0);
      _incomeGrowthController.text = (inputs['IncomeGrowth'] ?? 3.0).toStringAsFixed(1);
      _showResults = true;
      _isCalcDirty = false;
    }
  }

  @override
  void dispose() {
    final list = [
      _currentHoaController,
      _increaseRateController,
      _projYearsController,
      _monthlyIncomeController,
      _incomeGrowthController,
    ];
    for (final controller in list) {
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

  void _resetInputs() {
    setState(() {
      _currentHoaController.text = '350';
      _increaseRateController.text = '4.2';
      _projYearsController.text = '10';
      _monthlyIncomeController.text = '8500';
      _incomeGrowthController.text = '3.0';
      _showResults = false;
      _isCalcDirty = true;
    });
  }

  void _calculate() {
    setState(() {
      _showResults = true;
      _isCalcDirty = false;
    });
  }

  void _saveCalculation() async {
    final base = _val(_currentHoaController);
    final rate = _val(_increaseRateController);
    final years = _val(_projYearsController);
    final income = _val(_monthlyIncomeController);
    final incGrowth = _val(_incomeGrowthController);

    final finalFee = base * pow(1 + rate / 100, years);
    final finalIncome = income * pow(1 + incGrowth / 100, years);
    final incomePct = finalIncome > 0 ? (finalFee / finalIncome * 100) : 0.0;
    final currentIncomePct = income > 0 ? (base / income * 100) : 0.0;
    final dtiShift = incomePct - currentIncomePct;

    double totalExtra = 0;
    for (int i = 1; i <= years; i++) {
      final projFee = base * pow(1 + rate / 100, i);
      totalExtra += (projFee - base) * 12;
    }

    final labelCtrl = TextEditingController(text: 'HOA Fee Increases');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_hoa_fee_increases_screen'),
      builder: (context) => AlertDialog(
        backgroundColor: _theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Projection',
            style: AppTextStyles.playfair(
                size: 16, color: _theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: Projected HOA: ${CurrencyFormatter.compact(finalFee, symbol: r'$')}/mo · DTI Shift: ${(dtiShift > 0 ? '+' : '')}${dtiShift.toStringAsFixed(1)}%',
              style: AppTextStyles.dmSans(
                  size: 11, color: _theme.getMutedColor(context)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: _theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My HOA Increase Plan)',
                hintStyle: AppTextStyles.dmSans(size: 13, color: Colors.grey),
                filled: true,
                fillColor: _theme.getBgColor(context),
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
              backgroundColor: const Color(0xFF6D28D9),
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
          : 'HOA Fee Increases';

      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'HOA Fee Increases',
        inputs: {
          'CurrentHoa': base,
          'IncreaseRate': rate,
          'ProjYears': years,
          'MonthlyIncome': income,
          'IncomeGrowth': incGrowth,
        },
        results: {
          'FinalFee': finalFee,
          'TotalExtraCost': totalExtra,
          'IncomePct': incomePct,
          'DtiShift': dtiShift,
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
            backgroundColor: const Color(0xFF6D28D9),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = _theme.getCardColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);
    final borderCol = _theme.getBorderColor(context);
    final bgCol = _theme.getBgColor(context);

    // Compute active calculation
    final base = _val(_currentHoaController);
    final rate = _val(_increaseRateController);
    final years = _val(_projYearsController).toInt();
    final income = _val(_monthlyIncomeController);
    final incGrowth = _val(_incomeGrowthController);

    final finalFee = base * pow(1 + rate / 100, years);
    final finalIncome = income * pow(1 + incGrowth / 100, years);
    final incomePct = finalIncome > 0 ? (finalFee / finalIncome * 100) : 0.0;
    final currentIncomePct = income > 0 ? (base / income * 100) : 0.0;
    final dtiShift = incomePct - currentIncomePct;

    double totalExtra = 0;
    for (int i = 1; i <= years; i++) {
      final projFee = base * pow(1 + rate / 100, i);
      totalExtra += (projFee - base) * 12;
    }

    // Compounded table lists
    final List<int> showYears = [1, 2, 3, 5, 7, 10, 15, 20].where((y) => y <= years).toList();
    if (!showYears.contains(years) && years > 0) {
      showYears.add(years);
    }
    showYears.sort();

    // Rate strip values
    const rateStats = [
      {'label': 'Avg Increase', 'value': '4.2%', 'note': 'Annual (2024)'},
      {'label': 'Inflation', 'value': '3.4%', 'note': 'CPI 2024'},
      {'label': '10-Yr Impact', 'value': '+51%', 'note': 'At 4.2%/yr'},
      {'label': 'Cap Limit', 'value': '5–20%', 'note': 'Most CC&Rs'},
    ];

    return Scaffold(
      backgroundColor: bgCol,
      body: CustomScrollView(
        slivers: [
          // Header with gradient
          SliverAppBar(
            expandedHeight: 155,
            pinned: true,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0B1D3A), Color(0xFF4C1D95), Color(0xFF6D28D9)],
                        stops: [0.0, 0.55, 1.0],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 50,
                    child: Opacity(
                      opacity: 0.07,
                      child: Text(
                        '📈',
                        style: TextStyle(
                          fontSize: 72,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => context.pop(),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text('←', style: TextStyle(color: Colors.white, fontSize: 16)),
                                ),
                              ),
                              Column(
                                children: [
                                  const Text('📈', style: TextStyle(fontSize: 24)),
                                  Text(
                                    'HOA Fee Increases',
                                    style: AppTextStyles.playfair(size: 17, color: Colors.white),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 36),
                            ],
                          ),
                          const Spacer(),
                          Center(
                            child: Text(
                              'Growth Rate · 10-Year Projection · Budget Impact',
                              style: AppTextStyles.dmSans(size: 10, color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Rate Strip Block
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFF1B3F72),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: rateStats.map((stat) {
                  final idx = rateStats.indexOf(stat);
                  final isLast = idx == rateStats.length - 1;
                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : Border(
                                right: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    width: 1),
                              ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            stat['label']!,
                            style: AppTextStyles.dmSans(
                                size: 8.5, weight: FontWeight.w700, color: Colors.white54),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stat['value']!,
                            style: AppTextStyles.playfair(
                              size: 15,
                              weight: FontWeight.w800,
                              color: stat['label'] == 'Avg Increase' || stat['label'] == 'Cap Limit' ? const Color(0xFFFCD34D) : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            stat['note']!,
                            style: AppTextStyles.dmSans(
                                size: 7.5, color: Colors.white38),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Main scroll area
          SliverList(
            delegate: SliverChildListDelegate([
              // Section Title
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 12, 15, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'FEE INCREASE PROJECTOR',
                      style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                    ),
                    GestureDetector(
                      onTap: _resetInputs,
                      child: Text(
                        'Reset',
                        style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w600, color: const Color(0xFF1B3F72)),
                      ),
                    ),
                  ],
                ),
              ),

              // Inputs Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          alignment: Alignment.center,
                          child: const Text('📈', style: TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'HOA Increase Projector',
                                style: AppTextStyles.playfair(
                                    size: 14.5, weight: FontWeight.w800, color: textCol),
                              ),
                              Text(
                                'Model your long-term HOA cost trajectory',
                                style: AppTextStyles.dmSans(size: 9.5, color: mutedCol),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(child: _buildTextInputRow('Current Monthly HOA', _currentHoaController, prefix: r'$')),
                        const SizedBox(width: 10),
                        Expanded(child: _buildTextInputRow('Annual Increase Rate', _increaseRateController, suffix: '%')),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(child: _buildTextInputRow('Projection Years', _projYearsController, suffix: 'yrs')),
                        const SizedBox(width: 10),
                        Expanded(child: _buildTextInputRow('Monthly Income (Gross)', _monthlyIncomeController, prefix: r'$')),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildTextInputRow('Expected Annual Income Growth', _incomeGrowthController, suffix: '%'),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _calculate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6D28D9),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                              elevation: 2,
                            ),
                            child: Text(
                              '📊 Project HOA Increases',
                              style: AppTextStyles.playfair(size: 13, weight: FontWeight.w800),
                            ),
                          ),
                        ),
                        if (_showResults && !_isCalcDirty) ...[
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _saveCalculation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cardBg,
                              foregroundColor: const Color(0xFF6D28D9),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                                side: const BorderSide(color: Color(0xFF6D28D9), width: 2),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              '🔖 Save',
                              style: AppTextStyles.dmSans(
                                  size: 12, weight: FontWeight.w700, color: const Color(0xFF6D28D9)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Results view
              if (_showResults && !_isCalcDirty) ...[
                const SizedBox(height: 16),

                // Hero Result Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6D28D9).withValues(alpha: 0.25),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROJECTED HOA FEE (END OF PERIOD)',
                        style: AppTextStyles.dmSans(
                            size: 8.5,
                            weight: FontWeight.w700,
                            color: Colors.white70,
                            letterSpacing: 0.6),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${CurrencyFormatter.format(finalFee, symbol: r'$')}/mo',
                        style: AppTextStyles.playfair(
                            size: 32, weight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'From ${CurrencyFormatter.format(base, symbol: r'$')}/mo today — +${((finalFee / (base > 0 ? base : 1.0) - 1.0) * 100).toStringAsFixed(0)}% over $years years',
                        style: AppTextStyles.dmSans(
                            size: 10, color: Colors.white.withValues(alpha: 0.8), weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _buildHeroBottomBox('Total Extra Cost', CurrencyFormatter.compact(totalExtra, symbol: r'$')),
                          const SizedBox(width: 8),
                          _buildHeroBottomBox('% of Income', '${incomePct.toStringAsFixed(1)}%'),
                          const SizedBox(width: 8),
                          _buildHeroBottomBox('DTI Shift', '${(dtiShift > 0 ? '+' : '')}${dtiShift.toStringAsFixed(1)}%'),
                        ],
                      )
                    ],
                  ),
                ),

                // Line Chart Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HOA Fee vs. Income Growth Over Time',
                        style: AppTextStyles.playfair(
                            size: 12.5, weight: FontWeight.w700, color: textCol),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 130,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _FeeIncreaseChartPainter(
                            base: base,
                            rate: rate,
                            incGrowth: incGrowth,
                            years: years,
                            income: income,
                            textColor: textCol,
                            mutedColor: mutedCol,
                            gridColor: borderCol,
                            isDark: isDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildChartLegend(const Color(0xFFB91C1C), 'HOA Fee'),
                          const SizedBox(width: 14),
                          _buildChartLegend(const Color(0xFF15803D), 'Income (HOA %)'),
                        ],
                      )
                    ],
                  ),
                ),

                // Scenario Comparison
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
                  child: Text(
                    'SCENARIO COMPARISON',
                    style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                  ),
                ),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildScenarioBox('Conservative', '2.5%/yr', base * pow(1 + 2.5 / 100, years), const Color(0xFF15803D), isDark ? const Color(0xFF0F2618) : const Color(0xFFF0FDF4), const Color(0x4015803D), years),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildScenarioBox('Likely', '4.2%/yr', base * pow(1 + 4.2 / 100, years), const Color(0xFFD97706), isDark ? const Color(0xFF33200B) : const Color(0xFFFFFBEB), const Color(0x48D97706), years),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildScenarioBox('Aggressive', '7.0%/yr', base * pow(1 + 7.0 / 100, years), const Color(0xFFB91C1C), isDark ? const Color(0xFF3B1212) : const Color(0xFFFEF2F2), const Color(0x40B91C1C), years),
                      ),
                    ],
                  ),
                ),

                // Year-by-Year Table Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Year-by-Year Projection',
                        style: AppTextStyles.playfair(
                            size: 12.5, weight: FontWeight.w700, color: textCol),
                      ),
                      const SizedBox(height: 10),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1),
                          1: FlexColumnWidth(1.2),
                          2: FlexColumnWidth(1.2),
                          3: FlexColumnWidth(1.2),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: borderCol, width: 2)),
                            ),
                            children: [
                              _buildTableHeaderCell('Year', mutedCol),
                              _buildTableHeaderCell('HOA/Mo', mutedCol),
                              _buildTableHeaderCell('Annual Cost', mutedCol),
                              _buildTableHeaderCell('% of Income', mutedCol),
                            ],
                          ),
                          ...showYears.map((y) {
                            final feeY = base * pow(1 + rate / 100, y);
                            final annualCostY = feeY * 12;
                            final incY = income * pow(1 + incGrowth / 100, y);
                            final pctY = incY > 0 ? feeY / incY * 100 : 0.0;

                            Color pctTextCol = textCol;
                            if (pctY > 8.0) {
                              pctTextCol = const Color(0xFFB91C1C);
                            } else if (pctY < 4.0) {
                              pctTextCol = const Color(0xFF15803D);
                            }

                            final isEven = showYears.indexOf(y) % 2 == 1;

                            return TableRow(
                              decoration: BoxDecoration(
                                color: isEven ? (isDark ? const Color(0xFF141C33) : const Color(0xFFF0F4FF)) : Colors.transparent,
                                border: Border(bottom: BorderSide(color: borderCol)),
                              ),
                              children: [
                                _buildTableCell('Y$y', textCol),
                                _buildTableCell(CurrencyFormatter.format(feeY, symbol: r'$'), textCol, isVal: true),
                                _buildTableCell(CurrencyFormatter.compact(annualCostY, symbol: r'$'), textCol, isVal: true),
                                _buildTableCell('${pctY.toStringAsFixed(1)}%', pctTextCol, isVal: true),
                              ],
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Historical increases banner
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 12, 15, 8),
                child: Text(
                  'NATIONAL HOA INCREASE HISTORY',
                  style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                ),
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF2E240D), const Color(0xFF241C0A)]
                        : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
                  ),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📊 Annual HOA Fee Increases by Year',
                        style: AppTextStyles.playfair(size: 12, weight: FontWeight.w800, color: const Color(0xFF92400E))),
                    const SizedBox(height: 10),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 1.6,
                      children: [
                        _buildHistoryGridItem('2020', '+2.8%', isDark),
                        _buildHistoryGridItem('2021', '+3.1%', isDark),
                        _buildHistoryGridItem('2022', '+5.6%', isDark),
                        _buildHistoryGridItem('2023', '+4.8%', isDark),
                        _buildHistoryGridItem('2024', '+4.2%', isDark),
                        _buildHistoryGridItem('5-Yr Avg', '+4.1%', isDark),
                      ],
                    ),
                  ],
                ),
              ),

              // Stats
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStaticStatCard('📉', 'CC&R Cap (Avg)', '10%', 'Annual increase cap', cardBg, textCol, mutedCol, borderCol, isDark),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStaticStatCard('🔒', 'Vote Required', '>20%', 'Member vote needed', cardBg, textCol, mutedCol, borderCol, isDark),
                    ),
                  ],
                ),
              ),

              // Key Drivers
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 12, 15, 8),
                child: Text(
                  'KEY INCREASE DRIVERS (2024–2025)',
                  style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                ),
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What\'s Pushing HOA Fees Up',
                      style: AppTextStyles.playfair(
                          size: 12.5, weight: FontWeight.w700, color: textCol),
                    ),
                    const SizedBox(height: 14),
                    Column(
                      children: [
                        _buildDriverBar('Insurance Costs', '28%', const Color(0xFFB91C1C), isDark),
                        const SizedBox(height: 8),
                        _buildDriverBar('Labor & Mgmt', '24%', const Color(0xFFD97706), isDark),
                        const SizedBox(height: 8),
                        _buildDriverBar('Utility Rates', '20%', const Color(0xFF6D28D9), isDark),
                        const SizedBox(height: 8),
                        _buildDriverBar('Deferred Maint.', '16%', const Color(0xFF1B3F72), isDark),
                        const SizedBox(height: 8),
                        _buildDriverBar('Capital Projects', '12%', const Color(0xFF15803D), isDark),
                      ],
                    ),
                  ],
                ),
              ),

              // Strategy Tip
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF2E1A47), const Color(0xFF1E1030)]
                        : [const Color(0xFFF3E8FF), const Color(0xFFEDE9FE)],
                  ),
                  border: Border.all(color: const Color(0x2E6D28D9)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💡 Budget Planning Strategy',
                        style: AppTextStyles.playfair(size: 11, weight: FontWeight.w800, color: const Color(0xFF4C1D95))),
                    const SizedBox(height: 5),
                    Text(
                      'When qualifying for a mortgage, use your current HOA fee — lenders won\'t project future increases. But in your personal budget, model a 4–5% annual increase for a realistic long-term picture. At 4.2%/yr, a \$350/mo HOA becomes \$526/mo in 10 years — a 50% increase. Factor this into your 30-year home affordability plan.',
                      style: AppTextStyles.dmSans(size: 10, color: const Color(0xFF6D28D9), height: 1.55),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInputRow(String label, TextEditingController controller,
      {String? prefix, String? suffix}) {
    final textColor = _theme.getTextColor(context);
    final mutedColor = _theme.getMutedColor(context);
    final borderColor = _theme.getBorderColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
              size: 8.5, weight: FontWeight.w700, color: mutedColor, letterSpacing: 0.5),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: _theme.getBgColor(context),
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              if (prefix != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.05),
                    border: Border(right: BorderSide(color: borderColor, width: 1)),
                  ),
                  child: Text(prefix,
                      style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700, color: mutedColor)),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: AppTextStyles.playfair(
                        size: 14, weight: FontWeight.w800, color: textColor),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  child: Text(suffix,
                      style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: mutedColor)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBottomBox(String label, String val) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          children: [
            Text(label,
                style: AppTextStyles.dmSans(
                    size: 8.5, color: Colors.white54, weight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(val,
                style: AppTextStyles.playfair(
                    size: 12.5,
                    weight: FontWeight.w800,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: _theme.getMutedColor(context)),
        ),
      ],
    );
  }

  Widget _buildScenarioBox(String label, String rateStr, double val, Color color, Color bg, Color borderCol, int years) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: borderCol, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(label.toUpperCase(),
              style: AppTextStyles.dmSans(size: 8.5, color: color, weight: FontWeight.w700, letterSpacing: 0.3)),
          const SizedBox(height: 3),
          Text(rateStr,
              style: AppTextStyles.playfair(size: 15, weight: FontWeight.w800, color: color)),
          const SizedBox(height: 3),
          Text('$years-Yr Projection',
              style: AppTextStyles.dmSans(size: 8.5, color: _theme.getMutedColor(context))),
          const SizedBox(height: 2),
          Text('${CurrencyFormatter.format(val, symbol: r'$').split('.').first}/mo',
              style: AppTextStyles.playfair(size: 11, weight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Text(
        text,
        style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: color, letterSpacing: 0.4),
      ),
    );
  }

  Widget _buildTableCell(String text, Color color, {bool isVal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: Text(
        text,
        style: isVal
            ? AppTextStyles.playfair(size: 11, weight: FontWeight.w800, color: color)
            : AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _buildHistoryGridItem(String year, String val, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(7),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(year.toUpperCase(),
              style: AppTextStyles.dmSans(size: 8, color: const Color(0xFF92400E), weight: FontWeight.w700)),
          const SizedBox(height: 1),
          Text(val,
              style: AppTextStyles.playfair(size: 12.5, weight: FontWeight.w800, color: const Color(0xFF7C2D12))),
        ],
      ),
    );
  }

  Widget _buildDriverBar(String label, String pctStr, Color color, bool isDark) {
    final pct = double.tryParse(pctStr.replaceAll('%', '')) ?? 0.0;
    return Row(
      children: [
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
                size: 9.5, weight: FontWeight.w700, color: _theme.getMutedColor(context)),
          ),
        ),
        Expanded(
          child: Container(
            height: 18,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (pct / 30.0).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  pctStr,
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

  Widget _buildStaticStatCard(String icon, String label, String value, String sub,
      Color cardBg, Color textCol, Color mutedCol, Color borderCol, bool isDark, {Color? valColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(label.toUpperCase(), style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: mutedCol, letterSpacing: 0.4)),
          const SizedBox(height: 3),
          Text(value, style: AppTextStyles.playfair(size: 20, weight: FontWeight.w800, color: valColor ?? textCol)),
          Text(sub, style: AppTextStyles.dmSans(size: 9, color: mutedCol)),
        ],
      ),
    );
  }
}

// Custom Painter for Fee Increase Line Chart
class _FeeIncreaseChartPainter extends CustomPainter {
  final double base;
  final double rate;
  final double incGrowth;
  final int years;
  final double income;
  final Color textColor;
  final Color mutedColor;
  final Color gridColor;
  final bool isDark;

  const _FeeIncreaseChartPainter({
    required this.base,
    required this.rate,
    required this.incGrowth,
    required this.years,
    required this.income,
    required this.textColor,
    required this.mutedColor,
    required this.gridColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;

    final pts = years + 1;
    final List<double> fees = [];
    final List<double> incomes = [];
    for (int i = 0; i < pts; i++) {
      fees.add(base * pow(1 + rate / 100, i));
      incomes.add(income * pow(1 + incGrowth / 100, i));
    }

    final maxFee = fees.reduce(max) * 1.15;
    double px(int i) => 35.0 + i * (W - 55.0) / (pts - 1 > 0 ? pts - 1 : 1.0);
    double py(double v, double maxVal) => H - 20.0 - (v / (maxVal > 0 ? maxVal : 1.0)) * (H - 35.0);

    // Draw grid lines
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = gridColor;

    for (int g = 0; g < 4; g++) {
      final y = H - 20.0 - (g / 3) * (H - 35.0);
      canvas.drawLine(Offset(30.0, y), Offset(W - 10.0, y), gridPaint);
    }

    // HOA fee line (Red)
    final feeLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = const Color(0xFFB91C1C);

    final feePath = Path();
    for (int i = 0; i < pts; i++) {
      final v = fees[i];
      if (i == 0) {
        feePath.moveTo(px(i), py(v, maxFee));
      } else {
        feePath.lineTo(px(i), py(v, maxFee));
      }
    }
    canvas.drawPath(feePath, feeLinePaint);

    // HOA % of income line (Green, dashed)
    const maxPct = 20.0;
    final pctLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFF15803D);

    final List<Offset> pctPoints = [];
    for (int i = 0; i < pts; i++) {
      final pct = incomes[i] > 0 ? (fees[i] / incomes[i] * 100) : 0.0;
      pctPoints.add(Offset(px(i), py(pct, maxPct)));
    }

    // Draw dashed green line
    const dashWidth = 4.0;
    const dashSpace = 3.0;
    for (int i = 0; i < pctPoints.length - 1; i++) {
      final p1 = pctPoints[i];
      final p2 = pctPoints[i + 1];
      final dx = p2.dx - p1.dx;
      final dy = p2.dy - p1.dy;
      final distance = sqrt(dx * dx + dy * dy);
      final steps = (distance / (dashWidth + dashSpace)).floor();

      for (int step = 0; step < steps; step++) {
        final startRatio = step * (dashWidth + dashSpace) / distance;
        final endRatio = (step * (dashWidth + dashSpace) + dashWidth) / distance;
        canvas.drawLine(
          Offset(p1.dx + dx * startRatio, p1.dy + dy * startRatio),
          Offset(p1.dx + dx * min(endRatio, 1.0), p1.dy + dy * min(endRatio, 1.0)),
          pctLinePaint,
        );
      }
    }

    // Dots on HOA fee line
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFB91C1C);

    for (int i = 0; i < pts; i++) {
      canvas.drawCircle(Offset(px(i), py(fees[i], maxFee)), 3.0, dotPaint);
    }

    // X Labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final labelIdxs = [0, pts ~/ 2, pts - 1];

    for (final i in labelIdxs) {
      if (i < pts) {
        textPainter.text = TextSpan(
          text: 'Y$i',
          style: AppTextStyles.dmSans(size: 8, color: mutedColor, weight: FontWeight.w700),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(px(i) - textPainter.width / 2, H - 15.0));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FeeIncreaseChartPainter oldDelegate) {
    return oldDelegate.base != base ||
        oldDelegate.rate != rate ||
        oldDelegate.incGrowth != incGrowth ||
        oldDelegate.years != years ||
        oldDelegate.income != income ||
        oldDelegate.textColor != textColor;
  }
}
