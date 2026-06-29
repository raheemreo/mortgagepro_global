// lib/features/europe/tools/eu_euribor_tracker.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/europe_rates_provider.dart';
import '../../../shared/models/saved_calc.dart';

class EUEuriborTracker extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;

  const EUEuriborTracker({
    super.key,
    required this.theme,
    this.savedCalc,
  });

  @override
  ConsumerState<EUEuriborTracker> createState() => _EUEuriborTrackerState();
}

class _EUEuriborTrackerState extends ConsumerState<EUEuriborTracker> {
  String _selectedTenor = '6m';
  double _loan = 250000;
  double _spread = 1.50;
  int _termYears = 20;

  static const Map<String, double> _euriborRates = {
    '1w': 3.91,
    '1m': 3.87,
    '3m': 3.65,
    '6m': 3.42,
    '9m': 3.28,
    '12m': 3.17,
  };

  static const Map<String, List<double>> _historyData = {
    '6m': [3.82, 3.76, 3.68, 3.58, 3.52, 3.46, 3.44, 3.89, 3.76, 3.65, 3.54, 3.47, 3.42],
    '1y': [3.55, 4.19, 3.99, 3.94, 3.82, 3.58, 3.44, 3.65, 3.42],
    '2y': [0.11, 2.54, 3.55, 3.99, 3.82, 3.44, 3.42],
    '5y': [-0.5, -0.5, 0.1, 3.99, 3.82, 3.42],
  };

  static const Map<String, List<String>> _historyLabels = {
    '6m': ['Jun 24', 'Jul 24', 'Aug 24', 'Sep 24', 'Oct 24', 'Nov 24', 'Dec 24', 'Jan 25', 'Feb 25', 'Mar 25', 'Apr 25', 'May 25', 'Jun 25'],
    '1y': ['Jun 23', 'Sep 23', 'Dec 23', 'Mar 24', 'Jun 24', 'Sep 24', 'Dec 24', 'Mar 25', 'Jun 25'],
    '2y': ['Jun 22', 'Dec 22', 'Jun 23', 'Dec 23', 'Jun 24', 'Dec 24', 'Jun 25'],
    '5y': ['2020', '2021', '2022', '2023', '2024', '2025'],
  };

  static const Map<String, double> _tenorToDouble = {
    '1w': 1.0,
    '1m': 2.0,
    '3m': 3.0,
    '6m': 4.0,
    '9m': 5.0,
    '12m': 6.0,
  };

  static final Map<double, String> _doubleToTenor = {
    1.0: '1w',
    2.0: '1m',
    3.0: '3m',
    4.0: '6m',
    5.0: '9m',
    6.0: '12m',
  };

