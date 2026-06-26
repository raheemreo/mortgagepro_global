// lib/features/australia/tools/au_rba_rate_history.dart

import 'package:flutter/material.dart';
import 'dart:math';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';

class AURbaRateHistory extends StatefulWidget {
  final CountryTheme theme;
  const AURbaRateHistory({super.key, this.theme = CountryThemes.australia});

  @override
  State<AURbaRateHistory> createState() => _AURbaRateHistoryState();
}

class _AURbaRateHistoryState extends State<AURbaRateHistory> {
  int _activeTab = 0; // 0 = Chart, 1 = Decisions, 2 = Impact, 3 = Outlook

  // Chart Range state
  String _chartRange = '5y'; // '2y', '5y', '10y', '20y', 'all'

  // Impact Calculator Inputs
  double _loanBalance = 600000;
  double _loanTerm = 25;
  double _baseRate = 6.09;
  double _newRate = 5.84;

  // Historical RBA Cash Rate Target data points [YYYY-MM, Rate %]
  static const List<MapEntry<String, double>> _allRates = [
    MapEntry('2000-02', 5.50),
    MapEntry('2000-03', 5.75),
    MapEntry('2000-05', 6.00),
    MapEntry('2000-08', 6.25),
    MapEntry('2001-02', 5.75),
    MapEntry('2001-03', 5.50),
    MapEntry('2001-04', 5.25),
    MapEntry('2001-05', 5.00),
    MapEntry('2001-09', 4.75),
    MapEntry('2001-10', 4.50),
    MapEntry('2001-12', 4.25),
    MapEntry('2002-06', 4.50),
    MapEntry('2002-11', 4.75),
    MapEntry('2003-03', 4.75),
    MapEntry('2003-11', 5.00),
    MapEntry('2004-11', 5.25),
    MapEntry('2005-03', 5.50),
    MapEntry('2006-05', 5.75),
    MapEntry('2006-08', 6.00),
    MapEntry('2007-08', 6.25),
    MapEntry('2007-11', 6.50),
    MapEntry('2008-02', 7.00),
    MapEntry('2008-03', 7.25),
    MapEntry('2008-09', 7.00),
    MapEntry('2008-10', 6.00),
    MapEntry('2008-11', 5.25),
    MapEntry('2008-12', 4.25),
    MapEntry('2009-02', 3.25),
    MapEntry('2009-04', 3.00),
    MapEntry('2009-10', 3.25),
    MapEntry('2009-11', 3.50),
    MapEntry('2009-12', 3.75),
    MapEntry('2010-03', 4.00),
    MapEntry('2010-04', 4.25),
    MapEntry('2010-05', 4.50),
    MapEntry('2010-11', 4.75),
    MapEntry('2011-11', 4.50),
    MapEntry('2012-05', 3.75),
    MapEntry('2012-06', 3.50),
    MapEntry('2012-10', 3.25),
    MapEntry('2012-12', 3.00),
    MapEntry('2013-05', 2.75),
    MapEntry('2013-08', 2.50),
    MapEntry('2015-02', 2.25),
    MapEntry('2015-05', 2.00),
    MapEntry('2016-05', 1.75),
    MapEntry('2016-08', 1.50),
    MapEntry('2019-06', 1.25),
    MapEntry('2019-07', 1.00),
    MapEntry('2019-10', 0.75),
    MapEntry('2020-03', 0.50),
    MapEntry('2020-04', 0.25),
    MapEntry('2020-11', 0.10),
    MapEntry('2022-05', 0.35),
    MapEntry('2022-06', 0.85),
    MapEntry('2022-07', 1.35),
    MapEntry('2022-08', 1.85),
    MapEntry('2022-09', 2.35),
    MapEntry('2022-10', 2.60),
    MapEntry('2022-11', 2.85),
    MapEntry('2022-12', 3.10),
    MapEntry('2023-02', 3.35),
    MapEntry('2023-03', 3.60),
    MapEntry('2023-05', 3.85),
    MapEntry('2023-06', 4.10),
    MapEntry('2023-11', 4.35),
    MapEntry('2024-01', 4.35),
    MapEntry('2024-03', 4.35),
    MapEntry('2024-06', 4.35),
    MapEntry('2024-09', 4.35),
    MapEntry('2024-12', 4.35),
  ];

