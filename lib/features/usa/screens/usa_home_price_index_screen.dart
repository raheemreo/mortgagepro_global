// lib/features/usa/screens/usa_home_price_index_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/usa_rates_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../shared/widgets/bottom_nav.dart';

class USAHomePriceIndexScreen extends ConsumerStatefulWidget {
  const USAHomePriceIndexScreen({super.key});

  @override
  ConsumerState<USAHomePriceIndexScreen> createState() => _USAHomePriceIndexScreenState();
}

class _HpiPeriodData {
  final List<String> labels;
  final List<double> cs;
  final List<double> fhfa;
  final List<double> med;
  final String yoy;
  final String peak;

  const _HpiPeriodData({
    required this.labels,
    required this.cs,
    required this.fhfa,
    required this.med,
    required this.yoy,
    required this.peak,
  });
}

class _USAHomePriceIndexScreenState extends ConsumerState<USAHomePriceIndexScreen> {
  static const _theme = CountryThemes.usa;

  String _currentPeriod = '5y';

  static const Map<String, _HpiPeriodData> _hpiData = {
    '2y': _HpiPeriodData(
      labels: ['Jun\'23', 'Sep\'23', 'Dec\'23', 'Mar\'24', 'Jun\'24', 'Sep\'24', 'Dec\'24', 'Mar\'25'],
      cs: [307.0, 314.5, 310.5, 316.8, 323.4, 328.1, 325.6, 332.6],
      fhfa: [300, 307, 305, 311, 318, 323, 321, 328],
      med: [420, 425, 410, 415, 422, 428, 415, 416.9],
      yoy: '+4.9%', peak: '332.6 (Mar 2025)'
    ),
    '5y': _HpiPeriodData(
      labels: ['Jan\'20', 'Jul\'20', 'Jan\'21', 'Jul\'21', 'Jan\'22', 'Jul\'22', 'Jan\'23', 'Jul\'23', 'Jan\'24', 'Mar\'25'],
      cs: [218, 232, 248, 277, 298, 314, 294, 310, 315, 332.6],
      fhfa: [213, 228, 244, 272, 292, 308, 290, 306, 311, 328],
      med: [274, 284, 303, 340, 380, 413, 375, 405, 410, 416.9],
      yoy: '+5.1%', peak: '332.6 (Mar 2025)'
    ),
    '10y': _HpiPeriodData(
      labels: ['2015', '2016', '2017', '2018', '2019', '2020', '2021', '2022', '2023', '2024', '2025'],
      cs: [180, 186, 194, 204, 210, 218, 261, 305, 300, 322, 332.6],
      fhfa: [175, 182, 190, 200, 207, 213, 256, 300, 295, 318, 328],
      med: [222, 235, 248, 261, 275, 295, 347, 422, 392, 407, 416.9],
      yoy: '+5.1%', peak: '332.6 (2025)'
    ),
    '25y': _HpiPeriodData(
      labels: ['2000', '2003', '2006', '2009', '2012', '2015', '2018', '2020', '2022', '2025'],
      cs: [100, 130, 189, 148, 138, 180, 204, 218, 314, 332.6],
      fhfa: [96, 125, 181, 141, 133, 175, 200, 213, 300, 328],
      med: [147, 170, 221, 172, 183, 222, 261, 295, 422, 416.9],
      yoy: '233% since 2000', peak: 'All-time high (2025)'
    )
  };

