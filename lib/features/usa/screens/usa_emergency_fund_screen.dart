// lib/features/usa/screens/usa_emergency_fund_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAEmergencyFundScreen extends ConsumerStatefulWidget {
  final SavedCalc? savedCalc;
  const USAEmergencyFundScreen({super.key, this.savedCalc});

  @override
  ConsumerState<USAEmergencyFundScreen> createState() => _USAEmergencyFundScreenState();
}

class _USAEmergencyFundScreenState extends ConsumerState<USAEmergencyFundScreen> {
  static const _theme = CountryThemes.usa;

  // Controllers for monthly expenses
  final _housingController = TextEditingController(text: '2200');
  final _utilitiesController = TextEditingController(text: '320');
  final _foodController = TextEditingController(text: '650');
  final _transportController = TextEditingController(text: '580');
  final _healthController = TextEditingController(text: '420');
  final _debtController = TextEditingController(text: '350');
  final _otherController = TextEditingController(text: '280');

  // Controllers for savings and contribution
  final _currSavedController = TextEditingController(text: '12000');
  final _monthlyAddController = TextEditingController(text: '1200');

  // Target Months (3, 6, 9, 12)
  int _targetMonths = 6;

  // Focus nodes for styling active fields
  final Map<String, FocusNode> _focusNodes = {};

  final _resultsKey = GlobalKey();
  bool _hasCalculated = false;

  // Stored inputs for calculation
  double _calcHousing = 0.0;
  double _calcUtilities = 0.0;
  double _calcFood = 0.0;
  double _calcTransport = 0.0;
  double _calcHealth = 0.0;
  double _calcDebt = 0.0;
  double _calcOther = 0.0;
  double _calcCurrSaved = 0.0;
  double _calcMonthlyAdd = 0.0;
  int _calcTargetMonths = 6;

  // Validation errors
  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    for (var key in ['housing', 'utilities', 'food', 'transport', 'health', 'debt', 'other', 'currSaved', 'monthlyAdd']) {
      final fn = FocusNode();
      fn.addListener(() => setState(() {}));
      _focusNodes[key] = fn;
    }

    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _housingController.text = (inputs['housing'] ?? 2200.0).toStringAsFixed(0);
      _utilitiesController.text = (inputs['utilities'] ?? 320.0).toStringAsFixed(0);
      _foodController.text = (inputs['food'] ?? 650.0).toStringAsFixed(0);
      _transportController.text = (inputs['transport'] ?? 580.0).toStringAsFixed(0);
      _healthController.text = (inputs['health'] ?? 420.0).toStringAsFixed(0);
      _debtController.text = (inputs['debt'] ?? 350.0).toStringAsFixed(0);
      _otherController.text = (inputs['other'] ?? 280.0).toStringAsFixed(0);
      _currSavedController.text = (inputs['currSaved'] ?? 12000.0).toStringAsFixed(0);
      _monthlyAddController.text = (inputs['monthlyAdd'] ?? 1200.0).toStringAsFixed(0);
      _targetMonths = (inputs['targetMonths'] ?? 6.0).toInt();

