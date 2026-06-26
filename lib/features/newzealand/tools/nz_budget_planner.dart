// lib/features/newzealand/tools/nz_budget_planner.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZBudgetPlanner extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZBudgetPlanner({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZBudgetPlanner> createState() => _NZBudgetPlannerState();
}

class _NZBudgetPlannerState extends ConsumerState<NZBudgetPlanner> {
  final _incomeController = TextEditingController(text: '5500');
  final _income2Controller = TextEditingController(text: '0');

  final _housingController = TextEditingController(text: '2100');
  final _foodController = TextEditingController(text: '900');
  final _transportController = TextEditingController(text: '450');
  final _utilitiesController = TextEditingController(text: '280');
  final _entertainController = TextEditingController(text: '300');
  final _healthController = TextEditingController(text: '200');
  final _debtController = TextEditingController(text: '0');
  final _otherController = TextEditingController(text: '150');

  final bool _showResults = true;

  @override
  void dispose() {
    _incomeController.dispose();
    _income2Controller.dispose();
    _housingController.dispose();
    _foodController.dispose();
    _transportController.dispose();
    _utilitiesController.dispose();
    _entertainController.dispose();
    _healthController.dispose();
    _debtController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  void _saveCalculation(
    double totalInc,
    double totalExp,
    double surplus,
    double housingPct,
  ) async {
    final labelCtrl = TextEditingController(text: 'NZ Budget Planner');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Budget Plan',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Income: ${CurrencyFormatter.compact(totalInc, symbol: 'NZ\$')} · Surplus: ${CurrencyFormatter.compact(surplus, symbol: 'NZ\$')} · Housing: ${housingPct.round()}%',
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
                hintText: 'Label (e.g. My Monthly Budget)',
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
          : 'Budget Planner';

      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'Budget Planner',
        inputs: {
          'income1': double.tryParse(_incomeController.text) ?? 5500,
          'income2': double.tryParse(_income2Controller.text) ?? 0,
          'housing': double.tryParse(_housingController.text) ?? 2100,
          'food': double.tryParse(_foodController.text) ?? 900,
          'transport': double.tryParse(_transportController.text) ?? 450,
          'utilities': double.tryParse(_utilitiesController.text) ?? 280,
          'entertain': double.tryParse(_entertainController.text) ?? 300,
          'health': double.tryParse(_healthController.text) ?? 200,
          'debt': double.tryParse(_debtController.text) ?? 0,
          'other': double.tryParse(_otherController.text) ?? 150,
        },
        results: {
          'totalIncome': totalInc,
          'totalExpenses': totalExp,
          'surplus': surplus,
          'housingPct': housingPct,
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Budget planner saved!',
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

    final double inc = double.tryParse(_incomeController.text) ?? 5500;
    final double inc2 = double.tryParse(_income2Controller.text) ?? 0;
    final double totalInc = inc + inc2;

    final double housing = double.tryParse(_housingController.text) ?? 2100;
    final double food = double.tryParse(_foodController.text) ?? 900;
    final double transport = double.tryParse(_transportController.text) ?? 450;
    final double utilities = double.tryParse(_utilitiesController.text) ?? 280;
    final double entertain = double.tryParse(_entertainController.text) ?? 300;
    final double health = double.tryParse(_healthController.text) ?? 200;
    final double debt = double.tryParse(_debtController.text) ?? 0;
    final double other = double.tryParse(_otherController.text) ?? 150;

    final double totalExpenses = housing + food + transport + utilities + entertain + health + debt + other;
    final double surplus = totalInc - totalExpenses;
    final double housingPct = totalInc > 0 ? (housing / totalInc * 100) : 0.0;

    final double lifestyle = food + entertain + transport;
    final double essentials = utilities + health + debt + other;

    final Color statusColor = housingPct > 35
        ? const Color(0xFFC0392B)
        : housingPct > 30
            ? const Color(0xFFD4A017)
            : const Color(0xFF1A6B4A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Budget Planner',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: theme.getTextColor(context),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                border: Border.all(color: const Color(0xFFA7F3D0)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'NZ 2025',
                style: AppTextStyles.dmSans(
                  size: 9,
                  color: const Color(0xFF065F46),
                  weight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Main input card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A0F0D), Color(0xFF0D3B2E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NZ BUDGET PLANNER · HOUSING COST VS INCOME',
                style: AppTextStyles.dmSans(
                  size: 8,
                  color: Colors.white70,
                  weight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  text: 'Plan Your ',
                  style: AppTextStyles.playfair(size: 16, weight: FontWeight.w800, color: Colors.white),
                  children: [
                    TextSpan(
                      text: 'Monthly Budget',
                      style: AppTextStyles.playfair(size: 16, weight: FontWeight.w800, color: const Color(0xFFF5D060)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MONTHLY TAKE-HOME INCOME (NZD)', style: AppTextStyles.dmSans(size: 8, color: Colors.white60, weight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.09),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: TextField(
                            controller: _incomeController,
                            keyboardType: TextInputType.number,
                            style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: Colors.white),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 11),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PARTNER PAY', style: AppTextStyles.dmSans(size: 8, color: Colors.white60, weight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.09),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: TextField(
                            controller: _income2Controller,
                            keyboardType: TextInputType.number,
                            style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: Colors.white),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 11),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20)),
                  child: Text('Monthly Expenses', style: AppTextStyles.dmSans(size: 8.5, color: Colors.white70, weight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🏠 MORTGAGE / RENT', style: AppTextStyles.dmSans(size: 8, color: Colors.white60, weight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.09),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _housingController,
                            keyboardType: TextInputType.number,
                            style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: Colors.white),
                            decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 9)),
                            onChanged: (_) => setState(() {}),
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
                        Text('🛒 FOOD & GROCERIES', style: AppTextStyles.dmSans(size: 8, color: Colors.white60, weight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.09),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _foodController,
                            keyboardType: TextInputType.number,
                            style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: Colors.white),
                            decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 9)),
                            onChanged: (_) => setState(() {}),
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
                        Text('🚗 TRANSPORT', style: AppTextStyles.dmSans(size: 8, color: Colors.white60, weight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.09),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _transportController,
                            keyboardType: TextInputType.number,
                            style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: Colors.white),
                            decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 9)),
                            onChanged: (_) => setState(() {}),
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
                        Text('💡 UTILITIES & POWER', style: AppTextStyles.dmSans(size: 8, color: Colors.white60, weight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.09),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _utilitiesController,
                            keyboardType: TextInputType.number,
                            style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: Colors.white),
                            decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 9)),
                            onChanged: (_) => setState(() {}),
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
                        Text('🎉 ENTERTAINMENT', style: AppTextStyles.dmSans(size: 8, color: Colors.white60, weight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.09),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _entertainController,
                            keyboardType: TextInputType.number,
                            style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: Colors.white),
                            decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 9)),
                            onChanged: (_) => setState(() {}),
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
                        Text('🏥 HEALTH & INSURANCE', style: AppTextStyles.dmSans(size: 8, color: Colors.white60, weight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.09),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _healthController,
                            keyboardType: TextInputType.number,
                            style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: Colors.white),
                            decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 9)),
                            onChanged: (_) => setState(() {}),
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
                        Text('💳 DEBT REPAYMENTS', style: AppTextStyles.dmSans(size: 8, color: Colors.white60, weight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.09),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _debtController,
                            keyboardType: TextInputType.number,
                            style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: Colors.white),
                            decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 9)),
                            onChanged: (_) => setState(() {}),
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
                        Text('📦 OTHER EXPENSES', style: AppTextStyles.dmSans(size: 8, color: Colors.white60, weight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.09),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _otherController,
                            keyboardType: TextInputType.number,
                            style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: Colors.white),
                            decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 9)),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Results Card
        if (_showResults) ...[
          Text(
            'Your Budget Analysis',
            style: AppTextStyles.playfair(
              size: 12,
              weight: FontWeight.w800,
              color: theme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              children: [
                // Housing cost gauge dial
                Column(
                  children: [
                    Text('Housing Cost as % of Income', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context))),
                    const SizedBox(height: 4),
                    Text(
                      '${housingPct.round()}%',
                      style: AppTextStyles.playfair(size: 38, weight: FontWeight.w800, color: statusColor),
                    ),
                    Text('NZ guideline: keep below 30–35%', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
                    if (housingPct > 30)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFFFFFBEB), border: Border.all(color: const Color(0xFFFDE68A)), borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          '⚠️ Your housing costs exceed the recommended 30% threshold. Consider refinancing or reducing discretionary spending to ease cash flow pressure.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF92400E), height: 1.4),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),

                // Donut and Legend Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 110,
                      width: 110,
                      child: CustomPaint(
                        painter: _NZBudgetDonutPainter(
                          housing: housing,
                          lifestyle: lifestyle,
                          essentials: essentials,
                          surplus: max(0.0, surplus),
                          total: totalInc,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Net', style: AppTextStyles.playfair(size: 11, weight: FontWeight.bold, color: theme.getTextColor(context))),
                              Text(
                                surplus >= 0
                                    ? '+${CurrencyFormatter.compact(surplus, symbol: '\$')}'
                                    : '-${CurrencyFormatter.compact(surplus.abs(), symbol: '\$')}',
                                style: AppTextStyles.playfair(
                                  size: 12,
                                  weight: FontWeight.bold,
                                  color: surplus >= 0 ? const Color(0xFF1A6B4A) : const Color(0xFFC0392B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _buildLegendRow(const Color(0xFFC0392B), 'Housing', CurrencyFormatter.compact(housing, symbol: 'NZ\$')),
                          _buildLegendRow(const Color(0xFFD4A017), 'Lifestyle', CurrencyFormatter.compact(lifestyle, symbol: 'NZ\$')),
                          _buildLegendRow(const Color(0xFF0D9488), 'Essentials', CurrencyFormatter.compact(essentials, symbol: 'NZ\$')),
                          _buildLegendRow(const Color(0xFF1A6B4A), 'Surplus', CurrencyFormatter.compact(surplus, symbol: 'NZ\$')),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Category list bars
                Column(
                  children: [
                    _buildCategoryRow('🏠', 'Housing / Mortgage', housing, totalInc, const Color(0xFFC0392B)),
                    _buildCategoryRow('🛒', 'Food & Groceries', food, totalInc, const Color(0xFFD97706)),
                    _buildCategoryRow('🚗', 'Transport', transport, totalInc, const Color(0xFF0D9488)),
                    _buildCategoryRow('💡', 'Utilities & Power', utilities, totalInc, const Color(0xFF0EA5E9)),
                    _buildCategoryRow('🎉', 'Entertainment', entertain, totalInc, const Color(0xFF6D28D9)),
                  ],
                ),
                const SizedBox(height: 14),

                // Surplus/deficit status card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: surplus >= 0 ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                    border: Border.all(color: surplus >= 0 ? const Color(0xFF6EE7B7) : const Color(0xFFFECACA)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        surplus >= 0 ? '✅ Budget Surplus' : '⚠️ Budget Deficit',
                        style: AppTextStyles.dmSans(
                          size: 12,
                          weight: FontWeight.bold,
                          color: surplus >= 0 ? const Color(0xFF065F46) : const Color(0xFFC0392B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        surplus >= 0
                            ? '+${CurrencyFormatter.compact(surplus, symbol: 'NZ\$')}'
                            : '-${CurrencyFormatter.compact(surplus.abs(), symbol: 'NZ\$')}',
                        style: AppTextStyles.playfair(
                          size: 28,
                          weight: FontWeight.w800,
                          color: surplus >= 0 ? const Color(0xFF1A6B4A) : const Color(0xFFC0392B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        surplus >= 0
                            ? 'You have money left over each month. Direct this to KiwiSaver, extra mortgage payments, or an emergency savings account.'
                            : 'Your expenses exceed income by ${CurrencyFormatter.compact(surplus.abs(), symbol: 'NZ\$')} per month. Review housing costs and discretionary lifestyle spending urgently.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.dmSans(
                          size: 9.5,
                          color: surplus >= 0 ? const Color(0xFF047857) : const Color(0xFFC0392B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                ElevatedButton.icon(
                  onPressed: () => _saveCalculation(totalInc, totalExpenses, surplus, housingPct),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: theme.primaryColor,
                    side: BorderSide(color: theme.primaryColor, width: 1.5),
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Text('💾', style: TextStyle(fontSize: 14)),
                  label: Text('Save Budget Analysis',
                      style: AppTextStyles.playfair(
                          size: 13, weight: FontWeight.w800, color: theme.primaryColor)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // NZ cost of living benchmarks
        Text(
          'NZ Cost of Living Benchmarks 2025',
          style: AppTextStyles.playfair(
            size: 12,
            weight: FontWeight.w800,
            color: theme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [
              _buildBenchmarkItem('🏠', 'Auckland Median Rent', '3-bedroom house, Auckland metro', '\$2,700/mo'),
              _buildBenchmarkItem('🏠', 'Wellington Median Rent', '3-bedroom house, Wellington city', '\$2,200/mo'),
              _buildBenchmarkItem('🛒', 'Grocery Budget (4 people)', 'Weekly grocery spend, NZ avg 2025', '\$250/wk'),
              _buildBenchmarkItem('💡', 'Power Bill (avg household)', 'Monthly electricity, Genesis/Mercury', '\$180/mo'),
              _buildBenchmarkItem('🚗', 'Petrol Cost (per tank)', '~50L tank, avg NZ price ~\$2.30/L', '\$115/fill'),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLegendRow(Color color, String label, String amount) {
    final theme = widget.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.dmSans(size: 10, weight: FontWeight.bold, color: theme.getTextColor(context)),
          ),
          const Spacer(),
          Text(
            amount,
            style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(String icon, String name, double value, double total, Color color) {
    final theme = widget.theme;
    final double pct = total > 0 ? (value / total) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.dmSans(size: 10, weight: FontWeight.bold, color: theme.getTextColor(context)),
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 7,
                    color: const Color(0xFFF1F5F2),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: pct,
                      child: Container(color: color),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            CurrencyFormatter.compact(value, symbol: 'NZ\$'),
            style: AppTextStyles.dmSans(size: 10, weight: FontWeight.bold, color: theme.getTextColor(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkItem(String icon, String title, String desc, String val) {
    final theme = widget.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.getBgColor(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.bold, color: theme.getTextColor(context)),
                ),
                Text(
                  desc,
                  style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)),
                ),
              ],
            ),
          ),
          Text(
            val,
            style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: theme.primaryColor),
          ),
        ],
      ),
    );
  }
}

class _NZBudgetDonutPainter extends CustomPainter {
  final double housing;
  final double lifestyle;
  final double essentials;
  final double surplus;
  final double total;

  _NZBudgetDonutPainter({
    required this.housing,
    required this.lifestyle,
    required this.essentials,
    required this.surplus,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 9;

    // Track
    final trackPaint = Paint()
      ..color = const Color(0xFFE8F0EC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18.0;

    canvas.drawCircle(center, radius, trackPaint);

    final double activeTotal = housing + lifestyle + essentials + surplus;
    if (activeTotal <= 0) return;

    final double housingPct = housing / activeTotal;
    final double lifestylePct = lifestyle / activeTotal;
    final double essentialsPct = essentials / activeTotal;
    final double surplusPct = surplus / activeTotal;

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18.0;

    double startAngle = -pi / 2;

    // Housing (Red)
    strokePaint.color = const Color(0xFFC0392B);
    final double housingSweep = housingPct * 2 * pi;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, housingSweep, false, strokePaint);
    startAngle += housingSweep;

    // Lifestyle (Gold)
    strokePaint.color = const Color(0xFFD4A017);
    final double lifestyleSweep = lifestylePct * 2 * pi;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, lifestyleSweep, false, strokePaint);
    startAngle += lifestyleSweep;

    // Essentials (Teal)
    strokePaint.color = const Color(0xFF0D9488);
    final double essentialsSweep = essentialsPct * 2 * pi;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, essentialsSweep, false, strokePaint);
    startAngle += essentialsSweep;

    // Surplus (Green)
    strokePaint.color = const Color(0xFF1A6B4A);
    final double surplusSweep = surplusPct * 2 * pi;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, surplusSweep, false, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _NZBudgetDonutPainter oldDelegate) {
    return oldDelegate.housing != housing ||
        oldDelegate.lifestyle != lifestyle ||
        oldDelegate.essentials != essentials ||
        oldDelegate.surplus != surplus ||
        oldDelegate.total != total;
  }
}