  static const List<Map<String, dynamic>> _metroData = [
    {'area': 'New York', 'yoy': 8.2, 'price': 750, 'trend': '↑↑', 'grn': true},
    {'area': 'San Diego', 'yoy': 7.4, 'price': 871, 'trend': '↑↑', 'grn': true},
    {'area': 'Chicago', 'yoy': 7.1, 'price': 348, 'trend': '↑↑', 'grn': true},
    {'area': 'Miami', 'yoy': 6.8, 'price': 620, 'trend': '↑', 'grn': true},
    {'area': 'Los Angeles', 'yoy': 5.9, 'price': 880, 'trend': '↑', 'grn': true},
    {'area': 'Boston', 'yoy': 5.5, 'price': 625, 'trend': '↑', 'grn': true},
    {'area': 'Washington DC', 'yoy': 4.4, 'price': 546, 'trend': '↑', 'grn': true},
    {'area': 'Dallas', 'yoy': 3.1, 'price': 405, 'trend': '↑', 'grn': true},
    {'area': 'Phoenix', 'yoy': 1.7, 'price': 436, 'trend': '→', 'gold': true},
    {'area': 'Denver', 'yoy': -0.4, 'price': 575, 'trend': '↓', 'red': true},
    {'area': 'Austin', 'yoy': -2.1, 'price': 442, 'trend': '↓↓', 'red': true},
    {'area': 'San Francisco', 'yoy': -1.2, 'price': 1190, 'trend': '↓', 'red': true}
  ];

  static const List<Map<String, dynamic>> _regions = [
    {'r': 'Pacific', 'val': 3.2, 'color': Color(0xFF0F766E)},
    {'r': 'Mountain', 'val': 4.8, 'color': Color(0xFF15803D)},
    {'r': 'W. North Ctrl', 'val': 6.1, 'color': Color(0xFF1B3F72)},
    {'r': 'E. North Ctrl', 'val': 6.8, 'color': Color(0xFF1B3F72)},
    {'r': 'W. South Ctrl', 'val': 4.1, 'color': Color(0xFFD97706)},
    {'r': 'E. South Ctrl', 'val': 5.3, 'color': Color(0xFF15803D)},
    {'r': 'S. Atlantic', 'val': 5.7, 'color': Color(0xFF15803D)},
    {'r': 'Mid-Atlantic', 'val': 7.2, 'color': Color(0xFF0B1D3A)},
    {'r': 'New England', 'val': 7.8, 'color': Color(0xFF0B1D3A)}
  ];

  static const List<Map<String, dynamic>> _priceSegments = [
    {'label': 'Under \$250K', 'val': 16.0, 'color': Color(0xFF0F766E)},
    {'label': '\$250K–\$500K', 'val': 38.0, 'color': Color(0xFF1B3F72)},
    {'label': '\$500K–\$750K', 'val': 24.0, 'color': Color(0xFFD97706)},
    {'label': '\$750K–\$1M', 'val': 12.0, 'color': Color(0xFFB91C1C)},
    {'label': 'Over \$1M', 'val': 10.0, 'color': Color(0xFF4C1D95)}
  ];

  void _saveSnapshot() {
    final active = _hpiData[_currentPeriod]!;
    final medPrice = ref.read(censusMedianHomeValueProvider).valueOrNull?.value ?? 416900.0;
    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'US HPI Trend',
      label: 'HPI Trend · ${active.peak}',
      currencyCode: 'USD',
      inputs: {
        'national_YoY': 5.1,
        'median_price': medPrice,
      },
      results: {
        'CS YoY': double.tryParse(active.yoy.replaceAll('%', '').replaceAll('+', '')) ?? 4.9,
      },
    );

