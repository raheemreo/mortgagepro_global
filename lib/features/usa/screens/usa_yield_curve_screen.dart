// lib/features/usa/screens/usa_yield_curve_screen.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../shared/widgets/bottom_nav.dart';

class USAYieldCurveScreen extends ConsumerStatefulWidget {
  const USAYieldCurveScreen({super.key});

  @override
  ConsumerState<USAYieldCurveScreen> createState() => _USAYieldCurveScreenState();
}

class _USAYieldCurveScreenState extends ConsumerState<USAYieldCurveScreen> {
  static const _theme = CountryThemes.usa;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = _theme.getCardColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);
    final borderCol = _theme.getBorderColor(context);
    final bgCol = _theme.getBgColor(context);

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
                        colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72), Color(0xFFB91C1C)],
                        stops: [0.0, 0.55, 1.0],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('📊', style: TextStyle(fontSize: 28)),
                          const SizedBox(height: 2),
                          Text(
                            'Yield Curve',
                            style: AppTextStyles.playfair(size: 18, color: Colors.white, weight: FontWeight.w800),
                          ),
                          Text(
                            '2s10s Spread · Inversion Tracker · Jun 2026',
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
                      Expanded(child: _stripCell('2s10s', '+33bps', 'Spread', const Color(0xFF6EE7B7))),
                      _stripVDivider(),
                      Expanded(child: _stripCell('2-Yr', '4.10%', 'Treasury', const Color(0xFFFCD34D))),
                      _stripVDivider(),
                      Expanded(child: _stripCell('10-Yr', '4.43%', 'Treasury', Colors.white)),
                      _stripVDivider(),
                      Expanded(child: _stripCell('Shape', 'Normal', 'Upward Slope', const Color(0xFF6EE7B7))),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 2s10s Spread Header
                    _buildSectionHeader('2s10s Spread', isLive: true),
                    const SizedBox(height: 8),

                    // Hero Spread Card
                    _buildHeroSpreadCard(isDark),
                    const SizedBox(height: 20),

                    // Yield Curve Shape Chart
                    _buildSectionHeader('Current Yield Curve Shape'),
                    const SizedBox(height: 8),
                    _buildYieldCurveChartCard(isDark, cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 20),

                    // Maturity Yields Table
                    _buildSectionHeader('Full Maturity Rates — Jun 16, 2025'),
                    const SizedBox(height: 8),
                    _buildMaturityRatesCard(isDark, cardBg, textCol, mutedCol, borderCol),
                    const SizedBox(height: 20),

                    // Spread Snapshots Grid
                    _buildSectionHeader('Spread Snapshots'),
                    const SizedBox(height: 8),
                    _buildSpreadSnapshotsCard(isDark),
                    const SizedBox(height: 20),

                    // Recession precedents
                    _buildSectionHeader('Inversion → Recession History'),
                    const SizedBox(height: 8),
                    _buildPrecedentsCard(isDark, cardBg, textCol, mutedCol, borderCol),
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
                'FRED Live',
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

  Widget _buildHeroSpreadCard(bool isDark) {
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
                color: const Color(0xFF0F766E).withValues(alpha: 0.18),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '10-Year Treasury Yield Minus 2-Year Treasury Yield · Key Recession Signal',
                style: AppTextStyles.dmSans(size: 9.5, color: Colors.white.withValues(alpha: 0.48), weight: FontWeight.w700, letterSpacing: 0.8),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+33',
                    style: AppTextStyles.playfair(size: 48, weight: FontWeight.w800, color: const Color(0xFF6EE7B7)),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'bps',
                      style: AppTextStyles.dmSans(size: 16, weight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.65)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _hsPill('✅ Normal — Upward Slope', isNormal: true),
                  const SizedBox(width: 8),
                  _hsPill('Jun 16, 2025'),
                ],
              ),
              const SizedBox(height: 14),
              // Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.8,
                children: [
                  _hsGridBox('2-Yr Yield', '4.10%', const Color(0xFFFCD34D)),
                  _hsGridBox('10-Yr Yield', '4.43%', Colors.white),
                  _hsGridBox('Spread', '+33bps', const Color(0xFF6EE7B7)),
                  _hsGridBox('Inversion End', 'Sep 2024', Colors.white),
                  _hsGridBox('Peak Inv.', '-108bps', const Color(0xFFFCA5A5)),
                  _hsGridBox('Inv. Duration', '~26 mo.', Colors.white),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hsPill(String label, {bool isNormal = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isNormal
            ? const Color(0xFF6EE7B7).withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.12),
        border: Border.all(
          color: isNormal
              ? const Color(0xFF6EE7B7).withValues(alpha: 0.38)
              : Colors.white.withValues(alpha: 0.18),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.dmSans(
          size: 9.5,
          weight: FontWeight.w800,
          color: isNormal ? const Color(0xFF6EE7B7) : Colors.white.withValues(alpha: 0.75),
        ),
      ),
    );
  }

  Widget _hsGridBox(String label, String value, Color color) {
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
            style: AppTextStyles.playfair(size: 13, weight: FontWeight.w800, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildYieldCurveChartCard(bool isDark, Color cardBg, Color textCol, Color mutedCol, Color borderCol) {
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
                'US Treasury Yield Curve — Jun 16, 2025',
                style: AppTextStyles.playfair(size: 12.5, weight: FontWeight.w800, color: textCol),
              ),
              Text(
                'vs. Jun 2024',
                style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w500, color: _theme.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Upward sloping · 2s10s spread: +33bps · Dis-inverted since Sep 2024',
            style: AppTextStyles.dmSans(size: 9.5, color: mutedCol),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: CustomPaint(
              size: const Size(double.infinity, 150),
              painter: _YieldCurveChartPainter(isDark: isDark),
            ),
          ),
          const SizedBox(height: 10),
          // Legend
          Row(
            children: [
              _legendItem('Jun 2025 (Normal)', const Color(0xFF1B3F72), isDashed: false),
              const SizedBox(width: 14),
              _legendItem('Jun 2024 (Inverted)', const Color(0xFFB91C1C), isDashed: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color, {required bool isDashed}) {
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

  Widget _buildMaturityRatesCard(bool isDark, Color cardBg, Color textCol, Color mutedCol, Color borderCol) {
    const maturities = [
      _MaturityRow(term: '1-Mo', rate: 4.30, chg: '−3bps', chgVal: -3),
      _MaturityRow(term: '3-Mo', rate: 4.25, chg: '−2bps', chgVal: -2),
      _MaturityRow(term: '6-Mo', rate: 4.15, chg: '0bps', chgVal: 0),
      _MaturityRow(term: '1-Yr', rate: 4.05, chg: '−1bps', chgVal: -1),
      _MaturityRow(term: '2-Yr', rate: 4.10, chg: '+2bps', chgVal: 2),
      _MaturityRow(term: '5-Yr', rate: 4.15, chg: '+3bps', chgVal: 3),
      _MaturityRow(term: '10-Yr', rate: 4.43, chg: '+4bps', chgVal: 4),
      _MaturityRow(term: '20-Yr', rate: 4.80, chg: '+5bps', chgVal: 5),
      _MaturityRow(term: '30-Yr', rate: 4.90, chg: '+5bps', chgVal: 5),
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
            '📋 US Treasury Yields by Maturity',
            style: AppTextStyles.playfair(size: 12.5, weight: FontWeight.w800, color: textCol),
          ),
          const SizedBox(height: 12),
          ...maturities.map((m) {
            Color chgColor = mutedCol;
            if (m.chgVal > 0) {
              chgColor = const Color(0xFFB91C1C);
            } else if (m.chgVal < 0) {
              chgColor = const Color(0xFF15803D);
            }

            final double widthPct = (m.rate / 6.0).clamp(0.0, 1.0);

            List<Color> barColors = const [Color(0xFF334155), Color(0xFF1E293B)];
            if (m.term == '2-Yr' || m.term == '5-Yr') {
              barColors = const [Color(0xFFD97706), Color(0xFFB45309)];
            } else if (m.term == '10-Yr' || m.term == '20-Yr') {
              barColors = const [Color(0xFF0F766E), Color(0xFF0D9488)];
            } else if (m.term == '30-Yr') {
              barColors = const [Color(0xFFB91C1C), Color(0xFF991B1B)];
            } else if (m.term == '6-Mo' || m.term == '1-Yr') {
              barColors = const [Color(0xFF1B3F72), Color(0xFF0B1D3A)];
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      m.term,
                      style: AppTextStyles.playfair(size: 11, weight: FontWeight.w800, color: textCol),
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
                          widthFactor: widthPct,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: barColors),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 46,
                    child: Text(
                      '${m.rate.toStringAsFixed(2)}%',
                      style: AppTextStyles.playfair(size: 12, weight: FontWeight.w800, color: textCol),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 46,
                    child: Text(
                      m.chg,
                      style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: chgColor),
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
              'Source: US Treasury · FRED · Updated Jun 16, 2025',
              style: AppTextStyles.dmSans(size: 9, color: mutedCol),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpreadSnapshotsCard(bool isDark) {
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
            '2s10s Spread — Key Historical Readings',
            style: AppTextStyles.playfair(size: 12, weight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 3),
          Text(
            '2-Year vs 10-Year Treasury yield differential · Recession signal tracker',
            style: AppTextStyles.dmSans(size: 9.5, color: Colors.white.withValues(alpha: 0.45)),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.1,
            children: [
              _scBox('Today (Jun 2025)', '+33bps', 'Normal curve · Positive', const Color(0xFF6EE7B7)),
              _scBox('Peak Inversion', '−108bps', 'Jul 2023 · Deepest point', const Color(0xFFFCA5A5)),
              _scBox('Dis-inverted', 'Sep 2024', 'After ~26 month inversion', const Color(0xFFFCD34D)),
              _scBox('Pre-COVID', '+60bps', 'Feb 2020 baseline', const Color(0xFF6EE7B7)),
            ],
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.white.withValues(alpha: 0.10),
          ),
          Text(
            'Source: FRED · US Treasury · Updated Jun 16, 2025',
            style: AppTextStyles.dmSans(size: 9, color: Colors.white.withValues(alpha: 0.40)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _scBox(String label, String value, String note, Color valColor) {
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
            style: AppTextStyles.playfair(size: 20, weight: FontWeight.w800, color: valColor),
          ),
          const SizedBox(height: 3),
          Text(
            note,
            style: AppTextStyles.dmSans(size: 8.5, color: Colors.white.withValues(alpha: 0.40)),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPrecedentsCard(bool isDark, Color cardBg, Color textCol, Color mutedCol, Color borderCol) {
    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFB91C1C), Color(0xFF991B1B)]),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ Yield Curve Inversion Precedents',
                        style: AppTextStyles.playfair(size: 12.5, weight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Every major 2s10s inversion since 1980 · Recession followed',
                        style: AppTextStyles.dmSans(size: 9, color: Colors.white.withValues(alpha: 0.50)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _invRow('1978–80', 'Pre-Volcker Shock', 'Deep inversion · Recession followed 1980 & 1981', 'Recession', borderCol, textCol, mutedCol, isRec: true),
          _invRow('1988–89', 'S&L Crisis Era', 'Mild inversion · 1990–91 recession followed', 'Recession', borderCol, textCol, mutedCol, isRec: true),
          _invRow('1998–2000', 'Dot-Com Bubble', 'Inversion → 2001 recession · 18-month lag', 'Recession', borderCol, textCol, mutedCol, isRec: true),
          _invRow('2005–07', 'Pre-GFC', 'Inversion 2006 → GFC 2008 · 24-month lag', 'Recession', borderCol, textCol, mutedCol, isRec: true),
          _invRow('2022–24', 'Inflation Shock Era', '26 months inverted · Dis-inverted Sep 2024 · No recession yet', 'Pending', borderCol, textCol, mutedCol, isRec: false, isLast: true),
        ],
      ),
    );
  }

  Widget _invRow(
    String period,
    String name,
    String note,
    String result,
    Color borderCol,
    Color textCol,
    Color mutedCol, {
    required bool isRec,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: borderCol)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              period,
              style: AppTextStyles.playfair(size: 11, weight: FontWeight.w800, color: textCol),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w700, color: textCol),
                ),
                const SizedBox(height: 2),
                Text(
                  note,
                  style: AppTextStyles.dmSans(size: 9, color: mutedCol),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            result,
            style: AppTextStyles.dmSans(
              size: 11,
              weight: FontWeight.w800,
              color: isRec ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}

class _MaturityRow {
  final String term;
  final double rate;
  final String chg;
  final int chgVal;

  const _MaturityRow({required this.term, required this.rate, required this.chg, required this.chgVal});
}

class _YieldCurveChartPainter extends CustomPainter {
  final bool isDark;
  const _YieldCurveChartPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grid lines
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)
      ..strokeWidth = 1;

    // Grid lines at 20, 55, 90, 125 representing 5.5%, 4.5%, 3.5%, 2.5%
    for (final yVal in [20.0, 55.0, 90.0, 125.0]) {
      final y = yVal / 150.0 * h;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Y Labels
    final labelStyle = TextStyle(
      color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
      fontSize: 7.5,
    );
    final yLabels = ['5.5%', '4.5%', '3.5%', '2.5%'];
    final yVals = [20.0, 55.0, 90.0, 125.0];
    for (int i = 0; i < yLabels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: yLabels[i], style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, (yVals[i] / 150.0) * h - 10));
    }

    // X axis labels indices & positions
    // x positions: 28 65 100 135 165 195 225 255 285 330 365
    const xLabels = [
      ('1M', 28.0),
      ('3M', 65.0),
      ('6M', 100.0),
      ('1Y', 135.0),
      ('2Y', 165.0),
      ('3Y', 195.0),
      ('5Y', 225.0),
      ('7Y', 255.0),
      ('10Y', 285.0),
      ('20Y', 330.0),
      ('30Y', 365.0),
    ];
    for (final xl in xLabels) {
      final tp = TextPainter(
        text: TextSpan(text: xl.$1, style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((xl.$2 / 380.0) * w - tp.width / 2, h - 12));
    }

    // Yield curve data paths scaled to dynamic width/height
    // Jun 2024 (inverted):
    final curve2024Points = [
      Offset((28.0 / 380.0) * w, (27.0 / 150.0) * h),
      Offset((65.0 / 380.0) * w, (25.0 / 150.0) * h),
      Offset((100.0 / 380.0) * w, (27.0 / 150.0) * h),
      Offset((135.0 / 380.0) * w, (35.0 / 150.0) * h),
      Offset((165.0 / 380.0) * w, (49.0 / 150.0) * h),
      Offset((195.0 / 380.0) * w, (57.0 / 150.0) * h),
      Offset((225.0 / 380.0) * w, (62.0 / 150.0) * h),
      Offset((255.0 / 380.0) * w, (62.0 / 150.0) * h),
      Offset((285.0 / 380.0) * w, (68.0 / 150.0) * h),
      Offset((330.0 / 380.0) * w, (60.0 / 150.0) * h),
      Offset((365.0 / 380.0) * w, (64.0 / 150.0) * h),
    ];

    // Jun 2025 (normal):
    final curve2025Points = [
      Offset((28.0 / 380.0) * w, (70.0 / 150.0) * h),
      Offset((65.0 / 380.0) * w, (72.0 / 150.0) * h),
      Offset((100.0 / 380.0) * w, (76.0 / 150.0) * h),
      Offset((135.0 / 380.0) * w, (80.0 / 150.0) * h),
      Offset((165.0 / 380.0) * w, (78.0 / 150.0) * h),
      Offset((195.0 / 380.0) * w, (80.0 / 150.0) * h),
      Offset((225.0 / 380.0) * w, (76.0 / 150.0) * h),
      Offset((255.0 / 380.0) * w, (71.0 / 150.0) * h),
      Offset((285.0 / 380.0) * w, (65.0 / 150.0) * h),
      Offset((330.0 / 380.0) * w, (49.0 / 150.0) * h),
      Offset((365.0 / 380.0) * w, (45.0 / 150.0) * h),
    ];

    // Draw Inverted Curve (Red dashed line)
    final path2024 = Path()..moveTo(curve2024Points.first.dx, curve2024Points.first.dy);
    for (final p in curve2024Points.skip(1)) {
      path2024.lineTo(p.dx, p.dy);
    }
    final paint2024 = Paint()
      ..color = const Color(0xFFB91C1C).withValues(alpha: 0.70)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Custom dash path mapping
    final dashPath = _createDashedPath(path2024, 5.0, 3.0);
    canvas.drawPath(dashPath, paint2024);

    // Draw Normal Curve Area Fill (Blue gradient)
    final gradientRect = Rect.fromLTWH(0, 0, w, h);
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1B3F72).withValues(alpha: 0.25),
          const Color(0xFF1B3F72).withValues(alpha: 0.02),
        ],
      ).createShader(gradientRect);

    final fillPath = Path()..moveTo(curve2025Points.first.dx, curve2025Points.first.dy);
    for (final p in curve2025Points.skip(1)) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(curve2025Points.last.dx, (140.0 / 150.0) * h);
    fillPath.lineTo(curve2025Points.first.dx, (140.0 / 150.0) * h);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Draw Normal Curve Line (Solid blue line)
    final path2025 = Path()..moveTo(curve2025Points.first.dx, curve2025Points.first.dy);
    for (final p in curve2025Points.skip(1)) {
      path2025.lineTo(p.dx, p.dy);
    }
    final paint2025 = Paint()
      ..color = const Color(0xFF1B3F72)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path2025, paint2025);

    // Draw 2Y and 10Y dots
    final dot2Y = curve2025Points[4]; // 2Y
    final dot10Y = curve2025Points[8]; // 10Y

    canvas.drawCircle(dot2Y, 4.0, Paint()..color = const Color(0xFFD97706));
    canvas.drawCircle(dot10Y, 4.0, Paint()..color = const Color(0xFF1B3F72));

    // Label texts for 2Y & 10Y dots
    final textPainter2Y = TextPainter(
      text: const TextSpan(
        text: '2Y 4.10%',
        style: TextStyle(color: Color(0xFFD97706), fontSize: 7.5, fontWeight: FontWeight.bold),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    textPainter2Y.paint(canvas, Offset(dot2Y.dx - 18, dot2Y.dy + 8));

    final textPainter10Y = TextPainter(
      text: const TextSpan(
        text: '10Y 4.43%',
        style: TextStyle(color: Color(0xFF1B3F72), fontSize: 7.5, fontWeight: FontWeight.bold),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    textPainter10Y.paint(canvas, Offset(dot10Y.dx - 18, dot10Y.dy - 12));
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
  bool shouldRepaint(covariant _YieldCurveChartPainter old) => old.isDark != isDark;
}
