// lib/features/uk/tools/uk_amortization.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/result_panel.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/uk_rates_provider.dart';
import '../../../shared/models/saved_calc.dart';
import 'dart:math' as math;

class UKAmortization extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;
  const UKAmortization({super.key, required this.theme, this.savedCalc});

  @override
  ConsumerState<UKAmortization> createState() => _UKAmortizationState();
}

class _UKAmortizationState extends ConsumerState<UKAmortization> {
  final _loanController = TextEditingController(text: '250000');
  final _termController = TextEditingController(text: '25');
  final _rateController = TextEditingController(text: '4.75');
  final _extraController = TextEditingController(text: '0');

  double _loan = 250000;
  double _term = 25;
  double _rate = 4.75;
  double _extra = 0;

  String _viewMode = 'year'; // year, month

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _loanController.text = (inputs['loan'] ?? 250000.0).toStringAsFixed(0);
      _termController.text = (inputs['term'] ?? 25.0).toString().replaceAll(RegExp(r'\.0$'), '');
      _rateController.text = (inputs['rate'] ?? 4.75).toString();
      _extraController.text = (inputs['extra'] ?? 0.0).toStringAsFixed(0);
    }
    _calculateValues();
  }

  @override
  void dispose() {
    _loanController.dispose();
    _termController.dispose();
    _rateController.dispose();
    _extraController.dispose();
    super.dispose();
  }

  void _calculateValues() {
    setState(() {
      _loan = double.tryParse(_loanController.text) ?? 0;
      _term = double.tryParse(_termController.text) ?? 25;
      _rate = double.tryParse(_rateController.text) ?? 0;
      _extra = double.tryParse(_extraController.text) ?? 0;
    });
  }

  double _pmt(double r, double n, double pv) {
    if (r == 0) return pv / n;
    return pv * (r * math.pow(1 + r, n)) / (math.pow(1 + r, n) - 1);
  }

  @override
  Widget build(BuildContext context) {
    final rMo = _rate / 100 / 12;
    final totalMonths = (_term * 12).toInt();
    final basePmt = _pmt(rMo, totalMonths.toDouble(), _loan);
    final totalPmt = basePmt + _extra;

    // Generate schedule
    final List<Map<String, dynamic>> yearlyData = [];
    final List<Map<String, dynamic>> monthlyData = [];

    double bal = _loan;
    double totalInt = 0;
    double totalPrin = 0;
    int? halfwayYr;
    int? extraEndYr;

    Map<String, dynamic>? ms75;
    Map<String, dynamic>? ms50;
    Map<String, dynamic>? ms25;
    Map<String, dynamic>? ms10;

    for (int mo = 1; mo <= totalMonths && bal > 0.01; mo++) {
      final intPaid = bal * rMo;
      double prinPaid = totalPmt - intPaid;
      if (prinPaid > bal) prinPaid = bal;
      bal -= prinPaid;
      totalInt += intPaid;
      totalPrin += prinPaid;

      final yr = (mo / 12).ceil();
      if (yearlyData.length < yr) {
        yearlyData.add({
          'yr': yr,
          'payment': 0.0,
          'principal': 0.0,
          'interest': 0.0,
          'balance': 0.0,
        });
      }

      yearlyData[yr - 1]['payment'] = (yearlyData[yr - 1]['payment'] as double) + totalPmt;
      yearlyData[yr - 1]['principal'] = (yearlyData[yr - 1]['principal'] as double) + prinPaid;
      yearlyData[yr - 1]['interest'] = (yearlyData[yr - 1]['interest'] as double) + intPaid;
      yearlyData[yr - 1]['balance'] = bal;

      monthlyData.add({
        'mo': mo,
        'payment': totalPmt,
        'principal': prinPaid,
        'interest': intPaid,
        'balance': bal,
      });

      if (halfwayYr == null && bal <= _loan / 2) halfwayYr = yr;
      if (_extra > 0 && extraEndYr == null && bal <= 0.01) extraEndYr = yr;

      if (ms75 == null && bal <= _loan * 0.75) ms75 = {'yr': yr, 'val': bal};
      if (ms50 == null && bal <= _loan * 0.5) ms50 = {'yr': yr, 'val': bal};
      if (ms25 == null && bal <= _loan * 0.25) ms25 = {'yr': yr, 'val': bal};
      if (ms10 == null && bal <= _loan * 0.1) ms10 = {'yr': yr, 'val': bal};
    }

    final totalRepaid = totalPrin + totalInt;
    final intRatio = totalRepaid > 0 ? (totalInt / totalRepaid * 100) : 0.0;
    final actualTermYrs = yearlyData.length;
    final termSavedYrs = _extra > 0 ? (_term - actualTermYrs).clamp(0.0, _term) : 0.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = widget.theme.getCardColor(context);
    final textThemeColor = isDark ? Colors.white : const Color(0xFF0D0D2B);
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
              Expanded(child: _rateCell('Avg Mortgage', '25 yr', 'UK typical', textThemeColor)),
              _divider(),
              Expanded(child: _rateCell('2-Yr Fixed', '${fixed2yr.toStringAsFixed(2)}%', isLive ? 'Live 🟢' : 'Best buy', Colors.redAccent)),
              _divider(),
              Expanded(child: _rateCell('5-Yr Fixed', '${fixed5yr.toStringAsFixed(2)}%', 'Best buy', textThemeColor)),
              _divider(),
              Expanded(child: _rateCell('BoE Base', '${boeBase.toStringAsFixed(2)}%', isLive ? 'Live 🟢' : 'Current', isDark ? Colors.amber : const Color(0xFFD97706))),
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
            children: [
              Row(
                children: [
                  Expanded(child: _inputField(label: 'Loan Amount (£)', controller: _loanController)),
                  const SizedBox(width: 10),
                  Expanded(child: _inputField(label: 'Term (years)', controller: _termController)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _inputField(label: 'Interest Rate (%)', controller: _rateController)),
                  const SizedBox(width: 10),
                  Expanded(child: _inputField(label: 'Extra Monthly (£)', controller: _extraController)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Result Hero
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ESTIMATED MONTHLY REPAYMENT',
                style: AppTextStyles.dmSans(
                  size: 10,
                  weight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    CurrencyFormatter.format(totalPmt, symbol: '£').split('.').first,
                    style: AppTextStyles.dmSans(
                      size: 38,
                      weight: FontWeight.w800,
                      color: const Color(0xFFFFD700),
                    ).copyWith(fontFamily: 'Georgia'),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final calc = SavedCalc.create(
                        country: 'UK',
                        calcType: 'Amortization',
                        inputs: {
                          'loan': _loan,
                          'term': _term,
                          'rate': _rate,
                          'extra': _extra,
                        },
                        results: {
                          'Monthly Payment': totalPmt,
                          'Total Repaid': totalRepaid,
                          'Total Interest': totalInt,
                          'Term Saved Yrs': termSavedYrs,
                        },
                        label: '${CurrencyFormatter.compact(_loan, symbol: '£')} @ ${_rate.toStringAsFixed(2)}% · ${totalPmt.toStringAsFixed(0)}/mo',
                        currencyCode: 'GBP',
                      );
                      final messenger = ScaffoldMessenger.of(context);
                      await ref.read(savedProvider.notifier).save(calc);
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('✓ Amortization calculation saved'),
                          backgroundColor: Color(0xFF0D9488),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.save, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text('Save', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Base: ${CurrencyFormatter.format(basePmt, symbol: '£').split('.').first} + ${CurrencyFormatter.format(_extra, symbol: '£').split('.').first}/mo overpayment',
                style: AppTextStyles.dmSans(size: 11, color: Colors.white.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Total Interest: ${CurrencyFormatter.format(totalInt, symbol: '£').split('.').first} (${intRatio.toStringAsFixed(0)}% of total cost)',
                  style: AppTextStyles.dmSans(
                    size: 11,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Metrics Grid
        ResultPanel(
          primaryColor: widget.theme.primaryColor,
          rows: [
            ResultRow(label: 'Total Repaid', value: totalRepaid, currencyCode: 'GBP'),
            ResultRow(label: 'Total Interest', value: totalInt, currencyCode: 'GBP', isHighlighted: true),
            ResultRow(label: 'Half-way Point', value: halfwayYr != null ? halfwayYr.toDouble() : 0, isPercent: false, isYears: true),
            ResultRow(label: 'Interest-Free After', value: _extra > 0 ? termSavedYrs : 0.0, isPercent: false, isYears: true),
          ],
        ),
        const SizedBox(height: 16),

        // Chart Card
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
              Text(
                'Balance · Principal · Interest Over Time',
                style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textThemeColor),
              ),
              Text(
                'Annual view — outstanding balance & cumulative costs',
                style: AppTextStyles.dmSans(size: 9.5, color: widget.theme.getMutedColor(context)),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                width: double.infinity,
                child: CustomPaint(
                  painter: AmortizationChartPainter(
                    yearlyData: yearlyData,
                    loan: _loan,
                    isDark: isDark,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendItem(isDark ? Colors.white : const Color(0xFF0D0D2B), 'Balance'),
                  const SizedBox(width: 12),
                  _legendItem(const Color(0xFF059669), 'Principal paid'),
                  const SizedBox(width: 12),
                  _legendItem(const Color(0xFFC8102E), 'Interest paid'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Milestones
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: isDark ? [const Color(0xFF1E1B4B), const Color(0xFF121230)] : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF4338CA).withValues(alpha: 0.5) : const Color(0xFFA5B4FC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🏁 Balance Milestones',
                style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1E1B4B)),
              ),
              const SizedBox(height: 12),
              _milestoneRow('75% remaining', ms75),
              _milestoneRow('50% remaining', ms50),
              _milestoneRow('25% remaining', ms25),
              _milestoneRow('10% remaining', ms10),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Table Toggle Button
        Row(
          children: [
            Expanded(
              child: _tabButton(
                label: '📅 Annual View',
                active: _viewMode == 'year',
                onTap: () => setState(() => _viewMode = 'year'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _tabButton(
                label: '📆 Monthly View',
                active: _viewMode == 'month',
                onTap: () => setState(() => _viewMode = 'month'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Table
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                color: const Color(0xFF0D0D2B),
                child: Row(
                  children: [
                    Expanded(flex: 1, child: Text(_viewMode == 'year' ? 'Yr' : 'Mo', style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w700, color: Colors.white70))),
                    Expanded(flex: 2, child: Text('Payment', style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w700, color: Colors.white70))),
                    Expanded(flex: 2, child: Text('Principal', style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w700, color: Colors.white70))),
                    Expanded(flex: 2, child: Text('Interest', style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w700, color: Colors.white70))),
                    Expanded(flex: 2, child: Text('Balance', style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w700, color: Colors.white70))),
                  ],
                ),
              ),
              SizedBox(
                height: 260,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _viewMode == 'year' ? yearlyData.length : monthlyData.length,
                  itemBuilder: (context, index) {
                    final row = _viewMode == 'year' ? yearlyData[index] : monthlyData[index];
                    final stepLabel = _viewMode == 'year' ? row['yr'].toString() : row['mo'].toString();
                    final payment = row['payment'] as double;
                    final principal = row['principal'] as double;
                    final interest = row['interest'] as double;
                    final balance = row['balance'] as double;

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: index % 2 == 0 ? (isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAFAFA)) : Colors.transparent,
                        border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.black12, width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 1, child: Text(stepLabel, style: AppTextStyles.dmSans(size: 10.5, color: textThemeColor, weight: FontWeight.w700))),
                          Expanded(flex: 2, child: Text(CurrencyFormatter.format(payment, symbol: '£').split('.').first, style: AppTextStyles.dmSans(size: 10.5, color: textThemeColor, weight: FontWeight.w600))),
                          Expanded(flex: 2, child: Text(CurrencyFormatter.format(principal, symbol: '£').split('.').first, style: AppTextStyles.dmSans(size: 10.5, color: textThemeColor))),
                          Expanded(flex: 2, child: Text(CurrencyFormatter.format(interest, symbol: '£').split('.').first, style: AppTextStyles.dmSans(size: 10.5, color: const Color(0xFFC8102E)))),
                          Expanded(flex: 2, child: Text(CurrencyFormatter.format(balance, symbol: '£').split('.').first, style: AppTextStyles.dmSans(size: 10.5, color: isDark ? const Color(0xFF90CAF9) : const Color(0xFF1A1A6B), weight: FontWeight.w800))),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.dmSans(size: 9.5, color: widget.theme.getMutedColor(context))),
      ],
    );
  }

  Widget _milestoneRow(String label, Map<String, dynamic>? data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA))),
          Row(
            children: [
              Text(
                data != null ? 'Year ${data['yr']}' : '—',
                style: AppTextStyles.dmSans(size: 10, color: isDark ? Colors.white70 : const Color(0xFF6366F1)),
              ),
              const SizedBox(width: 12),
              Text(
                data != null ? CurrencyFormatter.format(data['val'], symbol: '£').split('.').first : '—',
                style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: isDark ? const Color(0xFFFFD700) : const Color(0xFF0D0D2B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tabButton({required String label, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF0D0D2B)
              : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F8)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? const Color(0xFF0D0D2B) : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 11.5,
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

  Widget _inputField({required String label, required TextEditingController controller}) {
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F8),
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

class AmortizationChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> yearlyData;
  final double loan;
  final bool isDark;

  AmortizationChartPainter({
    required this.yearlyData,
    required this.loan,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (yearlyData.isEmpty) return;

    const double padLeft = 40.0;
    const double padBottom = 20.0;
    const double padTop = 10.0;
    const double padRight = 10.0;

    final cw = size.width - padLeft - padRight;
    final ch = size.height - padTop - padBottom;

    final maxVal = loan;

    // Draw gridlines
    final gridPaint = Paint()
      ..color = isDark ? Colors.white12 : const Color(0xFFF0F0F5)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = padTop + ch - (ch * i / 4);
      canvas.drawLine(Offset(padLeft, y), Offset(size.width - padRight, y), gridPaint);
    }

    // Draw Balance Line (Outstanding balance)
    final balPath = Path();
    final prinPath = Path();
    final intPath = Path();

    double cumPrin = 0;
    double cumInt = 0;

    for (int i = 0; i < yearlyData.length; i++) {
      final d = yearlyData[i];
      final double x = padLeft + (i / (yearlyData.length - 1)) * cw;

      final double balVal = d['balance'] as double;
      final double yBal = padTop + ch * (1 - balVal / maxVal);
      if (i == 0) {
        balPath.moveTo(x, yBal);
      } else {
        balPath.lineTo(x, yBal);
      }

      cumPrin += d['principal'] as double;
      final double yPrin = padTop + ch * (1 - cumPrin / maxVal);
      if (i == 0) {
        prinPath.moveTo(x, yPrin);
      } else {
        prinPath.lineTo(x, yPrin);
      }

      cumInt += d['interest'] as double;
      final double yInt = padTop + ch * (1 - math.min(cumInt, maxVal) / maxVal);
      if (i == 0) {
        intPath.moveTo(x, yInt);
      } else {
        intPath.lineTo(x, yInt);
      }
    }

    // Paint Balance Line
    canvas.drawPath(
      balPath,
      Paint()
        ..color = isDark ? Colors.white : const Color(0xFF0D0D2B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Paint Principal Line
    canvas.drawPath(
      prinPath,
      Paint()
        ..color = const Color(0xFF059669)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Paint Interest Line (dashed-like)
    canvas.drawPath(
      intPath,
      Paint()
        ..color = const Color(0xFFC8102E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant AmortizationChartPainter oldDelegate) {
    return oldDelegate.yearlyData != yearlyData || oldDelegate.loan != loan || oldDelegate.isDark != isDark;
  }
}
