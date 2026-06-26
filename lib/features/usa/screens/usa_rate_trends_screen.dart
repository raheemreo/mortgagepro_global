// lib/features/usa/screens/usa_rate_trends_screen.dart

import 'dart:math' as math;
import 'dart:ui' show PathMetric;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../providers/usa_rates_provider.dart';

// ─── Data Structures ─────────────────────────────────────────────────────────

class _ChartData {
  final List<String> labels;
  final List<double> values;
  final List<double> tsyValues;
  const _ChartData({
    required this.labels,
    required this.values,
    required this.tsyValues,
  });
}

class _RateSeries {
  final String title;
  final String sub;
  final String badge;
  final bool isUp;
  final Color color;
  final Map<String, _ChartData> ranges;
  const _RateSeries({
    required this.title,
    required this.sub,
    required this.badge,
    required this.isUp,
    required this.color,
    required this.ranges,
  });
}

class _Milestone {
  final String year;
  final String title;
  final String desc;
  final String rate;
  final Color color;
  const _Milestone(this.year, this.title, this.desc, this.rate, this.color);
}

class _LenderInfo {
  final int rank;
  final String name;
  final String type;
  final String rate;
  final String apr;
  final double progress; // 0.0 - 1.0
  final bool isGreen;
  const _LenderInfo(this.rank, this.name, this.type, this.rate, this.apr, this.progress, {this.isGreen = false});
}

class USARateTrendsScreen extends ConsumerStatefulWidget {
  const USARateTrendsScreen({super.key});

  @override
  ConsumerState<USARateTrendsScreen> createState() => _USARateTrendsScreenState();
}

class _USARateTrendsScreenState extends ConsumerState<USARateTrendsScreen> {
  static const _theme = CountryThemes.usa;

  String _currentType = '30yr';
  String _currentRange = '6m';
  int? _hoverIndex;

  final _alertRateController = TextEditingController(text: '6.50');
  String _alertLoanType = '30-Yr Fixed';
  bool _alertSaved = false;

