// lib/features/newzealand/tools/nz_extra_repayments.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZExtraRepayments extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZExtraRepayments({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZExtraRepayments> createState() => _NZExtraRepaymentsState();
}

class _NZExtraRepaymentsState extends ConsumerState<NZExtraRepayments> {
  double _balance = 650000;
  double _rate = 6.59;
  int _termYears = 25;
  double _extraAmt = 500;
  String _extraFreq = 'monthly'; // 'weekly', 'fortnightly', 'monthly', 'lump'

  bool _showResults = false;

  void _reset() {
    setState(() {
      _balance = 650000;
      _rate = 6.59;
      _termYears = 25;
      _extraAmt = 500;
      _extraFreq = 'monthly';
      _showResults = false;
    });
  }

  double _calcMonthly(double P, double annualRate, int months) {
    final r = annualRate / 100 / 12;
    if (r == 0) return P / months;
    return P * r * pow(1 + r, months) / (pow(1 + r, months) - 1);
  }

  void _saveCalculation(double savedVal, int monthsSaved, double newPmt,
      double totalIntSavedPct) async {
    final labelCtrl = TextEditingController(text: 'NZ Extra Pay Plan');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/nz_extra_repayments'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Repayment Plan',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Saving: Extra repayments plan of ${CurrencyFormatter.compact(_extraAmt, symbol: "NZ\$")} $_extraFreq',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Accelerated Payoff)',
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
              backgroundColor: const Color(0xFF1A6B4A),
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
          : 'Extra Repayments';
      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'Extra Repayments',
        inputs: {
          'balance': _balance,
          'rate': _rate,
          'term': _termYears.toDouble(),
          'extraAmount': _extraAmt,
          'frequency': _extraFreq == 'weekly'
              ? 0.0
              : _extraFreq == 'fortnightly'
                  ? 1.0
                  : _extraFreq == 'monthly'
                      ? 2.0
                      : 3.0,
        },
        results: {
          'interestSaved': savedVal,
          'monthsSaved': monthsSaved.toDouble(),
          'newMonthlyPayment': newPmt,
          'interestSavedPct': totalIntSavedPct,
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Repayment plan saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF1A6B4A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    // Calculations
    final termMonths = _termYears * 12;
    double extraMonthly = 0;
    if (_extraFreq == 'weekly') {
      extraMonthly = _extraAmt * 52 / 12;
    } else if (_extraFreq == 'fortnightly') {
      extraMonthly = _extraAmt * 26 / 12;
    } else if (_extraFreq == 'monthly') {
      extraMonthly = _extraAmt;
    } else if (_extraFreq == 'lump') {
      extraMonthly = _extraAmt / termMonths;
    }

    final origMonthly = _calcMonthly(_balance, _rate, termMonths);
    final origInterest = origMonthly * termMonths - _balance;

    // Simulating amortization with extra payments
    double bal = _balance;
    double totInt = 0;
    int months = 0;
    final r = _rate / 100 / 12;

    while (bal > 0.01 && months < termMonths * 2) {
      final intCharge = bal * r;
      final principal = min(origMonthly + extraMonthly - intCharge, bal);
      totInt += intCharge;
      bal -= principal;
      months++;
    }

    final saved = max(0.0, origInterest - totInt);
    final monthsSaved = termMonths - months;
    final pct = origInterest > 0 ? (saved / origInterest * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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
                  Text('Extra Repayments Details',
                      style: AppTextStyles.dmSans(
                          size: 10,
                          color: theme.getMutedColor(context),
                          weight: FontWeight.w600)),
                  GestureDetector(
                    onTap: _reset,
                    child: Text('Reset ↺',
                        style: AppTextStyles.dmSans(
                            size: 11,
                            color: const Color(0xFFC0392B),
                            weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Accelerate Your Payoff',
                  style: AppTextStyles.playfair(
                      size: 18,
                      color: theme.getTextColor(context),
                      weight: FontWeight.w800)),
              const SizedBox(height: 16),

              // Inputs Row
              Row(
                children: [
                  Expanded(
                    child: _buildInputBox(
                      label: 'Loan Balance',
                      prefix: 'NZD \$',
                      value: _balance,
                      onChanged: (val) => setState(() => _balance = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputBox(
                      label: 'Interest Rate %',
                      prefix: '',
                      value: _rate,
                      isPercent: true,
                      onChanged: (val) => setState(() => _rate = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildInputBox(
                      label: 'Remaining Term (yrs)',
                      prefix: '',
                      value: _termYears.toDouble(),
                      isInteger: true,
                      onChanged: (val) =>
                          setState(() => _termYears = val.toInt()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputBox(
                      label: 'Extra Repayment Amount',
                      prefix: 'NZD \$',
                      value: _extraAmt,
                      onChanged: (val) => setState(() => _extraAmt = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Extra Repayment Frequency',
                      style: AppTextStyles.dmSans(
                          size: 8.5,
                          color: theme.getMutedColor(context),
                          weight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF5F2),
                      border: Border.all(color: const Color(0x150D3B2E)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _extraFreq,
                        isDense: true,
                        dropdownColor: theme.getCardColor(context),
                        style: AppTextStyles.dmSans(
                            size: 13,
                            color: const Color(0xFF0A0F0D),
                            weight: FontWeight.w700),
                        items: const [
                          DropdownMenuItem(
                              value: 'weekly', child: Text('Weekly')),
                          DropdownMenuItem(
                              value: 'fortnightly', child: Text('Fortnightly')),
                          DropdownMenuItem(
                              value: 'monthly', child: Text('Monthly')),
                          DropdownMenuItem(
                              value: 'lump',
                              child: Text('One-off Lump Sum (avg/yr)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _extraFreq = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              // Calculate Button
              ElevatedButton(
                onPressed: () {
                  if (_balance <= 0) return;
                  setState(() => _showResults = true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A6B4A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text('📉 Calculate Interest Savings',
                    style: AppTextStyles.dmSans(
                        size: 14,
                        color: Colors.white,
                        weight: FontWeight.w800)),
              ),
            ],
          ),
        ),

        // Results Section
        if (_showResults) ...[
          const SizedBox(height: 20),
          Text('Interest Savings Results',
              style: AppTextStyles.playfair(
                  size: 15, color: theme.getTextColor(context))),
          const SizedBox(height: 10),

          // Hero Save Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A0F0D), Color(0xFF0D3B2E)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Interest Saved · NZD',
                    style:
                        AppTextStyles.dmSans(size: 9.5, color: Colors.white54)),
                const SizedBox(height: 4),
                Text(CurrencyFormatter.format(saved, currencyCode: 'NZD'),
                    style: AppTextStyles.playfair(
                        size: 32,
                        color: const Color(0xFFF5D060),
                        weight: FontWeight.w800)),
                Text(
                  'Saves ${_formatPeriod(monthsSaved)} off your loan',
                  style: AppTextStyles.dmSans(size: 11, color: Colors.white70),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  childAspectRatio: 1.4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    _buildHeroBox('New Payoff', _formatPeriod(months)),
                    _buildHeroBox(
                        'Monthly Save',
                        CurrencyFormatter.compact(saved / _termYears,
                            symbol: 'NZ\$')),
                    _buildHeroBox(
                        'Total Savings', '${pct.toStringAsFixed(0)}% less'),
                  ],
                ),
              ],
            ),
          ),

          // Progress Ring Segment
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: CustomPaint(
                    painter: _NZExtraProgressRingPainter(pct: pct / 100.0),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Interest Reduction',
                          style: AppTextStyles.dmSans(
                              size: 13,
                              weight: FontWeight.w800,
                              color: theme.getTextColor(context))),
                      const SizedBox(height: 4),
                      Text(
                        'Your extra repayments eliminate ${pct.toStringAsFixed(0)}% of total interest — a guaranteed ${_rate.toStringAsFixed(2)}% return on every dollar.',
                        style: AppTextStyles.dmSans(
                            size: 9.5, color: theme.getMutedColor(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bar chart comparison
          const SizedBox(height: 20),
          Text('Repayment Comparison',
              style: AppTextStyles.playfair(
                  size: 15, color: theme.getTextColor(context))),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Loan Duration & Interest Cost',
                    style: AppTextStyles.dmSans(
                        size: 11,
                        weight: FontWeight.w800,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 14),

                // Interest Cost row
                _buildBarCompareRow('Interest Cost', origInterest, totInt,
                    (v) => CurrencyFormatter.compact(v, symbol: 'NZ\$'), theme),
                const SizedBox(height: 14),
                // Duration row
                _buildBarCompareRow('Loan Duration', termMonths.toDouble(),
                    months.toDouble(), (v) => _formatPeriod(v.toInt()), theme),

                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildDot('Original Loan', const Color(0xFF0D3B2E), theme),
                    const SizedBox(width: 14),
                    _buildDot('With Extra Repayments', const Color(0xFF0D9488),
                        theme),
                  ],
                ),
              ],
            ),
          ),

          // Savings boxes
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.45,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _buildSavingsBox('📅', 'Years Shorter',
                  _formatPeriod(monthsSaved), 'Loan term cut', theme),
              _buildSavingsBox(
                  '💰',
                  'Interest Saved',
                  CurrencyFormatter.compact(saved, symbol: 'NZ\$'),
                  'Total NZD',
                  theme),
              _buildSavingsBox(
                  '🏦',
                  'New Monthly',
                  CurrencyFormatter.compact(origMonthly + extraMonthly,
                      symbol: 'NZ\$'),
                  'P&I payment',
                  theme),
              _buildSavingsBox('📈', 'ROI of Extra',
                  '${_rate.toStringAsFixed(2)}%', 'Guaranteed return', theme),
            ],
          ),

          // Save report
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💾 Save this comparison',
                        style: AppTextStyles.dmSans(
                            size: 11,
                            weight: FontWeight.w800,
                            color: theme.getTextColor(context))),
                    Text('Accelerated payoff saved to portfolio',
                        style: AppTextStyles.dmSans(
                            size: 9, color: theme.getMutedColor(context))),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => _saveCalculation(
                      saved, monthsSaved, origMonthly + extraMonthly, pct),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Save',
                      style: AppTextStyles.dmSans(
                          size: 11,
                          color: Colors.white,
                          weight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInputBox({
    required String label,
    required String prefix,
    required double value,
    bool isPercent = false,
    bool isInteger = false,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF5F2),
        border: Border.all(color: const Color(0x150D3B2E)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 8.5,
                  color: const Color(0xFF4A6358),
                  weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (prefix.isNotEmpty)
                Text('$prefix ',
                    style: AppTextStyles.dmSans(
                        size: 11,
                        color: const Color(0xFF4A6358),
                        weight: FontWeight.w700)),
              Expanded(
                child: TextFormField(
                  initialValue:
                      isInteger ? value.toInt().toString() : value.toString(),
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.playfair(
                      size: 15,
                      color: const Color(0xFF0A0F0D),
                      weight: FontWeight.w800),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  onChanged: (val) {
                    final d = double.tryParse(val) ?? 0.0;
                    onChanged(d);
                  },
                ),
              ),
              if (isPercent)
                Text('%',
                    style: AppTextStyles.dmSans(
                        size: 11,
                        color: const Color(0xFF4A6358),
                        weight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(size: 8, color: Colors.white54)),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.dmSans(
                  size: 11.5, weight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildDot(String label, Color color, CountryTheme theme) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text(label,
            style: AppTextStyles.dmSans(
                size: 9.5, color: theme.getMutedColor(context))),
      ],
    );
  }

  Widget _buildBarCompareRow(String title, double origVal, double extraVal,
      String Function(double) formatter, CountryTheme theme) {
    final maxVal = max(origVal, extraVal);
    final origWidthPct = maxVal > 0 ? origVal / maxVal : 0.0;
    final extraWidthPct = maxVal > 0 ? extraVal / maxVal : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: AppTextStyles.dmSans(
                size: 10,
                weight: FontWeight.w700,
                color: theme.getTextColor(context))),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, c) {
                      return Row(
                        children: [
                          Container(
                            height: 18,
                            width: max(0.0, c.maxWidth * origWidthPct),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFF0D3B2E),
                                Color(0xFF1A6B4A)
                              ]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.only(left: 10),
                            alignment: Alignment.centerLeft,
                            child: Text(formatter(origVal),
                                style: AppTextStyles.dmSans(
                                    size: 8.5,
                                    color: Colors.white,
                                    weight: FontWeight.w800)),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  LayoutBuilder(
                    builder: (context, c) {
                      return Row(
                        children: [
                          Container(
                            height: 18,
                            width: max(0.0, c.maxWidth * extraWidthPct),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFF0D9488),
                                Color(0xFF0EA5E9)
                              ]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.only(left: 10),
                            alignment: Alignment.centerLeft,
                            child: Text(formatter(extraVal),
                                style: AppTextStyles.dmSans(
                                    size: 8.5,
                                    color: Colors.white,
                                    weight: FontWeight.w800)),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSavingsBox(
      String icon, String label, String val, String sub, CountryTheme theme) {
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
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 9,
                  color: theme.getMutedColor(context),
                  weight: FontWeight.w700)),
          Text(val,
              style: AppTextStyles.dmSans(
                  size: 13.5,
                  color: theme.getTextColor(context),
                  weight: FontWeight.w800)),
          Text(sub,
              style: AppTextStyles.dmSans(
                  size: 9, color: theme.getMutedColor(context))),
        ],
      ),
    );
  }

  String _formatPeriod(int monthsVal) {
    final y = monthsVal ~/ 12;
    final m = monthsVal % 12;
    if (y > 0) {
      return '${y}yr ${m > 0 ? "$m mo" : ""}';
    }
    return '$m months';
  }
}

class _NZExtraProgressRingPainter extends CustomPainter {
  final double pct;
  _NZExtraProgressRingPainter({required this.pct});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 6;
    const strokeWidth = 8.0;

    final paintBg = Paint()
      ..color = const Color(0xFFEDF5F2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, paintBg);

    final Paint paintActive = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0D9488), Color(0xFF1A6B4A)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = pct.clamp(0.0, 1.0) * 2 * pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      paintActive,
    );

    // Center text
    final textPainterPct = TextPainter(
      text: TextSpan(
          text: '${(pct * 100).toStringAsFixed(0)}%',
          style: const TextStyle(
              color: Color(0xFF0A0F0D),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'Palatino')),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainterPct.paint(canvas, center - Offset(textPainterPct.width / 2, 9));

    final textPainterSaved = TextPainter(
      text: const TextSpan(
          text: 'Saved',
          style:
              TextStyle(color: Colors.grey, fontSize: 8, fontFamily: 'Arial')),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainterSaved.paint(
        canvas, center - Offset(textPainterSaved.width / 2, -5));
  }

  @override
  bool shouldRepaint(covariant _NZExtraProgressRingPainter oldDelegate) =>
      oldDelegate.pct != pct;
}
