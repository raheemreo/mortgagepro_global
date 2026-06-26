// lib/features/usa/screens/usa_fred_rate_history_screen.dart

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

class USAFredRateHistoryScreen extends ConsumerStatefulWidget {
  const USAFredRateHistoryScreen({super.key});

  @override
  ConsumerState<USAFredRateHistoryScreen> createState() => _USAFredRateHistoryScreenState();
}

class _FredPeriodData {
  final List<String> labels;
  final List<double> rates30;
  final List<double> ratesFed;
  final List<double> rates10;
  final String hi;
  final String lo;
  final String per;
  final String chg;

  const _FredPeriodData({
    required this.labels,
    required this.rates30,
    required this.ratesFed,
    required this.rates10,
    required this.hi,
    required this.lo,
    required this.per,
    required this.chg,
  });
}

class _USAFredRateHistoryScreenState extends ConsumerState<USAFredRateHistoryScreen> {
  static const _theme = CountryThemes.usa;

  String _currentPeriod = '3y';

  static const Map<String, _FredPeriodData> _chartData = {
    '1y': _FredPeriodData(
      labels: ['Jun\'24', 'Aug\'24', 'Oct\'24', 'Dec\'24', 'Feb\'25', 'Apr\'25', 'Jun\'25'],
      rates30: [6.92, 6.50, 6.72, 6.85, 6.96, 6.88, 6.82],
      ratesFed: [5.33, 5.33, 5.33, 4.58, 4.33, 4.33, 5.33],
      rates10: [4.38, 3.91, 4.24, 4.57, 4.62, 4.38, 4.47],
      hi: '7.22% (Apr\'25)', lo: '6.11% (Sep\'24)', per: '1-Year View', chg: '↑ +0.28% YTD'
    ),
    '3y': _FredPeriodData(
      labels: ['Jun\'22', 'Dec\'22', 'Jun\'23', 'Oct\'23', 'Jan\'24', 'Jun\'24', 'Jan\'25', 'Jun\'25'],
      rates30: [5.52, 6.42, 6.71, 7.79, 6.62, 6.92, 6.96, 6.82],
      ratesFed: [1.75, 4.25, 5.00, 5.33, 5.33, 5.33, 5.33, 5.33],
      rates10: [3.28, 3.88, 3.84, 4.98, 4.02, 4.38, 4.57, 4.47],
      hi: '7.79% (Oct 2023)', lo: '5.52% (Jun 2022)', per: '3-Year View', chg: '↑ +1.30% (3yr)'
    ),
    '5y': _FredPeriodData(
      labels: ['Jun\'20', 'Jun\'21', 'Jan\'22', 'Jun\'22', 'Jan\'23', 'Jun\'23', 'Jan\'24', 'Jun\'24', 'Jan\'25', 'Jun\'25'],
      rates30: [3.16, 2.98, 3.55, 5.52, 6.48, 6.71, 6.62, 6.92, 6.96, 6.82],
      ratesFed: [0.09, 0.08, 0.08, 1.75, 4.50, 5.00, 5.33, 5.33, 5.33, 5.33],
      rates10: [0.91, 1.47, 1.79, 3.28, 3.59, 3.84, 4.02, 4.38, 4.57, 4.47],
      hi: '7.79% (Oct 2023)', lo: '2.65% (Jan 2021)', per: '5-Year View', chg: '↑ +3.84% (5yr)'
    ),
    '10y': _FredPeriodData(
      labels: ['2015', '2016', '2017', '2018', '2019', '2020', '2021', '2022', '2023', '2024', '2025'],
      rates30: [3.85, 3.65, 3.99, 4.54, 3.94, 3.11, 2.96, 5.34, 6.81, 6.73, 6.82],
      ratesFed: [0.24, 0.40, 1.00, 1.83, 2.16, 0.36, 0.08, 1.68, 5.02, 5.33, 5.33],
      rates10: [2.14, 1.84, 2.33, 2.91, 2.14, 0.89, 1.45, 3.01, 3.97, 4.35, 4.47],
      hi: '7.79% (Oct 2023)', lo: '2.65% (Jan 2021)', per: '10-Year View', chg: '↑ +2.97% (10yr)'
    ),
    '20y': _FredPeriodData(
      labels: ['2005', '2008', '2010', '2012', '2015', '2018', '2020', '2022', '2023', '2025'],
      rates30: [5.87, 6.03, 4.69, 3.66, 3.85, 4.54, 3.11, 5.34, 6.81, 6.82],
      ratesFed: [3.22, 2.00, 0.18, 0.14, 0.24, 1.83, 0.36, 1.68, 5.02, 5.33],
      rates10: [4.29, 3.67, 3.22, 1.80, 2.14, 2.91, 0.89, 3.01, 3.97, 4.47],
      hi: '7.79% (2023)', lo: '2.65% (2021)', per: '20-Year View', chg: '↑ +0.95% (20yr)'
    ),
    '50y': _FredPeriodData(
      labels: ['1975', '1980', '1985', '1990', '1995', '2000', '2005', '2010', '2015', '2020', '2025'],
      rates30: [9.09, 13.74, 12.43, 10.13, 7.93, 8.05, 5.87, 4.69, 3.85, 3.11, 6.82],
      ratesFed: [5.82, 13.35, 8.10, 8.10, 5.83, 6.24, 3.22, 0.18, 0.24, 0.36, 5.33],
      rates10: [7.99, 11.43, 10.62, 8.55, 6.57, 6.03, 4.29, 3.22, 2.14, 0.89, 4.47],
      hi: '16.63% (1981)', lo: '2.65% (2021)', per: '50-Year View', chg: 'Historical Low: 2.65% (2021)'
    )
  };

