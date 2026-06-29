// lib/features/newzealand/tools/nz_construction_loan.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZConstructionLoan extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZConstructionLoan({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZConstructionLoan> createState() => _NZConstructionLoanState();
}

class _NZConstructionLoanState extends ConsumerState<NZConstructionLoan> {
  final _landValController = TextEditingController(text: '400000');
  final _buildCostController = TextEditingController(text: '600000');
  final _depositController = TextEditingController(text: '200000');
  final _constRateController = TextEditingController(text: '7.45');
  final _endRateController = TextEditingController(text: '6.59');
  final _loanTermController = TextEditingController(text: '30');

  int _buildMonths = 12; // default 12 months
  int _activeStageIndex = 0;

  final List<Map<String, dynamic>> _stageData = [
    {'name': 'Slab / Foundation', 'icon': '🏗️', 'pct': 10.0},
    {'name': 'Frame', 'icon': '🪵', 'pct': 20.0},
    {'name': 'Lock-Up', 'icon': '🔐', 'pct': 25.0},
    {'name': 'Fit-Out', 'icon': '🔧', 'pct': 35.0},
    {'name': 'Completion (CCC)', 'icon': '✅', 'pct': 10.0},
  ];

  final bool _showResults = true;

  @override
  void dispose() {
    _landValController.dispose();
    _buildCostController.dispose();
    _depositController.dispose();
    _constRateController.dispose();
    _endRateController.dispose();
    _loanTermController.dispose();
    super.dispose();
  }

  double _pmt(double P, double annualRate, int months) {
    if (months <= 0) return 0;
    if (annualRate <= 0) return P / months;
    final double mr = (annualRate / 100) / 12;
    return P * mr * pow(1 + mr, months) / (pow(1 + mr, months) - 1);
  }

