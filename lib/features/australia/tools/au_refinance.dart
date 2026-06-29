// lib/features/australia/tools/au_refinance.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class AURefinance extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const AURefinance({super.key, this.theme = CountryThemes.australia});

  @override
  ConsumerState<AURefinance> createState() => _AURefinanceState();
}

class _AURefinanceState extends ConsumerState<AURefinance> {
  double _balance = 520000;
  double _curRate = 6.54;
  int _remYears = 22;
  String _repayType = 'pi';

  double _newRate = 5.79;
  int _newTerm = 25;
  String _lenderName = 'Commonwealth Bank (CBA)';

  double _dischargeFee = 350;
  double _appFee = 300;
  double _valFee = 300;
  double _breakCost = 0;
  double _legalFee = 800;

  bool _showResults = false;

  void _reset() {
    setState(() {
      _balance = 520000;
      _curRate = 6.54;
      _remYears = 22;
      _repayType = 'pi';
      _newRate = 5.79;
      _newTerm = 25;
      _lenderName = 'Commonwealth Bank (CBA)';
      _dischargeFee = 350;
      _appFee = 300;
      _valFee = 300;
      _breakCost = 0;
      _legalFee = 800;
      _showResults = false;
    });
  }

  double _monthlyPmt(double p, double ratePercent, int years) {
    final r = ratePercent / 100 / 12;
    final n = years * 12;
    if (r == 0) return p / n;
    return p * r * pow(1 + r, n) / (pow(1 + r, n) - 1);
  }

  double _totalInterest(double p, double ratePercent, int years) {
    final pmt = _monthlyPmt(p, ratePercent, years);
    return pmt * years * 12 - p;
  }

