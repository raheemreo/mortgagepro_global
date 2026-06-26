// lib/features/australia/tools/au_construction_loan.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class AUConstructionLoan extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const AUConstructionLoan({super.key, this.theme = CountryThemes.australia});

  @override
  ConsumerState<AUConstructionLoan> createState() => _AUConstructionLoanState();
}

class _AUConstructionLoanState extends ConsumerState<AUConstructionLoan> {
  double _totalCost = 380000;
  double _landValue = 320000;
  double _deposit = 70000;
  double _constRate = 6.49;
  double _piRate = 6.09;
  int _loanTermYr = 30;
  int _buildMonths = 12;
  String _builderType = 'vol'; // 'vol', 'cus', 'ow'

  final List<_BuildStage> _stages = [
    _BuildStage(name: 'Base / Slab', pct: 15, status: 'done', months: 1.5),
    _BuildStage(name: 'Frame', pct: 20, status: 'done', months: 2.0),
    _BuildStage(name: 'Lock-Up', pct: 25, status: 'active', months: 2.5),
    _BuildStage(name: 'Fit-Out', pct: 25, status: 'pending', months: 3.5),
    _BuildStage(
        name: 'Practical Completion', pct: 15, status: 'pending', months: 2.5),
  ];

  bool _showResults = false;

  void _reset() {
    setState(() {
      _totalCost = 380000;
      _landValue = 320000;
      _deposit = 70000;
      _constRate = 6.49;
      _piRate = 6.09;
      _loanTermYr = 30;
      _buildMonths = 12;
      _builderType = 'vol';
      _stages[0].status = 'done';
      _stages[0].pct = 15;
      _stages[1].status = 'done';
      _stages[1].pct = 20;
      _stages[2].status = 'active';
      _stages[2].pct = 25;
      _stages[3].status = 'pending';
      _stages[3].pct = 25;
      _stages[4].status = 'pending';
      _stages[4].pct = 15;
      _showResults = false;
    });
  }

  double _monthlyPmt(double p, double ratePercent, int years) {
    final r = ratePercent / 100 / 12;
    final n = years * 12;
    if (r == 0) return p / n;
    return p * r * pow(1 + r, n) / (pow(1 + r, n) - 1);
  }

