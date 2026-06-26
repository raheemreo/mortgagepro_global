// lib/features/newzealand/tools/nz_repayment_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZRepaymentCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZRepaymentCalc({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZRepaymentCalc> createState() => _NZRepaymentCalcState();
}

class _NZRepaymentCalcState extends ConsumerState<NZRepaymentCalc> {
  double _loanAmt = 680000;
  double _rate = 6.59;
  int _termYears = 30;
  int _ioPeriod = 5;

  bool _showResults = false;

  void _reset() {
    setState(() {
      _loanAmt = 680000;
      _rate = 6.59;
      _termYears = 30;
      _ioPeriod = 5;
      _showResults = false;
    });
  }

  double _calcPI(double loan, double rate, int years) {
    final r = rate / 100 / 12;
    final n = years * 12;
    if (r == 0) return loan / n;
    return loan * (r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
  }

  double _calcIO(double loan, double rate) {
    return loan * rate / 100 / 12;
  }

  double _getEquityAtYear(
      double loan, double rate, int totalYears, int checkYear) {
    final r = rate / 100 / 12;
    if (r == 0) return loan * checkYear / totalYears;
    final m = _calcPI(loan, rate, totalYears);
    double bal = loan;
    for (int i = 0; i < checkYear * 12; i++) {
      bal = bal * (1 + r) - m;
    }
    return max(0.0, loan - bal);
  }

  void _saveCalculation() async {
    final piMonthly = _calcPI(_loanAmt, _rate, _termYears);
    final ioMonthly = _calcIO(_loanAmt, _rate);
    final piTotal = piMonthly * _termYears * 12;
    final remainTerm = _termYears - _ioPeriod;
    final piAfterIO = _calcPI(_loanAmt, _rate, remainTerm);
    final ioTotal =
        (ioMonthly * _ioPeriod * 12) + (piAfterIO * remainTerm * 12);

    final labelCtrl = TextEditingController(text: 'NZ Repayment Plan');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Comparison',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Saving: ${CurrencyFormatter.compact(_loanAmt, symbol: 'NZ\$')} loan comparison @ $_rate%',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Investment Property)',
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
          : 'Repayment Calc';
      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'Repayment Calc',
        inputs: {
          'loanAmount': _loanAmt,
          'rate': _rate,
          'termYears': _termYears.toDouble(),
          'ioPeriod': _ioPeriod.toDouble(),
        },
        results: {
          'piMonthly': piMonthly,
          'ioMonthly': ioMonthly,
          'piTotalPaid': piTotal,
          'ioTotalPaid': ioTotal,
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Calculation saved!',
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
    final piMonthly = _calcPI(_loanAmt, _rate, _termYears);
    final ioMonthly = _calcIO(_loanAmt, _rate);
    final piTotal = piMonthly * _termYears * 12;
    final piInt = piTotal - _loanAmt;

    final ioTotalInt = ioMonthly * _ioPeriod * 12;
    final remainTerm = _termYears - _ioPeriod;
    final piAfterIO = _calcPI(_loanAmt, _rate, remainTerm);
    final ioTotal = ioTotalInt + (piAfterIO * remainTerm * 12);
    final ioInt = ioTotal - _loanAmt;

    final savings = ioTotal - piTotal;
    final eq5PI =
        _getEquityAtYear(_loanAmt, _rate, _termYears, min(5, _termYears));

    final curYear = DateTime.now().year;

    // Stacked bars pct
    final piPrinPct = piTotal > 0 ? _loanAmt / piTotal : 0.0;
    final piIntPct = piTotal > 0 ? piInt / piTotal : 0.0;
    final ioPrinPct = ioTotal > 0 ? _loanAmt / ioTotal : 0.0;
    final ioIntPct = ioTotal > 0 ? ioInt / ioTotal : 0.0;

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
                  Text('Repayment Setup',
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
              Text('Compare P&I vs Interest Only',
                  style: AppTextStyles.playfair(
                      size: 18,
                      color: theme.getTextColor(context),
                      weight: FontWeight.w800)),
              const SizedBox(height: 16),

              // Inputs Grid
              Row(
                children: [
                  Expanded(
                    child: _buildInputBox(
                      label: 'Loan Amount',
                      prefix: 'NZD \$',
                      value: _loanAmt,
                      onChanged: (val) => setState(() => _loanAmt = val),
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
                      label: 'Loan Term (yrs)',
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
                      label: 'IO Period (yrs)',
                      prefix: '',
                      value: _ioPeriod.toDouble(),
                      isInteger: true,
                      onChanged: (val) =>
                          setState(() => _ioPeriod = val.toInt()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Calculate Button
              ElevatedButton(
                onPressed: () {
                  if (_loanAmt <= 0) return;
                  if (_ioPeriod >= _termYears) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('IO Period must be less than full term',
                              style: AppTextStyles.dmSans())),
                    );
                    return;
                  }
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
                child: Text('📊 Compare Repayment Types',
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
          Text('Side-by-Side Comparison',
              style: AppTextStyles.playfair(
                  size: 15, color: theme.getTextColor(context))),
          const SizedBox(height: 10),

          // P&I vs IO panels
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A0F0D), Color(0xFF0D3B2E)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PRINCIPAL & INTEREST',
                          style: AppTextStyles.dmSans(
                              size: 8,
                              color: Colors.white54,
                              weight: FontWeight.w800)),
                      Text('P&I · Recommended',
                          style: AppTextStyles.dmSans(
                              size: 10,
                              color: Colors.white,
                              weight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Text(
                          CurrencyFormatter.format(piMonthly,
                              currencyCode: 'NZD'),
                          style: AppTextStyles.playfair(
                              size: 20,
                              color: const Color(0xFFF5D060),
                              weight: FontWeight.w800)),
                      Text('/month',
                          style: AppTextStyles.dmSans(
                              size: 8, color: Colors.white54)),
                      const SizedBox(height: 10),
                      _buildMiniRow('Total Interest',
                          CurrencyFormatter.compact(piInt, symbol: 'NZ\$')),
                      _buildMiniRow('Total Paid',
                          CurrencyFormatter.compact(piTotal, symbol: 'NZ\$')),
                      _buildMiniRow('Equity @ 5yr',
                          CurrencyFormatter.compact(eq5PI, symbol: 'NZ\$')),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFC0392B), Color(0xFF922B21)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('INTEREST ONLY',
                          style: AppTextStyles.dmSans(
                              size: 8,
                              color: Colors.white54,
                              weight: FontWeight.w800)),
                      Text('IO · Investors',
                          style: AppTextStyles.dmSans(
                              size: 10,
                              color: Colors.white,
                              weight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Text(
                          CurrencyFormatter.format(ioMonthly,
                              currencyCode: 'NZD'),
                          style: AppTextStyles.playfair(
                              size: 20,
                              color: const Color(0xFFF5D060),
                              weight: FontWeight.w800)),
                      Text('/month (IO period)',
                          style: AppTextStyles.dmSans(
                              size: 8, color: Colors.white54)),
                      const SizedBox(height: 10),
                      _buildMiniRow('Total Interest',
                          CurrencyFormatter.compact(ioInt, symbol: 'NZ\$')),
                      _buildMiniRow('Total Paid',
                          CurrencyFormatter.compact(ioTotal, symbol: 'NZ\$')),
                      _buildMiniRow('Equity @ 5yr', 'NZ\$0'),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Stacked Bar Visual
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
                Text('Total Cost Breakdown',
                    style: AppTextStyles.dmSans(
                        size: 12,
                        weight: FontWeight.w800,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 12),
                _buildStackedBarRow(
                    'P&I — Full Term', piTotal, piPrinPct, piIntPct, theme),
                const SizedBox(height: 12),
                _buildStackedBarRow(
                    'IO then P&I', ioTotal, ioPrinPct, ioIntPct, theme),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildDot('Principal', const Color(0xFF1A6B4A), theme),
                    const SizedBox(width: 14),
                    _buildDot('Interest', const Color(0xFFC0392B), theme),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    children: [
                      const Text('💰 ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(
                          'P&I saves ${CurrencyFormatter.format(savings, currencyCode: "NZD")} vs IO over full term',
                          style: AppTextStyles.dmSans(
                              size: 11,
                              weight: FontWeight.w800,
                              color: const Color(0xFF15803D)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // IO Warning Key Rules
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              border: Border.all(color: const Color(0xFFF59E0B)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('⚠️ Interest Only — Key NZ Rules',
                    style: AppTextStyles.dmSans(
                        size: 12,
                        weight: FontWeight.w800,
                        color: const Color(0xFF92400E))),
                const SizedBox(height: 4),
                Text(
                  '• Max IO period: typically 5 years for NZ owner-occupiers (1–2 yrs for investors)\n'
                  '• After IO period ends, P&I repayments increase significantly\n'
                  '• No equity built during IO period — property value changes affect LVR\n'
                  '• RBNZ LVR rules still apply: owner-occ 20% min deposit; investors 35%\n'
                  '• IO common for property investors under ring-fencing rules (IRD 2019)',
                  style: AppTextStyles.dmSans(
                      size: 9.5, color: const Color(0xFFB45309), height: 1.5),
                ),
              ],
            ),
          ),

          // IO Period Timeline
          const SizedBox(height: 20),
          Text('IO Period Timeline',
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
              children: [
                _buildTimelineItem(
                    '1',
                    'Now – Year $_ioPeriod (IO Period)',
                    'Interest Only: ${CurrencyFormatter.format(ioMonthly, currencyCode: "NZD")}/month · No principal reduction',
                    '$curYear – ${curYear + _ioPeriod}',
                    const Color(0xFF1A6B4A),
                    theme),
                _buildTimelineDivider(),
                _buildTimelineItem(
                    '2',
                    'Year $_ioPeriod – End (P&I)',
                    'Repayment jumps to ${CurrencyFormatter.format(piAfterIO, currencyCode: "NZD")}/month (${CurrencyFormatter.format(piAfterIO - ioMonthly, currencyCode: "NZD")} more)',
                    '${curYear + _ioPeriod} – ${curYear + _termYears}',
                    const Color(0xFFC0392B),
                    theme),
                _buildTimelineDivider(),
                _buildTimelineItem(
                    '3',
                    'Loan End',
                    'Total repaid: ${CurrencyFormatter.format(ioTotal, currencyCode: "NZD")} · Extra vs P&I: ${CurrencyFormatter.format(savings, currencyCode: "NZD")}',
                    '${curYear + _termYears}',
                    const Color(0xFFF5D060),
                    theme),
              ],
            ),
          ),

          // Save Button Bar
          const SizedBox(height: 14),
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
                    Text('💾 Save comparison',
                        style: AppTextStyles.dmSans(
                            size: 11,
                            weight: FontWeight.w800,
                            color: theme.getTextColor(context))),
                    Text('P&I vs IO saved to portfolio',
                        style: AppTextStyles.dmSans(
                            size: 9, color: theme.getMutedColor(context))),
                  ],
                ),
                ElevatedButton(
                  onPressed: _saveCalculation,
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

  Widget _buildMiniRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(size: 9, color: Colors.white70)),
          Text(val,
              style: AppTextStyles.dmSans(
                  size: 9.5, color: Colors.white, weight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildStackedBarRow(String label, double totalAmt, double prinPct,
      double intPct, CountryTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTextStyles.dmSans(
                    size: 10,
                    weight: FontWeight.w800,
                    color: theme.getTextColor(context))),
            Text('${CurrencyFormatter.compact(totalAmt, symbol: "NZ\$")} total',
                style: AppTextStyles.dmSans(
                    size: 10, color: theme.getMutedColor(context))),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 20,
          decoration: BoxDecoration(
              color: theme.getBgColor(context),
              borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              if (prinPct > 0)
                Expanded(
                  flex: (prinPct * 100).toInt(),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xFF1A6B4A), Color(0xFF0D9488)]),
                      borderRadius:
                          BorderRadius.horizontal(left: Radius.circular(8)),
                    ),
                  ),
                ),
              if (intPct > 0)
                Expanded(
                  flex: (intPct * 100).toInt(),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xFFC0392B), Color(0xFFE74C3C)]),
                      borderRadius:
                          BorderRadius.horizontal(right: Radius.circular(8)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
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

  Widget _buildTimelineItem(String step, String title, String sub, String date,
      Color color, CountryTheme theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(step,
              style: AppTextStyles.dmSans(
                  size: 11, color: Colors.white, weight: FontWeight.w800)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title,
                      style: AppTextStyles.dmSans(
                          size: 11.5,
                          weight: FontWeight.w800,
                          color: theme.getTextColor(context))),
                  Text(date,
                      style: AppTextStyles.dmSans(
                          size: 9, color: theme.getMutedColor(context))),
                ],
              ),
              const SizedBox(height: 2),
              Text(sub,
                  style: AppTextStyles.dmSans(
                      size: 9.5, color: theme.getMutedColor(context))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineDivider() {
    return Container(
      width: 2,
      height: 16,
      color: const Color(0x150A0F0D),
      margin: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
      alignment: Alignment.centerLeft,
    );
  }
}