      _calcHousing = _val(_housingController);
      _calcUtilities = _val(_utilitiesController);
      _calcFood = _val(_foodController);
      _calcTransport = _val(_transportController);
      _calcHealth = _val(_healthController);
      _calcDebt = _val(_debtController);
      _calcOther = _val(_otherController);
      _calcCurrSaved = _val(_currSavedController);
      _calcMonthlyAdd = _val(_monthlyAddController);
      _calcTargetMonths = _targetMonths;
      _hasCalculated = true;
    }
  }

  @override
  void dispose() {
    _housingController.dispose();
    _utilitiesController.dispose();
    _foodController.dispose();
    _transportController.dispose();
    _healthController.dispose();
    _debtController.dispose();
    _otherController.dispose();
    _currSavedController.dispose();
    _monthlyAddController.dispose();
    for (var fn in _focusNodes.values) {
      fn.dispose();
    }
    super.dispose();
  }

  double _val(TextEditingController c) => double.tryParse(c.text) ?? 0.0;

  void _resetInputs() {
    setState(() {
      _housingController.clear();
      _utilitiesController.clear();
      _foodController.clear();
      _transportController.clear();
      _healthController.clear();
      _debtController.clear();
      _otherController.clear();
      _currSavedController.clear();
      _monthlyAddController.clear();
      _targetMonths = 6;
      _hasCalculated = false;
      _errors.clear();
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 Inputs cleared'),
        backgroundColor: Color(0xFF1B3F72),
        duration: Duration(seconds: 2),
      ),
    );
  }

  bool _validateInputs() {
    bool isValid = true;
    setState(() {
      _errors.clear();
      final fields = {
        'housing': _housingController,
        'utilities': _utilitiesController,
        'food': _foodController,
        'transport': _transportController,
        'health': _healthController,
        'debt': _debtController,
        'other': _otherController,
        'currSaved': _currSavedController,
        'monthlyAdd': _monthlyAddController,
      };
      final names = {
        'housing': 'Monthly housing',
        'utilities': 'Utilities',
        'food': 'Groceries & food',
        'transport': 'Transportation',
        'health': 'Health insurance',
        'debt': 'Minimum debt',
        'other': 'Other essentials',
        'currSaved': 'Current emergency fund',
        'monthlyAdd': 'Monthly contribution',
      };
      fields.forEach((key, controller) {
        if (controller.text.trim().isEmpty) {
          _errors[key] = '${names[key]} is required';
          isValid = false;
        } else {
          final val = double.tryParse(controller.text);
          if (val == null || val < 0) {
            _errors[key] = 'Enter a valid positive number';
            isValid = false;
          }
        }
      });
    });
    return isValid;
  }

  void _saveCalculation() async {
    if (!_hasCalculated) return;
    final housing = _calcHousing;
    final utilities = _calcUtilities;
    final food = _calcFood;
    final transport = _calcTransport;
    final health = _calcHealth;
    final debt = _calcDebt;
    final other = _calcOther;
    final currSaved = _calcCurrSaved;
    final monthlyAdd = _calcMonthlyAdd;

    final totalMonthly = housing + utilities + food + transport + health + debt + other;
    final targetGoal = totalMonthly * _calcTargetMonths;

    final labelCtrl = TextEditingController(text: '$_calcTargetMonths-Month Emergency Fund Plan');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_emergency_fund_screen/save'),
      builder: (context) => AlertDialog(
        backgroundColor: _theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Emergency Fund',
            style: AppTextStyles.playfair(
                size: 16, color: _theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving: Target ${CurrencyFormatter.compact(targetGoal, symbol: '\$')} · Expenses: ${CurrencyFormatter.compact(totalMonthly, symbol: '\$')}/mo · Saved: ${CurrencyFormatter.compact(currSaved, symbol: '\$')}',
              style: AppTextStyles.dmSans(
                  size: 11, color: _theme.getMutedColor(context)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: _theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My Emergency Fund)',
                hintStyle: AppTextStyles.dmSans(size: 13, color: Colors.grey),
                filled: true,
                fillColor: _theme.getBgColor(context),
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
              backgroundColor: const Color(0xFF15803D),
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
          : 'Emergency Fund Plan';

      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'Emergency Fund Plan',
        label: label,
        currencyCode: 'USD',
        inputs: {
          'housing': housing,
          'utilities': utilities,
          'food': food,
          'transport': transport,
          'health': health,
          'debt': debt,
          'other': other,
          'currSaved': currSaved,
          'monthlyAdd': monthlyAdd,
          'targetMonths': _calcTargetMonths.toDouble(),
        },
        results: {
          'totalMonthly': totalMonthly,
          'targetGoal': targetGoal,
          'needed': max(0.0, targetGoal - currSaved),
          'months': totalMonthly > 0 ? max(0.0, targetGoal - currSaved) / (monthlyAdd > 0 ? monthlyAdd : 1.0) : 0.0,
        },
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Emergency Fund plan saved successfully!'),
            backgroundColor: Color(0xFF15803D),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _loadSavedCalculation(SavedCalc calc) {
    setState(() {
      _housingController.text = (calc.inputs['housing'] ?? 2200.0).toStringAsFixed(0);
      _utilitiesController.text = (calc.inputs['utilities'] ?? 320.0).toStringAsFixed(0);
      _foodController.text = (calc.inputs['food'] ?? 650.0).toStringAsFixed(0);
      _transportController.text = (calc.inputs['transport'] ?? 580.0).toStringAsFixed(0);
      _healthController.text = (calc.inputs['health'] ?? 420.0).toStringAsFixed(0);
      _debtController.text = (calc.inputs['debt'] ?? 350.0).toStringAsFixed(0);
      _otherController.text = (calc.inputs['other'] ?? 280.0).toStringAsFixed(0);
      _currSavedController.text = (calc.inputs['currSaved'] ?? 12000.0).toStringAsFixed(0);
      _monthlyAddController.text = (calc.inputs['monthlyAdd'] ?? 1200.0).toStringAsFixed(0);
      _targetMonths = (calc.inputs['targetMonths'] ?? 6.0).toInt();

      _calcHousing = _val(_housingController);
      _calcUtilities = _val(_utilitiesController);
      _calcFood = _val(_foodController);
      _calcTransport = _val(_transportController);
      _calcHealth = _val(_healthController);
      _calcDebt = _val(_debtController);
      _calcOther = _val(_otherController);
      _calcCurrSaved = _val(_currSavedController);
      _calcMonthlyAdd = _val(_monthlyAddController);
      _calcTargetMonths = _targetMonths;
      _hasCalculated = true;
      _errors.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Loaded saved calculation!'),
        backgroundColor: Color(0xFF15803D),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      routeSettings: const RouteSettings(name: '/tool/usa/emergencyfund/info'),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardBg = isDark ? const Color(0xFF141C33) : Colors.white;
        final textCol = isDark ? Colors.white : const Color(0xFF0B1D3A);
        final mutedCol = isDark ? Colors.white70 : const Color(0xFF4A5C7A);

        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView(
                controller: scrollController,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'About Emergency Funds',
                    style: AppTextStyles.playfair(size: 20, color: textCol, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'An emergency fund is money set aside to cover life\'s unexpected expenses, such as job loss, medical emergencies, or home repairs. For home buyers, keeping an emergency fund separate from your down payment is crucial to ensure you don\'t end up house-poor after closing.',
                    style: AppTextStyles.dmSans(size: 14, color: mutedCol, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Coverage Guidelines:',
                    style: AppTextStyles.playfair(size: 14, color: textCol, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 3 Months: Minimum target for dual-income households with stable jobs.\n• 6 Months: Recommended target for standard homeowners, single earners, or families with children.\n• 12 Months: Ideal for self-employed individuals, commission-based workers, or high-risk careers.',
                    style: AppTextStyles.dmSans(size: 13.5, color: mutedCol, height: 1.6),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = _theme.getCardColor(context);
    final textCol = _theme.getTextColor(context);
    final mutedCol = _theme.getMutedColor(context);
    final borderCol = _theme.getBorderColor(context);
    final bgCol = _theme.getBgColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final housing = _calcHousing;
    final utilities = _calcUtilities;
    final food = _calcFood;
    final transport = _calcTransport;
    final health = _calcHealth;
    final debt = _calcDebt;
    final other = _calcOther;
    final currSaved = _calcCurrSaved;
    final monthlyAdd = _calcMonthlyAdd;

    final totalMonthly = housing + utilities + food + transport + health + debt + other;
    final targetGoal = totalMonthly * _calcTargetMonths;
    final target3 = totalMonthly * 3;
    final target12 = totalMonthly * 12;

    final needed = max(0.0, targetGoal - currSaved);
    final months = needed <= 0 ? 0 : (monthlyAdd > 0 ? (needed / monthlyAdd).ceil() : 999);
    final progressPct = targetGoal > 0 ? (currSaved / targetGoal * 100).clamp(0.0, 100.0) : 0.0;

    // Categories data for chart
    final categories = [
      _CategoryItem('Housing', housing, const Color(0xFF1B3F72)),
      _CategoryItem('Utilities', utilities, const Color(0xFF15803D)),
      _CategoryItem('Food', food, const Color(0xFFD97706)),
      _CategoryItem('Transport', transport, const Color(0xFFB91C1C)),
      _CategoryItem('Health', health, const Color(0xFF7C3AED)),
      _CategoryItem('Debt', debt, const Color(0xFF0891B2)),
      _CategoryItem('Other', other, const Color(0xFF9CA3AF)),
    ];
    final maxCatVal = categories.map((c) => c.value).fold(1.0, max);

    final showOutdatedWarning = _hasCalculated && (
      _val(_housingController) != _calcHousing ||
      _val(_utilitiesController) != _calcUtilities ||
      _val(_foodController) != _calcFood ||
      _val(_transportController) != _calcTransport ||
      _val(_healthController) != _calcHealth ||
      _val(_debtController) != _calcDebt ||
      _val(_otherController) != _calcOther ||
      _val(_currSavedController) != _calcCurrSaved ||
      _val(_monthlyAddController) != _calcMonthlyAdd ||
      _targetMonths != _calcTargetMonths
    );

    // Watch saved down payment child scenarios
    final savedCalcs = ref.watch(savedProvider).where((c) => c.country == 'USA' && c.calcType == 'Emergency Fund Plan').toList();

    return Scaffold(
      backgroundColor: bgCol,
      body: CustomScrollView(
        slivers: [
          // Header with custom gradient and shield watermark
          SliverAppBar(
            expandedHeight: 155,
            pinned: true,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72), Color(0xFF15803D)],
                        stops: [0.0, 0.55, 1.0],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  // Watermark emoji
                  Positioned(
                    right: 10,
                    top: 50,
                    child: Opacity(
                      opacity: 0.07,
                      child: Text(
                        '🛡️',
                        style: TextStyle(
                          fontSize: 72,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ),
                  // Header content
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => context.pop(),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text('←', style: TextStyle(color: Colors.white, fontSize: 16)),
                                ),
                              ),
                              Column(
                                children: [
                                  const Text('🛡️', style: TextStyle(fontSize: 24)),
                                  Text(
                                    'Emergency Fund',
                                    style: AppTextStyles.playfair(size: 19, color: Colors.white),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: _showInfoSheet,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text('ℹ️', style: TextStyle(color: Colors.white, fontSize: 16)),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Mini subtitle inside header
                          Center(
                            child: Text(
                              '3–6 months of expenses · Keep reserves after closing',
                              style: AppTextStyles.dmSans(size: 10, color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Rate Strip Block
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFF1B3F72),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildRsCell('Min Target', '3 mo', 'Bare minimum', isGreen: true)),
                  _buildRsDivider(),
                  Expanded(child: _buildRsCell('Ideal', '6 mo', 'Recommended', isGold: true)),
                  _buildRsDivider(),
                  Expanded(child: _buildRsCell('Avg Spend', '\$6,081', 'Monthly HH')),
                  _buildRsDivider(),
                  Expanded(child: _buildRsCell('HY Savings', '4.5–5%', 'APY 2025')),
                ],
              ),
            ),
          ),

          // Main content list
          SliverList(
            delegate: SliverChildListDelegate([
              if (_hasCalculated) ...[
                Padding(
                  key: _resultsKey,
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Emergency Fund'.toUpperCase(),
                        style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),

                if (showOutdatedWarning)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      border: Border.all(color: Colors.amber.shade700, width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Text('⚠️ ', style: TextStyle(fontSize: 14)),
                        Expanded(
                          child: Text(
                            'Inputs have changed. Tap Calculate to update results.',
                            style: AppTextStyles.dmSans(
                              size: 11,
                              color: Colors.amber.shade800,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Result Hero Card (Green Gradient)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                  padding: const EdgeInsets.all(19),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF14532D), Color(0xFF15803D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_calcTargetMonths-MONTH EMERGENCY FUND TARGET',
                        style: AppTextStyles.dmSans(
                          size: 9.5,
                          weight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.55),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$',
                            style: AppTextStyles.dmSans(
                              size: 18,
                              weight: FontWeight.w800,
                              color: const Color(0xFF86EFAC),
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(targetGoal, symbol: '').split('.').first,
                            style: AppTextStyles.dmSans(
                              size: 38,
                              weight: FontWeight.w800,
                              color: Colors.white,
                            ).copyWith(fontFamily: 'Georgia'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Based on ${CurrencyFormatter.format(totalMonthly, symbol: '\$').split('.').first}/mo expenses · $_calcTargetMonths-month cushion',
                        style: AppTextStyles.dmSans(
                          size: 10,
                          color: Colors.white.withValues(alpha: 0.60),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Grid stats
                      Row(
                        children: [
                          Expanded(
                            child: _buildHeroStat('3-Month Min', CurrencyFormatter.format(target3, symbol: '\$').split('.').first, 'Bare minimum'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildHeroStat('Currently Saved', CurrencyFormatter.format(currSaved, symbol: '\$').split('.').first, '${progressPct.toStringAsFixed(0)}% of goal'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildHeroStat(
                              'Months to Goal',
                              months == 0 ? '✓ Done' : (months == 999 ? 'N/A' : '$months mo'),
                              '@ ${CurrencyFormatter.format(monthlyAdd, symbol: '\$').split('.').first}/mo',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Inputs Section
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 20, 15, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monthly Expenses'.toUpperCase(),
                      style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                    ),
                    GestureDetector(
                      onTap: _resetInputs,
                      child: Text(
                        'Reset',
                        style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w600, color: const Color(0xFF1B3F72)),
                      ),
                    ),
                  ],
                ),
              ),

              // Expense Breakdown Inputs Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderCol),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: bgCol,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: const Text('💰', style: TextStyle(fontSize: 15)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Expense Breakdown',
                          style: AppTextStyles.playfair(size: 12.5, color: textCol, weight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _buildInputField('Monthly Housing (Rent/Mortgage + HOA)', _housingController, 'housing'),
                    const SizedBox(height: 12),
                    _buildInputField('Utilities (Electric, Gas, Water, Internet)', _utilitiesController, 'utilities'),
                    const SizedBox(height: 12),
                    _buildInputField('Groceries & Food', _foodController, 'food'),
                    const SizedBox(height: 12),
                    _buildInputField('Transportation (Car payment, Gas, Insurance)', _transportController, 'transport'),
                    const SizedBox(height: 12),
                    _buildInputField('Health Insurance & Medical', _healthController, 'health'),
                    const SizedBox(height: 12),
                    _buildInputField('Minimum Debt Payments (CC, Student Loans)', _debtController, 'debt'),
                    const SizedBox(height: 12),
                    _buildInputField('Other Essentials (Phone, Childcare, etc.)', _otherController, 'other'),
                  ],
                ),
              ),

              // Savings & Targets Inputs Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderCol),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: bgCol,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: const Text('🏦', style: TextStyle(fontSize: 15)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Current Savings & Goals',
                          style: AppTextStyles.playfair(size: 12.5, color: textCol, weight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _buildInputField('Current Emergency Fund Saved', _currSavedController, 'currSaved'),
                    const SizedBox(height: 12),
                    _buildInputField('Monthly Contribution to Emergency Fund', _monthlyAddController, 'monthlyAdd'),
                    const SizedBox(height: 12),

                    // Target Coverage Pill Selector
                    Text(
                      'TARGET COVERAGE',
                      style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: mutedCol, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [3, 6, 9, 12].map((m) {
                        final isActive = _targetMonths == m;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _targetMonths = m),
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFF15803D) : bgCol,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isActive ? const Color(0xFF15803D) : borderCol, width: 1.5),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$m mo',
                                style: AppTextStyles.dmSans(
                                  size: 11,
                                  weight: FontWeight.w700,
                                  color: isActive ? Colors.white : mutedCol,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Calculate Button
                    GestureDetector(
                      onTap: () {
                        if (_validateInputs()) {
                          setState(() {
                            _calcHousing = _val(_housingController);
                            _calcUtilities = _val(_utilitiesController);
                            _calcFood = _val(_foodController);
                            _calcTransport = _val(_transportController);
                            _calcHealth = _val(_healthController);
                            _calcDebt = _val(_debtController);
                            _calcOther = _val(_otherController);
                            _calcCurrSaved = _val(_currSavedController);
                            _calcMonthlyAdd = _val(_monthlyAddController);
                            _calcTargetMonths = _targetMonths;
                            _hasCalculated = true;
                          });
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_resultsKey.currentContext != null) {
                              Scrollable.ensureVisible(
                                _resultsKey.currentContext!,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            }
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF15803D), Color(0xFF14532D)]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF15803D).withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '🛡️ Calculate Emergency Fund',
                          style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: Colors.white).copyWith(fontFamily: 'Georgia'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Save Button
                    GestureDetector(
                      onTap: _hasCalculated ? _saveCalculation : null,
                      child: Opacity(
                        opacity: _hasCalculated ? 1.0 : 0.5,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: cardBg,
                            border: Border.all(color: const Color(0xFFD97706), width: 1.5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('💾', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 8),
                              Text(
                                'Save This Calculation',
                                style: AppTextStyles.dmSans(
                                  size: 13,
                                  weight: FontWeight.w800,
                                  color: const Color(0xFFD97706),
                                ).copyWith(fontFamily: 'Georgia'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_hasCalculated) ...[
                // Coverage Scenarios Columns (3, 6, 12 months)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  child: Text(
                    'Coverage Scenarios'.toUpperCase(),
                    style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: _buildScenarioItem('3 months', target3, 'Min. target', 'Minimum', const Color(0xFFFEF3C7), const Color(0xFF92400E))),
                      const SizedBox(width: 8),
                      Expanded(child: _buildScenarioItem('6 months', targetGoal, 'Recommended', '✓ Ideal', const Color(0xFFDCFCE7), const Color(0xFF15803D))),
                      const SizedBox(width: 8),
                      Expanded(child: _buildScenarioItem('12 months', target12, 'Max security', 'Premium', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8))),
                    ],
                  ),
                ),

                // Progress Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Savings Progress to $_calcTargetMonths-Month Goal',
                        style: AppTextStyles.playfair(size: 12.5, color: textCol, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),

                      // Progress Track
                      Stack(
                        children: [
                          Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final w = constraints.maxWidth * (progressPct / 100);
                              return Container(
                                height: 10,
                                width: w,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF15803D), Color(0xFF22C55E)]),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('\$0', style: AppTextStyles.dmSans(size: 9, color: mutedCol, weight: FontWeight.w600)),
                          Text('Saved: ${CurrencyFormatter.format(currSaved, symbol: '\$').split('.').first}', style: AppTextStyles.dmSans(size: 9, color: mutedCol, weight: FontWeight.w600)),
                          Text('Goal: ${CurrencyFormatter.format(targetGoal, symbol: '\$').split('.').first}', style: AppTextStyles.dmSans(size: 9, color: mutedCol, weight: FontWeight.w600)),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Time display row
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: bgCol,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Text('⏱️ ', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textCol).copyWith(fontFamily: 'Georgia'),
                                      children: [
                                        const TextSpan(text: 'At '),
                                        TextSpan(text: CurrencyFormatter.format(monthlyAdd, symbol: '\$').split('.').first),
                                        const TextSpan(text: '/mo savings → '),
                                        TextSpan(
                                          text: months == 0 ? "Goal reached! 🎉" : (months == 999 ? "Increase contributions" : "$months months to reach goal"),
                                          style: const TextStyle(color: Color(0xFF15803D)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${CurrencyFormatter.format(currSaved, symbol: '\$').split('.').first} saved · ${needed > 0 ? '${CurrencyFormatter.format(needed, symbol: '\$').split('.').first} more needed' : 'Goal reached!'}',
                                    style: AppTextStyles.dmSans(size: 9.5, color: mutedCol),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Category Proportional Vertical Bar Chart Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Expense Breakdown',
                        style: AppTextStyles.playfair(size: 12.5, color: textCol, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 20),

                      // Custom bar chart
                      SizedBox(
                        height: 100,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: categories.map((cat) {
                            final h = max(4.0, (cat.value / maxCatVal) * 80);
                            return Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (cat.value > 0)
                                    Text(
                                      CurrencyFormatter.compact(cat.value, symbol: '\$'),
                                      style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w800, color: textCol),
                                    ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: h,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: cat.color,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    cat.label,
                                    style: AppTextStyles.dmSans(size: 8.5, color: mutedCol, weight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Breakdown details rows
                      Column(
                        children: [
                          ...categories.where((c) => c.value > 0).map((c) {
                            final pct = totalMonthly > 0 ? (c.value / totalMonthly * 100).round() : 0;
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: borderCol, width: 0.5)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(color: c.color, borderRadius: BorderRadius.circular(3)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c.label, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: textCol)),
                                        Text('$pct% of expenses', style: AppTextStyles.dmSans(size: 9, color: mutedCol)),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(c.value, symbol: '\$').split('.').first,
                                    style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textCol).copyWith(fontFamily: 'Georgia'),
                                  ),
                                ],
                              ),
                            );
                          }),
                          // Total monthly spend row
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: bgCol,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Monthly Expenses',
                                  style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: textCol),
                                ),
                                Text(
                                  CurrencyFormatter.format(totalMonthly, symbol: '\$').split('.').first,
                                  style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textCol).copyWith(fontFamily: 'Georgia'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status indicator banner (danger, warn, good)
                _buildStatusAlertCard(progressPct, currSaved, targetGoal, needed, months),
              ],

              // Post-Closing Homeowner Tips
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 20, 15, 8),
                child: Text(
                  'Post-Closing Homeowner Tips'.toUpperCase(),
                  style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                ),
              ),
              _buildTipCard('🏦', 'Use a High-Yield Savings Account', 'Top HYSAs (Marcus, Ally, SoFi) offer 4.5–5.0% APY in 2025. Your \$36K earns ~\$1,620/yr in interest while staying liquid.', '4.5–5% APY', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
              _buildTipCard('📊', 'Keep Fund Separate from Down Payment', 'Never co-mingle your emergency fund with your down payment savings. Lenders may flag funds used for closing as "depleted reserves."', 'Lender Tip', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
              _buildTipCard('🔄', 'Replenish After Any Withdrawal', 'After using emergency funds (e.g., a roof leak or job loss), rebuild within 6–12 months. Set an automatic monthly transfer to stay on track.', 'Best Practice', const Color(0xFFFEF3C7), const Color(0xFFB45309)),
              _buildTipCard('📋', 'Lenders Want 2–6 Months Reserves', 'Many conventional and jumbo loan programs require proof of 2–6 months of PITI (Principal, Interest, Taxes, Insurance) in reserves after closing.', 'Qualification Tip', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),

              // Saved calculations history panel
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: Text(
                  'Saved Scenarios'.toUpperCase(),
                  style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: mutedCol, letterSpacing: 1),
                ),
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol),
                ),
                child: savedCalcs.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: Text(
                            'No saved scenarios yet. Tap "Save This Calculation" above to bookmark a plan.',
                            style: AppTextStyles.dmSans(size: 11, color: mutedCol),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : Column(
                        children: savedCalcs.map((calc) {
                          final isLast = savedCalcs.indexOf(calc) == savedCalcs.length - 1;
                          final hVal = calc.inputs['housing'] ?? 0.0;
                          final uVal = calc.inputs['utilities'] ?? 0.0;
                          final fVal = calc.inputs['food'] ?? 0.0;
                          final tVal = calc.inputs['transport'] ?? 0.0;
                          final hlVal = calc.inputs['health'] ?? 0.0;
                          final dVal = calc.inputs['debt'] ?? 0.0;
                          final oVal = calc.inputs['other'] ?? 0.0;
                          final sum = hVal + uVal + fVal + tVal + hlVal + dVal + oVal;

                          final cSaved = calc.inputs['currSaved'] ?? 0.0;
                          final mAdd = calc.inputs['monthlyAdd'] ?? 0.0;
                          final tMos = (calc.inputs['targetMonths'] ?? 6.0).toInt();

                          return Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isLast ? Colors.transparent : borderCol.withValues(alpha: 0.5),
                                  width: 1,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _loadSavedCalculation(calc),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          calc.label,
                                          style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textCol).copyWith(fontFamily: 'Georgia'),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Expenses ${CurrencyFormatter.compact(sum, symbol: '\$')}/mo · $tMos-Month Target · Saved ${CurrencyFormatter.compact(cSaved, symbol: '\$')} · Adding ${CurrencyFormatter.compact(mAdd, symbol: '\$')}/mo',
                                          style: AppTextStyles.dmSans(size: 9.5, color: mutedCol),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    await ref.read(savedProvider.notifier).delete(calc.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Removed saved scenario'),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Text('🗑️', style: TextStyle(fontSize: 13)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),

              const SizedBox(height: 120),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildRsCell(String label, String value, String note, {bool isGreen = false, bool isGold = false}) {
    Color valColor = Colors.white;
    if (isGreen) valColor = const Color(0xFF86EFAC);
    if (isGold) valColor = const Color(0xFFFCD34D);

    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(size: 8.5, color: Colors.white70, weight: FontWeight.w700, letterSpacing: 0.4),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.dmSans(size: 15, weight: FontWeight.w800, color: valColor).copyWith(fontFamily: 'Georgia'),
        ),
        const SizedBox(height: 2),
        Text(
          note,
          style: AppTextStyles.dmSans(size: 8, color: Colors.white38),
        ),
      ],
    );
  }

  Widget _buildRsDivider() {
    return Container(
      width: 1,
      height: 25,
      color: Colors.white.withValues(alpha: 0.14),
    );
  }

  Widget _buildHeroStat(String label, String value, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w600, color: Colors.white54, letterSpacing: 0.4),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: Colors.white),
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

  Widget _buildInputField(String label, TextEditingController controller, String focusKey) {
    final focusNode = _focusNodes[focusKey]!;
    final isFocused = focusNode.hasFocus;
    final errorText = _errors[focusKey];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: _theme.getMutedColor(context), letterSpacing: 0.5),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: _theme.getBgColor(context),
            border: Border.all(
              color: errorText != null
                  ? Colors.red
                  : (isFocused ? const Color(0xFF15803D) : _theme.getBorderColor(context)),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 13, right: 10),
                child: Text(
                  '\$',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w700, color: _theme.getTextColor(context)).copyWith(fontFamily: 'Georgia'),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 11),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 13, left: 10),
                child: Text(
                  focusKey == 'currSaved' ? 'total' : '/mo',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: AppTextStyles.dmSans(
              size: 10,
              color: Colors.red,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScenarioItem(String label, double val, String desc, String badge, Color badgeBg, Color badgeText) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color finalBg = badgeBg;
    Color finalTxt = badgeText;
    if (isDark) {
      if (badgeBg == const Color(0xFFFEF3C7)) {
        finalBg = const Color(0xFF3F2D0F);
        finalTxt = const Color(0xFFFCD34D);
      } else if (badgeBg == const Color(0xFFDCFCE7)) {
        finalBg = const Color(0xFF0F3A1D);
        finalTxt = const Color(0xFF86EFAC);
      } else if (badgeBg == const Color(0xFFEFF6FF)) {
        finalBg = const Color(0xFF0F263F);
        finalTxt = const Color(0xFF93C5FD);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: _theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _theme.getBorderColor(context)),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w700, color: _theme.getMutedColor(context), letterSpacing: 0.4),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.compact(val, symbol: '\$'),
            style: AppTextStyles.dmSans(size: 20, weight: FontWeight.w800, color: _theme.getTextColor(context)).copyWith(fontFamily: 'Georgia'),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: AppTextStyles.dmSans(size: 9, color: _theme.getMutedColor(context)),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: finalBg, borderRadius: BorderRadius.circular(10)),
            child: Text(
              badge,
              style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w700, color: finalTxt),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusAlertCard(double pct, double currSaved, double target, double needed, int months) {
    Gradient cardGrd;
    Color borderC;
    Color textC;
    Color valC;
    String titleText;

    if (pct >= 100) {
      cardGrd = const LinearGradient(colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)]);
      borderC = const Color(0xFF86EFAC);
      textC = const Color(0xFF166534);
      valC = const Color(0xFF15803D);
      titleText = '✅ Emergency Fund Fully Funded!';
    } else if (pct >= 50) {
      cardGrd = const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]);
      borderC = const Color(0xFFFCD34D);
      textC = const Color(0xFF92400E);
      valC = const Color(0xFFB45309);
      titleText = '⚡ Halfway There — Keep Going!';
    } else {
      cardGrd = const LinearGradient(colors: [Color(0xFFFEF2F2), Color(0xFFFEE2E2)]);
      borderC = const Color(0xFFFECACA);
      textC = const Color(0xFF991B1B);
      valC = const Color(0xFFB91C1C);
      titleText = '⚠️ Fund Underfunded — Take Action';
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      if (pct >= 100) {
        cardGrd = const LinearGradient(colors: [Color(0xFF0A2E12), Color(0xFF0F3A1D)]);
        borderC = const Color(0xFF15803D).withValues(alpha: 0.5);
        textC = const Color(0xFF86EFAC);
        valC = const Color(0xFF4ADE80);
      } else if (pct >= 50) {
        cardGrd = const LinearGradient(colors: [Color(0xFF2E1B00), Color(0xFF3F260E)]);
        borderC = const Color(0xFFB45309).withValues(alpha: 0.5);
        textC = const Color(0xFFFDE68A);
        valC = const Color(0xFFFBBF24);
      } else {
        cardGrd = const LinearGradient(colors: [Color(0xFF3F0A0A), Color(0xFF4C1010)]);
        borderC = const Color(0xFFB91C1C).withValues(alpha: 0.5);
        textC = const Color(0xFFFEE2E2);
        valC = const Color(0xFFF87171);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: cardGrd,
        border: Border.all(color: borderC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titleText,
            style: AppTextStyles.playfair(size: 12, color: textC, weight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _buildAlertRow('Current Saved', CurrencyFormatter.format(currSaved, symbol: '\$').split('.').first, textC, valC),
          _buildAlertRow('$_targetMonths-Month Target', CurrencyFormatter.format(target, symbol: '\$').split('.').first, textC, valC),
          _buildAlertRow('Gap to Fill', needed > 0 ? CurrencyFormatter.format(needed, symbol: '\$').split('.').first : '\$0 — Goal Met!', textC, valC),
          _buildAlertRow('Months to Goal', months == 0 ? 'Reached! ✓' : (months == 999 ? 'Add contributions' : '$months months'), textC, valC),
        ],
      ),
    );
  }

  Widget _buildAlertRow(String label, String value, Color labelColor, Color valColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w600, color: labelColor)),
          Text(value, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: valColor).copyWith(fontFamily: 'Georgia')),
        ],
      ),
    );
  }

  Widget _buildTipCard(String emoji, String title, String desc, String tag, Color tagBg, Color tagText) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color finalBg = tagBg;
    Color finalTxt = tagText;
    if (isDark) {
      if (tagBg == const Color(0xFFDCFCE7)) {
        finalBg = const Color(0xFF0F3A1D);
        finalTxt = const Color(0xFF86EFAC);
      } else if (tagBg == const Color(0xFFEFF6FF)) {
        finalBg = const Color(0xFF0F263F);
        finalTxt = const Color(0xFF93C5FD);
      } else if (tagBg == const Color(0xFFFEF3C7)) {
        finalBg = const Color(0xFF2E1D0F);
        finalTxt = const Color(0xFFFCD34D);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: _theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _theme.getBorderColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _theme.getBgColor(context),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.playfair(size: 12, color: _theme.getTextColor(context), weight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: AppTextStyles.dmSans(size: 9.5, color: _theme.getMutedColor(context), height: 1.4),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: finalBg, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    tag,
                    style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w700, color: finalTxt),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryItem {
  final String label;
  final double value;
  final Color color;
  _CategoryItem(this.label, this.value, this.color);
}
