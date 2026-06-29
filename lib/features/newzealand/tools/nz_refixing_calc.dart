// lib/features/newzealand/tools/nz_refixing_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZRefixingCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZRefixingCalc({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZRefixingCalc> createState() => _NZRefixingCalcState();
}

class _NZRefixingCalcState extends ConsumerState<NZRefixingCalc> {
  double _balance = 550000;
  double _currentRate = 7.25;
  int _termYears = 30;
  double _breakFee = 0;
  String _expiryMonth = '2025-09';

  bool _showResults = false;

  final List<Map<String, dynamic>> _rates = [
    {'term': '1 Year', 'years': 1, 'rate': 6.59, 'bank': 'ANZ/ASB'},
    {'term': '2 Years', 'years': 2, 'rate': 6.35, 'bank': 'Kiwibank'},
    {'term': '3 Years', 'years': 3, 'rate': 6.29, 'bank': 'Westpac'},
    {'term': '5 Years', 'years': 5, 'rate': 6.19, 'bank': 'BNZ'},
    {'term': 'Floating', 'years': 1, 'rate': 8.64, 'bank': 'Variable'},
  ];

  void _reset() {
    setState(() {
      _balance = 550000;
      _currentRate = 7.25;
      _termYears = 30;
      _breakFee = 0;
      _expiryMonth = '2025-09';
      _showResults = false;
    });
  }

