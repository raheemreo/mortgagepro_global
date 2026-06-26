// lib/shared/widgets/amortization_chart.dart
// fl_chart AreaChart — principal vs interest over term

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../app/theme/country_themes.dart';
import '../../core/utils/mortgage_math.dart';
import '../../core/utils/currency_formatter.dart';
import '../../app/theme/text_styles.dart';

class AmortizationChart extends StatefulWidget {
  final List<AmortizationEntry> schedule;
  final CountryTheme theme;
  final String currencyCode;
  final double? extraMonthlySaving;

  const AmortizationChart({
    super.key,
    required this.schedule,
    required this.theme,
    required this.currencyCode,
    this.extraMonthlySaving,
  });

  @override
  State<AmortizationChart> createState() => _AmortizationChartState();
}

class _AmortizationChartState extends State<AmortizationChart> {
  bool _showYearly = true;

  List<Map<String, double>> get _yearlyData {
    final Map<int, Map<String, double>> yearMap = {};
    for (final entry in widget.schedule) {
      final yr = entry.year;
      yearMap[yr] ??= {'principal': 0, 'interest': 0, 'balance': 0};
      yearMap[yr]!['principal'] =
          (yearMap[yr]!['principal'] ?? 0) + entry.principal;
      yearMap[yr]!['interest'] =
          (yearMap[yr]!['interest'] ?? 0) + entry.interest;
      yearMap[yr]!['balance'] = entry.balance;
    }
    return yearMap.entries
        .map((e) => {
              'year': e.key.toDouble(),
              'principal': e.value['principal']!,
              'interest': e.value['interest']!,
              'balance': e.value['balance']!,
            })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final data = _yearlyData;
    if (data.isEmpty) return const SizedBox.shrink();

    final primaryColor = widget.theme.primaryColor;
    final accentColor = widget.theme.accentColor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Amortization Schedule',
                style: AppTextStyles.infoTitle(const Color(0xFF061528)),
              ),
              Row(
                children: [
                  _Toggle(
                    label: 'Yearly',
                    active: _showYearly,
                    color: primaryColor,
                    onTap: () => setState(() => _showYearly = true),
                  ),
                  const SizedBox(width: 6),
                  _Toggle(
                    label: 'Monthly',
                    active: !_showYearly,
                    color: primaryColor,
                    onTap: () => setState(() => _showYearly = false),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: data.first['balance']! / 4,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                  drawVerticalLine: false,
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (data.length / 5).roundToDouble().clamp(1, 999),
                      getTitlesWidget: (value, meta) => Text(
                        'Yr ${value.toInt()}',
                        style: AppTextStyles.rateNote(const Color(0xFF9CA3AF)),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Balance line
                  LineChartBarData(
                    spots: data
                        .map((d) => FlSpot(d['year']!, d['balance']!))
                        .toList(),
                    isCurved: true,
                    color: primaryColor,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: primaryColor.withValues(alpha: 0.10),
                    ),
                  ),
                  // Total interest line
                  LineChartBarData(
                    spots: data
                        .map((d) => FlSpot(d['year']!, d['interest']!))
                        .toList(),
                    isCurved: true,
                    color: accentColor.withValues(alpha: 0.7),
                    barWidth: 1.5,
                    dotData: const FlDotData(show: false),
                    dashArray: [5, 3],
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots.map((s) {
                      final isBalance = s.barIndex == 0;
                      return LineTooltipItem(
                        '${isBalance ? "Balance" : "Interest"}\n${CurrencyFormatter.compact(s.y, symbol: CurrencyFormatter.compactForCountry(1, widget.currencyCode).substring(0, 1))}',
                        AppTextStyles.dmSans(
                          size: 10,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            children: [
              _LegendDot(color: primaryColor, label: 'Balance'),
              const SizedBox(width: 16),
              _LegendDot(
                color: accentColor.withValues(alpha: 0.7),
                label: 'Yearly Interest',
                dashed: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _Toggle({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? color : color.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.w700,
            color: active ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _LegendDot({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 2.5,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.rateNote(const Color(0xFF6B7280)),
        ),
      ],
    );
  }
}
