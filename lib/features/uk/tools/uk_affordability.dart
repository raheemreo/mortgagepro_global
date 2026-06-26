// lib/features/uk/tools/uk_affordability.dart

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

class UKAffordability extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;
  const UKAffordability({super.key, required this.theme, this.savedCalc});

  @override
  ConsumerState<UKAffordability> createState() => _UKAffordabilityState();
}

class _UKAffordabilityState extends ConsumerState<UKAffordability> {
  String _appType = 'solo'; // solo, joint

  final _sal1Controller = TextEditingController(text: '55000');
  final _sal2Controller = TextEditingController(text: '35000');
  final _otherIncController = TextEditingController(text: '0');
  final _debtController = TextEditingController(text: '200');
  final _livingController = TextEditingController(text: '1500');
  final _depositController = TextEditingController(text: '50000');
  final _rateController = TextEditingController(text: '4.75');

  double _sal1 = 55000;
  double _sal2 = 35000;
  double _otherInc = 0;
  double _debt = 200;
  double _living = 1500;
  double _deposit = 50000;
  double _rate = 4.75;

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _sal1Controller.text = (inputs['sal1'] ?? 55000.0).toStringAsFixed(0);
      final double s2 = inputs['sal2'] ?? 0.0;
      _sal2Controller.text = s2.toStringAsFixed(0);
      _otherIncController.text = (inputs['otherInc'] ?? 0.0).toStringAsFixed(0);
      _debtController.text = (inputs['debt'] ?? 200.0).toStringAsFixed(0);
      _livingController.text = (inputs['living'] ?? 1500.0).toStringAsFixed(0);
      _depositController.text = (inputs['deposit'] ?? 50000.0).toStringAsFixed(0);
      _rateController.text = (inputs['rate'] ?? 4.75).toString();
      _appType = s2 > 0.0 ? 'joint' : 'solo';
    }
    _calculateValues();
  }

  @override
  void dispose() {
    _sal1Controller.dispose();
    _sal2Controller.dispose();
    _otherIncController.dispose();
    _debtController.dispose();
    _livingController.dispose();
    _depositController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _calculateValues() {
    setState(() {
      _sal1 = double.tryParse(_sal1Controller.text) ?? 0;
      _sal2 = _appType == 'joint' ? (double.tryParse(_sal2Controller.text) ?? 0) : 0;
      _otherInc = double.tryParse(_otherIncController.text) ?? 0;
      _debt = double.tryParse(_debtController.text) ?? 0;
      _living = double.tryParse(_livingController.text) ?? 0;
      _deposit = double.tryParse(_depositController.text) ?? 0;
      _rate = double.tryParse(_rateController.text) ?? 4.75;
    });
  }

  double _pmt(double r, double n, double pv) {
    if (r == 0) return pv / n;
    return pv * (r * math.pow(1 + r, n)) / (math.pow(1 + r, n) - 1);
  }

  @override
  Widget build(BuildContext context) {
    final s2Val = _appType == 'joint' ? _sal2 : 0.0;
    final totalIncome = _sal1 + s2Val + (_otherInc * 0.6);
    final maxBorrow = totalIncome * 4.5;
    final maxProp = maxBorrow + _deposit;
    final mult = totalIncome > 0 ? (maxBorrow / totalIncome) : 0.0;
    final ltv = maxProp > 0 ? (maxBorrow / maxProp * 100) : 0.0;

    final rMo = _rate / 100 / 12;
    final monthlyPmt = _pmt(rMo, 300, maxBorrow);

    final grossMo = totalIncome / 12;
    final taxMo = grossMo * 0.28;
    final netMo = grossMo - taxMo;
    final remaining = netMo - _debt - _living - monthlyPmt;

    // Stress test calculations
    const stressRate = 8.0;
    final stressPmt = _pmt(stressRate / 100 / 12, 300, maxBorrow);
    final stressMax = netMo - _debt - _living;
    final capacityPct = stressMax > 0 ? (stressPmt / stressMax * 100).clamp(0.0, 100.0) : 100.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = widget.theme.getCardColor(context);
    final textThemeColor = isDark ? Colors.white : const Color(0xFF0D0D2B);
    final borderCol = widget.theme.getBorderColor(context);

    // Live BoE rates
    final ukRates = ref.watch(ukRatesProvider).valueOrNull;
    final boeBase  = ukRates?.boeBase.value  ?? 4.25;
    final fixed2yr = ukRates?.fixed2yr.value ?? 4.75;
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
              Expanded(child: _rateCell('4× Salary', 'Standard', 'Most lenders', textThemeColor)),
              _divider(),
              Expanded(child: _rateCell('4.5× Salary', 'Common', 'Many banks', textThemeColor)),
              _divider(),
              Expanded(child: _rateCell('5× Salary', 'Max', 'High earners', textThemeColor)),
              _divider(),
              Expanded(child: _rateCell('BoE Base', '${boeBase.toStringAsFixed(2)}%${isLive ? ' 🟢' : ''}', '2-Yr: ${fixed2yr.toStringAsFixed(2)}%', Colors.redAccent)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'INCOME DETAILS',
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w700,
            color: widget.theme.getMutedColor(context),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),

        // Income Details Card
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
                'APPLICATION TYPE',
                style: AppTextStyles.dmSans(
                  size: 9,
                  weight: FontWeight.w700,
                  color: widget.theme.getMutedColor(context),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _tabButton(
                      label: '👤 Solo',
                      active: _appType == 'solo',
                      onTap: () => setState(() {
                        _appType = 'solo';
                        _calculateValues();
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _tabButton(
                      label: '👫 Joint',
                      active: _appType == 'joint',
                      onTap: () => setState(() {
                        _appType = 'joint';
                        _calculateValues();
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _inputField(label: 'Annual Salary (Applicant 1) (£)', controller: _sal1Controller),
              if (_appType == 'joint') ...[
                const SizedBox(height: 12),
                _inputField(label: 'Annual Salary (Applicant 2) (£)', controller: _sal2Controller),
              ],
              const SizedBox(height: 12),
              _inputField(label: 'Other Income (bonus, rental, etc.) (£)', controller: _otherIncController),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'COMMITMENTS & DEPOSIT',
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w700,
            color: widget.theme.getMutedColor(context),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),

        // Commitments Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            children: [
              _inputField(label: 'Monthly Debt Payments (£)', controller: _debtController),
              const SizedBox(height: 12),
              _inputField(label: 'Monthly Living Costs (£)', controller: _livingController),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _inputField(label: 'Deposit Available (£)', controller: _depositController)),
                  const SizedBox(width: 10),
                  Expanded(child: _inputField(label: 'Interest Rate (%)', controller: _rateController)),
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
                'MAXIMUM BORROWING',
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
                    CurrencyFormatter.format(maxBorrow, symbol: '£').split('.').first,
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
                        calcType: 'Affordability',
                        inputs: {
                          'sal1': _sal1,
                          'sal2': _sal2,
                          'otherInc': _otherInc,
                          'debt': _debt,
                          'living': _living,
                          'deposit': _deposit,
                          'rate': _rate,
                        },
                        results: {
                          'Max Borrowing': maxBorrow,
                          'Max Property': maxProp,
                          'Monthly Payment': monthlyPmt,
                          'Income Multiple': mult,
                          'LTV Ratio': ltv,
                        },
                        label: '${CurrencyFormatter.compact(maxBorrow, symbol: '£')} max borrow · ${mult.toStringAsFixed(1)}x multiple',
                        currencyCode: 'GBP',
                      );
                      final messenger = ScaffoldMessenger.of(context);
                      await ref.read(savedProvider.notifier).save(calc);
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('✓ Affordability calculation saved'),
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
                'Max property: ${CurrencyFormatter.format(maxProp, symbol: '£').split('.').first} with ${CurrencyFormatter.format(_deposit, symbol: '£').split('.').first} deposit',
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
                  'Income Multiple: ${mult.toStringAsFixed(1)}x · LTV: ${ltv.toStringAsFixed(0)}%',
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
            ResultRow(label: 'Max Property', value: maxProp, currencyCode: 'GBP'),
            ResultRow(label: 'Monthly Payment', value: monthlyPmt, currencyCode: 'GBP'),
            ResultRow(label: 'Income Multiple', value: mult, isPercent: false, isHighlighted: true),
            ResultRow(label: 'LTV Ratio', value: ltv / 100, isPercent: true),
          ],
        ),
        const SizedBox(height: 16),

        // Gauge Chart Card
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
                'Borrowing vs. Stress-Test Capacity',
                style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textThemeColor),
              ),
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: 250,
                  height: 130,
                  child: CustomPaint(
                    painter: AffordabilityGaugePainter(
                      capacityPct: capacityPct,
                      isDark: isDark,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${capacityPct.toInt()}%',
                            style: AppTextStyles.dmSans(size: 24, weight: FontWeight.w800, color: textThemeColor).copyWith(fontFamily: 'Georgia'),
                          ),
                          Text(
                            'of max capacity used',
                            style: AppTextStyles.dmSans(size: 9.5, color: widget.theme.getMutedColor(context)),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Low', style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF059669), weight: FontWeight.w800)),
                  Text('Medium', style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFB45309), weight: FontWeight.w800)),
                  Text('High', style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFC8102E), weight: FontWeight.w800)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Lender Borrowing Bands
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
                'Lender Borrowing Bands',
                style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textThemeColor),
              ),
              const SizedBox(height: 12),
              _bandRow(
                'Conservative (4×)',
                totalIncome * 4,
                isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.25) : const Color(0xFFFEF2F2),
                isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E),
                'Halifax, HSBC (standard)',
              ),
              const SizedBox(height: 8),
              _bandRow(
                'Standard (4.5×)',
                totalIncome * 4.5,
                isDark ? const Color(0xFF1E1B4B).withValues(alpha: 0.35) : const Color(0xFFEEF2FF),
                isDark ? const Color(0xFFC7D2FE) : const Color(0xFF1A1A6B),
                'Nationwide, Barclays',
              ),
              const SizedBox(height: 8),
              _bandRow(
                'Maximum (5×)',
                totalIncome * 5,
                isDark ? const Color(0xFF064E3B).withValues(alpha: 0.25) : const Color(0xFFF0FDF4),
                isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669),
                'Specialist / high earner',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Monthly Budget Check
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
                '💰 Monthly Budget Check',
                style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1E1B4B)),
              ),
              const SizedBox(height: 12),
              _budgetRow('Gross Monthly Income', grossMo, false),
              _budgetRow('Tax & NI (est. 28%)', taxMo, true),
              _budgetRow('Net Monthly Income', netMo, false, isBold: true),
              _budgetRow('Debt Payments', _debt, true),
              _budgetRow('Living Costs', _living, true),
              _budgetRow('Mortgage Payment', monthlyPmt, true),
              Divider(color: isDark ? const Color(0xFF4338CA).withValues(alpha: 0.4) : const Color(0xFFA5B4FC), height: 16),
              _budgetRow('Remaining', remaining.abs(), remaining < 0, isBold: true, labelSuffix: remaining >= 0 ? '' : ' (Over budget)'),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
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
            size: 12,
            weight: FontWeight.w800,
            color: active ? const Color(0xFFFFD700) : widget.theme.getMutedColor(context),
          ),
        ),
      ),
    );
  }

  Widget _bandRow(String label, double val, Color bg, Color textCol, String note) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w700, color: textCol)),
              const SizedBox(height: 2),
              Text(note, style: AppTextStyles.dmSans(size: 9.5, color: textCol.withValues(alpha: 0.7))),
            ],
          ),
          Text(
            CurrencyFormatter.format(val, symbol: '£').split('.').first,
            style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: textCol),
          ),
        ],
      ),
    );
  }

  Widget _budgetRow(String label, double val, bool isNegative, {bool isBold = false, String labelSuffix = ''}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label + labelSuffix,
            style: AppTextStyles.dmSans(
              size: 11,
              weight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: isDark ? const Color(0xFFC7D2FE) : const Color(0xFF4338CA),
            ),
          ),
          Text(
            (isNegative ? '-' : '') + CurrencyFormatter.format(val, symbol: '£').split('.').first,
            style: AppTextStyles.dmSans(
              size: 11,
              weight: isBold ? FontWeight.w800 : FontWeight.w700,
              color: isNegative
                  ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E))
                  : (isDark ? Colors.white : const Color(0xFF0D0D2B)),
            ),
          ),
        ],
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

class AffordabilityGaugePainter extends CustomPainter {
  final double capacityPct;
  final bool isDark;

  AffordabilityGaugePainter({
    required this.capacityPct,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 12;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    // Background semi-circle
    canvas.drawArc(rect, math.pi, math.pi, false, bgPaint);

    const gradient = LinearGradient(
      colors: [Color(0xFF059669), Color(0xFFB45309), Color(0xFFC8102E)],
    );

    final gradientPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    // We draw the arc based on capacityPct
    final sweepAngle = math.pi * (capacityPct / 100);
    if (sweepAngle > 0) {
      canvas.drawArc(rect, math.pi, sweepAngle, false, gradientPaint);
    }
  }

  @override
  bool shouldRepaint(covariant AffordabilityGaugePainter oldDelegate) {
    return oldDelegate.capacityPct != capacityPct || oldDelegate.isDark != isDark;
  }
}