    ref.read(savedProvider.notifier).save(calc);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ US Home Price Index bookmark saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = _theme.getCardColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);
    final borderCol = _theme.getBorderColor(context);
    final bgCol = _theme.getBgColor(context);

    final censusMedianAsync = ref.watch(censusMedianHomeValueProvider);
    final medPrice = censusMedianAsync.valueOrNull?.value ?? 416900.0;
    final formattedMedPrice = '\$${medPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    final formattedMedK = '\$${(medPrice / 1000).toStringAsFixed(0)}K';

    final active = _hpiData[_currentPeriod]!;
    final maxReg = _regions.map((r) => r['val'] as double).reduce(math.max);

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
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(gradient: _theme.headerGradient),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🏡', style: TextStyle(fontSize: 28)),
                          const SizedBox(height: 2),
                          Text('US Home Price Index', style: AppTextStyles.playfair(size: 18, color: Colors.white, weight: FontWeight.w800)),
                          Text('S&P Case-Shiller · FHFA · NAR · Zillow · 2025', style: AppTextStyles.dmSans(size: 9, color: Colors.white60)),
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
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: _theme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _theme.primaryColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStripItem('Nat\'l HPI YoY', '+5.1%', 'FHFA Q1 2025', Colors.green),
                      _buildStripItem('Med. Price', formattedMedPrice, censusMedianAsync.valueOrNull?.isLive == true ? 'Census Live' : 'NAR Q1 2025', Colors.amber),
                      _buildStripItem('CS-20 YoY', '+4.9%', 'S&P Apr 2025', Colors.green),
                      _buildStripItem('Peak (2022)', r'$479K', 'Nat\'l Med.', textCol),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // National Overview Hero
                    _buildSectionHeader('National HPI Overview', 'FHFA 2025', mutedCol),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFF0F766E)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('US Home Price Index · Annual Summary', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                          const SizedBox(height: 4),
                          const Text('Home Prices Up +5.1% YoY\nCooling from 2022 Peak', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Georgia', height: 1.25)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildHeroGridItem('FHFA HPI', '+5.1%', const Color(0xFF6EE7B7)),
                              const SizedBox(width: 6),
                              _buildHeroGridItem('CS-20 City', '+4.9%', const Color(0xFF6EE7B7)),
                              const SizedBox(width: 6),
                              _buildHeroGridItem('Zillow', '+2.9%', const Color(0xFF6EE7B7)),
                              const SizedBox(width: 6),
                              _buildHeroGridItem('Since 2020', '+52%', const Color(0xFFFCD34D)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // KPI Cards Row
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildKpiCard('🏠', formattedMedK, 'Median Price', censusMedianAsync.valueOrNull?.isLive == true ? 'Census Live' : '↑ +5.1% YoY', Colors.green, cardBg, textCol, mutedCol, borderCol),
                        const SizedBox(width: 8),
                        _buildKpiCard('📊', '313', 'FHFA Index', '↑ +15.9 pts', Colors.green, cardBg, textCol, mutedCol, borderCol),
                        const SizedBox(width: 8),
                        _buildKpiCard('🏙️', '+8.2%', 'Top Metro (NY)', 'Fastest Growth', Colors.green, cardBg, textCol, mutedCol, borderCol),
                      ],
                    ),

                    // Period selector and trend chart
                    _buildSectionHeader('HPI Trend Chart', 'S&P Case-Shiller', mutedCol),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _hpiData.keys.map((p) {
                          final activePeriod = _currentPeriod == p;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(p.toUpperCase()),
                              selected: activePeriod,
                              selectedColor: _theme.primaryColor,
                              labelStyle: AppTextStyles.dmSans(
                                size: 10.5,
                                weight: FontWeight.bold,
                                color: activePeriod ? Colors.white : textCol,
                              ),
                              onSelected: (sel) {
                                if (sel) setState(() => _currentPeriod = p);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderCol),
                        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('S&P/Case-Shiller 20-City', style: TextStyle(fontSize: 8.5, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  Text('332.6', style: AppTextStyles.playfair(size: 22, weight: FontWeight.bold, color: textCol)),
                                  Text('↑ ${active.yoy} Year-over-Year', style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Peak Index', style: TextStyle(fontSize: 8, color: Colors.grey)),
                                  Text(active.peak, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.bold, color: textCol)),
                                  const SizedBox(height: 3),
                                  const Text('Base (Jan 2000)', style: TextStyle(fontSize: 8, color: Colors.grey)),
                                  Text('100.0', style: AppTextStyles.dmSans(size: 10, weight: FontWeight.bold, color: textCol)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Custom Painter line chart
                          Container(
                            height: 170,
                            width: double.infinity,
                            decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEDF5F2), borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.all(8),
                            child: CustomPaint(
                              painter: _HpiChartPainter(
                                active: active,
                                isDark: isDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _buildLegendDot('Case-Shiller 20-City', const Color(0xFF0F766E)),
                              const SizedBox(width: 12),
                              _buildLegendDot('FHFA National', const Color(0xFF1B3F72)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _saveSnapshot,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _theme.primaryColor,
                          side: BorderSide(color: _theme.primaryColor, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Trend Bookmark', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),

                    // Top Metro Table
                    _buildSectionHeader('Top Metro HPI Changes', 'Q1 2025 YoY', mutedCol),
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol),
                        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 3))],
                      ),
                      child: Column(
                        children: [
                          Container(
                            color: const Color(0xFF0F766E),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('🏙️ Metro Area HPI · Year-over-Year', style: AppTextStyles.playfair(size: 10, weight: FontWeight.bold, color: Colors.white)),
                                const Text('S&P/Case-Shiller 2025', style: TextStyle(color: Colors.white54, fontSize: 8)),
                              ],
                            ),
                          ),
                          _buildMetroRow('Metro Area', 'YoY %', 'Med. Price', 'Trend', isHeader: true),
                          ..._metroData.map((m) {
                            return _buildMetroRow(
                              m['area'] as String,
                              '${m['yoy'] >= 0 ? '+' : ''}${m['yoy']}%',
                              '\$${m['price']}K',
                              m['trend'] as String,
                              isGrn: m['grn'] == true,
                              isRed: m['red'] == true,
                              isGold: m['gold'] == true,
                              isAlt: _metroData.indexOf(m) % 2 == 1,
                            );
                          }),
                        ],
                      ),
                    ),

                    // Regional HPI growth bar chart
                    _buildSectionHeader('Regional HPI YoY 2025', 'FHFA Divisions', mutedCol),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderCol),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📊 HPI Growth by Census Division', style: AppTextStyles.playfair(size: 12, color: textCol, weight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Column(
                            children: _regions.map((r) {
                              final name = r['r'] as String;
                              final val = r['val'] as double;
                              final color = r['color'] as Color;
                              final pct = val / maxReg;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    SizedBox(width: 84, child: Text(name, style: const TextStyle(fontSize: 9.5, color: Colors.grey, fontWeight: FontWeight.bold))),
                                    Expanded(
                                      child: Container(
                                        height: 22,
                                        decoration: BoxDecoration(color: bgCol, borderRadius: BorderRadius.circular(6)),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: FractionallySizedBox(
                                            widthFactor: pct,
                                            child: Container(
                                              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                                              alignment: Alignment.centerLeft,
                                              padding: const EdgeInsets.only(left: 6),
                                              child: val > 3 ? Text('$val%', style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)) : null,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(width: 45, child: Text('+$val%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    // Pie Segment Donut Chart
                    _buildSectionHeader('Price Segment Breakdown', 'NAR Q1 2025', mutedCol),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderCol),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🥧 Sales Volume by Price Range · Q1 2025', style: AppTextStyles.playfair(size: 12, color: textCol, weight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              SizedBox(
                                width: 110,
                                height: 110,
                                child: CustomPaint(
                                  painter: _HpiDonutPainter(
                                    segments: _priceSegments,
                                    isDark: isDark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  children: _priceSegments.map((s) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(width: 10, height: 10, decoration: BoxDecoration(color: s['color'] as Color, borderRadius: BorderRadius.circular(3))),
                                              const SizedBox(width: 6),
                                              Text(s['label'] as String, style: const TextStyle(fontSize: 9.5, color: Colors.grey, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                          Text('${(s['val'] as double).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Insights
                    _buildSectionHeader('Market Context', '2025 Analysis', mutedCol),
                    _buildInsightCard('📈', '2025 HPI Growth: Cooling but Positive', 'After a scorching **+20.6% YoY peak in 2022**, HPI growth has cooled to **+5.1% (FHFA)** and **+4.9% (Case-Shiller)** in 2025. This is close to the historical norm of 3–5% annual appreciation.', cardBg, textCol, mutedCol, borderCol),
                    _buildInsightCard('🏙️', 'Northeast & Midwest Outperforming', 'New York, Chicago, and Boston lead with **+7–8% YoY** growth. The Sun Belt markets (Austin, Phoenix) that surged during COVID are now correcting, with Austin down **−2.1%** YoY.', cardBg, textCol, mutedCol, borderCol),
                    _buildInsightCard('🏠', 'Lock-In Effect Constraining Supply', 'With **78% of US mortgages** locked in below 5%, existing homeowners are reluctant to sell, creating severe inventory shortages that continue to support prices despite high mortgage rates.', cardBg, textCol, mutedCol, borderCol),
                    _buildInsightCard('🔮', '2025 Price Forecast (Consensus)', 'Fannie Mae (+4.8%), Freddie Mac (+3.0%), NAR (+2.0%), Goldman Sachs (+4.4%). Most analysts project **continued modest appreciation** in 2025, driven by supply constraints and resilient demand.', cardBg, textCol, mutedCol, borderCol),
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

  Widget _buildStripItem(String label, String val, String note, Color color) {
    return Column(
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 7.5, color: Colors.white54, letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color, fontFamily: 'Georgia')),
        Text(note, style: const TextStyle(fontSize: 7.5, color: Colors.white38)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String tagText, Color labelColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title.toUpperCase(), style: AppTextStyles.dmSans(size: 10, weight: FontWeight.bold, color: labelColor, letterSpacing: 0.8)),
          if (tagText.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Text(tagText, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.green)),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroGridItem(String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(color: Colors.white12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label.toUpperCase(), style: const TextStyle(fontSize: 7, color: Colors.white54)),
            const SizedBox(height: 2),
            Text(val, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: color, fontFamily: 'Georgia')),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String emoji, String val, String label, String chg, Color chgCol, Color bg, Color txt, Color muted, Color border) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: txt, fontFamily: 'Georgia')),
            Text(label, style: TextStyle(fontSize: 8.5, color: muted), textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(chg, style: TextStyle(fontSize: 9, color: chgCol, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendDot(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMetroRow(String area, String yoy, String price, String trend, {bool isHeader = false, bool isGrn = false, bool isRed = false, bool isGold = false, bool isAlt = false}) {
    final themeTxtCol = Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0B1D3A);
    final rowCol = isHeader ? Colors.grey.withValues(alpha: 0.1) : isAlt ? Colors.grey.withValues(alpha: 0.05) : Colors.transparent;
    final textWeight = isHeader ? FontWeight.bold : FontWeight.normal;
    final double size = isHeader ? 8.5 : 10.5;

    Color trendCol = themeTxtCol;
    if (isGrn) trendCol = Colors.green;
    if (isRed) trendCol = Colors.red;
    if (isGold) trendCol = Colors.orange;

    return Container(
      color: rowCol,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 3, child: Text(area, style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.w800, fontSize: size, color: isHeader ? Colors.grey : themeTxtCol))),
          Expanded(flex: 2, child: Text(yoy, style: TextStyle(fontWeight: FontWeight.bold, fontSize: size, color: isHeader ? Colors.grey : trendCol), textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text(price, style: TextStyle(fontWeight: textWeight, fontSize: size, color: isHeader ? Colors.grey : themeTxtCol), textAlign: TextAlign.right)),
          Expanded(flex: 1, child: Text(trend, style: TextStyle(fontWeight: FontWeight.bold, fontSize: size, color: isHeader ? Colors.grey : trendCol), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String emoji, String title, String detail, Color cardBg, Color textCol, Color mutedCol, Color borderCol) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.playfair(size: 12, color: textCol, weight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(detail, style: TextStyle(fontSize: 9.5, color: mutedCol, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HpiChartPainter extends CustomPainter {
  final _HpiPeriodData active;
  final bool isDark;

  const _HpiChartPainter({required this.active, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final cs = active.cs;
    final fhfa = active.fhfa;
    final n = cs.length;

    final all = [...cs, ...fhfa];
    final minV = all.reduce(math.min) * 0.97;
    final maxV = all.reduce(math.max) * 1.01;

    const pl = 32.0;
    const pt = 12.0;
    const pr = 12.0;
    const pb = 20.0;

    final cw = size.width - pl - pr;
    final ch = size.height - pt - pb;

    double scaleX(int idx) => pl + (idx / (n - 1)) * cw;
    double scaleY(double v) => pt + ch - ((v - minV) / (maxV - minV)) * ch;

    // Draw Grid Lines
    final gridPaint = Paint()
      ..color = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    const steps = 4;
    for (int i = 0; i <= steps; i++) {
      final val = minV + (maxV - minV) * (i / steps);
      final y = scaleY(val);
      canvas.drawLine(Offset(pl, y), Offset(size.width - pr, y), gridPaint);

      textPainter.text = TextSpan(
        text: val.round().toString(),
        style: TextStyle(color: isDark ? Colors.white60 : Colors.grey, fontSize: 7.5),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(pl - textPainter.width - 4, y - textPainter.height / 2));
    }

    // Paint X-axis labels
    final int step = (n / 4).ceil();
    for (int i = 0; i < n; i += step) {
      final x = scaleX(i);
      textPainter.text = TextSpan(
        text: active.labels[i],
        style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600, fontSize: 7.5),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height - pb + 4));
    }

    void drawLinePath(List<double> data, Color col, double width, {bool fill = false}) {
      final path = Path();
      path.moveTo(scaleX(0), scaleY(data[0]));
      for (int i = 1; i < n; i++) {
        path.lineTo(scaleX(i), scaleY(data[i]));
      }

      if (fill) {
        final fillPath = Path.from(path)
          ..lineTo(scaleX(n - 1), scaleY(minV))
          ..lineTo(scaleX(0), scaleY(minV))
          ..close();
        final fillPaint = Paint()
          ..color = col.withValues(alpha: 0.08)
          ..style = PaintingStyle.fill;
        canvas.drawPath(fillPath, fillPaint);
      }

      final linePaint = Paint()
        ..color = col
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, linePaint);
    }

    // Draw FHFA Line
    drawLinePath(fhfa, const Color(0xFF1B3F72), 1.5);

    // Draw Case-Shiller Line
    drawLinePath(cs, const Color(0xFF0F766E), 2.5, fill: true);

    // Dot at end
    final dotX = scaleX(n - 1);
    final dotY = scaleY(cs[n - 1]);
    canvas.drawCircle(Offset(dotX, dotY), 4.0, Paint()..color = const Color(0xFF0F766E));
  }

  @override
  bool shouldRepaint(covariant _HpiChartPainter oldDelegate) =>
      oldDelegate.active != active || oldDelegate.isDark != isDark;
}

class _HpiDonutPainter extends CustomPainter {
  final List<Map<String, dynamic>> segments;
  final bool isDark;

  const _HpiDonutPainter({required this.segments, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2;
    final innerRadius = outerRadius * 0.6;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    double startAngle = -math.pi / 2;

    for (var segment in segments) {
      final value = segment['val'] as double;
      final sweepAngle = (value / 100.0) * 2 * math.pi;

      paint.color = segment['color'] as Color;

      // Draw segment path (doughnut ring slice)
      final path = Path();
      // Outer arc
      path.arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        sweepAngle,
        true,
      );
      // Inner arc
      path.arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle + sweepAngle,
        -sweepAngle,
        false,
      );
      path.close();

      canvas.drawPath(path, paint);

      startAngle += sweepAngle;
    }

    // Draw Center text
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: 'NAR',
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF0B1D3A),
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2 - 4),
    );

    textPainter.text = TextSpan(
      text: 'Q1 2025',
      style: TextStyle(
        color: isDark ? Colors.white54 : const Color(0xFF4A5C7A),
        fontSize: 7.5,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy + 4),
    );
  }

  @override
  bool shouldRepaint(covariant _HpiDonutPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