  // Static datasets matching HTML
  static const Map<String, _RateSeries> _datasets = {
    '30yr': _RateSeries(
      title: '30-Year Fixed Mortgage Rate',
      sub: 'Freddie Mac Primary Mortgage Market Survey',
      badge: '↑ +0.05 wk',
      isUp: true,
      color: Color(0xFF1B3F72),
      ranges: {
        '1m': _ChartData(labels: ['May 8', 'May 15', 'May 22', 'May 29', 'Jun 5'], values: [6.76, 6.81, 6.77, 6.77, 6.82], tsyValues: [4.44, 4.50, 4.47, 4.50, 4.47]),
        '3m': _ChartData(labels: ['Mar', 'Apr', 'May', 'Jun'], values: [6.65, 6.82, 6.77, 6.82], tsyValues: [4.22, 4.50, 4.50, 4.47]),
        '6m': _ChartData(labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'], values: [6.96, 6.87, 6.65, 6.82, 6.77, 6.82], tsyValues: [4.57, 4.42, 4.22, 4.50, 4.50, 4.47]),
        '1y': _ChartData(labels: ['Jun 24', 'Sep 24', 'Dec 24', 'Mar 25', 'Jun 25'], values: [6.86, 6.09, 6.72, 6.65, 6.82], tsyValues: [4.36, 3.77, 4.39, 4.22, 4.47]),
        '3y': _ChartData(labels: ['2022', '2023', '2024', '2025'], values: [3.76, 6.81, 6.72, 6.82], tsyValues: [2.75, 3.88, 4.39, 4.47]),
        '5y': _ChartData(labels: ['2021', '2022', '2023', '2024', '2025'], values: [2.65, 3.76, 7.79, 6.72, 6.82], tsyValues: [1.52, 2.75, 3.88, 4.39, 4.47]),
      },
    ),
    '15yr': _RateSeries(
      title: '15-Year Fixed Mortgage Rate',
      sub: 'Freddie Mac · National Average',
      badge: '↓ −0.02 wk',
      isUp: false,
      color: Color(0xFF15803D),
      ranges: {
        '1m': _ChartData(labels: ['May 8', 'May 15', 'May 22', 'May 29', 'Jun 5'], values: [6.14, 6.16, 6.13, 6.13, 6.11], tsyValues: [4.44, 4.50, 4.47, 4.50, 4.47]),
        '3m': _ChartData(labels: ['Mar', 'Apr', 'May', 'Jun'], values: [6.04, 6.10, 6.13, 6.11], tsyValues: [4.22, 4.50, 4.50, 4.47]),
        '6m': _ChartData(labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'], values: [6.28, 6.18, 6.04, 6.10, 6.13, 6.11], tsyValues: [4.57, 4.42, 4.22, 4.50, 4.50, 4.47]),
        '1y': _ChartData(labels: ['Jun 24', 'Sep 24', 'Dec 24', 'Mar 25', 'Jun 25'], values: [6.19, 5.38, 6.04, 6.04, 6.11], tsyValues: [4.36, 3.77, 4.39, 4.22, 4.47]),
        '3y': _ChartData(labels: ['2022', '2023', '2024', '2025'], values: [3.10, 6.11, 6.04, 6.11], tsyValues: [2.75, 3.88, 4.39, 4.47]),
        '5y': _ChartData(labels: ['2021', '2022', '2023', '2024', '2025'], values: [2.16, 3.10, 7.02, 6.04, 6.11], tsyValues: [1.52, 2.75, 3.88, 4.39, 4.47]),
      },
    ),
    'arm': _RateSeries(
      title: '5/1 Adjustable-Rate Mortgage',
      sub: 'National Average · First 5 years fixed',
      badge: '↓ −0.03 wk',
      isUp: false,
      color: Color(0xFFD97706),
      ranges: {
        '1m': _ChartData(labels: ['May 8', 'May 15', 'May 22', 'May 29', 'Jun 5'], values: [6.12, 6.10, 6.08, 6.08, 6.05], tsyValues: [4.44, 4.50, 4.47, 4.50, 4.47]),
        '3m': _ChartData(labels: ['Mar', 'Apr', 'May', 'Jun'], values: [6.00, 6.05, 6.08, 6.05], tsyValues: [4.22, 4.50, 4.50, 4.47]),
        '6m': _ChartData(labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'], values: [6.25, 6.10, 6.00, 6.05, 6.08, 6.05], tsyValues: [4.57, 4.42, 4.22, 4.50, 4.50, 4.47]),
        '1y': _ChartData(labels: ['Jun 24', 'Sep 24', 'Dec 24', 'Mar 25', 'Jun 25'], values: [6.25, 5.85, 6.00, 6.00, 6.05], tsyValues: [4.36, 3.77, 4.39, 4.22, 4.47]),
        '3y': _ChartData(labels: ['2022', '2023', '2024', '2025'], values: [3.36, 6.30, 6.00, 6.05], tsyValues: [2.75, 3.88, 4.39, 4.47]),
        '5y': _ChartData(labels: ['2021', '2022', '2023', '2024', '2025'], values: [2.40, 3.36, 6.89, 6.00, 6.05], tsyValues: [1.52, 2.75, 3.88, 4.39, 4.47]),
      },
    ),
    'jumbo': _RateSeries(
      title: 'Jumbo 30-Year Mortgage Rate',
      sub: 'Loans above \$766,550 conforming limit',
      badge: '↑ +0.08 wk',
      isUp: true,
      color: Color(0xFF6D28D9),
      ranges: {
        '1m': _ChartData(labels: ['May 8', 'May 15', 'May 22', 'May 29', 'Jun 5'], values: [6.92, 6.98, 6.96, 6.96, 7.04], tsyValues: [4.44, 4.50, 4.47, 4.50, 4.47]),
        '3m': _ChartData(labels: ['Mar', 'Apr', 'May', 'Jun'], values: [6.85, 6.97, 6.96, 7.04], tsyValues: [4.22, 4.50, 4.50, 4.47]),
        '6m': _ChartData(labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'], values: [7.10, 7.00, 6.85, 6.97, 6.96, 7.04], tsyValues: [4.57, 4.42, 4.22, 4.50, 4.50, 4.47]),
        '1y': _ChartData(labels: ['Jun 24', 'Sep 24', 'Dec 24', 'Mar 25', 'Jun 25'], values: [7.11, 6.35, 6.85, 6.85, 7.04], tsyValues: [4.36, 3.77, 4.39, 4.22, 4.47]),
        '3y': _ChartData(labels: ['2022', '2023', '2024', '2025'], values: [3.90, 7.20, 6.85, 7.04], tsyValues: [2.75, 3.88, 4.39, 4.47]),
        '5y': _ChartData(labels: ['2021', '2022', '2023', '2024', '2025'], values: [2.70, 3.90, 7.96, 6.85, 7.04], tsyValues: [1.52, 2.75, 3.88, 4.39, 4.47]),
      },
    ),
    'va': _RateSeries(
      title: 'VA Home Loan Rate',
      sub: 'Veterans Affairs · No PMI · 0% down',
      badge: '↑ +0.01 wk',
      isUp: true,
      color: Color(0xFF0F766E),
      ranges: {
        '1m': _ChartData(labels: ['May 8', 'May 15', 'May 22', 'May 29', 'Jun 5'], values: [6.20, 6.24, 6.22, 6.24, 6.25], tsyValues: [4.44, 4.50, 4.47, 4.50, 4.47]),
        '3m': _ChartData(labels: ['Mar', 'Apr', 'May', 'Jun'], values: [6.10, 6.18, 6.24, 6.25], tsyValues: [4.22, 4.50, 4.50, 4.47]),
        '6m': _ChartData(labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'], values: [6.40, 6.28, 6.10, 6.18, 6.24, 6.25], tsyValues: [4.57, 4.42, 4.22, 4.50, 4.50, 4.47]),
        '1y': _ChartData(labels: ['Jun 24', 'Sep 24', 'Dec 24', 'Mar 25', 'Jun 25'], values: [6.30, 5.75, 6.10, 6.10, 6.25], tsyValues: [4.36, 3.77, 4.39, 4.22, 4.47]),
        '3y': _ChartData(labels: ['2022', '2023', '2024', '2025'], values: [3.40, 6.50, 6.10, 6.25], tsyValues: [2.75, 3.88, 4.39, 4.47]),
        '5y': _ChartData(labels: ['2021', '2022', '2023', '2024', '2025'], values: [2.48, 3.40, 7.48, 6.10, 6.25], tsyValues: [1.52, 2.75, 3.88, 4.39, 4.47]),
      },
    ),
    'fha': _RateSeries(
      title: 'FHA 30-Year Mortgage Rate',
      sub: '3.5% minimum down · FHA rules apply',
      badge: '→ unchanged',
      isUp: false,
      color: Color(0xFFB91C1C),
      ranges: {
        '1m': _ChartData(labels: ['May 8', 'May 15', 'May 22', 'May 29', 'Jun 5'], values: [6.52, 6.58, 6.56, 6.55, 6.55], tsyValues: [4.44, 4.50, 4.47, 4.50, 4.47]),
        '3m': _ChartData(labels: ['Mar', 'Apr', 'May', 'Jun'], values: [6.42, 6.52, 6.55, 6.55], tsyValues: [4.22, 4.50, 4.50, 4.47]),
        '6m': _ChartData(labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'], values: [6.72, 6.58, 6.42, 6.52, 6.55, 6.55], tsyValues: [4.57, 4.42, 4.22, 4.50, 4.50, 4.47]),
        '1y': _ChartData(labels: ['Jun 24', 'Sep 24', 'Dec 24', 'Mar 25', 'Jun 25'], values: [6.60, 5.92, 6.42, 6.42, 6.55], tsyValues: [4.36, 3.77, 4.39, 4.22, 4.47]),
        '3y': _ChartData(labels: ['2022', '2023', '2024', '2025'], values: [3.60, 6.84, 6.42, 6.55], tsyValues: [2.75, 3.88, 4.39, 4.47]),
        '5y': _ChartData(labels: ['2021', '2022', '2023', '2024', '2025'], values: [2.55, 3.60, 7.58, 6.42, 6.55], tsyValues: [1.52, 2.75, 3.88, 4.39, 4.47]),
      },
    ),
  };

  static const List<_Milestone> _milestones = [
    _Milestone('1981', 'All-Time High — Volcker Era', 'Fed Chair Paul Volcker raised rates aggressively to fight 14% inflation. US economy entered recession.', '18.63%', Color(0xFFB91C1C)),
    _Milestone('2021', 'All-Time Low — COVID Era', 'Pandemic-era stimulus drove 30-yr rates to record lows. Refinance boom surged to \$2.8T in 2021.', '2.65%', Color(0xFF15803D)),
    _Milestone('2023', '20-Year High — Inflation Fight', 'Fastest Fed rate-hike cycle since 1980 pushed 30-yr to highest level since 2000.', '7.79%', Color(0xFFB91C1C)),
    _Milestone('2000', 'Pre-Crisis Average', 'Long-run average from 2000–2019. Rates above 6% were historically considered normal.', '6.29%', Color(0xFF1D4ED8)),
    _Milestone('Today', 'Current Rate · Jun 2025', 'Above long-run average. Affordability remains stretched vs 2021 lows at a \$400K home.', '6.82%', Color(0xFF1B3F72)),
  ];

  static const List<_LenderInfo> _lenders = [
    _LenderInfo(1, 'Rocket Mortgage', 'Online · Largest US lender', '6.79%', 'APR 7.01%', 0.95),
    _LenderInfo(2, 'United Wholesale', 'Wholesale · broker channel', '6.81%', 'APR 7.04%', 0.90),
    _LenderInfo(3, 'Chase Bank', 'Retail bank · full service', '6.88%', 'APR 7.10%', 0.80),
    _LenderInfo(4, 'Wells Fargo', 'Retail bank · nationwide', '6.91%', 'APR 7.14%', 0.74),
    _LenderInfo(5, 'Better.com', 'Online · instant pre-approval', '6.75%', 'APR 6.96%', 1.00, isGreen: true),
  ];

  @override
  void dispose() {
    _alertRateController.dispose();
    super.dispose();
  }

  void _saveRateAlert() async {
    final double targetRate = double.tryParse(_alertRateController.text) ?? 6.50;
    final labelCtrl = TextEditingController(text: 'Rate Alert: $_alertLoanType @ $targetRate%');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('🔔 Save Rate Alert',
            style: AppTextStyles.playfair(
                size: 16, color: _theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Save alert to trigger when $_alertLoanType drops below ${targetRate.toStringAsFixed(2)}%',
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
                hintText: 'Alert label name',
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
              backgroundColor: _theme.primaryColor,
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
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'Rate Alert';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'Rate Alert',
        inputs: {
          'TargetRate': targetRate,
        },
        results: {
          'TriggerRate': targetRate,
          'CurrentRate': 6.82,
        },
        label: label,
        currencyCode: 'USD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      setState(() => _alertSaved = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _alertSaved = false);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Rate alert saved successfully!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: _theme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final series = _datasets[_currentType]!;
    final chartData = series.ranges[_currentRange]!;

    final mortgage30Async = ref.watch(fredMortgage30Provider);
    final mortgage15Async = ref.watch(fredMortgage15Provider);
    final sofrAsync = ref.watch(fredSofrProvider);
    final fedFundsAsync = ref.watch(fredFedFundsProvider);

    final m30Val = mortgage30Async.valueOrNull?.value ?? 6.82;
    final m15Val = mortgage15Async.valueOrNull?.value ?? 6.11;
    final sofrVal = sofrAsync.valueOrNull?.value ?? 5.33;
    final fedFundsVal = fedFundsAsync.valueOrNull?.value ?? 5.33;

    final dynamicLenders = [
      _LenderInfo(1, 'Rocket Mortgage', 'Online · Largest US lender', '${(m30Val - 0.03).toStringAsFixed(2)}%', 'APR ${(m30Val - 0.03 + 0.22).toStringAsFixed(2)}%', 0.95),
      _LenderInfo(2, 'United Wholesale', 'Wholesale · broker channel', '${(m30Val - 0.01).toStringAsFixed(2)}%', 'APR ${(m30Val - 0.01 + 0.23).toStringAsFixed(2)}%', 0.90),
      _LenderInfo(3, 'Chase Bank', 'Retail bank · full service', '${(m30Val + 0.06).toStringAsFixed(2)}%', 'APR ${(m30Val + 0.06 + 0.22).toStringAsFixed(2)}%', 0.80),
      _LenderInfo(4, 'Wells Fargo', 'Retail bank · nationwide', '${(m30Val + 0.09).toStringAsFixed(2)}%', 'APR ${(m30Val + 0.09 + 0.23).toStringAsFixed(2)}%', 0.74),
      _LenderInfo(5, 'Better.com', 'Online · instant pre-approval', '${(m30Val - 0.07).toStringAsFixed(2)}%', 'APR ${(m30Val - 0.07 + 0.21).toStringAsFixed(2)}%', 1.00, isGreen: true),
    ];

    return Scaffold(
      backgroundColor: _theme.getBgColor(context),
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: _theme.headerGradient),
              ),
            ),
            expandedHeight: 125,
            pinned: true,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                ),
                alignment: Alignment.center,
                child: Text('←', style: AppTextStyles.dmSans(size: 18, color: Colors.white)),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🇺🇸  Rate Trends',
                    style: AppTextStyles.dmSans(size: 16, weight: FontWeight.w800, color: Colors.white)),
                Text('Freddie Mac · FRED · FOMC · Jun 2025',
                    style: AppTextStyles.dmSans(size: 9.5, color: Colors.white.withValues(alpha: 0.5))),
              ],
            ),
          ),

          // Scrollable Body
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Rate strip
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: _theme.getCardColor(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _theme.getBorderColor(context)),
                  ),
                  child: Row(
                    children: [
                      _stripItem('30-Yr Fixed', '${m30Val.toStringAsFixed(2)}%', mortgage30Async.valueOrNull?.isLive == true ? 'FRED Live' : 'Freddie Mac', isUp: true),
                      _stripItem('15-Yr Fixed', '${m15Val.toStringAsFixed(2)}%', mortgage15Async.valueOrNull?.isLive == true ? 'FRED Live' : 'Avg'),
                      _stripItem('5/1 ARM', '${(sofrVal + 0.72).toStringAsFixed(2)}%', sofrAsync.valueOrNull?.isLive == true ? 'FRED SOFR' : 'Avg', isUp: false),
                      _stripItem('Fed Funds', '${fedFundsVal.toStringAsFixed(2)}%', fedFundsAsync.valueOrNull?.isLive == true ? 'FRED Live' : 'FOMC', isGold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Rate type tabs
                _buildSectionLabel('Rate Type', trailing: 'Compare All'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _tabButton('30yr', '30-Yr Fixed'),
                      _tabButton('15yr', '15-Yr Fixed'),
                      _tabButton('arm', '5/1 ARM'),
                      _tabButton('jumbo', 'Jumbo'),
                      _tabButton('va', 'VA Loan'),
                      _tabButton('fha', 'FHA'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Time range selectors
                Row(
                  children: [
                    _rangeButton('1m'),
                    const SizedBox(width: 6),
                    _rangeButton('3m'),
                    const SizedBox(width: 6),
                    _rangeButton('6m'),
                    const SizedBox(width: 6),
                    _rangeButton('1y'),
                    const SizedBox(width: 6),
                    _rangeButton('3y'),
                    const SizedBox(width: 6),
                    _rangeButton('5y'),
                  ],
                ),
                const SizedBox(height: 12),

                // Main Chart Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _theme.getCardColor(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _theme.getBorderColor(context)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(series.title, style: AppTextStyles.playfair(size: 13, weight: FontWeight.bold, color: _theme.getTextColor(context))),
                                Text(series.sub, style: AppTextStyles.dmSans(size: 8.5, color: _theme.getMutedColor(context))),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: series.isUp
                                  ? (isDark ? const Color(0xFF0F3A1D) : const Color(0xFFF0FDF4))
                                  : (isDark ? const Color(0xFF4A0E0E) : const Color(0xFFFEF2F2)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              series.badge,
                              style: AppTextStyles.dmSans(
                                size: 8,
                                weight: FontWeight.bold,
                                color: series.isUp ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Chart Paint Area
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          const height = 170.0;
                          return GestureDetector(
                            onHorizontalDragUpdate: (details) {
                              final double localX = details.localPosition.dx;
                              setState(() {
                                const double padL = 32.0;
                                const double padR = 8.0;
                                final double plotW = width - padL - padR;
                                final double fraction = ((localX - padL) / plotW).clamp(0.0, 1.0);
                                _hoverIndex = (fraction * (chartData.values.length - 1)).round();
                              });
                            },
                            onHorizontalDragStart: (details) {
                              final double localX = details.localPosition.dx;
                              setState(() {
                                const double padL = 32.0;
                                const double padR = 8.0;
                                final double plotW = width - padL - padR;
                                final double fraction = ((localX - padL) / plotW).clamp(0.0, 1.0);
                                _hoverIndex = (fraction * (chartData.values.length - 1)).round();
                              });
                            },
                            onHorizontalDragEnd: (_) => setState(() {
                              _hoverIndex = null;
                            }),
                            onTapDown: (details) {
                              final double localX = details.localPosition.dx;
                              setState(() {
                                const double padL = 32.0;
                                const double padR = 8.0;
                                final double plotW = width - padL - padR;
                                final double fraction = ((localX - padL) / plotW).clamp(0.0, 1.0);
                                _hoverIndex = (fraction * (chartData.values.length - 1)).round();
                              });
                            },
                            onTapUp: (_) => setState(() {
                              _hoverIndex = null;
                            }),
                            child: CustomPaint(
                              size: Size(width, height),
                              painter: _ChartPainter(
                                data: chartData,
                                primaryColor: series.color,
                                hoverIndex: _hoverIndex,
                                isDark: isDark,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),

                      // Legend
                      Row(
                        children: [
                          _legendItem(series.color, '${series.title.split(' ').take(3).join(' ')} (${_currentType == '30yr' ? 'Freddie Mac' : 'Avg'})'),
                          const SizedBox(width: 14),
                          _legendItem(const Color(0xFFB91C1C).withValues(alpha: 0.6), '10-Yr Treasury Yield', isDashed: true),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Table
                _buildSectionLabel('Current Rates · Week of Jun 5, 2025', trailing: 'Freddie Mac'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _theme.getCardColor(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _theme.getBorderColor(context)),
                  ),
                  child: Column(
                    children: [
                      _tableRow('🏠', '30-Yr Fixed', 'Freddie Mac PMMS', '${m30Val.toStringAsFixed(2)}%', '↑ +0.05', true),
                      _tableRow('🏡', '15-Yr Fixed', 'National Average', '${m15Val.toStringAsFixed(2)}%', '↓ −0.02', false),
                      _tableRow('📊', '5/1 ARM', 'Adjustable Rate', '${(sofrVal + 0.72).toStringAsFixed(2)}%', '↓ −0.03', false),
                      _tableRow('🏢', 'Jumbo 30-Yr', '>\$766,550 loans', '${(m30Val + 0.22).toStringAsFixed(2)}%', '↑ +0.08', true),
                      _tableRow('🎖️', 'VA Loan', 'Veterans Affairs', '${(m30Val - 0.57).toStringAsFixed(2)}%', '↑ +0.01', true),
                      _tableRow('🏦', 'FHA 30-Yr', '3.5% min down', '${(m30Val - 0.27).toStringAsFixed(2)}%', '→ 0.00', null),
                      _tableRow('🌾', 'USDA Rural', '502 Guaranteed', '${(m30Val - 0.47).toStringAsFixed(2)}%', '↓ −0.01', false),
                      _tableRow('📉', '10-Yr T-Note', 'US Treasury', '${(m30Val - 2.35).toStringAsFixed(2)}%', '↓ −0.03', false, isLast: true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 52-week range sparklines
                _buildSectionLabel('52-Week Range', trailing: 'Full History'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _sparkCard('30-Yr Fixed', '${m30Val.toStringAsFixed(2)}%', '↑ +0.05', '52-wk: 6.61% – 7.79%', const Color(0xFF1B3F72), [28, 24, 26, 20, 30, 22, 18, 24, 16, 20, 14, 18, 16], isDark)),
                    const SizedBox(width: 10),
                    Expanded(child: _sparkCard('15-Yr Fixed', '${m15Val.toStringAsFixed(2)}%', '↓ −0.02', '52-wk: 5.92% – 7.02%', const Color(0xFF15803D), [32, 28, 30, 24, 28, 20, 22, 18, 22, 16, 20, 16, 18], isDark)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _sparkCard('5/1 ARM', '${(sofrVal + 0.72).toStringAsFixed(2)}%', '↓ −0.03', '52-wk: 5.77% – 6.89%', const Color(0xFFD97706), [30, 24, 28, 22, 26, 18, 24, 16, 20, 14, 20, 18, 22], isDark)),
                    const SizedBox(width: 10),
                    Expanded(child: _sparkCard('10-Yr T-Note', '${(m30Val - 2.35).toStringAsFixed(2)}%', '↓ −0.03', '52-wk: 3.80% – 4.99%', const Color(0xFFB91C1C), [14, 18, 12, 20, 16, 22, 18, 24, 20, 26, 22, 24, 22], isDark)),
                  ],
                ),
                const SizedBox(height: 16),

                // Fed outlook forecast card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FEDERAL RESERVE · FOMC 2025 OUTLOOK', style: AppTextStyles.dmSans(size: 8, color: Colors.white54, weight: FontWeight.bold, letterSpacing: 0.8)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Fed Funds Rate: ', style: AppTextStyles.playfair(size: 15, color: Colors.white, weight: FontWeight.bold)),
                          Text('${(fedFundsVal - 0.08).toStringAsFixed(2)}–${(fedFundsVal + 0.17).toStringAsFixed(2)}%', style: AppTextStyles.playfair(size: 15, color: const Color(0xFFFCD34D), weight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _fedBox('Current', '${fedFundsVal.toStringAsFixed(2)}%', 'Effective rate', isGold: true)),
                          const SizedBox(width: 8),
                          Expanded(child: _fedBox('Next FOMC', 'Jul 30', '2025 meeting')),
                          const SizedBox(width: 8),
                          Expanded(child: _fedBox('Cut Odds', '65%', 'CME FedWatch')),
                        ],
                      ),
                      const Divider(color: Colors.white12, height: 24),
                      Text('Rate Cut Probability by Meeting', style: AppTextStyles.dmSans(size: 9, color: Colors.white54, weight: FontWeight.bold, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      _probRow('Jul 30, 2025', 0.65),
                      const SizedBox(height: 6),
                      _probRow('Sep 17, 2025', 0.78),
                      const SizedBox(height: 6),
                      _probRow('Nov 5, 2025', 0.85),
                      const SizedBox(height: 6),
                      _probRow('Dec 10, 2025', 0.88),
                      const Divider(color: Colors.white12, height: 24),
                      Text(
                        'Fed Outlook: Markets price in 1–2 cuts in H2 2025. Mortgage rates typically follow the 10-year Treasury, not the Fed Funds rate directly. A 25bps cut may lower mortgage rates by only ~0.10–0.15%.',
                        style: AppTextStyles.dmSans(size: 9, color: Colors.white54, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Milestones
                _buildSectionLabel('📜 Historical Rate Milestones', trailing: null),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _theme.getCardColor(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _theme.getBorderColor(context)),
                  ),
                  child: Column(
                    children: List.generate(_milestones.length, (index) {
                      final m = _milestones[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: index == _milestones.length - 1
                              ? null
                              : Border(bottom: BorderSide(color: _theme.getBorderColor(context))),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: m.color.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              constraints: const BoxConstraints(minWidth: 42),
                              child: Text(m.year, style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.bold, color: m.color)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.title, style: AppTextStyles.playfair(size: 11, weight: FontWeight.bold, color: _theme.getTextColor(context))),
                                  const SizedBox(height: 2),
                                  Text(m.desc, style: AppTextStyles.dmSans(size: 9, color: _theme.getMutedColor(context), height: 1.3)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(m.rate, style: AppTextStyles.playfair(size: 12.5, weight: FontWeight.bold, color: m.color)),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),

                // Rate alert setup
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF33230A) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🔔', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Set Rate Alert', style: AppTextStyles.playfair(size: 13, weight: FontWeight.bold, color: const Color(0xFF92400E))),
                              Text('Get notified when 30-yr fixed hits your target', style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFB45309))),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Alert when rate drops below', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: const Color(0xFF92400E))),
                          Container(
                            width: 80,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0x59F59E0B)),
                            ),
                            child: TextField(
                              controller: _alertRateController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.right,
                              style: AppTextStyles.playfair(size: 12, weight: FontWeight.bold, color: const Color(0xFF92400E)),
                              decoration: const InputDecoration(
                                isDense: true,
                                suffixText: '% ',
                                contentPadding: EdgeInsets.all(6),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Loan type', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: const Color(0xFF92400E))),
                          Container(
                            width: 120,
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0x59F59E0B)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _alertLoanType,
                                dropdownColor: Colors.amber.shade50,
                                style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: const Color(0xFF92400E)),
                                onChanged: (val) {
                                  if (val != null) setState(() => _alertLoanType = val);
                                },
                                items: const [
                                  DropdownMenuItem(value: '30-Yr Fixed', child: Text('30-Yr Fixed')),
                                  DropdownMenuItem(value: '15-Yr Fixed', child: Text('15-Yr Fixed')),
                                  DropdownMenuItem(value: '5/1 ARM', child: Text('5/1 ARM')),
                                  DropdownMenuItem(value: 'VA Loan', child: Text('VA Loan')),
                                  DropdownMenuItem(value: 'FHA Loan', child: Text('FHA Loan')),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _saveRateAlert,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _alertSaved ? const Color(0xFF15803D) : const Color(0xFFD97706),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                          minimumSize: const Size.fromHeight(42),
                        ),
                        child: Text(
                          _alertSaved ? '✅ Alert Saved' : '🔔 Save Rate Alert',
                          style: AppTextStyles.playfair(size: 12, weight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Lenders Snapshot
                _buildSectionLabel('Top Lender Rates Today', trailing: 'View All'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _theme.getCardColor(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _theme.getBorderColor(context)),
                  ),
                  child: Column(
                    children: List.generate(dynamicLenders.length, (index) {
                      final l = dynamicLenders[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: index == _lenders.length - 1
                              ? null
                              : Border(bottom: BorderSide(color: _theme.getBorderColor(context))),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: l.isGreen
                                    ? (isDark ? const Color(0xFF0F3A1D) : const Color(0xFFFEF3C7))
                                    : (isDark ? Colors.white10 : _theme.getBgColor(context)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('${l.rank}', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.bold, color: l.isGreen ? const Color(0xFFD97706) : _theme.getTextColor(context))),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l.name, style: AppTextStyles.playfair(size: 11, weight: FontWeight.bold, color: _theme.getTextColor(context))),
                                  Text(l.type, style: AppTextStyles.dmSans(size: 8.5, color: _theme.getMutedColor(context))),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(l.rate, style: AppTextStyles.playfair(size: 13, weight: FontWeight.bold, color: _theme.getTextColor(context))),
                                Text(l.apr, style: AppTextStyles.dmSans(size: 8, color: _theme.getMutedColor(context))),
                                const SizedBox(height: 3),
                                Container(
                                  width: 72,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    width: 72 * l.progress,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: l.isGreen ? const Color(0xFF15803D) : _theme.primaryColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stripItem(String label, String val, String note, {bool? isUp, bool isGold = false}) {
    Color valColor = Colors.white;
    if (isGold) {
      valColor = const Color(0xFFFCD34D);
    }
    String indicator = '';
    Color indColor = Colors.white;
    if (isUp == true) {
      indicator = ' ↑';
      indColor = const Color(0xFF6EE7B7);
    } else if (isUp == false) {
      indicator = ' ↓';
      indColor = const Color(0xFFFCA5A5);
    }

    return Expanded(
      child: Column(
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white70, weight: FontWeight.bold)),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: val, style: AppTextStyles.playfair(size: 14, color: valColor, weight: FontWeight.bold)),
                if (indicator.isNotEmpty)
                  TextSpan(text: indicator, style: AppTextStyles.dmSans(size: 8, color: indColor, weight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(note, style: AppTextStyles.dmSans(size: 8, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, {String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.w800,
            color: _theme.getMutedColor(context),
            letterSpacing: 0.8,
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: AppTextStyles.dmSans(
              size: 10.5,
              weight: FontWeight.w600,
              color: _theme.primaryColor,
            ),
          ),
      ],
    );
  }

  Widget _tabButton(String key, String label) {
    final isActive = _currentType == key;
    return GestureDetector(
      onTap: () => setState(() {
        _currentType = key;
        _hoverIndex = null;
      }),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _theme.primaryColor : _theme.getCardColor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isActive ? _theme.primaryColor : _theme.getBorderColor(context)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 10.5,
            weight: FontWeight.bold,
            color: isActive ? Colors.white : _theme.getMutedColor(context),
          ),
        ),
      ),
    );
  }

  Widget _rangeButton(String key) {
    final isActive = _currentRange == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _currentRange = key;
          _hoverIndex = null;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? _theme.textColor : _theme.getCardColor(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isActive ? _theme.textColor : _theme.getBorderColor(context)),
          ),
          alignment: Alignment.center,
          child: Text(
            key.toUpperCase(),
            style: AppTextStyles.dmSans(
              size: 9.5,
              weight: FontWeight.bold,
              color: isActive ? Colors.white : _theme.getMutedColor(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String text, {bool isDashed = false}) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDashed ? null : color,
            border: isDashed ? Border.all(color: color, width: 1.5, style: BorderStyle.solid) : null,
          ),
          child: isDashed
              ? Center(
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.transparent),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 6),
        Text(text, style: AppTextStyles.dmSans(size: 9.5, color: _theme.getMutedColor(context), weight: FontWeight.w600)),
      ],
    );
  }

  Widget _tableRow(String icon, String name, String src, String rate, String chg, bool? isUp, {bool isLast = false}) {
    Color chgColor = _theme.getMutedColor(context);
    if (isUp == true) chgColor = const Color(0xFF15803D);
    if (isUp == false) chgColor = const Color(0xFFB91C1C);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: _theme.getBorderColor(context))),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _theme.getBgColor(context),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.playfair(size: 11, weight: FontWeight.bold, color: _theme.getTextColor(context))),
                Text(src, style: AppTextStyles.dmSans(size: 8.5, color: _theme.getMutedColor(context))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(rate, style: AppTextStyles.playfair(size: 13, weight: FontWeight.bold, color: _theme.getTextColor(context))),
          const SizedBox(width: 12),
          SizedBox(
            width: 50,
            child: Text(chg, style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.bold, color: chgColor), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _sparkCard(String label, String rate, String chg, String range, Color color, List<double> sparkPoints, bool isDark) {
    Color chgColor = _theme.getMutedColor(context);
    if (chg.startsWith('↑')) chgColor = const Color(0xFF15803D);
    if (chg.startsWith('↓')) chgColor = const Color(0xFFB91C1C);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: _theme.getMutedColor(context))),
              Text(chg, style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: chgColor)),
            ],
          ),
          const SizedBox(height: 2),
          Text(rate, style: AppTextStyles.playfair(size: 16, weight: FontWeight.bold, color: _theme.getTextColor(context))),
          const SizedBox(height: 6),
          SizedBox(
            height: 32,
            child: CustomPaint(
              size: const Size(double.infinity, 32),
              painter: _SparklinePainter(points: sparkPoints, lineColor: color),
            ),
          ),
          const SizedBox(height: 4),
          Text(range, style: AppTextStyles.dmSans(size: 8, color: _theme.getMutedColor(context))),
        ],
      ),
    );
  }

  Widget _fedBox(String lbl, String val, String sub, {bool isGold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(lbl.toUpperCase(), style: AppTextStyles.dmSans(size: 7.5, color: Colors.white54, weight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(val, style: AppTextStyles.playfair(size: 13, color: isGold ? const Color(0xFFFCD34D) : Colors.white, weight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(sub, style: AppTextStyles.dmSans(size: 7.5, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _probRow(String label, double prob) {
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(label, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54, weight: FontWeight.bold)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: prob,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFCD34D)),
              minHeight: 5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text('${(prob * 100).toInt()}%', style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.bold, color: const Color(0xFFFCD34D)), textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

// ─── Custom Painters ──────────────────────────────────────────────────────────

class _ChartPainter extends CustomPainter {
  final _ChartData data;
  final Color primaryColor;
  final int? hoverIndex;
  final bool isDark;

  const _ChartPainter({
    required this.data,
    required this.primaryColor,
    required this.hoverIndex,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double padL = 32.0;
    const double padR = 8.0;
    const double padT = 12.0;
    const double padB = 22.0;

    final double plotW = size.width - padL - padR;
    final double plotH = size.height - padT - padB;

    if (data.values.isEmpty) return;

    // Determine min and max
    final List<double> allVals = [...data.values, ...data.tsyValues];
    double minV = allVals.reduce(math.min) - 0.3;
    double maxV = allVals.reduce(math.max) + 0.3;
    if (minV < 0) minV = 0;

    double xPos(int i) => padL + (i / (data.values.length - 1)) * plotW;
    double yPos(double v) => padT + plotH - ((v - minV) / (maxV - minV)) * plotH;

    const int gridCount = 4;
    final Paint gridPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0x161B3F72)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final TextPainter yPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= gridCount; i++) {
      final double y = padT + (i / gridCount) * plotH;
      canvas.drawLine(Offset(padL, y), Offset(size.width - padR, y), gridPaint);

      final double val = maxV - (i / gridCount) * (maxV - minV);
      yPainter.text = TextSpan(
        text: '${val.toStringAsFixed(1)}%',
        style: TextStyle(
          color: isDark ? Colors.white60 : const Color(0xFF3D5280),
          fontSize: 8.0,
          fontFamily: 'DMSans',
        ),
      );
      yPainter.layout();
      yPainter.paint(canvas, Offset(padL - yPainter.width - 4, y - yPainter.height / 2));
    }

    // 2. Draw X labels
    final TextPainter xPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < data.labels.length; i++) {
      final double x = xPos(i);
      xPainter.text = TextSpan(
        text: data.labels[i],
        style: TextStyle(
          color: isDark ? Colors.white60 : const Color(0xFF3D5280),
          fontSize: 8.0,
          fontFamily: 'DMSans',
        ),
      );
      xPainter.layout();
      xPainter.paint(canvas, Offset(x - xPainter.width / 2, size.height - padB + 6));
    }

    // 3. Draw Shaded Gradient Fill for primary line
    final Path fillPath = Path();
    fillPath.moveTo(xPos(0), yPos(data.values.first));
    for (int i = 1; i < data.values.length; i++) {
      fillPath.lineTo(xPos(i), yPos(data.values[i]));
    }
    fillPath.lineTo(xPos(data.values.length - 1), padT + plotH);
    fillPath.lineTo(xPos(0), padT + plotH);
    fillPath.close();

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [primaryColor.withValues(alpha: 0.22), primaryColor.withValues(alpha: 0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(padL, padT, size.width - padR, padT + plotH))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 4. Draw Secondary Line (Treasury dashed)
    final Path tsyPath = Path();
    tsyPath.moveTo(xPos(0), yPos(data.tsyValues.first));
    for (int i = 1; i < data.tsyValues.length; i++) {
      tsyPath.lineTo(xPos(i), yPos(data.tsyValues[i]));
    }

    final Paint tsyPaint = Paint()
      ..color = const Color(0xFFB91C1C).withValues(alpha: 0.55)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    _drawDashedPath(canvas, tsyPath, tsyPaint, 4.0, 3.0);

    // 5. Draw Primary Line
    final Path mainPath = Path();
    mainPath.moveTo(xPos(0), yPos(data.values.first));
    for (int i = 1; i < data.values.length; i++) {
      mainPath.lineTo(xPos(i), yPos(data.values[i]));
    }

    final Paint mainPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(mainPath, mainPaint);

    // 6. Draw current dot
    final double curX = xPos(data.values.length - 1);
    final double curY = yPos(data.values.last);
    canvas.drawCircle(Offset(curX, curY), 4.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(curX, curY), 3.0, Paint()..color = primaryColor);

    // 7. Interactive Hover Tooltip scrubbing
    if (hoverIndex != null && hoverIndex! < data.values.length) {
      final double hX = xPos(hoverIndex!);
      final double hY = yPos(data.values[hoverIndex!]);

      // Vertical tracker line
      final Paint trackerPaint = Paint()
        ..color = isDark ? Colors.white30 : const Color(0xFF3D5280).withValues(alpha: 0.25)
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(hX, padT), Offset(hX, padT + plotH), trackerPaint);

      // Indicator dot
      canvas.drawCircle(Offset(hX, hY), 5.5, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(hX, hY), 3.5, Paint()..color = primaryColor);

      // Draw tooltip box
      final String rateStr = '${data.values[hoverIndex!].toStringAsFixed(2)}%';
      final String dateStr = data.labels[hoverIndex!];

      final TextPainter tooltipValPainter = TextPainter(
        text: TextSpan(
          text: rateStr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'DMSans',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final TextPainter tooltipDatePainter = TextPainter(
        text: TextSpan(
          text: dateStr,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 8.5,
            fontFamily: 'DMSans',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final double boxW = math.max(68.0, tooltipValPainter.width + 16.0);
      const double boxH = 28.0;

      double boxX = hX - boxW / 2;
      if (boxX < padL) boxX = padL;
      if (boxX + boxW > size.width - padR) boxX = size.width - padR - boxW;

      final double boxY = (hY - 36.0).clamp(padT, size.height - padB - boxH);

      final RRect rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(boxX, boxY, boxW, boxH),
        const Radius.circular(7.0),
      );

      canvas.drawRRect(rrect, Paint()..color = const Color(0xFF0B1D3A));

      tooltipValPainter.paint(
        canvas,
        Offset(boxX + (boxW - tooltipValPainter.width) / 2, boxY + 3.0),
      );
      tooltipDatePainter.paint(
        canvas,
        Offset(boxX + (boxW - tooltipDatePainter.width) / 2, boxY + 14.5),
      );
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, double dashW, double spaceW) {
    final List<PathMetric> metrics = path.computeMetrics().toList();
    for (final PathMetric metric in metrics) {
      double start = 0.0;
      while (start < metric.length) {
        final double end = math.min(start + dashW, metric.length);
        final Path dashPath = metric.extractPath(start, end);
        canvas.drawPath(dashPath, paint);
        start = end + spaceW;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.hoverIndex != hoverIndex ||
        oldDelegate.isDark != isDark;
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color lineColor;

  const _SparklinePainter({required this.points, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final double minV = points.reduce(math.min);
    final double maxV = points.reduce(math.max);
    final double range = maxV - minV == 0 ? 1.0 : maxV - minV;

    final double stepX = size.width / (points.length - 1);

    final Path path = Path();
    path.moveTo(0, size.height - ((points.first - minV) / range) * size.height);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(i * stepX, size.height - ((points[i] - minV) / range) * size.height);
    }

    // Gradient fill
    final Path fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          colors: [lineColor.withValues(alpha: 0.18), lineColor.withValues(alpha: 0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    // End point circle
    final double lastX = size.width;
    final double lastY = size.height - ((points.last - minV) / range) * size.height;
    canvas.drawCircle(Offset(lastX, lastY), 3.0, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(lastX, lastY), 1.8, Paint()..color = lineColor);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.lineColor != lineColor;
  }
}
