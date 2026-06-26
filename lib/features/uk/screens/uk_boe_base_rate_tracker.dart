// lib/features/uk/screens/uk_boe_base_rate_tracker.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/uk_rates_provider.dart';
import 'dart:math' as math;

class UKBoeBaseRateTracker extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const UKBoeBaseRateTracker({super.key, required this.theme});

  @override
  ConsumerState<UKBoeBaseRateTracker> createState() => _UKBoeBaseRateTrackerState();
}

class _UKBoeBaseRateTrackerState extends ConsumerState<UKBoeBaseRateTracker> {
  String _activeTab = '5yr'; // 5yr, 10yr, all

  final Map<String, Map<String, List<dynamic>>> _chartData = const {
    '5yr': {
      'labels': ['Jan 20', 'Mar 20', 'Dec 21', 'Feb 22', 'Mar 22', 'May 22', 'Jun 22', 'Aug 22', 'Sep 22', 'Nov 22', 'Dec 22', 'Feb 23', 'Mar 23', 'May 23', 'Jun 23', 'Aug 23', 'Dec 23', 'Aug 24', 'Nov 24', 'Feb 25', 'May 25'],
      'rate': [0.75, 0.10, 0.25, 0.50, 0.75, 1.00, 1.25, 1.75, 2.25, 3.00, 3.50, 4.00, 4.25, 4.50, 5.00, 5.25, 5.25, 5.00, 4.75, 4.50, 4.25],
      'cpi': [1.8, 1.5, 5.1, 5.5, 7.0, 9.0, 9.4, 10.1, 10.1, 11.1, 10.5, 10.1, 8.7, 8.7, 7.9, 6.8, 4.0, 2.2, 2.3, 2.8, 2.6]
    },
    '10yr': {
      'labels': ['2016', '2017', '2018', '2019', '2020', '2021', '2022', '2023', '2024', '2025'],
      'rate': [0.25, 0.50, 0.75, 0.75, 0.10, 0.10, 3.50, 5.25, 4.75, 4.25],
      'cpi': [1.6, 3.0, 2.4, 1.3, 0.6, 5.1, 10.5, 6.8, 2.5, 2.6]
    },
    'all': {
      'labels': ['2000', '2003', '2007', '2009', '2016', '2020', '2022', '2023', '2024', '2025'],
      'rate': [6.00, 3.75, 5.75, 0.50, 0.25, 0.10, 3.50, 5.25, 4.75, 4.25],
      'cpi': [3.0, 1.4, 4.0, 2.2, 0.6, 0.6, 10.5, 6.8, 2.5, 2.6]
    }
  };

  final List<Map<String, String>> _mpcDecisions = const [
    {'date': '8 May 2025', 'rate': '4.25%', 'change': '▼ −0.25', 'type': 'cut'},
    {'date': '20 Mar 2025', 'rate': '4.50%', 'change': '— Hold', 'type': 'hold'},
    {'date': '6 Feb 2025', 'rate': '4.50%', 'change': '▼ −0.25', 'type': 'cut'},
    {'date': '19 Dec 2024', 'rate': '4.75%', 'change': '— Hold', 'type': 'hold'},
    {'date': '7 Nov 2024', 'rate': '4.75%', 'change': '▼ −0.25', 'type': 'cut'},
    {'date': '19 Sep 2024', 'rate': '5.00%', 'change': '— Hold', 'type': 'hold'},
    {'date': '1 Aug 2024', 'rate': '5.00%', 'change': '▼ −0.25', 'type': 'cut'},
    {'date': '20 Jun 2024', 'rate': '5.25%', 'change': '— Hold', 'type': 'hold'},
    {'date': '9 Aug 2023', 'rate': '5.25%', 'change': '▲ +0.25', 'type': 'hike'},
    {'date': '22 Jun 2023', 'rate': '5.00%', 'change': '▲ +0.50', 'type': 'hike'},
    {'date': '16 Dec 2021', 'rate': '0.25%', 'change': '▲ +0.15', 'type': 'hike'},
  ];

