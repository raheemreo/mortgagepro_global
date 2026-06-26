// lib/features/newzealand/tools/nz_affordability_calc.dart

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

class NZAffordabilityCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZAffordabilityCalc({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZAffordabilityCalc> createState() =>
      _NZAffordabilityCalcState();
}

class _NZAffordabilityCalcState extends ConsumerState<NZAffordabilityCalc> {
  double _borrower1Income = 120000;
  double _borrower2Income = 0;
  double _expenses = 3500;
  double _debts = 400;
  double _deposit = 200000;
  int _termYears = 30;
  double _rate = 5.59;
  bool _showResults = false;
  final List<Map<String, dynamic>> _regions = [
    {'icon': '🏙️', 'city': 'Auckland', 'price': 950000.0},
    {'icon': '🌊', 'city': 'Wellington', 'price': 780000.0},
    {'icon': '🏔️', 'city': 'Christchurch', 'price': 610000.0},
    {'icon': '🌺', 'city': 'Hamilton', 'price': 650000.0},
    {'icon': '🌿', 'city': 'Tauranga', 'price': 810000.0},
    {'icon': '🍇', 'city': 'Dunedin', 'price': 520000.0},
  ];

  void _reset() {
    setState(() {
      _borrower1Income = 120000;
      _borrower2Income = 0;
      _expenses = 3500;
      _debts = 400;
      _deposit = 200000;
      _termYears = 30;
      _rate = 5.59;
      _showResults = false;
    });
  }

  // NZ piecewise PAYE net monthly income estimate
  double _netIncome(double gross) {
    if (gross <= 14000) {
      return gross * 0.895;
    }
    if (gross <= 48000) {
      return 14000 * 0.895 + (gross - 14000) * 0.83;
    }
    if (gross <= 70000) {
      return 14000 * 0.895 + 34000 * 0.83 + (gross - 48000) * 0.80;
    }
    if (gross <= 180000) {
      return 14000 * 0.895 +
          34000 * 0.83 +
          22000 * 0.80 +
          (gross - 70000) * 0.67;
    }
    return 14000 * 0.895 +
        34000 * 0.83 +
        22000 * 0.80 +
        110000 * 0.67 +
        (gross - 180000) * 0.61;
  }

  double _calcMonthly(double loan, double rate, int years) {
    final r = rate / 100 / 12;
    final n = years * 12;
    if (r == 0) return loan / n;
    return loan * (r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
  }

  void _saveCalculation() async {
    final income = _borrower1Income + _borrower2Income;
    final netMo = _netIncome(income) / 12;
    final maxByBudget = (netMo - _expenses - _debts) * 0.95;
    final singlePayment = _calcMonthly(1.0, _rate, _termYears);
    final maxLoanByBudget =
        singlePayment > 0 ? maxByBudget / singlePayment : 0.0;
    final maxLoanByDTI = (income * 6) - (_debts * 12);
    final maxLoan =
        max(0.0, min(maxLoanByBudget, min(maxLoanByDTI, income * 6)));

    final labelCtrl = TextEditingController(text: 'NZ Affordability Plan');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Affordability Report',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Saving: ${CurrencyFormatter.compact(maxLoan, symbol: "NZ\$")} borrowing capacity for ${CurrencyFormatter.compact(income, symbol: "NZ\$")} gross income',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Dream House Budget)',
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
          : 'Affordability';
      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'Affordability Calc',
        inputs: {
          'income1': _borrower1Income,
          'income2': _borrower2Income,
          'expenses': _expenses,
          'debts': _debts,
          'deposit': _deposit,
          'rate': _rate,
          'term': _termYears.toDouble(),
        },
        results: {
          'maxLoan': maxLoan,
          'maxPropPrice': maxLoan + _deposit,
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Affordability assessment saved!',
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

    // Live NZ rates
    final nzRates = ref.watch(nzRatesProvider).valueOrNull;
    final liveRate = nzRates?.fixed1yr.value;
    if (liveRate != null && _rate == 5.59) {
      // Only pre-fill on first build if still default
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _rate == 5.59) setState(() => _rate = liveRate);
      });
    }

    // Update region prices from Remote Config
    final rc = RemoteConfigService.instance;
    _regions[0]['price'] = rc.nzPriceAuckland * 1000.0;
    _regions[1]['price'] = rc.nzPriceWellington * 1000.0;
    _regions[2]['price'] = rc.nzPriceChristchurch * 1000.0;
    _regions[3]['price'] = rc.nzPriceHamilton * 1000.0;
    _regions[4]['price'] = rc.nzPriceTauranga * 1000.0;
    _regions[5]['price'] = rc.nzPriceDunedin * 1000.0;

    // Calculations
    final income = _borrower1Income + _borrower2Income;
    final netMo = _netIncome(income) / 12;
    final maxByBudget = (netMo - _expenses - _debts) * 0.95;
    final singlePayment =
        _isMonthlyView ? 0.0 : _calcMonthly(1.0, _rate, _termYears);
    final maxLoanByBudget =
        singlePayment > 0 ? maxByBudget / singlePayment : 0.0;
    final maxLoanByDTI = (income * 6) - (_debts * 12);
    final maxLoan =
        max(0.0, min(maxLoanByBudget, min(maxLoanByDTI, income * 6)));
    final maxProp = maxLoan + _deposit;

    final monthly = _calcMonthly(maxLoan, _rate, _termYears);
    final monthlyStress = _calcMonthly(maxLoan, _rate + 2.0, _termYears);

    // Health metrics
    final mortPct = netMo > 0 ? (monthly / netMo * 100) : 0.0;
    final totDebtPct = netMo > 0 ? ((monthly + _debts) / netMo * 100) : 0.0;
    final dti = income > 0 ? (maxLoan / income) : 0.0;
    final remaining = netMo - monthly - _debts - _expenses;
    final remPct = netMo > 0 ? (remaining / netMo * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Inputs Card
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
                  Text('Affordability Setup',
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
              Text('Your Finances & Expenses',
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
                      label: 'Gross Annual Income',
                      prefix: 'NZD \$',
                      value: _borrower1Income,
                      onChanged: (val) =>
                          setState(() => _borrower1Income = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputBox(
                      label: 'Partner Income (Yr)',
                      prefix: 'NZD \$',
                      value: _borrower2Income,
                      onChanged: (val) =>
                          setState(() => _borrower2Income = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildInputBox(
                      label: 'Monthly Expenses',
                      prefix: 'NZD \$',
                      value: _expenses,
                      onChanged: (val) => setState(() => _expenses = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputBox(
                      label: 'Existing Debts (Mo)',
                      prefix: 'NZD \$',
                      value: _debts,
                      onChanged: (val) => setState(() => _debts = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildInputBox(
                      label: 'Deposit Available',
                      prefix: 'NZD \$',
                      value: _deposit,
                      onChanged: (val) => setState(() => _deposit = val),
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

              // Rate Slider
              Text('Interest Rate: ${_rate.toStringAsFixed(2)}%',
                  style: AppTextStyles.dmSans(
                      size: 10,
                      weight: FontWeight.w700,
                      color: theme.getMutedColor(context))),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: const Color(0xFF1A6B4A),
                  thumbColor: const Color(0xFF1A6B4A),
                  inactiveTrackColor:
                      const Color(0xFF1A6B4A).withValues(alpha: 0.20),
                  trackHeight: 3,
                ),
                child: Slider(
                  value: _rate.clamp(4.0, 10.0),
                  min: 4.0,
                  max: 10.0,
                  divisions: 600,
                  onChanged: (v) => setState(() => _rate = v),
                ),
              ),

              const SizedBox(height: 10),
              // Calculate Button
              ElevatedButton(
                onPressed: () {
                  if (income <= 0) return;
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
                child: Text('💰 Calculate Affordability',
                    style: AppTextStyles.dmSans(
                        size: 14,
                        color: Colors.white,
                        weight: FontWeight.w800)),
              ),
            ],
          ),
        ),

        // Results
        if (_showResults) ...[
          const SizedBox(height: 20),
          Text('Your Borrowing Capacity',
              style: AppTextStyles.playfair(
                  size: 15, color: theme.getTextColor(context))),
          const SizedBox(height: 10),

          // Borrowing Hero Panel
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A0F0D), Color(0xFF0D3B2E)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Maximum Loan Amount · NZD',
                    style:
                        AppTextStyles.dmSans(size: 9.5, color: Colors.white54)),
                const SizedBox(height: 4),
                Text(CurrencyFormatter.format(maxLoan, currencyCode: 'NZD'),
                    style: AppTextStyles.playfair(
                        size: 36,
                        color: const Color(0xFFF5D060),
                        weight: FontWeight.w800)),
                Text(
                  'Max property: ${CurrencyFormatter.compact(maxProp, symbol: "NZ\$")} with ${CurrencyFormatter.compact(_deposit, symbol: "NZ\$")} deposit',
                  style:
                      AppTextStyles.dmSans(size: 10.5, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 2.3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    _buildHeroBox('Monthly Payment',
                        '\$${monthly.toStringAsFixed(0)}/mo'),
                    _buildHeroBox('Stress-Test Rate',
                        '\$${monthlyStress.toStringAsFixed(0)}/mo'),
                    _buildHeroBox(
                        'Max by DTI 6x',
                        CurrencyFormatter.compact(maxLoanByDTI,
                            symbol: 'NZ\$')),
                    _buildHeroBox('Max Property',
                        CurrencyFormatter.compact(maxProp, symbol: 'NZ\$')),
                  ],
                ),
              ],
            ),
          ),

          // Budget Health Check Card
          const SizedBox(height: 14),
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
                Text('Budget Health Check',
                    style: AppTextStyles.dmSans(
                        size: 12,
                        weight: FontWeight.w800,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 14),
                _buildHealthBar(
                    '🏠 Mortgage vs Net Income',
                    mortPct,
                    '${mortPct.toStringAsFixed(0)}%',
                    mortPct <= 30
                        ? const Color(0xFF1A6B4A)
                        : mortPct <= 35
                            ? const Color(0xFFD4A017)
                            : const Color(0xFFC0392B),
                    'NZ guideline: keep under 30–35% of net income',
                    theme),
                const SizedBox(height: 14),
                _buildHealthBar(
                    '💳 Total Debt vs Net Income',
                    totDebtPct,
                    '${totDebtPct.toStringAsFixed(0)}%',
                    totDebtPct <= 40
                        ? const Color(0xFF0D9488)
                        : const Color(0xFFC0392B),
                    'All debts: NZ banks prefer under 40% of net',
                    theme),
                const SizedBox(height: 14),
                _buildHealthBar(
                    '📊 DTI Ratio',
                    dti / 8 * 100,
                    '${dti.toStringAsFixed(1)}x',
                    dti <= 5
                        ? const Color(0xFF1A6B4A)
                        : dti <= 6
                            ? const Color(0xFFD4A017)
                            : const Color(0xFFC0392B),
                    'RBNZ cap: 6x owner-occupier',
                    theme),
                const SizedBox(height: 14),
                _buildHealthBar(
                    '💵 Remaining After Mortgage',
                    remPct,
                    '\$${remaining.toStringAsFixed(0)}/mo',
                    const Color(0xFF1A6B4A),
                    'After mortgage, debts & living costs',
                    theme),
              ],
            ),
          ),

          // NZ Region Match
          const SizedBox(height: 20),
          Text('NZ Region Match',
              style: AppTextStyles.playfair(
                  size: 15, color: theme.getTextColor(context))),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: _regions.map((r) {
              final price = r['price'] as double;
              final needed = max(0.0, price - _deposit);
              final canAfford = needed <= maxLoan;
              final close = !canAfford && needed <= maxLoan * 1.15;
              Color badgeBg;
              Color badgeFg;
              String badgeText;
              if (canAfford) {
                badgeBg = const Color(0xFFECFDF5);
                badgeFg = const Color(0xFF065F46);
                badgeText = '✅ Affordable';
              } else if (close) {
                badgeBg = const Color(0xFFFFFBEB);
                badgeFg = const Color(0xFF92400E);
                badgeText = '⚠️ Just Outside';
              } else {
                badgeBg = const Color(0xFFFEF2F2);
                badgeFg = const Color(0xFFC0392B);
                badgeText = '❌ Out of Range';
              }
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.getCardColor(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.getBorderColor(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(r['icon'], style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(r['city'],
                            style: AppTextStyles.dmSans(
                                size: 10.5,
                                weight: FontWeight.w800,
                                color: theme.getTextColor(context))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(CurrencyFormatter.compact(price, symbol: 'NZ\$'),
                        style: AppTextStyles.dmSans(
                            size: 13,
                            weight: FontWeight.w800,
                            color: const Color(0xFF1A6B4A))),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(badgeText,
                          style: AppTextStyles.dmSans(
                              size: 8.5,
                              weight: FontWeight.w700,
                              color: badgeFg)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          // Monthly Budget Breakdown Card
          const SizedBox(height: 20),
          Text('Monthly Budget Breakdown',
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
                Text('Monthly Budget Plan',
                    style: AppTextStyles.dmSans(
                        size: 12,
                        weight: FontWeight.w800,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 10),
                _buildBudgetRow(
                    '💼 Net Monthly Income (est.)',
                    '\$${netMo.toStringAsFixed(0)}/mo',
                    '',
                    const Color(0xFF1A6B4A),
                    theme),
                _buildBudgetRow(
                    '🏠 Mortgage Repayment',
                    '-\$${monthly.toStringAsFixed(0)}',
                    '${mortPct.toStringAsFixed(0)}% of net',
                    const Color(0xFFC0392B),
                    theme),
                _buildBudgetRow(
                    '💳 Debt Repayments',
                    '-\$${_debts.toStringAsFixed(0)}',
                    '${(netMo > 0 ? (_debts / netMo * 100) : 0).toStringAsFixed(0)}% of net',
                    const Color(0xFFC0392B),
                    theme),
                _buildBudgetRow(
                    '🛒 Living Expenses',
                    '-\$${_expenses.toStringAsFixed(0)}',
                    '${(netMo > 0 ? (_expenses / netMo * 100) : 0).toStringAsFixed(0)}% of net',
                    const Color(0xFFC0392B),
                    theme),
                const Divider(),
                _buildBudgetRow(
                    '✅ Remaining / Savings',
                    '\$${remaining.toStringAsFixed(0)}',
                    '${remPct.toStringAsFixed(0)}% of net',
                    const Color(0xFF1A6B4A),
                    theme),
              ],
            ),
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
                    Text('💾 Save affordability report',
                        style: AppTextStyles.dmSans(
                            size: 11,
                            weight: FontWeight.w800,
                            color: theme.getTextColor(context))),
                    Text('Income & budget snapshot saved',
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

  bool get _isMonthlyView => false; // Dummy to compile smoothly

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
                  size: 12.5, weight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildHealthBar(String label, double pct, String displayVal,
      Color color, String subtitle, CountryTheme theme) {
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
            Text(displayVal,
                style: AppTextStyles.dmSans(
                    size: 11, weight: FontWeight.w800, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 12,
          decoration: BoxDecoration(
              color: theme.getBgColor(context),
              borderRadius: BorderRadius.circular(6)),
          child: Row(
            children: [
              Container(
                width: max(
                    0.0,
                    pct.clamp(0.0, 100.0) /
                        100.0 *
                        200.0), // Approximate slider width scaling
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Text(subtitle,
            style: AppTextStyles.dmSans(
                size: 9, color: theme.getMutedColor(context))),
      ],
    );
  }

  Widget _buildBudgetRow(String iconLabel, String amount, String pctText,
      Color color, CountryTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(iconLabel,
              style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.w700,
                  color: theme.getTextColor(context))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount,
                  style: AppTextStyles.dmSans(
                      size: 12, weight: FontWeight.w800, color: color)),
              if (pctText.isNotEmpty)
                Text(pctText,
                    style: AppTextStyles.dmSans(
                        size: 9.5, color: theme.getMutedColor(context))),
            ],
          ),
        ],
      ),
    );
  }
}
