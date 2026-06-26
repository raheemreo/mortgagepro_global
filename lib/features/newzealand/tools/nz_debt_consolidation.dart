// lib/features/newzealand/tools/nz_debt_consolidation.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZDebtConsolidation extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZDebtConsolidation({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZDebtConsolidation> createState() => _NZDebtConsolidationState();
}

class _NZDebtConsolidationState extends ConsumerState<NZDebtConsolidation> {
  // Mortgage Controllers
  final _mortBalController = TextEditingController(text: '420000');
  final _mortRateController = TextEditingController(text: '6.59');
  final _mortTermController = TextEditingController(text: '25');
  final _newRateController = TextEditingController(text: '6.59');

  int _consTerm = 25; // default consolidation term

  // Short term debts list
  final List<Map<String, dynamic>> _debts = [
    {'name': 'Credit Card', 'icon': '💳', 'balance': 8000.0, 'rate': 21.5, 'term': 3},
    {'name': 'Personal Loan', 'icon': '🏦', 'balance': 15000.0, 'rate': 14.5, 'term': 4},
    {'name': 'Car Loan', 'icon': '🚗', 'balance': 18000.0, 'rate': 11.5, 'term': 5},
  ];

  final bool _showResults = true;

  @override
  void dispose() {
    _mortBalController.dispose();
    _mortRateController.dispose();
    _mortTermController.dispose();
    _newRateController.dispose();
    super.dispose();
  }

  double _pmt(double P, double annualRate, int months) {
    if (months <= 0) return 0;
    if (annualRate <= 0) return P / months;
    final double mr = (annualRate / 100) / 12;
    return P * mr * pow(1 + mr, months) / (pow(1 + mr, months) - 1);
  }

  void _addDebt() {
    setState(() {
      _debts.add({
        'name': 'Other Debt',
        'icon': '💰',
        'balance': 5000.0,
        'rate': 15.0,
        'term': 3,
      });
    });
  }

  void _removeDebt(int index) {
    setState(() {
      _debts.removeAt(index);
    });
  }

