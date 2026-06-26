// lib/features/uk/screens/uk_house_price_index.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import 'dart:math' as math;

class UKHousePriceIndex extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const UKHousePriceIndex({super.key, required this.theme});

  @override
  ConsumerState<UKHousePriceIndex> createState() => _UKHousePriceIndexState();
}

class _UKHousePriceIndexState extends ConsumerState<UKHousePriceIndex> {
  String _activeTab = 'England'; // England, Devolved, Top

  final Map<String, List<Map<String, dynamic>>> _regions = const {
    'England': [
      {'flag': '🏙️', 'name': 'London', 'price': 523000.0, 'chg': '+3.4%', 'bar': 100, 'hl': true},
      {'flag': '🌿', 'name': 'South East', 'price': 388000.0, 'chg': '+4.6%', 'bar': 74, 'hl': false},
      {'flag': '🌾', 'name': 'East of Eng.', 'price': 345000.0, 'chg': '+5.1%', 'bar': 66, 'hl': false},
      {'flag': '🌊', 'name': 'South West', 'price': 318000.0, 'chg': '+4.9%', 'bar': 61, 'hl': false},
      {'flag': '🏭', 'name': 'Midlands', 'price': 255000.0, 'chg': '+6.8%', 'bar': 49, 'hl': false},
      {'flag': '⚽', 'name': 'North West', 'price': 221000.0, 'chg': '+7.2%', 'bar': 42, 'hl': false},
      {'flag': '🎯', 'name': 'Yorkshire', 'price': 207000.0, 'chg': '+6.5%', 'bar': 40, 'hl': false},
      {'flag': '⛏️', 'name': 'North East', 'price': 162000.0, 'chg': '+8.1%', 'bar': 31, 'hl': false},
    ],
    'Devolved': [
      {'flag': '🏴󠁧󠁢󠁳󠁣󠁴󠁿', 'name': 'Scotland', 'price': 196000.0, 'chg': '+5.6%', 'bar': 37, 'hl': true},
      {'flag': '🏴󠁧󠁢󠁷󠁬󠁳󠁿', 'name': 'Wales', 'price': 211000.0, 'chg': '+4.8%', 'bar': 40, 'hl': false},
      {'flag': '🇮🇪', 'name': 'N. Ireland', 'price': 175000.0, 'chg': '+9.4%', 'bar': 33, 'hl': false},
    ],
    'Top': [
      {'flag': '🏙️', 'name': 'London', 'price': 523000.0, 'chg': '+3.4%', 'bar': 100, 'hl': true},
      {'flag': '🎓', 'name': 'Cambridge', 'price': 504000.0, 'chg': '+2.9%', 'bar': 96, 'hl': false},
      {'flag': '🌊', 'name': 'Bristol', 'price': 359000.0, 'chg': '+5.5%', 'bar': 69, 'hl': false},
      {'flag': '🌆', 'name': 'Manchester', 'price': 246000.0, 'chg': '+8.0%', 'bar': 47, 'hl': false},
      {'flag': '⚙️', 'name': 'Birmingham', 'price': 236000.0, 'chg': '+7.1%', 'bar': 45, 'hl': false},
      {'flag': '🌁', 'name': 'Edinburgh', 'price': 322000.0, 'chg': '+6.3%', 'bar': 62, 'hl': false},
    ]
  };

  final List<String> _chartLabels = const ['Jan 20', 'Jun 20', 'Jan 21', 'Jun 21', 'Jan 22', 'Jun 22', 'Jan 23', 'Jun 23', 'Jan 24', 'Jun 24', 'Jan 25', 'Mar 25'];
  final List<double> _chartUk = const [232000, 238000, 249000, 265000, 274000, 293000, 275000, 285000, 282000, 285000, 266000, 268319];
  final List<double> _chartLondon = const [476000, 490000, 500000, 512000, 528000, 542000, 515000, 525000, 519000, 522000, 520000, 523000];

