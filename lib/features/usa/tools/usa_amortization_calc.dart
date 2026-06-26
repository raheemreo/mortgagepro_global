// lib/features/usa/tools/usa_amortization_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/mortgage_math.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class USAAmortizationCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const USAAmortizationCalc({super.key, this.theme = CountryThemes.usa});

  @override
  ConsumerState<USAAmortizationCalc> createState() => _USAAmortizationCalcState();
}

class _USAAmortizationCalcState extends ConsumerState<USAAmortizationCalc> {
  // Input Controllers
  final _homePriceController = TextEditingController(text: '450000');
  final _downPmtController = TextEditingController(text: '90000');
  final _rateController = TextEditingController(text: '6.82');
  final _extraPmtController = TextEditingController(text: '0');

  int _termYears = 30;
  int _selectedYear = 1;
  int _displayMonthsCount = 12;

  @override
  void dispose() {
    _homePriceController.dispose();
    _downPmtController.dispose();
    _rateController.dispose();
    _extraPmtController.dispose();
    super.dispose();
  }

  double _val(TextEditingController c) => double.tryParse(c.text) ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Inputs
    final price = _val(_homePriceController);
    final down = _val(_downPmtController);
    final rate = _val(_rateController);
    final extra = _val(_extraPmtController);
    final loanAmt = max(0.0, price - down);

    // Calculate base monthly P&I
    final basePayment = MortgageMath.monthlyPayment(
      principal: loanAmt,
      annualRatePercent: rate,
      termYears: _termYears,
    );

    // Build schedule
    final schedule = <_AmortRow>[];
    double balance = loanAmt;
    final r = rate / 100 / 12;
    final totalPayment = basePayment + extra;
    final n = _termYears * 12;
    final startDate = DateTime(2025, 6, 1);

    for (int month = 1; month <= n; month++) {
      if (balance <= 0.01) break;
      final interestCharge = balance * r;
      final principalCharge = min(totalPayment - interestCharge, balance);
      balance -= principalCharge;
      if (balance < 0.01) balance = 0.0;

      final date = DateTime(startDate.year, startDate.month + month - 1, 1);
      schedule.add(_AmortRow(
        month: month,
        year: ((month - 1) ~/ 12) + 1,
        payment: interestCharge + principalCharge,
        principal: principalCharge,
        interest: interestCharge,
        balance: balance,
        date: date,
      ));
    }

    final totalPaid = schedule.fold(0.0, (sum, row) => sum + row.payment);
    final totalInterest = max(0.0, totalPaid - loanAmt);

    final payoffDate = schedule.isNotEmpty ? schedule.last.date : DateTime.now();
    final payoffMonthYear = '${_getMonthNameAbbr(payoffDate.month)} ${payoffDate.year}';

    // Composition percentages
    final pPct = totalPaid > 0 ? (loanAmt / totalPaid * 100).round() : 0;
    final iPct = totalPaid > 0 ? (totalInterest / totalPaid * 100).round() : 0;

    // Cap selected year by the actual length of the schedule
    final totalYearsInSchedule = schedule.isNotEmpty ? (schedule.length / 12.0).ceil() : 0;
    final activeSelectedYear = min(_selectedYear, max(1, totalYearsInSchedule));

    // Filter year rows
    final yearRows = schedule.where((row) => row.year == activeSelectedYear).toList();
    final visibleRows = yearRows.take(_displayMonthsCount).toList();