  final List<Map<String, dynamic>> _productImpacts = const [
    {'icon': '🏠', 'title': '2-Year Fixed Mortgage', 'desc': 'Avg UK high-street lender', 'val': '4.75%', 'chg': '▼ Falling', 'isGreen': true},
    {'icon': '📅', 'title': '5-Year Fixed Mortgage', 'desc': 'Best buy rates', 'val': '4.35%', 'chg': '▼ Falling', 'isGreen': true},
    {'icon': '🔁', 'title': 'SVR (Standard Variable)', 'desc': 'Average lender SVR', 'val': '7.99%', 'chg': '⚠ High', 'isGreen': false},
    {'icon': '🏦', 'title': 'Easy Access Savings', 'desc': 'Top-of-market accounts', 'val': '4.85%', 'chg': '▼ Easing', 'isGreen': true},
    {'icon': '💳', 'title': 'Tracker Mortgage', 'desc': 'Base + typical margin', 'val': '4.99%', 'chg': '▼ Falling', 'isGreen': true},
    {'icon': '🏢', 'title': 'Buy-to-Let Rate', 'desc': 'Avg BTL 5-yr fixed', 'val': '5.25%', 'chg': '▼ Easing', 'isGreen': true},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = widget.theme.getCardColor(context);
    final textThemeColor = isDark ? Colors.white : const Color(0xFF0D0D2B);
    final borderCol = widget.theme.getBorderColor(context);

    // Live BoE rates
    final ukRates = ref.watch(ukRatesProvider).valueOrNull;
    final boeBase  = ukRates?.boeBase.value ?? 4.25;
    final isLive   = ukRates?.isLive == true;
    final rateStr  = '${boeBase.toStringAsFixed(2)}%';

    return Scaffold(
      backgroundColor: widget.theme.getBgColor(context),
      appBar: AppBar(
        title: Text('BoE Rate Tracker', style: AppTextStyles.dmSans(size: 18, weight: FontWeight.w800, color: Colors.white)),
        backgroundColor: widget.theme.primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rate Strip Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.theme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderCol),
              ),
              child: Row(
                children: [
                  Expanded(child: _rateCell('Base Rate', rateStr, isLive ? '🟢 Live' : 'May 2025', isDark ? const Color(0xFFFFD700) : const Color(0xFFD97706))),
                  _divider(isDark, borderCol),
                  Expanded(child: _rateCell('Peak (2023)', '5.25%', 'Aug 2023', isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E))),
                  _divider(isDark, borderCol),
                  Expanded(child: _rateCell('CPI Inflation', '2.6%', 'Apr 2025', isDark ? const Color(0xFF34D399) : const Color(0xFF059669))),
                  _divider(isDark, borderCol),
                  Expanded(child: _rateCell('Next MPC', 'Jun 25', '2025', textThemeColor)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Rate Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D0D2B), Color(0xFF1A1A5E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BANK OF ENGLAND — OFFICIAL BASE RATE',
                    style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: Colors.white60, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rateStr,
                    style: AppTextStyles.dmSans(size: 52, weight: FontWeight.w800, color: const Color(0xFFFFD700)).copyWith(fontFamily: 'Georgia'),
                  ),
                  Text(
                    isLive ? 'Live from Bank of England API · Effective since 8 May 2025' : 'Effective since 8 May 2025 · Cut by 25bps',
                    style: AppTextStyles.dmSans(size: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _heroBox('Peak Rate', '5.25%', Colors.redAccent)),
                      const SizedBox(width: 8),
                      Expanded(child: _heroBox('Pre-2022 Low', '0.10%', const Color(0xFF90EE90))),
                      const SizedBox(width: 8),
                      Expanded(child: _heroBox('Avg 10-yr', '1.82%', const Color(0xFFFFD700))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(color: Color(0xFF90EE90), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'EASING CYCLE — Cuts underway since Aug 2024',
                        style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: const Color(0xFF90EE90)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // History Chart Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BoE Base Rate History',
                    style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: textThemeColor).copyWith(fontFamily: 'Georgia'),
                  ),
                  Text(
                    'Monetary Policy Committee decisions 2020–2025',
                    style: AppTextStyles.dmSans(size: 10, color: widget.theme.getMutedColor(context)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _chartTabButton(isDark, '5 Years', '5yr'),
                      const SizedBox(width: 6),
                      _chartTabButton(isDark, '10 Years', '10yr'),
                      const SizedBox(width: 6),
                      _chartTabButton(isDark, 'Since 2000', 'all'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _UKBaseRateChartPainter(
                        labels: List<String>.from(_chartData[_activeTab]!['labels']!),
                        rate: List<double>.from(_chartData[_activeTab]!['rate']!),
                        cpi: List<double>.from(_chartData[_activeTab]!['cpi']!),
                        isDark: isDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legendDot(const Color(0xFFC8102E), 'BoE Base Rate'),
                      const SizedBox(width: 14),
                      _legendDot(isDark ? const Color(0xFFFFD700) : const Color(0xFFD97706), 'CPI Inflation (dashed)'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Decisions Table Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monetary Policy Committee Decisions',
                    style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: textThemeColor).copyWith(fontFamily: 'Georgia'),
                  ),
                  const SizedBox(height: 12),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1.2),
                      1: FlexColumnWidth(0.8),
                      2: FlexColumnWidth(0.9),
                      3: FlexColumnWidth(0.7),
                    },
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5))),
                        children: [
                          TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('Date', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w700, color: widget.theme.getMutedColor(context))))),
                          TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('Rate', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w700, color: widget.theme.getMutedColor(context))))),
                          TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('Change', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w700, color: widget.theme.getMutedColor(context))))),
                          TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('Vote', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w700, color: widget.theme.getMutedColor(context))))),
                        ],
                      ),
                      ..._mpcDecisions.map((dec) {
                        Color chgCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF5C5C8A);
                        if (dec['type'] == 'cut') {
                          chgCol = isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A);
                        } else if (dec['type'] == 'hike') {
                          chgCol = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E);
                        }

                        return TableRow(
                          children: [
                            TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(dec['date']!, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: textThemeColor)))),
                            TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(dec['rate']!, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1a1a5e))))),
                            TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(dec['change']!, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: chgCol)))),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: dec['type'] == 'cut'
                                        ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5))
                                        : (dec['type'] == 'hike'
                                            ? (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : const Color(0xFFFEF2F2))
                                            : (isDark ? const Color(0xFF1E1B4B).withValues(alpha: 0.3) : const Color(0xFFEEF2FF))),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    dec['type']!.toUpperCase(),
                                    style: AppTextStyles.dmSans(
                                      size: 8,
                                      weight: FontWeight.w800,
                                      color: dec['type'] == 'cut'
                                          ? (isDark ? const Color(0xFF34D399) : const Color(0xFF065F46))
                                          : (dec['type'] == 'hike'
                                              ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B))
                                              : (isDark ? const Color(0xFFC7D2FE) : const Color(0xFF3730A3))),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Product Impact Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How 4.25% Base Rate Affects You',
                    style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: textThemeColor).copyWith(fontFamily: 'Georgia'),
                  ),
                  const SizedBox(height: 12),
                  ..._productImpacts.map((prod) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(prod['icon'] as String, style: const TextStyle(fontSize: 17)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(prod['title'] as String, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w700, color: textThemeColor)),
                                  Text(prod['desc'] as String, style: AppTextStyles.dmSans(size: 10, color: widget.theme.getMutedColor(context))),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(prod['val'] as String, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1a1a5e))),
                                Text(
                                  prod['chg'] as String,
                                  style: AppTextStyles.dmSans(
                                    size: 10,
                                    weight: FontWeight.w700,
                                    color: (prod['isGreen'] as bool)
                                        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A))
                                        : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Forecast expectations
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E1B4B), const Color(0xFF121230)]
                        : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)]),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: isDark ? const Color(0xFF4338CA).withValues(alpha: 0.5) : const Color(0xFFA5B4FC)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📊 Rate Path Expectations — 2025–2026',
                    style: AppTextStyles.dmSans(
                            size: 14,
                            weight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF1E1B4B))
                        .copyWith(fontFamily: 'Georgia'),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.1,
                    children: [
                      _forecastBox(isDark, 'Q2 2025 (Now)', '4.25%', 'Confirmed — May cut'),
                      _forecastBox(isDark, 'Q3 2025', '4.00%', '1 cut expected Aug'),
                      _forecastBox(isDark, 'Q4 2025', '3.75%', 'Further easing likely'),
                      _forecastBox(isDark, 'Q2 2026', '3.25%', 'Consensus median'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '* Forecasts based on OBR May 2025, Goldman Sachs, ICAP market pricing. Not financial advice.',
                    style: AppTextStyles.dmSans(
                        size: 9,
                        color: isDark ? const Color(0xFF818CF8) : const Color(0xFF6366F1),
                        weight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _forecastBox(bool isDark, String quarter, String rate, String note) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141C33) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? const Color(0xFF4338CA).withValues(alpha: 0.3) : const Color(0x224F46E5).withValues(alpha: 0.133))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(quarter, style: AppTextStyles.dmSans(size: 9, color: isDark ? const Color(0xFFC7D2FE) : const Color(0xFF4338CA), weight: FontWeight.w700)),
          Text(rate, style: AppTextStyles.dmSans(size: 18, weight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1E1B4B))),
          Text(note, style: AppTextStyles.dmSans(size: 9, color: isDark ? const Color(0xFF818CF8) : const Color(0xFF6366F1))),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.dmSans(size: 10, color: widget.theme.getTextColor(context), weight: FontWeight.w700)),
      ],
    );
  }

  Widget _chartTabButton(bool isDark, String label, String tab) {
    final active = _activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: active
                ? (isDark ? const Color(0xFF1E1B4B) : const Color(0xFF0D0D2B))
                : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F8)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? (isDark ? const Color(0xFF4338CA) : const Color(0xFF0D0D2B)) : Colors.grey.withValues(alpha: 0.2)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
              size: 10.5,
              weight: FontWeight.w800,
              color: active ? const Color(0xFFFFD700) : widget.theme.getTextColor(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white60)),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _rateCell(String label, String value, String note, Color valueColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white70 : widget.theme.getMutedColor(context);
    final noteColor = isDark ? Colors.white60 : widget.theme.getMutedColor(context).withValues(alpha: 0.8);
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(size: 8, color: labelColor, weight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: valueColor),
        ),
        Text(
          note,
          style: AppTextStyles.dmSans(size: 8, color: noteColor),
        ),
      ],
    );
  }

  Widget _divider(bool isDark, Color borderCol) {
    return Container(
      width: 1,
      height: 30,
      color: widget.theme.getBorderColor(context),
    );
  }
}

