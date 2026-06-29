// lib/features/australia/tools/au_amortization.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class AUAmortization extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const AUAmortization({super.key, this.theme = CountryThemes.australia});

  @override
  ConsumerState<AUAmortization> createState() => _AUAmortizationState();
}

class _AUAmortizationState extends ConsumerState<AUAmortization> {
  double _loanAmt = 600000;
  double _rate = 6.09;
  int _termYears = 30;
  String _frequency = 'fortnightly'; // 'weekly', 'fortnightly', 'monthly'

  bool _showResults = false;
  bool _showAllRows = false;

  void _reset() {
    setState(() {
      _loanAmt = 600000;
      _rate = 6.09;
      _termYears = 30;
      _frequency = 'fortnightly';
      _showResults = false;
    });
  }

  void _saveCalculation() async {
    final periodsPerYear = _frequency == 'weekly'
        ? 52
        : _frequency == 'fortnightly'
            ? 26
            : 12;
    final periodRate = (_rate / 100) / periodsPerYear;
    final totalPeriods = _termYears * periodsPerYear;
    final payment =
        _loanAmt * periodRate / (1 - pow(1 + periodRate, -totalPeriods));
    final totalInterest = payment * totalPeriods - _loanAmt;

    final labelCtrl = TextEditingController(text: 'My Amortization Plan');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/au_amortization'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Amortization Schedule',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Saving: \$${CurrencyFormatter.compact(_loanAmt, symbol: 'AU\$')} loan @ $_rate% ($_frequency)',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Dream House Amort)',
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
              backgroundColor: const Color(0xFF002868),
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
          : 'Amortization Plan';
      final calc = SavedCalc.create(
        country: 'Australia',
        calcType: 'Amortization Schedule',
        inputs: {
          'loanAmt': _loanAmt,
          'rate': _rate,
          'termYears': _termYears.toDouble(),
          'frequency': _frequency == 'weekly'
              ? 0.0
              : _frequency == 'fortnightly'
                  ? 1.0
                  : 2.0,
        },
        results: {
          'payment': payment,
          'totalInterest': totalInterest,
          'totalRepayable': _loanAmt + totalInterest,
        },
        label: label,
        currencyCode: 'AUD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Schedule saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF002868),
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
    final periodsPerYear = _frequency == 'weekly'
        ? 52
        : _frequency == 'fortnightly'
            ? 26
            : 12;
    final periodRate = (_rate / 100) / periodsPerYear;
    final totalPeriods = _termYears * periodsPerYear;
    final payment =
        _loanAmt * periodRate / (1 - pow(1 + periodRate, -totalPeriods));

    double balance = _loanAmt;
    double totalInterest = 0;
    final List<_YearData> yearlyData = [];

    double yearlyPrincipal = 0;
    double yearlyInterest = 0;
    bool half50Found = false;
    int half50Year = 0;

    for (int p = 1; p <= totalPeriods; p++) {
      final intCharge = balance * periodRate;
      final princ = payment - intCharge;
      balance = max(0.0, balance - princ);
      totalInterest += intCharge;
      yearlyPrincipal += princ;
      yearlyInterest += intCharge;

      if (balance / _loanAmt <= 0.5 && !half50Found) {
        half50Found = true;
        half50Year = (p / periodsPerYear).ceil();
      }

      if (p % periodsPerYear == 0 || p == totalPeriods) {
        yearlyData.add(_YearData(
          year: (p / periodsPerYear).ceil(),
          payment: yearlyPrincipal + yearlyInterest,
          principal: yearlyPrincipal,
          interest: yearlyInterest,
          balance: balance,
        ));
        yearlyPrincipal = 0;
        yearlyInterest = 0;
      }
    }

    final totalRepayable = payment * totalPeriods;
    final freqLabel = _frequency == 'weekly'
        ? 'per week'
        : _frequency == 'fortnightly'
            ? 'per fortnight'
            : 'per month';

    final displayedRows =
        _showAllRows ? yearlyData : yearlyData.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? theme.getCardColor(context) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color:
                    isDark ? theme.getBorderColor(context) : theme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
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
                  Text('Loan Details',
                      style: AppTextStyles.dmSans(
                          size: 11,
                          color: theme.primaryColor,
                          weight: FontWeight.w700,
                          letterSpacing: 0.5)),
                  GestureDetector(
                    onTap: _reset,
                    child: Text('Reset ↺',
                        style: AppTextStyles.dmSans(
                            size: 11,
                            color: theme.primaryColor,
                            weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildSliderInputRow(
                label: 'Loan Amount',
                value: _loanAmt,
                min: 50000,
                max: 2000000,
                prefix: 'AUD \$',
                onChanged: (val) => setState(() => _loanAmt = val),
              ),
              const SizedBox(height: 12),

              _buildSliderInputRow(
                label: 'Interest Rate (% p.a.)',
                value: _rate,
                min: 1,
                max: 15,
                prefix: '% ',
                step: 0.01,
                onChanged: (val) => setState(() => _rate = val),
              ),
              const SizedBox(height: 12),

              // Term Select
              Text('LOAN TERM',
                  style: AppTextStyles.dmSans(
                      size: 9,
                      color: theme.mutedColor,
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
                  child: DropdownButton<int>(
                    value: _termYears,
                    dropdownColor: theme.getCardColor(context),
                    isExpanded: true,
                    style: AppTextStyles.dmSans(
                        size: 14,
                        color: theme.getTextColor(context),
                        weight: FontWeight.w800),
                    items: [
                      DropdownMenuItem(
                          value: 30,
                          child: Text('30 years',
                              style: AppTextStyles.dmSans(
                                  color: theme.getTextColor(context)))),
                      DropdownMenuItem(
                          value: 25,
                          child: Text('25 years',
                              style: AppTextStyles.dmSans(
                                  color: theme.getTextColor(context)))),
                      DropdownMenuItem(
                          value: 20,
                          child: Text('20 years',
                              style: AppTextStyles.dmSans(
                                  color: theme.getTextColor(context)))),
                      DropdownMenuItem(
                          value: 15,
                          child: Text('15 years',
                              style: AppTextStyles.dmSans(
                                  color: theme.getTextColor(context)))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _termYears = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Frequency tabs
              Text('REPAYMENT FREQUENCY',
                  style: AppTextStyles.dmSans(
                      size: 9,
                      color: theme.mutedColor,
                      weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                      child: _buildFreqTab('Weekly', _frequency == 'weekly',
                          () => setState(() => _frequency = 'weekly'))),
                  const SizedBox(width: 6),
                  Expanded(
                      child: _buildFreqTab(
                          'Fortnightly',
                          _frequency == 'fortnightly',
                          () => setState(() => _frequency = 'fortnightly'))),
                  const SizedBox(width: 6),
                  Expanded(
                      child: _buildFreqTab('Monthly', _frequency == 'monthly',
                          () => setState(() => _frequency = 'monthly'))),
                ],
              ),
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
                child: Text('📅 Generate Schedule',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        color: Colors.white,
                        weight: FontWeight.w800,
                        letterSpacing: 0.3)),
              ),
            ],
          ),
        ),

        // Results Section
        if (_showResults) ...[
          const SizedBox(height: 20),
          Text('Loan Summary',
              style: AppTextStyles.playfair(size: 15, color: theme.textColor)),
          const SizedBox(height: 10),

          // Summary Grid cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              _buildSummaryCard('Repayment',
                  CurrencyFormatter.format(payment, currencyCode: 'AUD'),
                  sub: freqLabel, colorClass: 'red'),
              _buildSummaryCard('Total Interest',
                  CurrencyFormatter.format(totalInterest, currencyCode: 'AUD'),
                  sub: 'over loan term', colorClass: 'blue'),
              _buildSummaryCard('Total Repayable',
                  CurrencyFormatter.format(totalRepayable, currencyCode: 'AUD'),
                  sub: 'principal + interest', colorClass: 'teal'),
              _buildSummaryCard('Interest : Principal',
                  '${(totalInterest / totalRepayable * 100).round()}%',
                  sub: 'interest share', colorClass: 'gold'),
            ],
          ),

          // Chart Card
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
                Text('Principal vs Interest Over Time',
                    style: AppTextStyles.dmSans(
                        size: 12,
                        weight: FontWeight.w700,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _AmortChartPainter(
                        yearlyData: yearlyData,
                        maxVal: _loanAmt + totalInterest,
                        isDark: isDark),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildDotIndicator(
                        'Principal Paid',
                        isDark
                            ? const Color(0xFFFCA5A5)
                            : const Color(0xFF7C2D12)),
                    const SizedBox(width: 14),
                    _buildDotIndicator(
                        'Interest Paid',
                        isDark
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF002868)),
                    const SizedBox(width: 14),
                    _buildDotIndicator(
                        'Balance',
                        isDark
                            ? const Color(0xFFFCA5A5).withValues(alpha: 0.3)
                            : const Color(0x3B7C2D12)),
                  ],
                ),
              ],
            ),
          ),

          // Key Milestones
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
                Text('Key Milestones',
                    style: AppTextStyles.dmSans(
                        size: 12,
                        weight: FontWeight.w700,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 8),
                _buildMilestoneRow('🏁', '50% Balance Cleared',
                    'When you owe half of original loan', 'Yr $half50Year'),
                _buildMilestoneRow('🎉', 'Loan Free',
                    'Final $_frequency payment', 'Yr $_termYears'),
                _buildMilestoneRow(
                    '💸',
                    'Total Interest Cost',
                    '${(totalInterest / _loanAmt * 100).round()}% of original loan',
                    CurrencyFormatter.format(totalInterest,
                        currencyCode: 'AUD')),
                _buildMilestoneRow(
                    '📆',
                    '${_frequency[0].toUpperCase()}${_frequency.substring(1)} Payment',
                    'Fixed for loan term',
                    CurrencyFormatter.format(payment, currencyCode: 'AUD')),
              ],
            ),
          ),

          // Year-by-Year Schedule Table
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Year-by-Year Schedule',
                  style: AppTextStyles.playfair(
                      size: 15, color: theme.getTextColor(context))),
              GestureDetector(
                onTap: () => setState(() => _showAllRows = !_showAllRows),
                child: Text(_showAllRows ? 'Collapse ‹' : 'Show All ›',
                    style: AppTextStyles.dmSans(
                        size: 11,
                        color: isDark
                            ? const Color(0xFFFFD700)
                            : theme.primaryColor,
                        weight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? theme.getCardColor(context) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: isDark
                      ? theme.getBorderColor(context)
                      : theme.borderColor),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 18,
                headingRowHeight: 32,
                dataRowMinHeight: 32,
                dataRowMaxHeight: 32,
                columns: [
                  DataColumn(
                      label: Text('Year',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.getTextColor(context)))),
                  DataColumn(
                      label: Text('Payment',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.getTextColor(context)))),
                  DataColumn(
                      label: Text('Principal',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.getTextColor(context)))),
                  DataColumn(
                      label: Text('Interest',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.getTextColor(context)))),
                  DataColumn(
                      label: Text('Balance',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.getTextColor(context)))),
                ],
                rows: displayedRows.map((r) {
                  return DataRow(
                    cells: [
                      DataCell(Text('Yr ${r.year}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFFFD700)
                                  : const Color(0xFF7C2D12)))),
                      DataCell(Text(
                          CurrencyFormatter.format(r.payment,
                              currencyCode: 'AUD'),
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.getTextColor(context)))),
                      DataCell(Text(
                          CurrencyFormatter.format(r.principal,
                              currencyCode: 'AUD'),
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.getTextColor(context)))),
                      DataCell(Text(
                          CurrencyFormatter.format(r.interest,
                              currencyCode: 'AUD'),
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.getTextColor(context)))),
                      DataCell(Text(
                          CurrencyFormatter.format(r.balance,
                              currencyCode: 'AUD'),
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.getTextColor(context)))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveCalculation,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? theme.getCardColor(context)
                  : const Color(0xFF002868),
              foregroundColor: Colors.white,
              side: isDark
                  ? BorderSide(color: theme.getBorderColor(context))
                  : null,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              minimumSize: const Size(double.infinity, 44),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔖', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text('Save This Schedule',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        weight: FontWeight.w700,
                        color:
                            isDark ? const Color(0xFFFFD700) : Colors.white)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSliderInputRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required String prefix,
    double step = 1,
    required ValueChanged<double> onChanged,
  }) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: AppTextStyles.dmSans(
                size: 9,
                color: theme.mutedColor,
                weight: FontWeight.w800,
                letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFFFF8F0),
            border: Border.all(
                color:
                    isDark ? theme.getBorderColor(context) : theme.borderColor),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              if (prefix.isNotEmpty)
                Text(prefix,
                    style: AppTextStyles.dmSans(
                        size: 14,
                        color: isDark
                            ? const Color(0xFFFFD700)
                            : theme.primaryColor,
                        weight: FontWeight.w700)),
              Expanded(
                child: TextFormField(
                  key: ValueKey(value),
                  initialValue:
                      step == 1 ? value.toInt().toString() : value.toString(),
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.dmSans(
                      size: 14,
                      color: theme.getTextColor(context),
                      weight: FontWeight.w800),
                  decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero),
                  onChanged: (val) {
                    final d = double.tryParse(val) ?? 0.0;
                    onChanged(d);
                  },
                ),
              ),
            ],
          ),
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor:
                isDark ? const Color(0xFFFFD700) : theme.primaryColor,
            inactiveTrackColor:
                (isDark ? const Color(0xFFFFD700) : theme.primaryColor)
                    .withValues(alpha: 0.15),
            thumbColor: isDark ? const Color(0xFFFFD700) : theme.primaryColor,
            trackHeight: 3,
            overlayColor:
                (isDark ? const Color(0xFFFFD700) : theme.primaryColor)
                    .withValues(alpha: 0.1),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: step == 1 ? (max - min).toInt() : null,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
                step == 1
                    ? '\$${(min / 1000).toStringAsFixed(0)}K'
                    : '${min.toStringAsFixed(0)}%',
                style: AppTextStyles.dmSans(
                    size: 9, color: theme.getMutedColor(context))),
            Text(
                step == 1
                    ? '\$${(max / 1000000).toStringAsFixed(1)}M'
                    : '${max.toStringAsFixed(0)}%',
                style: AppTextStyles.dmSans(
                    size: 9, color: theme.getMutedColor(context))),
          ],
        ),
      ],
    );
  }

  Widget _buildFreqTab(String text, bool active, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF7C2D12)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFFFF8F0)),
          border: Border.all(
              color: active
                  ? const Color(0xFF7C2D12)
                  : (isDark
                      ? widget.theme.getBorderColor(context)
                      : const Color(0x3B7C2D12))),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w700,
            color: active
                ? Colors.white
                : (isDark
                    ? widget.theme.getTextColor(context)
                    : const Color(0xFF92400E)),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String val,
      {required String sub, required String colorClass}) {
    LinearGradient grad;
    if (colorClass == 'blue') {
      grad =
          const LinearGradient(colors: [Color(0xFF002868), Color(0xFF1E3A8A)]);
    } else if (colorClass == 'teal') {
      grad =
          const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF115E59)]);
    } else if (colorClass == 'gold') {
      grad =
          const LinearGradient(colors: [Color(0xFFD97706), Color(0xFF92400E)]);
    } else {
      grad =
          const LinearGradient(colors: [Color(0xFF1A0A00), Color(0xFF7C2D12)]);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: grad,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(size: 8.5, color: Colors.white70)),
          const SizedBox(height: 2),
          Text(val,
              style: AppTextStyles.playfair(
                  size: 16, weight: FontWeight.w800, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(sub,
              style: AppTextStyles.dmSans(size: 8.5, color: Colors.white60)),
        ],
      ),
    );
  }

  Widget _buildMilestoneRow(
      String emoji, String title, String sub, String val) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFFFF8F0),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.dmSans(
                        size: 12,
                        weight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black)),
                Text(sub,
                    style: AppTextStyles.dmSans(
                        size: 10,
                        color: isDark
                            ? widget.theme.getMutedColor(context)
                            : const Color(0xFF92400E))),
              ],
            ),
          ),
          Text(val,
              style: AppTextStyles.dmSans(
                  size: 12.5,
                  weight: FontWeight.w800,
                  color: isDark
                      ? const Color(0xFFFFD700)
                      : const Color(0xFF7C2D12))),
        ],
      ),
    );
  }

  Widget _buildDotIndicator(String label, Color color) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label,
            style: AppTextStyles.dmSans(
                size: 10,
                color: widget.theme.getTextColor(context),
                weight: FontWeight.w700)),
      ],
    );
  }
}

