// lib/features/newzealand/tools/nz_deposit_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZDepositCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZDepositCalc({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZDepositCalc> createState() => _NZDepositCalcState();
}

class _NZDepositCalcState extends ConsumerState<NZDepositCalc> {
  final _priceController = TextEditingController(text: '800000');
  final _currentController = TextEditingController(text: '22000');
  final _ksController = TextEditingController(text: '28000');
  final _monthlyController = TextEditingController(text: '2800');

  double _depPct = 20.0;
  double _savingsRate = 4.8;
  bool _includeKs = true;

  bool _showResults = false;
  final Map<String, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};
  final _resultsKey = GlobalKey();

  @override
  void dispose() {
    _priceController.dispose();
    _currentController.dispose();
    _ksController.dispose();
    _monthlyController.dispose();
    super.dispose();
  }

  int _calcMonthsToGoal(double target, double startBal, double monthlySave, double rateVal) {
    if (startBal >= target) return 0;
    if (monthlySave <= 0) return 999; // infinite
    double bal = startBal;
    final r = rateVal / 12 / 100;
    int m = 0;
    while (bal < target && m < 600) {
      bal = bal * (1 + r) + monthlySave;
      m++;
    }
    return m;
  }

  void _reset() {
    setState(() {
      _priceController.text = '800000';
      _currentController.text = '22000';
      _ksController.text = '28000';
      _monthlyController.text = '2800';
      _depPct = 20.0;
      _savingsRate = 4.8;
      _includeKs = true;
      _showResults = false;
      _calcSnapshot.clear();
      _errors.clear();
    });
  }

  void _calculate() {
    final errors = <String, String>{};
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final current = double.tryParse(_currentController.text) ?? 0.0;
    final ks = double.tryParse(_ksController.text) ?? 0.0;
    final monthly = double.tryParse(_monthlyController.text) ?? 0.0;

    final target = price * _depPct / 100;
    final startSav = current + (_includeKs ? ks : 0);

    if (price <= 0) errors['price'] = 'Enter valid property price';
    if (current < 0) errors['current'] = 'Cannot be negative';
    if (ks < 0) errors['ks'] = 'Cannot be negative';
    if (monthly <= 0 && startSav < target) {
      errors['monthly'] = 'Enter a monthly savings amount greater than 0';
    }

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) return;

    setState(() {
      _calcSnapshot['price'] = price;
      _calcSnapshot['current'] = current;
      _calcSnapshot['ks'] = ks;
      _calcSnapshot['monthly'] = monthly;
      _calcSnapshot['depPct'] = _depPct;
      _calcSnapshot['savingsRate'] = _savingsRate;
      _calcSnapshot['includeKs'] = _includeKs;
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
    final double snapPrice = _calcSnapshot['price'] ?? 800000.0;
    final double snapCurrent = _calcSnapshot['current'] ?? 22000.0;
    final double snapKs = _calcSnapshot['ks'] ?? 28000.0;
    final double snapMonthly = _calcSnapshot['monthly'] ?? 2800.0;
    final double snapDepPct = _calcSnapshot['depPct'] ?? 20.0;
    final double snapSavingsRate = _calcSnapshot['savingsRate'] ?? 4.8;
    final bool snapIncludeKs = _calcSnapshot['includeKs'] ?? true;

    final double target = snapPrice * snapDepPct / 100;
    final double startSav = snapCurrent + (snapIncludeKs ? snapKs : 0);
    final int months = _calcMonthsToGoal(target, startSav, snapMonthly, snapSavingsRate);

    final inputs = <String, double>{
      'price': snapPrice,
      'current': snapCurrent,
      'ks': snapKs,
      'monthly': snapMonthly,
      'depPct': snapDepPct,
      'savingsRate': snapSavingsRate,
      'includeKs': snapIncludeKs ? 1.0 : 0.0,
    };
    final results = <String, double>{
      'target': target,
      'needed': max(0.0, target - startSav),
      'months': months.toDouble(),
    };

    final labelCtrl = TextEditingController(text: 'NZ Deposit Savings');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/nz_deposit_calc/save'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Savings Plan',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Target: ${CurrencyFormatter.compact(target, symbol: 'NZ\$')} · Timeline: ${months == 0 ? "Ready" : "$months months"}',
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
                hintText: 'Label (e.g. First Home Fund)',
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
          : 'Savings Plan';

      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'Deposit Planner',
        inputs: inputs,
        results: results,
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

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    final double rawPrice = double.tryParse(_priceController.text) ?? 800000;
    final double rawCurrent = double.tryParse(_currentController.text) ?? 22000;
    final double rawKs = double.tryParse(_ksController.text) ?? 28000;
    final double rawMonthly = double.tryParse(_monthlyController.text) ?? 2800;
    final double rawDepPct = _depPct;
    final double rawSavingsRate = _savingsRate;
    final bool rawIncludeKs = _includeKs;

    final double price = _showResults ? (_calcSnapshot['price'] ?? rawPrice) : rawPrice;
    final double current = _showResults ? (_calcSnapshot['current'] ?? rawCurrent) : rawCurrent;
    final double ks = _showResults ? (_calcSnapshot['ks'] ?? rawKs) : rawKs;
    final double monthly = _showResults ? (_calcSnapshot['monthly'] ?? rawMonthly) : rawMonthly;
    final double depPct = _showResults ? (_calcSnapshot['depPct'] ?? rawDepPct) : rawDepPct;
    final double savingsRate = _showResults ? (_calcSnapshot['savingsRate'] ?? rawSavingsRate) : rawSavingsRate;
    final bool includeKs = _showResults ? (_calcSnapshot['includeKs'] ?? rawIncludeKs) : rawIncludeKs;

    final double target = price * depPct / 100;
    final double startSav = current + (includeKs ? ks : 0);
    final double needed = max(0.0, target - startSav);
    final int months = _calcMonthsToGoal(target, startSav, monthly, savingsRate);
    final double yrs = months / 12;

    // Total with interest
    final double r = savingsRate / 12 / 100;
    double finalBalance = startSav;
    for (int m = 0; m < months; m++) {
      finalBalance = finalBalance * (1 + r) + monthly;
    }

    final double progressPct = min(100.0, target > 0 ? (startSav / target * 100) : 0.0);

    final isDirty = _showResults && (
      _priceController.text != (_calcSnapshot['price']?.toString() ?? '') ||
      _currentController.text != (_calcSnapshot['current']?.toString() ?? '') ||
      _ksController.text != (_calcSnapshot['ks']?.toString() ?? '') ||
      _monthlyController.text != (_calcSnapshot['monthly']?.toString() ?? '') ||
      _depPct != (_calcSnapshot['depPct'] ?? 0.0) ||
      _savingsRate != (_calcSnapshot['savingsRate'] ?? 0.0) ||
      _includeKs != (_calcSnapshot['includeKs'] ?? true)
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title banner
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Goal',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: theme.getTextColor(context),
              ),
            ),
            GestureDetector(
              onTap: _reset,
              child: Text(
                'Reset ↺',
                style: AppTextStyles.dmSans(
                  size: 11,
                  color: const Color(0xFFC0392B),
                  weight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Result Hero Card
        Container(
          padding: const EdgeInsets.all(20),
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
                'DEPOSIT SAVINGS GOAL · NZD',
                style: AppTextStyles.dmSans(
                  size: 8,
                  color: Colors.white70,
                  weight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                months == 0
                    ? '🎉 Ready Now!'
                    : yrs < 1
                        ? '$months months'
                        : '${yrs.toStringAsFixed(1)} years',
                style: AppTextStyles.playfair(
                  size: 34,
                  weight: FontWeight.w800,
                  color: const Color(0xFFF5D060),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'to save ${CurrencyFormatter.compact(target, symbol: 'NZ\$')} (${depPct.toStringAsFixed(0)}% of ${CurrencyFormatter.compact(price, symbol: 'NZ\$')})',
                style: AppTextStyles.dmSans(
                  size: 10.5,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildHeroBox(
                      'Target Deposit',
                      CurrencyFormatter.compact(target, symbol: 'NZ\$'),
                      const Color(0xFFF5D060),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroBox(
                      'Monthly Saving',
                      '${CurrencyFormatter.compact(monthly, symbol: 'NZ\$')}/mo',
                      const Color(0xFF0EA5E9),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeroBox(
                      'Total with Interest',
                      CurrencyFormatter.compact(finalBalance, symbol: 'NZ\$'),
                      const Color(0xFF5EEAD4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Progress Ring Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '💰 Current Progress',
                style: AppTextStyles.playfair(
                  size: 13,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: SizedBox(
                  height: 100,
                  width: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 90,
                        width: 90,
                        child: CircularProgressIndicator(
                          value: progressPct / 100,
                          strokeWidth: 10,
                          backgroundColor: theme.getBgColor(context),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF0EA5E9)),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${progressPct.toStringAsFixed(0)}%',
                            style: AppTextStyles.playfair(
                              size: 20,
                              weight: FontWeight.w800,
                              color: const Color(0xFF0EA5E9),
                            ),
                          ),
                          Text(
                            'Saved',
                            style: AppTextStyles.dmSans(
                              size: 9,
                              color: theme.getMutedColor(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildProgressBox('Current Savings', current),
                  _buildProgressBox('Still Needed', needed),
                  _buildProgressBox('KiwiSaver Est.', ks),
                  _buildProgressBox('With KiwiSaver', max(0.0, target - current - ks)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Inputs Card
        Text(
          'Your Savings Plan',
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
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🏦 ', style: TextStyle(fontSize: 16)),
                  Text(
                    'Property & Savings',
                    style: AppTextStyles.playfair(
                      size: 13,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TARGET PROPERTY PRICE (NZD)',
                      style: AppTextStyles.dmSans(
                          size: 8,
                          weight: FontWeight.w800,
                          color: theme.getMutedColor(context))),
                  const SizedBox(height: 6),
                  _buildInputField(_priceController, _errors['price']),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DEPOSIT TARGET',
                      style: AppTextStyles.dmSans(
                          size: 8,
                          weight: FontWeight.w800,
                          color: theme.getMutedColor(context))),
                  const SizedBox(height: 6),
                  Row(
                    children: [10.0, 20.0, 25.0, 30.0].map((val) {
                      final active = _depPct == val;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: InkWell(
                            onTap: () => setState(() => _depPct = val),
                            child: Container(
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xFF0EA5E9)
                                    : theme.getBgColor(context),
                                border: Border.all(
                                  color: active
                                      ? const Color(0xFF0EA5E9)
                                      : theme.getBorderColor(context),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${val.toStringAsFixed(0)}%',
                                style: AppTextStyles.dmSans(
                                  size: 10.5,
                                  weight: FontWeight.bold,
                                  color: active ? Colors.white : theme.getTextColor(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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
                        Text('CURRENT SAVINGS',
                            style: AppTextStyles.dmSans(
                                size: 8,
                                weight: FontWeight.w800,
                                color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        _buildInputField(_currentController, _errors['current']),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('KIWISAVER BALANCE',
                            style: AppTextStyles.dmSans(
                                size: 8,
                                weight: FontWeight.w800,
                                color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        _buildInputField(_ksController, _errors['ks']),
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
                        Text('MONTHLY SAVINGS',
                            style: AppTextStyles.dmSans(
                                size: 8,
                                weight: FontWeight.w800,
                                color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        _buildInputField(_monthlyController, _errors['monthly']),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SAVINGS RATE',
                            style: AppTextStyles.dmSans(
                                size: 8,
                                weight: FontWeight.w800,
                                color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: theme.getBgColor(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.getBorderColor(context)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<double>(
                              value: _savingsRate,
                              isExpanded: true,
                              dropdownColor: theme.getCardColor(context),
                              items: const [
                                DropdownMenuItem(
                                    value: 4.5, child: Text('4.50% (ANZ/ASB)')),
                                DropdownMenuItem(
                                    value: 4.8, child: Text('4.80% (Best rate)')),
                                DropdownMenuItem(
                                    value: 5.0, child: Text('5.00% (Term)')),
                                DropdownMenuItem(
                                    value: 5.5, child: Text('5.50% (Online)')),
                              ],
                              onChanged: (val) =>
                                  setState(() => _savingsRate = val ?? 4.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('INCLUDE KIWISAVER WITHDRAWAL?',
                      style: AppTextStyles.dmSans(
                          size: 8,
                          weight: FontWeight.w800,
                          color: theme.getMutedColor(context))),
                  const SizedBox(height: 6),
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: theme.getBgColor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.getBorderColor(context)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<bool>(
                        value: _includeKs,
                        isExpanded: true,
                        dropdownColor: theme.getCardColor(context),
                        items: const [
                          DropdownMenuItem(
                              value: true, child: Text('Yes — use KiwiSaver')),
                          DropdownMenuItem(
                              value: false, child: Text('No — savings only')),
                        ],
                        onChanged: (val) =>
                            setState(() => _includeKs = val ?? true),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('🔑 Calculate Savings Timeline',
                    style: AppTextStyles.playfair(
                        size: 13,
                        weight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ],
          ),
        ),

        // Savings Trajectory Chart Card
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
                      'Inputs have changed. Tap Calculate Savings Timeline to refresh results.',
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
                Text(
                  'Savings Trajectory',
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
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.getBorderColor(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Projected Balance',
                            style: AppTextStyles.playfair(
                              size: 13,
                              weight: FontWeight.w800,
                              color: theme.getTextColor(context),
                            ),
                          ),
                          Text(
                            'Monthly View',
                            style: AppTextStyles.dmSans(
                              size: 9,
                              color: const Color(0xFF0EA5E9),
                              weight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Custom Painter Savings Chart
                      SizedBox(
                        height: 140,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _NZDepositSavingsChartPainter(
                            start: startSav,
                            monthly: monthly,
                            target: target,
                            rate: savingsRate,
                            months: months,
                            theme: theme,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Scenarios Card
                Text(
                  'Savings Scenarios',
                  style: AppTextStyles.playfair(
                    size: 12,
                    weight: FontWeight.w800,
                    color: theme.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.25,
                  children: [
                    _buildScenarioCard('Save \$1K/mo', 1000, startSav, target, months),
                    _buildScenarioCard('Save \$2K/mo', 2000, startSav, target, months),
                    _buildScenarioCard('Current Plan', monthly, startSav, target, months, highlight: true),
                    _buildScenarioCard('Save \$5K/mo', 5000, startSav, target, months),
                  ],
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: _saveCalculation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A6B4A),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('💾 ', style: TextStyle(fontSize: 14)),
                      Text('Save This Savings Plan',
                          style: AppTextStyles.playfair(
                              size: 12,
                              weight: FontWeight.w800,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Tips Card
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0xFF93C5FD)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '💡 NZ First Home Saver Tips',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E40AF),
                ),
              ),
              const SizedBox(height: 6),
              ...[
                'Open a First Home Saver account for higher interest rates.',
                'Maximise KiwiSaver contributions — it counts toward your deposit.',
                'Apply for the KiwiSaver HomeStart Grant (up to \$10K new / \$5K existing).',
                'Consider a 10% deposit with LVR exemption for first-home buyers.',
                'Interest on NZ savings is taxed at your RWT/PIE rate (typically 17.5–28%).'
              ].map((text) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ',
                            style: TextStyle(
                                fontSize: 9, color: Color(0xFF1D4ED8))),
                        Expanded(
                          child: Text(
                            text,
                            style: AppTextStyles.dmSans(
                              size: 9.5,
                              color: const Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBox(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.dmSans(
              size: 7,
              color: Colors.white60,
              weight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.dmSans(
              size: 11.5,
              weight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBox(String label, double val) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.getBgColor(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(
              size: 8.5,
              color: theme.getMutedColor(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            CurrencyFormatter.compact(val, symbol: 'NZ\$'),
            style: AppTextStyles.dmSans(
              size: 12,
              weight: FontWeight.bold,
              color: theme.getTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String? errorText) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: errorText != null ? Colors.red : theme.getBorderColor(context)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: AppTextStyles.dmSans(
                size: 14, weight: FontWeight.w700, color: theme.getTextColor(context)),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: InputBorder.none,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 2),
          Text(errorText, style: AppTextStyles.dmSans(size: 9, color: Colors.red, weight: FontWeight.bold)),
        ],
      ],
    );
  }

  Widget _buildScenarioCard(
      String label, double scenMonthly, double startSav, double target, int currentMonths,
      {bool highlight = false}) {
    final theme = widget.theme;
    final int scenMonths = _calcMonthsToGoal(target, startSav, scenMonthly, _savingsRate);
    final double y = scenMonths / 12;

    final diff = scenMonths - currentMonths;
    final diffY = (diff.abs() / 12);

    final bg = highlight
        ? const Color(0xFF0A0F0D)
        : theme.getCardColor(context);

    final border = highlight
        ? Border.all(color: const Color(0xFF0D3B2E), width: 1.5)
        : Border.all(color: theme.getBorderColor(context));

    final textCol = highlight ? Colors.white : theme.getTextColor(context);
    final mutedCol = highlight ? Colors.white70 : theme.getMutedColor(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        border: border,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(
              size: 8.5,
              weight: FontWeight.bold,
              color: mutedCol,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            scenMonths == 0 ? '✅ Done' : '${y.toStringAsFixed(1)} yrs',
            style: AppTextStyles.playfair(
              size: 16,
              weight: FontWeight.bold,
              color: highlight ? const Color(0xFFF5D060) : textCol,
            ),
          ),
          Text(
            scenMonths == 0 ? 'Already saved' : '$scenMonths months',
            style: AppTextStyles.dmSans(
              size: 9,
              color: mutedCol,
            ),
          ),
          if (!highlight && currentMonths > 0) ...[
            const SizedBox(height: 4),
            Text(
              diff > 0
                  ? '↑ ${diffY.toStringAsFixed(1)} yrs slower'
                  : '↓ ${diffY.toStringAsFixed(1)} yrs faster',
              style: AppTextStyles.dmSans(
                size: 9,
                weight: FontWeight.bold,
                color: diff > 0 ? const Color(0xFFC0392B) : const Color(0xFF15803D),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NZDepositSavingsChartPainter extends CustomPainter {
  final double start;
  final double monthly;
  final double target;
  final double rate;
  final int months;
  final CountryTheme theme;

  _NZDepositSavingsChartPainter({
    required this.start,
    required this.monthly,
    required this.target,
    required this.rate,
    required this.months,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double W = size.width;
    final double H = size.height;
    const double padL = 40.0;
    const double padR = 10.0;
    const double padT = 10.0;
    const double padB = 20.0;

    final double cW = W - padL - padR;
    final double cH = H - padT - padB;

    final double r = rate / 12 / 100;
    final double maxVal = target * 1.05;

    final List<Offset> points = [];
    double bal = start;

    final int step = max(1, (months / 30).floor());
    for (int m = 0; m <= months; m += step) {
      final double x = padL + (m / (months > 0 ? months : 1)) * cW;
      final double y = padT + cH - (min(bal, maxVal) / maxVal) * cH;
      points.add(Offset(x, y));

      for (int i = 0; i < step && m + i < months; i++) {
        bal = bal * (1 + r) + monthly;
      }
    }

    if (points.isNotEmpty && points.last.dx < padL + cW) {
      final double x = padL + cW;
      final double y = padT + cH - (min(bal, maxVal) / maxVal) * cH;
      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    // Draw grid & Y labels
    final Paint gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 1;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= 2; i++) {
      final double f = i / 2;
      final double val = maxVal * f;
      final double y = padT + cH - f * cH;
      final String lbl = val >= 1000000
          ? '${(val / 1000000).toStringAsFixed(1)}M'
          : '${(val / 1000).toStringAsFixed(0)}K';

      textPainter.text = TextSpan(
        text: '\$$lbl',
        style: const TextStyle(fontSize: 8, color: Colors.grey),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(padL - textPainter.width - 4, y - 4));

      if (i > 0) {
        canvas.drawLine(Offset(padL, y), Offset(padL + cW, y), gridPaint);
      }
    }

    // Target Line
    final double ty = padT + cH - (target / maxVal) * cH;
    final Paint targetPaint = Paint()
      ..color = const Color(0xFFD4A017)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(padL, ty), Offset(padL + cW, ty), targetPaint);
    textPainter.text = const TextSpan(
      text: 'Goal',
      style: TextStyle(fontSize: 7.5, color: Color(0xFFD4A017), fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(padL + cW - textPainter.width - 2, ty - 9));

    // Area Gradient
    final Path areaPath = Path()..moveTo(points.first.dx, padT + cH);
    for (final pt in points) {
      areaPath.lineTo(pt.dx, pt.dy);
    }
    areaPath.lineTo(points.last.dx, padT + cH);
    areaPath.close();

    final Paint areaPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF0EA5E9).withValues(alpha: 0.25), const Color(0xFF0EA5E9).withValues(alpha: 0.01)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(padL, padT, cW, cH));

    canvas.drawPath(areaPath, areaPaint);

    // Line Path
    final Path linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final Paint linePaint = Paint()
      ..color = const Color(0xFF0EA5E9)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    // Endpoint dots
    final Paint dotPaint = Paint()..color = const Color(0xFF0EA5E9);
    final Paint dotStroke = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final pt in [points.first, points[points.length ~/ 2], points.last]) {
      canvas.drawCircle(pt, 3.5, dotPaint);
      canvas.drawCircle(pt, 3.5, dotStroke);
    }

    // X Labels
    final int currentYear = DateTime.now().year;
    for (int i = 0; i <= 2; i++) {
      final double f = i / 2;
      final int m = (f * months).round();
      final int yr = currentYear + (m / 12).floor();
      textPainter.text = TextSpan(
        text: '$yr',
        style: const TextStyle(fontSize: 8, color: Colors.grey),
      );
      textPainter.layout();
      canvas.drawText(
        canvas,
        textPainter,
        Offset(padL + f * cW - textPainter.width / 2, H - 10),
      );
    }
  }


  @override
  bool shouldRepaint(covariant _NZDepositSavingsChartPainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.monthly != monthly ||
        oldDelegate.target != target ||
        oldDelegate.rate != rate ||
        oldDelegate.months != months;
  }
}

extension on Canvas {
  void drawText(Canvas canvas, TextPainter tp, Offset offset) {
    tp.paint(canvas, offset);
  }
}
