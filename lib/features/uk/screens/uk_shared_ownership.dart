// lib/features/uk/screens/uk_shared_ownership.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import 'dart:math' as math;

class UKSharedOwnership extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;
  const UKSharedOwnership({super.key, required this.theme, this.savedCalc});

  @override
  ConsumerState<UKSharedOwnership> createState() => _UKSharedOwnershipState();
}

class _UKSharedOwnershipState extends ConsumerState<UKSharedOwnership> {
  double _propVal = 280000;
  double _income = 52000;
  double _currentShare = 25; // 25, 40, 50, 75
  double _term = 25;
  double _rate = 4.75;

  bool _showResults = false;
  final Map<String, double> _calcSnapshot = {};
  final _resultsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _propVal = inputs['propVal'] ?? 280000;
      _income = inputs['income'] ?? 52000;
      _currentShare = inputs['currentShare'] ?? 25;
      _term = inputs['term'] ?? 25;
      _rate = inputs['rate'] ?? 4.75;
      _calcSnapshot['propVal'] = _propVal;
      _calcSnapshot['income'] = _income;
      _calcSnapshot['currentShare'] = _currentShare;
      _calcSnapshot['term'] = _term;
      _calcSnapshot['rate'] = _rate;
      _showResults = true;
    }
  }

  double _pmt(double r, double n, double pv) {
    if (r == 0) return pv / n;
    return pv * (r * math.pow(1 + r, n)) / (math.pow(1 + r, n) - 1);
  }

  double _calcSDLT(double val) {
    if (val <= 425000) return 0;
    if (val <= 625000) return (val - 425000) * 0.05;
    return val * 0.05;
  }

  void _calculate() {
    setState(() {
      _calcSnapshot['propVal'] = _propVal;
      _calcSnapshot['income'] = _income;
      _calcSnapshot['currentShare'] = _currentShare;
      _calcSnapshot['term'] = _term;
      _calcSnapshot['rate'] = _rate;
      _showResults = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_resultsKey.currentContext != null) {
        Scrollable.ensureVisible(
          _resultsKey.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _reset() {
    setState(() {
      _propVal = 280000;
      _income = 52000;
      _currentShare = 25;
      _term = 25;
      _rate = 4.75;
      _calcSnapshot.clear();
      _showResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double propValVal = _showResults ? (_calcSnapshot['propVal'] ?? _propVal) : _propVal;
    final double incomeVal = _showResults ? (_calcSnapshot['income'] ?? _income) : _income;
    final double shareValPct = _showResults ? (_calcSnapshot['currentShare'] ?? _currentShare) : _currentShare;
    final double termVal = _showResults ? (_calcSnapshot['term'] ?? _term) : _term;
    final double rateVal = _showResults ? (_calcSnapshot['rate'] ?? _rate) : _rate;

    // Shared Ownership Calculations
    final shareVal = propValVal * shareValPct / 100;
    final deposit = shareVal * 0.10; // 10% deposit typical
    final loanAmt = shareVal - deposit;
    final monthlyRate = rateVal / 100 / 12;
    final n = termVal * 12;
    final mortPayment = _pmt(monthlyRate, n, loanAmt);
    final unsoldVal = propValVal * (1 - shareValPct / 100);
    final rent = unsoldVal * 0.0275 / 12; // 2.75% rent p.a.
    const serviceCharge = 150.0;
    final totalMonthly = mortPayment + rent + serviceCharge;

    // Affordability
    final pctIncome = totalMonthly / (incomeVal / 12) * 100;
    final eligible = incomeVal <= 80000 && pctIncome <= 45;

    // Staircase
    final List<Map<String, dynamic>> staircaseOptions = [
      {'pct': shareValPct + 10, 'label': '+10% staircase'},
      {'pct': shareValPct + 25, 'label': '+25% staircase'},
      {'pct': 100.0, 'label': 'Full ownership'},
    ].where((s) => (s['pct'] as double) > shareValPct && (s['pct'] as double) <= 100).toList();

    // Upfront costs
    final sdlt = _calcSDLT(shareVal);
    const legalFees = 1500.0;
    const surveyFee = 650.0;
    const mortgageFee = 995.0;
    final totalUpfront = deposit + sdlt + legalFees + surveyFee + mortgageFee;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = widget.theme.getCardColor(context);
    final textThemeColor = isDark ? Colors.white : const Color(0xFF0D0D2B);
    final borderCol = widget.theme.getBorderColor(context);

    final isDirty = _showResults && (
      _propVal != (_calcSnapshot['propVal'] ?? 0.0) ||
      _income != (_calcSnapshot['income'] ?? 0.0) ||
      _currentShare != (_calcSnapshot['currentShare'] ?? 0.0) ||
      _term != (_calcSnapshot['term'] ?? 0.0) ||
      _rate != (_calcSnapshot['rate'] ?? 0.0)
    );

    return Scaffold(
      backgroundColor: widget.theme.getBgColor(context),
      appBar: AppBar(
        title: Text('Shared Ownership', style: AppTextStyles.dmSans(size: 18, weight: FontWeight.w800, color: Colors.white)),
        backgroundColor: widget.theme.primaryColor,
        elevation: 0,
        actions: [
          if (_showResults)
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: () async {
                final calc = SavedCalc.create(
                  country: 'UK',
                  calcType: 'Shared Ownership',
                  inputs: {
                    'propVal': propValVal,
                    'income': incomeVal,
                    'currentShare': shareValPct,
                    'term': termVal,
                    'rate': rateVal,
                  },
                  results: {
                    'Share Value': shareVal,
                    'Deposit': deposit,
                    'Mortgage Payment': mortPayment,
                    'Rent Payment': rent,
                    'Total Monthly': totalMonthly,
                  },
                  label: '${shareValPct.toInt()}% share of ${CurrencyFormatter.compact(propValVal, symbol: '£')}',
                  currencyCode: 'GBP',
                );
                final messenger = ScaffoldMessenger.of(context);
                await ref.read(savedProvider.notifier).save(calc);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('✓ Shared Ownership calculation saved'),
                    backgroundColor: Color(0xFF0D9488),
                  ),
                );
              },
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Strip
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.theme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderCol),
              ),
              child: Row(
                children: [
                  Expanded(child: _rateCell('Min Share', '10%', '2024 Rules', isDark ? const Color(0xFF34D399) : const Color(0xFF059669))),
                  _divider(),
                  Expanded(child: _rateCell('Avg Rent', '2.75%', 'of unsold', textThemeColor)),
                  _divider(),
                  Expanded(child: _rateCell('Max Share', '100%', 'Freehold', isDark ? const Color(0xFFFFD700) : const Color(0xFFD97706))),
                  _divider(),
                  Expanded(child: _rateCell('FTB Relief', '£425k', 'SDLT cap', isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E))),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info Notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: isDark
                    ? const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF121230)])
                    : const LinearGradient(colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)]),
                border: Border.all(color: isDark ? const Color(0xFF4338CA).withValues(alpha: 0.5) : const Color(0xFFA5B4FC)),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🏛️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Government Shared Ownership Scheme',
                          style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1E1B4B)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Buy a 10–75% share of a home, pay subsidised rent on the rest. Staircase up to 100% ownership over time. Funded by Homes England & GLA. Income cap: £80,000 (£90,000 in London).',
                          style: AppTextStyles.dmSans(size: 10, color: isDark ? const Color(0xFFC7D2FE) : const Color(0xFF4338CA), height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'YOUR DETAILS',
                  style: AppTextStyles.dmSans(
                    size: 11,
                    weight: FontWeight.w700,
                    color: widget.theme.getMutedColor(context),
                    letterSpacing: 1.0,
                  ),
                ),
                GestureDetector(
                  onTap: _reset,
                  child: Text(
                    'Reset',
                    style: AppTextStyles.dmSans(
                      size: 11,
                      weight: FontWeight.bold,
                      color: widget.theme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Slider inputs card
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
                  _sliderGroup('Full Property Value', _propVal, 80000, 600000, '£', (v) => setState(() => _propVal = v)),
                  _sliderGroup('Annual Household Income', _income, 20000, 90000, '£', (v) => setState(() => _income = v)),
                  const SizedBox(height: 8),
                  Text(
                    'YOUR INITIAL SHARE',
                    style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w700, color: widget.theme.getMutedColor(context), letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _shareTabButton('25%', 25),
                      const SizedBox(width: 6),
                      _shareTabButton('40%', 40),
                      const SizedBox(width: 6),
                      _shareTabButton('50%', 50),
                      const SizedBox(width: 6),
                      _shareTabButton('75%', 75),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sliderGroup('Mortgage Term', _term, 10, 35, ' yrs', (v) => setState(() => _term = v)),
                  _sliderGroup('Mortgage Rate', _rate, 2.0, 8.0, '%', (v) => setState(() => _rate = v), isDecimal: true),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _calculate,
                      child: Text(
                        'Calculate Costs',
                        style: AppTextStyles.dmSans(size: 14, color: Colors.white, weight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_showResults) ...[
              if (isDirty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Text('⚠️ ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(
                          'Inputs have changed. Tap Calculate Costs to refresh results.',
                          style: AppTextStyles.dmSans(size: 11, color: Colors.amber[800], weight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                key: _resultsKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Result Hero Card
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
                            'MONTHLY TOTAL COST',
                            style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: Colors.white60, letterSpacing: 0.7),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${CurrencyFormatter.format(totalMonthly, symbol: '£').split('.').first}/mo',
                            style: AppTextStyles.dmSans(size: 34, weight: FontWeight.w800, color: Colors.white).copyWith(fontFamily: 'Georgia'),
                          ),
                          Text(
                            'Mortgage repayment + rent on unsold share',
                            style: AppTextStyles.dmSans(size: 11, color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 2.1,
                            children: [
                              _heroGridBox('Share Value', CurrencyFormatter.format(shareVal, symbol: '£').split('.').first, const Color(0xFFFFD700)),
                              _heroGridBox('Deposit (10%)', CurrencyFormatter.format(deposit, symbol: '£').split('.').first, Colors.white),
                              _heroGridBox('Mortgage/mo', CurrencyFormatter.format(mortPayment, symbol: '£').split('.').first, const Color(0xFF90EE90)),
                              _heroGridBox('Rent/mo', CurrencyFormatter.format(rent, symbol: '£').split('.').first, const Color(0xFFFF8A9A)),
                              _heroGridBox('Service Charge', '£150', Colors.white),
                              _heroGridBox('Affordability', eligible ? '✔ Eligible' : '⚠ Review', eligible ? const Color(0xFF90EE90) : const Color(0xFFFF8A9A)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Cost Distribution Donut
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: borderCol),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Cost Breakdown',
                            style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textThemeColor).copyWith(fontFamily: 'Georgia'),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              SizedBox(
                                width: 110,
                                height: 110,
                                child: Stack(
                                  children: [
                                    CustomPaint(
                                      size: const Size(110, 110),
                                      painter: _SharedOwnershipDonutPainter(
                                        mortPayment: mortPayment,
                                        rentPayment: rent,
                                        serviceCharge: serviceCharge,
                                        isDark: isDark,
                                      ),
                                    ),
                                    Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            CurrencyFormatter.format(totalMonthly, symbol: '£').split('.').first,
                                            style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: textThemeColor).copyWith(fontFamily: 'Georgia'),
                                          ),
                                          Text(
                                            'per month',
                                            style: AppTextStyles.dmSans(size: 8, color: widget.theme.getMutedColor(context), weight: FontWeight.w700),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _legendItem(isDark ? const Color(0xFF93C5FD) : const Color(0xFF1a1a5e), 'Mortgage', mortPayment),
                                    const SizedBox(height: 6),
                                    _legendItem(isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E), 'Rent', rent),
                                    const SizedBox(height: 6),
                                    _legendItem(isDark ? const Color(0xFFFFD700) : const Color(0xFFD97706), 'Service Charge', serviceCharge),
                                    const SizedBox(height: 6),
                                    _legendPctItem(const Color(0xFFE0E7FF), '% of Income', pctIncome),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Staircasing Plan Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF0D0D2B), Color(0xFF1A1A5E)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Staircasing Plan 📈',
                            style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: Colors.white).copyWith(fontFamily: 'Georgia'),
                          ),
                          Text(
                            'Cost to buy additional shares (at current value)',
                            style: AppTextStyles.dmSans(size: 10, color: Colors.white60),
                          ),
                          const SizedBox(height: 12),
                          if (staircaseOptions.isEmpty)
                            Text('You own 100% full ownership.', style: AppTextStyles.dmSans(size: 11, color: Colors.white70))
                          else
                            ...staircaseOptions.map((opt) {
                              final target = opt['pct'] as double;
                              final addPct = target - shareValPct;
                              final cost = propValVal * addPct / 100;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
                                      alignment: Alignment.center,
                                      child: Text('${target.toInt()}%', style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: const Color(0xFFFFD700))),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(opt['label'] as String, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w700, color: Colors.white)),
                                          const SizedBox(height: 2),
                                          Text('Covers ${addPct.toInt()}% at current ${CurrencyFormatter.compact(propValVal, symbol: '£')} valuation', style: AppTextStyles.dmSans(size: 10, color: Colors.white54)),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(cost, symbol: '£').split('.').first,
                                      style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: const Color(0xFF90EE90)),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Upfront costs card
                    Text(
                      'UPFRONT COSTS',
                      style: AppTextStyles.dmSans(
                        size: 11,
                        weight: FontWeight.w700,
                        color: widget.theme.getMutedColor(context),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderCol),
                      ),
                      child: Column(
                        children: [
                          _upfrontRow('Deposit (10%)', deposit, 'On your ${shareValPct.toInt()}% share'),
                          _upfrontRow('Stamp Duty (SDLT)', sdlt, 'On share value (FTB relief applied)', isRed: true),
                          _upfrontRow('Legal / Conveyancing', legalFees, 'Estimated solicitor fees', isRed: true),
                          _upfrontRow('Survey Fee', surveyFee, 'HomeBuyer Report (RICS)', isRed: true),
                          _upfrontRow('Mortgage Arrangement Fee', mortgageFee, 'Typical lender fee', isRed: true),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Total Upfront', style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: widget.theme.primaryColor)),
                                  Text('Cash needed at completion', style: AppTextStyles.dmSans(size: 10, color: widget.theme.getMutedColor(context))),
                                ],
                              ),
                              Text(
                                CurrencyFormatter.format(totalUpfront, symbol: '£').split('.').first,
                                style: AppTextStyles.dmSans(size: 16, weight: FontWeight.w800, color: widget.theme.primaryColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Eligibility Card
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
                          Text(
                            'Can you apply? 🔍',
                            style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: textThemeColor).copyWith(fontFamily: 'Georgia'),
                          ),
                          const SizedBox(height: 12),
                          _eligibilityRow(
                            eligible: incomeVal <= 80000,
                            text: 'Household income: ${CurrencyFormatter.format(incomeVal, symbol: '£').split('.').first} — ${incomeVal <= 80000 ? 'within' : 'EXCEEDS'} the £80,000 cap (£90,000 in London).',
                          ),
                          const SizedBox(height: 8),
                          _eligibilityRow(
                            eligible: true,
                            text: 'First-time buyer or previous shared owner required (or no longer able to afford current home).',
                          ),
                          const SizedBox(height: 8),
                          _eligibilityRow(
                            eligible: true,
                            text: 'Must not own another home at time of purchase.',
                          ),
                          const SizedBox(height: 8),
                          _eligibilityRow(
                            eligible: propValVal <= 600000,
                            text: 'Property value: ${CurrencyFormatter.format(propValVal, symbol: '£').split('.').first} — ${propValVal <= 600000 ? 'within typical' : 'above'} the affordable housing threshold.',
                          ),
                          const SizedBox(height: 8),
                          _eligibilityRow(
                            eligible: true,
                            text: 'Lease requirement: minimum 80 years remaining on lease recommended before purchasing.',
                            isWarning: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _eligibilityRow({required bool eligible, required String text, bool isWarning = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isWarning ? 'ℹ️' : (eligible ? '✅' : '❌'),
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.dmSans(size: 11.5, color: isDark ? Colors.white70 : const Color(0xFF374151), height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _upfrontRow(String label, double val, String desc, {bool isRed = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w700, color: widget.theme.getTextColor(context))),
              Text(desc, style: AppTextStyles.dmSans(size: 10, color: widget.theme.getMutedColor(context))),
            ],
          ),
          Text(
            CurrencyFormatter.format(val, symbol: '£').split('.').first,
            style: AppTextStyles.dmSans(
              size: 12.5,
              weight: FontWeight.w800,
              color: isRed
                  ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E))
                  : widget.theme.getTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, double value) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: AppTextStyles.dmSans(size: 10.5, color: widget.theme.getTextColor(context).withValues(alpha: 0.7))),
        ),
        Text(
          CurrencyFormatter.format(value, symbol: '£').split('.').first,
          style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: widget.theme.getTextColor(context)),
        ),
      ],
    );
  }

  Widget _legendPctItem(Color color, String label, double value) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: AppTextStyles.dmSans(size: 10.5, color: widget.theme.getTextColor(context).withValues(alpha: 0.7))),
        ),
        Text(
          '${value.toStringAsFixed(0)}%',
          style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: widget.theme.getTextColor(context)),
        ),
      ],
    );
  }

  Widget _shareTabButton(String label, double val) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = _currentShare == val;
    final activeCol = isDark ? const Color(0xFF93C5FD) : const Color(0xFF1a1a5e);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _currentShare = val;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? activeCol
                : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F8)),
            border: Border.all(color: active ? activeCol : const Color(0xFFE0E7FF), width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
              size: 11.5,
              weight: FontWeight.w700,
              color: active
                  ? (isDark ? const Color(0xFF0D0D2B) : Colors.white)
                  : widget.theme.getMutedColor(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroGridBox(String label, String val, Color valColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54)),
          const SizedBox(height: 2),
          Text(val, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: valColor)),
        ],
      ),
    );
  }

  Widget _sliderGroup(String label, double val, double min, double max, String suffix, ValueChanged<double> onChanged, {bool isDecimal = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: widget.theme.getTextColor(context))),
            Text(
              suffix == '£' ? CurrencyFormatter.format(val, symbol: '£').split('.').first : '${isDecimal ? val.toStringAsFixed(2) : val.toInt()}$suffix',
              style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: isDark ? const Color(0xFF93C5FD) : widget.theme.primaryColor),
            ),
          ],
        ),
        Slider(
          value: val.clamp(min, max),
          min: min,
          max: max,
          activeColor: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1a1a5e),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _rateCell(String label, String value, String note, Color valueColor) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(size: 8, color: widget.theme.getMutedColor(context), weight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: valueColor),
        ),
        Text(
          note,
          style: AppTextStyles.dmSans(size: 8, color: widget.theme.getMutedColor(context)),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.grey.withValues(alpha: 0.2),
    );
  }
}

