// lib/features/australia/tools/au_mortgage_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class AUMortgageCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const AUMortgageCalc({super.key, this.theme = CountryThemes.australia});

  @override
  ConsumerState<AUMortgageCalc> createState() => _AUMortgageCalcState();
}

class _AUMortgageCalcState extends ConsumerState<AUMortgageCalc> {
  double _propVal = 750000;
  double _deposit = 75000;
  double _rate = 6.09;
  int _termYears = 30;
  double _offsetBal = 0;
  String _loanType = 'PI'; // 'PI' or 'IO'

  bool _showResults = false;

  void _reset() {
    setState(() {
      _propVal = 750000;
      _deposit = 75000;
      _rate = 6.09;
      _termYears = 30;
      _offsetBal = 0;
      _loanType = 'PI';
      _showResults = false;
    });
  }

  // LMI estimate (Genworth/QBE sliding scale approximation)
  double _calcLMI(double loanAmt, double propVal) {
    final lvr = loanAmt / propVal;
    if (lvr <= 0.80) return 0;
    double rate;
    if (lvr <= 0.85) {
      rate = 0.0077;
    } else if (lvr <= 0.90) {
      rate = 0.0196;
    } else if (lvr <= 0.95) {
      rate = 0.0384;
    } else {
      rate = 0.0486;
    }
    return loanAmt * rate;
  }

