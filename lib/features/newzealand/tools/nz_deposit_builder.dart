// lib/features/newzealand/tools/nz_deposit_builder.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZDepositBuilder extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZDepositBuilder({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZDepositBuilder> createState() => _NZDepositBuilderState();
}

class _NZDepositBuilderState extends ConsumerState<NZDepositBuilder> {
  double _targetProp = 750000;
  double _depPct = 20;
  double _curSavings = 50000;
  double _kiwiBalance = 25000;
  double _monthlySavings = 2000;
  double _savRate = 5.0;
  double _kiwiRate = 6.5;

  bool _showResults = false;
  String _selectedGoalName = 'Owner-Occ (Standard)';

  final List<Map<String, dynamic>> _goals = [
    {
      'icon': '🏠',
      'name': 'Owner-Occ',
      'pct': 20.0,
      'label': 'Owner-Occ (Standard)'
    },
    {'icon': '🏘️', 'name': 'Investor', 'pct': 35.0, 'label': 'Investor'},
    {
      'icon': '⚡',
      'name': 'Low Equity',
      'pct': 10.0,
      'label': 'Low Equity (LEM)'
    },
    {'icon': '🥝', 'name': 'Kāinga Ora', 'pct': 5.0, 'label': 'Kāinga Ora FHP'},
  ];

  void _reset() {
    setState(() {
      _targetProp = 750000;
      _depPct = 20;
      _curSavings = 50000;
      _kiwiBalance = 25000;
      _monthlySavings = 2000;
      _savRate = 5.0;
      _kiwiRate = 6.5;
      _selectedGoalName = 'Owner-Occ (Standard)';
      _showResults = false;
    });
  }