  final List<Map<String, dynamic>> _types = const [
    {'type': '🏢 Flat', 'price': 232000.0, 'chg': '+3.2%', 'vsUk': '−13.5%', 'isChgPos': true, 'isVsPos': false},
    {'type': '🏘️ Terraced', 'price': 236000.0, 'chg': '+4.8%', 'vsUk': '−12.1%', 'isChgPos': true, 'isVsPos': false},
    {'type': '🏠 Semi-Det', 'price': 272000.0, 'chg': '+5.6%', 'vsUk': '+1.4%', 'isChgPos': true, 'isVsPos': true},
    {'type': '🏡 Detached', 'price': 430000.0, 'chg': '+5.1%', 'vsUk': '+60.3%', 'isChgPos': true, 'isVsPos': true},
    {'type': '🔑 New Build', 'price': 312000.0, 'chg': '+6.2%', 'vsUk': '+16.3%', 'isChgPos': true, 'isVsPos': true},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = widget.theme.getCardColor(context);
    final textThemeColor = isDark ? Colors.white : const Color(0xFF0D0D2B);
    final borderCol = widget.theme.getBorderColor(context);

    return Scaffold(
      backgroundColor: widget.theme.getBgColor(context),
      appBar: AppBar(
        title: Text('House Price Index', style: AppTextStyles.dmSans(size: 18, weight: FontWeight.w800, color: Colors.white)),
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
                  Expanded(child: _rateCell('UK Avg', '£268,319', 'Mar 2025', isDark ? const Color(0xFFFFD700) : const Color(0xFFD97706))),
                  _divider(isDark, borderCol),
                  Expanded(child: _rateCell('Annual Chg', '+5.4%', 'YoY', isDark ? const Color(0xFF34D399) : const Color(0xFF059669))),
                  _divider(isDark, borderCol),
                  Expanded(child: _rateCell('London', '£523k', 'Avg Price', textThemeColor)),
                  _divider(isDark, borderCol),
                  Expanded(child: _rateCell('Monthly', '+0.3%', 'MoM', isDark ? const Color(0xFF34D399) : const Color(0xFF059669))),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // National Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
                    'UK AVERAGE HOUSE PRICE — MARCH 2025',
                    style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: Colors.white60, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '£268,319',
                    style: AppTextStyles.dmSans(size: 40, weight: FontWeight.w800, color: Colors.white).copyWith(fontFamily: 'Georgia'),
                  ),
                  Text(
                    'HM Land Registry · UK HPI Official Data',
                    style: AppTextStyles.dmSans(size: 11, color: Colors.white54),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _heroBox('Annual Growth', '+5.4%', const Color(0xFF90EE90))),
                      const SizedBox(width: 8),
                      Expanded(child: _heroBox('Monthly Change', '+0.3%', const Color(0xFF90EE90))),
                      const SizedBox(width: 8),
                      Expanded(child: _heroBox('Peak (2022)', '£292,000', const Color(0xFFFFD700))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.trending_up, color: Color(0xFF90EE90), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Prices rising — 5th consecutive monthly gain',
                        style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: const Color(0xFF90EE90)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Price Trend Chart Card
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
                    'UK Average House Price Trend',
                    style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: textThemeColor).copyWith(fontFamily: 'Georgia'),
                  ),
                  Text(
                    'Monthly — HM Land Registry Official HPI 2020–2025',
                    style: AppTextStyles.dmSans(size: 10, color: widget.theme.getMutedColor(context)),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _UKHpiTrendChartPainter(
                        labels: _chartLabels,
                        uk: _chartUk,
                        london: _chartLondon,
                        isDark: isDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legendDot(isDark ? const Color(0xFF93C5FD) : const Color(0xFF1a1a5e), 'UK Average'),
                      const SizedBox(width: 14),
                      _legendDot(const Color(0xFFC8102E), 'London (dashed)'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Regional Tabs
            Row(
              children: [
                _tabButton('England', 'England'),
                const SizedBox(width: 6),
                _tabButton('Devolved', 'Devolved'),
                const SizedBox(width: 6),
                _tabButton('Top Cities', 'Top'),
              ],
            ),
            const SizedBox(height: 12),

            // Regional Grid Breakdown
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.3,
              ),
              itemCount: _regions[_activeTab]!.length,
              itemBuilder: (context, index) {
                final reg = _regions[_activeTab]![index];
                final double pr = reg['price'] as double;
                final bool hl = reg['hl'] as bool;
                final regValColor = hl ? const Color(0xFFFFD700) : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E));

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: hl
                        ? const LinearGradient(colors: [Color(0xFF0D0D2B), Color(0xFF1A1A5E)])
                        : null,
                    color: hl ? null : cardBg,
                    border: Border.all(color: borderCol),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(reg['flag'] as String, style: const TextStyle(fontSize: 20)),
                          Text(
                            reg['chg'] as String,
                            style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w800, color: isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A)),
                          ),
                        ],
                      ),
                      Text(
                        reg['name'] as String,
                        style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: hl ? Colors.white : textThemeColor).copyWith(fontFamily: 'Georgia'),
                      ),
                      Text(
                        CurrencyFormatter.format(pr, symbol: '£').split('.').first,
                        style: AppTextStyles.dmSans(size: 15, weight: FontWeight.w800, color: regValColor),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Container(
                          height: 4,
                          color: Colors.grey.withValues(alpha: 0.1),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: (reg['bar'] as int) / 100,
                              child: Container(color: regValColor),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // By Property Type Card
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
                  Text(
                    'By Property Type',
                    style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: textThemeColor).copyWith(fontFamily: 'Georgia'),
                  ),
                  const SizedBox(height: 12),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1.2),
                      1: FlexColumnWidth(1.0),
                      2: FlexColumnWidth(0.9),
                      3: FlexColumnWidth(0.9),
                    },
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5))),
                        children: [
                          TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('Type', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w700, color: widget.theme.getMutedColor(context))))),
                          TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('Avg Price', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w700, color: widget.theme.getMutedColor(context))))),
                          TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('Ann. Chg', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w700, color: widget.theme.getMutedColor(context))))),
                          TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('vs UK', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w700, color: widget.theme.getMutedColor(context))))),
                        ],
                      ),
                      ..._types.map((t) {
                        final double pr = t['price'] as double;
                        return TableRow(
                          children: [
                            TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(t['type'] as String, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: textThemeColor)))),
                            TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(CurrencyFormatter.format(pr, symbol: '£').split('.').first, style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1a1a5e))))),
                            TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(t['chg'] as String, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: (t['isChgPos'] as bool) ? (isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A)) : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E)))))),
                            TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(t['vsUk'] as String, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: (t['isVsPos'] as bool) ? (isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A)) : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E)))))),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Affordability metrics ONS Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF4C0519), const Color(0xFF1C0005)]
                        : [const Color(0xFFFEF2FF), const Color(0xFFFEE2FF)]),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: isDark ? const Color(0xFF9F1239).withValues(alpha: 0.5) : const Color(0xFFFCA5A5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💷 House Price Affordability — 2025',
                    style: AppTextStyles.dmSans(
                            size: 14,
                            weight: FontWeight.w800,
                            color: isDark ? const Color(0xFFFECDD3) : const Color(0xFF991B1B))
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
                      _affordBox(isDark, 'Price-to-Income (UK)', '8.0×', 'Avg household income'),
                      _affordBox(isDark, 'Price-to-Income (London)', '12.5×', 'Most unaffordable'),
                      _affordBox(isDark, 'Avg Salary UK', '£34,963', 'ONS ASHE 2024'),
                      _affordBox(isDark, 'Most Affordable', 'N. Ireland', '£175,000 avg'),
                    ],
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

  Widget _affordBox(bool isDark, String label, String value, String note) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141C33) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? const Color(0xFF9F1239).withValues(alpha: 0.3) : const Color(0x22C8102E))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8.5, color: isDark ? const Color(0xFFFECDD3) : const Color(0xFF991B1B), weight: FontWeight.w700)),
          Text(value, style: AppTextStyles.dmSans(size: 16, weight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0D0D2B))),
          Text(note, style: AppTextStyles.dmSans(size: 8.5, color: isDark ? Colors.white54 : Colors.grey)),
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

  Widget _tabButton(String label, String tab) {
    final active = _activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(colors: [Color(0xFFC8102E), Color(0xFF8B0A1E)])
                : null,
            color: active
                ? null
                : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? Colors.transparent : Colors.grey.withValues(alpha: 0.2)),
            boxShadow: active
                ? [BoxShadow(color: const Color(0xFFC8102E).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
              size: 10.5,
              weight: FontWeight.w800,
              color: active ? Colors.white : widget.theme.getTextColor(context),
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
      color: isDark ? Colors.white24 : borderCol,
    );
  }
}