  void _saveCalculation() async {
    final totalCosts =
        _dischargeFee + _appFee + _valFee + _breakCost + _legalFee;
    final oldPmt = _monthlyPmt(_balance, _curRate, _remYears);
    final newPmt = _monthlyPmt(_balance, _newRate, _newTerm);
    final monthlySaving = oldPmt - newPmt;
    final oldTotalInterest = _totalInterest(_balance, _curRate, _remYears);
    final newTotalInterest = _totalInterest(_balance, _newRate, _newTerm);
    final lifetimeSaving = oldTotalInterest - newTotalInterest - totalCosts;

    final labelCtrl = TextEditingController(text: 'Refinance Scenario');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/au_refinance'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Refinance Scenario',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Saving: \$${CurrencyFormatter.compact(lifetimeSaving, symbol: 'AU\$')} lifetime savings',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. CBA to Athena)',
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
              backgroundColor: widget.theme.primaryColor,
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
          : 'Refinance Plan';
      final calc = SavedCalc.create(
        country: 'Australia',
        calcType: 'Refinance Tool',
        inputs: {
          'balance': _balance,
          'curRate': _curRate,
          'remYears': _remYears.toDouble(),
          'newRate': _newRate,
          'newTerm': _newTerm.toDouble(),
        },
        results: {
          'lifetimeSaving': lifetimeSaving,
          'monthlySaving': monthlySaving,
          'totalCosts': totalCosts,
          'breakevenMonths': monthlySaving > 0
              ? (totalCosts / monthlySaving).ceilToDouble()
              : 999.0,
        },
        label: label,
        currencyCode: 'AUD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Calculation saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: widget.theme.primaryColor,
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

    // Calculations
    final totalCosts =
        _dischargeFee + _appFee + _valFee + _breakCost + _legalFee;
    final oldPmt = _monthlyPmt(_balance, _curRate, _remYears);
    final newPmt = _monthlyPmt(_balance, _newRate, _newTerm);
    final monthlySaving = oldPmt - newPmt;
    final annualSaving = monthlySaving * 12;

    final oldTotalInterest = _totalInterest(_balance, _curRate, _remYears);
    final newTotalInterest = _totalInterest(_balance, _newRate, _newTerm);
    final lifetimeSaving = oldTotalInterest - newTotalInterest - totalCosts;

    final breakevenMonths =
        monthlySaving > 0 ? (totalCosts / monthlySaving).ceil() : 999;

    // Chart coordinates building
    final maxYears = max(_remYears, _newTerm);
    final steps = min(maxYears, 30);
    final List<double> oldInterestCurve = [];
    final List<double> newInterestCurve = [];

    double oldInterestAcc = 0;
    double newInterestAcc = totalCosts;
    double oldBal = _balance;
    double newBal = _balance;

    oldInterestCurve.add(0);
    newInterestCurve.add(totalCosts);

    for (int y = 1; y <= steps; y++) {
      for (int m = 0; m < 12; m++) {
        final oInt = oldBal * (_curRate / 100 / 12);
        oldInterestAcc += oInt;
        oldBal = max(0.0, oldBal - (oldPmt - oInt));

        final nInt = newBal * (_newRate / 100 / 12);
        newInterestAcc += nInt;
        newBal = max(0.0, newBal - (newPmt - nInt));
      }
      oldInterestCurve.add(oldInterestAcc);
      newInterestCurve.add(newInterestAcc);
    }

    final ratio = oldPmt > 0 ? (newPmt / oldPmt) : 0.0;
    final barRatioVal = ratio.clamp(0.1, 1.0);

    // Verdict card setup
    String verdictTitle;
    String verdictSub;
    Color verdictBg;
    Color verdictBorder;
    String verdictEmoji;

    if (lifetimeSaving > 0 && breakevenMonths < 36) {
      verdictEmoji = '✅';
      verdictTitle = 'Strong Refinance Case';
      verdictSub =
          'You break even in $breakevenMonths months and save ${CurrencyFormatter.format(lifetimeSaving, currencyCode: 'AUD')} over the loan life. Refinancing is highly recommended.';
      verdictBg = isDark
          ? const Color(0xFF064E3B).withValues(alpha: 0.3)
          : const Color(0xFFECFDF5);
      verdictBorder =
          isDark ? const Color(0xFF34D399) : const Color(0xFF6EE7B7);
    } else if (lifetimeSaving > 0 && breakevenMonths < 72) {
      verdictEmoji = '⚠️';
      verdictTitle = 'Worth Considering';
      verdictSub =
          'Breakeven is $breakevenMonths months. If you plan to stay in the property beyond that, refinancing adds value.';
      verdictBg = isDark
          ? const Color(0xFF7C2D12).withValues(alpha: 0.3)
          : const Color(0xFFFFF7ED);
      verdictBorder =
          isDark ? const Color(0xFFF59E0B) : const Color(0xFFFCA5A5);
    } else {
      verdictEmoji = '❌';
      verdictTitle = 'May Not Be Worth It';
      verdictSub =
          'Costs may outweigh benefits in your timeframe. Consider a lower-cost refinance option or negotiating with your current lender.';
      verdictBg = isDark
          ? const Color(0xFF7F1D1D).withValues(alpha: 0.3)
          : const Color(0xFFFEF2F2);
      verdictBorder =
          isDark ? const Color(0xFFF87171) : const Color(0xFFFCA5A5);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current Loan Details Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? theme.getCardColor(context) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color:
                    isDark ? theme.getBorderColor(context) : theme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Current Loan Details',
                      style: AppTextStyles.dmSans(
                          size: 11,
                          color: isDark
                              ? const Color(0xFFFFD700)
                              : theme.primaryColor,
                          weight: FontWeight.w700,
                          letterSpacing: 0.5)),
                  GestureDetector(
                    onTap: _reset,
                    child: Text('Reset ↺',
                        style: AppTextStyles.dmSans(
                            size: 11,
                            color: isDark
                                ? const Color(0xFFFFD700)
                                : theme.primaryColor,
                            weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInputBox('Remaining Balance', 'AUD \$', _balance,
                  onChanged: (v) => setState(() => _balance = v)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _buildInputBox('Current Rate', '%', _curRate,
                          isPercent: true,
                          onChanged: (v) => setState(() => _curRate = v))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _buildInputBox(
                          'Years Remaining', 'yr', _remYears.toDouble(),
                          isInteger: true,
                          onChanged: (v) =>
                              setState(() => _remYears = v.toInt()))),
                ],
              ),
              const SizedBox(height: 10),
              Text('REPAYMENT TYPE',
                  style: AppTextStyles.dmSans(
                      size: 9,
                      color: theme.getMutedColor(context),
                      weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFFFF8F0),
                  border: Border.all(
                      color: isDark
                          ? theme.getBorderColor(context)
                          : theme.borderColor),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _repayType,
                    dropdownColor: theme.getCardColor(context),
                    isExpanded: true,
                    style: AppTextStyles.dmSans(
                        size: 14,
                        color: theme.getTextColor(context),
                        weight: FontWeight.w800),
                    items: [
                      DropdownMenuItem(
                          value: 'pi',
                          child: Text('Principal & Interest (P&I)',
                              style: AppTextStyles.dmSans(
                                  color: theme.getTextColor(context)))),
                      DropdownMenuItem(
                          value: 'io',
                          child: Text('Interest Only (IO)',
                              style: AppTextStyles.dmSans(
                                  color: theme.getTextColor(context)))),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _repayType = v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // New Loan Details Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? theme.getCardColor(context) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color:
                    isDark ? theme.getBorderColor(context) : theme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Proposed Refinance',
                  style: AppTextStyles.dmSans(
                      size: 11,
                      color:
                          isDark ? const Color(0xFFFFD700) : theme.primaryColor,
                      weight: FontWeight.w700,
                      letterSpacing: 0.5)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _buildInputBox('New Rate', '%', _newRate,
                          isPercent: true,
                          onChanged: (v) => setState(() => _newRate = v))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _buildInputBox(
                          'New Loan Term', 'yr', _newTerm.toDouble(),
                          isInteger: true,
                          onChanged: (v) =>
                              setState(() => _newTerm = v.toInt()))),
                ],
              ),
              const SizedBox(height: 10),
              Text('LENDER / PRODUCT',
                  style: AppTextStyles.dmSans(
                      size: 9,
                      color: theme.getMutedColor(context),
                      weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFFFF8F0),
                  border: Border.all(
                      color: isDark
                          ? theme.getBorderColor(context)
                          : theme.borderColor),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _lenderName,
                    dropdownColor: theme.getCardColor(context),
                    isExpanded: true,
                    style: AppTextStyles.dmSans(
                        size: 14,
                        color: theme.getTextColor(context),
                        weight: FontWeight.w800),
                    items: [
                      DropdownMenuItem(
                          value: 'Commonwealth Bank (CBA)',
                          child: Text('Commonwealth Bank (CBA)',
                              style: AppTextStyles.dmSans(
                                  color: theme.getTextColor(context)))),
                      DropdownMenuItem(
                          value: 'Westpac',
                          child: Text('Westpac',
                              style: AppTextStyles.dmSans(
                                  color: theme.getTextColor(context)))),
                      DropdownMenuItem(
                          value: 'ANZ',
                          child: Text('ANZ',
                              style: AppTextStyles.dmSans(
                                  color: theme.getTextColor(context)))),
                      DropdownMenuItem(
                          value: 'NAB',
                          child: Text('NAB',
                              style: AppTextStyles.dmSans(
                                  color: theme.getTextColor(context)))),
                      DropdownMenuItem(
                          value: 'Macquarie Bank',
                          child: Text('Macquarie Bank',
                              style: AppTextStyles.dmSans(
                                  color: theme.getTextColor(context)))),
                      DropdownMenuItem(
                          value: 'ING Direct',
                          child: Text('ING Direct',
                              style: AppTextStyles.dmSans(
                                  color: theme.getTextColor(context)))),
                      DropdownMenuItem(
                          value: 'Athena Home Loans',
                          child: Text('Athena Home Loans',
                              style: AppTextStyles.dmSans(
                                  color: theme.getTextColor(context)))),
                      DropdownMenuItem(
                          value: 'Other Lender',
                          child: Text('Other Lender',
                              style: AppTextStyles.dmSans(
                                  color: theme.getTextColor(context)))),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _lenderName = v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Refinancing Costs Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? theme.getCardColor(context) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color:
                    isDark ? theme.getBorderColor(context) : theme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Refinancing Costs (AUS)',
                  style: AppTextStyles.dmSans(
                      size: 11,
                      color:
                          isDark ? const Color(0xFFFFD700) : theme.primaryColor,
                      weight: FontWeight.w700,
                      letterSpacing: 0.5)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _buildInputBox(
                          'Discharge Fee', 'AUD \$', _dischargeFee,
                          onChanged: (v) => setState(() => _dischargeFee = v))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _buildInputBox(
                          'Application Fee', 'AUD \$', _appFee,
                          onChanged: (v) => setState(() => _appFee = v))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _buildInputBox('Valuation Fee', 'AUD \$', _valFee,
                          onChanged: (v) => setState(() => _valFee = v))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _buildInputBox(
                          'Break Cost (Fixed)', 'AUD \$', _breakCost,
                          onChanged: (v) => setState(() => _breakCost = v))),
                ],
              ),
              const SizedBox(height: 10),
              _buildInputBox('Legal / Settlement Fee', 'AUD \$', _legalFee,
                  onChanged: (v) => setState(() => _legalFee = v)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _showResults = true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text('🔄 Calculate Refinance Savings',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        color: Colors.white,
                        weight: FontWeight.w800)),
              ),
            ],
          ),
        ),

        // Results Section
        if (_showResults) ...[
          const SizedBox(height: 20),

          // Result Hero Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Refinance Analysis',
                  style: AppTextStyles.playfair(
                      size: 15, color: theme.getTextColor(context))),
              GestureDetector(
                onTap: _saveCalculation,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? theme.getCardColor(context) : Colors.white,
                    border: Border.all(
                        color: isDark
                            ? theme.getBorderColor(context)
                            : theme.borderColor),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('💾 Save',
                      style: AppTextStyles.dmSans(
                          size: 11,
                          color: isDark
                              ? const Color(0xFFFFD700)
                              : theme.primaryColor,
                          weight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A0A00), Color(0xFF7C2D12)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Lifetime Savings',
                    style: AppTextStyles.dmSans(
                        size: 10,
                        color: Colors.white60,
                        weight: FontWeight.w700,
                        letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text(
                    CurrencyFormatter.format(lifetimeSaving,
                        currencyCode: 'AUD'),
                    style: AppTextStyles.playfair(
                        size: 36,
                        color: const Color(0xFFFFD700),
                        weight: FontWeight.w800)),
                Text(
                    'by switching lenders today (interest saved less upfront costs)',
                    style:
                        AppTextStyles.dmSans(size: 11, color: Colors.white70)),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _buildHeroBox(
                        'Monthly Saving',
                        (monthlySaving >= 0 ? '+' : '') +
                            CurrencyFormatter.format(monthlySaving,
                                currencyCode: 'AUD'),
                        color: const Color(0xFFBBF7D0)),
                    _buildHeroBox(
                        'Annual Saving',
                        (annualSaving >= 0 ? '+' : '') +
                            CurrencyFormatter.format(annualSaving,
                                currencyCode: 'AUD'),
                        color: const Color(0xFFBBF7D0)),
                    _buildHeroBox('Old Repayment',
                        '${CurrencyFormatter.format(oldPmt, currencyCode: 'AUD')}/mo',
                        color: const Color(0xFFFCA5A5)),
                    _buildHeroBox('New Repayment',
                        '${CurrencyFormatter.format(newPmt, currencyCode: 'AUD')}/mo',
                        color: const Color(0xFFFFD700)),
                  ],
                ),
              ],
            ),
          ),

          // Monthly Comparison Bars Card
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? theme.getCardColor(context) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: isDark
                      ? theme.getBorderColor(context)
                      : theme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📊 Monthly Repayment Comparison',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        weight: FontWeight.w800,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 16),
                _buildBarRow('Current', oldPmt, 1.0, const Color(0xFFEF4444)),
                const SizedBox(height: 10),
                _buildBarRow(
                    'New', newPmt, barRatioVal, const Color(0xFF16A34A)),
                const SizedBox(height: 12),
                Divider(color: isDark ? Colors.white24 : null),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        'Rate difference: ${(_newRate - _curRate).abs().toStringAsFixed(2)}%',
                        style: AppTextStyles.dmSans(
                            size: 10,
                            color: theme.getMutedColor(context),
                            weight: FontWeight.bold)),
                    Text(
                        monthlySaving >= 0
                            ? '${((1 - ratio) * 100).toStringAsFixed(1)}% less/month'
                            : 'Higher repayment',
                        style: AppTextStyles.dmSans(
                            size: 10,
                            color: const Color(0xFF16A34A),
                            weight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),

          // Breakeven Timeline Card
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? theme.getCardColor(context) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: isDark
                      ? theme.getBorderColor(context)
                      : theme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('⏱ Breakeven Timeline',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        weight: FontWeight.w800,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 16),
                // Breakeven bar line
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxMo = min(120, max(60, breakevenMonths * 2));
                    final pct = (breakevenMonths / maxMo).clamp(0.0, 1.0);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : const Color(0xFFFFF0E4),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: pct,
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    const Color(0xFF7C2D12),
                                    isDark
                                        ? const Color(0xFF60A5FA)
                                        : const Color(0xFF002868)
                                  ]),
                                  borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(3)),
                                ),
                              ),
                            ),
                            Positioned(
                              left: pct * (constraints.maxWidth - 16),
                              top: -5,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C2D12),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: isDark
                                          ? theme.getCardColor(context)
                                          : Colors.white,
                                      width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Month 0',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: isDark
                                        ? const Color(0xFFFFD700)
                                        : const Color(0xFF92400E))),
                            Text('$maxMo mo',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: isDark
                                        ? const Color(0xFFFFD700)
                                        : const Color(0xFF92400E))),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _buildTimelineBox(
                            'Total Costs',
                            CurrencyFormatter.format(totalCosts,
                                currencyCode: 'AUD'))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _buildTimelineBox(
                            'Breakeven',
                            breakevenMonths > 120
                                ? 'N/A'
                                : '$breakevenMonths mo')),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _buildTimelineBox(
                            'Net Benefit',
                            CurrencyFormatter.format(lifetimeSaving,
                                currencyCode: 'AUD'),
                            valColor: const Color(0xFF16A34A))),
                  ],
                ),
              ],
            ),
          ),

          // Cumulative Interest Savings Chart
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? theme.getCardColor(context) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: isDark
                      ? theme.getBorderColor(context)
                      : theme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📈 Cumulative Interest Savings',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        weight: FontWeight.w800,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildLegendItem(const Color(0xFFEF4444), 'Current Loan'),
                    const SizedBox(width: 14),
                    _buildLegendItem(
                        isDark
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF002868),
                        'After Refinance'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 140,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: RefinanceChartPainter(
                      oldCurve: oldInterestCurve,
                      newCurve: newInterestCurve,
                      steps: steps,
                      isDark: isDark,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Refinancing costs breakdown
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF002868),
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Refinancing Costs Breakdown',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 12),
                _buildCostRowWhite(
                    'Discharge Fee',
                    CurrencyFormatter.format(_dischargeFee,
                        currencyCode: 'AUD')),
                _buildCostRowWhite('Application Fee',
                    CurrencyFormatter.format(_appFee, currencyCode: 'AUD')),
                _buildCostRowWhite('Valuation Fee',
                    CurrencyFormatter.format(_valFee, currencyCode: 'AUD')),
                _buildCostRowWhite('Legal / Settlement Fee',
                    CurrencyFormatter.format(_legalFee, currencyCode: 'AUD')),
                _buildCostRowWhite('Break Cost',
                    CurrencyFormatter.format(_breakCost, currencyCode: 'AUD')),
                const Divider(color: Colors.white24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Upfront Cost',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD700))),
                    Text(
                        CurrencyFormatter.format(totalCosts,
                            currencyCode: 'AUD'),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD700))),
                  ],
                ),
              ],
            ),
          ),

          // Verdict Card
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: verdictBg,
              border: Border.all(color: verdictBorder),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(verdictEmoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(verdictTitle,
                          style: AppTextStyles.playfair(
                              size: 14,
                              weight: FontWeight.w800,
                              color: theme.getTextColor(context))),
                      const SizedBox(height: 4),
                      Text(verdictSub,
                          style: AppTextStyles.dmSans(
                              size: 11,
                              color: theme.getTextColor(context),
                              height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInputBox(String label, String prefix, double value,
      {bool isPercent = false,
      bool isInteger = false,
      required ValueChanged<double> onChanged}) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: AppTextStyles.dmSans(
                size: 9,
                color: theme.getMutedColor(context),
                weight: FontWeight.w800)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFFFF8F0),
            border: Border.all(
                color:
                    isDark ? theme.getBorderColor(context) : theme.borderColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              if (!isPercent)
                Text('$prefix ',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        color: theme.getMutedColor(context),
                        weight: FontWeight.bold)),
              Expanded(
                child: TextFormField(
                  key: ValueKey(value),
                  initialValue:
                      isInteger ? value.toInt().toString() : value.toString(),
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.dmSans(
                      size: 14,
                      color: theme.getTextColor(context),
                      weight: FontWeight.bold),
                  decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero),
                  onChanged: (v) {
                    final d = double.tryParse(v) ?? 0.0;
                    onChanged(d);
                  },
                ),
              ),
              if (isPercent)
                Text('%',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        color: theme.getMutedColor(context),
                        weight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBox(String label, String val, {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 9, color: Colors.white54)),
          const SizedBox(height: 2),
          Text(val,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildBarRow(String label, double pmt, double barPct, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        SizedBox(
            width: 50,
            child: Text(label,
                style: AppTextStyles.dmSans(
                    size: 10,
                    color: widget.theme.getTextColor(context),
                    weight: FontWeight.bold))),
        Expanded(
          child: Container(
            height: 28,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: barPct,
              child: Container(
                padding: const EdgeInsets.only(left: 8),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(8)),
                child: Text(
                    '${CurrencyFormatter.format(pmt, currencyCode: 'AUD')}/mo',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineBox(String label, String value, {Color? valColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  color: isDark
                      ? const Color(0xFFFFD700)
                      : const Color(0xFF92400E))),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: valColor ?? (isDark ? Colors.white : Colors.black),
                  fontFamily: 'Georgia')),
        ],
      ),
    );
  }

  Widget _buildCostRowWhite(String name, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name,
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color col, String text) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(text,
            style: TextStyle(
                fontSize: 10, color: widget.theme.getTextColor(context))),
      ],
    );
  }
}

