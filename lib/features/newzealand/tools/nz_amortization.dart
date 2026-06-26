// lib/features/newzealand/tools/nz_amortization.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../providers/nz_rates_provider.dart';

class NZAmortization extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const NZAmortization({super.key, this.theme = CountryThemes.newZealand});

  @override
  ConsumerState<NZAmortization> createState() => _NZAmortizationState();
}

class _NZAmortizationState extends ConsumerState<NZAmortization> {
  double _loanAmt = 680000;
  double _rate = 5.59;
  int _termYears = 30;
  int _startYear = 2025;

  bool _showResults = false;
  bool _showAllYears = false;
  bool _isMonthlyView = false;
  int _selectedYearIndex = 1; // 1-indexed year

  List<_AmortMonth> _schedule = [];

  void _reset() {
    setState(() {
      _loanAmt = 680000;
      _rate = 5.59;
      _termYears = 30;
      _startYear = 2025;
      _showResults = false;
      _showAllYears = false;
      _isMonthlyView = false;
      _selectedYearIndex = 1;
      _schedule = [];
    });
  }

  void _buildSchedule() {
    final loan = _loanAmt;
    final rate = _rate;
    final years = _termYears;
    final r = rate / 100 / 12;
    final n = years * 12;
    final m =
        r == 0 ? loan / n : loan * (r * pow(1 + r, n)) / (pow(1 + r, n) - 1);

    double bal = loan;
    List<_AmortMonth> sched = [];
    for (int mo = 1; mo <= n; mo++) {
      final monthlyInt = bal * r;
      final prin = m - monthlyInt;
      bal = max(0.0, bal - prin);
      sched.add(_AmortMonth(mo, monthlyInt, prin, bal, m));
    }
    setState(() {
      _schedule = sched;
      _showResults = true;
    });
  }