  double _calcMonthlyPmt(double loan, double rate, int termYrs) {
    final r = rate / 100 / 12;
    final n = termYrs * 12;
    if (n <= 0 || r <= 0) return loan * rate / 100 / 12;
    return loan * (r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
  }

  void _saveCalculation() async {
    final currPmt = _calcMonthlyPmt(_balance, _currentRate, _termYears);
    List<Map<String, dynamic>> results = _rates.map((opt) {
      final pmt = _calcMonthlyPmt(_balance, opt['rate'] as double, _termYears);
      final savingPerMonth = currPmt - pmt;
      final savingPerTerm = savingPerMonth * (opt['years'] as int) * 12;
      final netSaving = savingPerTerm - _breakFee;
      return {...opt, 'pmt': pmt, 'netSaving': netSaving};
    }).toList();

    final fixedOptions = results.where((r) => r['term'] != 'Floating').toList();
    fixedOptions.sort((a, b) =>
        (b['netSaving'] as double).compareTo(a['netSaving'] as double));
    final best = fixedOptions.first;

    final labelCtrl = TextEditingController(text: 'NZ Refix Analysis');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/nz_refixing_calc'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Analysis',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Saving refix analysis for ${CurrencyFormatter.compact(_balance, symbol: "NZ\$")} balance. Best: ${best['term']}',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My Refix Plan)',
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
          : 'Refixing Calc';
      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'Refixing Calc',
        inputs: {
          'balance': _balance,
          'currentRate': _currentRate,
          'term': _termYears.toDouble(),
          'breakFee': _breakFee,
        },
        results: {
          'bestTerm': best['years'].toDouble(),
          'bestRate': best['rate'] as double,
          'netSaving': best['netSaving'] as double,
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Refix analysis saved!',
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
    final currPmt = _calcMonthlyPmt(_balance, _currentRate, _termYears);
    List<Map<String, dynamic>> results = [];

    Map<String, dynamic>? best;

    if (_showResults) {
      results = _rates.map((opt) {
        final pmt =
            _calcMonthlyPmt(_balance, opt['rate'] as double, _termYears);
        final savingPerMonth = currPmt - pmt;
        final savingPerTerm = savingPerMonth * (opt['years'] as int) * 12;
        final netSaving = savingPerTerm - _breakFee;
        return {
          ...opt,
          'pmt': pmt,
          'savingPerMonth': savingPerMonth,
          'savingPerTerm': savingPerTerm,
          'netSaving': netSaving
        };
      }).toList();

      final fixedOptions =
          results.where((r) => r['term'] != 'Floating').toList();
      fixedOptions.sort((a, b) =>
          (b['netSaving'] as double).compareTo(a['netSaving'] as double));
      best = fixedOptions.first;
    }

    final half = _balance / 2;
    final splitPmt1 = _calcMonthlyPmt(half, 6.59, _termYears);
    final splitPmt2 = _calcMonthlyPmt(half, 6.35, _termYears);

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
                  Text('Mortgage Details',
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
              Text('Current Fixed Rate Details',
                  style: AppTextStyles.playfair(
                      size: 18,
                      color: theme.getTextColor(context),
                      weight: FontWeight.w800)),
              const SizedBox(height: 16),

              _buildFieldLabel('Current Loan Balance'),
              _buildInputBox(
                prefix: 'NZD \$',
                value: _balance,
                onChanged: (val) => setState(() => _balance = val),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Current Rate'),
                        _buildInputBox(
                          prefix: '',
                          value: _currentRate,
                          isPercent: true,
                          onChanged: (val) =>
                              setState(() => _currentRate = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Remaining Term'),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDF5F2),
                            border: Border.all(color: const Color(0x150D3B2E)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _termYears,
                              isDense: true,
                              dropdownColor: theme.getCardColor(context),
                              style: AppTextStyles.dmSans(
                                  size: 13,
                                  color: const Color(0xFF0A0F0D),
                                  weight: FontWeight.w700),
                              items: const [
                                DropdownMenuItem(
                                    value: 30, child: Text('30 years')),
                                DropdownMenuItem(
                                    value: 27, child: Text('27 years')),
                                DropdownMenuItem(
                                    value: 25, child: Text('25 years')),
                                DropdownMenuItem(
                                    value: 22, child: Text('22 years')),
                                DropdownMenuItem(
                                    value: 20, child: Text('20 years')),
                                DropdownMenuItem(
                                    value: 15, child: Text('15 years')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _termYears = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Fixed Expiry Month'),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 11),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDF5F2),
                            border: Border.all(color: const Color(0x150D3B2E)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(_expiryMonth,
                              style: AppTextStyles.dmSans(
                                  size: 13,
                                  weight: FontWeight.w800,
                                  color: const Color(0xFF0A0F0D))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Break Fee (if early)'),
                        _buildInputBox(
                          prefix: 'NZ\$',
                          value: _breakFee,
                          onChanged: (val) => setState(() => _breakFee = val),
                        ),
                      ],
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
                child: Text('🔄 Find Best Refix Term',
                    style: AppTextStyles.dmSans(
                        size: 14,
                        color: Colors.white,
                        weight: FontWeight.w800)),
              ),
            ],
          ),
        ),

        // Results Recommendation
        if (_showResults && best != null) ...[
          const SizedBox(height: 20),
          Text('Best Refix Strategy',
              style: AppTextStyles.playfair(
                  size: 15, color: theme.getTextColor(context))),
          const SizedBox(height: 10),

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
                Text('Best Refix Strategy · NZD',
                    style:
                        AppTextStyles.dmSans(size: 9.5, color: Colors.white54)),
                const SizedBox(height: 6),
                Text('Refix to ${best['term']} Fixed @ ${best['rate']}%',
                    style: AppTextStyles.dmSans(
                        size: 18,
                        color: Colors.white,
                        weight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  'Best available: ${best['bank']} · Saves ${CurrencyFormatter.format(best['savingPerMonth'] as double, currencyCode: "NZD")}/month vs your current rate',
                  style: AppTextStyles.dmSans(size: 11, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Text('Total Savings vs Current Rate',
                    style: AppTextStyles.dmSans(
                        size: 9,
                        color: Colors.white54,
                        weight: FontWeight.w700)),
                Text(
                  '${best['netSaving'] >= 0 ? "+" : ""}${CurrencyFormatter.compact(best['netSaving'] as double, symbol: "NZ\$")}',
                  style: AppTextStyles.playfair(
                      size: 28,
                      color: const Color(0xFF6EE7B7),
                      weight: FontWeight.w800),
                ),
                Text(
                    'over ${best['years']} year${best['years'] > 1 ? "s" : ""} vs current rate of $_currentRate%',
                    style: AppTextStyles.dmSans(
                        size: 10.5, color: Colors.white54)),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: _saveCalculation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('💾 Save This Analysis',
                      style: AppTextStyles.dmSans(
                          size: 11,
                          color: Colors.white,
                          weight: FontWeight.w800)),
                ),
              ],
            ),
          ),

          // Refix options list
          const SizedBox(height: 20),
          Text('All Refix Options',
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
                Text('NZ 2025 Rates comparison',
                    style: AppTextStyles.dmSans(
                        size: 11,
                        weight: FontWeight.w700,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 10),
                ...results.map((opt) {
                  final isBest = opt['term'] == best?['term'];
                  final netSaving = opt['netSaving'] as double;
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color:
                          isBest ? const Color(0x101A6B4A) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: isBest
                                    ? const LinearGradient(colors: [
                                        Color(0xFF1A6B4A),
                                        Color(0xFF0D9488)
                                      ])
                                    : null,
                                color:
                                    isBest ? null : theme.getBgColor(context),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                isBest ? '★ Best' : '${opt['years']}yr',
                                style: AppTextStyles.dmSans(
                                    size: 10,
                                    weight: FontWeight.w800,
                                    color: isBest
                                        ? Colors.white
                                        : theme.getMutedColor(context)),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${opt['term']} Fixed',
                                    style: AppTextStyles.dmSans(
                                        size: 12,
                                        weight: FontWeight.w800,
                                        color: theme.getTextColor(context))),
                                Text('${opt['rate']}% p.a. · ${opt['bank']}',
                                    style: AppTextStyles.dmSans(
                                        size: 9.5,
                                        color: theme.getMutedColor(context))),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                                '${CurrencyFormatter.compact(opt['pmt'] as double, symbol: "NZ\$")}/mo',
                                style: AppTextStyles.dmSans(
                                    size: 13,
                                    weight: FontWeight.w800,
                                    color: theme.getTextColor(context))),
                            Text(
                              netSaving >= 0
                                  ? 'Save ${CurrencyFormatter.compact(netSaving, symbol: "NZ\$")}'
                                  : 'Extra ${CurrencyFormatter.compact(netSaving.abs(), symbol: "NZ\$")}',
                              style: AppTextStyles.dmSans(
                                  size: 9.5,
                                  color: netSaving >= 0
                                      ? const Color(0xFF1A6B4A)
                                      : const Color(0xFFC0392B),
                                  weight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // Split Mortgage Strategy Card
          const SizedBox(height: 20),
          Text('Split Mortgage Strategy',
              style: AppTextStyles.playfair(
                  size: 15, color: theme.getTextColor(context))),
          const SizedBox(height: 10),
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
                Text('💡 Split Mortgage Strategy',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        weight: FontWeight.w800,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF0D3B2E), Color(0xFF1A6B4A)]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Text('Split 1 (50%)',
                                style: AppTextStyles.dmSans(
                                    size: 8.5,
                                    color: Colors.white60,
                                    weight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                                '${CurrencyFormatter.compact(splitPmt1, symbol: "NZ\$")}/mo',
                                style: AppTextStyles.dmSans(
                                    size: 13,
                                    weight: FontWeight.w800,
                                    color: Colors.white)),
                            Text('1-yr @ 6.59%',
                                style: AppTextStyles.dmSans(
                                    size: 9, color: Colors.white60)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF0D9488), Color(0xFF0F766E)]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Text('Split 2 (50%)',
                                style: AppTextStyles.dmSans(
                                    size: 8.5,
                                    color: Colors.white60,
                                    weight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                                '${CurrencyFormatter.compact(splitPmt2, symbol: "NZ\$")}/mo',
                                style: AppTextStyles.dmSans(
                                    size: 13,
                                    weight: FontWeight.w800,
                                    color: Colors.white)),
                            Text('2-yr @ 6.35%',
                                style: AppTextStyles.dmSans(
                                    size: 9, color: Colors.white60)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Splitting your loan across multiple terms reduces rate risk. If rates drop, your 1-year portion refixes sooner. If rates rise, your 2-year portion is protected. Popular NZ strategy in uncertain rate environments.',
                  style: AppTextStyles.dmSans(
                      size: 10,
                      color: theme.getMutedColor(context),
                      height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(label,
          style: AppTextStyles.dmSans(
              size: 9,
              weight: FontWeight.w700,
              color: widget.theme.getMutedColor(context))),
    );
  }

  Widget _buildInputBox({
    required String prefix,
    required double value,
    bool isPercent = false,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF5F2),
        border: Border.all(color: const Color(0x150D3B2E)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
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
              initialValue: value.toString(),
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
    );
  }
}