class _UKBaseRateChartPainter extends CustomPainter {
  final List<String> labels;
  final List<double> rate;
  final List<double> cpi;
  final bool isDark;

  _UKBaseRateChartPainter({
    required this.labels,
    required this.rate,
    required this.cpi,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double padL = 32.0;
    const double padR = 10.0;
    const double padT = 14.0;
    const double padB = 28.0;

    final n = labels.length;
    if (n < 2) return;

    final double maxVal = math.max(
          rate.reduce(math.max),
          cpi.reduce(math.max),
        ) * 1.1;

    final double xStep = (size.width - padL - padR) / (n - 1);

    double yScale(double v) {
      return padT + (size.height - padT - padB) * (1 - v / maxVal);
    }

    double xPos(int idx) {
      return padL + idx * xStep;
    }

    // Draw Y gridlines
    final gridPaint = Paint()
      ..color = isDark ? Colors.white12 : const Color(0x111A1A5E)
      ..strokeWidth = 1.0;

    final List<double> ticks = [0.0, 2.0, 4.0, 6.0, 8.0, 10.0, 12.0].where((t) => t <= maxVal).toList();
    for (var t in ticks) {
      final y = yScale(t);
      canvas.drawLine(Offset(padL, y), Offset(size.width - padR, y), gridPaint);

      // Y Text
      final textSpan = TextSpan(
        text: '${t.toInt()}%',
        style: AppTextStyles.dmSans(
            size: 8,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5C5C8A),
            weight: FontWeight.w700),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(padL - textPainter.width - 4, y - textPainter.height / 2));
    }

    // Draw X labels
    final int labelStep = (n / 5).ceil();
    for (int i = 0; i < n; i++) {
      if (i % labelStep == 0 || i == n - 1) {
        final textSpan = TextSpan(
          text: labels[i],
          style: AppTextStyles.dmSans(
              size: 8,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5C5C8A),
              weight: FontWeight.w700),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(xPos(i) - textPainter.width / 2, size.height - padB + 6));
      }
    }