  void _saveCalculation() async {
    final loanAmt = _landValue + _totalCost - _deposit;
    final propValue = _landValue + _totalCost;
    final lvr = propValue > 0 ? (loanAmt / propValue) * 100 : 0.0;
    final monthlyConstRate = _constRate / 100 / 12;

    final List<_DrawdownEvent> drawdownEvents = [];
    double cumMonths = 0;
    for (int i = 0; i < _stages.length; i++) {
      final s = _stages[i];
      cumMonths += s.months;
      final mo = min(cumMonths.round(), _buildMonths);
      drawdownEvents.add(_DrawdownEvent(
          mo: mo, amt: loanAmt * s.pct / 100, stageName: s.name, stageIdx: i));
    }

    double drawn = 0;
    double totalConstInt = 0;
    for (int mo = 1; mo <= _buildMonths; mo++) {
      for (final ev in drawdownEvents) {
        if (ev.mo == mo) drawn += ev.amt;
      }
      drawn = min(drawn, loanAmt);
      final interest = drawn * monthlyConstRate;
      totalConstInt += interest;
    }

    final piPmt = _monthlyPmt(loanAmt, _piRate, _loanTermYr);

    final labelCtrl = TextEditingController(text: 'My Construction Loan');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Project',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Saving: \$${CurrencyFormatter.compact(loanAmt, symbol: 'AU\$')} total loan',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Knockdown Rebuild)',
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
          : 'Construction Project';
      final calc = SavedCalc.create(
        country: 'Australia',
        calcType: 'Construction Loan',
        inputs: {
          'totalCost': _totalCost,
          'landValue': _landValue,
          'deposit': _deposit,
          'constRate': _constRate,
          'piRate': _piRate,
          'loanTermYr': _loanTermYr.toDouble(),
          'buildMonths': _buildMonths.toDouble(),
        },
        results: {
          'loanAmount': loanAmt,
          'totalConstInt': totalConstInt,
          'piPmt': piPmt,
          'lvr': lvr,
        },
        label: label,
        currencyCode: 'AUD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Project saved!',
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

    final loanAmt = _landValue + _totalCost - _deposit;
    final propValue = _landValue + _totalCost;
    final lvr = propValue > 0 ? (loanAmt / propValue) * 100 : 0.0;
    final monthlyConstRate = _constRate / 100 / 12;

    final List<_DrawdownEvent> drawdownEvents = [];
    double cumMonths = 0;
    for (int i = 0; i < _stages.length; i++) {
      final s = _stages[i];
      cumMonths += s.months;
      final mo = min(cumMonths.round(), _buildMonths);
      drawdownEvents.add(_DrawdownEvent(
          mo: mo, amt: loanAmt * s.pct / 100, stageName: s.name, stageIdx: i));
    }

    double drawn = 0;
    final List<_DrawdownMonthData> monthlyData = [];
    double totalConstInt = 0;
    for (int mo = 1; mo <= _buildMonths; mo++) {
      for (final ev in drawdownEvents) {
        if (ev.mo == mo) drawn += ev.amt;
      }
      drawn = min(drawn, loanAmt);
      final interest = drawn * monthlyConstRate;
      totalConstInt += interest;
      monthlyData.add(_DrawdownMonthData(
          mo: mo,
          drawn: drawn,
          interest: interest,
          remaining: loanAmt - drawn));
    }

    final piPmt = _monthlyPmt(loanAmt, _piRate, _loanTermYr);
    final avgMonthlyInt = _buildMonths > 0 ? totalConstInt / _buildMonths : 0.0;

    // Build stage tracker progress
    double donePct = 0;
    for (final s in _stages) {
      if (s.status == 'done') {
        donePct += s.pct;
      } else if (s.status == 'active') {
        donePct += s.pct / 2;
      }
    }
    final drawnProgress = loanAmt * donePct / 100;
    final remainingProgress = loanAmt - drawnProgress;

    // Stage colors list
    final List<Color> stageColors = [
      isDark ? const Color(0xFFFCA5A5) : const Color(0xFF7C2D12),
      isDark ? const Color(0xFF60A5FA) : const Color(0xFF002868),
      isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
      isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706),
      isDark ? const Color(0xFF34D399) : const Color(0xFF15803D)
    ];