    // Saved calculations watch
    final savedCalcs = ref.watch(savedProvider).where((c) => c.country == 'USA' && c.calcType == 'Amortization Calculator').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip
        Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F4FF),
            border: Border.all(color: isDark ? Colors.white10 : const Color(0x1B1B3F72)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(child: _buildRsCell('30-Yr Fixed', '6.82%', 'Freddie Mac', isUp: true)),
              _buildRsDivider(),
              Expanded(child: _buildRsCell('15-Yr Fixed', '6.11%', 'Avg')),
              _buildRsDivider(),
              Expanded(child: _buildRsCell('5/1 ARM', '6.05%', 'Avg', isDown: true)),
              _buildRsDivider(),
              Expanded(child: _buildRsCell('Fed Funds', '5.33%', 'FOMC', isGold: true)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _buildSectionHeader('Monthly Payment Summary', onReset: _resetInputs),
        const SizedBox(height: 8),

        // Summary Hero
        Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
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
                'ESTIMATED MONTHLY P&I PAYMENT',
                style: AppTextStyles.dmSans(
                  size: 9.5,
                  weight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.48),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                CurrencyFormatter.format(basePayment, symbol: '\$').split('.').first,
                style: AppTextStyles.dmSans(
                  size: 46,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ).copyWith(fontFamily: 'Georgia'),
              ),
              const SizedBox(height: 4),
              Text(
                '${CurrencyFormatter.format(loanAmt, symbol: '\$').split('.').first} loan · ${rate.toStringAsFixed(2)}% · $_termYears years · Payoff: $payoffMonthYear',
                style: AppTextStyles.dmSans(
                  size: 11,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 12),

              // Stats row
              Row(
                children: [
                  Expanded(
                    child: _buildHeroStat('Total Paid', CurrencyFormatter.format(totalPaid, symbol: '\$').split('.').first, null),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildHeroStat('Total Interest', CurrencyFormatter.format(totalInterest, symbol: '\$').split('.').first, const Color(0xFFFCA5A5)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildHeroStat('Loan Amount', CurrencyFormatter.format(loanAmt, symbol: '\$').split('.').first, const Color(0xFFFCD34D)),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _buildSectionHeader('Loan Details', onReset: null),
        const SizedBox(height: 8),

        // Parameters Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.getBorderColor(context)),
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
                  const Text('🏠 ', style: TextStyle(fontSize: 16)),
                  Text(
                    'Mortgage Parameters',
                    style: AppTextStyles.dmSans(
                      size: 12.5,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context),
                    ).copyWith(fontFamily: 'Georgia'),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Home Price & Down Payment Row
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      label: 'Home Price',
                      controller: _homePriceController,
                      hint: 'US median: \$412,000 (2025)',
                      prefix: '\$',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInputField(
                      label: 'Down Payment',
                      controller: _downPmtController,
                      hint: '20% = no PMI',
                      prefix: '\$',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Rate & Term Row
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      label: 'Interest Rate',
                      controller: _rateController,
                      hint: '30-yr avg: 6.82%',
                      suffix: '%',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Loan Term'.toUpperCase(),
                          style: AppTextStyles.dmSans(
                            size: 9.5,
                            weight: FontWeight.w700,
                            color: theme.getMutedColor(context),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.getBgColor(context),
                            border: Border.all(color: theme.getBorderColor(context), width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _termYears,
                              dropdownColor: theme.getCardColor(context),
                              items: const [
                                DropdownMenuItem(value: 30, child: Text('30 Years')),
                                DropdownMenuItem(value: 20, child: Text('20 Years')),
                                DropdownMenuItem(value: 15, child: Text('15 Years')),
                                DropdownMenuItem(value: 10, child: Text('10 Years')),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _termYears = v;
                                    _selectedYear = 1;
                                  });
                                }
                              },
                              style: AppTextStyles.dmSans(
                                size: 14,
                                weight: FontWeight.w700,
                                color: theme.getTextColor(context),
                              ),
                              isExpanded: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '30-yr most common',
                          style: AppTextStyles.dmSans(
                            size: 8.5,
                            weight: FontWeight.w500,
                            color: theme.getMutedColor(context).withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Extra payment
              _buildInputField(
                label: 'Extra Monthly Payment (Optional)',
                controller: _extraPmtController,
                hint: '\$100/mo extra saves ~\$30K interest on a 30-yr \$360K loan',
                prefix: '\$',
                suffix: '/mo',
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Generate Amortization Schedule Button (Red Gradient)
        GestureDetector(
          onTap: () => setState(() {}),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB91C1C), Color(0xFF991B1B)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB91C1C).withValues(alpha: 0.40),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📅', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  'Generate Amortization Schedule',
                  style: AppTextStyles.dmSans(
                    size: 14,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ).copyWith(fontFamily: 'Georgia'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Save Button (Green)
        _buildSaveButton(_saveCalculation),

        const SizedBox(height: 20),
        _buildSectionHeader('Principal vs Interest Breakdown', onReset: null),
        const SizedBox(height: 8),

        // Visual Breakdown Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.getBorderColor(context)),
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
              Text(
                'Where Your Money Goes Over Loan Life',
                style: AppTextStyles.dmSans(
                  size: 12.5,
                  weight: FontWeight.w800,
                  color: theme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 12),

              // Stacked Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 18,
                  width: double.infinity,
                  child: Row(
                    children: [
                      if (pPct > 0)
                        Expanded(
                          flex: pPct,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [Color(0xFF1B3F72), Color(0xFF0B1D3A)]),
                            ),
                          ),
                        ),
                      if (iPct > 0)
                        Expanded(
                          flex: iPct,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [Color(0xFFB91C1C), Color(0xFF991B1B)]),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Stacked legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStackedLegendItem('Principal', pPct, const Color(0xFF1B3F72)),
                  const SizedBox(width: 14),
                  _buildStackedLegendItem('Interest', iPct, const Color(0xFFB91C1C)),
                ],
              ),
              const SizedBox(height: 14),

              // Donut Payoff Ring Row
              Row(
                children: [
                  CustomPaint(
                    size: const Size(92, 92),
                    painter: _AmortizationDonutPainter(
                      principalPct: pPct / 100.0,
                      interestPct: iPct / 100.0,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildDonutLegendRow(
                          color: const Color(0xFF1B3F72),
                          label: 'Total Principal',
                          value: CurrencyFormatter.format(loanAmt, symbol: '\$').split('.').first,
                        ),
                        const SizedBox(height: 8),
                        _buildDonutLegendRow(
                          color: const Color(0xFFB91C1C),
                          label: 'Total Interest',
                          value: CurrencyFormatter.format(totalInterest, symbol: '\$').split('.').first,
                        ),
                        const SizedBox(height: 8),
                        _buildDonutLegendRow(
                          color: const Color(0xFFD97706),
                          label: 'Total Paid',
                          value: CurrencyFormatter.format(totalPaid, symbol: '\$').split('.').first,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Progress bars list below
              _buildProgressRow('Loan Principal', loanAmt, pPct, const Color(0xFF1B3F72)),
              const SizedBox(height: 8),
              _buildProgressRow('Total Interest', totalInterest, iPct, const Color(0xFFB91C1C)),
              const SizedBox(height: 8),
              _buildProgressRow('Total Cost', totalPaid, 100, const Color(0xFFD97706)),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _buildSectionHeader('Yearly Summary', onReset: null),
        const SizedBox(height: 8),

        // Year Tabs
        if (totalYearsInSchedule > 0)
          SizedBox(
            height: 34,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: totalYearsInSchedule,
              itemBuilder: (context, idx) {
                final y = idx + 1;
                final isActive = y == activeSelectedYear;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedYear = y;
                        _displayMonthsCount = 12;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF1B3F72) : theme.getCardColor(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive ? const Color(0xFF1B3F72) : theme.getBorderColor(context),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Yr $y',
                        style: AppTextStyles.dmSans(
                          size: 10.5,
                          weight: FontWeight.w700,
                          color: isActive ? Colors.white : theme.getMutedColor(context),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 10),

        // Table Card
        Container(
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)]),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                child: Row(
                  children: [
                    _th('Month', alignment: Alignment.centerLeft, flex: 3),
                    _th('Payment'),
                    _th('Principal'),
                    _th('Interest'),
                    _th('Balance', flex: 4),
                  ],
                ),
              ),

              // Rows list
              if (visibleRows.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No entries for this year',
                      style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context)),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visibleRows.length,
                  itemBuilder: (context, idx) {
                    final row = visibleRows[idx];
                    final moName = '${_getMonthNameAbbr(row.date.month)} ${row.date.year.toString().substring(2)}';
                    return Container(
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: theme.getBorderColor(context), width: 0.5)),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              moName,
                              style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: theme.getTextColor(context)),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: _td(CurrencyFormatter.format(row.payment, symbol: '').split('.').first),
                          ),
                          Expanded(
                            flex: 3,
                            child: _td(CurrencyFormatter.format(row.principal, symbol: '').split('.').first, color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1B3F72)),
                          ),
                          Expanded(
                            flex: 3,
                            child: _td(CurrencyFormatter.format(row.interest, symbol: '').split('.').first, color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C)),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              CurrencyFormatter.format(row.balance, symbol: '\$').split('.').first,
                              textAlign: TextAlign.right,
                              style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: theme.getTextColor(context)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              // Show More Button
              if (yearRows.length > _displayMonthsCount)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _displayMonthsCount += 12;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: theme.getBgColor(context),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Show More Months ↓',
                      style: AppTextStyles.dmSans(
                        size: 12,
                        weight: FontWeight.w700,
                        color: const Color(0xFF1E4FBF),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Saved Calculations panel at bottom
        const SizedBox(height: 20),
        _buildSectionHeader('Saved Schedules', onReset: null),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.07),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: savedCalcs.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      'No saved schedules yet. Tap "Save This Schedule" above to bookmark a loan scenario.',
                      style: AppTextStyles.dmSans(
                        size: 11,
                        color: theme.getMutedColor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: savedCalcs.map((calc) {
                    final isLast = savedCalcs.indexOf(calc) == savedCalcs.length - 1;
                    final priceVal = calc.inputs['Price'] ?? 0.0;
                    final downVal = calc.inputs['DownPmt'] ?? 0.0;
                    final loanAmtVal = priceVal - downVal;
                    final rateVal = calc.inputs['Rate'] ?? 0.0;
                    final termVal = calc.inputs['Term'] ?? 30.0;
                    final extraVal = calc.inputs['ExtraPmt'] ?? 0.0;
                    final piVal = calc.results['MonthlyPI'] ?? 0.0;

                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isLast
                                ? Colors.transparent
                                : theme.getBorderColor(context).withValues(alpha: 0.5),
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
                                    '${CurrencyFormatter.compact(piVal, symbol: '\$')}/mo · ${rateVal.toStringAsFixed(2)}% · ${termVal.toStringAsFixed(0)}yr',
                                    style: AppTextStyles.dmSans(
                                      size: 12,
                                      weight: FontWeight.w800,
                                      color: theme.getTextColor(context),
                                    ).copyWith(fontFamily: 'Georgia'),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Loan ${CurrencyFormatter.compact(loanAmtVal, symbol: '\$')} · Down ${CurrencyFormatter.compact(downVal, symbol: '\$')}${extraVal > 0 ? ' · Extra ${CurrencyFormatter.compact(extraVal, symbol: '\$')}/mo' : ''}',
                                    style: AppTextStyles.dmSans(
                                      size: 9.5,
                                      color: theme.getMutedColor(context),
                                    ),
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
                                  SnackBar(
                                    content: Text('Removed saved schedule', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
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
      ],
    );
  }

  Widget _buildRsCell(String label, String value, String note, {bool isGold = false, bool isUp = false, bool isDown = false}) {
    final textColor = isGold ? const Color(0xFFFCD34D) : Colors.white;
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8.5,
            color: Colors.white.withValues(alpha: 0.48),
            weight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: AppTextStyles.dmSans(
                size: 15,
                weight: FontWeight.w800,
                color: textColor,
              ).copyWith(fontFamily: 'Georgia'),
            ),
            if (isUp)
              const Text('↑', style: TextStyle(fontSize: 10, color: Color(0xFF6EE7B7))),
            if (isDown)
              const Text('↓', style: TextStyle(fontSize: 10, color: Color(0xFFFCA5A5))),
          ],
        ),
        Text(
          note,
          style: AppTextStyles.dmSans(
            size: 8,
            color: Colors.white.withValues(alpha: 0.38),
          ),
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

  Widget _buildHeroStat(String label, String value, Color? valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.dmSans(
              size: 8,
              weight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.45),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.dmSans(
              size: 14,
              weight: FontWeight.w800,
              color: valueColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    String? prefix,
    String? suffix,
  }) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 9.5,
            weight: FontWeight.w700,
            color: theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            border: Border.all(color: theme.getBorderColor(context), width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              if (prefix != null)
                Padding(
                  padding: const EdgeInsets.only(left: 13, right: 10),
                  child: Text(
                    prefix,
                    style: AppTextStyles.dmSans(
                      size: 14,
                      weight: FontWeight.w800,
                      color: theme.getMutedColor(context),
                    ),
                  ),
                ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTextStyles.dmSans(
                    size: 14,
                    weight: FontWeight.w700,
                    color: theme.getTextColor(context),
                  ).copyWith(fontFamily: 'Georgia'),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.only(right: 13, left: 10),
                  child: Text(
                    suffix,
                    style: AppTextStyles.dmSans(
                      size: 12,
                      weight: FontWeight.w700,
                      color: theme.getMutedColor(context),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (hint.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            hint,
            style: AppTextStyles.dmSans(
              size: 8.5,
              weight: FontWeight.w500,
              color: theme.getMutedColor(context).withValues(alpha: 0.75),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStackedLegendItem(String label, int pct, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = color;
    if (isDark) {
      if (color == const Color(0xFF1B3F72)) {
        textColor = const Color(0xFF93C5FD);
      } else if (color == const Color(0xFFB91C1C)) {
        textColor = const Color(0xFFFCA5A5);
      }
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label $pct%',
          style: AppTextStyles.dmSans(
            size: 9.5,
            weight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressRow(String label, double val, int pct, Color color) {
    final theme = widget.theme;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.w600,
                  color: theme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 2),
              Stack(
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.getBgColor(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final maxW = constraints.maxWidth;
                      final fillW = maxW * (pct / 100.0);
                      return Container(
                        height: 8,
                        width: fillW,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          CurrencyFormatter.format(val, symbol: '\$').split('.').first,
          style: AppTextStyles.dmSans(
            size: 12,
            weight: FontWeight.w800,
            color: theme.getTextColor(context),
          ).copyWith(fontFamily: 'Georgia'),
        ),
      ],
    );
  }

  Widget _th(String label, {Alignment alignment = Alignment.centerRight, int flex = 3}) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: alignment,
        child: Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 9,
            weight: FontWeight.w800,
            color: Colors.white70,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  Widget _td(String text, {Color? color}) {
    return Container(
      alignment: Alignment.centerRight,
      child: Text(
        text,
        style: AppTextStyles.dmSans(
          size: 11,
          weight: FontWeight.w700,
          color: color ?? widget.theme.getMutedColor(context),
        ),
      ),
    );
  }

  String _getMonthNameAbbr(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onReset}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 10.5,
            weight: FontWeight.w800,
            color: widget.theme.getMutedColor(context),
            letterSpacing: 1,
          ),
        ),
        if (onReset != null)
          GestureDetector(
            onTap: onReset,
            child: Text(
              'Reset →',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF93C5FD)
                    : const Color(0xFF1E4FBF),
              ),
            ),
          ),
      ],
    );
  }

  void _saveCalculation() async {
    final price = _val(_homePriceController);
    final down = _val(_downPmtController);
    final rate = _val(_rateController);
    final extra = _val(_extraPmtController);
    final loanAmt = max(0.0, price - down);

    final basePayment = MortgageMath.monthlyPayment(
      principal: loanAmt,
      annualRatePercent: rate,
      termYears: _termYears,
    );

    // Recompute totalPaid/totalInterest
    double balance = loanAmt;
    final r = rate / 100 / 12;
    final totalPayment = basePayment + extra;
    final n = _termYears * 12;
    double computedTotalPaid = 0.0;
    for (int month = 1; month <= n; month++) {
      if (balance <= 0.01) break;
      final interestCharge = balance * r;
      final principalCharge = min(totalPayment - interestCharge, balance);
      balance -= principalCharge;
      computedTotalPaid += interestCharge + principalCharge;
    }
    final computedTotalInterest = max(0.0, computedTotalPaid - loanAmt);

    final labelCtrl = TextEditingController(text: 'Amortization Schedule');
    final confirmed = await showDialog<bool>(
      context: context,
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
              'Saving: P&I ${CurrencyFormatter.compact(basePayment, symbol: '\$')} · Loan: ${CurrencyFormatter.compact(loanAmt, symbol: '\$')} · Rate: ${rate.toStringAsFixed(2)}%',
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
                hintText: 'Label (e.g. My Amortization Calc)',
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
          : 'Amortization Schedule';
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'Amortization Calculator',
        inputs: {
          'Price': price,
          'DownPmt': down,
          'Rate': rate,
          'Term': _termYears.toDouble(),
          'ExtraPmt': extra,
        },
        results: {
          'MonthlyPI': basePayment,
          'TotalPaid': computedTotalPaid,
          'TotalInterest': computedTotalInterest,
          'LoanAmount': loanAmt,
        },
        label: label,
        currencyCode: 'USD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Calculation saved successfully!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: widget.theme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _loadSavedCalculation(SavedCalc calc) {
    setState(() {
      _homePriceController.text = (calc.inputs['Price'] ?? 450000.0).toStringAsFixed(0);
      _downPmtController.text = (calc.inputs['DownPmt'] ?? 90000.0).toStringAsFixed(0);
      _rateController.text = (calc.inputs['Rate'] ?? 6.82).toStringAsFixed(2);
      _extraPmtController.text = (calc.inputs['ExtraPmt'] ?? 0.0).toStringAsFixed(0);
      _termYears = (calc.inputs['Term'] ?? 30.0).round();
      _selectedYear = 1;
      _displayMonthsCount = 12;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded saved schedule!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
        backgroundColor: widget.theme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildDonutLegendRow({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700, color: widget.theme.getTextColor(context)),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: widget.theme.getTextColor(context)),
        ),
      ],
    );
  }

  Widget _buildSaveButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF15803D), Color(0xFF166534)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF15803D).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔖', style: TextStyle(fontSize: 15)),
            const SizedBox(width: 8),
            Text(
              'Save This Schedule',
              style: AppTextStyles.dmSans(
                size: 13,
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetInputs() {
    setState(() {
      _homePriceController.text = '450000';
      _downPmtController.text = '90000';
      _rateController.text = '6.82';
      _extraPmtController.text = '0';
      _termYears = 30;
      _selectedYear = 1;
      _displayMonthsCount = 12;
    });
  }
}

class _AmortRow {
  final int month;
  final int year;
  final double payment;
  final double principal;
  final double interest;
  final double balance;
  final DateTime date;

  const _AmortRow({
    required this.month,
    required this.year,
    required this.payment,
    required this.principal,
    required this.interest,
    required this.balance,
    required this.date,
  });
}

class _AmortizationDonutPainter extends CustomPainter {
  final double principalPct;
  final double interestPct;
  final bool isDark;

  _AmortizationDonutPainter({
    required this.principalPct,
    required this.interestPct,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const strokeWidth = 13.0;

    final paintBg = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F4FF)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, paintBg);

    final total = principalPct + interestPct;
    if (total <= 0) return;

    double startAngle = -pi / 2;

    if (principalPct > 0) {
      final sweep = 2 * pi * principalPct;
      final paintPrincipal = Paint()
        ..color = const Color(0xFF1B3F72)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, sweep, false, paintPrincipal);
      startAngle += sweep;
    }

    if (interestPct > 0) {
      final sweep = 2 * pi * interestPct;
      final paintInterest = Paint()
        ..color = const Color(0xFFB91C1C)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, sweep, false, paintInterest);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


