// lib/features/usa/screens/usa_cpi_vs_fed_rate_screen.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../providers/usa_rates_provider.dart';
import '../../../shared/widgets/bottom_nav.dart';

class USACpiVsFedRateScreen extends ConsumerStatefulWidget {
  const USACpiVsFedRateScreen({super.key});

  @override
  ConsumerState<USACpiVsFedRateScreen> createState() => _USACpiVsFedRateScreenState();
}

class _USACpiVsFedRateScreenState extends ConsumerState<USACpiVsFedRateScreen> {
  static const _theme = CountryThemes.usa;

  void _saveSnapshot(double rawFedRate) async {
    final nowStr = DateFormat('MMM d, yyyy').format(DateTime.now());
    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'CPI vs Fed Rate',
      label: 'CPI vs Fed Rate Snapshot - $nowStr',
      inputs: {
        'CPI_YoY': 2.3,
        'Core_CPI': 2.8,
        'FedFunds': rawFedRate,
      },
      results: {
        'RealRate': rawFedRate - 2.3,
        'RealRateCore': rawFedRate - 2.8,
        'GapToTarget': 0.3,
      },
      currencyCode: 'USD',
    );

    await ref.read(savedProvider.notifier).save(calc);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Snapshot Saved to Bookmarks!',
            style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700),
          ),
          backgroundColor: _theme.primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _deleteSnapshot(SavedCalc calc) async {
    await ref.read(savedProvider.notifier).delete(calc.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🗑️ Snapshot Deleted!',
            style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700),
          ),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
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

    final fedFundsAsync = ref.watch(fredFedFundsProvider);
    final rawFedFunds = fedFundsAsync.valueOrNull?.value ?? 5.33;
    final liveFundsStr = '${rawFedFunds.toStringAsFixed(2)}%';

    final realRate = rawFedFunds - 2.3;
    final realRateStr = '${realRate >= 0 ? '+' : ''}${realRate.toStringAsFixed(2)}%';

    // Saved snapshots filter
    final savedList = ref.watch(savedProvider);
    final cpiSnapshots = savedList.where((c) => c.calcType == 'CPI vs Fed Rate').toList();

    return Scaffold(
      backgroundColor: bgCol,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Header
              SliverAppBar(
                expandedHeight: 150,
                pinned: true,
                backgroundColor: Colors.transparent,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(10),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                    ),
                    alignment: Alignment.center,
                    child: const Text('⚠️', style: TextStyle(fontSize: 16)),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72), Color(0xFFD97706)],
                        stops: [0.0, 0.55, 1.0],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('💵', style: TextStyle(fontSize: 28)),
                          const SizedBox(height: 2),
                          Text(
                            'CPI vs Fed Rate',
                            style: AppTextStyles.playfair(size: 18, color: Colors.white, weight: FontWeight.w800),
                          ),
                          Text(
                            'Inflation Gap · Real Rate · BLS & FRED · Jun 2026',
                            style: AppTextStyles.dmSans(size: 9, color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Rate Strip
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1D3A).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _stripCell('CPI YoY', '2.3%', 'Apr 2025', const Color(0xFFFCA5A5))),
                      _stripVDivider(),
                      Expanded(child: _stripCell('Core CPI', '2.8%', 'Ex-Food/Energy', const Color(0xFFFCD34D))),
                      _stripVDivider(),
                      Expanded(child: _stripCell('Fed Rate', liveFundsStr, 'Effective', const Color(0xFF6EE7B7))),
                      _stripVDivider(),
                      Expanded(child: _stripCell('Real Rate', realRateStr, 'Restrictive', Colors.white)),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Inflation Gap Header
                    _buildSectionHeader('Inflation Gap', isLive: true),
                    const SizedBox(height: 8),

                    // Hero Gap Card
                    _buildHeroGapCard(isDark, rawFedFunds, realRateStr),
                    const SizedBox(height: 20),

                    // 12-Month CPI vs Fed Rate History Chart
                    _buildSectionHeader('12-Month CPI vs Fed Rate History'),
                    const SizedBox(height: 8),
                    _buildChartCard(isDark, cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 20),

                    // CPI Component Breakdown
                    _buildSectionHeader('CPI Component Breakdown — Apr 2025'),
                    const SizedBox(height: 8),
                    _buildBreakdownCard(isDark, cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 20),

                    // Real Rate Analysis
                    _buildSectionHeader('Real Rate Analysis'),
                    const SizedBox(height: 8),
                    _buildRealRateCard(isDark, rawFedFunds),
                    const SizedBox(height: 20),

                    // Save Snapshot Card
                    _buildSectionHeader('Save Snapshot'),
                    const SizedBox(height: 8),
                    _buildSaveSnapshotCard(isDark, cardBg, textCol, mutedCol, borderCol, rawFedFunds, cpiSnapshots),
                  ]),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNav(
              activeIndex: 1,
              activeColor: _theme.primaryColor,
              countryIcon: _theme.flag,
              countryLabel: 'USA',
              countryRoute: '/usa',
            ),
          ),
        ],
      ),
    );
  }

  Widget _stripVDivider() => Container(
      width: 1, height: 30, color: Colors.white.withValues(alpha: 0.14));

  Widget _stripCell(String label, String value, String note, Color valColor) {
    return Column(
      children: [
        Text(label.toUpperCase(),
            style: AppTextStyles.dmSans(size: 8.5, color: Colors.white.withValues(alpha: 0.48), weight: FontWeight.w700, letterSpacing: 0.4)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyles.dmSans(size: 15, weight: FontWeight.w800, color: valColor)),
        Text(note,
            style: AppTextStyles.dmSans(size: 8, color: Colors.white.withValues(alpha: 0.38))),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {bool isLive = false, String? tagText}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 10.5,
            weight: FontWeight.w800,
            color: _theme.getMutedColor(context),
            letterSpacing: 1.0,
          ),
        ),
        if (isLive)
          Row(
            children: [
              _liveDot(),
              const SizedBox(width: 4),
              Text(
                'BLS Live',
                style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w600, color: _theme.primaryColor),
              ),
            ],
          ),
        if (tagText != null)
          Text(
            tagText,
            style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w600, color: _theme.primaryColor),
          ),
      ],
    );
  }

  Widget _liveDot() {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: Color(0xFF22C55E),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildHeroGapCard(bool isDark, double rawFedFunds, String realRateStr) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
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
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD97706).withValues(alpha: 0.18),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CPI Inflation vs Federal Funds Rate · Policy Gap Analysis · Apr 2025',
                style: AppTextStyles.dmSans(size: 9.5, color: Colors.white.withValues(alpha: 0.48), weight: FontWeight.w700, letterSpacing: 0.8),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                      ),
                      child: Column(
                        children: [
                          Text('CPI INFLATION', style: AppTextStyles.dmSans(size: 9, color: Colors.white.withValues(alpha: 0.48), weight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('2.3%', style: AppTextStyles.playfair(size: 28, weight: FontWeight.w800, color: const Color(0xFFFCA5A5))),
                          const SizedBox(height: 2),
                          Text('Apr 2025 YoY', style: AppTextStyles.dmSans(size: 8.5, color: Colors.white.withValues(alpha: 0.40))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('vs', style: AppTextStyles.playfair(size: 18, color: Colors.white.withValues(alpha: 0.35))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                      ),
                      child: Column(
                        children: [
                          Text('FED FUNDS RATE', style: AppTextStyles.dmSans(size: 9, color: Colors.white.withValues(alpha: 0.48), weight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('${rawFedFunds.toStringAsFixed(2)}%', style: AppTextStyles.playfair(size: 28, weight: FontWeight.w800, color: const Color(0xFFFCD34D))),
                          const SizedBox(height: 2),
                          Text('Effective EFFR', style: AppTextStyles.dmSans(size: 8.5, color: Colors.white.withValues(alpha: 0.40))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Policy Gap (Real Rate)', style: AppTextStyles.dmSans(size: 10, color: Colors.white.withValues(alpha: 0.55), weight: FontWeight.bold)),
                        Text('Fed is significantly restrictive above inflation', style: AppTextStyles.dmSans(size: 9, color: Colors.white.withValues(alpha: 0.40))),
                      ],
                    ),
                    Text(
                      realRateStr,
                      style: AppTextStyles.playfair(size: 18, weight: FontWeight.w800, color: const Color(0xFFFCD34D)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.8,
                children: [
                  _hgBox('Core CPI', '2.8%', const Color(0xFFFCD34D)),
                  _hgBox('PCE YoY', '2.3%', const Color(0xFFFCA5A5)),
                  _hgBox('Core PCE', '2.6%', const Color(0xFFFCA5A5)),
                  _hgBox('Fed Target', '2.0%', const Color(0xFF6EE7B7)),
                  _hgBox('Gap to Target', '+0.3%', const Color(0xFFFCA5A5)),
                  _hgBox('Stance', rawFedFunds - 2.3 > 0.5 ? 'Restrict.' : 'Accom.', const Color(0xFF6EE7B7)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hgBox(String label, String value, Color valColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(size: 8.5, color: Colors.white.withValues(alpha: 0.45), letterSpacing: 0.3),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.playfair(size: 13, weight: FontWeight.w800, color: valColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(bool isDark, Color cardBg, Color textCol, Color mutedCol, Color borderCol) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
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
                'CPI Inflation & Fed Funds Rate — 2021–2025',
                style: AppTextStyles.playfair(size: 12.5, weight: FontWeight.w800, color: textCol),
              ),
              Text(
                'FRED · BLS',
                style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w500, color: _theme.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Shaded gap = real rate (above zero = restrictive policy)',
            style: AppTextStyles.dmSans(size: 9.5, color: mutedCol),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 135,
            child: CustomPaint(
              size: const Size(double.infinity, 135),
              painter: _CpiFedRateChartPainter(isDark: isDark),
            ),
          ),
          const SizedBox(height: 10),
          // Legend
          Row(
            children: [
              _chartLegendItem('CPI YoY', const Color(0xFFB91C1C)),
              const SizedBox(width: 16),
              _chartLegendItem('Fed Funds Rate', const Color(0xFF1B3F72)),
              const SizedBox(width: 16),
              _chartLegendItem('2% Fed Target', const Color(0xFF15803D), isDashed: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartLegendItem(String label, Color color, {bool isDashed = false}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: isDashed ? null : color,
            borderRadius: BorderRadius.circular(2),
          ),
          child: isDashed
              ? Row(
                  children: [
                    Container(width: 3, height: 3, color: color),
                    const SizedBox(width: 2),
                    Container(width: 3, height: 3, color: color),
                    const SizedBox(width: 2),
                    Container(width: 2, height: 3, color: color),
                  ],
                )
              : null,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.dmSans(size: 9, color: _theme.getMutedColor(context)),
        ),
      ],
    );
  }

  Widget _buildBreakdownCard(bool isDark, Color cardBg, Color textCol, Color mutedCol, Color borderCol) {
    const components = [
      _ComponentRow(label: 'Shelter', rate: 4.9, chgText: '↓ slow', barColors: [Color(0xFFB91C1C), Color(0xFF991B1B)]),
      _ComponentRow(label: 'Food at Home', rate: 1.7, chgText: '↓ easing', barColors: [Color(0xFFD97706), Color(0xFFB45309)]),
      _ComponentRow(label: 'Food Away Home', rate: 3.4, chgText: '↑ sticky', barColors: [Color(0xFFD97706), Color(0xFFB45309)]),
      _ComponentRow(label: 'Energy', rate: -3.7, chgText: '↓ defla.', barColors: [Color(0xFF15803D), Color(0xFF166534)]),
      _ComponentRow(label: 'New Vehicles', rate: -0.7, chgText: '↓ defla.', barColors: [Color(0xFF0F766E), Color(0xFF0D9488)]),
      _ComponentRow(label: 'Medical Care', rate: 3.1, chgText: '→ stable', barColors: [Color(0xFF334155), Color(0xFF1E293B)]),
      _ComponentRow(label: 'Apparel', rate: 1.2, chgText: '→ flat', barColors: [Color(0xFF1B3F72), Color(0xFF0B1D3A)]),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📈 Inflation by Category (YoY %)',
            style: AppTextStyles.playfair(size: 12.5, weight: FontWeight.w800, color: textCol),
          ),
          const SizedBox(height: 12),
          ...components.map((c) {
            // Normalize rates for bar: range is -5% to +10%. Shift by +5% to get factor 0-15%.
            final double valueToNormalize = c.rate + 5.0; // 0 to 15
            final double widthFactor = (valueToNormalize / 15.0).clamp(0.0, 1.0);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 108,
                    child: Text(
                      c.label,
                      style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: mutedCol),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: widthFactor,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: c.barColors),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 42,
                    child: Text(
                      '${c.rate >= 0 ? '' : ''}${c.rate.toStringAsFixed(1)}%',
                      style: AppTextStyles.playfair(size: 11, weight: FontWeight.w800, color: textCol),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 38,
                    child: Text(
                      c.chgText,
                      style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w700, color: mutedCol),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 10),
            color: borderCol,
          ),
          Center(
            child: Text(
              'Source: Bureau of Labor Statistics · CPI-U · April 2025',
              style: AppTextStyles.dmSans(size: 9, color: mutedCol),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealRateCard(bool isDark, double rawFedFunds) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
        ),
        borderRadius: BorderRadius.circular(18),
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
            '📐 Real Interest Rate Breakdown',
            style: AppTextStyles.playfair(size: 12, weight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 3),
          Text(
            'Federal Funds Rate minus inflation measures · Restrictive = positive real rate',
            style: AppTextStyles.dmSans(size: 9.5, color: Colors.white.withValues(alpha: 0.45)),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.85,
            children: [
              _rcBox('Real Rate (CPI)', '+${(rawFedFunds - 2.3).toStringAsFixed(2)}%', 'EFFR minus 2.3% CPI · Most restrictive in 15 yrs'),
              _rcBox('Real Rate (Core)', '+${(rawFedFunds - 2.8).toStringAsFixed(2)}%', 'EFFR minus 2.8% Core CPI'),
              _rcBox('Real Rate (PCE)', '+${(rawFedFunds - 2.3).toStringAsFixed(2)}%', 'EFFR minus 2.3% PCE · Fed\'s preferred gauge'),
              _rcBox('Neutral Real Rate', '~0.5%', 'r* estimate · FOMC long-run neutral', isGold: true),
            ],
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.white.withValues(alpha: 0.10),
          ),
          Text(
            'Source: BLS · BEA · FRED · Jun 16, 2025',
            style: AppTextStyles.dmSans(size: 9, color: Colors.white.withValues(alpha: 0.40)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _rcBox(String label, String value, String note, {bool isGold = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(size: 8.5, color: Colors.white.withValues(alpha: 0.45), letterSpacing: 0.3),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.playfair(size: 20, weight: FontWeight.w800, color: isGold ? const Color(0xFFFCD34D) : const Color(0xFF6EE7B7)),
          ),
          const SizedBox(height: 3),
          Text(
            note,
            style: AppTextStyles.dmSans(size: 8, color: Colors.white.withValues(alpha: 0.35)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveSnapshotCard(
    bool isDark,
    Color cardBg,
    Color textCol,
    Color mutedCol,
    Color borderCol,
    double rawFedFunds,
    List<SavedCalc> snapshots,
  ) {
    final realRate = rawFedFunds - 2.3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💾 Save Current Reading',
            style: AppTextStyles.playfair(size: 12.5, weight: FontWeight.w800, color: textCol),
          ),
          const SizedBox(height: 4),
          Text(
            'Save today\'s CPI vs Fed Rate snapshot to track inflation progress over time',
            style: AppTextStyles.dmSans(size: 9.5, color: mutedCol),
          ),
          const SizedBox(height: 12),
          // Snapshot container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              children: [
                _ssRow('Date', DateFormat('MMM d, yyyy').format(DateTime.now()), mutedCol, textCol),
                _ssRow('CPI (Apr 2025)', '2.3% YoY', mutedCol, textCol),
                _ssRow('Core CPI', '2.8% YoY', mutedCol, textCol),
                _ssRow('Fed Funds Rate', '${rawFedFunds.toStringAsFixed(2)}% (4.25–4.50%)', mutedCol, textCol),
                _ssRow('Real Rate', '+${realRate.toStringAsFixed(2)}% (Restrictive)', mutedCol, textCol),
                _ssRow('Gap to 2% Target', '+0.3%', mutedCol, textCol),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _saveSnapshot(rawFedFunds),
            icon: const Text('💾', style: TextStyle(fontSize: 14)),
            label: Text(
              'Save This Snapshot',
              style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _theme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              minimumSize: const Size.fromHeight(42),
            ),
          ),
          const SizedBox(height: 14),
          // Snapshots List
          if (snapshots.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('No saved snapshots yet', style: AppTextStyles.dmSans(size: 10, color: mutedCol)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshots.length,
              itemBuilder: (context, idx) {
                final snap = snapshots[idx];
                final snapFedVal = snap.inputs['FedFunds']?.toDouble() ?? 5.33;
                final snapRealVal = snap.results['RealRate']?.toDouble() ?? (snapFedVal - 2.3);
                final savedDateText = snap.label.replaceFirst('CPI vs Fed Rate Snapshot - ', '');

                return Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderCol),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$savedDateText · CPI 2.3% · Fed ${snapFedVal.toStringAsFixed(2)}%',
                              style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: textCol),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Real Rate +${snapRealVal.toStringAsFixed(2)}% · Core CPI 2.8%',
                              style: AppTextStyles.dmSans(size: 9.5, color: mutedCol),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Color(0xFFB91C1C), size: 18),
                        onPressed: () => _deleteSnapshot(snap),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _ssRow(String label, String value, Color labelColor, Color valColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w600, color: labelColor)),
          Text(value, style: AppTextStyles.playfair(size: 11, weight: FontWeight.w800, color: valColor)),
        ],
      ),
    );
  }
}

class _ComponentRow {
  final String label;
  final double rate;
  final String chgText;
  final List<Color> barColors;

  const _ComponentRow({required this.label, required this.rate, required this.chgText, required this.barColors});
}

class _CpiFedRateChartPainter extends CustomPainter {
  final bool isDark;
  const _CpiFedRateChartPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grid lines at 18, 45, 72, 99 representing 10%, 7.5%, 5.0%, 2.5%
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)
      ..strokeWidth = 1;

    final yGridVals = [18.0, 45.0, 72.0, 99.0];
    for (final yVal in yGridVals) {
      final y = yVal / 135.0 * h;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Y Labels
    final labelStyle = TextStyle(
      color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
      fontSize: 7.5,
    );
    final yLabels = ['10%', '7.5%', '5%', '2.5%'];
    for (int i = 0; i < yLabels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: yLabels[i], style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, (yGridVals[i] / 135.0) * h - 10));
    }

    // X axis labels
    const xLabels = [
      ('Jan\'21', 20.0),
      ('Jan\'22', 85.0),
      ('Jan\'23', 152.0),
      ('Jan\'24', 220.0),
      ('Jan\'25', 288.0),
    ];
    for (final xl in xLabels) {
      final tp = TextPainter(
        text: TextSpan(text: xl.$1, style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((xl.$2 / 380.0) * w - tp.width / 2, h - 12));
    }

    // Paths details
    // CPI Path: Jan'21=1.4(111), Jun'21=5.4(68), Dec'21=7.0(50), Jun'22=9.1(28), Dec'22=6.5(56), Jun'23=3.0(94), Dec'23=3.4(89), Jun'24=3.0(94), Dec'24=2.7(97), Jun'25=2.3(101)
    final cpiPoints = [
      Offset((25.0 / 380.0) * w, (111.0 / 135.0) * h),
      Offset((55.0 / 380.0) * w, (80.0 / 135.0) * h),
      Offset((85.0 / 380.0) * w, (68.0 / 135.0) * h),
      Offset((115.0 / 380.0) * w, (50.0 / 135.0) * h),
      Offset((148.0 / 380.0) * w, (28.0 / 135.0) * h), // peak 9.1%
      Offset((152.0 / 380.0) * w, (56.0 / 135.0) * h),
      Offset((180.0 / 380.0) * w, (94.0 / 135.0) * h),
      Offset((220.0 / 380.0) * w, (89.0 / 135.0) * h),
      Offset((260.0 / 380.0) * w, (94.0 / 135.0) * h),
      Offset((295.0 / 380.0) * w, (97.0 / 135.0) * h),
      Offset((340.0 / 380.0) * w, (101.0 / 135.0) * h),
      Offset((370.0 / 380.0) * w, (101.0 / 135.0) * h),
    ];

    // Fed Rate Path:
    // Jan'21=0.09(125), Mar'22=0.33(122), Jun'22=1.58(109), Sep'22=3.08(93), Dec'22=4.33(80), Jun'23=5.08(72), Sep'23=5.33(69), Dec'23=5.33(69), Jun'24=5.33(69), Sep'24=4.83(74), Dec'24=4.33(80), Jun'25=4.33(80)
    final fedPoints = [
      Offset((25.0 / 380.0) * w, (125.0 / 135.0) * h),
      Offset((85.0 / 380.0) * w, (125.0 / 135.0) * h),
      Offset((105.0 / 380.0) * w, (122.0 / 135.0) * h),
      Offset((130.0 / 380.0) * w, (109.0 / 135.0) * h),
      Offset((148.0 / 380.0) * w, (93.0 / 135.0) * h),
      Offset((152.0 / 380.0) * w, (80.0 / 135.0) * h),
      Offset((180.0 / 380.0) * w, (72.0 / 135.0) * h),
      Offset((220.0 / 380.0) * w, (69.0 / 135.0) * h),
      Offset((260.0 / 380.0) * w, (69.0 / 135.0) * h),
      Offset((280.0 / 380.0) * w, (74.0 / 135.0) * h),
      Offset((295.0 / 380.0) * w, (80.0 / 135.0) * h),
      Offset((340.0 / 380.0) * w, (80.0 / 135.0) * h),
      Offset((370.0 / 380.0) * w, (80.0 / 135.0) * h),
    ];

    // CPI Line (Red)
    final cpiPath = Path()..moveTo(cpiPoints.first.dx, cpiPoints.first.dy);
    for (final p in cpiPoints.skip(1)) {
      cpiPath.lineTo(p.dx, p.dy);
    }
    final cpiPaint = Paint()
      ..color = const Color(0xFFB91C1C)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(cpiPath, cpiPaint);

    // Fed Rate Line (Blue)
    final fedPath = Path()..moveTo(fedPoints.first.dx, fedPoints.first.dy);
    for (final p in fedPoints.skip(1)) {
      fedPath.lineTo(p.dx, p.dy);
    }
    final fedPaint = Paint()
      ..color = const Color(0xFF1B3F72)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(fedPath, fedPaint);

    // Current Dots
    canvas.drawCircle(cpiPoints.last, 4.0, Paint()..color = const Color(0xFFB91C1C));
    canvas.drawCircle(fedPoints.last, 4.0, Paint()..color = const Color(0xFF1B3F72));

    // Peak CPI Dot & Label
    final peakPt = cpiPoints[4]; // 9.1%
    canvas.drawCircle(peakPt, 4.0, Paint()..color = const Color(0xFFD97706));
    final peakTp = TextPainter(
      text: const TextSpan(
        text: 'PEAK 9.1%',
        style: TextStyle(color: Color(0xFFD97706), fontSize: 7.5, fontWeight: FontWeight.bold),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    peakTp.paint(canvas, Offset(peakPt.dx - 38, peakPt.dy - 14));

    // 2% target line (y=104)
    final targetY = (104.0 / 135.0) * h;
    final targetPaint = Paint()
      ..color = const Color(0xFF15803D).withValues(alpha: 0.60)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final targetPath = Path()
      ..moveTo(0, targetY)
      ..lineTo(w, targetY);

    final dashPath = _createDashedPath(targetPath, 4.0, 3.0);
    canvas.drawPath(dashPath, targetPaint);

    final targetTp = TextPainter(
      text: const TextSpan(
        text: '2% target',
        style: TextStyle(color: Color(0xFF15803D), fontSize: 7),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    targetTp.paint(canvas, Offset(w - targetTp.width - 10, targetY - 10));
  }

  Path _createDashedPath(Path sourcePath, double dashLength, double gapLength) {
    final Path dest = Path();
    for (final ui.PathMetric metric in sourcePath.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = draw ? dashLength : gapLength;
        if (draw) {
          dest.addPath(metric.extractPath(distance, distance + len), Offset.zero);
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _CpiFedRateChartPainter old) => old.isDark != isDark;
}
