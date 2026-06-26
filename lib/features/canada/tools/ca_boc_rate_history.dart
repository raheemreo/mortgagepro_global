// lib/features/canada/tools/ca_boc_rate_history.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/mortgage_math.dart';
import '../../../providers/canada_rates_provider.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class CABocRateHistory extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const CABocRateHistory({super.key, required this.theme});

  @override
  ConsumerState<CABocRateHistory> createState() => _CABocRateHistoryState();
}

class _CABocRateHistoryState extends ConsumerState<CABocRateHistory> {
  final _balanceController = TextEditingController(text: '500000');
  final bool _hasCalculated = true;

  final List<Map<String, dynamic>> _timelineData = const [
    {'date': 'March 18, 2026', 'rate': '2.25%', 'action': 'Hold', 'type': 'hold', 'desc': 'Hold — Middle East energy risk'},
    {'date': 'January 29, 2026', 'rate': '2.25%', 'action': 'Hold', 'type': 'hold', 'desc': 'Hold — US tariffs/trade uncertainty'},
    {'date': 'December 10, 2025', 'rate': '2.25%', 'action': '−25bps', 'type': 'cut', 'desc': 'Cut — weak growth, 1.8% CPI'},
    {'date': 'October 23, 2025', 'rate': '2.50%', 'action': '−25bps', 'type': 'cut', 'desc': 'Cut — GDP contraction Q4'},
    {'date': 'March 12, 2025', 'rate': '2.75%', 'action': '−25bps', 'type': 'cut', 'desc': 'Cut — trade uncertainty'},
    {'date': 'January 29, 2025', 'rate': '3.00%', 'action': '−25bps', 'type': 'cut', 'desc': 'Cut — inflation at 2% target'},
    {'date': 'December 11, 2024', 'rate': '3.25%', 'action': '−50bps', 'type': 'cut', 'desc': 'Jumbo cut — weak jobs data'},
    {'date': 'October 23, 2024', 'rate': '3.75%', 'action': '−50bps', 'type': 'cut', 'desc': 'Jumbo cut — recession fears'},
    {'date': 'September 4, 2024', 'rate': '4.25%', 'action': '−25bps', 'type': 'cut', 'desc': 'Cut — CPI eased to 2.5%'},
    {'date': 'July 24, 2024', 'rate': '4.50%', 'action': '−25bps', 'type': 'cut', 'desc': 'Cut — inflation eased'},
    {'date': 'June 5, 2024', 'rate': '4.75%', 'action': '−25bps', 'type': 'cut', 'desc': 'First cut since 2020 · Cycle begins'},
    {'date': 'July 12, 2023', 'rate': '5.00%', 'action': '+25bps', 'type': 'hike', 'desc': 'Final hike — peak rate cycle'},
  ];

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  void _saveRateScenario(double balance, double peakPmt, double curPmt, double savings, double currentOvernight) async {
    final labelCtrl = TextEditingController(text: 'Rate Impact Scenario');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Rate Scenario',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving Scenario: Savings of ${CurrencyFormatter.compact(savings, symbol: 'CA\$')}/mo · Balance: ${CurrencyFormatter.compact(balance, symbol: 'CA\$')}',
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
                hintText: 'Label (e.g. My Mortgage Savings)',
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
          : 'Rate Impact Scenario';

      final calc = SavedCalc.create(
        country: 'Canada',
        calcType: 'BoC Rate History',
        inputs: {
          'Mortgage Balance': balance,
          'Peak Overnight Rate': 5.00,
          'Current Overnight Rate': currentOvernight,
        },
        results: {
          'Monthly Savings': savings,
          'Peak Payment': peakPmt,
          'Current Payment': curPmt,
        },
        label: label,
        currencyCode: 'CAD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Rate scenario saved successfully!',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double balance = double.tryParse(_balanceController.text) ?? 500000;

    // Watch live Canada rates
    final ratesAsync = ref.watch(canadaCalculatedRatesProvider);
    final currentPrime = ratesAsync.valueOrNull?.prime.value ?? 4.45;
    final currentOvernight = ratesAsync.valueOrNull?.overnight.value ?? 2.25;

    // Math: Peak variable rate (Prime Peak = 7.20% - 0.5% = 6.70%)
    // Current variable rate (Prime Current = currentPrime - 0.5% = variable rate)
    const double peakRate = 6.70;
    final double curRate = currentPrime - 0.50;

    final double peakPmt = MortgageMath.canadianMonthlyPayment(
      principal: balance,
      annualRatePercent: peakRate,
      termYears: 25,
    );
    final double curPmt = MortgageMath.canadianMonthlyPayment(
      principal: balance,
      annualRatePercent: curRate,
      termYears: 25,
    );

    final double monthlySavings = peakPmt - curPmt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Info Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0A2E1A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoCell('Current BoC', '${currentOvernight.toStringAsFixed(2)}%', ratesAsync.valueOrNull?.overnight.isLive == true ? 'Live Valet' : 'Held', isGreen: true),
              _infoCell('Peak 2023', '5.00%', 'Jul\'23', isRed: true),
              _infoCell('Total Cuts', '−${(5.00 - currentOvernight).toStringAsFixed(2)}%', 'Jun\'24–Present', isGreen: true),
              _infoCell('Prime Rate', '${currentPrime.toStringAsFixed(2)}%', ratesAsync.valueOrNull?.prime.isLive == true ? 'Live Valet' : '+220bps'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Current Rate Card
        Text(
          'CURRENT RATE OVERVIEW',
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A2E1A), Color(0xFF1A5C35)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BANK OF CANADA OVERNIGHT RATE',
                style: AppTextStyles.dmSans(
                  size: 9,
                  color: Colors.white60,
                  weight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${currentOvernight.toStringAsFixed(2)}%',
                    style: AppTextStyles.playfair(
                      size: 44,
                      weight: FontWeight.w800,
                      color: const Color(0xFF6EDFA0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Held Policy Rate',
                            style: AppTextStyles.dmSans(size: 9.5, color: Colors.white60)),
                        Text('Last change: −25bps (Dec\'25)',
                            style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: const Color(0xFF86EFAC))),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${ratesAsync.valueOrNull?.overnight.isLive == true ? "Live BoC Valet Feed" : "Held"} · Next decision: June 4, 2026',
                style: AppTextStyles.dmSans(size: 11, color: Colors.white60),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _miniRateBox('Prime Rate', '${currentPrime.toStringAsFixed(2)}%'),
                  const SizedBox(width: 8),
                  _miniRateBox('Variable Mtg', '~${(ratesAsync.valueOrNull?.rateVariable ?? 3.95).toStringAsFixed(2)}%'),
                  const SizedBox(width: 8),
                  _miniRateBox('vs 2023 Peak', '−${(5.00 - currentOvernight).toStringAsFixed(2)}%', isGreen: true),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Rate Chart (2022–2026)
        Text(
          'RATE CHART (2022–2026)',
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BoC Overnight Policy Rate Trend',
                style: AppTextStyles.playfair(
                  size: 13,
                  weight: FontWeight.bold,
                  color: theme.getTextColor(context),
                ),
              ),
              Text(
                'Hike cycle 2022–23 → Cut cycle 2024–25 → Hold 2026',
                style: AppTextStyles.dmSans(
                  size: 9.5,
                  color: theme.getMutedColor(context),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                width: double.infinity,
                child: CustomPaint(
                  painter: _BocRateLinePainter(isDark: isDark),
                ),
              ),
              const SizedBox(height: 12),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendDot(const Color(0xFFC8102E), 'Peak 5.00%'),
                  const SizedBox(width: 16),
                  _legendDot(const Color(0xFF6EDFA0), 'Current 2.25%'),
                  const SizedBox(width: 16),
                  _legendDot(theme.primaryColor, 'Policy Rate'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Next BoC Decision Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
            ),
            border: Border.all(color: const Color(0xFFF59E0B)),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📅', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next BoC Decision: June 4, 2026',
                      style: AppTextStyles.playfair(
                        size: 13,
                        weight: FontWeight.bold,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Consensus: Hold at 2.25%. Middle East energy risks and trade uncertainty cited. BoC watching inflation closely — March CPI 1.8%. Hike risk rises if energy inflation broadens.',
                      style: AppTextStyles.dmSans(
                        size: 10,
                        color: const Color(0xFFB45309),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Interactive Savings Calculator
        Text(
          'CALCULATE YOUR RATE SAVINGS',
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
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
                      Text(
                        'Mortgage Balance',
                        style: AppTextStyles.dmSans(
                          size: 13,
                          weight: FontWeight.bold,
                          color: theme.getTextColor(context),
                        ),
                      ),
                      Text(
                        'Outstanding balance',
                        style: AppTextStyles.dmSans(
                          size: 10,
                          color: theme.getMutedColor(context),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'CA\$',
                        style: AppTextStyles.dmSans(
                          size: 12,
                          weight: FontWeight.bold,
                          color: theme.getMutedColor(context),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 110,
                        height: 38,
                        decoration: BoxDecoration(
                          color: theme.getBgColor(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.getBorderColor(context)),
                        ),
                        child: TextField(
                          controller: _balanceController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          style: AppTextStyles.dmSans(
                            size: 13,
                            weight: FontWeight.bold,
                            color: theme.getTextColor(context),
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          onChanged: (val) {
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: balance.clamp(50000, 2000000),
                min: 50000,
                max: 2000000,
                divisions: 195,
                activeColor: theme.primaryColor,
                inactiveColor: theme.getBorderColor(context),
                onChanged: (val) {
                  setState(() {
                    _balanceController.text = val.round().toString();
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (_hasCalculated) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RATE IMPACT ON YOUR MORTGAGE',
                style: AppTextStyles.dmSans(
                  size: 10,
                  weight: FontWeight.bold,
                  color: theme.getMutedColor(context),
                  letterSpacing: 0.6,
                ),
              ),
              GestureDetector(
                onTap: () => _saveRateScenario(balance, peakPmt, curPmt, monthlySavings, currentOvernight),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Text('💾', style: TextStyle(fontSize: 10)),
                      const SizedBox(width: 4),
                      Text(
                        'Save Scenario',
                        style: AppTextStyles.dmSans(
                          size: 10,
                          weight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              children: [
                _impactRow('Peak Payment (at 6.70%)', peakPmt, 'Higher monthly cost', isRed: true),
                const Divider(height: 18, thickness: 0.5),
                _impactRow('Current Payment (at ${curRate.toStringAsFixed(2)}%)', curPmt, 'Reduced monthly cost', isGreen: true),
                const Divider(height: 18, thickness: 0.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated Monthly Savings',
                          style: AppTextStyles.dmSans(
                            size: 12,
                            weight: FontWeight.bold,
                            color: theme.getTextColor(context),
                          ),
                        ),
                        Text(
                          'Overnight rate dropped 2.75%',
                          style: AppTextStyles.dmSans(
                            size: 9.5,
                            color: theme.getMutedColor(context),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(monthlySavings, symbol: 'CA\$'),
                          style: AppTextStyles.dmSans(
                            size: 13,
                            weight: FontWeight.bold,
                            color: const Color(0xFF1A5C35),
                          ),
                        ),
                        Text(
                          'saved / month',
                          style: AppTextStyles.dmSans(
                            size: 9,
                            weight: FontWeight.bold,
                            color: const Color(0xFF1A5C35),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Decision History Timeline
        Text(
          'DECISION HISTORY (2023–2026)',
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.bold,
            color: theme.getMutedColor(context),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _timelineData.length,
          itemBuilder: (context, index) {
            final item = _timelineData[index];
            final type = item['type'] as String;

            Color dotColor = const Color(0xFFF59E0B);
            Color changeBg = const Color(0xFFFFFBEB);
            Color changeText = const Color(0xFF92400E);
            if (type == 'cut') {
              dotColor = const Color(0xFF1A5C35);
              changeBg = const Color(0xFFF0FDF4);
              changeText = const Color(0xFF166534);
            } else if (type == 'hike') {
              dotColor = const Color(0xFFC8102E);
              changeBg = const Color(0xFFFEF2F2);
              changeText = const Color(0xFF991B1B);
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Timeline line & dot
                  Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: dotColor.withValues(alpha: 0.3),
                              blurRadius: 4,
                            )
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: 2,
                          color: index == _timelineData.length - 1
                              ? Colors.transparent
                              : theme.getBorderColor(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Content card
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.getCardColor(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.getBorderColor(context)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item['date'] as String,
                                style: AppTextStyles.dmSans(
                                  size: 10,
                                  weight: FontWeight.bold,
                                  color: theme.getMutedColor(context),
                                ),
                              ),
                              Text(
                                item['rate'] as String,
                                style: AppTextStyles.playfair(
                                  size: 14,
                                  weight: FontWeight.w800,
                                  color: type == 'cut'
                                      ? const Color(0xFF1A5C35)
                                      : (type == 'hike' ? const Color(0xFFC8102E) : const Color(0xFFF59E0B)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item['desc'] as String,
                                  style: AppTextStyles.dmSans(
                                    size: 11,
                                    weight: FontWeight.bold,
                                    color: theme.getTextColor(context),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: changeBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item['action'] as String,
                                  style: AppTextStyles.dmSans(
                                    size: 9,
                                    weight: FontWeight.bold,
                                    color: changeText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _infoCell(String label, String value, String note, {bool isRed = false, bool isGreen = false}) {
    Color valColor = Colors.white;
    if (isRed) {
      valColor = const Color(0xFFFF8A9A);
    } else if (isGreen) {
      valColor = const Color(0xFF6EDFA0);
    }
    return Column(
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white60, weight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(value, style: AppTextStyles.dmSans(size: 14, color: valColor, weight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(note, style: AppTextStyles.dmSans(size: 8, color: Colors.white38)),
      ],
    );
  }

  Widget _miniRateBox(String label, String val, {bool isGreen = false}) {
    final valueColor = isGreen ? const Color(0xFF6EDFA0) : Colors.white;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white54)),
            const SizedBox(height: 2),
            Text(
              val,
              style: AppTextStyles.dmSans(
                size: 12,
                weight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.dmSans(
            size: 9,
            color: widget.theme.getMutedColor(context),
            weight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _impactRow(String label, double val, String desc, {bool isRed = false, bool isGreen = false}) {
    final textStyle = AppTextStyles.dmSans(
      size: 11,
      weight: FontWeight.bold,
      color: widget.theme.getTextColor(context),
    );
    final valueStyle = AppTextStyles.dmSans(
      size: 12,
      weight: FontWeight.w800,
      color: widget.theme.primaryColor,
    );
    final subDescColor = isRed
        ? const Color(0xFFC8102E)
        : (isGreen ? const Color(0xFF1A5C35) : widget.theme.getMutedColor(context));

    final ratesAsync = ref.watch(canadaCalculatedRatesProvider);
    final currentPrime = ratesAsync.valueOrNull?.prime.value ?? 4.45;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: textStyle),
              const SizedBox(height: 2),
              Text(
                label.contains('Peak') ? 'Peak Prime: 7.20%' : 'Current Prime: ${currentPrime.toStringAsFixed(2)}%',
                style: AppTextStyles.dmSans(size: 9, color: widget.theme.getMutedColor(context)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(CurrencyFormatter.format(val, symbol: 'CA\$'), style: valueStyle),
              const SizedBox(height: 2),
              Text(desc, style: AppTextStyles.dmSans(size: 9, weight: FontWeight.bold, color: subDescColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BocRateLinePainter extends CustomPainter {
  final bool isDark;
  const _BocRateLinePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // scale SVG coordinates (viewBox 360 x 160) to actual canvas size
    final double scaleX = size.width / 360.0;
    final double scaleY = size.height / 160.0;

    final paintLine = Paint()
      ..color = const Color(0xFF1A5C35)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final paintFill = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1A5C35).withValues(alpha: 0.3),
          const Color(0xFF1A5C35).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    final paintGrid = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFF0A2E1A).withValues(alpha: 0.07)
      ..strokeWidth = 1.0;

    // Draw reference horizontal grid lines from HTML (Y axis grids for 5.0%, 4.0%, 3.0%, 2.0%)
    // In SVG: 5.0% is at y=10, 4.0% is at y=48, 3.0% is at y=86, 2.0% is at y=124
    canvas.drawLine(Offset(28 * scaleX, 10 * scaleY), Offset(355 * scaleX, 10 * scaleY), paintGrid);
    canvas.drawLine(Offset(28 * scaleX, 48 * scaleY), Offset(355 * scaleX, 48 * scaleY), paintGrid);
    canvas.drawLine(Offset(28 * scaleX, 86 * scaleY), Offset(355 * scaleX, 86 * scaleY), paintGrid);
    canvas.drawLine(Offset(28 * scaleX, 124 * scaleY), Offset(355 * scaleX, 124 * scaleY), paintGrid);

    // Points from SVG polyline
    const List<Offset> points = [
      Offset(28, 152.5),
      Offset(40, 145),
      Offset(53, 130),
      Offset(66, 115),
      Offset(79, 85),
      Offset(92, 62.5),
      Offset(105, 47.5),
      Offset(118, 32.5),
      Offset(131, 25),
      Offset(144, 17.5),
      Offset(157, 10), // Peak
      Offset(170, 10),
      Offset(183, 17.5),
      Offset(196, 25),
      Offset(209, 32.5),
      Offset(222, 47.5),
      Offset(235, 62.5),
      Offset(248, 70),
      Offset(261, 77.5),
      Offset(274, 77.5),
      Offset(287, 77.5),
      Offset(300, 85),
      Offset(313, 92.5),
      Offset(326, 92.5),
      Offset(339, 92.5),
      Offset(352, 92.5), // Current
    ];

    final pathLine = Path();
    final pathFill = Path();

    for (int i = 0; i < points.length; i++) {
      final double x = points[i].dx * scaleX;
      final double y = points[i].dy * scaleY;
      if (i == 0) {
        pathLine.moveTo(x, y);
        pathFill.moveTo(x, y);
      } else {
        pathLine.lineTo(x, y);
        pathFill.lineTo(x, y);
      }
    }

    pathFill.lineTo(352 * scaleX, size.height);
    pathFill.lineTo(28 * scaleX, size.height);
    pathFill.close();

    canvas.drawPath(pathFill, paintFill);
    canvas.drawPath(pathLine, paintLine);

    // Draw markers
    final paintMarkerOuter = Paint()..color = Colors.white;
    final paintMarkerPeak = Paint()..color = const Color(0xFFC8102E);
    final paintMarkerCur = Paint()..color = const Color(0xFF6EDFA0);

    // Peak Marker (at 157, 10)
    final Offset peakOffset = Offset(157 * scaleX, 10 * scaleY);
    canvas.drawCircle(peakOffset, 5, paintMarkerOuter);
    canvas.drawCircle(peakOffset, 3.5, paintMarkerPeak);

    // Current Marker (at 352, 92.5)
    final Offset curOffset = Offset(352 * scaleX, 92.5 * scaleY);
    canvas.drawCircle(curOffset, 5, paintMarkerOuter);
    canvas.drawCircle(curOffset, 3.5, paintMarkerCur);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
