// lib/features/usa/screens/usa_hoa_reserve_fund_health_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAHoaReserveFundHealthScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAHoaReserveFundHealthScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAHoaReserveFundHealthScreen> createState() => _USAHoaReserveFundHealthScreenState();
}

class _USAHoaReserveFundHealthScreenState extends ConsumerState<USAHoaReserveFundHealthScreen> {
  static const _theme = CountryThemes.usa;

  final _currentReservesController = TextEditingController(text: '185000');
  final _fullyFundedController = TextEditingController(text: '400000');
  final _totalUnitsController = TextEditingController(text: '48');
  final _annualContribController = TextEditingController(text: '36000');
  final _nextProjectController = TextEditingController(text: '120000');
  final _yearsOutController = TextEditingController(text: '3');

  bool _showResults = false;
  bool _isCalcDirty = true;

  @override
  void initState() {
    super.initState();
    final list = [
      _currentReservesController,
      _fullyFundedController,
      _totalUnitsController,
      _annualContribController,
      _nextProjectController,
      _yearsOutController,
    ];
    for (final controller in list) {
      controller.addListener(_markDirty);
    }

    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _currentReservesController.text = (inputs['CurrentReserves'] ?? 185000.0).toStringAsFixed(0);
      _fullyFundedController.text = (inputs['FullyFunded'] ?? 400000.0).toStringAsFixed(0);
      _totalUnitsController.text = (inputs['TotalUnits'] ?? 48.0).toStringAsFixed(0);
      _annualContribController.text = (inputs['AnnualContrib'] ?? 36000.0).toStringAsFixed(0);
      _nextProjectController.text = (inputs['NextProject'] ?? 120000.0).toStringAsFixed(0);
      _yearsOutController.text = (inputs['YearsOut'] ?? 3.0).toStringAsFixed(0);
      _showResults = true;
      _isCalcDirty = false;
    }
  }

  @override
  void dispose() {
    final list = [
      _currentReservesController,
      _fullyFundedController,
      _totalUnitsController,
      _annualContribController,
      _nextProjectController,
      _yearsOutController,
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
      _currentReservesController.text = '185000';
      _fullyFundedController.text = '400000';
      _totalUnitsController.text = '48';
      _annualContribController.text = '36000';
      _nextProjectController.text = '120000';
      _yearsOutController.text = '3';
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
    final curr = _val(_currentReservesController);
    final full = _val(_fullyFundedController);
    final units = _val(_totalUnitsController);
    final contrib = _val(_annualContribController);
    final project = _val(_nextProjectController);
    final years = _val(_yearsOutController);

    final pct = min((curr / (full > 0 ? full : 1.0)) * 100, 100.0);
    final shortfall = max(full - curr, 0.0);
    final perUnit = units > 0 ? shortfall / units : 0.0;
    final projBal = curr + contrib * years;
    final assessNeeded = max(project - projBal, 0.0);
    final assessPerUnit = units > 0 ? assessNeeded / units : 0.0;

    final labelCtrl = TextEditingController(text: 'Reserve Fund Analysis');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_hoa_reserve_fund_health_screen'),
      builder: (context) => AlertDialog(
        backgroundColor: _theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Analysis',
            style: AppTextStyles.playfair(
                size: 16, color: _theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: Funding Level: ${pct.toStringAsFixed(1)}% · Shortfall: ${CurrencyFormatter.compact(shortfall, symbol: r'$')}',
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
                hintText: 'Label (e.g. HOA Reserve Health)',
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
          : 'Reserve Fund Analysis';

      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'HOA Reserve Health',
        inputs: {
          'CurrentReserves': curr,
          'FullyFunded': full,
          'TotalUnits': units,
          'AnnualContrib': contrib,
          'NextProject': project,
          'YearsOut': years,
        },
        results: {
          'FundingLevel': pct,
          'Shortfall': shortfall,
          'PerUnitRisk': perUnit,
          'ProjectedBalance': projBal,
          'AssessmentPerUnit': assessPerUnit,
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
    final curr = _val(_currentReservesController);
    final full = _val(_fullyFundedController);
    final units = _val(_totalUnitsController);
    final contrib = _val(_annualContribController);
    final project = _val(_nextProjectController);
    final years = _val(_yearsOutController);

    final pct = min((curr / (full > 0 ? full : 1.0)) * 100, 100.0);
    final shortfall = max(full - curr, 0.0);
    final perUnit = units > 0 ? shortfall / units : 0.0;
    final yrsToFull = shortfall > 0 ? (contrib > 0 ? (shortfall / contrib).ceil() : 99) : 0;
    final projBal = curr + contrib * years;
    final assessNeeded = max(project - projBal, 0.0);
    final assessPerUnit = units > 0 ? assessNeeded / units : 0.0;

    // Rate strip values
    const rateStats = [
      {'label': 'Healthy Level', 'value': '≥70%', 'note': 'CAI Standard'},
      {'label': 'US HOAs', 'value': '70%', 'note': 'Underfunded'},
      {'label': 'Avg Assess.', 'value': '\$3.8K', 'note': 'Special / Unit'},
      {'label': 'Critical Below', 'value': '30%', 'note': 'Danger Zone'},
    ];

    // Status colors & texts
    String statusText = '';
    String riskTitle = '';
    String riskText = '';
    List<Color> heroColors = const [Color(0xFF15803D), Color(0xFF166534)]; // Healthy
    Color riskCardBg = const Color(0xFFF0FDF4);
    Color riskBorderCol = const Color(0x4015803D);
    Color riskTextCol = const Color(0xFF15803D);

    if (pct >= 70) {
      statusText = 'Healthy Reserve — Low Special Assessment Risk';
      riskTitle = '✅ Low Risk — Well-Funded HOA';
      riskText = 'At ${pct.toStringAsFixed(1)}% funded, this HOA meets the CAI 70% threshold. Special assessment risk is low. Lenders (including Fannie Mae) view this favorably. Annual contributions appear adequate relative to long-term needs.';
      heroColors = const [Color(0xFF15803D), Color(0xFF166534)];
      riskCardBg = isDark ? const Color(0xFF0F2618) : const Color(0xFFF0FDF4);
      riskBorderCol = const Color(0x4015803D);
      riskTextCol = const Color(0xFF15803D);
    } else if (pct >= 50) {
      statusText = 'Fair Funding — Moderate Assessment Possible';
      riskTitle = '⚠️ Moderate Risk — Review Major Projects';
      riskText = 'At ${pct.toStringAsFixed(1)}% funded, this HOA is below CAI\'s healthy threshold. A special assessment is possible if a major project arises. Shortfall of ${CurrencyFormatter.format(shortfall, symbol: r'$')} could mean ~${CurrencyFormatter.format(perUnit, symbol: r'$')}/unit in future assessments. Request the full reserve study before closing.';
      heroColors = const [Color(0xFFD97706), Color(0xFF92400E)];
      riskCardBg = isDark ? const Color(0xFF33200B) : const Color(0xFFFFFBEB);
      riskBorderCol = const Color(0x48D97706);
      riskTextCol = const Color(0xFFD97706);
    } else if (pct >= 30) {
      statusText = 'At Risk — High Chance of Special Assessment';
      riskTitle = '🚨 High Risk — Significant Underfunding';
      riskText = 'At ${pct.toStringAsFixed(1)}% funded, this HOA is significantly underfunded. A special assessment of ${CurrencyFormatter.format(perUnit, symbol: r'$')}/unit or higher is highly probable within the next few years. Some lenders may refuse to finance units in HOAs below 50% funded.';
      heroColors = const [Color(0xFFD97706), Color(0xFF92400E)];
      riskCardBg = isDark ? const Color(0xFF33200B) : const Color(0xFFFFFBEB);
      riskBorderCol = const Color(0x48D97706);
      riskTextCol = const Color(0xFFD97706);
    } else {
      statusText = 'Critical — Severe Underfunding Danger';
      riskTitle = '🚨 Critical Risk — Avoid Without Expert Review';
      riskText = 'At only ${pct.toStringAsFixed(1)}% funded, this is a severely underfunded HOA. Fannie Mae and FHA lenders may refuse to approve loans. A large special assessment of ${CurrencyFormatter.format(perUnit, symbol: r'$')}+ per unit is highly likely. Consult a HOA attorney and reserve specialist before purchasing.';
      heroColors = const [Color(0xFFB91C1C), Color(0xFF7F1D1D)];
      riskCardBg = isDark ? const Color(0xFF3B1212) : const Color(0xFFFEF2F2);
      riskBorderCol = const Color(0x40B91C1C);
      riskTextCol = const Color(0xFFB91C1C);
    }

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
                        '⚠️',
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
                                  const Text('⚠️', style: TextStyle(fontSize: 24)),
                                  Text(
                                    'Reserve Fund Health',
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
                              'Funding Level · Risk · Special Assessments',
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
                              color: stat['label'] == 'Healthy Level' || stat['label'] == 'Critical Below' ? const Color(0xFFFCD34D) : Colors.white,
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

          // Content body
          SliverList(
            delegate: SliverChildListDelegate([
              // Calculator Header
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 12, 15, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RESERVE FUND CALCULATOR',
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
                          child: const Text('🏦', style: TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reserve Fund Analyzer',
                                style: AppTextStyles.playfair(
                                    size: 14.5, weight: FontWeight.w800, color: textCol),
                              ),
                              Text(
                                'Calculate funding level & special assessment risk',
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
                        Expanded(child: _buildTextInputRow('Current Reserves', _currentReservesController, prefix: r'$')),
                        const SizedBox(width: 10),
                        Expanded(child: _buildTextInputRow('Fully Funded Amount', _fullyFundedController, prefix: r'$')),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(child: _buildTextInputRow('Total Units in HOA', _totalUnitsController)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildTextInputRow('Annual Reserve Contrib.', _annualContribController, prefix: r'$')),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildTextInputRow('Next Major Project Cost (est.)', _nextProjectController, prefix: r'$'),
                    const SizedBox(height: 12),

                    _buildTextInputRow('Years Until Next Major Project', _yearsOutController, suffix: 'yrs'),
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
                              '🔍 Analyze Reserve Health',
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

                // Hero Result card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: heroColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: heroColors.first.withValues(alpha: 0.25),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RESERVE FUNDING LEVEL',
                        style: AppTextStyles.dmSans(
                            size: 8.5,
                            weight: FontWeight.w700,
                            color: Colors.white70,
                            letterSpacing: 0.6),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${pct.toStringAsFixed(1)}%',
                        style: AppTextStyles.playfair(
                            size: 36, weight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusText,
                        style: AppTextStyles.dmSans(
                            size: 10, color: Colors.white.withValues(alpha: 0.8), weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _buildHeroBottomBox('Shortfall', CurrencyFormatter.format(shortfall, symbol: r'$')),
                          const SizedBox(width: 8),
                          _buildHeroBottomBox('Per Unit Risk', CurrencyFormatter.format(perUnit, symbol: r'$')),
                          const SizedBox(width: 8),
                          _buildHeroBottomBox('Yrs to Funded', yrsToFull > 0 ? '${yrsToFull}y' : '✅ Full'),
                        ],
                      )
                    ],
                  ),
                ),

                // Gauge card
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
                        'Reserve Funding Gauge',
                        style: AppTextStyles.playfair(
                            size: 12.5, weight: FontWeight.w700, color: textCol),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: SizedBox(
                          height: 120,
                          width: 240,
                          child: CustomPaint(
                            painter: _ReserveGaugePainter(
                              pct: pct,
                              textColor: textCol,
                              mutedColor: mutedCol,
                              isDark: isDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildZoneBadge('Healthy', '≥70%', pct >= 70, const Color(0xFFDCFCE7), const Color(0xFF15803D)),
                          const SizedBox(width: 4),
                          _buildZoneBadge('Fair', '50–69%', pct >= 50 && pct < 70, const Color(0xFFFEF9C3), const Color(0xFFD97706)),
                          const SizedBox(width: 4),
                          _buildZoneBadge('At Risk', '30–49%', pct >= 30 && pct < 50, const Color(0xFFFFEDD5), const Color(0xFFEA580C)),
                          const SizedBox(width: 4),
                          _buildZoneBadge('Critical', '<30%', pct < 30, const Color(0xFFFEE2E2), const Color(0xFFB91C1C)),
                        ],
                      )
                    ],
                  ),
                ),

                // Projection Chart Card
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
                        'Reserve Balance vs. Project Deadline',
                        style: AppTextStyles.playfair(
                            size: 12.5, weight: FontWeight.w700, color: textCol),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _ReserveProjectionPainter(
                            curr: curr,
                            contrib: contrib,
                            project: project,
                            years: years.toInt(),
                            textColor: textCol,
                            mutedColor: mutedCol,
                            gridColor: borderCol,
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Risk Callout Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: riskCardBg,
                    border: Border.all(color: riskBorderCol),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        riskTitle,
                        style: AppTextStyles.playfair(
                            size: 12, weight: FontWeight.w800, color: riskTextCol),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        riskText,
                        style: AppTextStyles.dmSans(
                            size: 10, color: mutedCol, height: 1.55),
                      ),
                    ],
                  ),
                ),

                // Sub Stats Grid
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: assessPerUnit > 1000 ? const Color(0x40B91C1C) : borderCol),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('💸', style: TextStyle(fontSize: 22)),
                              const SizedBox(height: 6),
                              Text('Potential Special Assess.'.toUpperCase(),
                                  style: AppTextStyles.dmSans(size: 8.5, color: mutedCol, weight: FontWeight.w700, letterSpacing: 0.4)),
                              const SizedBox(height: 3),
                              Text(
                                assessPerUnit > 0 ? '${CurrencyFormatter.format(assessPerUnit, symbol: r'$')}/unit' : '✅ Covered',
                                style: AppTextStyles.playfair(
                                    size: 15.5,
                                    weight: FontWeight.w800,
                                    color: assessPerUnit > 1000 ? const Color(0xFFB91C1C) : const Color(0xFF15803D)),
                              ),
                              Text('If project hits today', style: AppTextStyles.dmSans(size: 9, color: mutedCol)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderCol),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('📅', style: TextStyle(fontSize: 22)),
                              const SizedBox(height: 6),
                              Text('Projected Balance'.toUpperCase(),
                                  style: AppTextStyles.dmSans(size: 8.5, color: mutedCol, weight: FontWeight.w700, letterSpacing: 0.4)),
                              const SizedBox(height: 3),
                              Text(
                                CurrencyFormatter.compact(projBal, symbol: r'$'),
                                style: AppTextStyles.playfair(size: 15.5, weight: FontWeight.w800, color: textCol),
                              ),
                              Text('At project deadline', style: AppTextStyles.dmSans(size: 9, color: mutedCol)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // National Reserve Statistics
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 18, 15, 8),
                child: Text(
                  'NATIONAL RESERVE STATISTICS',
                  style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                ),
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStaticStatCard('🚨', 'HOAs Underfunded', '70%', 'Below 70% funded (CAI)', cardBg, textCol, mutedCol, const Color(0x38B91C1C), isDark, valColor: const Color(0xFFB91C1C)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStaticStatCard('✅', 'Avg Healthy HOA', '82%', 'Well-run communities', cardBg, textCol, mutedCol, const Color(0x4015803D), isDark, valColor: const Color(0xFF15803D)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStaticStatCard('💰', 'Avg Special Assessment', '\$3.8K', 'Per unit (2023–2024)', cardBg, textCol, mutedCol, borderCol, isDark),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStaticStatCard('⛈️', 'Large Assessments', '\$10K+', 'Seen post-Surfside FL', cardBg, textCol, mutedCol, const Color(0x38B91C1C), isDark, valColor: const Color(0xFFB91C1C)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Checklist
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 18, 15, 8),
                child: Text(
                  'BUYER DUE DILIGENCE CHECKLIST',
                  style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                ),
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                padding: const EdgeInsets.all(15),
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
                    Text(
                      '📋 Reserve Documents to Request',
                      style: AppTextStyles.playfair(size: 13, weight: FontWeight.w800, color: textCol),
                    ),
                    const SizedBox(height: 12),
                    _buildChecklistItem('✓', 'Reserve Study (within 3 years)', 'Professional analysis of all major components & funding timeline', const Color(0xFFDCFCE7), const Color(0xFF15803D), textCol, mutedCol),
                    _buildChecklistItem('✓', 'Last 2 Years\' Financials', 'Audited or reviewed statements from a CPA', const Color(0xFFDCFCE7), const Color(0xFF15803D), textCol, mutedCol),
                    _buildChecklistItem('?', 'Pending Special Assessments', 'Ask HOA board directly — not always in documents', const Color(0xFFFEF9C3), const Color(0xFFD97706), textCol, mutedCol),
                    _buildChecklistItem('?', 'Delinquency Rate', '>15% delinquency = possible Fannie Mae/FHA financing issues', const Color(0xFFFEF9C3), const Color(0xFFD97706), textCol, mutedCol),
                    _buildChecklistItem('!', 'Pending Litigation', 'Any active lawsuits against HOA affect insurability & lenders', const Color(0xFFFEE2E2), const Color(0xFFB91C1C), textCol, mutedCol),
                    _buildChecklistItem('✓', 'Meeting Minutes (12 months)', 'Reveals deferred maintenance, disputes, upcoming projects', const Color(0xFFDCFCE7), const Color(0xFF15803D), textCol, mutedCol),
                  ],
                ),
              ),

              // The Surfside Effect
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
                    Text('💡 The Surfside Effect (2021)',
                        style: AppTextStyles.playfair(size: 11, weight: FontWeight.w800, color: const Color(0xFF4C1D95))),
                    const SizedBox(height: 5),
                    Text(
                      'After the Champlain Towers collapse in Surfside, FL, Florida passed SB 4D requiring milestone inspections and full reserve funding for condos 3+ stories. Many Florida HOAs have issued \$10,000–\$100,000+ special assessments per unit. Always check reserve fund health before making an offer.',
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

  Widget _buildZoneBadge(String label, String val, bool isActive, Color bg, Color textCol) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? Border.all(color: textCol, width: 1.5) : null,
        ),
        child: Column(
          children: [
            Text(label,
                style: AppTextStyles.dmSans(size: 8.5, color: textCol, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(val,
                style: AppTextStyles.playfair(size: 11, weight: FontWeight.w800, color: textCol)),
          ],
        ),
      ),
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

  Widget _buildChecklistItem(String icon, String title, String sub, Color iconBg,
      Color iconText, Color textCol, Color mutedCol) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x120B1D3A), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              icon,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: iconText),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.dmSans(
                        size: 11, weight: FontWeight.w700, color: textCol)),
                Text(sub, style: AppTextStyles.dmSans(size: 9, color: mutedCol)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Gauge Chart
class _ReserveGaugePainter extends CustomPainter {
  final double pct;
  final Color textColor;
  final Color mutedColor;
  final bool isDark;

  const _ReserveGaugePainter({
    required this.pct,
    required this.textColor,
    required this.mutedColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height - 15;
    final radius = min(size.width / 2, size.height) - 15;

    // Draw background arc
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24.0
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2F8);

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      pi,
      pi,
      false,
      bgPaint,
    );

    // Color zones on arc
    final zones = [
      {'start': 0.0, 'end': 0.30, 'color': const Color(0xFFB91C1C)},
      {'start': 0.30, 'end': 0.50, 'color': const Color(0xFFEA580C)},
      {'start': 0.50, 'end': 0.70, 'color': const Color(0xFFD97706)},
      {'start': 0.70, 'end': 1.00, 'color': const Color(0xFF15803D)},
    ];

    final zonePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24.0;

    for (final z in zones) {
      final s = pi + (z['start'] as double) * pi;
      final e = ((z['end'] as double) - (z['start'] as double)) * pi;
      zonePaint.color = z['color'] as Color;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        s,
        e,
        false,
        zonePaint,
      );
    }

    // Needle
    final angle = pi + (pct / 100.0).clamp(0.0, 1.0) * pi;
    final needlePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = textColor;

    final path = Path();
    final cosAngle = cos(angle);
    final sinAngle = sin(angle);

    // Base width perpendicular to needle direction
    const needleBaseWidth = 6.0;
    final bx1 = cx - sinAngle * needleBaseWidth;
    final by1 = cy + cosAngle * needleBaseWidth;
    final bx2 = cx + sinAngle * needleBaseWidth;
    final by2 = cy - cosAngle * needleBaseWidth;

    // Needle tip
    final tx = cx + cosAngle * (radius - 12);
    final ty = cy + sinAngle * (radius - 12);

    path.moveTo(bx1, by1);
    path.lineTo(tx, ty);
    path.lineTo(bx2, by2);
    path.close();

    canvas.drawPath(path, needlePaint);

    // Pin at base
    final pinPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = textColor;
    canvas.drawCircle(Offset(cx, cy), 8, pinPaint);

    // Labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: '0%',
      style: AppTextStyles.dmSans(size: 8, color: mutedColor, weight: FontWeight.w700),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx - radius - 18, cy + 2));

    textPainter.text = TextSpan(
      text: '100%',
      style: AppTextStyles.dmSans(size: 8, color: mutedColor, weight: FontWeight.w700),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx + radius + 2, cy + 2));

    textPainter.text = TextSpan(
      text: '70%',
      style: AppTextStyles.dmSans(size: 8, color: mutedColor, weight: FontWeight.w700),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx + 8, cy - radius + 12));

    // Draw central percentage text
    textPainter.text = TextSpan(
      text: '${pct.toStringAsFixed(1)}%',
      style: AppTextStyles.playfair(size: 20, weight: FontWeight.w800, color: textColor),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx - textPainter.width / 2, cy - 35));

    textPainter.text = TextSpan(
      text: 'Funded',
      style: AppTextStyles.dmSans(size: 8, color: mutedColor, weight: FontWeight.w700),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx - textPainter.width / 2, cy - 15));
  }

  @override
  bool shouldRepaint(covariant _ReserveGaugePainter oldDelegate) {
    return oldDelegate.pct != pct || oldDelegate.isDark != isDark || oldDelegate.textColor != textColor;
  }
}