class RefinanceChartPainter extends CustomPainter {
  final List<double> oldCurve;
  final List<double> newCurve;
  final int steps;
  final bool isDark;

  RefinanceChartPainter(
      {required this.oldCurve,
      required this.newCurve,
      required this.steps,
      this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (oldCurve.isEmpty || newCurve.isEmpty) return;

    final maxVal = max(
      oldCurve.reduce(max),
      newCurve.reduce(max),
    );
    if (maxVal == 0) return;

    final paintOld = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final paintNew = Paint()
      ..color = isDark ? const Color(0xFF60A5FA) : const Color(0xFF002868)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final pathOld = Path();
    final pathNew = Path();

    final dx = size.width / steps;

    for (int i = 0; i <= steps; i++) {
      final x = i * dx;
      final yOld = size.height - (oldCurve[i] / maxVal * size.height);
      final yNew = size.height - (newCurve[i] / maxVal * size.height);

      if (i == 0) {
        pathOld.moveTo(x, yOld);
        pathNew.moveTo(x, yNew);
      } else {
        pathOld.lineTo(x, yOld);
        pathNew.lineTo(x, yNew);
      }
    }

    canvas.drawPath(pathOld, paintOld);
    canvas.drawPath(pathNew, paintNew);
  }

  @override
  bool shouldRepaint(covariant RefinanceChartPainter oldDelegate) => true;
}