  void _saveCalculation(double targetDep, double totalAvailable, int months,
      double totalInterest) async {
    final labelCtrl =
        TextEditingController(text: 'NZ Deposit Build: $_selectedGoalName');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/nz_deposit_builder'),
      builder: (context) {
        return AlertDialog(
          backgroundColor: widget.theme.getCardColor(context),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('💾 Save Savings Plan',
              style: AppTextStyles.playfair(
                  size: 16, color: widget.theme.getTextColor(context))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saving: ${CurrencyFormatter.compact(targetDep, symbol: 'NZ\$')} target. Saved ${CurrencyFormatter.compact(totalAvailable, symbol: 'NZ\$')} so far.',
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
                  hintText: 'Label (e.g. Auckland House Deposit)',
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
        );
      },
    );

    if (confirmed == true && mounted) {
      final label = labelCtrl.text;
      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'Deposit Builder',
        inputs: {
          'targetProp': _targetProp,
          'depPct': _depPct,
          'curSavings': _curSavings,
          'kiwiBalance': _kiwiBalance,
          'monthlySavings': _monthlySavings,
          'savRate': _savRate,
        },
        results: {
          'targetDeposit': targetDep,
          'currentSaved': totalAvailable,
          'months': months.toDouble(),
          'interestEarned': totalInterest,
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Savings plan saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF1A6B4A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _addMonths(int months) {
    final d = DateTime.now();
    final newDate = DateTime(d.year, d.month + months, d.day);
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${monthNames[newDate.month - 1]} ${newDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    // Calculations
    final targetDep = _targetProp * _depPct / 100;
    final totalAvailable = _curSavings + _kiwiBalance;
    final shortfall = max(0.0, targetDep - totalAvailable);

    // Calculate compound timeline
    final r = _savRate / 100 / 12;
    double bal = totalAvailable;
    int months = 0;
    double totalInterest = 0;

    while (bal < targetDep && months < 600) {
      bal += _monthlySavings;
      final interest = bal * r;
      bal += interest;
      totalInterest += interest;
      months++;
    }

    final progressPct = targetDep > 0
        ? (totalAvailable / targetDep * 100).clamp(0.0, 100.0)
        : 0.0;

    // Milestone calculations (25%, 50%, 75%, 100%)
    final milestones = [25, 50, 75, 100].map((p) {
      final goalAmt = targetDep * p / 100;
      double b = totalAvailable;
      int mo = 0;
      while (b < goalAmt && mo < 600) {
        b += _monthlySavings;
        b += b * r;
        mo++;
      }
      return {
        'pct': p,
        'amount': goalAmt,
        'months': mo,
        'date': _addMonths(mo),
      };
    }).toList();

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Rate Strip
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                    child: _buildRateStripCell(
                        '20% Dep.', 'Owner', 'Min required')),
                _buildDivider(),
                Expanded(
                    child: _buildRateStripCell(
                        '35% Dep.', 'Investor', 'Min required')),
                _buildDivider(),
                Expanded(
                    child: _buildRateStripCell(
                        'Savings', '5.50%', 'Term deposit')),
                _buildDivider(),
                Expanded(
                    child: _buildRateStripCell(
                        'KiwiSaver', '✓ Use', '3yr+ eligible',
                        isGold: true)),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Deposit Goal Selector
          Text('Deposit Goal',
              style: AppTextStyles.dmSans(
                  size: 11,
                  color: theme.getMutedColor(context),
                  weight: FontWeight.w800)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _goals.map((g) {
                final isSelected = _selectedGoalName == g['label'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedGoalName = g['label'];
                      _depPct = g['pct'];
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFECFDF5)
                          : theme.getCardColor(context),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1A6B4A)
                              : theme.getBorderColor(context),
                          width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(g['icon'], style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(
                          g['name'],
                          style: AppTextStyles.dmSans(
                            size: 10,
                            weight: FontWeight.w700,
                            color: isSelected
                                ? const Color(0xFF1A6B4A)
                                : theme.getTextColor(context),
                          ),
                        ),
                        Text(
                          '${g['pct'].toInt()}%',
                          style: AppTextStyles.dmSans(
                              size: 11,
                              weight: FontWeight.w800,
                              color: const Color(0xFF1A6B4A)),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),

          // Savings Details Inputs Card
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
                    Text('🏦 Your Savings Details',
                        style: AppTextStyles.playfair(
                            size: 15,
                            color: theme.getTextColor(context),
                            weight: FontWeight.w800)),
                    GestureDetector(
                      onTap: _reset,
                      child: Text('Reset ↺',
                          style: AppTextStyles.dmSans(
                              size: 11,
                              color: const Color(0xFF1A6B4A),
                              weight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildNumericField(
                        label: 'Target Property (NZD)',
                        value: _targetProp,
                        onChanged: (val) => setState(() => _targetProp = val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildNumericField(
                        label: 'Deposit Target %',
                        value: _depPct,
                        isPercent: true,
                        onChanged: (val) => setState(() => _depPct = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildNumericField(
                        label: 'Current Savings (NZD)',
                        value: _curSavings,
                        onChanged: (val) => setState(() => _curSavings = val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildNumericField(
                        label: 'KiwiSaver Balance',
                        value: _kiwiBalance,
                        onChanged: (val) => setState(() => _kiwiBalance = val),
                        subtitle: 'Withdraw after 3+ years',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Monthly Savings Contribution Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('MONTHLY SAVINGS CONTRIBUTION',
                        style: AppTextStyles.dmSans(
                            size: 9,
                            color: theme.getMutedColor(context),
                            weight: FontWeight.w700)),
                    Text(
                        CurrencyFormatter.format(_monthlySavings,
                            currencyCode: 'NZD'),
                        style: AppTextStyles.dmSans(
                            size: 12,
                            color: theme.getTextColor(context),
                            weight: FontWeight.w800)),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: const Color(0xFF1A6B4A),
                    inactiveTrackColor: theme.getBgColor(context),
                    thumbColor: const Color(0xFF1A6B4A),
                    overlayColor:
                        const Color(0xFF1A6B4A).withValues(alpha: 0.12),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    min: 200,
                    max: 10000,
                    divisions: 98,
                    value: _monthlySavings,
                    onChanged: (val) => setState(
                        () => _monthlySavings = (val / 100).round() * 100.0),
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildNumericField(
                        label: 'Savings Interest Rate %',
                        value: _savRate,
                        isPercent: true,
                        onChanged: (val) => setState(() => _savRate = val),
                        subtitle: 'NZ TDs ~5.5% p.a.',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildNumericField(
                        label: 'KiwiSaver Growth %',
                        value: _kiwiRate,
                        isPercent: true,
                        onChanged: (val) => setState(() => _kiwiRate = val),
                        subtitle: 'Balanced fund avg.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: () {
                    if (_targetProp <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Target property must be greater than 0',
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
                  child: Text('🏦 Calculate Savings Timeline',
                      style: AppTextStyles.dmSans(
                          size: 13,
                          color: Colors.white,
                          weight: FontWeight.w800)),
                ),
              ],
            ),
          ),

          if (_showResults) ...[
            const SizedBox(height: 16),

            // Result Hero Card
            Container(
              padding: const EdgeInsets.all(20),
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
                  Text("You'll reach your deposit goal in",
                      style: AppTextStyles.dmSans(
                          size: 9.5,
                          color: Colors.white54,
                          weight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                      'Target Deposit: ${CurrencyFormatter.format(targetDep, currencyCode: 'NZD')}',
                      style: AppTextStyles.dmSans(
                          size: 13, color: Colors.white70)),
                  Text(
                    months == 0 ? 'Already there! 🎉' : _addMonths(months),
                    style: AppTextStyles.playfair(
                        size: 28,
                        color: const Color(0xFFF5D060),
                        weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    months == 0
                        ? 'Your savings already cover the target deposit.'
                        : 'Save ${CurrencyFormatter.format(_monthlySavings, currencyCode: 'NZD')}/month for $months months',
                    style:
                        AppTextStyles.dmSans(size: 11, color: Colors.white60),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _buildHeroBox(
                              'Target Dep.',
                              CurrencyFormatter.compact(targetDep,
                                  symbol: 'NZ\$'),
                              const Color(0xFFF5D060))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildHeroBox(
                              'Total Savings',
                              CurrencyFormatter.compact(totalAvailable,
                                  symbol: 'NZ\$'),
                              const Color(0xFF6EE7B7))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildHeroBox(
                              'Shortfall',
                              shortfall > 0
                                  ? CurrencyFormatter.compact(shortfall,
                                      symbol: 'NZ\$')
                                  : 'Met ✓',
                              shortfall > 0
                                  ? Colors.white
                                  : const Color(0xFF6EE7B7))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Progress Bar Card
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Savings Progress',
                          style: AppTextStyles.playfair(
                              size: 13,
                              color: theme.getTextColor(context),
                              weight: FontWeight.w800)),
                      Text('${progressPct.toStringAsFixed(0)}%',
                          style: AppTextStyles.dmSans(
                              size: 11,
                              weight: FontWeight.w800,
                              color: const Color(0xFF1A6B4A))),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Progress Bar Track
                  Container(
                    height: 28,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: theme.getBgColor(context),
                        borderRadius: BorderRadius.circular(30)),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final fillWidth =
                                constraints.maxWidth * (progressPct / 100);
                            return Container(
                              width:
                                  fillWidth.clamp(30.0, constraints.maxWidth),
                              height: double.infinity,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Color(0xFF1A6B4A),
                                  Color(0xFF0D9488)
                                ]),
                                borderRadius: BorderRadius.horizontal(
                                    left: Radius.circular(30),
                                    right: Radius.circular(30)),
                              ),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                '${progressPct.toStringAsFixed(0)}%',
                                style: AppTextStyles.dmSans(
                                    size: 11,
                                    weight: FontWeight.w800,
                                    color: Colors.white),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          'Saved: ${CurrencyFormatter.format(totalAvailable, currencyCode: 'NZD')}',
                          style: AppTextStyles.dmSans(
                              size: 9.5, color: theme.getMutedColor(context))),
                      Text(
                          'Target: ${CurrencyFormatter.format(targetDep, currencyCode: 'NZD')}',
                          style: AppTextStyles.dmSans(
                              size: 9.5, color: theme.getMutedColor(context))),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                              color: theme.getBgColor(context),
                              borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            children: [
                              Text('Months to Goal',
                                  style: AppTextStyles.dmSans(
                                      size: 8.5,
                                      color: theme.getMutedColor(context),
                                      weight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(months == 0 ? 'Done!' : '$months mo',
                                  style: AppTextStyles.playfair(
                                      size: 16,
                                      color: theme.getTextColor(context),
                                      weight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                              color: theme.getBgColor(context),
                              borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            children: [
                              Text('Interest Earned',
                                  style: AppTextStyles.dmSans(
                                      size: 8.5,
                                      color: theme.getMutedColor(context),
                                      weight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(
                                  CurrencyFormatter.format(totalInterest,
                                      currencyCode: 'NZD'),
                                  style: AppTextStyles.playfair(
                                      size: 16,
                                      color: const Color(0xFF1A6B4A),
                                      weight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Timeline Milestones
            Text('Savings Milestones',
                style: AppTextStyles.playfair(
                    size: 14,
                    color: theme.getTextColor(context),
                    weight: FontWeight.w800)),
            const SizedBox(height: 10),
            Column(
              children: milestones.map((m) {
                final isDone = totalAvailable >= (m['amount'] as double);
                final currentMonths = m['months'] as int;
                final pct = m['pct'] as int;
                final amount = m['amount'] as double;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.getCardColor(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.getBorderColor(context)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDone
                              ? const Color(0xFFECFDF5)
                              : theme.getBgColor(context),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isDone ? '✅' : '⭐',
                          style: TextStyle(
                              fontSize: 14,
                              color: isDone
                                  ? const Color(0xFF1A6B4A)
                                  : Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$pct% of deposit reached',
                                style: AppTextStyles.dmSans(
                                    size: 12,
                                    weight: FontWeight.w800,
                                    color: theme.getTextColor(context))),
                            const SizedBox(height: 2),
                            Text(
                              isDone
                                  ? 'Achieved!'
                                  : '${m['date']} · $currentMonths months away',
                              style: AppTextStyles.dmSans(
                                  size: 9.5,
                                  color: theme.getMutedColor(context)),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(amount, currencyCode: 'NZD'),
                        style: AppTextStyles.dmSans(
                            size: 13,
                            weight: FontWeight.w800,
                            color: isDone
                                ? const Color(0xFF1A6B4A)
                                : theme.getMutedColor(context)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Save Plan Card
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('💾 Save This Savings Plan',
                            style: AppTextStyles.dmSans(
                                size: 12,
                                weight: FontWeight.w800,
                                color: theme.getTextColor(context))),
                        const SizedBox(height: 2),
                        Text('Track your progress toward your deposit goal',
                            style: AppTextStyles.dmSans(
                                size: 9.5,
                                color: theme.getMutedColor(context))),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _saveCalculation(
                        targetDep, totalAvailable, months, totalInterest),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A6B4A),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                    child: Text('Save ›',
                        style: AppTextStyles.dmSans(
                            size: 11,
                            color: Colors.white,
                            weight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),

          // Deposit Boost Strategies
          Text('Deposit Boost Strategies',
              style: AppTextStyles.playfair(
                  size: 14,
                  color: theme.getTextColor(context),
                  weight: FontWeight.w800)),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _buildBoostCard(
                  '🥝',
                  'KiwiSaver Withdrawal',
                  CurrencyFormatter.compact(_kiwiBalance, symbol: 'NZ\$'),
                  '3+ years · First home only',
                  theme),
              _buildBoostCard('🎁', 'HomeStart Grant', 'Up to NZ\$10K',
                  'New build · 3yr KiwiSaver', theme),
              _buildBoostCard('👨‍👩‍👧', 'Family Gift / Loan', 'Equity loan',
                  'Banks accept gifted deposit', theme),
              _buildBoostCard('🏛️', 'Kāinga Ora FHP', '5% deposit',
                  'Income cap applies', theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRateStripCell(String label, String value, String subtitle,
      {bool isGold = false}) {
    return Column(
      children: [
        Text(label.toUpperCase(),
            style: AppTextStyles.dmSans(
                size: 8,
                color: Colors.white54,
                weight: FontWeight.w600,
                letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyles.dmSans(
                size: 14,
                weight: FontWeight.w800,
                color: isGold ? const Color(0xFFF5D060) : Colors.white)),
        const SizedBox(height: 1),
        Text(subtitle,
            style: AppTextStyles.dmSans(size: 7.5, color: Colors.white38),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 25,
      width: 1,
      color: Colors.white12,
    );
  }

  Widget _buildNumericField({
    required String label,
    required double value,
    bool isPercent = false,
    required ValueChanged<double> onChanged,
    String? subtitle,
  }) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.getBgColor(context),
        border: Border.all(color: theme.getBorderColor(context)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: AppTextStyles.dmSans(
                  size: 8,
                  color: theme.getMutedColor(context),
                  weight: FontWeight.w700)),
          const SizedBox(height: 2),
          Row(
            children: [
              if (!isPercent)
                Text('\$ ',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        color: theme.getMutedColor(context),
                        weight: FontWeight.w700)),
              Expanded(
                child: TextFormField(
                  key: ValueKey(value),
                  initialValue: value.toStringAsFixed(0),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: AppTextStyles.playfair(
                      size: 14,
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
                        size: 13,
                        color: theme.getMutedColor(context),
                        weight: FontWeight.w700)),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle,
                style: AppTextStyles.dmSans(
                    size: 8, color: theme.getMutedColor(context))),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label.toUpperCase(),
              style: AppTextStyles.dmSans(
                  size: 8,
                  color: Colors.white54,
                  weight: FontWeight.w600,
                  letterSpacing: 0.3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.dmSans(
                  size: 12.5, color: color, weight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildBoostCard(
      String icon, String title, String val, String sub, CountryTheme theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.getBorderColor(context)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(title,
              style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(val,
              style: AppTextStyles.dmSans(
                  size: 13,
                  weight: FontWeight.w800,
                  color: const Color(0xFF1A6B4A))),
          const SizedBox(height: 2),
          Text(sub,
              style: AppTextStyles.dmSans(
                  size: 8.5, color: theme.getMutedColor(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