  void _saveCalculation() async {
    if (_schedule.isEmpty) return;
    final monthly = _schedule.first.pmt;
    final totalPaid = monthly * _termYears * 12;

    final labelCtrl = TextEditingController(text: 'NZ Amortization Plan');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Amortization',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Saving: ${CurrencyFormatter.compact(_loanAmt, symbol: "NZ\$")} schedule @ $_rate% for $_termYears yrs',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. 30yr Amortization)',
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
          : 'Amortization';
      final calc = SavedCalc.create(
        country: 'New Zealand',
        calcType: 'Amortization',
        inputs: {
          'loanAmount': _loanAmt,
          'rate': _rate,
          'termYears': _termYears.toDouble(),
          'startYear': _startYear.toDouble(),
        },
        results: {
          'monthly': monthly,
          'totalPaid': totalPaid,
          'totalInterest': totalPaid - _loanAmt,
        },
        label: label,
        currencyCode: 'NZD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Amortization saved!',
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

    // Inject live rate on first build if still at default
    final nzRates = ref.watch(nzRatesProvider).valueOrNull;
    final liveRate = nzRates?.fixed1yr.value;
    if (liveRate != null && _rate == 5.59) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _rate == 5.59) setState(() => _rate = liveRate);
      });
    }

    // Derived summary details
    double monthly = 0;
    double totalPaid = 0;
    double totalInt = 0;

    int half25 = 0;
    int half50 = 0;
    int half75 = 0;

    if (_schedule.isNotEmpty) {
      monthly = _schedule.first.pmt;
      totalPaid = monthly * _termYears * 12;
      totalInt = totalPaid - _loanAmt;

      half25 = _schedule.indexWhere((m) => m.bal <= _loanAmt * 0.75) + 1;
      half50 = _schedule.indexWhere((m) => m.bal <= _loanAmt * 0.50) + 1;
      half75 = _schedule.indexWhere((m) => m.bal <= _loanAmt * 0.25) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Inputs Card
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
                  Text('Amortization Setup',
                      style: AppTextStyles.dmSans(
                          size: 10,
                          color: theme.getMutedColor(context),
                          weight: FontWeight.w600)),
                  GestureDetector(
                    onTap: _reset,
                    child: Text('Reset ↺',
                        style: AppTextStyles.dmSans(
                            size: 11,
                            color: const Color(0xFFC0392B),
                            weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Loan Repayment Schedule',
                  style: AppTextStyles.playfair(
                      size: 18,
                      color: theme.getTextColor(context),
                      weight: FontWeight.w800)),
              const SizedBox(height: 16),

              // Inputs Row
              Row(
                children: [
                  Expanded(
                    child: _buildInputBox(
                      label: 'Loan Amount',
                      prefix: 'NZD \$',
                      value: _loanAmt,
                      onChanged: (val) => setState(() => _loanAmt = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputBox(
                      label: 'Interest Rate %',
                      prefix: '',
                      value: _rate,
                      isPercent: true,
                      onChanged: (val) => setState(() => _rate = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildInputBox(
                      label: 'Loan Term (yrs)',
                      prefix: '',
                      value: _termYears.toDouble(),
                      isInteger: true,
                      onChanged: (val) =>
                          setState(() => _termYears = val.toInt()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputBox(
                      label: 'Start Year',
                      prefix: '',
                      value: _startYear.toDouble(),
                      isInteger: true,
                      onChanged: (val) =>
                          setState(() => _startYear = val.toInt()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Generate Button
              ElevatedButton(
                onPressed: () {
                  if (_loanAmt <= 0) return;
                  _buildSchedule();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A6B4A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: Text('📅 Generate Schedule',
                    style: AppTextStyles.dmSans(
                        size: 14,
                        color: Colors.white,
                        weight: FontWeight.w800)),
              ),
            ],
          ),
        ),

        // Results Summary
        if (_showResults && _schedule.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Summary',
              style: AppTextStyles.playfair(
                  size: 15, color: theme.getTextColor(context))),
          const SizedBox(height: 10),

          // Summary grid
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A0F0D), Color(0xFF0D3B2E)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildSummaryBox(
                    'Monthly Payment',
                    CurrencyFormatter.format(monthly, currencyCode: 'NZD'),
                    const Color(0xFF6EE7B7)),
                _buildSummaryBox(
                    'Total Repaid',
                    CurrencyFormatter.compact(totalPaid, symbol: 'NZ\$'),
                    const Color(0xFFF5D060)),
                _buildSummaryBox(
                    'Total Interest',
                    CurrencyFormatter.compact(totalInt, symbol: 'NZ\$'),
                    const Color(0xFFFCA5A5)),
                _buildSummaryBox('Loan Paid Off', '${_startYear + _termYears}',
                    Colors.white),
              ],
            ),
          ),

          // Area Chart Card
          const SizedBox(height: 20),
          Text('Balance Reduction Over Time',
              style: AppTextStyles.playfair(
                  size: 15, color: theme.getTextColor(context))),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amortization Balance Trajectory',
                    style: AppTextStyles.dmSans(
                        size: 11,
                        weight: FontWeight.w800,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _NZAmortizationAreaPainter(
                      schedule: _schedule,
                      loanAmount: _loanAmt,
                      termYears: _termYears,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildDot(
                        'Principal Remaining', const Color(0xFF1A6B4A), theme),
                    const SizedBox(width: 14),
                    _buildDot(
                        'Cumulative Interest', const Color(0xFFC0392B), theme),
                  ],
                ),
              ],
            ),
          ),

          // Milestones
          const SizedBox(height: 20),
          Text('Key Milestones',
              style: AppTextStyles.playfair(
                  size: 15, color: theme.getTextColor(context))),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.45,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _buildMilestoneCard(
                  '🎯',
                  '25% Paid Off',
                  '${CurrencyFormatter.compact(_loanAmt * 0.25, symbol: "NZ\$")} equity',
                  half25 > 0 ? 'Month $half25' : 'N/A',
                  theme),
              _buildMilestoneCard(
                  '🏆',
                  '50% Paid Off',
                  '${CurrencyFormatter.compact(_loanAmt * 0.50, symbol: "NZ\$")} equity',
                  half50 > 0 ? 'Month $half50' : 'N/A',
                  theme),
              _buildMilestoneCard(
                  '🌟',
                  '75% Paid Off',
                  '${CurrencyFormatter.compact(_loanAmt * 0.75, symbol: "NZ\$")} equity',
                  half75 > 0 ? 'Month $half75' : 'N/A',
                  theme),
              _buildMilestoneCard(
                  '🎉',
                  'Fully Paid',
                  '${CurrencyFormatter.compact(totalPaid, symbol: "NZ\$")} total',
                  'Year ${_startYear + _termYears}',
                  theme),
            ],
          ),

          // Year-by-Year Schedule Header
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Schedule Details',
                  style: AppTextStyles.playfair(
                      size: 15, color: theme.getTextColor(context))),
              GestureDetector(
                onTap: () => setState(() => _isMonthlyView = !_isMonthlyView),
                child: Text(_isMonthlyView ? 'Yearly View →' : 'Monthly View →',
                    style: AppTextStyles.dmSans(
                        size: 11,
                        weight: FontWeight.w700,
                        color: const Color(0xFF1A6B4A))),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Monthly view tabs
          if (_isMonthlyView) ...[
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _termYears,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, idx) {
                  final yrLabel = _startYear + idx;
                  final active = _selectedYearIndex == (idx + 1);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedYearIndex = idx + 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF0D3B2E)
                            : theme.getCardColor(context),
                        border: Border.all(
                            color: active
                                ? const Color(0xFF1A6B4A)
                                : theme.getBorderColor(context)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('$yrLabel',
                          style: AppTextStyles.dmSans(
                              size: 11,
                              weight: FontWeight.w700,
                              color: active
                                  ? Colors.white
                                  : theme.getTextColor(context))),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Table
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              children: [
                _buildTableHeader(),
                const Divider(),
                _buildTableRows(theme),
                if (!_isMonthlyView) ...[
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () =>
                        setState(() => _showAllYears = !_showAllYears),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.getBgColor(context),
                      foregroundColor: theme.getTextColor(context),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                        _showAllYears
                            ? '📋 Collapse Schedule'
                            : '📋 View All Years',
                        style: AppTextStyles.dmSans(
                            size: 11, weight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ),

          // Save Schedule
          const SizedBox(height: 14),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💾 Save schedule',
                        style: AppTextStyles.dmSans(
                            size: 11,
                            weight: FontWeight.w800,
                            color: theme.getTextColor(context))),
                    Text('Full amortization saved to portfolio',
                        style: AppTextStyles.dmSans(
                            size: 9, color: theme.getMutedColor(context))),
                  ],
                ),
                ElevatedButton(
                  onPressed: _saveCalculation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Save',
                      style: AppTextStyles.dmSans(
                          size: 11,
                          color: Colors.white,
                          weight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInputBox({
    required String label,
    required String prefix,
    required double value,
    bool isPercent = false,
    bool isInteger = false,
    required ValueChanged<double> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFEDF5F2),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0x150D3B2E)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 8.5,
                  color: isDark ? Colors.white70 : const Color(0xFF4A6358),
                  weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (prefix.isNotEmpty)
                Text('$prefix ',
                    style: AppTextStyles.dmSans(
                        size: 11,
                        color:
                            isDark ? Colors.white70 : const Color(0xFF4A6358),
                        weight: FontWeight.w700)),
              Expanded(
                child: TextFormField(
                  initialValue:
                      isInteger ? value.toInt().toString() : value.toString(),
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.playfair(
                      size: 15,
                      color: isDark ? Colors.white : const Color(0xFF0A0F0D),
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
                        size: 11,
                        color:
                            isDark ? Colors.white70 : const Color(0xFF4A6358),
                        weight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 8.5, color: Colors.white54, weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.dmSans(
                  size: 14, color: color, weight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildDot(String label, Color color, CountryTheme theme) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label,
            style: AppTextStyles.dmSans(
                size: 10, color: theme.getMutedColor(context))),
      ],
    );
  }

  Widget _buildMilestoneCard(
      String icon, String label, String value, String sub, CountryTheme theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.getBorderColor(context)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 9,
                  color: theme.getMutedColor(context),
                  weight: FontWeight.w700)),
          Text(value,
              style: AppTextStyles.dmSans(
                  size: 12,
                  color: theme.getTextColor(context),
                  weight: FontWeight.w800)),
          Text(sub,
              style: AppTextStyles.dmSans(
                  size: 9, color: theme.getMutedColor(context))),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: Text('Period',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey))),
          Expanded(
              child: Text('Principal',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey),
                  textAlign: TextAlign.right)),
          Expanded(
              child: Text('Interest',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey),
                  textAlign: TextAlign.right)),
          Expanded(
              child: Text('Balance',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey),
                  textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildTableRows(CountryTheme theme) {
    List<Widget> rows = [];
    if (_isMonthlyView) {
      final int startIdx = (_selectedYearIndex - 1) * 12;
      final int endIdx = min(startIdx + 12, _schedule.length);
      final List<_AmortMonth> yearMonths = _schedule.sublist(startIdx, endIdx);

      for (int i = 0; i < yearMonths.length; i++) {
        final m = yearMonths[i];
        rows.add(_buildTableRow(
          'Mo ${startIdx + i + 1}',
          CurrencyFormatter.compact(m.prin, symbol: ''),
          CurrencyFormatter.compact(m.interest, symbol: ''),
          CurrencyFormatter.compact(m.bal, symbol: ''),
          theme,
        ));
      }
      if (yearMonths.length > 6) {
        // Just show a scroll hint if needed, but since it's only 12 rows, we can output all 12.
      }
    } else {
      final int limit = _showAllYears ? _termYears : min(10, _termYears);
      for (int y = 1; y <= limit; y++) {
        final int fromIdx = (y - 1) * 12;
        final int toIdx = min(y * 12, _schedule.length);
        final List<_AmortMonth> yearMonths = _schedule.sublist(fromIdx, toIdx);

        final totalPrin =
            yearMonths.fold<double>(0.0, (sum, m) => sum + m.prin);
        final totalInterest =
            yearMonths.fold<double>(0.0, (sum, m) => sum + m.interest);
        final endBalance = yearMonths.last.bal;

        rows.add(_buildTableRow(
          '${_startYear + y - 1}',
          CurrencyFormatter.compact(totalPrin, symbol: ''),
          CurrencyFormatter.compact(totalInterest, symbol: ''),
          CurrencyFormatter.compact(endBalance, symbol: ''),
          theme,
        ));
      }
    }

    return Column(children: rows);
  }

  Widget _buildTableRow(String label, String prin, String interest, String bal,
      CountryTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: Text(label,
                  style: AppTextStyles.dmSans(
                      size: 11,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context)))),
          Expanded(
              child: Text('\$$prin',
                  style: AppTextStyles.dmSans(
                      size: 10.5,
                      color: const Color(0xFF1A6B4A),
                      weight: FontWeight.w600),
                  textAlign: TextAlign.right)),
          Expanded(
              child: Text('\$$interest',
                  style: AppTextStyles.dmSans(
                      size: 10.5,
                      color: const Color(0xFFC0392B),
                      weight: FontWeight.w600),
                  textAlign: TextAlign.right)),
          Expanded(
              child: Text('\$$bal',
                  style: AppTextStyles.dmSans(
                      size: 10.5,
                      color: theme.getTextColor(context),
                      weight: FontWeight.w700),
                  textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _AmortMonth {
  final int mo;
  final double interest;
  final double prin;
  final double bal;
  final double pmt;
  _AmortMonth(this.mo, this.interest, this.prin, this.bal, this.pmt);
}

class _NZAmortizationAreaPainter extends CustomPainter {
  final List<_AmortMonth> schedule;
  final double loanAmount;
  final int termYears;

  _NZAmortizationAreaPainter({
    required this.schedule,
    required this.loanAmount,
    required this.termYears,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (schedule.isEmpty) return;

    final W = size.width;
    final H = size.height;
    const pad = 15.0;

    // Filter points to draw (e.g. 50 points max to prevent overload)
    final int step = max(1, (schedule.length / 50).floor());
    List<_AmortMonth> pts = [];
    for (int i = 0; i < schedule.length; i += step) {
      pts.add(schedule[i]);
    }
    if (pts.last.mo != schedule.last.mo) {
      pts.add(schedule.last);
    }

    // Cumulative interest calculations
    double cumIntSum = 0;
    final List<double> cumInterest = [];
    for (var m in schedule) {
      cumIntSum += m.interest;
      cumInterest.add(cumIntSum);
    }
    final double maxInt = cumInterest.last;

    // Build path points
    final Path balPath = Path();
    final Path intPath = Path();

    for (int i = 0; i < pts.length; i++) {
      final p = pts[i];
      final x = pad + (i / (pts.length - 1)) * (W - 2 * pad);
      final yBal = H - pad - (p.bal / loanAmount) * (H - 2 * pad);

      final cumI = cumInterest[min(p.mo - 1, cumInterest.length - 1)];
      final yInt = H - pad - (cumI / maxInt) * (H - 2 * pad);

      if (i == 0) {
        balPath.moveTo(x, yBal);
        intPath.moveTo(x, yInt);
      } else {
        balPath.lineTo(x, yBal);
        intPath.lineTo(x, yInt);
      }
    }

    // Draw Principal Remaining Fill & Stroke
    final Paint fillBal = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1A6B4A).withValues(alpha: 0.4),
          const Color(0xFF1A6B4A).withValues(alpha: 0.02)
        ],
      ).createShader(Rect.fromLTWH(0, 0, W, H));
    final Path fillBalPath = Path.from(balPath)
      ..lineTo(W - pad, H - pad)
      ..lineTo(pad, H - pad)
      ..close();
    canvas.drawPath(fillBalPath, fillBal);

    final Paint strokeBal = Paint()
      ..color = const Color(0xFF1A6B4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(balPath, strokeBal);

    // Draw Cumulative Interest Fill & Stroke
    final Paint fillInt = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFC0392B).withValues(alpha: 0.3),
          const Color(0xFFC0392B).withValues(alpha: 0.02)
        ],
      ).createShader(Rect.fromLTWH(0, 0, W, H));
    final Path fillIntPath = Path.from(intPath)
      ..lineTo(W - pad, H - pad)
      ..lineTo(pad, H - pad)
      ..close();
    canvas.drawPath(fillIntPath, fillInt);

    final Paint strokeInt = Paint()
      ..color = const Color(0xFFC0392B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(intPath, strokeInt);

    // Baseline axis
    final Paint baseline = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(pad, H - pad), Offset(W - pad, H - pad), baseline);

    // Labels
    final tpYear1 = TextPainter(
      text: const TextSpan(
          text: 'Year 1', style: TextStyle(color: Colors.grey, fontSize: 8)),
      textDirection: TextDirection.ltr,
    )..layout();
    tpYear1.paint(canvas, Offset(pad, H - 12));

    final tpYearEnd = TextPainter(
      text: TextSpan(
          text: 'Year $termYears',
          style: const TextStyle(color: Colors.grey, fontSize: 8)),
      textDirection: TextDirection.ltr,
    )..layout();
    tpYearEnd.paint(canvas, Offset(W - pad - tpYearEnd.width, H - 12));
  }

  @override
  bool shouldRepaint(covariant _NZAmortizationAreaPainter oldDelegate) =>
      oldDelegate.schedule != schedule ||
      oldDelegate.loanAmount != loanAmount ||
      oldDelegate.termYears != termYears;
}