  static const List<Map<String, dynamic>> _yrData = [
    {'yr': '2015', 'val': 3.85},
    {'yr': '2016', 'val': 3.65},
    {'yr': '2017', 'val': 3.99},
    {'yr': '2018', 'val': 4.54},
    {'yr': '2019', 'val': 3.94},
    {'yr': '2020', 'val': 3.11},
    {'yr': '2021', 'val': 2.96},
    {'yr': '2022', 'val': 5.34},
    {'yr': '2023', 'val': 6.81},
    {'yr': '2024', 'val': 6.73},
    {'yr': '2025', 'val': 6.82}
  ];

  static const List<Map<String, dynamic>> _fomcMeetings = [
    {'mon': 'Jan', 'day': '29', 'title': 'January FOMC Meeting', 'sub': 'Decision: Hold · Range: 5.25–5.50%', 'badge': 'Held', 'type': 'past'},
    {'mon': 'Mar', 'day': '19', 'title': 'March FOMC Meeting', 'sub': 'Decision: Hold · Range: 5.25–5.50%', 'badge': 'Held', 'type': 'past'},
    {'mon': 'May', 'day': '7', 'title': 'May FOMC Meeting', 'sub': 'Decision: Hold · "Watching inflation data"', 'badge': 'Held', 'type': 'past'},
    {'mon': 'Jun', 'day': '18', 'title': 'June FOMC Meeting (Recent)', 'sub': 'Decision: Hold · Dot plot revised · 1 cut expected 2025', 'badge': 'Held', 'type': 'past', 'recent': true},
    {'mon': 'Jul', 'day': '30', 'title': 'July FOMC Meeting', 'sub': 'Cut probability: 68% · CME FedWatch', 'badge': 'Watch', 'type': 'watch'},
    {'mon': 'Sep', 'day': '17', 'title': 'September FOMC Meeting', 'sub': 'SEP (dot plot) update · Key meeting', 'badge': 'Watch', 'type': 'watch'},
    {'mon': 'Nov', 'day': '5', 'title': 'November FOMC Meeting', 'sub': 'Post-election meeting · Policy review', 'badge': 'TBD', 'type': 'hold'},
    {'mon': 'Dec', 'day': '17', 'title': 'December FOMC Meeting', 'sub': 'Year-end SEP · 2026 projections', 'badge': 'TBD', 'type': 'hold'}
  ];