  void _saveCalculation() async {
    final loanAmt = _propVal - _deposit;
    if (loanAmt <= 0) return;

    final effectiveLoan = max(0.0, loanAmt - _offsetBal);
    final lvr = (loanAmt / _propVal) * 100;
    final monthlyRate = _rate / 100 / 12;
    final n = _termYears * 12;

    double monthly;
    double totalInterest;
    double totalPaid;

    if (_loanType == 'PI') {
      if (monthlyRate == 0) {
        monthly = effectiveLoan / n;
      } else {
        monthly = effectiveLoan *
            (monthlyRate * pow(1 + monthlyRate, n)) /
            (pow(1 + monthlyRate, n) - 1);
      }
      totalPaid = monthly * n;
      totalInterest = totalPaid - effectiveLoan;
    } else {
      monthly = effectiveLoan * monthlyRate;
      totalInterest = monthly * n;
      totalPaid = loanAmt + totalInterest;
    }

    final lmi = _calcLMI(loanAmt, _propVal);

    // Prompt user for label
    final labelCtrl = TextEditingController(text: 'Bondi Beach Property');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/au_mortgage_calc/save'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Calculation',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Saving: ${CurrencyFormatter.compact(loanAmt, symbol: 'AU\$')} loan @ $_rate% → ${CurrencyFormatter.compact(monthly, symbol: 'AU\$')}/mo',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Dream Home - Bondi)',
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
              backgroundColor: const Color(0xFF002868),
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
          : 'Mortgage Calc';
      final calc = SavedCalc.create(
        country: 'Australia',
        calcType: 'Mortgage Calc',
        inputs: {
          'propertyValue': _propVal,
          'deposit': _deposit,
          'rate': _rate,
          'termYears': _termYears.toDouble(),
          'offsetBal': _offsetBal,
          'loanType': _loanType == 'PI' ? 0.0 : 1.0,
        },
        results: {
          'monthly': monthly,
          'totalInterest': totalInterest,
          'totalRepaid': totalPaid,
          'lvr': lvr,
          'lmi': lmi,
        },
        label: label,
        currencyCode: 'AUD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Calculation saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF002868),
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

    // Calculations
    final loanAmt = _propVal - _deposit;
    final effectiveLoan = max(0.0, loanAmt - _offsetBal);
    final lvr = _propVal > 0 ? (loanAmt / _propVal) * 100 : 0.0;
    final monthlyRate = _rate / 100 / 12;
    final n = _termYears * 12;

    double monthly;
    double totalInterest;
    double totalPaid;

    if (_loanType == 'PI') {
      if (monthlyRate == 0) {
        monthly = effectiveLoan / n;
      } else {
        monthly = effectiveLoan *
            (monthlyRate * pow(1 + monthlyRate, n)) /
            (pow(1 + monthlyRate, n) - 1);
      }
      totalPaid = monthly * n;
      totalInterest = totalPaid - effectiveLoan;
    } else {
      monthly = effectiveLoan * monthlyRate;
      totalInterest = monthly * n;
      totalPaid = loanAmt + totalInterest;
    }

    final lmi = _calcLMI(loanAmt, _propVal);
    final offsetSaving = _offsetBal > 0 ? _offsetBal * monthlyRate : 0.0;

    // Donut chart percentages
    final donutTotal = loanAmt + totalInterest + lmi;
    final principalPct = donutTotal > 0 ? loanAmt / donutTotal : 0.0;
    final interestPct = donutTotal > 0 ? totalInterest / donutTotal : 0.0;
    final lmiPct = donutTotal > 0 ? lmi / donutTotal : 0.0;

    // Amortization 10-year preview
    final List<_AmortYear> amortPreview = [];
    double currentBal = effectiveLoan;
    for (int y = 1; y <= min(_termYears, 10); y++) {
      double yearPrincipal = 0;
      double yearInterest = 0;
      for (int m = 0; m < 12; m++) {
        if (currentBal <= 0) break;
        final intCharge = currentBal * monthlyRate;
        final mPay = _loanType == 'PI' ? monthly : currentBal * monthlyRate;
        final prinPay = _loanType == 'PI' ? mPay - intCharge : 0.0;
        yearInterest += intCharge;
        yearPrincipal += prinPay;
        currentBal -= prinPay;
      }
      amortPreview.add(_AmortYear(y, yearPrincipal, yearInterest));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF140800), Color(0xFF7C2D12)],
            ),
            borderRadius: BorderRadius.circular(20),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Australian Mortgage Calculator',
                      style: AppTextStyles.dmSans(
                          size: 10,
                          color: Colors.white54,
                          weight: FontWeight.w600)),
                  GestureDetector(
                    onTap: _reset,
                    child: Text('Reset ↺',
                        style: AppTextStyles.dmSans(
                            size: 11,
                            color: const Color(0xFFFFD700),
                            weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Calculate with LMI & Offset',
                  style: AppTextStyles.playfair(
                      size: 18, color: Colors.white, weight: FontWeight.w800)),
              const SizedBox(height: 16),

              // Inputs Grid
              Row(
                children: [
                  Expanded(
                    child: _buildInputBox(
                      label: 'Property Value',
                      prefix: 'AUD \$',
                      value: _propVal,
                      onChanged: (val) => setState(() => _propVal = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputBox(
                      label: 'Deposit',
                      prefix: 'AUD \$',
                      value: _deposit,
                      onChanged: (val) => setState(() => _deposit = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildInputBox(
                      label: 'Interest Rate %',
                      prefix: '',
                      value: _rate,
                      isPercent: true,
                      onChanged: (val) => setState(() => _rate = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputBox(
                      label: 'Loan Term (yrs)',
                      prefix: '',
                      value: _termYears.toDouble(),
                      isInteger: true,
                      onChanged: (val) =>
                          setState(() => _termYears = val.toInt()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              _buildInputBox(
                label: 'Offset Account Balance (optional)',
                prefix: 'AUD \$',
                value: _offsetBal,
                onChanged: (val) => setState(() => _offsetBal = val),
              ),
              const SizedBox(height: 14),

              // Toggle Row
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildToggleButton(
                          'Principal & Interest', _loanType == 'PI', () {
                        setState(() => _loanType = 'PI');
                      }),
                    ),
                    Expanded(
                      child: _buildToggleButton(
                          'Interest Only', _loanType == 'IO', () {
                        setState(() => _loanType = 'IO');
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Calculate Button
              ElevatedButton(
                onPressed: () {
                  if (loanAmt <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Deposit must be less than property value',
                              style: AppTextStyles.dmSans())),
                    );
                    return;
                  }
                  setState(() => _showResults = true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF002868),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 44),
                  elevation: 4,
                ),
                child: Text('🏠 Calculate Mortgage',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Results',
                  style: AppTextStyles.playfair(
                      size: 15, color: theme.getTextColor(context))),
              GestureDetector(
                onTap: _saveCalculation,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white,
                    border: Border.all(color: theme.getBorderColor(context)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('💾 Save',
                      style: AppTextStyles.dmSans(
                          size: 11,
                          color: isDark
                              ? const Color(0xFFFFD700)
                              : theme.primaryColor,
                          weight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Monthly Repayment Hero
          Container(
            padding: const EdgeInsets.all(20),
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
              children: [
                Text('Monthly Repayment',
                    style: AppTextStyles.dmSans(
                        size: 11,
                        color: theme.getMutedColor(context),
                        weight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(CurrencyFormatter.format(monthly, currencyCode: 'AUD'),
                    style: AppTextStyles.playfair(
                        size: 42,
                        color: theme.getTextColor(context),
                        weight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  '${_loanType == 'PI' ? 'Principal & Interest' : 'Interest Only'} · $_termYears years @ $_rate%',
                  style: AppTextStyles.dmSans(
                      size: 10, color: theme.getMutedColor(context)),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                _buildRepayRow('Fortnightly repayment', monthly / 2, theme),
                const SizedBox(height: 6),
                _buildRepayRow('Weekly repayment', monthly / 4.333, theme),
                const SizedBox(height: 16),

                // Grid Summary
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _buildSummaryBox(
                        'Loan Amount',
                        CurrencyFormatter.format(loanAmt, currencyCode: 'AUD'),
                        Colors.blue),
                    _buildSummaryBox('LVR', '${lvr.toStringAsFixed(1)}%',
                        lvr > 80 ? Colors.red : Colors.green),
                    _buildSummaryBox(
                        'Total Interest',
                        CurrencyFormatter.format(totalInterest,
                            currencyCode: 'AUD'),
                        Colors.red),
                    _buildSummaryBox(
                        'Total Repaid',
                        CurrencyFormatter.format(totalPaid,
                            currencyCode: 'AUD'),
                        Colors.black),
                    _buildSummaryBox(
                        'LMI Est.',
                        lmi > 0
                            ? CurrencyFormatter.format(lmi, currencyCode: 'AUD')
                            : '\$0 (LVR ≤ 80%)',
                        Colors.red),
                    _buildSummaryBox(
                        'Offset Saving',
                        offsetSaving > 0
                            ? '${CurrencyFormatter.format(offsetSaving, currencyCode: 'AUD')}/mo'
                            : '\$0/mo',
                        Colors.green),
                  ],
                ),
              ],
            ),
          ),

          // Donut Chart
          const SizedBox(height: 20),
          Text('Loan Breakdown',
              style: AppTextStyles.playfair(
                  size: 15, color: theme.getTextColor(context))),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CustomPaint(
                    painter: _DonutChartPainter(
                      principalPct: principalPct,
                      interestPct: interestPct,
                      lmiPct: lmiPct,
                      isDark: isDark,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      _buildLegendRow('Principal', loanAmt, principalPct,
                          const Color(0xFF002868)),
                      const SizedBox(height: 8),
                      _buildLegendRow('Total Interest', totalInterest,
                          interestPct, const Color(0xFFEA580C)),
                      if (lmi > 0) ...[
                        const SizedBox(height: 8),
                        _buildLegendRow(
                            'LMI', lmi, lmiPct, const Color(0xFFFFD700)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Amortization Bar Chart
          const SizedBox(height: 20),
          Text('Principal vs Interest by Year',
              style: AppTextStyles.playfair(
                  size: 15, color: theme.getTextColor(context))),
          const SizedBox(height: 10),
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
                Text('Amortisation Snapshot (First 10 years)',
                    style: AppTextStyles.dmSans(
                        size: 12,
                        weight: FontWeight.w700,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 14),
                ...amortPreview.map((ay) {
                  final total = ay.principal + ay.interest;
                  final pPct = total > 0 ? ay.principal / total : 0.0;
                  final iPct = total > 0 ? ay.interest / total : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Text('Yr ${ay.year}',
                              style: AppTextStyles.dmSans(
                                  size: 10,
                                  color: theme.getMutedColor(context),
                                  weight: FontWeight.w700)),
                        ),
                        Expanded(
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : const Color(0xFFFFF8F0),
                                borderRadius: BorderRadius.circular(4)),
                            child: Row(
                              children: [
                                if (pPct > 0)
                                  Flexible(
                                    flex: (pPct * 100).toInt(),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF002868),
                                        borderRadius: BorderRadius.horizontal(
                                            left: Radius.circular(4)),
                                      ),
                                    ),
                                  ),
                                if (iPct > 0)
                                  Flexible(
                                    flex: (iPct * 100).toInt(),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEA580C),
                                        borderRadius: BorderRadius.horizontal(
                                            right: Radius.circular(4)),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 70,
                          child: Text(
                            CurrencyFormatter.compact(total, symbol: 'AU\$'),
                            style: AppTextStyles.dmSans(
                                size: 10,
                                weight: FontWeight.w700,
                                color: theme.getTextColor(context)),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildDotIndicator(
                        'Principal', const Color(0xFF002868), theme),
                    const SizedBox(width: 14),
                    _buildDotIndicator(
                        'Interest', const Color(0xFFEA580C), theme),
                  ],
                ),
              ],
            ),
          ),
        ],

        // Guide Cards

        // Guide Cards
        const SizedBox(height: 20),
        Text('Mortgage Tips',
            style: AppTextStyles.playfair(
                size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF7C2D12).withValues(alpha: 0.2),
                      const Color(0xFF7C2D12).withValues(alpha: 0.1)
                    ]
                  : const [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
            ),
            border: Border.all(
                color:
                    isDark ? const Color(0xFFEA580C) : const Color(0xFFFCA5A5)),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🇦🇺 Australian Mortgage Guide',
                  style: AppTextStyles.dmSans(
                      size: 13,
                      weight: FontWeight.w800,
                      color: isDark
                          ? const Color(0xFFFFD700)
                          : const Color(0xFF7C2D12))),
              const SizedBox(height: 12),
              _buildTipRow('1',
                  'The RBA cut the cash rate to 4.10% in May 2026. Variable rates typically price 1.75–2.25% above the cash rate.'),
              _buildTipRow('2',
                  'LMI is required when your deposit is below 20% (LVR > 80%). It protects the lender, not you.'),
              _buildTipRow('3',
                  'An offset account reduces the interest charged — every dollar in offset equals a dollar less of loan balance for interest calculation.'),
              _buildTipRow('4',
                  'Making fortnightly repayments (half monthly) means you effectively make 13 monthly payments per year instead of 12.'),
            ],
          ),
        ),
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
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 8.5, color: Colors.white54, weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (prefix.isNotEmpty)
                Text('$prefix ',
                    style: AppTextStyles.dmSans(
                        size: 11,
                        color: Colors.white54,
                        weight: FontWeight.w700)),
              Expanded(
                child: TextFormField(
                  initialValue:
                      isInteger ? value.toInt().toString() : value.toString(),
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.playfair(
                      size: 15, color: Colors.white, weight: FontWeight.w800),
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
                        color: Colors.white54,
                        weight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFFD700) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w700,
            color: active ? const Color(0xFF1A0A00) : Colors.white60,
          ),
        ),
      ),
    );
  }

  Widget _buildRepayRow(String label, double val, CountryTheme theme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.dmSans(
                size: 11, color: theme.getMutedColor(context))),
        Text(CurrencyFormatter.format(val, currencyCode: 'AUD'),
            style: AppTextStyles.playfair(
                size: 16,
                color: isDark ? const Color(0xFFFFD700) : theme.primaryColor,
                weight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildSummaryBox(String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color displayColor = color;
    if (isDark) {
      if (color == Colors.black) {
        displayColor = Colors.white;
      } else if (color == Colors.blue) {
        displayColor = const Color(0xFF60A5FA);
      } else if (color == Colors.green) {
        displayColor = const Color(0xFF34D399);
      } else if (color == Colors.red) {
        displayColor = const Color(0xFFFCA5A5);
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 8.5,
                  color: isDark ? Colors.white70 : const Color(0xFF92400E),
                  weight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.playfair(
                  size: 14, color: displayColor, weight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String label, double val, double pct, Color color) {
    final theme = widget.theme;
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: AppTextStyles.dmSans(
                  size: 11,
                  color: theme.getMutedColor(context),
                  weight: FontWeight.w600)),
        ),
        Text(
          '${CurrencyFormatter.compact(val, symbol: 'AU\$')} (${(pct * 100).toStringAsFixed(1)}%)',
          style: AppTextStyles.dmSans(
              size: 11,
              color: theme.getTextColor(context),
              weight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildDotIndicator(String label, Color color, CountryTheme theme) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label,
            style: AppTextStyles.dmSans(
                size: 10,
                color: theme.getMutedColor(context),
                weight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildTipRow(String bullet, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
                color: Color(0xFFEA580C), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(bullet,
                style: AppTextStyles.dmSans(
                    size: 9, color: Colors.white, weight: FontWeight.w900)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: AppTextStyles.dmSans(
                    size: 10.5, color: const Color(0xFF92400E), height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _AmortYear {
  final int year;
  final double principal;
  final double interest;
  const _AmortYear(this.year, this.principal, this.interest);
}

class _DonutChartPainter extends CustomPainter {
  final double principalPct;
  final double interestPct;
  final double lmiPct;
  final bool isDark;

  _DonutChartPainter({
    required this.principalPct,
    required this.interestPct,
    required this.lmiPct,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    const strokeWidth = 14.0;

    final paintBg = Paint()
      ..color =
          isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFFFF8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, paintBg);

    double startAngle = -pi / 2;

    // Draw Principal Segment
    if (principalPct > 0) {
      final sweepAngle = principalPct * 2 * pi;
      final paintP = Paint()
        ..color = const Color(0xFF002868)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startAngle, sweepAngle, false, paintP);
      startAngle += sweepAngle;
    }

    // Draw Interest Segment
    if (interestPct > 0) {
      final sweepAngle = interestPct * 2 * pi;
      final paintI = Paint()
        ..color = const Color(0xFFEA580C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startAngle, sweepAngle, false, paintI);
      startAngle += sweepAngle;
    }

    // Draw LMI Segment
    if (lmiPct > 0) {
      final sweepAngle = lmiPct * 2 * pi;
      final paintL = Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startAngle, sweepAngle, false, paintL);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) =>
      oldDelegate.principalPct != principalPct ||
      oldDelegate.interestPct != interestPct ||
      oldDelegate.lmiPct != lmiPct ||
      oldDelegate.isDark != isDark;
}