// Custom Painter for Projections Line Chart
class _ReserveProjectionPainter extends CustomPainter {
  final double curr;
  final double contrib;
  final double project;
  final int years;
  final Color textColor;
  final Color mutedColor;
  final Color gridColor;
  final bool isDark;

  const _ReserveProjectionPainter({
    required this.curr,
    required this.contrib,
    required this.project,
    required this.years,
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
    final finalBal = curr + contrib * years;
    final maxY = max(finalBal, project) * 1.15;

    double px(int i) => 35.0 + i * (W - 55.0) / (pts - 1 > 0 ? pts - 1 : 1.0);
    double py(double v) => H - 25.0 - (v / (maxY > 0 ? maxY : 1.0)) * (H - 45.0);

    // Draw grid lines
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = gridColor;

    for (int g = 0; g < 4; g++) {
      final y = H - 25.0 - (g / 3) * (H - 45.0);
      canvas.drawLine(Offset(35.0, y), Offset(W - 20.0, y), gridPaint);
    }

    // Reserve growth line
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = const Color(0xFF6D28D9);

    final path = Path();
    for (int i = 0; i < pts; i++) {
      final v = curr + contrib * i;
      if (i == 0) {
        path.moveTo(px(i), py(v));
      } else {
        path.lineTo(px(i), py(v));
      }
    }
    canvas.drawPath(path, linePaint);

    // Project cost line (dashed)
    final projectPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFFB91C1C);

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double currentX = 35.0;
    final projectY = py(project);

    while (currentX < W - 20.0) {
      canvas.drawLine(
        Offset(currentX, projectY),
        Offset(min(currentX + dashWidth, W - 20.0), projectY),
        projectPaint,
      );
      currentX += dashWidth + dashSpace;
    }

    // Dots on Reserve line
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF6D28D9);

