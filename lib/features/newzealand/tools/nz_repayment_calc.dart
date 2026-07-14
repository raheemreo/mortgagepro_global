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
  final Map<String, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};
  final _resultsKey = GlobalKey();

  void _reset() {
    setState(() {
      _loanAmt = 680000;
      _rate = 6.59;
      _termYears = 30;
      _ioPeriod = 5;
      _showResults = false;
      _calcSnapshot.clear();
      _errors.clear();
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

  void _calculate() {
    final errors = <String, String>{};

    if (_loanAmt <= 0) {
      errors['loanAmt'] = 'Enter valid loan amount';
    }
    if (_rate <= 0 || _rate > 25) {
      errors['rate'] = 'Enter rate between 0.1% and 25%';
    }
    if (_termYears <= 0 || _termYears > 50) {
      errors['termYears'] = 'Enter term between 1 and 50 years';
    }
    if (_ioPeriod < 0 || _ioPeriod >= _termYears) {
      errors['ioPeriod'] = 'IO period must be less than term years';
    }

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) return;

    setState(() {
      _calcSnapshot['loanAmt'] = _loanAmt;
      _calcSnapshot['rate'] = _rate;
      _calcSnapshot['termYears'] = _termYears;
      _calcSnapshot['ioPeriod'] = _ioPeriod;
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

  void _saveCalculation() async {
    final snapLoanAmt = _calcSnapshot['loanAmt'] ?? _loanAmt;
    final snapRate = _calcSnapshot['rate'] ?? _rate;
    final snapTermYears = _calcSnapshot['termYears'] ?? _termYears;
    final snapIoPeriod = _calcSnapshot['ioPeriod'] ?? _ioPeriod;

    final piMonthly = _calcPI(snapLoanAmt, snapRate, snapTermYears);
    final ioMonthly = _calcIO(snapLoanAmt, snapRate);
    final piTotal = piMonthly * snapTermYears * 12;
    final remainTerm = snapTermYears - snapIoPeriod;
    final piAfterIO = _calcPI(snapLoanAmt, snapRate, remainTerm);
    final ioTotal =
        (ioMonthly * snapIoPeriod * 12) + (piAfterIO * remainTerm * 12);

    final labelCtrl = TextEditingController(text: 'NZ Repayment Plan');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/nz_repayment_calc'),
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
                'Saving: ${CurrencyFormatter.compact(snapLoanAmt, symbol: 'NZ\$')} loan comparison @ $snapRate%',
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
        inputs: <String, double>{
          'loanAmount': snapLoanAmt,
          'rate': snapRate,
          'termYears': snapTermYears.toDouble(),
          'ioPeriod': snapIoPeriod.toDouble(),
        },
        results: <String, double>{
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

    final double rawLoanAmt = _loanAmt;
    final double rawRate = _rate;
    final int rawTerm = _termYears;
    final int rawIoPeriod = _ioPeriod;

    final double loanAmt = _showResults ? (_calcSnapshot['loanAmt'] ?? rawLoanAmt) : rawLoanAmt;
    final double rate = _showResults ? (_calcSnapshot['rate'] ?? rawRate) : rawRate;
    final int termYears = _showResults ? (_calcSnapshot['termYears'] ?? rawTerm) : rawTerm;
    final int ioPeriod = _showResults ? (_calcSnapshot['ioPeriod'] ?? rawIoPeriod) : rawIoPeriod;

    // Calculations
    final piMonthly = _calcPI(loanAmt, rate, termYears);
    final ioMonthly = _calcIO(loanAmt, rate);
    final piTotal = piMonthly * termYears * 12;
    final piInt = piTotal - loanAmt;

    final ioTotalInt = ioMonthly * ioPeriod * 12;
    final remainTerm = termYears - ioPeriod;
    final piAfterIO = _calcPI(loanAmt, rate, remainTerm);
    final ioTotal = ioTotalInt + (piAfterIO * remainTerm * 12);
    final ioInt = ioTotal - loanAmt;

    final savings = ioTotal - piTotal;
    final eq5PI =
        _getEquityAtYear(loanAmt, rate, termYears, min(5, termYears));

    // Stacked bars pct
    final piPrinPct = piTotal > 0 ? loanAmt / piTotal : 0.0;
    final piIntPct = piTotal > 0 ? piInt / piTotal : 0.0;
    final ioPrinPct = ioTotal > 0 ? loanAmt / ioTotal : 0.0;
    final ioIntPct = ioTotal > 0 ? ioInt / ioTotal : 0.0;

    final isDirty = _showResults && (
      _loanAmt != (_calcSnapshot['loanAmt'] ?? 0.0) ||
      _rate != (_calcSnapshot['rate'] ?? 0.0) ||
      _termYears != (_calcSnapshot['termYears'] ?? 0) ||
      _ioPeriod != (_calcSnapshot['ioPeriod'] ?? 0)
    );

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
                      errorText: _errors['loanAmt'],
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
                      errorText: _errors['rate'],
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
                      errorText: _errors['termYears'],
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
                      errorText: _errors['ioPeriod'],
                      onChanged: (val) =>
                          setState(() => _ioPeriod = val.toInt()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Calculate Button
              ElevatedButton(
                onPressed: _calculate,
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
          if (isDirty) ...[
            const SizedBox(height: 12),
            Container(
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
                      'Inputs have changed. Tap Compare Repayment Types to refresh results.',
                      style: AppTextStyles.dmSans(size: 11, color: Colors.amber[800], weight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Container(
            key: _resultsKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                              size: 11,
                              weight: FontWeight.bold,
                              color: const Color(0xFFB45309))),
                      const SizedBox(height: 6),
                      Text(
                          '• RBNZ LVR Speed Limits restrict owner-occupiers from easily getting IO terms without 20%+ equity.\n'
                          '• Repayments increase significantly after the IO period ends (e.g. 25 years left to pay principal vs 30).\n'
                          '• Typically suitable for property investors matching rental receipts or short-term bridging scenarios.',
                          style: AppTextStyles.dmSans(
                              size: 9.5,
                              color: const Color(0xFF92400E),
                              height: 1.4)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveCalculation,
                    icon: const Text('💾', style: TextStyle(fontSize: 14)),
                    label: Text(
                      'Save Repayment Plan Analysis',
                      style: AppTextStyles.playfair(
                          size: 12.5, color: Colors.white, weight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A6B4A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
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
    String? errorText,
  }) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.getBgColor(context),
        border: Border.all(color: errorText != null ? Colors.red : theme.getBorderColor(context)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 8.5,
                  color: theme.getMutedColor(context),
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
                        color: theme.getMutedColor(context),
                        weight: FontWeight.w700)),
              Expanded(
                child: TextFormField(
                  key: ValueKey(value),
                  initialValue:
                      isInteger ? value.toInt().toString() : value.toString(),
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.playfair(
                      size: 15,
                      color: theme.getTextColor(context),
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
                        color: theme.getMutedColor(context),
                        weight: FontWeight.w700)),
            ],
          ),
          if (errorText != null) ...[
            const SizedBox(height: 2),
            Text(errorText, style: AppTextStyles.dmSans(size: 8, color: Colors.red, weight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  AppTextStyles.dmSans(size: 8.5, color: Colors.white70)),
          Text(val,
              style: AppTextStyles.dmSans(
                  size: 9, color: Colors.white, weight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildStackedBarRow(String label, double total, double principalPct,
      double interestPct, CountryTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTextStyles.dmSans(
                    size: 10,
                    weight: FontWeight.w700,
                    color: theme.getTextColor(context))),
            Text(CurrencyFormatter.format(total, currencyCode: 'NZD'),
                style: AppTextStyles.dmSans(
                    size: 11,
                    weight: FontWeight.w800,
                    color: theme.getTextColor(context))),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                if (principalPct > 0)
                  Expanded(
                    flex: (principalPct * 100).round(),
                    child: Container(color: const Color(0xFF1A6B4A)),
                  ),
                if (interestPct > 0)
                  Expanded(
                    flex: (interestPct * 100).round(),
                    child: Container(color: const Color(0xFFC0392B)),
                  ),
              ],
            ),
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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: AppTextStyles.dmSans(
                size: 9, color: theme.getMutedColor(context))),
      ],
    );
  }
}