  void _saveCalculation() {
    final activeData = _chartData[_currentPeriod]!;
    final m30Val = ref.read(fredMortgage30Provider).valueOrNull?.value ?? 6.82;
    final fedFundsVal = ref.read(fredFedFundsProvider).valueOrNull?.value ?? 5.33;
    final calc = SavedCalc.create(
      country: 'USA',
      calcType: 'FRED Rate Trends',
      label: 'FRED Rate · ${activeData.per}',
      currencyCode: 'USD',
      inputs: {
        'period': _currentPeriod == '1y' ? 1.0 : _currentPeriod == '3y' ? 3.0 : _currentPeriod == '5y' ? 5.0 : 10.0,
        'current_30yr': m30Val,
        'current_fed': fedFundsVal,
      },
      results: {
        'Historical High': double.tryParse(activeData.hi.split('%')[0]) ?? 7.79,
        'Historical Low': double.tryParse(activeData.lo.split('%')[0]) ?? 2.65,
      },
    );

    ref.read(savedProvider.notifier).save(calc);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ FRED Rate Trends snapshot saved to bookmarks!'),
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

    final mortgage30Async = ref.watch(fredMortgage30Provider);
    final mortgage15Async = ref.watch(fredMortgage15Provider);
    final sofrAsync = ref.watch(fredSofrProvider);
    final fedFundsAsync = ref.watch(fredFedFundsProvider);

    final m30Val = mortgage30Async.valueOrNull?.value ?? 6.82;
    final m15Val = mortgage15Async.valueOrNull?.value ?? 6.11;
    final sofrVal = sofrAsync.valueOrNull?.value ?? 5.33;
    final fedFundsVal = fedFundsAsync.valueOrNull?.value ?? 5.33;

    final activeData = _chartData[_currentPeriod]!;
    final maxYr = _yrData.map((d) => d['val'] as double).reduce(math.max);

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
                          const Text('📉', style: TextStyle(fontSize: 28)),
                          const SizedBox(height: 2),
                          Text('FRED Rate History', style: AppTextStyles.playfair(size: 18, color: Colors.white, weight: FontWeight.w800)),
                          Text('Federal Reserve · FOMC · 30-Yr Mortgage Rate Timeline', style: AppTextStyles.dmSans(size: 9, color: Colors.white60)),
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
                      _buildStripItem('30-Yr Now', '${m30Val.toStringAsFixed(2)}%', mortgage30Async.valueOrNull?.isLive == true ? 'FRED Live' : 'Freddie Mac', textCol),
                      _buildStripItem('Fed Funds', '${fedFundsVal.toStringAsFixed(2)}%', fedFundsAsync.valueOrNull?.isLive == true ? 'FRED Live' : 'FOMC', Colors.amber),
                      _buildStripItem('10-Yr T-Note', '4.47%', 'Treasury', textCol),
                      _buildStripItem('YTD Chg', '+0.28%', 'vs Jan 2025', Colors.red),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Fed Banner
                    _buildSectionHeader('Federal Reserve', 'FOMC 2025', mutedCol),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          const Text('🏛️', style: TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Fed Funds Rate · Current Target', style: TextStyle(color: Colors.white60, fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 0.6)),
                                const SizedBox(height: 2),
                                Text('${(fedFundsVal - 0.08).toStringAsFixed(2)}% – ${(fedFundsVal + 0.17).toStringAsFixed(2)}%', style: AppTextStyles.playfair(size: 20, color: const Color(0xFFFCD34D), weight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text('Next FOMC: Jul 30, 2025 · Cut probability: 68%', style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(6)),
                            child: const Text('FRED Live', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _chartData.keys.map((p) {
                          final active = _currentPeriod == p;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(p.toUpperCase()),
                              selected: active,
                              selectedColor: _theme.primaryColor,
                              labelStyle: AppTextStyles.dmSans(
                                size: 10.5,
                                weight: FontWeight.bold,
                                color: active ? Colors.white : textCol,
                              ),
                              onSelected: (sel) {
                                if (sel) setState(() => _currentPeriod = p);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    _buildSectionHeader('30-Year Fixed Rate Chart', 'Freddie Mac PMMS', mutedCol),
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
                                  const Text('30-Yr Fixed · Current', style: TextStyle(fontSize: 8.5, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  Text('${m30Val.toStringAsFixed(2)}%', style: AppTextStyles.playfair(size: 22, weight: FontWeight.bold, color: textCol)),
                                  const Text('↑ +0.05% this week', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('🔴 Hi: ${activeData.hi}', style: const TextStyle(color: Colors.red, fontSize: 9.5, fontWeight: FontWeight.bold)),
                                  Text('🟢 Lo: ${activeData.lo}', style: const TextStyle(color: Colors.green, fontSize: 9.5, fontWeight: FontWeight.bold)),
                                  Text('Period: ${activeData.per}', style: const TextStyle(color: Colors.grey, fontSize: 8.5)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEDF5F2), borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.all(8),
                            child: CustomPaint(
                              painter: _FredRateHistoryPainter(
                                activeData: activeData,
                                isDark: isDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              _buildLegendItem('30-Yr Fixed', const Color(0xFF1B3F72)),
                              const SizedBox(width: 12),
                              _buildLegendItem('Fed Funds', const Color(0xFFD97706)),
                              const SizedBox(width: 12),
                              _buildLegendItem('10-Yr Treasury', const Color(0xFFF59E0B)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _saveCalculation,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _theme.primaryColor,
                          side: BorderSide(color: _theme.primaryColor, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Rate Snapshot Bookmark', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),

                    _buildSectionHeader('Current Rates Snapshot', 'June 2025', mutedCol),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 9,
                      mainAxisSpacing: 9,
                      childAspectRatio: 2.2,
                      children: [
                        _buildGridCard('30-Yr Fixed', '${m30Val.toStringAsFixed(2)}%', '↑ +0.05 wk', mortgage30Async.valueOrNull?.isLive == true ? 'FRED Live' : 'Freddie Mac PMMS', Colors.green),
                        _buildGridCard('15-Yr Fixed', '${m15Val.toStringAsFixed(2)}%', '↓ -0.02 wk', mortgage15Async.valueOrNull?.isLive == true ? 'FRED Live' : 'National Avg', Colors.red),
                        _buildGridCard('5/1 ARM', '${(sofrVal + 0.72).toStringAsFixed(2)}%', '↓ -0.03 wk', sofrAsync.valueOrNull?.isLive == true ? 'FRED SOFR' : 'National Avg', Colors.red),
                        _buildGridCard('Fed Funds', '${fedFundsVal.toStringAsFixed(2)}%', '— Unchanged', fedFundsAsync.valueOrNull?.isLive == true ? 'FRED Live' : 'FOMC Target Midpt', Colors.grey),
                        _buildGridCard('10-Yr Treasury', '4.47%', '↓ -0.03', 'US Treasury Dept.', Colors.red),
                        _buildGridCard('30-Yr Treasury', '4.61%', '↑ +0.02', 'US Treasury Dept.', Colors.green),
                      ],
                    ),

                    _buildSectionHeader('30-Yr Rate Annual History', 'FRED Data', mutedCol),
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol),
                        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 3))],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Container(
                            color: const Color(0xFF0B1D3A),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('📊 Freddie Mac PMMS Annual Averages', style: AppTextStyles.playfair(size: 10, weight: FontWeight.bold, color: Colors.white)),
                                const Text('Source: FRED / Freddie Mac', style: TextStyle(color: Colors.white54, fontSize: 8)),
                              ],
                            ),
                          ),
                          _buildTableRow('Year', '30-Yr Avg', '15-Yr Avg', 'Fed Funds', isHeader: true),
                          _buildTableRow('2025 YTD', '6.72%', '6.05%', '5.33%', isGold: true),
                          _buildTableRow('2024', '6.73%', '6.05%', '5.33%', isAlt: true),
                          _buildTableRow('2023', '6.81%', '6.17%', '5.02%', isRed: true),
                          _buildTableRow('2022', '5.34%', '4.67%', '1.68%', isAlt: true, isRed: true),
                          _buildTableRow('2021', '2.96%', '2.37%', '0.08%', isGrn: true),
                          _buildTableRow('2020', '3.11%', '2.61%', '0.36%', isAlt: true, isGrn: true),
                          _buildTableRow('2019', '3.94%', '3.39%', '2.16%'),
                          _buildTableRow('2018', '4.54%', '3.99%', '1.83%', isAlt: true),
                          _buildTableRow('2010', '4.69%', '4.10%', '0.18%', isGrn: true),
                          _buildTableRow('2000', '8.05%', '7.72%', '6.24%', isAlt: true, isRed: true),
                          _buildTableRow('1981 (Peak)', '16.63%', '—', '16.38%', isRed: true, isBoldPeak: true),
                        ],
                      ),
                    ),

                    _buildSectionHeader('Annual Rate Comparison', '2015–2025', mutedCol),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📊 30-Year Fixed Rate · Annual Average', style: AppTextStyles.playfair(size: 12, color: textCol, weight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Column(
                            children: _yrData.map((d) {
                              final yr = d['yr'] as String;
                              final val = d['val'] as double;
                              final pct = val / maxYr;
                              final color = val > 6 ? Colors.red : val > 4 ? Colors.orange : Colors.green;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    SizedBox(width: 38, child: Text(yr, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                                    Expanded(
                                      child: Container(
                                        height: 18,
                                        decoration: BoxDecoration(color: bgCol, borderRadius: BorderRadius.circular(4)),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: FractionallySizedBox(
                                            widthFactor: pct,
                                            child: Container(
                                              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(width: 42, child: Text('$val%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    // FOMC Meeting Calendar
                    _buildSectionHeader('2025 FOMC Meeting Calendar', 'Rate Decisions', mutedCol),
                    Column(
                      children: _fomcMeetings.map((m) {
                        return _buildFomcItem(
                          m['mon'] as String,
                          m['day'] as String,
                          m['title'] as String,
                          m['sub'] as String,
                          m['badge'] as String,
                          m['type'] as String,
                          m['recent'] == true,
                          cardBg,
                          textCol,
                          mutedCol,
                          borderCol,
                        );
                      }).toList(),
                    ),

                    // Key Insights
                    _buildSectionHeader('Rate Context & Insights', 'Analysis', mutedCol),
                    _buildInsightCard('📊', 'Current Rate in Historical Context', 'At **6.82%**, the 30-yr fixed is well above the 2021 pandemic low of **2.65%** but below the 1981 peak of **16.63%**. The 50-year average is approximately **7.7%**, making current rates near the long-term average.', cardBg, textCol, mutedCol, borderCol),
                    _buildInsightCard('🏛️', 'Fed Rate vs. Mortgage Rate Spread', 'The spread between the **30-yr mortgage (6.82%)** and the **10-yr Treasury (4.47%)** is ~235 bps — elevated vs. the historical norm of ~170 bps. This reflects lender risk premium and MBS market conditions.', cardBg, textCol, mutedCol, borderCol),
                    _buildInsightCard('🔮', '2025 Rate Outlook (Consensus)', 'Most forecasters (Fannie Mae, MBA, NAR) project 30-yr rates to end 2025 in the **6.2–6.8% range** depending on Fed cuts. If the Fed cuts 1–2x, rates could dip toward **6.2–6.5%** by year-end.', cardBg, textCol, mutedCol, borderCol),
                    _buildInsightCard('💡', 'Impact of 1% Rate Change on Payments', 'On a **\$400,000 loan**, each 1% rate change = ~**\$240/month** difference. Going from 6.82% to 5.82% saves approximately **\$2,880/year** in interest payments.', cardBg, textCol, mutedCol, borderCol),
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
        Text(val, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.bold, color: color)),
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
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Text(tagText, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.blue)),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildGridCard(String label, String val, String chg, String src, Color chgCol) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(val, style: AppTextStyles.playfair(size: 16, weight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0B1D3A))),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(chg, style: TextStyle(fontSize: 8, color: chgCol, fontWeight: FontWeight.bold)),
              Text(src, style: const TextStyle(fontSize: 7.5, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(String yr, String r30, String r15, String rFed, {bool isHeader = false, bool isAlt = false, bool isGold = false, bool isGrn = false, bool isRed = false, bool isBoldPeak = false}) {
    final weight = isHeader || isBoldPeak ? FontWeight.bold : FontWeight.normal;
    final double size = isHeader ? 8.5 : 10.5;
    final rowCol = isHeader ? Colors.grey.withValues(alpha: 0.1) : isAlt ? Colors.grey.withValues(alpha: 0.05) : Colors.transparent;
    final txtCol = isHeader ? Colors.grey : isGold ? Colors.orange : isGrn ? Colors.green : isRed ? Colors.red : const Color(0xFF0B1D3A);
    final themeTxtCol = Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0B1D3A);

    return Container(
      color: rowCol,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 3, child: Text(yr, style: TextStyle(fontWeight: isBoldPeak ? FontWeight.bold : weight, fontSize: size, color: isHeader ? Colors.grey : themeTxtCol))),
          Expanded(flex: 2, child: Text(r30, style: TextStyle(fontWeight: weight, fontSize: size, color: isHeader ? Colors.grey : txtCol), textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text(r15, style: TextStyle(fontWeight: weight, fontSize: size, color: isHeader ? Colors.grey : themeTxtCol), textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text(rFed, style: TextStyle(fontWeight: weight, fontSize: size, color: isHeader ? Colors.grey : (isHeader ? Colors.grey : (isGold ? Colors.orange : themeTxtCol))), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildFomcItem(String mon, String day, String title, String sub, String badge, String type, bool recent, Color cardBg, Color textCol, Color mutedCol, Color borderCol) {
    Color badgeColor = Colors.grey;
    Color badgeTxtColor = Colors.white;
    if (type == 'watch') {
      badgeColor = const Color(0xFFFEF3C7);
      badgeTxtColor = const Color(0xFF92400E);
    } else if (type == 'hold') {
      badgeColor = const Color(0xFFF0FDF4);
      badgeTxtColor = const Color(0xFF15803D);
    } else if (type == 'past') {
      badgeColor = Colors.grey.withValues(alpha: 0.1);
      badgeTxtColor = mutedCol;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: recent ? Colors.amber : borderCol, width: recent ? 1.8 : 1.0),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(mon.toUpperCase(), style: AppTextStyles.dmSans(size: 8, color: mutedCol, weight: FontWeight.bold)),
              Text(day, style: AppTextStyles.playfair(size: 18, color: textCol, weight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.playfair(size: 11.5, color: textCol, weight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(sub, style: AppTextStyles.dmSans(size: 9, color: mutedCol)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
            child: Text(badge, style: TextStyle(color: badgeTxtColor, fontSize: 8, fontWeight: FontWeight.bold)),
          ),
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

class _FredRateHistoryPainter extends CustomPainter {
  final _FredPeriodData activeData;
  final bool isDark;

  const _FredRateHistoryPainter({required this.activeData, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rates30 = activeData.rates30;
    final ratesFed = activeData.ratesFed;
    final rates10 = activeData.rates10;
    final n = rates30.length;

    // Combine all to get global min/max bounds
    final all = [...rates30, ...ratesFed, ...rates10];
    final minV = all.reduce(math.min) - 0.5;
    final maxV = all.reduce(math.max) + 0.5;

    const pl = 30.0;
    const pt = 14.0;
    const pr = 14.0;
    const pb = 22.0;

    final cw = size.width - pl - pr;
    final ch = size.height - pt - pb;

    double scaleX(int idx) => pl + (idx / (n - 1)) * cw;
    double scaleY(double v) => pt + ch - ((v - minV) / (maxV - minV)) * ch;

    // Paint Grid Lines
    final gridPaint = Paint()
      ..color = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    const gridSteps = 4;
    for (int i = 0; i <= gridSteps; i++) {
      final val = minV + (maxV - minV) * (i / gridSteps);
      final y = scaleY(val);
      canvas.drawLine(Offset(pl, y), Offset(size.width - pr, y), gridPaint);

      // Value label
      textPainter.text = TextSpan(
        text: val.toStringAsFixed(1),
        style: TextStyle(color: isDark ? Colors.white60 : Colors.grey, fontSize: 7.5),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(pl - textPainter.width - 4, y - textPainter.height / 2));
    }

    // Paint X-axis labels
    final int labelStep = (n / 4).ceil();
    for (int i = 0; i < n; i += labelStep) {
      final x = scaleX(i);
      textPainter.text = TextSpan(
        text: activeData.labels[i],
        style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600, fontSize: 7.5),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height - pb + 4));
    }

    // Function to draw lines
    void drawRateLine(List<double> data, Color col, double width, {bool fill = false}) {
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

    // Draw Fed Funds
    drawRateLine(ratesFed, const Color(0xFFD97706), 1.5);

    // Draw 10-Yr Treasury
    drawRateLine(rates10, const Color(0xFFF59E0B), 1.5);

    // Draw 30-Yr Fixed
    drawRateLine(rates30, const Color(0xFF1B3F72), 2.5, fill: true);

    // Draw endpoint dot for 30-Yr Fixed
    final lastX = scaleX(n - 1);
    final lastY = scaleY(rates30[n - 1]);
    final dotPaint = Paint()
      ..color = const Color(0xFF1B3F72)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(lastX, lastY), 4.0, dotPaint);

    textPainter.text = TextSpan(
      text: '${rates30[n - 1]}%',
      style: const TextStyle(color: Color(0xFF1B3F72), fontSize: 8.5, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(lastX - textPainter.width - 6, lastY - textPainter.height - 4));
  }

  @override
  bool shouldRepaint(covariant _FredRateHistoryPainter oldDelegate) =>
      oldDelegate.activeData != activeData || oldDelegate.isDark != isDark;
}