class _SharedOwnershipDonutPainter extends CustomPainter {
  final double mortPayment;
  final double rentPayment;
  final double serviceCharge;
  final bool isDark;

  _SharedOwnershipDonutPainter({
    required this.mortPayment,
    required this.rentPayment,
    required this.serviceCharge,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;

    final bgPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawCircle(center, radius, bgPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);

    final double total = mortPayment + rentPayment + serviceCharge;
    if (total <= 0) return;

    final mortPct = mortPayment / total;
    final rentPct = rentPayment / total;
    final svcPct = serviceCharge / total;

    final double mortRad = mortPct * 2 * math.pi;
    final double rentRad = rentPct * 2 * math.pi;
    final double svcRad = svcPct * 2 * math.pi;

    final mortPaint = Paint()
      ..color = isDark ? const Color(0xFF93C5FD) : const Color(0xFF1a1a5e)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.butt;

    final rentPaint = Paint()
      ..color = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.butt;

    final svcPaint = Paint()
      ..color = isDark ? const Color(0xFFFFD700) : const Color(0xFFD97706)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.butt;

    double startAngle = -math.pi / 2;

    canvas.drawArc(rect, startAngle, mortRad, false, mortPaint);
    startAngle += mortRad;

    canvas.drawArc(rect, startAngle, rentRad, false, rentPaint);
    startAngle += rentRad;

    canvas.drawArc(rect, startAngle, svcRad, false, svcPaint);
  }

  @override
  bool shouldRepaint(covariant _SharedOwnershipDonutPainter oldDelegate) {
    return oldDelegate.mortPayment != mortPayment ||
        oldDelegate.rentPayment != rentPayment ||
        oldDelegate.serviceCharge != serviceCharge ||
        oldDelegate.isDark != isDark;
  }
}