    for (int i = 0; i < pts; i++) {
      final v = curr + contrib * i;
      canvas.drawCircle(Offset(px(i), py(v)), 3.5, dotPaint);
    }

    // X Labels & Legends
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: 'Project Cost: ${CurrencyFormatter.compact(project, symbol: r'$')}',
      style: AppTextStyles.dmSans(size: 7.5, color: const Color(0xFFB91C1C), weight: FontWeight.w700),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(35.0, projectY - 12.0));

    textPainter.text = TextSpan(
      text: 'Projected Bal: ${CurrencyFormatter.compact(finalBal, symbol: r'$')}',
      style: AppTextStyles.dmSans(size: 7.5, color: const Color(0xFF6D28D9), weight: FontWeight.w700),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(W - 20.0 - textPainter.width, py(finalBal) - 12.0));

    // Years labels on X axis
    for (int i = 0; i < pts; i += max(1, (pts / 5).round())) {
      textPainter.text = TextSpan(
        text: 'Y$i',
        style: AppTextStyles.dmSans(size: 8.5, color: mutedColor, weight: FontWeight.w700),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(px(i) - textPainter.width / 2, H - 18.0));
    }
  }

  @override
  bool shouldRepaint(covariant _ReserveProjectionPainter oldDelegate) {
    return oldDelegate.curr != curr ||
        oldDelegate.contrib != contrib ||
        oldDelegate.project != project ||
        oldDelegate.years != years ||
        oldDelegate.textColor != textColor;
  }
}