  String _chartPeriod = '6m';
  bool _calculated = false;

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _loan = inputs['loan'] ?? 250000.0;
      _spread = inputs['spread'] ?? 1.50;
      _termYears = (inputs['term'] ?? 20.0).toInt();
      final tenorVal = inputs['tenor'] ?? 4.0;
      _selectedTenor = _doubleToTenor[tenorVal] ?? '6m';
      _calculated = true;
    }
  }

  double _calculateMonthly(double loan, double rate, int termYrs) {
    final r = (rate / 100) / 12;
    final n = termYrs * 12;
    if (r == 0) return loan / n;
    return loan * (r * math.pow(1 + r, n)) / (math.pow(1 + r, n) - 1);
  }

  void _saveTrackerResult(double monthly, double totalRate, double annualSaving) async {
    final labelCtrl = TextEditingController(text: 'Euribor mortgage analysis');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/eu_euribor_tracker'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Analysis',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: Payment ${CurrencyFormatter.compact(monthly, symbol: '€')}/mo at ${totalRate.toStringAsFixed(2)}% rate',
              style: AppTextStyles.dmSans(
                  size: 11, color: widget.theme.getMutedColor(context)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Variable Loan)',
                hintStyle: AppTextStyles.dmSans(size: 13, color: Colors.grey),
                filled: true,
                fillColor: widget.theme.getBgColor(context),
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
              backgroundColor: widget.theme.primaryColor,
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
          : 'Euribor analysis';
      final calc = SavedCalc.create(
        country: 'Europe',
        calcType: 'Euribor Tracker',
        inputs: {
          'loan': _loan,
          'spread': _spread,
          'term': _termYears.toDouble(),
          'tenor': _tenorToDouble[_selectedTenor] ?? 4.0,
        },
        results: {
          'Payment': monthly,
          'Rate': totalRate,
          'Saving': annualSaving,
        },
        label: '$label - ${_selectedTenor.toUpperCase()} Euribor',
        currencyCode: 'EUR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Analysis saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: widget.theme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final cardBg = theme.getCardColor(context);
    final borderCol = theme.getBorderColor(context);
    final textColor = theme.getTextColor(context);
    final mutedText = theme.getMutedColor(context);

    // Live ECB rates from provider — override static fallback map
    final ratesAsync = ref.watch(europeRatesProvider);
    final liveRates = ratesAsync.valueOrNull;
    final isLive = liveRates?.isLive == true;
    final liveEcbRate = liveRates?.ecbRate.value ?? 4.00;

    // Build effective euribor rates: live values override static fallbacks
    final effectiveRates = Map<String, double>.from(_euriborRates);
    if (liveRates != null) {
      effectiveRates['3m'] = liveRates.euribor3m.value;
      effectiveRates['6m'] = liveRates.euribor6m.value;
      effectiveRates['12m'] = liveRates.euribor12m.value;
    }

    // Live Euribor rate selection
    final eurRate = effectiveRates[_selectedTenor] ?? 3.42;
    final totalRate = eurRate + _spread;
    final monthlyPayment = _calculateMonthly(_loan, totalRate, _termYears);

    // Savings compared to peak oct 2023 rate (peak rate = 4.19%)
    final peakTotalRate = 4.19 + _spread;
    final peakMonthlyPayment = _calculateMonthly(_loan, peakTotalRate, _termYears);
    final monthlySaving = peakMonthlyPayment - monthlyPayment;
    final annualSaving = monthlySaving * 12;

    // Scenarios (-1%, current, +1%)
    final payMinus = _calculateMonthly(_loan, totalRate - 1.0, _termYears);
    final payPlus = _calculateMonthly(_loan, totalRate + 1.0, _termYears);

    // Trend chart points
    final trendHistory = _historyData[_chartPeriod]!;
    final trendLabels = _historyLabels[_chartPeriod]!;
    final double maxTrend = trendHistory.reduce(math.max);
    final double minTrend = trendHistory.reduce(math.min);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate strip on top
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.theme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.theme.primaryColor.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _rateStripItem('1M Euribor', '3.87%', 'Jun 2025', Colors.green),
              _rateDivider(),
              _rateStripItem('3M Euribor', '3.65%', 'Jun 2025', Colors.blue),
              _rateDivider(),
              _rateStripItem('6M Euribor', '3.42%', 'Jun 2025', Colors.orange),
              _rateDivider(),
              _rateStripItem('12M Euribor', '3.17%', 'Jun 2025', Colors.red),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Live Euribor rates box grid
        Text('LIVE EURIBOR RATES${isLive ? ' 🟢' : ''}', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: mutedText, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: theme.headerGradient,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isLive ? Colors.green : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isLive ? 'Live Data · ECB Data Portal' : 'Estimated · ECB API unreachable',
                    style: AppTextStyles.dmSans(size: 10, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Euribor Tenors', style: AppTextStyles.playfair(size: 20, color: const Color(0xFFFFCC00), weight: FontWeight.w900)),
              Text('Select a tenor box to load into the impact calculator', style: AppTextStyles.dmSans(size: 10.5, color: Colors.white54)),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.8,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                children: [
                  ...effectiveRates.keys.map((tenor) {
                    final active = _selectedTenor == tenor;
                    final rate = effectiveRates[tenor]!;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTenor = tenor),
                      child: Container(
                        decoration: BoxDecoration(
                          color: active ? const Color(0xFFFFCC00).withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.1),
                          border: Border.all(
                              color: active ? const Color(0xFFFFCC00) : Colors.white.withValues(alpha: 0.15)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(tenor.toUpperCase(), style: AppTextStyles.dmSans(size: 9, weight: FontWeight.bold, color: Colors.white70)),
                            const SizedBox(height: 2),
                            Text('${rate.toStringAsFixed(2)}%',
                                style: AppTextStyles.playfair(size: 14, color: Colors.white, weight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    );
                  }),
                  _staticTenorBox('ECB RATE', '${liveEcbRate.toStringAsFixed(2)}%', 'HOLD'),
                  _staticTenorBox('PEAK RATE', '4.19%', "Oct '23"),
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
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderCol),
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
                      Text('Euribor Rate Trajectory', style: AppTextStyles.cardTitle(textColor)),
                      Text('Data Source: European Central Bank (ECB)', style: AppTextStyles.dmSans(size: 9.5, color: mutedText)),
                    ],
                  ),
                  Row(
                    children: ['6m', '1y', '2y', '5y'].map((p) {
                      final active = _chartPeriod == p;
                      return GestureDetector(
                        onTap: () => setState(() => _chartPeriod = p),
                        child: Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: active ? theme.primaryColor : theme.getBgColor(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: active ? theme.primaryColor : borderCol),
                          ),
                          child: Text(p.toUpperCase(),
                              style: AppTextStyles.dmSans(
                                  size: 10,
                                  weight: FontWeight.bold,
                                  color: active ? const Color(0xFFFFCC00) : textColor)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 140,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: EuriborHistoryPainter(
                    history: trendHistory,
                    labels: trendLabels,
                    min: minTrend,
                    max: maxTrend,
                    theme: theme,
                    isDark: Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _statSummaryBox('52W Peak', '4.19%', '6M tenor, Oct 2023'),
                  const SizedBox(width: 8),
                  _statSummaryBox('52W Low', '3.17%', '12M tenor, Jun 2025'),
                  const SizedBox(width: 8),
                  _statSummaryBox('YTD Change', '-0.72%', 'v Jan 2025 (3.89%)'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Mortgage Impact Calculator
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('💶 Mortgage Impact Calculator', style: AppTextStyles.cardTitle(textColor)),
              const SizedBox(height: 14),

              // Inputs Group
              Row(
                children: [
                  Expanded(
                    child: _numericInputBox('Loan Balance (€)', _loan, (v) => setState(() => _loan = v), min: 10000, max: 2000000),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dropdownInputBox(
                      'Euribor Tenor',
                      _selectedTenor,
                      _euriborRates.keys.map((k) {
                        return DropdownMenuItem<String>(
                          value: k,
                          child: Text('${k.toUpperCase()} (${_euriborRates[k]}%)', style: AppTextStyles.dmSans(size: 12.5, color: textColor, weight: FontWeight.bold)),
                        );
                      }).toList(),
                      (val) {
                        if (val != null) setState(() => _selectedTenor = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _numericInputBox('Bank Spread (%)', _spread, (v) => setState(() => _spread = v), min: 0.1, max: 5.0, step: 0.05),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dropdownInputBox(
                      'Remaining Term',
                      _termYears.toString(),
                      [10, 15, 20, 25, 30].map((y) {
                        return DropdownMenuItem<String>(
                          value: y.toString(),
                          child: Text('$y years', style: AppTextStyles.dmSans(size: 12.5, color: textColor, weight: FontWeight.bold)),
                        );
                      }).toList(),
                      (val) {
                        if (val != null) setState(() => _termYears = int.parse(val));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: () => setState(() => _calculated = true),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFCC00), Color(0xFFF59E0B)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFCC00).withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🧠', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text('Calculate Impact',
                          style: AppTextStyles.dmSans(
                              size: 14, weight: FontWeight.w900, color: const Color(0xFF1A0040))),
                    ],
                  ),
                ),
              ),

              if (_calculated) ...[
                const SizedBox(height: 16),
                // Monthly payment hero
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: theme.headerGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text('Estimated Monthly Payment', style: AppTextStyles.dmSans(size: 10.5, color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(monthlyPayment, symbol: '€'),
                        style: AppTextStyles.playfair(size: 28, color: const Color(0xFFFFCC00), weight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'at ${totalRate.toStringAsFixed(2)}% rate ($eurRate% Euribor + ${_spread.toStringAsFixed(2)}% spread)',
                        style: AppTextStyles.dmSans(size: 10, color: Colors.white60),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Saving items
                Row(
                  children: [
                    _impactMiniStat('Current Total Rate', '${totalRate.toStringAsFixed(2)}%', Theme.of(context).brightness == Brightness.dark ? theme.accentColor : theme.primaryColor),
                    const SizedBox(width: 8),
                    _impactMiniStat('Peak Saving/mo', '- ${CurrencyFormatter.compact(monthlySaving, symbol: '€')}', Colors.green),
                    const SizedBox(width: 8),
                    _impactMiniStat('Annual Saving', '- ${CurrencyFormatter.compact(annualSaving, symbol: '€')}/yr', Theme.of(context).brightness == Brightness.dark ? Colors.greenAccent : Colors.green.shade800),
                  ],
                ),
                const SizedBox(height: 16),

                // Scenarios
                Text('Rate Shock Scenarios', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _scenarioBox('If -1% Cut', '${(totalRate - 1.0).toStringAsFixed(2)}%', payMinus),
                    const SizedBox(width: 6),
                    _scenarioBox('Current Rate', '${totalRate.toStringAsFixed(2)}%', monthlyPayment, isCurrent: true),
                    const SizedBox(width: 6),
                    _scenarioBox('If +1% Hike', '${(totalRate + 1.0).toStringAsFixed(2)}%', payPlus),
                  ],
                ),
                const SizedBox(height: 16),

                // Save button
                ElevatedButton.icon(
                  onPressed: () => _saveTrackerResult(monthlyPayment, totalRate, annualSaving),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Text('💾', style: TextStyle(fontSize: 14)),
                  label: Text('Save This Analysis',
                      style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w800)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ECB decisions list
        Text('ECB RATE DECISIONS 2024-2025', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: mutedText, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            children: [
              _ecbDecisionRow('12 Jun 2025', 'Rate Cut -0.25%', 'Deposit rate → 3.50%', Colors.green, 'CUT'),
              _ecbDecisionDivider(borderCol),
              _ecbDecisionRow('17 Apr 2025', 'Rate Cut -0.25%', 'Deposit rate → 3.75%', Colors.green, 'CUT'),
              _ecbDecisionDivider(borderCol),
              _ecbDecisionRow('30 Jan 2025', 'Rate Hold', 'Deposit rate → 4.00%', Colors.blue, 'HOLD'),
              _ecbDecisionDivider(borderCol),
              _ecbDecisionRow('12 Dec 2024', 'Rate Cut -0.25%', 'Deposit rate → 4.00%', Colors.green, 'CUT'),
              _ecbDecisionDivider(borderCol),
              _ecbDecisionRow('06 Jun 2024', 'First Cut -0.25%', 'Deposit rate → 4.50% — cycle start', Colors.green, 'CUT'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rateStripItem(String label, String rate, String date, Color col) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 9, weight: FontWeight.bold, color: widget.theme.getMutedColor(context))),
        const SizedBox(height: 2),
        Text(rate, style: AppTextStyles.playfair(size: 13, weight: FontWeight.bold, color: col)),
        const SizedBox(height: 1),
        Text(date, style: AppTextStyles.dmSans(size: 8, color: widget.theme.getMutedColor(context))),
      ],
    );
  }

  Widget _rateDivider() {
    return Container(
      width: 0.5,
      height: 28,
      color: widget.theme.getBorderColor(context),
    );
  }

  Widget _staticTenorBox(String tenor, String rate, String note) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(tenor, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54, weight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(rate, style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w900)),
          const SizedBox(height: 1),
          Text(note, style: AppTextStyles.dmSans(size: 8, color: const Color(0xFFFFCC00), weight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _statSummaryBox(String label, String val, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: widget.theme.getBgColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.theme.getBorderColor(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 8, weight: FontWeight.bold, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 3),
            Text(val, style: AppTextStyles.playfair(size: 14, color: widget.theme.getTextColor(context), weight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTextStyles.dmSans(size: 7.5, color: widget.theme.getMutedColor(context))),
          ],
        ),
      ),
    );
  }

  Widget _numericInputBox(String label, double value, ValueChanged<double> onChanged,
      {required double min, required double max, double step = 1000.0}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: widget.theme.getBgColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: widget.theme.getMutedColor(context))),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  step >= 1.0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2),
                  style: AppTextStyles.playfair(size: 13.5, weight: FontWeight.w800, color: widget.theme.getTextColor(context)),
                ),
              ),
              GestureDetector(
                onTap: () => onChanged(math.max(min, value - step)),
                child: Icon(Icons.remove_circle_outline, size: 16, color: Theme.of(context).brightness == Brightness.dark ? widget.theme.accentColor : widget.theme.primaryColor),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => onChanged(math.min(max, value + step)),
                child: Icon(Icons.add_circle_outline, size: 16, color: Theme.of(context).brightness == Brightness.dark ? widget.theme.accentColor : widget.theme.primaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdownInputBox(String label, String value, List<DropdownMenuItem<String>> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: widget.theme.getBgColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: widget.theme.getMutedColor(context))),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items,
              onChanged: onChanged,
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _impactMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: widget.theme.getBgColor(context),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(value, style: AppTextStyles.playfair(size: 13.5, color: color, weight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.dmSans(size: 9, weight: FontWeight.bold, color: widget.theme.getMutedColor(context))),
          ],
        ),
      ),
    );
  }

  Widget _scenarioBox(String label, String rate, double payAmt, {bool isCurrent = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? widget.theme.accentColor : widget.theme.primaryColor;
    final activeBg = isDark ? widget.theme.accentColor.withValues(alpha: 0.12) : widget.theme.primaryColor.withValues(alpha: 0.08);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isCurrent ? activeBg : widget.theme.getBgColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isCurrent ? activeColor : widget.theme.getBorderColor(context),
              width: isCurrent ? 1.5 : 1.0),
        ),
        child: Column(
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: isCurrent ? activeColor : widget.theme.getMutedColor(context))),
            const SizedBox(height: 4),
            Text(rate, style: AppTextStyles.playfair(size: 12, color: widget.theme.getTextColor(context), weight: FontWeight.bold)),
            Text('${CurrencyFormatter.compact(payAmt, symbol: '€')}/mo',
                style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.bold, color: activeColor)),
          ],
        ),
      ),
    );
  }

  Widget _ecbDecisionRow(String date, String action, String subtitle, Color color, String badge) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(badge == 'CUT' ? '↓' : '●', style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: AppTextStyles.dmSans(size: 9.5, color: widget.theme.getMutedColor(context))),
                Row(
                  children: [
                    Text(action, style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.bold, color: widget.theme.getTextColor(context))),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(badge, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.dmSans(size: 10, color: widget.theme.getMutedColor(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ecbDecisionDivider(Color borderCol) {
    return Divider(height: 1, color: borderCol);
  }
}

class EuriborHistoryPainter extends CustomPainter {
  final List<double> history;
  final List<String> labels;
  final double min;
  final double max;
  final CountryTheme theme;
  final bool isDark;

  EuriborHistoryPainter({
    required this.history,
    required this.labels,
    required this.min,
    required this.max,
    required this.theme,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double W = size.width;
    final double H = size.height;
    const double pl = 36.0;
    const double pr = 10.0;
    const double pt = 14.0;
    const double pb = 28.0;

    final n = history.length;
    final double minV = min - 0.3;
    final double maxV = max + 0.3;
    final double range = maxV - minV == 0 ? 1.0 : maxV - minV;

    double cx(int i) => pl + (i / (n - 1)) * (W - pl - pr);
    double cy(double v) => pt + (1 - (v - minV) / range) * (H - pt - pb);

    // Grid lines and ticks
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    const int steps = 4;
    for (int i = 0; i <= steps; i++) {
      final v = minV + i * (maxV - minV) / steps;
      final y = cy(v);

      canvas.drawLine(Offset(pl, y), Offset(W - pr, y), gridPaint);

      final textSpan = TextSpan(
        text: '${v.toStringAsFixed(1)}%',
        style: const TextStyle(color: Colors.grey, fontSize: 8.5),
      );
      textPainter.text = textSpan;
      textPainter.layout();
      textPainter.paint(canvas, Offset(pl - textPainter.width - 4, y - textPainter.height / 2));
    }

    // Line Path
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round
      ..color = isDark ? theme.accentColor : theme.primaryColor;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final List<Offset> points = [];
    for (int i = 0; i < n; i++) {
      points.add(Offset(cx(i), cy(history[i])));
    }

    path.moveTo(points.first.dx, points.first.dy);
    fillPath.moveTo(pl, H - pb);
    fillPath.lineTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
      fillPath.lineTo(points[i].dx, points[i].dy);
    }

    fillPath.lineTo(cx(n - 1), H - pb);
    fillPath.close();

    final curveColor = isDark ? theme.accentColor : theme.primaryColor;
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [curveColor.withValues(alpha: 0.22), curveColor.withValues(alpha: 0.01)],
    );
    fillPaint.shader = gradient.createShader(Rect.fromLTWH(pl, pt, W - pl - pr, H - pt - pb));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw last point circle highlight
    final lastPt = points.last;
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = isDark ? theme.accentColor : theme.primaryColor;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.white;

    canvas.drawCircle(lastPt, 5.0, dotPaint);
    canvas.drawCircle(lastPt, 5.0, borderPaint);

    // X-axis text labels
    for (int i = 0; i < n; i++) {
      if (i % (n / 4).ceil() == 0 || i == n - 1) {
        final textSpan = TextSpan(
          text: labels[i],
          style: const TextStyle(color: Colors.grey, fontSize: 8.5),
        );
        textPainter.text = textSpan;
        textPainter.layout();
        textPainter.paint(canvas, Offset(cx(i) - textPainter.width / 2, H - pb + 4));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