  void _saveCalculation(
    double totalLoan,
    double lvr,
    double buildInt,
    double finalPmt,
    double avgIntPmt,
    double totalCostBuild,
  ) async {
    final labelCtrl = TextEditingController(text: 'NZ Construction Loan');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/nz_construction_loan/save'),
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
              'Loan: ${CurrencyFormatter.compact(totalLoan, symbol: 'NZ\$')} · LVR: ${lvr.toStringAsFixed(1)}% · Final Pmt: ${CurrencyFormatter.compact(finalPmt, symbol: 'NZ\$')}/mo',
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
                hintText: 'Label (e.g. My Custom Build)',
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
          : 'Construction Loan';

      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'Construction Loan',
        inputs: {
          'landVal': double.tryParse(_landValController.text) ?? 400000,
          'buildCost': double.tryParse(_buildCostController.text) ?? 600000,
          'deposit': double.tryParse(_depositController.text) ?? 200000,
          'constRate': double.tryParse(_constRateController.text) ?? 7.45,
          'endRate': double.tryParse(_endRateController.text) ?? 6.59,
          'loanTerm': double.tryParse(_loanTermController.text) ?? 30,
          'buildMonths': _buildMonths.toDouble(),
        },
        results: {
          'totalLoan': totalLoan,
          'lvr': lvr,
          'buildInterest': buildInt,
          'finalPmt': finalPmt,
          'avgIntPmt': avgIntPmt,
          'totalCostBuild': totalCostBuild,
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Construction loan calculation saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF1A6B4A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    final double landVal = double.tryParse(_landValController.text) ?? 400000;
    final double buildCost = double.tryParse(_buildCostController.text) ?? 600000;
    final double deposit = double.tryParse(_depositController.text) ?? 200000;
    final double constRate = double.tryParse(_constRateController.text) ?? 7.45;
    final double endRate = double.tryParse(_endRateController.text) ?? 6.59;
    final int loanTerm = int.tryParse(_loanTermController.text) ?? 30;

    final double totalValue = landVal + buildCost;
    final double totalLoan = totalValue - deposit;
    final double lvr = totalValue > 0 ? (totalLoan / totalValue * 100) : 0.0;

    // Progressive drawdown calculations
    final int stageMonths = max(1, _buildMonths ~/ _stageData.length);
    double runningLoan = landVal;
    double totalBuildInt = 0.0;

    final List<Map<String, dynamic>> phases = [];
    final List<Map<String, dynamic>> tableRows = [];
    int monthCounter = 0;

    for (int i = 0; i < _stageData.length; i++) {
      final double pct = _stageData[i]['pct'];
      final double drawAmount = buildCost * pct / 100;
      runningLoan += drawAmount;
      final double monthInt = runningLoan * (constRate / 100) / 12;
      final int phaseDuration = i < _stageData.length - 1
          ? stageMonths
          : _buildMonths - stageMonths * (_stageData.length - 1);

      totalBuildInt += monthInt * phaseDuration;

      phases.add({
        'stage': _stageData[i]['name'],
        'drawn': runningLoan,
        'drawAmount': drawAmount,
        'monthInt': monthInt,
        'duration': phaseDuration,
      });

      for (int m = 0; m < phaseDuration; m++) {
        monthCounter++;
        tableRows.add({
          'stage': 'S${i + 1} Mo$monthCounter',
          'drawn': runningLoan,
          'month': monthCounter,
          'monthInt': monthInt,
        });
      }
    }

    final double avgIntPmt = _buildMonths > 0 ? totalBuildInt / _buildMonths : 0.0;
    final double finalPmt = _pmt(totalLoan, endRate, loanTerm * 12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Construction Loan Tool',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: theme.getTextColor(context),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                border: Border.all(color: const Color(0xFFFDE68A)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'NZ Standard',
                style: AppTextStyles.dmSans(
                  size: 9,
                  color: const Color(0xFFD4A017),
                  weight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Progressive Stages horizontal indicator track
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Row(
            children: List.generate(_stageData.length, (index) {
              final active = _activeStageIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeStageIndex = index),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: active
                          ? const LinearGradient(
                              colors: [Color(0xFFD4A017), Color(0xFF8B4513)],
                            )
                          : null,
                      borderRadius: index == 0
                          ? const BorderRadius.horizontal(left: Radius.circular(13))
                          : index == _stageData.length - 1
                              ? const BorderRadius.horizontal(right: Radius.circular(13))
                              : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${index + 1}',
                          style: AppTextStyles.dmSans(
                            size: 10,
                            weight: FontWeight.bold,
                            color: active ? Colors.white70 : theme.getMutedColor(context),
                          ),
                        ),
                        Text(
                          _stageData[index]['name'].split(' ').first,
                          style: AppTextStyles.dmSans(
                            size: 8.5,
                            weight: FontWeight.bold,
                            color: active ? Colors.white : theme.getTextColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),

        // Main Calculator Inputs
        Text(
          'Loan Details',
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
                  const Text('🏗️ ', style: TextStyle(fontSize: 16)),
                  Text(
                    'Construction Specs',
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
                        Text('LAND VALUE (NZD)', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        _buildInputBox(_landValController),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TOTAL BUILD COST (NZD)', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        _buildInputBox(_buildCostController),
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
                        Text('DEPOSIT / EQUITY (NZD)', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        _buildInputBox(_depositController),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CONSTRUCTION RATE (%)', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        _buildInputBox(_constRateController),
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
                        Text('END RATE (P&I RATE %)', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        _buildInputBox(_endRateController),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LOAN TERM (YRS)', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        _buildInputBox(_loanTermController),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text('ESTIMATED BUILD TIME', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
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
                    value: _buildMonths,
                    isExpanded: true,
                    dropdownColor: theme.getCardColor(context),
                    items: const [
                      DropdownMenuItem(value: 6, child: Text('6 months')),
                      DropdownMenuItem(value: 9, child: Text('9 months')),
                      DropdownMenuItem(value: 12, child: Text('12 months')),
                      DropdownMenuItem(value: 15, child: Text('15 months')),
                      DropdownMenuItem(value: 18, child: Text('18 months')),
                      DropdownMenuItem(value: 24, child: Text('24 months')),
                    ],
                    onChanged: (val) => setState(() => _buildMonths = val ?? 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Drawdown Customiser List
        Text(
          'Drawdown Stage Customiser',
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
          itemCount: _stageData.length,
          itemBuilder: (context, index) {
            final s = _stageData[index];
            final double amt = buildCost * s['pct'] / 100;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.getCardColor(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.getBorderColor(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${s['icon']} Stage ${index + 1}: ${s['name']}',
                        style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context)),
                      ),
                      Text(
                        '${s['pct'].round()}% · ${CurrencyFormatter.compact(amt, symbol: 'NZ\$')}',
                        style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: const Color(0xFFD4A017)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 8,
                      color: theme.getBgColor(context),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: s['pct'] / 100.0,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [Color(0xFFD4A017), Color(0xFF8B4513)]),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DRAWDOWN % OF BUILD', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
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
                                controller: TextEditingController(text: s['pct'].round().toString()),
                                onChanged: (val) {
                                  s['pct'] = double.tryParse(val) ?? 0.0;
                                  setState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('EST. AMOUNT (NZD)', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                            const SizedBox(height: 4),
                            Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.getBgColor(context).withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                CurrencyFormatter.compact(amt, symbol: 'NZ\$'),
                                style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w700, color: theme.getTextColor(context).withValues(alpha: 0.6)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),

        // Results Card
        if (_showResults) ...[
          Text(
            'Construction Loan Summary',
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
                colors: [Color(0xFF0A0F0D), Color(0xFF2C1A0E)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONSTRUCTION SUMMARY',
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
                    _buildResultBox('Total Loan Amount', CurrencyFormatter.compact(totalLoan, symbol: 'NZ\$'), 'Land + Build - Deposit', const Color(0xFFF5D060)),
                    _buildResultBox('LVR', '${lvr.toStringAsFixed(1)}%', 'Loan to Value Ratio', Colors.white),
                    _buildResultBox('Interest During Build', CurrencyFormatter.compact(totalBuildInt, symbol: 'NZ\$'), 'Interest-only phase', Colors.white),
                    _buildResultBox('Final Monthly Payment', CurrencyFormatter.compact(finalPmt, symbol: 'NZ\$'), 'P&I after completion', const Color(0xFF6EE7B7)),
                    _buildResultBox('Avg Interest-Only Pmt', CurrencyFormatter.compact(avgIntPmt, symbol: 'NZ\$'), 'During construction', Colors.white),
                    _buildResultBox('Total Cost of Build', CurrencyFormatter.compact(buildCost + totalBuildInt, symbol: 'NZ\$'), 'Build + build interest', Colors.white),
                  ],
                ),
                const SizedBox(height: 20),

                // Drawdown Chart
                Text(
                  'DRAWDOWN SCHEDULE',
                  style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w800, color: Colors.white60),
                ),
                const SizedBox(height: 10),
                ...phases.map((p) {
                  final pctOfLoan = totalLoan > 0 ? (p['drawn'] / totalLoan) : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(p['stage'], style: AppTextStyles.dmSans(size: 9, color: Colors.white70)),
                            Text(CurrencyFormatter.compact(p['drawAmount'], symbol: 'NZ\$'), style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.bold, color: const Color(0xFFF5D060))),
                          ],
                        ),
                        const SizedBox(height: 3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Container(
                            height: 9,
                            color: Colors.white.withValues(alpha: 0.08),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: min(1.0, pctOfLoan),
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(colors: [Color(0xFFD4A017), Color(0xFFF5D060)]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 14),

                ElevatedButton.icon(
                  onPressed: () => _saveCalculation(
                    totalLoan,
                    lvr,
                    totalBuildInt,
                    finalPmt,
                    avgIntPmt,
                    buildCost + totalBuildInt,
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
                    'Save Construction Loan Specs',
                    style: AppTextStyles.playfair(size: 13, weight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Monthly Interest During Build Table Card
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
                  '📅 Monthly Interest During Build',
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
                    1: FlexColumnWidth(1.1),
                    2: FlexColumnWidth(0.8),
                    3: FlexColumnWidth(1.1),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.getBorderColor(context)))),
                      children: [
                        _tableHeader('Stage Month'),
                        _tableHeader('Drawn'),
                        _tableHeader('Month #'),
                        _tableHeader('Monthly Int'),
                      ],
                    ),
                    ...tableRows.map((r) {
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(r['stage'], style: AppTextStyles.dmSans(size: 10, color: theme.getTextColor(context))),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(CurrencyFormatter.compact(r['drawn'], symbol: 'NZ\$'), style: AppTextStyles.dmSans(size: 10, color: theme.getTextColor(context))),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text('${r['month']}', style: AppTextStyles.dmSans(size: 10, color: theme.getTextColor(context))),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              CurrencyFormatter.compact(r['monthInt'], symbol: 'NZ\$'),
                              style: AppTextStyles.dmSans(size: 10, weight: FontWeight.bold, color: const Color(0xFFD4A017)),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // NZ construction process steps card
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
                '🇳🇿 NZ Construction Loan Process',
                style: AppTextStyles.playfair(
                  size: 14,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 14),
              _buildStepItem(1, 'Land Purchase → Slab (10–15%)', 'First drawdown covers land or foundation. Interest-only charged on drawn balance. Bank releases funds after sign-off.'),
              _buildStepItem(2, 'Frame Completed (20–25%)', 'Wall frames and roof trusses are built. Valuation inspects progress before the next payment release.'),
              _buildStepItem(3, 'Lock-Up Phase (20–25%)', 'Windows, roofing, cladding fitted. Building secure from weather. Bank makes third progress payment.'),
              _buildStepItem(4, 'Fit-Out / Fixing (25–30%)', 'Plumbing, electrical, plastering, internal doors, kitchen cabinets. Largest stage - monitor drawdowns.'),
              _buildStepItem(5, 'Practical Completion (5–10%)', 'Council issues Code Compliance Certificate (CCC). Final funds released. Loan switches to standard P&I mortgage.'),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildResultBox(String title, String val, String sub, Color valColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
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
            style: AppTextStyles.dmSans(size: 14.5, weight: FontWeight.w800, color: valColor),
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

  Widget _buildStepItem(int num, String title, String desc) {
    final theme = widget.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD4A017), Color(0xFF8B4513)],
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '$num',
              style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.dmSans(
                      size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context)),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: AppTextStyles.dmSans(
                      size: 9.5, color: theme.getMutedColor(context), height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
}