  static const List<Map<String, String>> _decisionsList = [
    {
      'date': 'Nov 2023',
      'action': 'up',
      'change': '+0.25%',
      'rate': '4.35%',
      'note': '12th hike of cycle under persistent inflation concerns'
    },
    {
      'date': 'Oct 2023',
      'action': 'hold',
      'change': 'Hold',
      'rate': '4.10%',
      'note': 'Board held rates steady to assess lag effects of hikes'
    },
    {
      'date': 'Sep 2023',
      'action': 'hold',
      'change': 'Hold',
      'rate': '4.10%',
      'note': 'Lowe\'s final meeting, inflation showing signs of moderating'
    },
    {
      'date': 'Aug 2023',
      'action': 'hold',
      'change': 'Hold',
      'rate': '4.10%',
      'note': 'Rate held to monitor consumer spending & job markets'
    },
    {
      'date': 'Jul 2023',
      'action': 'hold',
      'change': 'Hold',
      'rate': '4.10%',
      'note': 'RBA paused after consecutive monthly increases'
    },
    {
      'date': 'Jun 2023',
      'action': 'up',
      'change': '+0.25%',
      'rate': '4.10%',
      'note': 'Inflation proved stubborn, driving another hike'
    },
    {
      'date': 'May 2023',
      'action': 'up',
      'change': '+0.25%',
      'rate': '3.85%',
      'note': 'CPI services index rising, RBA hiked unexpectedly'
    },
    {
      'date': 'Mar 2023',
      'action': 'up',
      'change': '+0.25%',
      'rate': '3.60%',
      'note': 'Core inflation remained well above target bounds'
    },
    {
      'date': 'Feb 2023',
      'action': 'up',
      'change': '+0.25%',
      'rate': '3.35%',
      'note': 'CPI reached a peak of 7.8% in Q4 2022'
    },
    {
      'date': 'Dec 2022',
      'action': 'up',
      'change': '+0.25%',
      'rate': '3.10%',
      'note': '8th consecutive cash rate hike of 2022'
    },
    {
      'date': 'Nov 2022',
      'action': 'up',
      'change': '+0.25%',
      'rate': '2.85%',
      'note': 'Board continues path to return CPI to target range'
    },
    {
      'date': 'Oct 2022',
      'action': 'up',
      'change': '+0.25%',
      'rate': '2.60%',
      'note': 'Slower pace after triple 50 bps increases'
    },
    {
      'date': 'Sep 2022',
      'action': 'up',
      'change': '+0.50%',
      'rate': '2.35%',
      'note': 'RBA hiked aggressively to counter rising wage rates'
    },
    {
      'date': 'May 2022',
      'action': 'up',
      'change': '+0.25%',
      'rate': '0.35%',
      'note': 'First cash rate increase in Australia since November 2010'
    },
    {
      'date': 'Nov 2020',
      'action': 'down',
      'change': '-0.15%',
      'rate': '0.10%',
      'note': 'Historical low cash rate to support economy during pandemic'
    },
  ];

  static const List<Map<String, dynamic>> _upcomingMeetings = [
    {'date': 'Feb 17-18, 2025', 'rate': '4.10%?', 'prob': 'Cut Expected'},
    {'date': 'Apr 1, 2025', 'rate': '3.85%?', 'prob': 'Possible Cut'},
    {'date': 'May 20, 2025', 'rate': '3.60%?', 'prob': 'Possible Cut'},
    {'date': 'Jul 8, 2025', 'rate': '3.35%?', 'prob': 'Data Dependent'},
    {'date': 'End 2025 (Est)', 'rate': '3.10%', 'prob': 'Consensus Market Forecast'},
  ];