  void _saveCalculation(
    double totalDebt,
    double currentPmt,
    double newPmt,
    double cfRelief,
    double interestSep,
    double interestCons,
  ) async {
    final labelCtrl = TextEditingController(text: 'NZ Debt Consolidation');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Consolidation',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consolidated: ${CurrencyFormatter.compact(totalDebt, symbol: 'NZ\$')} · Relief: ${CurrencyFormatter.compact(cfRelief, symbol: 'NZ\$')}/mo · Net saving: ${CurrencyFormatter.compact(interestSep - interestCons, symbol: 'NZ\$')}',
              style: AppTextStyles.dmSans(
                  size: 11, color: widget.theme.getMutedColor(context)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My Consolidation Plan)',
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
          : 'Debt Consolidation';

      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'Debt Consolidation',
        inputs: {
          'mortBal': double.tryParse(_mortBalController.text) ?? 420000,
          'mortRate': double.tryParse(_mortRateController.text) ?? 6.59,
          'newRate': double.tryParse(_newRateController.text) ?? 6.59,
          'consTerm': _consTerm.toDouble(),
          'debtsCount': _debts.length.toDouble(),
        },
        results: {
          'consolidatedDebtsAmt': totalDebt,
          'currentMonthlyPmt': currentPmt,
          'newMonthlyPmt': newPmt,
          'cashFlowRelief': cfRelief,
          'interestSeparate': interestSep,
          'interestConsolidated': interestCons,
          'netSavings': interestSep - interestCons,
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Consolidation assessment saved!',
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

    final double mortBal = double.tryParse(_mortBalController.text) ?? 420000;
    final double mortRate = double.tryParse(_mortRateController.text) ?? 6.59;
    final int mortTerm = int.tryParse(_mortTermController.text) ?? 25;
    final double newRate = double.tryParse(_newRateController.text) ?? 6.59;

    // Calculations
    final double mortPmt = _pmt(mortBal, mortRate, mortTerm * 12);
    double totalDebtsBalance = 0;
    double currentDebtPmts = 0;
    double debtInterestTotal = 0;

    for (var d in _debts) {
      final double bal = d['balance'] ?? 0;
      final double r = d['rate'] ?? 0;
      final int t = d['term'] ?? 1;
      final double p = _pmt(bal, r, t * 12);
      totalDebtsBalance += bal;
      currentDebtPmts += p;
      debtInterestTotal += (p * t * 12) - bal;
    }

    final double totalCurrentBal = mortBal + totalDebtsBalance;
    final double newPmt = _pmt(totalCurrentBal, newRate, _consTerm * 12);
    final double totalIntCons = (newPmt * _consTerm * 12) - totalCurrentBal;
    final double mortIntOrig = (mortPmt * mortTerm * 12) - mortBal;
    final double totalIntSep = mortIntOrig + debtInterestTotal;
    final double cfRelief = (mortPmt + currentDebtPmts) - newPmt;
    final double netSavings = totalIntSep - totalIntCons;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Debt Consolidation Tool',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: theme.getTextColor(context),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                border: Border.all(color: const Color(0xFFFECACA)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Debt Payoff',
                style: AppTextStyles.dmSans(
                  size: 9,
                  color: const Color(0xFFC0392B),
                  weight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Warning Note Banner
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
            ),
            border: Border.all(color: const Color(0xFFF59E0B)),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consolidation Considerations',
                      style: AppTextStyles.dmSans(
                          size: 12.5,
                          weight: FontWeight.w800,
                          color: const Color(0xFF92400E)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rolling short-term debts into a 25-30 year mortgage can dramatically increase total interest paid, even at a lower rate. Always compare total cost, not just monthly repayments. Consider a shorter consolidation term.',
                      style: AppTextStyles.dmSans(
                          size: 9.5,
                          color: const Color(0xFFB45309),
                          height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Short-term Debts Section
        Text(
          'Your Current Debts',
          style: AppTextStyles.playfair(
            size: 12,
            weight: FontWeight.w800,
            color: theme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _debts.length,
          itemBuilder: (context, index) {
            final d = _debts[index];
            final double r = d['rate'] ?? 0;
            String rateBand = 'Low Cost';
            Color bandColor = const Color(0xFF065F46);
            Color bandBg = const Color(0xFFECFDF5);
            if (r > 18) {
              rateBand = 'High Cost';
              bandColor = const Color(0xFFC0392B);
              bandBg = const Color(0xFFFEF2F2);
            } else if (r > 11) {
              rateBand = 'Medium';
              bandColor = const Color(0xFFC2410C);
              bandBg = const Color(0xFFFFF7ED);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.getCardColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.getBorderColor(context)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(d['icon'] ?? '💰', style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            d['name'] ?? 'Debt',
                            style: AppTextStyles.dmSans(
                                size: 12, weight: FontWeight.w800, color: theme.getTextColor(context)),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => _removeDebt(index),
                        icon: const Icon(Icons.close, size: 16, color: Color(0xFFC0392B)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('BALANCE (NZD)', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 36,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w700, color: theme.getTextColor(context)),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: theme.getBgColor(context),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                controller: TextEditingController(text: d['balance'].round().toString()),
                                onChanged: (val) {
                                  d['balance'] = double.tryParse(val) ?? 0.0;
                                  setState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('RATE (%)', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 36,
                              child: TextField(
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w700, color: theme.getTextColor(context)),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: theme.getBgColor(context),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                controller: TextEditingController(text: d['rate'].toString()),
                                onChanged: (val) {
                                  d['rate'] = double.tryParse(val) ?? 0.0;
                                  setState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TERM (YRS)', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 36,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w700, color: theme.getTextColor(context)),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: theme.getBgColor(context),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                controller: TextEditingController(text: d['term'].toString()),
                                onChanged: (val) {
                                  d['term'] = int.tryParse(val) ?? 1;
                                  setState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: bandBg, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        '${d['rate']}% — $rateBand',
                        style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: bandColor),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Add debt button
        OutlinedButton(
          onPressed: _addDebt,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF1A6B4A)),
            minimumSize: const Size(double.infinity, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(
            '+ Add Another Debt',
            style: AppTextStyles.playfair(
                size: 12, weight: FontWeight.w800, color: const Color(0xFF1A6B4A)),
          ),
        ),
        const SizedBox(height: 16),

        // Mortgage details
        Text(
          'Mortgage & Consolidation Details',
          style: AppTextStyles.playfair(
            size: 12,
            weight: FontWeight.w800,
            color: theme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 8),
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
              Row(
                children: [
                  const Text('🏠 ', style: TextStyle(fontSize: 16)),
                  Text(
                    'Consolidation Setup',
                    style: AppTextStyles.playfair(
                      size: 13,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CURRENT MORTGAGE BAL', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        _buildInputBox(_mortBalController),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MORTGAGE RATE (%)', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        _buildInputBox(_mortRateController),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('REMAINING TERM (YRS)', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        _buildInputBox(_mortTermController),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NEW CONSOLIDATED RATE (%)', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        _buildInputBox(_newRateController),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text('CONSOLIDATION TERM', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
              const SizedBox(height: 6),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.getBgColor(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _consTerm,
                    isExpanded: true,
                    dropdownColor: theme.getCardColor(context),
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('5 years (Recommended — saves most interest)')),
                      DropdownMenuItem(value: 10, child: Text('10 years')),
                      DropdownMenuItem(value: 15, child: Text('15 years')),
                      DropdownMenuItem(value: 20, child: Text('20 years')),
                      DropdownMenuItem(value: 25, child: Text('25 years (existing term)')),
                      DropdownMenuItem(value: 30, child: Text('30 years')),
                    ],
                    onChanged: (val) => setState(() => _consTerm = val ?? 25),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Results Card
        if (_showResults) ...[
          Text(
            'Consolidation Analysis',
            style: AppTextStyles.playfair(
              size: 12,
              weight: FontWeight.w800,
              color: theme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A0F0D), Color(0xFF7B1919)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONSOLIDATION SUMMARY',
                  style: AppTextStyles.dmSans(
                      size: 8, weight: FontWeight.w800, color: Colors.white54, letterSpacing: 0.5),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.7,
                  children: [
                    _buildResultBox('Total Short-Term Debts', CurrencyFormatter.compact(totalDebtsBalance, symbol: 'NZ\$'), 'All debts combined', false, false),
                    _buildResultBox('Current Monthly Payments', CurrencyFormatter.compact(mortPmt + currentDebtPmts, symbol: 'NZ\$'), 'All debts + mortgage', false, false),
                    _buildResultBox('New Monthly Payment', CurrencyFormatter.compact(newPmt, symbol: 'NZ\$'), 'Consolidated amount', true, false),
                    _buildResultBox('Monthly Cash Flow Relief', CurrencyFormatter.compact(cfRelief, symbol: 'NZ\$'), 'Saved per month', true, cfRelief > 0),
                    _buildResultBox('Total Interest (Separate)', CurrencyFormatter.compact(totalIntSep, symbol: 'NZ\$'), 'Original terms', false, false),
                    _buildResultBox('Total Interest (Consolidated)', CurrencyFormatter.compact(totalIntCons, symbol: 'NZ\$'), 'Over new term', false, false),
                  ],
                ),
                const SizedBox(height: 20),

                // Comparison bars
                Text(
                  'COMPARE PAYMENTS & INTEREST',
                  style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w800, color: Colors.white60),
                ),
                const SizedBox(height: 10),
                _buildCompareBar('Current Monthly Pmt', mortPmt + currentDebtPmts, max(mortPmt + currentDebtPmts, newPmt), const Color(0xFFFCA5A5)),
                const SizedBox(height: 8),
                _buildCompareBar('New Monthly Pmt', newPmt, max(mortPmt + currentDebtPmts, newPmt), const Color(0xFF6EE7B7)),
                const SizedBox(height: 12),
                _buildCompareBar('Interest Separate', totalIntSep, max(totalIntSep, totalIntCons), const Color(0xFFFCA5A5)),
                const SizedBox(height: 8),
                _buildCompareBar('Interest Consolidated', totalIntCons, max(totalIntSep, totalIntCons), const Color(0xFF6EE7B7)),
                const SizedBox(height: 20),

                // Verdict Box
                _buildVerdictBox(netSavings),
                const SizedBox(height: 14),

                ElevatedButton.icon(
                  onPressed: () => _saveCalculation(
                    totalDebtsBalance,
                    mortPmt + currentDebtPmts,
                    newPmt,
                    cfRelief,
                    totalIntSep,
                    totalIntCons,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                  icon: const Text('💾', style: TextStyle(fontSize: 14)),
                  label: Text(
                    'Save Consolidation Analysis',
                    style: AppTextStyles.playfair(size: 13, weight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Debt-by-debt table card
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
                Text(
                  '📊 Debt-by-Debt Breakdown',
                  style: AppTextStyles.playfair(
                    size: 13,
                    weight: FontWeight.w800,
                    color: theme.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 12),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1.2),
                    1: FlexColumnWidth(1.0),
                    2: FlexColumnWidth(0.8),
                    3: FlexColumnWidth(1.0),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.getBorderColor(context)))),
                      children: [
                        _tableHeader('Debt'),
                        _tableHeader('Balance'),
                        _tableHeader('Rate'),
                        _tableHeader('Monthly Pmt'),
                      ],
                    ),
                    ..._debts.map((d) {
                      final double bal = d['balance'] ?? 0;
                      final double r = d['rate'] ?? 0;
                      final int t = d['term'] ?? 1;
                      final double p = _pmt(bal, r, t * 12);
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text('${d['icon']} ${d['name']}', style: AppTextStyles.dmSans(size: 10, color: theme.getTextColor(context))),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(CurrencyFormatter.compact(bal, symbol: 'NZ\$'), style: AppTextStyles.dmSans(size: 10, color: theme.getTextColor(context))),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text('$r%', style: AppTextStyles.dmSans(size: 10, color: theme.getTextColor(context))),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text('${CurrencyFormatter.compact(p, symbol: 'NZ\$')}/mo', style: AppTextStyles.dmSans(size: 10, color: theme.getTextColor(context))),
                          ),
                        ],
                      );
                    }),
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text('🏠 Mortgage', style: AppTextStyles.dmSans(size: 10, color: theme.getTextColor(context))),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(CurrencyFormatter.compact(mortBal, symbol: 'NZ\$'), style: AppTextStyles.dmSans(size: 10, color: theme.getTextColor(context))),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text('$mortRate%', style: AppTextStyles.dmSans(size: 10, color: theme.getTextColor(context))),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text('${CurrencyFormatter.compact(mortPmt, symbol: 'NZ\$')}/mo', style: AppTextStyles.dmSans(size: 10, color: theme.getTextColor(context))),
                        ),
                      ],
                    ),
                    TableRow(
                      decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.getTextColor(context), width: 1.5))),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text('TOTAL', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: theme.getTextColor(context))),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(CurrencyFormatter.compact(totalCurrentBal, symbol: 'NZ\$'), style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: theme.getTextColor(context))),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('—', style: TextStyle(fontSize: 10)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '${CurrencyFormatter.compact(mortPmt + currentDebtPmts, symbol: 'NZ\$')}/mo',
                            style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: theme.primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildResultBox(String title, String val, String sub, bool highlight, bool pos) {
    Color valColor = Colors.white;
    Color bg = Colors.white.withValues(alpha: 0.09);
    Color border = Colors.white.withValues(alpha: 0.14);

    if (highlight) {
      if (pos) {
        valColor = const Color(0xFF6EE7B7);
        bg = const Color(0xFF166534).withValues(alpha: 0.25);
        border = const Color(0xFF6EE7B7).withValues(alpha: 0.4);
      } else {
        valColor = const Color(0xFFFCA5A5);
        bg = const Color(0xFF991B1B).withValues(alpha: 0.25);
        border = const Color(0xFFFCA5A5).withValues(alpha: 0.4);
      }
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.dmSans(size: 7.5, color: Colors.white60, weight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: AppTextStyles.dmSans(
                size: 14.5,
                weight: FontWeight.w800,
                color: valColor),
          ),
          const SizedBox(height: 1),
          Text(
            sub,
            style: AppTextStyles.dmSans(size: 8, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildCompareBar(String label, double val, double maxVal, Color color) {
    final pct = maxVal > 0 ? val / maxVal : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 9, color: Colors.white70)),
            Text(CurrencyFormatter.compact(val, symbol: 'NZ\$'), style: AppTextStyles.dmSans(size: 9, weight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Container(
            height: 10,
            color: Colors.white.withValues(alpha: 0.08),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct,
              child: Container(color: color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerdictBox(double netSavings) {
    if (netSavings > 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          border: Border.all(color: const Color(0xFFA7F3D0)),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            const Text('✅', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saves ${CurrencyFormatter.compact(netSavings, symbol: 'NZ\$')} in interest',
                    style: AppTextStyles.dmSans(
                        size: 12, weight: FontWeight.w800, color: const Color(0xFF065F46)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Consolidation reduces total interest over the loan term. Consider a shorter term to maximise savings.',
                    style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF4A6358)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          border: Border.all(color: const Color(0xFFFECACA)),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Costs ${CurrencyFormatter.compact(-netSavings, symbol: 'NZ\$')} MORE in interest',
                    style: AppTextStyles.dmSans(
                        size: 12, weight: FontWeight.w800, color: const Color(0xFF991B1B)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'A shorter consolidation term or keeping debts separate may be better. Consult a mortgage adviser.',
                    style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF4A6358)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.dmSans(
          size: 8.5,
          weight: FontWeight.bold,
          color: widget.theme.getMutedColor(context),
        ),
      ),
    );
  }

  Widget _buildInputBox(TextEditingController controller) {
    final theme = widget.theme;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: theme.getBgColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: AppTextStyles.dmSans(
            size: 14, weight: FontWeight.w700, color: theme.getTextColor(context)),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}