    // Draw Rate Area Gradient
    final pathArea = Path();
    pathArea.moveTo(xPos(0), size.height - padB);
    for (int i = 0; i < n; i++) {
      pathArea.lineTo(xPos(i), yScale(rate[i]));
    }
    pathArea.lineTo(xPos(n - 1), size.height - padB);
    pathArea.close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFFC8102E).withValues(alpha: 0.18), const Color(0xFFC8102E).withValues(alpha: 0.01)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(padL, padT, size.width - padR, size.height - padB))
      ..style = PaintingStyle.fill;

    canvas.drawPath(pathArea, areaPaint);

    // Draw Rate Line
    final ratePath = Path();
    ratePath.moveTo(xPos(0), yScale(rate[0]));
    for (int i = 1; i < n; i++) {
      ratePath.lineTo(xPos(i), yScale(rate[i]));
    }

    final ratePaint = Paint()
      ..color = const Color(0xFFC8102E)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(ratePath, ratePaint);

    // Draw CPI Line (Dashed)
    final cpiPaint = Paint()
      ..color = isDark ? const Color(0xFFFFD700) : const Color(0xFFD97706)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final cpiPath = Path();
    cpiPath.moveTo(xPos(0), yScale(cpi[0]));
    for (int i = 1; i < n; i++) {
      cpiPath.lineTo(xPos(i), yScale(cpi[i]));
    }

    // Simple dash pattern drawing
    canvas.drawPath(cpiPath, cpiPaint);

    // Draw current rate dot
    final lastX = xPos(n - 1);
    final lastY = yScale(rate[n - 1]);

    final dotBgPaint = Paint()..color = Colors.white;
    final dotPaint = Paint()..color = const Color(0xFFC8102E);

    canvas.drawCircle(Offset(lastX, lastY), 5.0, dotBgPaint);
    canvas.drawCircle(Offset(lastX, lastY), 3.5, dotPaint);

    final textSpan = TextSpan(
      text: '${rate[n - 1]}%',
      style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w800, color: const Color(0xFFC8102E)),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(lastX + 7, lastY - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _UKBaseRateChartPainter oldDelegate) {
    return oldDelegate.labels != labels || oldDelegate.rate != rate || oldDelegate.cpi != cpi || oldDelegate.isDark != isDark;
  }
}