class _YearData {
  final int year;
  final double payment;
  final double principal;
  final double interest;
  final double balance;

  _YearData({
    required this.year,
    required this.payment,
    required this.principal,
    required this.interest,
    required this.balance,
  });
}

class _AmortChartPainter extends CustomPainter {
  final List<_YearData> yearlyData;
  final double maxVal;
  final bool isDark;

  _AmortChartPainter(
      {required this.yearlyData, required this.maxVal, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (yearlyData.isEmpty) return;

    final paintBalance = Paint()
      ..color = (isDark ? const Color(0xFFFCA5A5) : const Color(0xFF7C2D12))
          .withValues(alpha: isDark ? 0.05 : 0.1)
      ..style = PaintingStyle.fill;

    final paintPrincipal = Paint()
      ..color = isDark ? const Color(0xFFFCA5A5) : const Color(0xFF7C2D12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final paintInterest = Paint()
      ..color = isDark ? const Color(0xFF60A5FA) : const Color(0xFF002868)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final pathBalance = Path();
    final pathPrincipal = Path();
    final pathInterest = Path();

    final dx = size.width / (yearlyData.length - 1);

    double cumPrinc = 0;
    double cumInt = 0;

    for (int i = 0; i < yearlyData.length; i++) {
      final x = i * dx;
      final d = yearlyData[i];

      cumPrinc += d.principal;
      cumInt += d.interest;

      final yBal = size.height - (d.balance / maxVal * size.height);
      final yPrinc = size.height - (cumPrinc / maxVal * size.height);
      final yInt = size.height - (cumInt / maxVal * size.height);

      if (i == 0) {
        pathBalance.moveTo(x, yBal);
        pathPrincipal.moveTo(x, yPrinc);
        pathInterest.moveTo(x, yInt);
      } else {
        pathBalance.lineTo(x, yBal);
        pathPrincipal.lineTo(x, yPrinc);
        pathInterest.lineTo(x, yInt);
      }
    }

    // Close the balance fill path
    pathBalance.lineTo(size.width, size.height);
    pathBalance.lineTo(0, size.height);
    pathBalance.close();

    canvas.drawPath(pathBalance, paintBalance);
    canvas.drawPath(pathPrincipal, paintPrincipal);
    canvas.drawPath(pathInterest, paintInterest);
  }

  @override
  bool shouldRepaint(covariant _AmortChartPainter oldDelegate) => true;
}