  static const List<Map<String, dynamic>> _bankForecasts = [
    {'bank': 'CBA', 'rate': '3.10%', 'color': Color(0xFF7C2D12)},
    {'bank': 'Westpac', 'rate': '3.10%', 'color': Color(0xFF002868)},
    {'bank': 'ANZ', 'rate': '3.35%', 'color': Color(0xFFD97706)},
    {'bank': 'NAB', 'rate': '3.10%', 'color': Color(0xFF0F766E)},
    {'bank': 'Macquarie', 'rate': '2.85%', 'color': Color(0xFF7C3AED)},
    {'bank': 'AMP', 'rate': '3.35%', 'color': Color(0xFFBE185D)},
  ];

  List<MapEntry<String, double>> _filterChartData() {
    final now = DateTime.now();
    DateTime cutoff;
    switch (_chartRange) {
      case '2y':
        cutoff = DateTime(now.year - 2, now.month);
        break;
      case '5y':
        cutoff = DateTime(now.year - 5, now.month);
        break;
      case '10y':
        cutoff = DateTime(now.year - 10, now.month);
        break;
      case '20y':
        cutoff = DateTime(now.year - 20, now.month);
        break;
      default:
        return _allRates;
    }

    return _allRates.where((entry) {
      final parts = entry.key.split('-');
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      return DateTime(y, m).isAfter(cutoff);
    }).toList();
  }

