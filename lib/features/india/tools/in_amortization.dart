// lib/features/india/tools/in_amortization.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class INAmortization extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INAmortization({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INAmortization> createState() => _INAmortizationState();
}

class _INAmortizationState extends ConsumerState<INAmortization> {
  late TextEditingController _amtController;
  late TextEditingController _rateController;
  late TextEditingController _tenureController;
  DateTime _startMonth = DateTime(2025, 7);
  String _viewMode = 'yearly'; // 'monthly', 'yearly'

  @override
  void initState() {
    super.initState();
    _amtController = TextEditingController(text: '5000000');
    _rateController = TextEditingController(text: '8.50');
    _tenureController = TextEditingController(text: '20');
  }

  @override
  void dispose() {
    _amtController.dispose();
    _rateController.dispose();
    _tenureController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _amtController.text = '5000000';
      _rateController.text = '8.50';
      _tenureController.text = '20';
      _startMonth = DateTime(2025, 7);
      _viewMode = 'yearly';
    });
  }

  double _getAmt() => double.tryParse(_amtController.text) ?? 0.0;
  double _getRate() => double.tryParse(_rateController.text) ?? 0.0;
  int _getTenure() => int.tryParse(_tenureController.text) ?? 0;

  String _fmt(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)} L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }

  String _fmtSh(double n) {
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }

  Future<void> _selectStartMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2060),
      helpText: 'SELECT START MONTH',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      setState(() {
        _startMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  void _saveCalculation() async {
    final p = _getAmt();
    final rateVal = _getRate();
    final tenureVal = _getTenure();
    final r = rateVal / 1200;
    final n = tenureVal * 12;

    if (p <= 0 || rateVal <= 0 || tenureVal <= 0) return;

    final emi = p * r * pow(1 + r, n) / (pow(1 + r, n) - 1);
    final totalPay = emi * n;
    final totalInt = totalPay - p;

    final labelCtrl = TextEditingController(text: 'Amortization Plan');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Schedule', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving: ${_fmt(p)} loan @ ${rateVal.toStringAsFixed(2)}% for $tenureVal yrs',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My House Schedule)',
                hintStyle: AppTextStyles.dmSans(size: 13, color: Colors.grey),
                filled: true,
                fillColor: widget.theme.getBgColor(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTextStyles.dmSans(size: 12, color: Colors.grey, weight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE05F00),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save', style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'Amortization Plan';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'Amortization Schedule',
        inputs: {
          'loanAmt': p,
          'rate': rateVal,
          'termYears': tenureVal.toDouble(),
          'startYear': _startMonth.year.toDouble(),
          'startMonth': _startMonth.month.toDouble(),
        },
        results: {
          'emi': emi,
          'totalInterest': totalInt,
          'totalRepayable': totalPay,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Schedule saved!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF046A38),
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

    final p = _getAmt();
    final rateVal = _getRate();
    final tenureVal = _getTenure();

    final r = rateVal / 1200;
    final totalPeriods = tenureVal * 12;

    double emi = 0;
    double totalRepayable = 0;
    double totalInterest = 0;

    final List<_MonthRow> monthlyRows = [];
    final List<_YearData> yearlyData = [];
    int half50Year = 0;

    if (p > 0 && r > 0 && totalPeriods > 0) {
      emi = p * r * pow(1 + r, totalPeriods) / (pow(1 + r, totalPeriods) - 1);
      totalRepayable = emi * totalPeriods;
      totalInterest = totalRepayable - p;

      double balance = p;
      double yearlyPrincipal = 0;
      double yearlyInterest = 0;
      bool half50Found = false;

      for (int i = 1; i <= totalPeriods; i++) {
        final intCharge = balance * r;
        final princ = emi - intCharge;
        balance = max(0.0, balance - princ);
        yearlyPrincipal += princ;
        yearlyInterest += intCharge;

        monthlyRows.add(_MonthRow(
          period: i,
          principal: princ,
          interest: intCharge,
          balance: balance,
        ));

        if (balance / p <= 0.5 && !half50Found) {
          half50Found = true;
          half50Year = (i / 12).ceil();
        }

        if (i % 12 == 0 || i == totalPeriods) {
          yearlyData.add(_YearData(
            year: (i / 12).ceil(),
            payment: yearlyPrincipal + yearlyInterest,
            principal: yearlyPrincipal,
            interest: yearlyInterest,
            balance: balance,
          ));
          yearlyPrincipal = 0;
          yearlyInterest = 0;
        }
      }
    }

    final intPercent = totalRepayable > 0 ? (totalInterest / totalRepayable * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Info Strip
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.09),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRateStripItem('EMI', _fmtSh(emi), 'Monthly', isFirst: true),
              _buildRateStripItem('Principal', _fmt(p), 'Loan Amt'),
              _buildRateStripItem('Interest', _fmt(totalInterest), 'Total Int'),
              _buildRateStripItem('Tenure', '$tenureVal Yr', '$totalPeriods EMIs'),
            ],
          ),
        ),

        // Section label
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Loan Parameters', style: AppTextStyles.sectionLabel(theme.getMutedColor(context))),
              GestureDetector(
                onTap: _reset,
                child: Text('Reset ↺', style: AppTextStyles.dmSans(size: 11, color: const Color(0xFFE05F00), weight: FontWeight.w700)),
              ),
            ],
          ),
        ),

        // Input Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.getBorderColor(context)),
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
              // Amount & Rate
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Loan Amount (₹)',
                      controller: _amtController,
                      hint: '50,00,000',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      label: 'Interest Rate (%)',
                      controller: _rateController,
                      hint: '8.50',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tenure & Month
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Tenure (Years)',
                      controller: _tenureController,
                      hint: '20',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('START MONTH', style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context), weight: FontWeight.w800)),
                        const SizedBox(height: 5),
                        GestureDetector(
                          onTap: _selectStartMonth,
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: theme.getBgColor(context),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.getBorderColor(context)),
                            ),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('MMM yyyy').format(_startMonth),
                                  style: AppTextStyles.dmSans(size: 13.5, weight: FontWeight.bold, color: theme.getTextColor(context)),
                                ),
                                Icon(Icons.calendar_today, size: 16, color: theme.getMutedColor(context)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Generate Button
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('⚡ Schedule generated!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
                      backgroundColor: const Color(0xFF046A38),
                      duration: const Duration(milliseconds: 600),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                  shadowColor: const Color(0xFFFF6B00).withValues(alpha: 0.4),
                ),
                child: Center(
                  child: Text(
                    '☸ Generate Schedule',
                    style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Summary Boxes Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
            _buildSummaryBox('Monthly EMI', _fmtSh(emi), sub: 'Per Month', highlight: true),
            _buildSummaryBox('Total Payment', _fmt(totalRepayable), sub: 'Principal + Interest'),
            _buildSummaryBox('Total Interest', _fmt(totalInterest), sub: 'Over Tenure'),
            _buildSummaryBox('Interest %', '$intPercent%', sub: 'Of Total Outgo'),
          ],
        ),

        const SizedBox(height: 20),

        // Custom Horizontal Stacked Bar Chart
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.getBorderColor(context)),
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
              Text('📈 Annual Principal vs Interest', style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
              const SizedBox(height: 2),
              Text('Stacked view — how your payment shifts over years', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
              const SizedBox(height: 16),
              
              if (yearlyData.isEmpty)
                const Center(child: Text('No data available'))
              else
                Column(
                  children: yearlyData.take(20).map((yearRow) {
                    final double totalYearPayment = yearRow.principal + yearRow.interest;
                    final double pWidth = totalYearPayment > 0 ? (yearRow.principal / totalYearPayment) : 0.0;
                    final double iWidth = 1.0 - pWidth;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text(
                              'Y${yearRow.year}',
                              style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w800, color: theme.getMutedColor(context)),
                            ),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                height: 16,
                                color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF5E6D4),
                                child: Row(
                                  children: [
                                    if (pWidth > 0)
                                      Expanded(
                                        flex: (pWidth * 100).round(),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Color(0xFFFF6B00), Color(0xFFF5A623)],
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (iWidth > 0)
                                      Expanded(
                                        flex: (iWidth * 100).round(),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Color(0xFF1A3A8F), Color(0xFF4F6FBF)],
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 12),
              Row(
                children: [
                  _buildLegendDot('Principal', const Color(0xFFFF6B00)),
                  const SizedBox(width: 14),
                  _buildLegendDot('Interest', const Color(0xFF1A3A8F)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Timeline Milestones
        if (half50Year > 0) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Key Milestones', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w700, color: theme.getTextColor(context))),
                const SizedBox(height: 8),
                _buildMilestoneRow('🏁', '50% Balance Cleared', 'When you owe half of original loan', 'Yr $half50Year'),
                _buildMilestoneRow('🎉', 'Loan Free', 'Final EMI payment', 'Yr $tenureVal'),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Monthly / Yearly Schedule
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Schedule Table', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
            Row(
              children: [
                _buildTab('Yearly', _viewMode == 'yearly', () => setState(() => _viewMode = 'yearly')),
                const SizedBox(width: 6),
                _buildTab('Monthly', _viewMode == 'monthly', () => setState(() => _viewMode = 'monthly')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Table Wrapper
        Container(
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        _viewMode == 'monthly' ? 'EMI#' : 'Year',
                        style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: Colors.white70),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Principal',
                        style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: Colors.white70),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Interest',
                        style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: Colors.white70),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Balance',
                        style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: Colors.white70),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),

              // Table Body
              SizedBox(
                height: 320,
                child: _viewMode == 'monthly'
                    ? ListView.builder(
                        itemCount: monthlyRows.length,
                        itemBuilder: (context, index) {
                          final row = monthlyRows[index];
                          final isYearEnd = row.period % 12 == 0;
                          final dateStr = _getMonthStr(row.period);

                          return _buildTableRow(
                            label: '$dateStr (${row.period})',
                            principal: _fmtSh(row.principal),
                            interest: _fmtSh(row.interest),
                            balance: _fmtSh(row.balance),
                            highlight: isYearEnd,
                          );
                        },
                      )
                    : ListView.builder(
                        itemCount: yearlyData.length,
                        itemBuilder: (context, index) {
                          final row = yearlyData[index];
                          return _buildTableRow(
                            label: 'Yr ${row.year}',
                            principal: _fmtSh(row.principal),
                            interest: _fmtSh(row.interest),
                            balance: _fmtSh(row.balance),
                            highlight: true,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Save bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF064E3B), const Color(0xFF047857)]
                  : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isDark ? const Color(0xFF065F46) : const Color(0xFF6EE7B7),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Row(
            children: [
              const Text('💾', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Save Amortization Schedule',
                      style: AppTextStyles.dmSans(
                        size: 12,
                        weight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF07543A),
                      ),
                    ),
                    Text(
                      'Save full schedule details for reference',
                      style: AppTextStyles.dmSans(
                        size: 9.5,
                        color: isDark ? Colors.white70 : const Color(0xFF046A38),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _saveCalculation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF046A38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text('Save', style: AppTextStyles.dmSans(size: 10, color: Colors.white, weight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Widget Builders ---

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context), weight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 44,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.dmSans(size: 13.5, weight: FontWeight.bold, color: theme.getTextColor(context)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13.5),
              filled: true,
              fillColor: theme.getBgColor(context),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.getBorderColor(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.primaryColor),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryBox(String label, String value, {required String sub, bool highlight = false}) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final boxBg = highlight
        ? const LinearGradient(
            colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    final bgColor = highlight ? null : theme.getCardColor(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        gradient: boxBg,
        borderRadius: BorderRadius.circular(16),
        border: highlight ? null : Border.all(color: theme.getBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.dmSans(
              size: 8.5,
              color: highlight ? Colors.white54 : theme.getMutedColor(context),
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.playfair(
              size: 15,
              weight: FontWeight.w800,
              color: highlight ? const Color(0xFFFFDEA0) : theme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: AppTextStyles.dmSans(
              size: 8.5,
              color: highlight ? Colors.white38 : theme.getMutedColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: widget.theme.getTextColor(context)),
        ),
      ],
    );
  }

  Widget _buildMilestoneRow(String emoji, String title, String sub, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: widget.theme.getBgColor(context),
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
                Text(title, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: widget.theme.getTextColor(context))),
                Text(sub, style: AppTextStyles.dmSans(size: 10, color: widget.theme.getMutedColor(context))),
              ],
            ),
          ),
          Text(val, style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: const Color(0xFFE05F00))),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFF6B00) : Colors.transparent,
          border: Border.all(color: active ? const Color(0xFFFF6B00) : widget.theme.getBorderColor(context)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 9.5,
            weight: FontWeight.w700,
            color: active ? Colors.white : widget.theme.getMutedColor(context),
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow({
    required String label,
    required String principal,
    required String interest,
    required String balance,
    bool highlight = false,
  }) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
      decoration: BoxDecoration(
        color: highlight ? const Color(0x05FF6B00) : Colors.transparent,
        border: Border(bottom: BorderSide(color: theme.getBorderColor(context), width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: theme.getMutedColor(context)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              principal,
              style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: const Color(0xFF046A38)),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              interest,
              style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: const Color(0xFFE05F00)),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              balance,
              style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w700, color: theme.getTextColor(context)),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateStripItem(String label, String value, String subtitle, {bool isFirst = false}) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: isFirst
              ? null
              : const Border(
                  left: BorderSide(color: Colors.white12, width: 1.0),
                ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.dmSans(
                size: 8,
                color: Colors.white60,
                weight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTextStyles.dmSans(
                size: 13,
                color: const Color(0xFFFFDEA0),
                weight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.dmSans(
                size: 8,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthStr(int periodIndex) {
    final date = DateTime(_startMonth.year, _startMonth.month + periodIndex - 1);
    return DateFormat('MMM yy').format(date);
  }
}

class _MonthRow {
  final int period;
  final double principal;
  final double interest;
  final double balance;

  _MonthRow({
    required this.period,
    required this.principal,
    required this.interest,
    required this.balance,
  });
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
