// lib/features/newzealand/tools/nz_revolving_credit.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZRevolvingCredit extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZRevolvingCredit({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZRevolvingCredit> createState() => _NZRevolvingCreditState();
}

class _NZRevolvingCreditState extends ConsumerState<NZRevolvingCredit> {
  final _homeValController = TextEditingController(text: '850000');
  final _mortgageBalController = TextEditingController(text: '420000');
  final _rcLimitController = TextEditingController(text: '50000');
  final _rcRateController = TextEditingController(text: '8.70');
  final _monthlySalaryController = TextEditingController(text: '8000');
  final _monthlyExpController = TextEditingController(text: '4500');

  double _drawn = 20000.0;
  bool _showResults = false;
  final Map<String, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};
  final _resultsKey = GlobalKey();

  @override
  void dispose() {
    _homeValController.dispose();
    _mortgageBalController.dispose();
    _rcLimitController.dispose();
    _rcRateController.dispose();
    _monthlySalaryController.dispose();
    _monthlyExpController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _homeValController.text = '850000';
      _mortgageBalController.text = '420000';
      _rcLimitController.text = '50000';
      _rcRateController.text = '8.70';
      _monthlySalaryController.text = '8000';
      _monthlyExpController.text = '4500';
      _drawn = 20000.0;
      _showResults = false;
      _calcSnapshot.clear();
      _errors.clear();
    });
  }

  void _calculate() {
    final errors = <String, String>{};
    final double homeVal = double.tryParse(_homeValController.text) ?? 0.0;
    final double mortBal = double.tryParse(_mortgageBalController.text) ?? 0.0;
    final double limit = double.tryParse(_rcLimitController.text) ?? 0.0;
    final double rate = double.tryParse(_rcRateController.text) ?? 0.0;
    final double salary = double.tryParse(_monthlySalaryController.text) ?? 0.0;
    final double expenses = double.tryParse(_monthlyExpController.text) ?? 0.0;

    if (homeVal <= 0) {
      errors['homeVal'] = 'Enter valid home value';
    }
    if (mortBal < 0) {
      errors['mortBal'] = 'Mortgage balance cannot be negative';
    }
    if (limit <= 0) {
      errors['rcLimit'] = 'Enter valid revolving limit';
    }
    if (rate < 0) {
      errors['rcRate'] = 'Interest rate cannot be negative';
    }
    if (salary < 0) {
      errors['salary'] = 'Income cannot be negative';
    }
    if (expenses < 0) {
      errors['expenses'] = 'Expenses cannot be negative';
    }

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) return;

    setState(() {
      _calcSnapshot['homeVal'] = homeVal;
      _calcSnapshot['mortBal'] = mortBal;
      _calcSnapshot['rcLimit'] = limit;
      _calcSnapshot['rcRate'] = rate;
      _calcSnapshot['drawn'] = _drawn > limit ? limit : _drawn;
      _calcSnapshot['salary'] = salary;
      _calcSnapshot['expenses'] = expenses;
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

  void _saveCalculation(
    double dailyInt,
    double monthlyInt,
    double annualInt,
    double available,
    double maxEquity,
    double netSurplus,
  ) async {
    final double homeVal = _calcSnapshot['homeVal'] ?? (double.tryParse(_homeValController.text) ?? 850000.0);
    final double mortBal = _calcSnapshot['mortBal'] ?? (double.tryParse(_mortgageBalController.text) ?? 420000.0);
    final double limit = _calcSnapshot['rcLimit'] ?? (double.tryParse(_rcLimitController.text) ?? 50000.0);
    final double rate = (_calcSnapshot['rcRate'] ?? (double.tryParse(_rcRateController.text) ?? 8.70)) / 100;
    final double snapDrawn = _calcSnapshot['drawn'] ?? _drawn;
    final double salary = _calcSnapshot['salary'] ?? (double.tryParse(_monthlySalaryController.text) ?? 8000.0);
    final double expenses = _calcSnapshot['expenses'] ?? (double.tryParse(_monthlyExpController.text) ?? 4500.0);

    final labelCtrl = TextEditingController(text: 'NZ Revolving Credit');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/nz_revolving_credit/save'),
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
              'Limit: ${CurrencyFormatter.compact(limit, symbol: 'NZ\$')} · Drawn: ${CurrencyFormatter.compact(snapDrawn, symbol: 'NZ\$')} · Monthly Cost: ${CurrencyFormatter.compact(monthlyInt, symbol: 'NZ\$')}',
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
                hintText: 'Label (e.g. My Credit Goal)',
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
          : 'Revolving Credit';

      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'Revolving Credit',
        inputs: {
          'homeVal': homeVal,
          'mortBal': mortBal,
          'rcLimit': limit,
          'rcRate': rate * 100,
          'drawn': snapDrawn,
          'salary': salary,
          'expenses': expenses,
        },
        results: {
          'dailyInt': dailyInt,
          'monthlyInt': monthlyInt,
          'annualInt': annualInt,
          'available': available,
          'usableEquity': maxEquity,
          'netSurplus': netSurplus,
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Revolving Credit assessment saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF1A6B4A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildInputBox(TextEditingController controller, {String? errorText}) {
    final theme = widget.theme;
    return Container(
      height: errorText != null ? 58 : 44,
      decoration: BoxDecoration(
        color: theme.getBgColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: errorText != null ? Colors.red : theme.getBorderColor(context)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTextStyles.dmSans(
                  size: 14, weight: FontWeight.w700, color: theme.getTextColor(context)),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.zero,
                isDense: true,
                border: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                errorText,
                style: AppTextStyles.dmSans(size: 8, color: Colors.red, weight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    // Read parameters from snapshot if results are shown, else live controllers
    final double homeVal = _showResults
        ? (_calcSnapshot['homeVal'] ?? 0.0)
        : (double.tryParse(_homeValController.text) ?? 0.0);
    final double mortBal = _showResults
        ? (_calcSnapshot['mortBal'] ?? 0.0)
        : (double.tryParse(_mortgageBalController.text) ?? 0.0);
    final double limit = _showResults
        ? (_calcSnapshot['rcLimit'] ?? 0.0)
        : (double.tryParse(_rcLimitController.text) ?? 0.0);
    final double rate = (_showResults
        ? (_calcSnapshot['rcRate'] ?? 8.70)
        : (double.tryParse(_rcRateController.text) ?? 8.70)) / 100;
    final double snapDrawn = _showResults
        ? (_calcSnapshot['drawn'] ?? 0.0)
        : _drawn;
    final double salary = _showResults
        ? (_calcSnapshot['salary'] ?? 0.0)
        : (double.tryParse(_monthlySalaryController.text) ?? 0.0);
    final double expenses = _showResults
        ? (_calcSnapshot['expenses'] ?? 0.0)
        : (double.tryParse(_monthlyExpController.text) ?? 0.0);

    // Adjust _drawn bounds based on limit
    final double currentLimit = double.tryParse(_rcLimitController.text) ?? 50000.0;
    if (_drawn > currentLimit) {
      _drawn = currentLimit;
    }

    final double dailyInt = snapDrawn * rate / 365;
    final double monthlyInt = snapDrawn * rate / 12;
    final double annualInt = snapDrawn * rate;
    final double available = limit - snapDrawn;
    final double maxEquity = homeVal * 0.80 - mortBal;
    final double netSurplus = salary - expenses - monthlyInt;
    final double pct = limit > 0 ? snapDrawn / limit : 0.0;

    final double monthlyParkSaving = salary * rate / 12;

    final isDirty = _showResults && (
      (double.tryParse(_homeValController.text) ?? 0.0) != (_calcSnapshot['homeVal'] ?? 0.0) ||
      (double.tryParse(_mortgageBalController.text) ?? 0.0) != (_calcSnapshot['mortBal'] ?? 0.0) ||
      (double.tryParse(_rcLimitController.text) ?? 0.0) != (_calcSnapshot['rcLimit'] ?? 0.0) ||
      (double.tryParse(_rcRateController.text) ?? 0.0) != (_calcSnapshot['rcRate'] ?? 0.0) ||
      (double.tryParse(_monthlySalaryController.text) ?? 0.0) != (_calcSnapshot['salary'] ?? 0.0) ||
      (double.tryParse(_monthlyExpController.text) ?? 0.0) != (_calcSnapshot['expenses'] ?? 0.0) ||
      _drawn != (_calcSnapshot['drawn'] ?? 0.0)
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Revolving Credit Tool',
              style: AppTextStyles.playfair(
                size: 15,
                weight: FontWeight.w800,
                color: theme.getTextColor(context),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                border: Border.all(color: const Color(0xFF99F6E4)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'NZ Specific',
                style: AppTextStyles.dmSans(
                  size: 9,
                  color: const Color(0xFF0D9488),
                  weight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Info Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A0F0D), Color(0xFF0D3B2E)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Text('🏦', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REVOLVING CREDIT FACILITY',
                      style: AppTextStyles.dmSans(
                        size: 8,
                        color: Colors.white60,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Flexible Access',
                      style: AppTextStyles.playfair(
                        size: 18,
                        weight: FontWeight.w800,
                        color: const Color(0xFFF5D060),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Draw & repay anytime · Interest on balance used · ANZ, ASB, BNZ, Kiwibank, Westpac',
                      style: AppTextStyles.dmSans(
                        size: 9,
                        color: Colors.white70,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Calculator Inputs
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Revolving Credit Setup',
              style: AppTextStyles.playfair(
                size: 12,
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
                  color: const Color(0xFF0D9488),
                  weight: FontWeight.bold,
                ),
              ),
            ),
          ],
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
              Text(
                '🔄 Enter Details',
                style: AppTextStyles.playfair(
                  size: 13,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 12),
              Text('HOME VALUE (NZD)',
                  style: AppTextStyles.dmSans(
                      size: 8, weight: FontWeight.w800, color: theme.getMutedColor(context))),
              const SizedBox(height: 6),
              _buildInputBox(_homeValController, errorText: _errors['homeVal']),
              const SizedBox(height: 12),

              Text('OUTSTANDING MORTGAGE BALANCE (NZD)',
                  style: AppTextStyles.dmSans(
                      size: 8, weight: FontWeight.w800, color: theme.getMutedColor(context))),
              const SizedBox(height: 6),
              _buildInputBox(_mortgageBalController, errorText: _errors['mortBal']),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('REVOLVING LIMIT',
                            style: AppTextStyles.dmSans(
                                size: 8,
                                weight: FontWeight.w800,
                                color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        _buildInputBox(_rcLimitController, errorText: _errors['rcLimit']),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('INTEREST RATE (%)',
                            style: AppTextStyles.dmSans(
                                size: 8,
                                weight: FontWeight.w800,
                                color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        _buildInputBox(_rcRateController, errorText: _errors['rcRate']),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text('AMOUNT CURRENTLY DRAWN',
                  style: AppTextStyles.dmSans(
                      size: 8, weight: FontWeight.w800, color: theme.getMutedColor(context))),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Drawn Limit',
                    style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)),
                  ),
                  Text(
                    CurrencyFormatter.compact(_drawn, symbol: 'NZ\$'),
                    style: AppTextStyles.dmSans(
                        size: 13, weight: FontWeight.w800, color: const Color(0xFF0D9488)),
                  ),
                ],
              ),
              Slider(
                value: _drawn,
                min: 0,
                max: currentLimit > 0 ? currentLimit : 100000,
                activeColor: const Color(0xFF0D9488),
                inactiveColor: const Color(0xFFE8F0EC),
                onChanged: (val) => setState(() => _drawn = val),
              ),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MONTHLY INCOME CREDITED',
                            style: AppTextStyles.dmSans(
                                size: 8,
                                weight: FontWeight.w800,
                                color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        _buildInputBox(_monthlySalaryController, errorText: _errors['salary']),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MONTHLY EXPENSES',
                            style: AppTextStyles.dmSans(
                                size: 8,
                                weight: FontWeight.w800,
                                color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        _buildInputBox(_monthlyExpController, errorText: _errors['expenses']),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text(
                  'Calculate Revolving Credit',
                  style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Results Analysis
        if (_showResults) ...[
          if (isDirty) ...[
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
                      'Inputs have changed. Tap Calculate Revolving Credit to refresh results.',
                      style: AppTextStyles.dmSans(size: 11, color: Colors.amber[800], weight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            key: _resultsKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Facility Analysis',
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
                      colors: [Color(0xFF0A0F0D), Color(0xFF0D3B2E)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR REVOLVING CREDIT ANALYSIS',
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
                          _buildResultBox('Daily Interest Cost', CurrencyFormatter.format(dailyInt, decimalDigits: 2, symbol: 'NZ\$'), 'On drawn amount', true),
                          _buildResultBox('Monthly Interest', CurrencyFormatter.compact(monthlyInt, symbol: 'NZ\$'), 'At current draw', false),
                          _buildResultBox('Available to Draw', CurrencyFormatter.compact(available, symbol: 'NZ\$'), 'Remaining facility', false),
                          _buildResultBox('Usable Equity', CurrencyFormatter.compact(max(0, maxEquity), symbol: 'NZ\$'), '80% LVR limit', false),
                          _buildResultBox('Net Monthly Surplus', CurrencyFormatter.compact(netSurplus, symbol: 'NZ\$'), 'Income - Exp - Int', false),
                          _buildResultBox('Annual Interest', CurrencyFormatter.compact(annualInt, symbol: 'NZ\$'), 'Full year cost', false),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Donut Chart
                      Center(
                        child: SizedBox(
                          height: 140,
                          width: 140,
                          child: CustomPaint(
                            painter: _NZRevolvingCreditDonutPainter(percent: pct),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${(pct * 100).round()}%',
                                    style: AppTextStyles.playfair(
                                        size: 20, weight: FontWeight.w800, color: Colors.white),
                                  ),
                                  Text(
                                    'Facility Used',
                                    style: AppTextStyles.dmSans(size: 8, color: Colors.white54),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Legend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem(const Color(0xFF0D9488), 'Drawn'),
                          const SizedBox(width: 14),
                          _buildLegendItem(const Color(0xFFF5D060), 'Available'),
                          const SizedBox(width: 14),
                          _buildLegendItem(Colors.white12, 'Unencumbered'),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Parking savings banner
                      if (salary > 0)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5).withValues(alpha: 0.1),
                            border: Border.all(color: const Color(0xFF6EE7B7).withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Row(
                            children: [
                              const Text('💡', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Parking salary saves ${CurrencyFormatter.compact(monthlyParkSaving, symbol: 'NZ\$')}/mo',
                                      style: AppTextStyles.dmSans(
                                          size: 11.5, weight: FontWeight.w800, color: const Color(0xFF6EE7B7)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Credit your full salary to RC to minimise daily balance & interest',
                                      style: AppTextStyles.dmSans(size: 9, color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 14),

                      ElevatedButton.icon(
                        onPressed: () => _saveCalculation(dailyInt, monthlyInt, annualInt, available, maxEquity, netSurplus),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white30),
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                        ),
                        icon: const Text('💾', style: TextStyle(fontSize: 14)),
                        label: Text(
                          'Save Calculation',
                          style: AppTextStyles.playfair(size: 13, weight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Interest Scenario Table
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
                        '📅 Interest Scenario Table',
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
                          2: FlexColumnWidth(1.1),
                          3: FlexColumnWidth(1.0),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.getBorderColor(context)))),
                            children: [
                              _tableHeader('Amount Drawn'),
                              _tableHeader('Monthly Int.'),
                              _tableHeader('Annual Cost'),
                              _tableHeader('vs Salary %'),
                            ],
                          ),
                          ..._generateTableRows(limit, rate, salary, theme),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],

        // How NZ Revolving Credit works
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
                '🇳🇿 How NZ Revolving Credit Works',
                style: AppTextStyles.playfair(
                  size: 14,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 14),
              _buildStepItem(
                1,
                'Equity-Based Facility',
                'NZ banks lend up to 80% LVR. E.g. \$850K home, \$420K mortgage leaves up to \$260K potential credit limit.',
              ),
              _buildStepItem(
                2,
                'Salary Credited Instantly',
                'Your pay goes directly into the revolving account, reducing the balance on day 1. Withdraw money as you need it for bills.',
              ),
              _buildStepItem(
                3,
                'Interest Calculated Daily',
                'ASB Orbit, Westpac Choices, ANZ Flexi - interest is calculated daily on the balance remaining at end of day, then charged monthly.',
              ),
              _buildStepItem(
                4,
                'Tax Deductibility Notes',
                'Owner-occupied home loan interest is NOT deductible. For investment properties, check IRD rules regarding interest claiming.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildResultBox(String title, String val, String sub, bool highlight) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFF0D9488).withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.09),
        border: Border.all(
          color: highlight ? const Color(0xFF0D9488).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.14),
        ),
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
                color: highlight ? const Color(0xFF6EE7B7) : Colors.white),
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

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.dmSans(size: 9, color: Colors.white60),
        ),
      ],
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
                colors: [Color(0xFF0D9488), Color(0xFF0D3B2E)],
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
                      size: 9.5, color: theme.getMutedColor(context), height: 1.4),
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

  List<TableRow> _generateTableRows(double limit, double rate, double salary, CountryTheme theme) {
    final List<double> scenarios = [5000, 10000, 20000, 30000, limit];
    final List<double> uniqueScenarios = scenarios.toSet().toList();
    uniqueScenarios.sort();

    return uniqueScenarios.map((amt) {
      final double mi = amt * rate / 12;
      final double ai = amt * rate;
      final String pctSal = salary > 0 ? '${((mi / salary) * 100).toStringAsFixed(1)}%' : '—';

      return TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(CurrencyFormatter.compact(amt, symbol: 'NZ\$'),
                style: AppTextStyles.dmSans(size: 10, color: theme.getTextColor(context))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(CurrencyFormatter.compact(mi, symbol: 'NZ\$'),
                style: AppTextStyles.dmSans(size: 10, color: theme.getTextColor(context))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(CurrencyFormatter.compact(ai, symbol: 'NZ\$'),
                style: AppTextStyles.dmSans(size: 10, color: theme.getTextColor(context))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(pctSal,
                style: AppTextStyles.dmSans(
                    size: 10, weight: FontWeight.bold, color: theme.primaryColor)),
          ),
        ],
      );
    }).toList();
  }
}

class _NZRevolvingCreditDonutPainter extends CustomPainter {
  final double percent;
  const _NZRevolvingCreditDonutPainter({required this.percent});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final center = Offset(radius, radius);
    const double strokeW = 12.0;
    final double ringRadius = radius - strokeW / 2;

    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;

    canvas.drawCircle(center, ringRadius, basePaint);

    final rect = Rect.fromCircle(center: center, radius: ringRadius);

    final fillPaint = Paint()
      ..color = const Color(0xFF0D9488)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (percent.clamp(0.0, 1.0)) * 2 * pi;
    canvas.drawArc(rect, -pi / 2, sweepAngle, false, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _NZRevolvingCreditDonutPainter oldDelegate) =>
      oldDelegate.percent != percent;
}