    // Post-build first 10 years amortization stacked bar points
    final List<_PostBuildYearData> postBuildPts = [];
    double pbBal = loanAmt;
    final r = _piRate / 100 / 12;
    for (int y = 1; y <= min(_loanTermYr, 10); y++) {
      double intYear = 0;
      double prinYear = 0;
      for (int m = 0; m < 12; m++) {
        final i = pbBal * r;
        intYear += i;
        pbBal = max(0.0, pbBal - (piPmt - i));
        prinYear += piPmt - i;
      }
      postBuildPts.add(
          _PostBuildYearData(year: y, principal: prinYear, interest: intYear));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(colors: [
                    const Color(0xFF7C2D12).withValues(alpha: 0.2),
                    const Color(0xFF7C2D12).withValues(alpha: 0.1)
                  ])
                : const LinearGradient(
                    colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)]),
            border: Border.all(
                color: isDark
                    ? const Color(0xFFEA580C).withValues(alpha: 0.4)
                    : const Color(0xFFFCA5A5)),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🏗️', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How Construction Loans Work in Australia',
                        style: AppTextStyles.playfair(
                            size: 12,
                            color: isDark
                                ? const Color(0xFFFFD700)
                                : const Color(0xFF7C2D12),
                            weight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      'Funds are released in progressive drawdowns at each build stage. You only pay interest on the amount drawn down — not the full loan — during construction. Once the build is complete, it converts to a standard P&I mortgage.',
                      style: AppTextStyles.dmSans(
                          size: 10,
                          color: isDark
                              ? const Color(0xFFFFEDD5)
                              : const Color(0xFFC2410C),
                          height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Inputs Card
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
                  Text('Construction Finance',
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
              Row(
                children: [
                  Expanded(
                      child: _buildInputBox(
                          'Total Build Cost', 'AUD \$', _totalCost,
                          onChanged: (v) => setState(() => _totalCost = v))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _buildInputBox('Land Value', 'AUD \$', _landValue,
                          onChanged: (v) => setState(() => _landValue = v))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _buildInputBox('Deposit Paid', 'AUD \$', _deposit,
                          onChanged: (v) => setState(() => _deposit = v))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _buildInputBox(
                          'Construction Rate', '% p.a.', _constRate,
                          isPercent: true,
                          onChanged: (v) => setState(() => _constRate = v))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _buildInputBox(
                          'P&I Rate (post-build)', '% p.a.', _piRate,
                          isPercent: true,
                          onChanged: (v) => setState(() => _piRate = v))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _buildInputBox(
                          'Loan Term', 'yrs', _loanTermYr.toDouble(),
                          isInteger: true,
                          onChanged: (v) =>
                              setState(() => _loanTermYr = v.toInt()))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _buildInputBox(
                          'Build Duration', 'months', _buildMonths.toDouble(),
                          isInteger: true,
                          onChanged: (v) =>
                              setState(() => _buildMonths = v.toInt()))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BUILDER',
                            style: AppTextStyles.dmSans(
                                size: 9,
                                color: theme.getMutedColor(context),
                                weight: FontWeight.w800)),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFFFF8F0),
                            border: Border.all(
                                color: isDark
                                    ? theme.getBorderColor(context)
                                    : theme.borderColor),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _builderType,
                              dropdownColor: theme.getCardColor(context),
                              isExpanded: true,
                              style: AppTextStyles.dmSans(
                                  size: 14,
                                  color: theme.getTextColor(context),
                                  weight: FontWeight.bold),
                              items: [
                                DropdownMenuItem(
                                    value: 'vol',
                                    child: Text('Volume Builder',
                                        style: AppTextStyles.dmSans(
                                            color:
                                                theme.getTextColor(context)))),
                                DropdownMenuItem(
                                    value: 'cus',
                                    child: Text('Custom Builder',
                                        style: AppTextStyles.dmSans(
                                            color:
                                                theme.getTextColor(context)))),
                                DropdownMenuItem(
                                    value: 'ow',
                                    child: Text('Owner-Builder',
                                        style: AppTextStyles.dmSans(
                                            color:
                                                theme.getTextColor(context)))),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _builderType = v);
                              },
                            ),
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

        const SizedBox(height: 12),

        // Progressive Drawdown Stages Card
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
              Text('Build Stages (AUS Standard)',
                  style: AppTextStyles.dmSans(
                      size: 11,
                      color:
                          isDark ? const Color(0xFFFFD700) : theme.primaryColor,
                      weight: FontWeight.w700,
                      letterSpacing: 0.5)),
              const SizedBox(height: 12),
              ..._stages.asMap().entries.map((entry) {
                final idx = entry.key;
                final s = entry.value;
                final amt = _totalCost * s.pct / 100;
                final isActive = s.status == 'active';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isActive
                        ? (isDark
                            ? theme.primaryColor.withValues(alpha: 0.25)
                            : const Color(0xFFFFF0E4))
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFFFF8F0)),
                    border: Border.all(
                        color: isActive
                            ? theme.primaryColor
                            : (isDark
                                ? theme.getBorderColor(context)
                                : const Color(0xFFE2E8F0))),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(s.name,
                                  style: AppTextStyles.dmSans(
                                      size: 12,
                                      weight: FontWeight.bold,
                                      color: theme.getTextColor(context))),
                              const SizedBox(width: 8),
                              _buildStatusBadge(s.status),
                            ],
                          ),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: s.status,
                              dropdownColor: theme.getCardColor(context),
                              isDense: true,
                              style: AppTextStyles.dmSans(
                                  size: 10,
                                  weight: FontWeight.bold,
                                  color: isDark
                                      ? const Color(0xFFFFD700)
                                      : theme.primaryColor),
                              items: [
                                DropdownMenuItem(
                                    value: 'done',
                                    child: Text('Done',
                                        style: AppTextStyles.dmSans(
                                            size: 10,
                                            color:
                                                theme.getTextColor(context)))),
                                DropdownMenuItem(
                                    value: 'active',
                                    child: Text('In Progress',
                                        style: AppTextStyles.dmSans(
                                            size: 10,
                                            color:
                                                theme.getTextColor(context)))),
                                DropdownMenuItem(
                                    value: 'pending',
                                    child: Text('Pending',
                                        style: AppTextStyles.dmSans(
                                            size: 10,
                                            color:
                                                theme.getTextColor(context)))),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => s.status = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: s.pct / 100,
                                minHeight: 6,
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : const Color(0xFFE5E7EB),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    stageColors[idx]),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${s.pct.toInt()}%',
                              style: AppTextStyles.dmSans(
                                  size: 12,
                                  weight: FontWeight.bold,
                                  color: theme.getTextColor(context))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Drawdown Amount',
                              style: AppTextStyles.dmSans(
                                  size: 10,
                                  color: theme.getMutedColor(context))),
                          Text(
                              CurrencyFormatter.format(amt,
                                  currencyCode: 'AUD'),
                              style: AppTextStyles.dmSans(
                                  size: 11,
                                  weight: FontWeight.bold,
                                  color: theme.getTextColor(context))),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
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
                child: Text('🏗️ Calculate Construction Costs',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        color: Colors.white,
                        weight: FontWeight.w800)),
              ),
            ],
          ),
        ),

        // Construction Progress Stage Tracker Card
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF002868),
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Build Stage Tracker',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 14),
              // Step timeline
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _stages.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final s = entry.value;
                  final isDone = s.status == 'done';
                  final isActive = s.status == 'active';

                  return Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isDone
                                ? const Color(0xFFFFD700)
                                : isActive
                                    ? const Color(0x4DFFD700)
                                    : Colors.white10,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: isDone || isActive
                                    ? const Color(0xFFFFD700)
                                    : Colors.white30,
                                width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            isDone
                                ? '✓'
                                : isActive
                                    ? '⚡'
                                    : '${idx + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDone ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.name.split(' ')[0],
                          style: const TextStyle(
                              fontSize: 8, color: Colors.white60),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _buildProgressStat(
                          'Drawn Down', formatAud(drawnProgress),
                          isGold: true)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildProgressStat(
                          'Remaining', formatAud(remainingProgress))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildProgressStat(
                          'Build %', '${donePct.round()}%',
                          isGold: true)),
                ],
              ),
            ],
          ),
        ),

        // Results Section
        if (_showResults) ...[
          const SizedBox(height: 20),

          // Result Summary Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cost Summary',
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
            padding: const EdgeInsets.all(20),
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
                Text('Total Interest During Construction',
                    style: AppTextStyles.dmSans(
                        size: 10,
                        color: Colors.white60,
                        weight: FontWeight.w700,
                        letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text(
                    CurrencyFormatter.format(totalConstInt,
                        currencyCode: 'AUD'),
                    style: AppTextStyles.playfair(
                        size: 34,
                        color: const Color(0xFFFFD700),
                        weight: FontWeight.w800)),
                Text('interest-only during build period',
                    style:
                        AppTextStyles.dmSans(size: 12, color: Colors.white70)),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _buildHeroBox('Monthly P&I (post-build)',
                        '${CurrencyFormatter.format(piPmt, currencyCode: 'AUD')}/mo',
                        color: const Color(0xFFFFD700)),
                    _buildHeroBox('Total Loan Amount',
                        CurrencyFormatter.format(loanAmt, currencyCode: 'AUD')),
                    _buildHeroBox('LVR',
                        '${lvr.toStringAsFixed(1)}%${lvr > 80 ? ' ⚠️' : ' ✓'}'),
                    _buildHeroBox('Avg Interest / Month',
                        '${CurrencyFormatter.format(avgMonthlyInt, currencyCode: 'AUD')}/mo',
                        color: const Color(0xFFBBF7D0)),
                  ],
                ),
              ],
            ),
          ),

          // Progressive Drawdown chart
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
                Text('📊 Progressive Drawdown & Interest',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        weight: FontWeight.w800,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildLegendItem(
                        isDark
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF002868),
                        'Cumul. Draw'),
                    const SizedBox(width: 14),
                    _buildLegendItem(
                        const Color(0xFFEF4444), 'Monthly Interest'),
                    const SizedBox(width: 14),
                    _buildLegendItem(
                        const Color(0xFFFFD700), 'Remaining Funds'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _DrawdownChartPainter(
                      monthlyData: monthlyData,
                      loanAmt: loanAmt,
                      isDark: isDark,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stage Interest Table Card
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
                Text('📋 Stage-by-Stage Interest Breakdown',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        weight: FontWeight.w800,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 12),
                DataTable(
                  columnSpacing: 10,
                  horizontalMargin: 4,
                  columns: [
                    DataColumn(
                        label: Text('Stage',
                            style:
                                TextStyle(color: theme.getTextColor(context)))),
                    DataColumn(
                        label: Text('Drawdown',
                            style:
                                TextStyle(color: theme.getTextColor(context)))),
                    DataColumn(
                        label: Text('Balance',
                            style:
                                TextStyle(color: theme.getTextColor(context)))),
                    DataColumn(
                        label: Text('Int. Due',
                            style:
                                TextStyle(color: theme.getTextColor(context)))),
                  ],
                  rows: _stages.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final s = entry.value;
                    final amt = loanAmt * s.pct / 100;

                    double cumBalance = 0;
                    for (int i = 0; i <= idx; i++) {
                      cumBalance += loanAmt * _stages[i].pct / 100;
                    }
                    final stageInt = cumBalance * monthlyConstRate * s.months;

                    return DataRow(
                      cells: [
                        DataCell(Row(
                          children: [
                            Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: stageColors[idx],
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text('${idx + 1}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.getTextColor(context))),
                          ],
                        )),
                        DataCell(Text(
                            CurrencyFormatter.format(amt, currencyCode: 'AUD'),
                            style:
                                TextStyle(color: theme.getTextColor(context)))),
                        DataCell(Text(
                            CurrencyFormatter.format(cumBalance,
                                currencyCode: 'AUD'),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.getTextColor(context)))),
                        DataCell(Text(
                            CurrencyFormatter.format(stageInt,
                                currencyCode: 'AUD'),
                            style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFF15803D),
                                fontWeight: FontWeight.bold))),
                      ],
                    );
                  }).toList(),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Construction Interest',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFFFD700)
                                : const Color(0xFF7C2D12))),
                    Text(
                        CurrencyFormatter.format(totalConstInt,
                            currencyCode: 'AUD'),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFFFD700)
                                : const Color(0xFF7C2D12))),
                  ],
                ),
              ],
            ),
          ),

          // Total Cost Breakdown
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF115E59)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💰 Total Project Cost Breakdown',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 12),
                _buildCostRow('Land Cost',
                    CurrencyFormatter.format(_landValue, currencyCode: 'AUD')),
                _buildCostRow('Build Contract',
                    CurrencyFormatter.format(_totalCost, currencyCode: 'AUD')),
                _buildCostRow(
                    'Construction Interest',
                    CurrencyFormatter.format(totalConstInt,
                        currencyCode: 'AUD')),
                _buildCostRow('Loan Est. Fees', '~\$1,200'),
                _buildCostRow('Building Insurance', '~\$1,500/yr'),
                _buildCostRow('Deposit / Equity',
                    '−${CurrencyFormatter.format(_deposit, currencyCode: 'AUD')}',
                    valColor: const Color(0xFFFCA5A5)),
                const Divider(color: Colors.white24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Project Value',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD700))),
                    Text(
                        CurrencyFormatter.format(
                            _landValue + _totalCost + totalConstInt,
                            currencyCode: 'AUD'),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD700))),
                  ],
                ),
              ],
            ),
          ),

          // Post-build first 10 years stacked bars
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
                Text('📈 Post-Build Amortisation (First 10 Years)',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        weight: FontWeight.w800,
                        color: theme.getTextColor(context))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildLegendItem(
                        isDark
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF002868),
                        'Principal'),
                    const SizedBox(width: 14),
                    _buildLegendItem(const Color(0xFFEF4444), 'Interest'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _StackedBarChartPainter(
                        pts: postBuildPts, isDark: isDark),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Help Tips
        const SizedBox(height: 20),
        Text('Key Tips for Australian Construction Loans',
            style: AppTextStyles.playfair(
                size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 10),
        _buildTipCard('🛡️', 'Home Builder Insurance is Mandatory',
            'All states except QLD, WA and TAS require Domestic Building Insurance (DBI) for work over \$16,000. Your builder must provide evidence before receiving progress payments.'),
        _buildTipCard('📝', 'Fixed-Price Building Contract',
            'Lenders prefer a fixed-price contract with a registered builder. Cost-plus contracts can make it harder to get approved. Get an independent valuation before the slab is poured.'),
        _buildTipCard('📋', 'Council Approvals & HESS',
            'Ensure Development Approval (DA) or a Complying Development Certificate (CDC) is in hand. HESS (HomeStart) in SA or similar state grants may reduce your construction loan amount.'),
        _buildTipCard('💡', 'Interest Only Saves Cash During Build',
            'During the construction phase you only pay interest on drawn funds — not the full loan. This frees up cash while you may be paying rent. Plan your budget around the P&I conversion date.'),
      ],
    );
  }

  String formatAud(double amount) =>
      CurrencyFormatter.format(amount, currencyCode: 'AUD');

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

  Widget _buildStatusBadge(String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (status == 'done') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: isDark ? const Color(0x3334D399) : const Color(0xFFBBF7D0),
            borderRadius: BorderRadius.circular(10)),
        child: Text('✓ Done',
            style: TextStyle(
                fontSize: 8,
                color:
                    isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
                fontWeight: FontWeight.bold)),
      );
    } else if (status == 'active') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: isDark ? const Color(0x33F59E0B) : const Color(0xFFFEF9C3),
            borderRadius: BorderRadius.circular(10)),
        child: Text('⚡ In Progress',
            style: TextStyle(
                fontSize: 8,
                color:
                    isDark ? const Color(0xFFFFD700) : const Color(0xFF92400E),
                fontWeight: FontWeight.bold)),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10)),
        child: Text('⏳ Pending',
            style: TextStyle(
                fontSize: 8,
                color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                fontWeight: FontWeight.bold)),
      );
    }
  }

  Widget _buildProgressStat(String label, String value, {bool isGold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 9, color: Colors.white54)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isGold ? const Color(0xFFFFD700) : Colors.white)),
        ],
      ),
    );
  }

  Widget _buildHeroBox(String label, String val, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 11),
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
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color ?? Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
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

  Widget _buildCostRow(String name, String value, {Color? valColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name,
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: valColor ?? Colors.white)),
        ],
      ),
    );
  }

  Widget _buildTipCard(String icon, String title, String body) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? widget.theme.getCardColor(context) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
            color: isDark
                ? widget.theme.getBorderColor(context)
                : widget.theme.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.playfair(
                        size: 12,
                        weight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 3),
                Text(body,
                    style: AppTextStyles.dmSans(
                        size: 10,
                        color: isDark
                            ? widget.theme.getMutedColor(context)
                            : const Color(0xFF92400E),
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildStage {
  final String name;
  double pct;
  String status;
  final double months;

  _BuildStage({
    required this.name,
    required this.pct,
    required this.status,
    required this.months,
  });
}

class _DrawdownEvent {
  final int mo;
  final double amt;
  final String stageName;
  final int stageIdx;

  _DrawdownEvent({
    required this.mo,
    required this.amt,
    required this.stageName,
    required this.stageIdx,
  });
}

class _DrawdownMonthData {
  final int mo;
  final double drawn;
  final double interest;
  final double remaining;

  _DrawdownMonthData({
    required this.mo,
    required this.drawn,
    required this.interest,
    required this.remaining,
  });
}

class _PostBuildYearData {
  final int year;
  final double principal;
  final double interest;

  _PostBuildYearData({
    required this.year,
    required this.principal,
    required this.interest,
  });
}

class _DrawdownChartPainter extends CustomPainter {
  final List<_DrawdownMonthData> monthlyData;
  final double loanAmt;
  final bool isDark;

  _DrawdownChartPainter(
      {required this.monthlyData, required this.loanAmt, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (monthlyData.isEmpty) return;

    final paintDraw = Paint()
      ..color = isDark ? const Color(0xFF60A5FA) : const Color(0xFF002868)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final paintRem = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final paintInt = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final pathDraw = Path();
    final pathRem = Path();
    final pathInt = Path();

    final maxInt = monthlyData.map((d) => d.interest).reduce(max) * 1.1;
    final dx = size.width / (monthlyData.length - 1);

    for (int i = 0; i < monthlyData.length; i++) {
      final x = i * dx;
      final d = monthlyData[i];

      final yDraw = size.height - (d.drawn / loanAmt * size.height);
      final yRem = size.height - ((loanAmt - d.drawn) / loanAmt * size.height);
      final yInt = maxInt > 0
          ? size.height - (d.interest / maxInt * size.height)
          : size.height;

      if (i == 0) {
        pathDraw.moveTo(x, yDraw);
        pathRem.moveTo(x, yRem);
        pathInt.moveTo(x, yInt);
      } else {
        pathDraw.lineTo(x, yDraw);
        pathRem.lineTo(x, yRem);
        pathInt.lineTo(x, yInt);
      }
    }

    canvas.drawPath(pathDraw, paintDraw);
    canvas.drawPath(pathRem, paintRem);
    canvas.drawPath(pathInt, paintInt);
  }

  @override
  bool shouldRepaint(covariant _DrawdownChartPainter oldDelegate) => true;
}

class _StackedBarChartPainter extends CustomPainter {
  final List<_PostBuildYearData> pts;
  final bool isDark;

  _StackedBarChartPainter({required this.pts, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (pts.isEmpty) return;

    final maxVal = pts.map((p) => p.principal + p.interest).reduce(max);
    if (maxVal == 0) return;

    final gapW = size.width / pts.length;
    final barW = gapW * 0.6;

    final paintP = Paint()
      ..color = isDark ? const Color(0xFF60A5FA) : const Color(0xFF002868)
      ..style = PaintingStyle.fill;

    final paintI = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < pts.length; i++) {
      final p = pts[i];
      final x = i * gapW + (gapW - barW) / 2;

      final hP = p.principal / maxVal * size.height;
      final hI = p.interest / maxVal * size.height;

      final yP = size.height - hP;
      final yI = yP - hI;

      // Draw principal rect
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, yP, barW, hP), const Radius.circular(2)),
        paintP,
      );

      // Draw interest rect
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, yI, barW, hI), const Radius.circular(2)),
        paintI,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StackedBarChartPainter oldDelegate) => true;
}
