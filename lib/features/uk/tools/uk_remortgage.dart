// lib/features/uk/tools/uk_remortgage.dart

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

class UKRemortgage extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;
  const UKRemortgage({super.key, required this.theme, this.savedCalc});

  @override
  ConsumerState<UKRemortgage> createState() => _UKRemortgageState();
}

class _UKRemortgageState extends ConsumerState<UKRemortgage> {
  final _balanceController = TextEditingController(text: '220000');
  final _currRateController = TextEditingController(text: '8.17');
  final _remTermController = TextEditingController(text: '22');
  final _ercController = TextEditingController(text: '0');
  final _newRateController = TextEditingController(text: '4.35');
  final _newTermController = TextEditingController(text: '22');
  final _feeController = TextEditingController(text: '999');

  double _balance = 220000;
  double _currRate = 8.17;
  int _remTerm = 22;
  double _erc = 0;
  double _newRate = 4.35;
  int _newTerm = 22;
  double _fee = 999;

  bool _hasCalculated = false;

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _balanceController.text =
          (inputs['balance'] ?? 220000.0).toStringAsFixed(0);
      _currRateController.text = (inputs['currRate'] ?? 8.17).toString();
      _remTermController.text = (inputs['remTerm'] ?? 22.0).toStringAsFixed(0);
      _ercController.text = (inputs['erc'] ?? 0.0).toStringAsFixed(0);
      _newRateController.text = (inputs['newRate'] ?? 4.35).toString();
      _newTermController.text = (inputs['newTerm'] ?? 22.0).toStringAsFixed(0);
      _feeController.text = (inputs['fee'] ?? 999.0).toStringAsFixed(0);
      _hasCalculated = true;
    }
    _calculateValues();
  }

  @override
  void dispose() {
    _balanceController.dispose();
    _currRateController.dispose();
    _remTermController.dispose();
    _ercController.dispose();
    _newRateController.dispose();
    _newTermController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  void _calculateValues() {
    setState(() {
      _balance = double.tryParse(_balanceController.text) ?? 0;
      _currRate = double.tryParse(_currRateController.text) ?? 0;
      _remTerm = int.tryParse(_remTermController.text) ?? 22;
      _erc = double.tryParse(_ercController.text) ?? 0;
      _newRate = double.tryParse(_newRateController.text) ?? 0;
      _newTerm = int.tryParse(_newTermController.text) ?? 22;
      _fee = double.tryParse(_feeController.text) ?? 0;
    });
  }

  double _pmt(double r, double n, double pv) {
    if (r == 0) return pv / n;
    return pv * (r * math.pow(1 + r, n)) / (math.pow(1 + r, n) - 1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = widget.theme.getCardColor(context);
    final textThemeColor = isDark ? Colors.white : const Color(0xFF0D0D2B);
    final borderCol = widget.theme.getBorderColor(context);

    // Live BoE rates
    final ukRates = ref.watch(ukRatesProvider).valueOrNull;
    final boeBase  = ukRates?.boeBase.value  ?? 4.25;
    final fixed2yr = ukRates?.fixed2yr.value ?? 4.75;
    final fixed5yr = ukRates?.fixed5yr.value ?? 4.35;
    final svr      = ukRates?.svr.value      ?? 7.10;
    final isLive   = ukRates?.isLive == true;

    // Calculations
    const legal = 500.0;
    final crMo = _currRate / 100 / 12;
    final nrMo = _newRate / 100 / 12;
    final rtMo = _remTerm * 12;
    final ntMo = _newTerm * 12;

    final currPmt = _pmt(crMo, rtMo.toDouble(), _balance);
    final newPmt = _pmt(nrMo, ntMo.toDouble(), _balance);
    final diff = currPmt - newPmt;

    final totalCurrInterest = currPmt * rtMo - _balance;
    final totalNewInterest = newPmt * ntMo - _balance;
    final totalIntSaved = totalCurrInterest - totalNewInterest;

    final switchCost = _erc + _fee + legal;
    final breakEvenMo = diff > 0 ? switchCost / diff : double.infinity;
    final breakEvenStr = breakEvenMo == double.infinity
        ? 'N/A'
        : (breakEvenMo < 1 ? '< 1 month' : '${breakEvenMo.ceil()} months');
    final netSaving = diff * ntMo - switchCost;

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
                  child: _rateCell(
                      '2-Yr Fixed', '${fixed2yr.toStringAsFixed(2)}%', isLive ? '🟢 Live' : '+0.05', isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E))),
              _divider(),
              Expanded(
                  child: _rateCell(
                      '5-Yr Fixed', '${fixed5yr.toStringAsFixed(2)}%', 'Best buy', textThemeColor)),
              _divider(),
              Expanded(
                  child: _rateCell(
                      'BoE Base', '${boeBase.toStringAsFixed(2)}%', isLive ? '🟢 Live' : 'Current', isDark ? const Color(0xFFFFD700) : const Color(0xFFD97706))),
              _divider(),
              Expanded(
                  child: _rateCell(
                      'SVR Avg', '${svr.toStringAsFixed(2)}%', 'UK Avg', isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E))),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'YOUR CURRENT MORTGAGE',
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w700,
            color: widget.theme.getMutedColor(context),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),

        // Current Deal Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            children: [
              _inputField(
                  label: 'Outstanding Balance (£)',
                  controller: _balanceController),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _inputField(
                          label: 'Current Interest Rate (%)',
                          controller: _currRateController)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _inputField(
                          label: 'Remaining Term (Years)',
                          controller: _remTermController)),
                ],
              ),
              const SizedBox(height: 12),
              _inputField(
                  label: 'Early Repayment Charge (ERC) (£)',
                  controller: _ercController),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Text(
          'NEW DEAL DETAILS',
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w700,
            color: widget.theme.getMutedColor(context),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),

        // New Deal Card
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
                  Expanded(
                      child: _inputField(
                          label: 'New Interest Rate (%)',
                          controller: _newRateController)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _inputField(
                          label: 'New Deal Term (Years)',
                          controller: _newTermController)),
                ],
              ),
              const SizedBox(height: 12),
              _inputField(
                  label: 'Arrangement Fee (£)', controller: _feeController),
            ],
          ),
        ),
        const SizedBox(height: 16),

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
              '🔁 Calculate Savings',
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
                  'MONTHLY SAVING',
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
                      diff >= 0
                          ? '${CurrencyFormatter.format(diff, symbol: '£').split('.').first}/mo'
                          : '−${CurrencyFormatter.format(diff.abs(), symbol: '£').split('.').first}/mo',
                      style: AppTextStyles.dmSans(
                              size: 34,
                              weight: FontWeight.w800,
                              color: Colors.white)
                          .copyWith(fontFamily: 'Georgia'),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final calc = SavedCalc.create(
                          country: 'UK',
                          calcType: 'Remortgage',
                          inputs: {
                            'balance': _balance,
                            'currRate': _currRate,
                            'remTerm': _remTerm.toDouble(),
                            'erc': _erc,
                            'newRate': _newRate,
                            'newTerm': _newTerm.toDouble(),
                            'fee': _fee,
                          },
                          results: {
                            'Monthly Saving': diff,
                            'Current Payment': currPmt,
                            'New Payment': newPmt,
                            'Interest Saved': totalIntSaved,
                            'Switch Cost': switchCost,
                            'Net Saving': netSaving,
                          },
                          label:
                              '${CurrencyFormatter.compact(_balance, symbol: '£')} balance · ${diff >= 0 ? 'Save' : 'Extra'} ${CurrencyFormatter.compact(diff.abs(), symbol: '£')}/mo',
                          currencyCode: 'GBP',
                        );
                        final messenger = ScaffoldMessenger.of(context);
                        await ref.read(savedProvider.notifier).save(calc);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('✓ Remortgage calculation saved'),
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
                  'New payment: ${CurrencyFormatter.format(newPmt, symbol: '£').split('.').first}/mo at ${_newRate.toStringAsFixed(2)}%',
                  style: AppTextStyles.dmSans(size: 11, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: diff >= 0
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    diff >= 0
                        ? '✅ Save ${CurrencyFormatter.format(diff * 12, symbol: '£').split('.').first} per year'
                        : '⚠️ Extra ${CurrencyFormatter.format(diff.abs() * 12, symbol: '£').split('.').first} per year',
                    style: AppTextStyles.dmSans(
                        size: 10.5,
                        color: diff >= 0
                            ? const Color(0xFF90EE90)
                            : Colors.redAccent,
                        weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Metrics row
          ResultPanel(
            primaryColor: widget.theme.primaryColor,
            rows: [
              ResultRow(
                  label: 'Current Payment',
                  value: currPmt,
                  currencyCode: 'GBP'),
              ResultRow(
                  label: 'New Payment', value: newPmt, currencyCode: 'GBP'),
              ResultRow(
                  label: 'Interest Saved',
                  value: totalIntSaved,
                  currencyCode: 'GBP',
                  isHighlighted: true),
              ResultRow(
                  label: 'Break-even Period',
                  value: breakEvenMo == double.infinity ? 0.0 : breakEvenMo,
                  isPercent: false,
                  customValue: breakEvenStr),
            ],
          ),
          const SizedBox(height: 12),

          // Comparison Bar Chart
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
                  'Monthly Payment Comparison',
                  style: AppTextStyles.dmSans(
                          size: 12,
                          weight: FontWeight.w800,
                          color: textThemeColor)
                      .copyWith(fontFamily: 'Georgia'),
                ),
                const SizedBox(height: 12),
                _barRow('Current', currPmt, isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E),
                    math.max(currPmt, newPmt)),
                const SizedBox(height: 8),
                _barRow('New Deal', newPmt, isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                    math.max(currPmt, newPmt)),
                const SizedBox(height: 8),
                _barRow('Saving', diff.abs(), isDark ? const Color(0xFF93C5FD) : const Color(0xFF1a1a5e),
                    math.max(currPmt, newPmt)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Switching Cost / Benefit Breakdown Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF121230)])
                  : const LinearGradient(colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF4338CA).withValues(alpha: 0.5) : const Color(0xFFA5B4FC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💷 Cost / Benefit Breakdown',
                  style: AppTextStyles.dmSans(
                          size: 12,
                          weight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF1E1B4B))
                      .copyWith(fontFamily: 'Georgia'),
                ),
                const SizedBox(height: 12),
                _breakdownRow('ERC (Early Repayment Charge)', _erc),
                _breakdownRow('Arrangement Fee', _fee),
                _breakdownRow('Legal / Valuation (est.)', legal),
                _breakdownRow('Total Switching Cost', switchCost, isBold: true),
                _breakdownRow('Annual Saving', diff * 12),
                const Divider(color: Color(0xFFA5B4FC), height: 16),
                _breakdownRow('Net Saving (full term)', netSaving,
                    isBold: true, isNet: true),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _barRow(String label, double val, Color color, double max) {
    final pct = max > 0 ? (val / max) : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
                size: 11,
                color: widget.theme.getMutedColor(context),
                weight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 22,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF5F5F8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: pct.clamp(0.0, 1.0),
                  child: Container(color: color),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 60,
          child: Text(
            CurrencyFormatter.format(val, symbol: '£').split('.').first,
            style: AppTextStyles.dmSans(
                size: 11.5,
                weight: FontWeight.w800,
                color: widget.theme.getTextColor(context)),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _breakdownRow(String label, double val,
      {bool isBold = false, bool isNet = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(
              size: 12,
              weight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: isDark ? const Color(0xFFC7D2FE) : const Color(0xFF4338CA),
            ),
          ),
          Text(
            (isNet && val >= 0 ? '+' : '') +
                CurrencyFormatter.format(val, symbol: '£').split('.').first,
            style: AppTextStyles.dmSans(
              size: 12,
              weight: isBold ? FontWeight.w800 : FontWeight.w700,
              color: (isNet && val < 0) || (!isNet && label.contains('Cost'))
                  ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E))
                  : (isNet && val >= 0
                      ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                      : (isDark ? Colors.white : const Color(0xFF0D0D2B))),
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
