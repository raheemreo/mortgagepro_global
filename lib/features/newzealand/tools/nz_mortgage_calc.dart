// lib/features/newzealand/tools/nz_mortgage_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../providers/nz_rates_provider.dart';
import '../../../services/remote_config_service.dart';

class NZMortgageCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZMortgageCalc({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZMortgageCalc> createState() => _NZMortgageCalcState();
}

class _NZMortgageCalcState extends ConsumerState<NZMortgageCalc> {
  double _propVal = 850000;
  double _deposit = 170000;
  double _rate = 5.59;
  int _termYears = 30;
  String _repayType = 'PI';

  bool _showResults = false;

  final List<Map<String, dynamic>> _banks = [
    {'name': 'Kiwibank', 'icon': '🥝', 'rate': 5.55},
    {'name': 'ANZ', 'icon': '🏦', 'rate': 5.59},
    {'name': 'ASB', 'icon': '🏦', 'rate': 5.59},
    {'name': 'BNZ', 'icon': '🏦', 'rate': 5.59},
    {'name': 'Westpac', 'icon': '🏦', 'rate': 5.65},
    {'name': 'SBS Bank', 'icon': '🏦', 'rate': 5.70},
  ];

  void _reset() {
    setState(() {
      _propVal = 850000;
      _deposit = 170000;
      _rate = 5.59;
      _termYears = 30;
      _repayType = 'PI';
      _showResults = false;
    });
  }

  void _saveCalculation() async {
    final loanAmt = _propVal - _deposit;
    if (loanAmt <= 0) return;

    final lvr = (loanAmt / _propVal) * 100;
    final monthlyRate = _rate / 100 / 12;
    final n = _termYears * 12;

    double monthly;
    double totalInterest;
    double totalPaid;

    if (_repayType == 'PI') {
      if (monthlyRate == 0) {
        monthly = loanAmt / n;
      } else {
        monthly = loanAmt *
            (monthlyRate * pow(1 + monthlyRate, n)) /
            (pow(1 + monthlyRate, n) - 1);
      }
      totalPaid = monthly * n;
      totalInterest = totalPaid - loanAmt;
    } else {
      monthly = loanAmt * monthlyRate;
      totalInterest = monthly * n;
      totalPaid = loanAmt + totalInterest;
    }

    final labelCtrl = TextEditingController(text: 'NZ Dream Home');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/nz_mortgage_calc/save'),
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
                'Saving: ${CurrencyFormatter.compact(loanAmt, symbol: 'NZ\$')} loan @ $_rate% → ${CurrencyFormatter.compact(monthly, symbol: 'NZ\$')}/mo',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Auckland Property)',
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
          : 'Mortgage Calc';
      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'Mortgage Calc',
        inputs: {
          'propertyValue': _propVal,
          'deposit': _deposit,
          'rate': _rate,
          'termYears': _termYears.toDouble(),
          'repayType': _repayType == 'PI' ? 0.0 : 1.0,
        },
        results: {
          'monthly': monthly,
          'totalInterest': totalInterest,
          'totalRepaid': totalPaid,
          'lvr': lvr,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Live NZ rates
    final nzRates = ref.watch(nzRatesProvider).valueOrNull;
    final f1 = nzRates?.fixed1yr.value ?? 5.59;
    final f2 = nzRates?.fixed2yr.value ?? 5.29;
    final f3 = nzRates?.fixed3yr.value ?? 5.19;
    final f5 = nzRates?.fixed5yr.value ?? 5.09;
    final fl = nzRates?.floating.value ?? 7.24;
    final isLive = nzRates?.isLive == true;
    final rc = RemoteConfigService.instance;
    final ocr = double.tryParse(rc.nzOcrRate) ?? 2.25;

    // Update bank rates if live
    if (isLive) {
      _banks[0]['rate'] = nzRates?.kiwibank1yr ?? 5.55;
      _banks[1]['rate'] = nzRates?.anz1yr      ?? 5.59;
      _banks[2]['rate'] = nzRates?.asb1yr      ?? 5.59;
      _banks[3]['rate'] = nzRates?.bnz1yr      ?? 5.59;
      _banks[4]['rate'] = nzRates?.westpac1yr  ?? 5.65;
    }

    // Calculations
    final loanAmt = _propVal - _deposit;
    final lvr = _propVal > 0 ? (loanAmt / _propVal) * 100 : 0.0;
    final monthlyRate = _rate / 100 / 12;
    final n = _termYears * 12;

    double monthly;
    double totalInterest;
    double totalPaid;

    if (_repayType == 'PI') {
      if (monthlyRate == 0) {
        monthly = loanAmt / n;
      } else {
        monthly = loanAmt *
            (monthlyRate * pow(1 + monthlyRate, n)) /
            (pow(1 + monthlyRate, n) - 1);
      }
      totalPaid = monthly * n;
      totalInterest = totalPaid - loanAmt;
    } else {
      monthly = loanAmt * monthlyRate;
      totalInterest = monthly * n;
      totalPaid = loanAmt + totalInterest;
    }

    final fortnightly = monthly / 2;
    final weekly = monthly / 4.333;

    // Donut chart percentages
    final donutTotal = loanAmt + totalInterest;
    final principalPct = donutTotal > 0 ? loanAmt / donutTotal : 0.0;
    final interestPct = donutTotal > 0 ? totalInterest / donutTotal : 0.0;

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
              colors: [Color(0xFF0A0F0D), Color(0xFF0D3B2E)],
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
                  Text('New Zealand Mortgage Details',
                      style: AppTextStyles.dmSans(
                          size: 10,
                          color: Colors.white54,
                          weight: FontWeight.w600)),
                  GestureDetector(
                    onTap: _reset,
                    child: Text('Reset ↺',
                        style: AppTextStyles.dmSans(
                            size: 11,
                            color: const Color(0xFFF5D060),
                            weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Calculate NZ Home Loan',
                  style: AppTextStyles.playfair(
                      size: 18, color: Colors.white, weight: FontWeight.w800)),
              const SizedBox(height: 16),

              // Inputs Grid
              Row(
                children: [
                  Expanded(
                    child: _buildInputBox(
                      label: 'Property Value',
                      prefix: 'NZD \$',
                      value: _propVal,
                      onChanged: (val) => setState(() => _propVal = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputBox(
                      label: 'Deposit',
                      prefix: 'NZD \$',
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
              const SizedBox(height: 14),

              // Quick Rate Pills
              Text('NZ Lender Rates${isLive ? " 🟢 Live" : " (2025 Est.)"}',
                  style: AppTextStyles.dmSans(
                      size: 9, color: Colors.white54, weight: FontWeight.w600)),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildRatePill('1-yr Fixed ${f1.toStringAsFixed(2)}%', f1),
                    const SizedBox(width: 6),
                    _buildRatePill('2-yr Fixed ${f2.toStringAsFixed(2)}%', f2),
                    const SizedBox(width: 6),
                    _buildRatePill('3-yr Fixed ${f3.toStringAsFixed(2)}%', f3),
                    const SizedBox(width: 6),
                    _buildRatePill('5-yr Fixed ${f5.toStringAsFixed(2)}%', f5),
                    const SizedBox(width: 6),
                    _buildRatePill('Floating ${fl.toStringAsFixed(2)}%', fl),
                    const SizedBox(width: 6),
                    _buildRatePill('OCR ${ocr.toStringAsFixed(2)}%', ocr),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Repayment Type Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _repayType,
                    dropdownColor: const Color(0xFF0A0F0D),
                    style: AppTextStyles.dmSans(
                        size: 13, color: Colors.white, weight: FontWeight.w700),
                    items: const [
                      DropdownMenuItem(
                          value: 'PI', child: Text('Principal & Interest')),
                      DropdownMenuItem(
                          value: 'IO', child: Text('Interest Only')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _repayType = val);
                      }
                    },
                  ),
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
                  backgroundColor: const Color(0xFF1A6B4A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 44),
                  elevation: 4,
                ),
                child: Text('🌿 Calculate NZ Mortgage',
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
              Text(
                'LVR: ${lvr.toStringAsFixed(1)}% ${lvr > 80 ? "⚠️ High" : "✅ OK"}',
                style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.w700,
                  color: lvr > 80
                      ? const Color(0xFFC0392B)
                      : const Color(0xFF1A6B4A),
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
                Text(CurrencyFormatter.format(monthly, currencyCode: 'NZD'),
                    style: AppTextStyles.playfair(
                        size: 38,
                        color: theme.getTextColor(context),
                        weight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  'Fortnightly: ${CurrencyFormatter.format(fortnightly, currencyCode: "NZD")} · Weekly: ${CurrencyFormatter.format(weekly, currencyCode: "NZD")}',
                  style: AppTextStyles.dmSans(
                      size: 10, color: theme.getMutedColor(context)),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // Grid Summary
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  childAspectRatio: 1.4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    _buildSummaryBox(
                        'Loan Amount',
                        CurrencyFormatter.compact(loanAmt, symbol: 'NZ\$'),
                        Colors.blue),
                    _buildSummaryBox(
                        'Total Interest',
                        CurrencyFormatter.compact(totalInterest,
                            symbol: 'NZ\$'),
                        const Color(0xFFC0392B)),
                    _buildSummaryBox(
                        'Total Repaid',
                        CurrencyFormatter.compact(totalPaid, symbol: 'NZ\$'),
                        theme.getTextColor(context)),
                  ],
                ),
              ],
            ),
          ),

          // Save Calculation Card
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
                    Text('💾 Save this calculation',
                        style: AppTextStyles.dmSans(
                            size: 12,
                            weight: FontWeight.w800,
                            color: theme.getTextColor(context))),
                    Text('Store to your NZ loan portfolio',
                        style: AppTextStyles.dmSans(
                            size: 10, color: theme.getMutedColor(context))),
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

          // Cost Breakdown Donut Chart
          const SizedBox(height: 20),
          Text('Cost Breakdown',
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
                  width: 100,
                  height: 100,
                  child: CustomPaint(
                    painter: _NZDonutPainter(
                      principalPct: principalPct,
                      interestPct: interestPct,
                      lvr: lvr,
                      isDark: isDark,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _buildLegendRow('Principal', loanAmt, principalPct,
                          const Color(0xFF1A6B4A)),
                      const SizedBox(height: 8),
                      _buildLegendRow('Total Interest', totalInterest,
                          interestPct, const Color(0xFFC0392B)),
                      const SizedBox(height: 8),
                      _buildLegendRow('Deposit', _deposit, _deposit / _propVal,
                          const Color(0xFFF5D060)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Freq compare bar chart
          const SizedBox(height: 20),
          Text('Payment Frequency Options',
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
                _buildFreqBar('Monthly', monthly, 1.0,
                    const [Color(0xFF1A6B4A), Color(0xFF0D9488)]),
                const SizedBox(height: 10),
                _buildFreqBar('Fortnightly', fortnightly, 0.92,
                    const [Color(0xFF0D9488), Color(0xFF0EA5E9)]),
                const SizedBox(height: 10),
                _buildFreqBar('Weekly', weekly, 0.46,
                    const [Color(0xFF0EA5E9), Color(0xFF6D28D9)]),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF115E59).withValues(alpha: 0.3)
                        : const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: isDark
                            ? const Color(0xFF0D9488)
                            : const Color(0xFF5EEAD4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('💡 Fortnightly saves interest',
                          style: AppTextStyles.dmSans(
                              size: 11,
                              weight: FontWeight.w800,
                              color: isDark
                                  ? const Color(0xFF2DD4BF)
                                  : const Color(0xFF0F766E))),
                      const SizedBox(height: 2),
                      Text(
                        'Paying fortnightly (26 × half-monthly) makes ~1 extra month/yr, saving thousands in interest over the loan term.',
                        style: AppTextStyles.dmSans(
                            size: 9.5,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF0D9488)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lender Comparison
          const SizedBox(height: 20),
          Text('Lender Comparison',
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
                Text('NZ Bank Rates · 1-yr Fixed${isLive ? " 🟢 Live" : " (2025 Est.)"}',
                    style: AppTextStyles.dmSans(
                        size: 11,
                        weight: FontWeight.w700,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 12),
                ..._banks.map((b) {
                  final rateVal = b['rate'] as double;
                  final cheapestRate = (_banks.map((b) => b['rate'] as double).reduce((a, b) => a < b ? a : b));
                  final m = _calculateBankMonthly(
                      loanAmt, rateVal, _termYears, _repayType);
                  final cheapest = _calculateBankMonthly(
                      loanAmt, cheapestRate, _termYears, _repayType);
                  final diff = m - cheapest;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                          bottom:
                              BorderSide(color: theme.getBorderColor(context))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: rateVal == 6.55
                                        ? const Color(0xFF1A6B4A)
                                        : const Color(0xFFC0C8C1),
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text('${b['icon']} ${b['name']}',
                                style: AppTextStyles.dmSans(
                                    size: 11.5,
                                    weight: FontWeight.w800,
                                    color: theme.getTextColor(context))),
                            const SizedBox(width: 6),
                            Text('${rateVal.toStringAsFixed(2)}% p.a.',
                                style: AppTextStyles.dmSans(
                                    size: 10,
                                    color: theme.getMutedColor(context))),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('\$${m.toStringAsFixed(0)}/mo',
                                style: AppTextStyles.dmSans(
                                    size: 12,
                                    weight: FontWeight.w800,
                                    color: const Color(0xFF1A6B4A))),
                            Text(
                                diff == 0
                                    ? 'Cheapest'
                                    : '+\$${diff.toStringAsFixed(0)}/mo',
                                style: AppTextStyles.dmSans(
                                    size: 9,
                                    weight: FontWeight.w700,
                                    color: diff == 0
                                        ? const Color(0xFF1A6B4A)
                                        : const Color(0xFFC0392B))),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  double _calculateBankMonthly(
      double loan, double rate, int years, String type) {
    final r = rate / 100 / 12;
    final n = years * 12;
    if (type == 'IO') return loan * r;
    if (r == 0) return loan / n;
    return loan * (r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
  }

  Widget _buildRatePill(String label, double rateVal) {
    final active = _rate == rateVal;
    return GestureDetector(
      onTap: () => setState(() => _rate = rateVal),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF0D3B2E)
              : Colors.white.withValues(alpha: 0.1),
          border: Border.all(
              color: active
                  ? const Color(0xFF1A6B4A)
                  : Colors.white.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w700,
                color: active ? Colors.white : Colors.white70)),
      ),
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

  Widget _buildSummaryBox(String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFEDF5F2),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.transparent),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 8,
                  color: isDark ? Colors.white70 : const Color(0xFF4A6358),
                  weight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.playfair(
                  size: 12, color: color, weight: FontWeight.w800),
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
          '${CurrencyFormatter.compact(val, symbol: 'NZ\$')} (${(pct * 100).toStringAsFixed(0)}%)',
          style: AppTextStyles.dmSans(
              size: 11,
              color: theme.getTextColor(context),
              weight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildFreqBar(
      String label, double val, double widthPct, List<Color> colors) {
    final theme = widget.theme;
    return Row(
      children: [
        SizedBox(
            width: 60,
            child: Text(label,
                style: AppTextStyles.dmSans(
                    size: 10,
                    color: theme.getMutedColor(context),
                    weight: FontWeight.w700))),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                        color: theme.getBgColor(context),
                        borderRadius: BorderRadius.circular(6)),
                  ),
                  Container(
                    width: constraints.maxWidth * widthPct,
                    height: 14,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Text(CurrencyFormatter.format(val, currencyCode: 'NZD'),
            style: AppTextStyles.dmSans(
                size: 11,
                color: theme.getTextColor(context),
                weight: FontWeight.w800)),
      ],
    );
  }
}

class _NZDonutPainter extends CustomPainter {
  final double principalPct;
  final double interestPct;
  final double lvr;
  final bool isDark;

  _NZDonutPainter({
    required this.principalPct,
    required this.interestPct,
    required this.lvr,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    const strokeWidth = 14.0;

    final paintBg = Paint()
      ..color =
          isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFEDF5F2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, paintBg);

    double startAngle = -pi / 2;

    // Draw Principal Segment
    if (principalPct > 0) {
      final sweepAngle = principalPct * 2 * pi;
      final paintP = Paint()
        ..color = const Color(0xFF1A6B4A)
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
        ..color = const Color(0xFFC0392B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startAngle, sweepAngle, false, paintI);
    }

    // Draw central LVR text
    final textPainterLVR = TextPainter(
      text: TextSpan(
          text: 'LVR',
          style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF0A0F0D),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              fontFamily: 'Palatino')),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainterLVR.paint(canvas, center - Offset(textPainterLVR.width / 2, 12));

    final textPainterPct = TextPainter(
      text: TextSpan(
          text: '${lvr.toStringAsFixed(0)}%',
          style: TextStyle(
              color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF1A6B4A),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'Palatino')),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainterPct.paint(canvas, center - Offset(textPainterPct.width / 2, -2));
  }

  @override
  bool shouldRepaint(covariant _NZDonutPainter oldDelegate) =>
      oldDelegate.principalPct != principalPct ||
      oldDelegate.interestPct != interestPct ||
      oldDelegate.lvr != lvr ||
      oldDelegate.isDark != isDark;
}