class _UKHpiTrendChartPainter extends CustomPainter {
  final List<String> labels;
  final List<double> uk;
  final List<double> london;
  final bool isDark;

  _UKHpiTrendChartPainter({
    required this.labels,
    required this.uk,
    required this.london,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double padL = 46.0;
    const double padR = 12.0;
    const double padT = 14.0;
    const double padB = 28.0;

    final n = labels.length;
    if (n < 2) return;

    final List<double> allVals = [...uk, ...london];
    final double maxVal = allVals.reduce(math.max) * 1.05;
    final double minVal = allVals.reduce(math.min) * 0.95;

    final double xStep = (size.width - padL - padR) / (n - 1);

    double yScale(double v) {
      return padT + (size.height - padT - padB) * (1 - (v - minVal) / (maxVal - minVal));
    }

    double xPos(int idx) {
      return padL + idx * xStep;
    }

    // Y Gridlines
    final gridPaint = Paint()
      ..color = isDark ? Colors.white12 : const Color(0x111A1A5E)
      ..strokeWidth = 1.0;

    final List<int> yTicks = [200, 250, 300, 350, 400, 450, 500, 550];
    for (var t in yTicks) {
      final val = t * 1000.0;
      if (val >= minVal && val <= maxVal) {
        final y = yScale(val);
        canvas.drawLine(Offset(padL, y), Offset(size.width - padR, y), gridPaint);

        // Y label
        final textSpan = TextSpan(
          text: '£${t}k',
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
    }

    // X Labels
    final int step = (n / 4).ceil();
    for (int i = 0; i < n; i++) {
      if (i % step == 0 || i == n - 1) {
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

    // UK Area fill
    final areaPath = Path();
    areaPath.moveTo(xPos(0), size.height - padB);
    for (int i = 0; i < n; i++) {
      areaPath.lineTo(xPos(i), yScale(uk[i]));
    }
    areaPath.lineTo(xPos(n - 1), size.height - padB);
    areaPath.close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        colors: isDark
            ? [const Color(0xFF93C5FD).withValues(alpha: 0.15), const Color(0xFF93C5FD).withValues(alpha: 0.01)]
            : [const Color(0xFF1a1a5e).withValues(alpha: 0.15), const Color(0xFF1a1a5e).withValues(alpha: 0.01)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(padL, padT, size.width - padR, size.height - padB))
      ..style = PaintingStyle.fill;

    canvas.drawPath(areaPath, areaPaint);

    // UK Line
    final ukPath = Path();
    ukPath.moveTo(xPos(0), yScale(uk[0]));
    for (int i = 1; i < n; i++) {
      ukPath.lineTo(xPos(i), yScale(uk[i]));
    }

    final ukPaint = Paint()
      ..color = isDark ? const Color(0xFF93C5FD) : const Color(0xFF1a1a5e)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(ukPath, ukPaint);

    // London Line (dashed)
    final lnPath = Path();
    lnPath.moveTo(xPos(0), yScale(london[0]));
    for (int i = 1; i < n; i++) {
      lnPath.lineTo(xPos(i), yScale(london[i]));
    }

    final lnPaint = Paint()
      ..color = const Color(0xFFC8102E)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(lnPath, lnPaint);

    // UK End Dot
    final lastX = xPos(n - 1);
    final lastY = yScale(uk[n - 1]);
    canvas.drawCircle(Offset(lastX, lastY), 5.0, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(lastX, lastY), 3.5, Paint()..color = isDark ? const Color(0xFF93C5FD) : const Color(0xFF1a1a5e));

    // Label on UK end
    final textSpan = TextSpan(
      text: '£${(uk[n - 1] / 1000).round()}k',
      style: AppTextStyles.dmSans(
          size: 9.5,
          weight: FontWeight.w800,
          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1a1a5e)),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(lastX - textPainter.width - 6, lastY - textPainter.height - 4));
  }

  @override
  bool shouldRepaint(covariant _UKHpiTrendChartPainter oldDelegate) {
    return oldDelegate.labels != labels || oldDelegate.uk != uk || oldDelegate.london != london || oldDelegate.isDark != isDark;
  }
}