  double _monthlyPayment(double rate, double balance, double termYears) {
    if (rate <= 0) return balance / (termYears * 12);
    final r = rate / 100 / 12;
    final n = termYears * 12;
    return balance * r * pow(1 + r, n) / (pow(1 + r, n) - 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cash Rate Hero Metrics Bar
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              Expanded(child: _buildHeroMetric('Cash Rate', '4.35%', 'Current', Colors.amber)),
              _buildDivider(),
              Expanded(child: _buildHeroMetric('Last Change', "Nov '23", '+0.25%', const Color(0xFFFF8A9A))),
              _buildDivider(),
              Expanded(child: _buildHeroMetric('Peak Cycle', '4.35%', '13-yr high', const Color(0xFFFF8A9A))),
              _buildDivider(),
              Expanded(child: _buildHeroMetric('Trough', '0.10%', "Nov'20–Apr'22", const Color(0xFFBBF7D0))),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tabs
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Row(
            children: [
              Expanded(child: _buildTabBtn('Chart', 0)),
              Expanded(child: _buildTabBtn('Decisions', 1)),
              Expanded(child: _buildTabBtn('Impact', 2)),
              Expanded(child: _buildTabBtn('Outlook', 3)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tab Content
        if (_activeTab == 0) _buildChartTab(theme),
        if (_activeTab == 1) _buildDecisionsTab(theme),
        if (_activeTab == 2) _buildImpactTab(theme),
        if (_activeTab == 3) _buildOutlookTab(theme),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 36, color: Colors.white24);
  }

  Widget _buildHeroMetric(String label, String val, String change, Color valColor) {
    return Column(
      children: [
        Text(label.toUpperCase(),
            style: AppTextStyles.dmSans(
                size: 8, color: Colors.white60, weight: FontWeight.w800, letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(val,
            style: AppTextStyles.playfair(
                size: 16.5, color: valColor, weight: FontWeight.w900)),
        const SizedBox(height: 1),
        Text(change,
            style: AppTextStyles.dmSans(
                size: 8.5, color: Colors.white70, weight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTabBtn(String label, int index) {
    final active = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? widget.theme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.w800,
            color: active
                ? Colors.white
                : widget.theme.getTextColor(context).withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }

  // ─── TAB 1: CHART ──────────────────────────────────────────────────
  Widget _buildChartTab(CountryTheme theme) {
    final filteredData = _filterChartData();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RBA Cash Rate Target (%)',
                  style: AppTextStyles.playfair(
                      size: 13.5, weight: FontWeight.bold, color: theme.getTextColor(context))),
              Text('Reserve Bank of Australia — Historical tracker',
                  style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context))),
              const SizedBox(height: 12),

              // Range buttons
              Row(
                children: ['2Y', '5Y', '10Y', '20Y', 'All'].map((range) {
                  final active = _chartRange == range.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: GestureDetector(
                      onTap: () => setState(() => _chartRange = range.toLowerCase()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: active ? theme.primaryColor : theme.getBgColor(context),
                          border: Border.all(
                              color: active ? theme.primaryColor : theme.getBorderColor(context)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          range,
                          style: AppTextStyles.dmSans(
                              size: 9.5,
                              weight: FontWeight.w800,
                              color: active ? Colors.white : theme.getTextColor(context)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Chart Drawing
              SizedBox(
                height: 180,
                width: double.infinity,
                child: CustomPaint(
                  painter: _RbaRateChartPainter(
                    data: filteredData,
                    lineColor: theme.primaryColor,
                    textColor: theme.getTextColor(context),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Statistics Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.1,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _buildStatCard('Hikes (May\'22-Nov\'23)', '13', '425 bps total lift', Colors.red),
            _buildStatCard('Consecutive Holds', '13', 'Dec\'23 – Feb\'25 duration', Colors.amber),
            _buildStatCard('Avg Rate (10yr)', '1.83%', '2014 – 2024 timeframe', Colors.blue),
            _buildStatCard('Avg Rate (All Time)', '5.20%', '1990 – 2024 historical', theme.getTextColor(context)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String sub, Color valColor) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(value, style: AppTextStyles.playfair(size: 18, color: valColor, weight: FontWeight.w900)),
          const SizedBox(height: 1),
          Text(sub, style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context))),
        ],
      ),
    );
  }

  // ─── TAB 2: DECISIONS LIST ──────────────────────────────────────────
  Widget _buildDecisionsTab(CountryTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent RBA Cash Rate Decisions',
              style: AppTextStyles.playfair(
                  size: 13.5, weight: FontWeight.bold, color: theme.getTextColor(context))),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _decisionsList.length,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, idx) {
              final dec = _decisionsList[idx];
              final isUp = dec['action'] == 'up';
              final isDown = dec['action'] == 'down';

              IconData icon;
              Color iconBg, iconFg;
              if (isUp) {
                icon = Icons.trending_up;
                iconBg = const Color(0xFFFEE2E2);
                iconFg = Colors.red;
              } else if (isDown) {
                icon = Icons.trending_down;
                iconBg = const Color(0xFFDCFCE7);
                iconFg = Colors.green;
              } else {
                icon = Icons.trending_flat;
                iconBg = theme.getBgColor(context);
                iconFg = Colors.orange;
              }

              return Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(dec['date']!,
                        style: AppTextStyles.dmSans(
                            size: 10,
                            color: theme.getMutedColor(context),
                            weight: FontWeight.w700)),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: iconFg, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dec['change']!,
                            style: AppTextStyles.dmSans(
                                size: 13,
                                weight: FontWeight.w800,
                                color: theme.getTextColor(context))),
                        Text('Cash Rate → ${dec['rate']} · ${dec['note']}',
                            style: AppTextStyles.dmSans(
                                size: 10, color: theme.getMutedColor(context))),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── TAB 3: IMPACT CALCULATOR ──────────────────────────────────────
  Widget _buildImpactTab(CountryTheme theme) {
    final m1 = _monthlyPayment(_baseRate, _loanBalance, _loanTerm);
    final m2 = _monthlyPayment(_newRate, _loanBalance, _loanTerm);
    final diff = m2 - m1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [theme.primaryColor, theme.accentColor],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📊 Repayment Impact Calculator',
                  style: AppTextStyles.playfair(
                      size: 13.5, weight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              _buildImpactInputRow('Loan Balance', _loanBalance, (val) => setState(() => _loanBalance = val)),
              const SizedBox(height: 8),
              _buildImpactInputRow('Term (Years)', _loanTerm, (val) => setState(() => _loanTerm = val)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildImpactInputRow('Base Rate %', _baseRate, (val) => setState(() => _baseRate = val), step: 0.01),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildImpactInputRow('New Rate %', _newRate, (val) => setState(() => _newRate = val), step: 0.01),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Impact Results Panel
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Monthly Repayment Impact',
                        style: AppTextStyles.dmSans(size: 9.5, color: Colors.white60, weight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                        '${diff < 0 ? '− ' : '+ '}${CurrencyFormatter.format(diff.abs(), currencyCode: 'AUD')}/mo',
                        style: AppTextStyles.playfair(
                            size: 24, color: Colors.amber, weight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(
                        'Annual Difference: ${diff < 0 ? 'Saved' : 'Cost'} \$${(diff.abs() * 12).toStringAsFixed(0)}',
                        style: AppTextStyles.dmSans(size: 10, color: Colors.white70)),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('At $_baseRate%', style: AppTextStyles.dmSans(size: 9, color: Colors.white60)),
                        Text(CurrencyFormatter.format(m1, currencyCode: 'AUD'), style: AppTextStyles.playfair(size: 15, color: Colors.white, weight: FontWeight.w800)),
                      ],
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.white30, size: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('At $_newRate%', style: AppTextStyles.dmSans(size: 9, color: Colors.white60)),
                        Text(CurrencyFormatter.format(m2, currencyCode: 'AUD'), style: AppTextStyles.playfair(size: 15, color: Colors.greenAccent, weight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Historical Rates Repayment Scale (chart of repayments at various rates on $600K loan)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monthly Repayment on \$600K Loan',
                  style: AppTextStyles.playfair(
                      size: 13, weight: FontWeight.bold, color: theme.getTextColor(context))),
              Text('repayments over a 25 year term across cash rate tiers',
                  style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
              const SizedBox(height: 16),

              // Bar rep list
              SizedBox(
                height: 130,
                width: double.infinity,
                child: CustomPaint(
                  painter: _RepaymentScalePainter(
                    loanAmt: 600000,
                    term: 25,
                    ratesList: const [0.10, 1.00, 2.00, 3.00, 4.00, 5.00, 6.09, 7.00, 8.00],
                    primaryColor: theme.primaryColor,
                    accentColor: theme.accentColor,
                    textColor: theme.getTextColor(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImpactInputRow(String label, double val, ValueChanged<double> onChanged, {double step = 1.0}) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: AppTextStyles.dmSans(size: 11, color: Colors.white70, weight: FontWeight.w600)),
        ),
        Expanded(
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: TextFormField(
              key: ValueKey(val),
              initialValue: val.toStringAsFixed(step == 1.0 ? 0 : 2),
              keyboardType: TextInputType.number,
              style: AppTextStyles.dmSans(size: 13.5, color: Colors.white, weight: FontWeight.w800),
              decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
              onChanged: (text) {
                final d = double.tryParse(text) ?? 0.0;
                onChanged(d);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ─── TAB 4: OUTLOOK / FORECASTS ───────────────────────────────────
  Widget _buildOutlookTab(CountryTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // RBA Meetings Outlook
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            border: Border.all(color: const Color(0xFF93C5FD)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📅 Upcoming RBA Meetings & Expectations',
                  style: AppTextStyles.playfair(
                      size: 13, weight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
              const SizedBox(height: 10),
              ..._upcomingMeetings.map((m) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(m['date'],
                            style: AppTextStyles.dmSans(
                                size: 11,
                                weight: FontWeight.bold,
                                color: const Color(0xFF1D4ED8))),
                        Row(
                          children: [
                            Text(m['rate'],
                                style: AppTextStyles.playfair(
                                    size: 12,
                                    weight: FontWeight.w800,
                                    color: const Color(0xFF1E3A8A))),
                            const SizedBox(width: 8),
                            Text(m['prob'],
                                style: AppTextStyles.dmSans(
                                    size: 9.5,
                                    weight: FontWeight.w700,
                                    color: const Color(0xFF2563EB))),
                          ],
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Economist Bank Forecasts
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Economist Forecasts — Cash Rate End 2025',
                  style: AppTextStyles.playfair(
                      size: 13, weight: FontWeight.bold, color: theme.getTextColor(context))),
              const SizedBox(height: 12),
              ..._bankForecasts.map((f) {
                final double val = double.parse(f['rate'].replaceAll('%', ''));
                // Let's divide by 4.35 to get progress ratio
                final pct = (val / 4.35).clamp(0.0, 1.0);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 70,
                          child: Text(f['bank'],
                              style: AppTextStyles.dmSans(
                                  size: 11,
                                  weight: FontWeight.bold,
                                  color: theme.getTextColor(context)))),
                      Expanded(
                        child: Container(
                          height: 18,
                          decoration: BoxDecoration(
                            color: theme.getBgColor(context),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: pct,
                            child: Container(
                              decoration: BoxDecoration(
                                color: f['color'],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 45,
                        child: Text(
                          f['rate'],
                          style: AppTextStyles.dmSans(
                              size: 11.5,
                              weight: FontWeight.bold,
                              color: theme.getTextColor(context)),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Inflation Metrics Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            border: Border.all(color: const Color(0xFFFCD34D)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Key Inflation Metrics (Latest)',
                  style: AppTextStyles.playfair(
                      size: 13, weight: FontWeight.bold, color: const Color(0xFF92400E))),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  _buildMetricGridItem('CPI (Annual)', '3.5%', 'Q3 2024'),
                  _buildMetricGridItem('Trimmed Mean CPI', '3.5%', 'RBA Target: 2-3%', isWarn: true),
                  _buildMetricGridItem('Unemployment', '4.1%', 'Nov 2024'),
                  _buildMetricGridItem('GDP Growth', '0.8%', 'Annual Q2 2024'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricGridItem(String label, String value, String sub, {bool isWarn = false}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF92400E), weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.playfair(
                  size: 18,
                  weight: FontWeight.w900,
                  color: isWarn ? Colors.red : Colors.black)),
          const SizedBox(height: 1),
          Text(sub, style: AppTextStyles.dmSans(size: 8, color: const Color(0xFF92400E))),
        ],
      ),
    );
  }
}

// ─── CUSTOM PAINTERS ────────────────────────────────────────────────

// RBA Cash Rate Line Chart Painter
class _RbaRateChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> data;
  final Color lineColor;
  final Color textColor;

  _RbaRateChartPainter({
    required this.data,
    required this.lineColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final rates = data.map((e) => e.value).toList();
    final double maxR = rates.reduce(max);
    final double minR = rates.reduce(min);
    final double rangeR = maxR - minR > 0 ? (maxR - minR) : 1.0;

    const double padL = 32.0;
    const double padR = 10.0;
    const double padT = 16.0;
    const double padB = 24.0;

    final double w2 = size.width - padL - padR;
    final double h2 = size.height - padT - padB;

    double getX(int index) => padL + (index / (data.length - 1)) * w2;
    double getY(double rate) => padT + h2 - ((rate - minR) / rangeR) * h2;

    // Grid lines & labels
    final gridPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 4; i++) {
      final y = padT + (i / 4) * h2;
      canvas.drawLine(Offset(padL, y), Offset(size.width - padR, y), gridPaint);

      final val = maxR - (i / 4) * (maxR - minR);
      final tp = TextPainter(
        text: TextSpan(
          text: '${val.toStringAsFixed(1)}%',
          style: AppTextStyles.dmSans(size: 8, color: textColor.withValues(alpha: 0.5)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // Gradient fill under path
    final path = Path();
    path.moveTo(getX(0), padT + h2);
    for (int i = 0; i < data.length; i++) {
      path.lineTo(getX(i), getY(data[i].value));
    }
    path.lineTo(getX(data.length - 1), padT + h2);
    path.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withValues(alpha: 0.16), lineColor.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(padL, padT, w2, h2));
    canvas.drawPath(path, fillPaint);

    // Main Line
    final linePath = Path();
    linePath.moveTo(getX(0), getY(data[0].value));
    for (int i = 1; i < data.length; i++) {
      linePath.lineTo(getX(i), getY(data[i].value));
    }

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // Latest Rate Endpoint indicator dot
    final lastX = getX(data.length - 1);
    final lastY = getY(data.last.value);
    canvas.drawCircle(Offset(lastX, lastY), 4.5, Paint()..color = Colors.amber);
    canvas.drawCircle(Offset(lastX, lastY), 2.5, Paint()..color = lineColor);

    // Date X Labels (First and last)
    final tpStart = TextPainter(
      text: TextSpan(
        text: data.first.key,
        style: AppTextStyles.dmSans(size: 8, color: textColor.withValues(alpha: 0.5)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpStart.paint(canvas, Offset(padL, size.height - 18));

    final tpEnd = TextPainter(
      text: TextSpan(
        text: data.last.key,
        style: AppTextStyles.dmSans(size: 8, color: textColor.withValues(alpha: 0.5)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpEnd.paint(canvas, Offset(size.width - padR - tpEnd.width, size.height - 18));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Repayment Scale Chart Painter (draws monthly repayment bar charts on $600K loan)
class _RepaymentScalePainter extends CustomPainter {
  final double loanAmt;
  final double term;
  final List<double> ratesList;
  final Color primaryColor;
  final Color accentColor;
  final Color textColor;

  _RepaymentScalePainter({
    required this.loanAmt,
    required this.term,
    required this.ratesList,
    required this.primaryColor,
    required this.accentColor,
    required this.textColor,
  });

  double _monthly(double rate) {
    if (rate <= 0) return loanAmt / (term * 12);
    final r = rate / 100 / 12;
    final n = term * 12;
    return loanAmt * r * pow(1 + r, n) / (pow(1 + r, n) - 1);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final payments = ratesList.map(_monthly).toList();
    final double maxVal = payments.reduce(max);
    final double minVal = payments.reduce(min);
    final double valRange = maxVal - minVal > 0 ? (maxVal - minVal) : 1.0;

    const double padL = 40.0;
    const double padR = 10.0;
    const double padT = 16.0;
    const double padB = 26.0;

    final double w2 = size.width - padL - padR;
    final double h2 = size.height - padT - padB;
    final double barWidth = (w2 / ratesList.length) - 6;

    // Draw Y ticks (monthly repayment amount)
    final gridPaint = Paint()
      ..color = textColor.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;
    for (int i = 0; i <= 3; i++) {
      final y = padT + (i / 3) * h2;
      canvas.drawLine(Offset(padL, y), Offset(size.width - padR, y), gridPaint);

      final val = maxVal - (i / 3) * (maxVal - minVal);
      final tp = TextPainter(
        text: TextSpan(
          text: '\$${(val / 1000).toStringAsFixed(1)}K',
          style: AppTextStyles.dmSans(size: 8, color: textColor.withValues(alpha: 0.5)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // Draw Bars
    for (int i = 0; i < ratesList.length; i++) {
      final r = ratesList[i];
      final val = payments[i];
      final h = ((val - minVal) / valRange) * (h2 * 0.8) + (h2 * 0.15);
      final y = padT + h2 - h;
      final x = padL + i * (w2 / ratesList.length) + 3;

      // Color coding (special colors for RBA trough and RBA peak)
      Color barColor = primaryColor;
      if (r == 4.35) {
        barColor = Colors.amber;
      } else if (r == 0.10) {
        barColor = Colors.green;
      }

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, h),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );

      final barPaint = Paint()
        ..color = barColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rect, barPaint);

      // Value label on top
      final tpVal = TextPainter(
        text: TextSpan(
          text: '\$${(val / 1000).toStringAsFixed(1)}K',
          style: AppTextStyles.dmSans(size: 7, weight: FontWeight.bold, color: textColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tpVal.paint(canvas, Offset(x + barWidth / 2 - tpVal.width / 2, y - 9));

      // Rate label at bottom
      final tpRate = TextPainter(
        text: TextSpan(
          text: '${r.toStringAsFixed(1 == r.truncateToDouble() ? 0 : 1)}%',
          style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w700, color: textColor.withValues(alpha: 0.7)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tpRate.paint(canvas, Offset(x + barWidth / 2 - tpRate.width / 2, size.height - 18));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
