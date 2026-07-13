// lib/features/uk/tools/uk_mortgage_calc.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/result_panel.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/uk_rates_provider.dart';
import '../../../shared/models/saved_calc.dart';
import 'dart:math' as math;

class UKMortgageCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;
  const UKMortgageCalc({super.key, required this.theme, this.savedCalc});

  @override
  ConsumerState<UKMortgageCalc> createState() => _UKMortgageCalcState();
}

class _UKMortgageCalcState extends ConsumerState<UKMortgageCalc> {
  String _repaymentType = 'repayment'; // repayment, interest
  String _mortgageType = 'residential'; // residential, btl, remortgage

  final _propValController = TextEditingController(text: '380000');
  final _depositController = TextEditingController(text: '57000');
  final _rateController = TextEditingController(text: '4.75');
  final _termController = TextEditingController(text: '25');

  double _propVal = 380000;
  double _deposit = 57000;
  double _rate = 4.75;
  int _term = 25;

  bool _hasCalculated = false;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(settingsProvider.notifier).getCalculatorInputs('UK', 'mortgage');
    if (saved != null) {
      _propValController.text = (saved['propVal'] as num?)?.toStringAsFixed(0) ?? '380000';
      _depositController.text = (saved['deposit'] as num?)?.toStringAsFixed(0) ?? '57000';
      _rateController.text = (saved['rate'] as num?)?.toString() ?? '4.75';
      _termController.text = (saved['term'] as num?)?.toStringAsFixed(0) ?? '25';
      _repaymentType = saved['repaymentType'] as String? ?? 'repayment';
      _mortgageType = saved['mortgageType'] as String? ?? 'residential';
      _hasCalculated = true;
    } else if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _propValController.text =
          (inputs['propVal'] ?? 380000.0).toStringAsFixed(0);
      _depositController.text =
          (inputs['deposit'] ?? 57000.0).toStringAsFixed(0);
      _rateController.text = (inputs['rate'] ?? 4.75).toString();
      _termController.text = (inputs['term'] ?? 25.0).toStringAsFixed(0);
      _repaymentType =
          (inputs['isRepayment'] ?? 1.0) == 1.0 ? 'repayment' : 'interest';
      _hasCalculated = true;
    }
    _calculateValues();
  }

  @override
  void dispose() {
    _propValController.dispose();
    _depositController.dispose();
    _rateController.dispose();
    _termController.dispose();
    super.dispose();
  }

  void _calculateValues() {
    setState(() {
      _propVal = double.tryParse(_propValController.text) ?? 0;
      _deposit = double.tryParse(_depositController.text) ?? 0;
      _rate = double.tryParse(_rateController.text) ?? 4.75;
      _term = int.tryParse(_termController.text) ?? 25;
    });
    _persistInputs();
  }

  void _persistInputs() {
    ref.read(settingsProvider.notifier).saveCalculatorInput('UK', 'mortgage', {
      'propVal': _propVal,
      'deposit': _deposit,
      'rate': _rate,
      'term': _term,
      'repaymentType': _repaymentType,
      'mortgageType': _mortgageType,
    });
  }

  double _pmt(double r, double n, double pv) {
    if (r == 0) return pv / n;
    return pv * (r * math.pow(1 + r, n)) / (math.pow(1 + r, n) - 1);
  }

  @override
  Widget build(BuildContext context) {
    final loan = _propVal - _deposit;
    final ltv = _propVal > 0 ? (loan / _propVal * 100) : 0.0;
    final mRate = _rate / 100 / 12;
    final n = _term * 12;

    double monthly;
    if (_repaymentType == 'repayment') {
      monthly = mRate == 0 ? loan / n : _pmt(mRate, n.toDouble(), loan);
    } else {
      monthly = loan * mRate;
    }

    final totalRepaid =
        _repaymentType == 'repayment' ? (monthly * n) : (monthly * n + loan);
    final totalInterest = totalRepaid - loan;
    final interestPct =
        totalRepaid > 0 ? (totalInterest / totalRepaid * 100) : 0.0;

    // Stress test: typical UK avg income = £45k
    const avgAnnual = 45000;
    final ptoi = (monthly * 12) / avgAnnual * 100;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = widget.theme.getCardColor(context);
    final textThemeColor = widget.theme.getTextColor(context);
    final borderCol = widget.theme.getBorderColor(context);

    // Live BoE rates
    final ukRates = ref.watch(ukRatesProvider).valueOrNull;
    final boeBase  = ukRates?.boeBase.value  ?? 4.25;
    final fixed2yr = ukRates?.fixed2yr.value ?? 4.75;
    final fixed5yr = ukRates?.fixed5yr.value ?? 4.35;
    final isLive   = ukRates?.isLive == true;

    return Column(
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
              Expanded(
                  child: _rateCell('2-Yr Fixed', '${fixed2yr.toStringAsFixed(2)}%',
                      isLive ? 'Live 🟢' : 'Jun 2025',
                      isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E))),
              _divider(),
              Expanded(
                  child: _rateCell(
                      '5-Yr Fixed', '${fixed5yr.toStringAsFixed(2)}%', 'Best buy', textThemeColor)),
              _divider(),
              Expanded(
                  child: _rateCell('BoE Base', '${boeBase.toStringAsFixed(2)}%',
                      isLive ? 'Live 🟢' : 'May 2025',
                      isDark ? const Color(0xFFFFD700) : const Color(0xFFD97706))),
              _divider(),
              Expanded(
                  child: _rateCell('Tracker', '${(boeBase + 0.25).toStringAsFixed(2)}%', 'Base+0.25',
                      isDark ? const Color(0xFF34D399) : const Color(0xFF059669))),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'MORTGAGE DETAILS',
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w700,
            color: widget.theme.getMutedColor(context),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),

        // Inputs Card
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
                'REPAYMENT TYPE',
                style: AppTextStyles.dmSans(
                    size: 8.5,
                    weight: FontWeight.w700,
                    color: widget.theme.getMutedColor(context),
                    letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _tabButton(
                      label: 'Repayment',
                      active: _repaymentType == 'repayment',
                      onTap: () => setState(() {
                        _repaymentType = 'repayment';
                        _calculateValues();
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _tabButton(
                      label: 'Interest Only',
                      active: _repaymentType == 'interest',
                      onTap: () => setState(() {
                        _repaymentType = 'interest';
                        _calculateValues();
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                      child: _inputField(
                          label: 'Property Value (£)',
                          controller: _propValController)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _inputField(
                          label: 'Deposit (£)',
                          controller: _depositController)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _inputField(
                          label: 'Interest Rate (%)',
                          controller: _rateController)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _inputField(
                          label: 'Term (Years)', controller: _termController)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'MORTGAGE TYPE',
                style: AppTextStyles.dmSans(
                    size: 8.5,
                    weight: FontWeight.w700,
                    color: widget.theme.getMutedColor(context),
                    letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF5F5F8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _mortgageType,
                    isExpanded: true,
                    dropdownColor: cardBg,
                    style: AppTextStyles.dmSans(
                        size: 13,
                        weight: FontWeight.w700,
                        color: textThemeColor),
                    items: const [
                      DropdownMenuItem(
                          value: 'residential',
                          child: Text('Residential Mortgage')),
                      DropdownMenuItem(
                          value: 'btl', child: Text('Buy-to-Let Mortgage')),
                      DropdownMenuItem(
                          value: 'remortgage', child: Text('Remortgage')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _mortgageType = val;
                          _calculateValues();
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Calculate Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC8102E),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13)),
            ),
            onPressed: () {
              _calculateValues();
              setState(() => _hasCalculated = true);
            },
            child: Text(
              '🏠 Calculate Mortgage',
              style: AppTextStyles.dmSans(
                  size: 14, color: Colors.white, weight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (_hasCalculated) ...[
          // Results Header Card
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
                  'MONTHLY PAYMENT',
                  style: AppTextStyles.dmSans(
                      size: 10,
                      weight: FontWeight.w700,
                      color: Colors.white60,
                      letterSpacing: 0.7),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      CurrencyFormatter.format(monthly, symbol: '£'),
                      style: AppTextStyles.dmSans(
                              size: 34,
                              weight: FontWeight.w800,
                              color: const Color(0xFFFFD700))
                          .copyWith(fontFamily: 'Georgia'),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final calc = SavedCalc.create(
                          country: 'UK',
                          calcType: 'Mortgage Calc',
                          inputs: {
                            'propVal': _propVal,
                            'deposit': _deposit,
                            'rate': _rate,
                            'term': _term.toDouble(),
                            'isRepayment':
                                _repaymentType == 'repayment' ? 1.0 : 0.0,
                          },
                          results: {
                            'Monthly Payment': monthly,
                            'Loan Amount': loan,
                            'Total Repaid': totalRepaid,
                            'Total Interest': totalInterest,
                            'LTV Ratio': ltv,
                          },
                          label:
                              '${CurrencyFormatter.compact(_propVal, symbol: '£')} prop · ${_rate.toStringAsFixed(2)}% · $_term yrs',
                          currencyCode: 'GBP',
                        );
                        final messenger = ScaffoldMessenger.of(context);
                        await ref.read(savedProvider.notifier).save(calc);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('✓ Mortgage calculation saved'),
                            backgroundColor: Color(0xFF0D9488),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.save,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text('Save',
                                style: AppTextStyles.dmSans(
                                    size: 11,
                                    weight: FontWeight.w800,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_repaymentType == 'repayment' ? 'Repayment' : 'Interest Only'} · ${_rate.toStringAsFixed(2)}% · $_term yrs',
                  style: AppTextStyles.dmSans(size: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Result grid panel
          ResultPanel(
            primaryColor: widget.theme.primaryColor,
            rows: [
              ResultRow(label: 'Loan Amount', value: loan, currencyCode: 'GBP'),
              ResultRow(
                  label: 'Total Repaid',
                  value: totalRepaid,
                  currencyCode: 'GBP'),
              ResultRow(
                  label: 'Total Interest',
                  value: totalInterest,
                  currencyCode: 'GBP',
                  isHighlighted: true),
              ResultRow(label: 'LTV Ratio', value: ltv / 100, isPercent: true),
            ],
          ),
          const SizedBox(height: 12),

          // Affordability stress test panel
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
                  'Payment-to-Income Stress Test',
                  style: AppTextStyles.dmSans(
                          size: 12,
                          weight: FontWeight.w800,
                          color: textThemeColor)
                      .copyWith(fontFamily: 'Georgia'),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 14,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF15803D),
                          Color(0xFF1a1a5e),
                          Color(0xFFD97706),
                          Color(0xFFC8102E)
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Align(
                          alignment:
                              Alignment(ptoi.clamp(0.0, 100.0) / 50 - 1.0, 0),
                          child: Container(
                            width: 6,
                            height: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Affordable',
                        style: AppTextStyles.dmSans(
                            size: 8.5,
                            color: widget.theme.getMutedColor(context),
                            weight: FontWeight.w700)),
                    Text('Moderate',
                        style: AppTextStyles.dmSans(
                            size: 8.5,
                            color: widget.theme.getMutedColor(context),
                            weight: FontWeight.w700)),
                    Text('Stretched',
                        style: AppTextStyles.dmSans(
                            size: 8.5,
                            color: widget.theme.getMutedColor(context),
                            weight: FontWeight.w700)),
                    Text('High Risk',
                        style: AppTextStyles.dmSans(
                            size: 8.5,
                            color: widget.theme.getMutedColor(context),
                            weight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: ptoi < 28
                          ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5))
                          : ptoi < 40
                              ? (isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7))
                              : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ptoi < 28
                          ? '✓ Affordable (${ptoi.toStringAsFixed(0)}% of avg income)'
                          : ptoi < 40
                              ? '⚠ Moderate (${ptoi.toStringAsFixed(0)}% of avg income)'
                              : '✗ Stretched (${ptoi.toStringAsFixed(0)}% of avg income)',
                      style: AppTextStyles.dmSans(
                        size: 10.5,
                        weight: FontWeight.w800,
                        color: ptoi < 28
                            ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D))
                            : ptoi < 40
                                ? (isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E))
                                : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Total cost breakdown pie chart (donut)
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
                  '📊 Total Cost Breakdown',
                  style: AppTextStyles.dmSans(
                          size: 12,
                          weight: FontWeight.w800,
                          color: textThemeColor)
                      .copyWith(fontFamily: 'Georgia'),
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
                            painter: _UKMortgageDonutPainter(
                              interestPct: interestPct,
                              isDark: isDark,
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${interestPct.toStringAsFixed(0)}%',
                                  style: AppTextStyles.dmSans(
                                          size: 14,
                                          weight: FontWeight.w800,
                                          color: textThemeColor)
                                      .copyWith(fontFamily: 'Georgia'),
                                ),
                                Text(
                                  'Interest',
                                  style: AppTextStyles.dmSans(
                                      size: 8.5,
                                      color: widget.theme.getMutedColor(context),
                                      weight: FontWeight.w700),
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
                          _legendItem(
                              isDark ? const Color(0xFF93C5FD) : const Color(0xFF1a1a5e), 'Principal', loan),
                          const SizedBox(height: 8),
                          _legendItem(const Color(0xFFC8102E), 'Interest',
                              totalInterest),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Amortization Preview columns
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
                  '📅 Principal vs Interest Over Time',
                  style: AppTextStyles.dmSans(
                          size: 12,
                          weight: FontWeight.w800,
                          color: textThemeColor)
                      .copyWith(fontFamily: 'Georgia'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: _buildAmortBars(loan, mRate, n),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: const Color(0xFFC8102E),
                                borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 4),
                        Text('Interest',
                            style: AppTextStyles.dmSans(
                                size: 10, color: widget.theme.getMutedColor(context))),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1a1a5e),
                                borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 4),
                        Text('Principal',
                            style: AppTextStyles.dmSans(
                                size: 10, color: widget.theme.getMutedColor(context))),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildAmortBars(double loan, double mRate, int totalMonths) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Widget> bars = [];
    const stepsCount = 7;
    final stepSize = (totalMonths / stepsCount).floor();

    double balance = loan;
    for (int step = 1; step <= stepsCount; step++) {
      final mo = step * stepSize;
      if (mo > totalMonths) break;

      double intAmt = 0;
      double prinAmt = 0;
      double bal = balance;

      // Calculate principal/interest for this step's year (e.g. 12 months)
      for (int i = 0; i < 12; i++) {
        final currentInt = bal * mRate;
        double currentPmt;
        if (_repaymentType == 'repayment') {
          currentPmt = mRate == 0
              ? loan / totalMonths
              : _pmt(mRate, totalMonths.toDouble(), loan);
        } else {
          currentPmt = loan * mRate;
        }
        final currentPrin = currentPmt - currentInt;
        intAmt += currentInt;
        prinAmt += currentPrin;
        bal -= currentPrin;
      }
      balance = bal;

      final total = intAmt + prinAmt;
      final intPct = total > 0 ? (intAmt / total) : 0.0;
      final prinPct = total > 0 ? (prinAmt / total) : 0.0;

      bars.add(
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 12,
                height: (40 * intPct).clamp(2.0, 40.0),
                color: const Color(0xFFC8102E),
              ),
              Container(
                width: 12,
                height: (40 * prinPct).clamp(2.0, 40.0),
                color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1a1a5e),
              ),
              const SizedBox(height: 4),
              Text(
                'Yr ${(mo / 12).round()}',
                style: AppTextStyles.dmSans(
                    size: 7.5, color: widget.theme.getMutedColor(context)),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: bars,
    );
  }

  Widget _legendItem(Color color, String label, double value) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: AppTextStyles.dmSans(
                  size: 11,
                  color: widget.theme.getTextColor(context).withValues(alpha: 0.7))),
        ),
        Text(
          CurrencyFormatter.format(value, symbol: '£').split('.').first,
          style: AppTextStyles.dmSans(
              size: 12, weight: FontWeight.w800, color: widget.theme.getTextColor(context)),
        ),
      ],
    );
  }

  Widget _tabButton(
      {required String label,
      required bool active,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF0D0D2B)
              : (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF5F5F8)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? const Color(0xFF0D0D2B)
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 12,
            weight: FontWeight.w800,
            color: active ? const Color(0xFFFFD700) : widget.theme.getMutedColor(context),
          ),
        ),
      ),
    );
  }

  Widget _rateCell(String label, String value, String note, Color valueColor) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
              size: 8, color: widget.theme.getMutedColor(context), weight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.dmSans(
              size: 13, weight: FontWeight.w800, color: valueColor),
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

  Widget _inputField(
      {required String label, required TextEditingController controller}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8.5,
            weight: FontWeight.w700,
            color: widget.theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => _calculateValues(),
          style: AppTextStyles.dmSans(
            size: 13,
            weight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0D0D2B),
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF5F5F8),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _UKMortgageDonutPainter extends CustomPainter {
  final double interestPct;
  final bool isDark;

  _UKMortgageDonutPainter({required this.interestPct, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;

    final bgPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.05)
          : const Color(0xFFEEF2FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawCircle(center, radius, bgPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);

    final principalPaint = Paint()
      ..color = isDark ? const Color(0xFF93C5FD) : const Color(0xFF1a1a5e)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.butt;

    final interestPaint = Paint()
      ..color = const Color(0xFFC8102E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.butt;

    final double interestRad = (interestPct / 100) * 2 * math.pi;
    final double principalRad = 2 * math.pi - interestRad;

    // Draw principal arc (top starting at -pi/2)
    canvas.drawArc(rect, -math.pi / 2, principalRad, false, principalPaint);

    // Draw interest arc
    canvas.drawArc(
        rect, -math.pi / 2 + principalRad, interestRad, false, interestPaint);
  }

  @override
  bool shouldRepaint(covariant _UKMortgageDonutPainter oldDelegate) {
    return oldDelegate.interestPct != interestPct ||
        oldDelegate.isDark != isDark;
  }
}
