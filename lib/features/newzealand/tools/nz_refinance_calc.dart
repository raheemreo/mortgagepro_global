// lib/features/newzealand/tools/nz_refinance_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class NZRefinanceCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZRefinanceCalc({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZRefinanceCalc> createState() => _NZRefinanceCalcState();
}

class _NZRefinanceCalcState extends ConsumerState<NZRefinanceCalc> {
  // Current Loan
  final _curBalController = TextEditingController(text: '520000');
  final _curRateController = TextEditingController(text: '7.29');
  final _curTermMosController = TextEditingController(text: '18');
  final _curLoanTermController = TextEditingController(text: '24');

  // New Loan
  final _newRateController = TextEditingController(text: '6.59');
  final _newTermController = TextEditingController(text: '24');
  final _wsFixedController = TextEditingController(text: '5.80');
  final _wsCurrentController = TextEditingController(text: '4.90');
  final _cashbackController = TextEditingController(text: '3000');
  final _legalController = TextEditingController(text: '1500');

  bool _showResults = false;
  final Map<String, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};
  final _resultsKey = GlobalKey();

  @override
  void dispose() {
    _curBalController.dispose();
    _curRateController.dispose();
    _curTermMosController.dispose();
    _curLoanTermController.dispose();
    _newRateController.dispose();
    _newTermController.dispose();
    _wsFixedController.dispose();
    _wsCurrentController.dispose();
    _cashbackController.dispose();
    _legalController.dispose();
    super.dispose();
  }

  double _pmt(double P, double annualRate, int months) {
    if (months <= 0) return 0;
    if (annualRate <= 0) return P / months;
    final double mr = (annualRate / 100) / 12;
    return P * mr * pow(1 + mr, months) / (pow(1 + mr, months) - 1);
  }

  void _reset() {
    setState(() {
      _curBalController.text = '520000';
      _curRateController.text = '7.29';
      _curTermMosController.text = '18';
      _curLoanTermController.text = '24';
      _newRateController.text = '6.59';
      _newTermController.text = '24';
      _wsFixedController.text = '5.80';
      _wsCurrentController.text = '4.90';
      _cashbackController.text = '3000';
      _legalController.text = '1500';
      _showResults = false;
      _calcSnapshot.clear();
      _errors.clear();
    });
  }

  void _calculate() {
    final errors = <String, String>{};
    final double curBal = double.tryParse(_curBalController.text) ?? 0.0;
    final double curRate = double.tryParse(_curRateController.text) ?? 0.0;
    final int curTermMos = int.tryParse(_curTermMosController.text) ?? 0;
    final int curLoanTerm = int.tryParse(_curLoanTermController.text) ?? 0;
    final double newRate = double.tryParse(_newRateController.text) ?? 0.0;
    final int newTerm = int.tryParse(_newTermController.text) ?? 0;
    final double wsFixed = double.tryParse(_wsFixedController.text) ?? 0.0;
    final double wsCurrent = double.tryParse(_wsCurrentController.text) ?? 0.0;
    final double cashback = double.tryParse(_cashbackController.text) ?? 0.0;
    final double legal = double.tryParse(_legalController.text) ?? 0.0;

    if (curBal <= 0) {
      errors['curBal'] = 'Enter valid current balance';
    }
    if (curRate < 0) {
      errors['curRate'] = 'Current rate cannot be negative';
    }
    if (curTermMos < 0) {
      errors['curTermMos'] = 'Term months cannot be negative';
    }
    if (curLoanTerm <= 0) {
      errors['curLoanTerm'] = 'Enter valid current loan term';
    }
    if (newRate < 0) {
      errors['newRate'] = 'New rate cannot be negative';
    }
    if (newTerm <= 0) {
      errors['newTerm'] = 'Enter valid new term';
    }
    if (wsFixed < 0) {
      errors['wsFixed'] = 'Wholesale rate cannot be negative';
    }
    if (wsCurrent < 0) {
      errors['wsCurrent'] = 'Wholesale rate cannot be negative';
    }
    if (cashback < 0) {
      errors['cashback'] = 'Cashback cannot be negative';
    }
    if (legal < 0) {
      errors['legal'] = 'Legal costs cannot be negative';
    }

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) return;

    setState(() {
      _calcSnapshot['curBal'] = curBal;
      _calcSnapshot['curRate'] = curRate;
      _calcSnapshot['curTermMos'] = curTermMos;
      _calcSnapshot['curLoanTerm'] = curLoanTerm;
      _calcSnapshot['newRate'] = newRate;
      _calcSnapshot['newTerm'] = newTerm;
      _calcSnapshot['wsFixed'] = wsFixed;
      _calcSnapshot['wsCurrent'] = wsCurrent;
      _calcSnapshot['cashback'] = cashback;
      _calcSnapshot['legal'] = legal;
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
    double breakFee,
    double netCost,
    double oldPmt,
    double newPmt,
    double monthlySaving,
    double totalIntSaved,
    double breakEvenMonths,
  ) async {
    final double curBal = _calcSnapshot['curBal'] ?? (double.tryParse(_curBalController.text) ?? 520000.0);
    final double curRate = _calcSnapshot['curRate'] ?? (double.tryParse(_curRateController.text) ?? 7.29);
    final int curTermMos = _calcSnapshot['curTermMos'] ?? (int.tryParse(_curTermMosController.text) ?? 18);
    final double newRate = _calcSnapshot['newRate'] ?? (double.tryParse(_newRateController.text) ?? 6.59);

    final labelCtrl = TextEditingController(text: 'NZ Refinance Calculator');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/nz_refinance_calc'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Refinance Calculation',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Break Fee: ${CurrencyFormatter.compact(breakFee, symbol: 'NZ\$')} · Monthly Saving: ${CurrencyFormatter.compact(monthlySaving, symbol: 'NZ\$')}',
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
                hintText: 'Label (e.g. Westpac Refinance Plan)',
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
          : 'Refinance Calc';

      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'Refinance Calc',
        inputs: {
          'balance': curBal,
          'curRate': curRate,
          'curTermMos': curTermMos.toDouble(),
          'newRate': newRate,
        },
        results: {
          'breakFee': breakFee,
          'netCost': netCost,
          'oldPmt': oldPmt,
          'newPmt': newPmt,
          'monthlySaving': monthlySaving,
          'totalIntSaved': totalIntSaved,
          'breakEvenMonths': breakEvenMonths,
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Refinance calculation saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF1A6B4A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildInputBox(TextEditingController controller, {String? hint, String? errorText}) {
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
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
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

    final double curBal = _showResults
        ? (_calcSnapshot['curBal'] ?? 0.0)
        : (double.tryParse(_curBalController.text) ?? 0.0);
    final double curRate = _showResults
        ? (_calcSnapshot['curRate'] ?? 0.0)
        : (double.tryParse(_curRateController.text) ?? 0.0);
    final int curTermMos = _showResults
        ? (_calcSnapshot['curTermMos'] ?? 0)
        : (int.tryParse(_curTermMosController.text) ?? 0);
    final int curLoanTerm = _showResults
        ? (_calcSnapshot['curLoanTerm'] ?? 0)
        : (int.tryParse(_curLoanTermController.text) ?? 0);

    final double newRate = _showResults
        ? (_calcSnapshot['newRate'] ?? 0.0)
        : (double.tryParse(_newRateController.text) ?? 0.0);
    final int newTerm = _showResults
        ? (_calcSnapshot['newTerm'] ?? 0)
        : (int.tryParse(_newTermController.text) ?? 0);

    final double wsFixed = _showResults
        ? (_calcSnapshot['wsFixed'] ?? 0.0)
        : (double.tryParse(_wsFixedController.text) ?? 0.0);
    final double wsCurrent = _showResults
        ? (_calcSnapshot['wsCurrent'] ?? 0.0)
        : (double.tryParse(_wsCurrentController.text) ?? 0.0);
    final double cashback = _showResults
        ? (_calcSnapshot['cashback'] ?? 0.0)
        : (double.tryParse(_cashbackController.text) ?? 0.0);
    final double legal = _showResults
        ? (_calcSnapshot['legal'] ?? 0.0)
        : (double.tryParse(_legalController.text) ?? 0.0);

    // Wholesale rate diff break fee formula
    final double rateDiff = (wsFixed - wsCurrent) / 100;
    final double breakFee = rateDiff > 0 ? (curBal * rateDiff * (curTermMos / 12)) : 0.0;
    final double netCost = breakFee + legal - cashback;

    final double oldPmt = _pmt(curBal, curRate, curLoanTerm * 12);
    final double newPmt = _pmt(curBal, newRate, newTerm * 12);
    final double monthlySaving = oldPmt - newPmt;

    final double breakEvenMonths = monthlySaving > 0 ? (netCost / monthlySaving) : double.infinity;

    final double totalIntOld = (oldPmt * curLoanTerm * 12) - curBal;
    final double totalIntNew = (newPmt * newTerm * 12) - curBal;
    final double totalIntSaved = totalIntOld - totalIntNew - breakFee - legal + cashback;

    final isDirty = _showResults && (
      (double.tryParse(_curBalController.text) ?? 0.0) != (_calcSnapshot['curBal'] ?? 0.0) ||
      (double.tryParse(_curRateController.text) ?? 0.0) != (_calcSnapshot['curRate'] ?? 0.0) ||
      (int.tryParse(_curTermMosController.text) ?? 0) != (_calcSnapshot['curTermMos'] ?? 0) ||
      (int.tryParse(_curLoanTermController.text) ?? 0) != (_calcSnapshot['curLoanTerm'] ?? 0) ||
      (double.tryParse(_newRateController.text) ?? 0.0) != (_calcSnapshot['newRate'] ?? 0.0) ||
      (int.tryParse(_newTermController.text) ?? 0) != (_calcSnapshot['newTerm'] ?? 0) ||
      (double.tryParse(_wsFixedController.text) ?? 0.0) != (_calcSnapshot['wsFixed'] ?? 0.0) ||
      (double.tryParse(_wsCurrentController.text) ?? 0.0) != (_calcSnapshot['wsCurrent'] ?? 0.0) ||
      (double.tryParse(_cashbackController.text) ?? 0.0) != (_calcSnapshot['cashback'] ?? 0.0) ||
      (double.tryParse(_legalController.text) ?? 0.0) != (_calcSnapshot['legal'] ?? 0.0)
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Refinance Calculator',
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
                'Fixed Rate Warning',
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

        // Break cost warning explainer
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
            ),
            border: Border.all(color: const Color(0xFFF59E0B)),
            borderRadius: BorderRadius.circular(13),
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
                      'NZ Break Costs Can Be Significant',
                      style: AppTextStyles.dmSans(
                          size: 12, weight: FontWeight.w800, color: const Color(0xFF92400E)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NZ banks calculate break fees based on wholesale interest rate movements. If wholesale rates have fallen since you locked in your fixed term, break costs can be extremely high. Always request a formal quote from your bank first.',
                      style: AppTextStyles.dmSans(
                          size: 9.5, color: const Color(0xFFB45309), height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Calculator Inputs Card
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Refinance Details',
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
                  color: const Color(0xFFC0392B),
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
                '🔁 Current Loan',
                style: AppTextStyles.playfair(
                  size: 13,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('REMAINING BALANCE (NZD)', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        _buildInputBox(_curBalController, errorText: _errors['curBal']),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CURRENT FIXED RATE (%)', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        _buildInputBox(_curRateController, errorText: _errors['curRate']),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('REMAINING FIXED TERM (MOS)', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        _buildInputBox(_curTermMosController, errorText: _errors['curTermMos']),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('REMAINING LOAN TERM (YRS)', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        _buildInputBox(_curLoanTermController, errorText: _errors['curLoanTerm']),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                '🏦 New Loan / Refinance Details',
                style: AppTextStyles.playfair(
                  size: 13,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NEW RATE (%)', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        _buildInputBox(_newRateController, errorText: _errors['newRate']),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NEW TERM (YRS)', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        _buildInputBox(_newTermController, errorText: _errors['newTerm']),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WHOLESALE RATE WHEN LOCKED (%)', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        _buildInputBox(_wsFixedController, errorText: _errors['wsFixed']),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CURRENT WHOLESALE RATE (%)', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        _buildInputBox(_wsCurrentController, errorText: _errors['wsCurrent']),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CASHBACK INCENTIVE (NZD)', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        _buildInputBox(_cashbackController, errorText: _errors['cashback']),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LEGAL / ADMIN COSTS (NZD)', style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                        const SizedBox(height: 6),
                        _buildInputBox(_legalController, errorText: _errors['legal']),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC0392B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text(
                  'Calculate Refinance Analysis',
                  style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Results Card
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
                      'Inputs have changed. Tap Calculate Refinance Analysis to refresh results.',
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
                  'Refinance Analysis',
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
                      colors: [Color(0xFF0A0F0D), Color(0xFF0F5D4A)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REFINANCE SUMMARY',
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
                          _buildResultBox('Estimated Break Fee', CurrencyFormatter.compact(breakFee, symbol: 'NZ\$'), 'Wholesale diff formula', const Color(0xFFF5D060)),
                          _buildResultBox('Net Cost to Refinance', CurrencyFormatter.compact(netCost, symbol: 'NZ\$'), 'Fees - Cashback', Colors.white),
                          _buildResultBox('Old Monthly Payment', CurrencyFormatter.compact(oldPmt, symbol: 'NZ\$'), 'Current mortgage', Colors.white),
                          _buildResultBox('New Monthly Payment', CurrencyFormatter.compact(newPmt, symbol: 'NZ\$'), 'After refinance', const Color(0xFF6EE7B7)),
                          _buildResultBox('Monthly Saving', CurrencyFormatter.compact(max(0, monthlySaving), symbol: 'NZ\$'), 'Per month cash gain', const Color(0xFF6EE7B7)),
                          _buildResultBox('Total Interest Saved', CurrencyFormatter.compact(max(0, totalIntSaved), symbol: 'NZ\$'), 'Over loan life', const Color(0xFF6EE7B7)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Break-even timeline
                      Text(
                        'BREAK-EVEN POINT',
                        style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w800, color: Colors.white60),
                      ),
                      const SizedBox(height: 8),
                      _buildBreakEvenTimeline(breakEvenMonths),
                      const SizedBox(height: 20),

                      // Horizontal Timeline bars
                      Text(
                        'REFINANCING SAVINGS TIMELINE',
                        style: AppTextStyles.dmSans(size: 8, weight: FontWeight.w800, color: Colors.white60),
                      ),
                      const SizedBox(height: 10),
                      _buildTimelineBar('Break Fee', breakFee, const Color(0xFFFCA5A5)),
                      _buildTimelineBar('Legal Costs', legal, const Color(0xFFFCD34D)),
                      _buildTimelineBar('Lender Cashback', cashback, const Color(0xFF6EE7B7)),
                      _buildTimelineBar('Monthly Saving', monthlySaving, const Color(0xFF67E8F9)),
                      _buildTimelineBar('Annual Saving', monthlySaving * 12, const Color(0xFF6EE7B7)),
                      _buildTimelineBar('Net Lifetime Savings', max(0, totalIntSaved), const Color(0xFF86EFAC)),
                      const SizedBox(height: 18),

                      ElevatedButton.icon(
                        onPressed: () => _saveCalculation(
                          breakFee,
                          netCost,
                          oldPmt,
                          newPmt,
                          monthlySaving,
                          totalIntSaved,
                          breakEvenMonths,
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
                          'Save Refinance Analysis',
                          style: AppTextStyles.playfair(size: 13, weight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],

        // Bank Rates Comparison
        Text(
          'NZ Bank Rates (Current)',
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
              Text(
                '🏦 Current 1-Year Fixed Rates',
                style: AppTextStyles.playfair(
                  size: 13,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 10),
              _buildBankRow('🥝 Kiwibank', '6.55%', 'NZ-owned · cashback available', true),
              _buildBankRow('🏦 ANZ', '6.59%', 'Simplicity PLUS · flexi account option', false),
              _buildBankRow('🏦 ASB', '6.59%', 'FastTrack offset facility', false),
              _buildBankRow('🏦 BNZ', '6.59%', 'TotalMoney offset option', false),
              _buildBankRow('🏦 Westpac', '6.65%', 'Choices offset facility', false),
              _buildBankRow('🏦 SBS Bank', '6.79%', 'Mutual banking option', false),
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

  Widget _buildBreakEvenTimeline(double breakEvenMonths) {
    final double progress = breakEvenMonths == double.infinity ? 1.0 : min(breakEvenMonths / 60.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Container(
            height: 14,
            color: Colors.white.withValues(alpha: 0.08),
            child: Stack(
              children: [
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF6EE7B7), Color(0xFFF5D060)]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          breakEvenMonths == double.infinity || breakEvenMonths <= 0
              ? 'Never break even — refinancing not recommended'
              : 'Break-even: ${breakEvenMonths.round()} months (${(breakEvenMonths / 12).toStringAsFixed(1)} years)',
          style: AppTextStyles.dmSans(
              size: 11, weight: FontWeight.w800, color: const Color(0xFFF5D060)),
        ),
      ],
    );
  }

  Widget _buildTimelineBar(String label, double val, Color color) {
    const double maxVal = 5000.0; // scale factor
    final double pct = min(val / maxVal, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 8,
                color: Colors.white.withValues(alpha: 0.08),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: pct,
                  child: Container(color: color),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppTextStyles.dmSans(size: 9, color: Colors.white70),
            ),
          ),
          Text(
            CurrencyFormatter.compact(val, symbol: 'NZ\$'),
            style: AppTextStyles.dmSans(size: 10, weight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBankRow(String name, String rate, String note, bool highlight) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.getBorderColor(context))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: theme.getTextColor(context)),
              ),
              const SizedBox(height: 2),
              Text(
                note,
                style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rate,
                style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.primaryColor),
              ),
              if (highlight)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    'Best Rate',
                    style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.bold, color: const Color(0xFF065F46)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
