// lib/features/india/tools/in_epf_calculator.dart

import 'package:flutter/material.dart';
import 'dart:math' show max, min, pi;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../core/utils/compat.dart';

class INEPFCalculator extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INEPFCalculator({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INEPFCalculator> createState() => _INEPFCalculatorState();
}

class _INEPFCalculatorState extends ConsumerState<INEPFCalculator> {
  // Input states
  double _basicSalary = 35000;
  double _existingBalance = 250000;
  int _yearsToRetirement = 25;
  double _salaryIncrement = 5.0; // 0, 5, 8, 10
  double _roi = 8.25; // default EPFO rate

  // Controllers
  late TextEditingController _basicSalaryCtrl;
  late TextEditingController _existingBalanceCtrl;
  late TextEditingController _yearsCtrl;
  late TextEditingController _roiCtrl;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _basicSalaryCtrl =
        TextEditingController(text: _basicSalary.toStringAsFixed(0));
    _existingBalanceCtrl =
        TextEditingController(text: _existingBalance.toStringAsFixed(0));
    _yearsCtrl =
        TextEditingController(text: _yearsToRetirement.toStringAsFixed(0));
    _roiCtrl = TextEditingController(text: _roi.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _basicSalaryCtrl.dispose();
    _existingBalanceCtrl.dispose();
    _yearsCtrl.dispose();
    _roiCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _basicSalary = 35000;
      _existingBalance = 250000;
      _yearsToRetirement = 25;
      _salaryIncrement = 5.0;
      _roi = 8.25;

      _basicSalaryCtrl.text = '35000';
      _existingBalanceCtrl.text = '250000';
      _yearsCtrl.text = '25';
      _roiCtrl.text = '8.25';
    });
  }

  String _fmt(double n) {
    return '₹${Compat.round(n).toLocaleString()}';
  }

  String _fmtShort(double n) {
    if (n >= 10000000) return '${(n / 10000000).toStringAsFixed(1)}Cr';
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    return Compat.round(n).toLocaleString();
  }

  Map<String, dynamic> _calculateValues() {
    double corpus = _existingBalance;
    double empTotal = 0;
    double emplrTotal = 0;
    double intTotal = 0;
    final r = _roi / 100 / 12;

    final List<Map<String, dynamic>> yearData = [];
    double curBasic = _basicSalary;

    for (int y = 1; y <= _yearsToRetirement; y++) {
      double yearEmp = 0;
      double yearEmpr = 0;
      double yearInt = 0;
      for (int m = 0; m < 12; m++) {
        final empM = curBasic * 0.12;
        final emprM = curBasic * 0.0367;
        final intM = corpus * r;
        corpus += empM + emprM + intM;
        yearEmp += empM;
        yearEmpr += emprM;
        yearInt += intM;
      }
      empTotal += yearEmp;
      emplrTotal += yearEmpr;
      intTotal += yearInt;

      yearData.add({
        'y': y,
        'yearEmp': yearEmp,
        'yearEmpr': yearEmpr,
        'yearInt': yearInt,
        'corpus': corpus
      });

      if (_salaryIncrement > 0) curBasic *= (1 + _salaryIncrement / 100);
    }

    return {
      'corpus': corpus,
      'empTotal': empTotal,
      'emplrTotal': emplrTotal,
      'intTotal': intTotal,
      'yearData': yearData,
    };
  }

  void _saveCalculation(double corpus, double empTotal, double emplrTotal,
      double intTotal) async {
    final labelCtrl = TextEditingController(text: 'EPF Calculator');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save EPF Calculation',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Saving: Maturity ${_fmt(corpus)} · Basic ${_fmt(_basicSalary)}',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My EPF Retirement)',
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
              backgroundColor: const Color(0xFF046A38),
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
          : 'EPF Calculator';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'EPF Calculator',
        inputs: {
          'basicSalary': _basicSalary,
          'existingBalance': _existingBalance,
          'years': _yearsToRetirement.toDouble(),
          'increment': _salaryIncrement,
          'rate': _roi,
        },
        results: {
          'corpus': corpus,
          'employeeTotal': empTotal,
          'employerTotal': emplrTotal,
          'interestTotal': intTotal,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Calculation saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: const Color(0xFF046A38),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _scrollToResults() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _resultsKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(context,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final results = _calculateValues();
    final corpus = results['corpus'] as double;
    final empTotal = results['empTotal'] as double;
    final emplrTotal = results['emplrTotal'] as double;
    final intTotal = results['intTotal'] as double;
    final double monthlyCont =
        _basicSalary * 0.24; // Employee (12%) + Employer (12%)
    final List<Map<String, dynamic>> yearData =
        results['yearData'] as List<Map<String, dynamic>>;

    // Filter projection data: Year 1, every 5th year, and last year
    final List<Map<String, dynamic>> projectionRows = [];
    for (int i = 0; i < yearData.length; i++) {
      final y = i + 1;
      if (y == 1 || y % 5 == 0 || y == _yearsToRetirement) {
        projectionRows.add(yearData[i]);
      }
    }
    final Set<int> added = {};
    final List<Map<String, dynamic>> uniqueRows = [];
    for (final r in projectionRows) {
      if (!added.contains(r['y'])) {
        added.add(r['y']);
        uniqueRows.add(r);
      }
    }

    final maxChartVal = uniqueRows.isNotEmpty
        ? uniqueRows.map((d) => d['corpus'] as double).reduce(max)
        : 1.0;

    // Retrieve saved calculations matching EPF
    final savedList = ref
        .watch(savedProvider)
        .where((c) => c.calcType == 'EPF Calculator')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Rate Strip Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1F48).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Row(
            children: [
              _headerRateItem('EPF Rate', '${_roi.toStringAsFixed(2)}%',
                  'FY 25–26', context),
              _verticalDivider(),
              _headerRateItem('Employer', '12%', 'Of Basic', context),
              _verticalDivider(),
              _headerRateItem('Employee', '12%', 'Of Basic', context,
                  isGreen: true),
              _verticalDivider(),
              _headerRateItem('EPS Share', '8.33%', 'Pension', context),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Inputs Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                blurRadius: 20,
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
                  Text('INPUT DETAILS',
                      style: AppTextStyles.dmSans(
                          size: 9.5,
                          color: theme.getMutedColor(context),
                          weight: FontWeight.w800,
                          letterSpacing: 0.5)),
                  GestureDetector(
                    onTap: _reset,
                    child: Text('Reset ↺',
                        style: AppTextStyles.dmSans(
                            size: 11,
                            color: const Color(0xFFFF6B00),
                            weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Synced input-slider 1: Monthly Basic Salary + DA
              _buildSyncedInputRow(
                label: 'BASIC SALARY + DA (MONTHLY)',
                controller: _basicSalaryCtrl,
                value: _basicSalary,
                min: 1000,
                max: 200000,
                prefix: '₹ ',
                onChangedText: (val) {
                  setState(() {
                    _basicSalary = val;
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _basicSalary = val;
                    _basicSalaryCtrl.text = val.toStringAsFixed(0);
                  });
                },
              ),
              const SizedBox(height: 12),

              // Input 2: Current EPF Balance
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CURRENT EPF BALANCE',
                      style: AppTextStyles.dmSans(
                          size: 8.5,
                          color: theme.getMutedColor(context),
                          weight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.04),
                      border: Border.all(
                          color:
                              const Color(0xFFFF6B00).withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: TextFormField(
                      controller: _existingBalanceCtrl,
                      keyboardType: TextInputType.number,
                      style: AppTextStyles.dmSans(
                          size: 13,
                          color: theme.getTextColor(context),
                          weight: FontWeight.w800),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        prefixText: '₹ ',
                      ),
                      onChanged: (v) {
                        final parsed = double.tryParse(v);
                        if (parsed != null && parsed >= 0) {
                          setState(() {
                            _existingBalance = parsed;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Synced input-slider 3: Years to Retirement
              _buildSyncedInputRow(
                label: 'YEARS TO RETIREMENT',
                controller: _yearsCtrl,
                value: _yearsToRetirement.toDouble(),
                min: 1,
                max: 40,
                suffix: ' Years',
                onChangedText: (val) {
                  setState(() {
                    _yearsToRetirement = val.toInt();
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _yearsToRetirement = val.toInt();
                    _yearsCtrl.text = val.toStringAsFixed(0);
                  });
                },
              ),
              const SizedBox(height: 16),

              // Increment buttons
              Text('EXPECTED ANNUAL SALARY INCREMENT',
                  style: AppTextStyles.dmSans(
                      size: 8.5,
                      color: theme.getMutedColor(context),
                      weight: FontWeight.w800)),
              const SizedBox(height: 8),
              Row(
                children: [0.0, 5.0, 8.0, 10.0].map((inc) {
                  final active = _salaryIncrement == inc;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _salaryIncrement = inc),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFFFF6B00)
                              : Colors.transparent,
                          border: Border.all(
                              color: active
                                  ? const Color(0xFFFF6B00)
                                  : theme.getBorderColor(context)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${inc.toStringAsFixed(0)}%',
                          style: AppTextStyles.dmSans(
                            size: 11,
                            weight: FontWeight.w800,
                            color: active
                                ? Colors.white
                                : theme.getMutedColor(context),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Synced input-slider 4: ROI / Interest Rate
              _buildSyncedInputRow(
                label: 'EPF INTEREST RATE (P.A.)',
                controller: _roiCtrl,
                value: _roi,
                min: 5.0,
                max: 15.0,
                suffix: '% p.a.',
                onChangedText: (val) {
                  setState(() {
                    _roi = val;
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _roi = val;
                    _roiCtrl.text = val.toStringAsFixed(2);
                  });
                },
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _scrollToResults,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF046A38),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: Text('🏛️ Calculate EPF Corpus',
                          style: AppTextStyles.dmSans(
                              size: 13,
                              color: Colors.white,
                              weight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 50,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => _saveCalculation(
                          corpus, empTotal, emplrTotal, intTotal),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B1F48),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Icon(Icons.bookmark_border, size: 20),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Result Hero Card
        Container(
          key: _resultsKey,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ESTIMATED EPF MATURITY CORPUS',
                  style: AppTextStyles.dmSans(
                      size: 9,
                      color: Colors.white60,
                      weight: FontWeight.w700,
                      letterSpacing: 0.8)),
              const SizedBox(height: 4),
              Text(
                _fmt(corpus),
                style: AppTextStyles.playfair(
                    size: 32,
                    color: const Color(0xFFFFDEA0),
                    weight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.2,
                children: [
                  _resultBox('Employee Contrib.', _fmt(empTotal)),
                  _resultBox('Employer Contrib.', _fmt(emplrTotal)),
                  _resultBox('Total Interest', _fmt(intTotal)),
                  _resultBox('Monthly Contribution', _fmt(monthlyCont)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Growth Chart Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📈 EPF Corpus Accumulation',
                  style: AppTextStyles.dmSans(
                      size: 13,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context))),
              const SizedBox(height: 16),
              SizedBox(
                height: 140,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: uniqueRows.map((d) {
                    final balanceVal = d['corpus'] as double;
                    final yearEmp = d['yearEmp'] as double;
                    final yearEmpr = d['yearEmpr'] as double;

                    final double totalH =
                        max(6.0, (balanceVal / maxChartVal) * 120.0);
                    final double empH = (yearEmp / balanceVal) * totalH;
                    final double emprH = (yearEmpr / balanceVal) * totalH;
                    final double intH = max(0.0, totalH - empH - emprH);

                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 18,
                            height: totalH,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  height: intH,
                                  width: 18,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF046A38),
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(4)),
                                  ),
                                ),
                                Container(
                                  height: emprH,
                                  width: 18,
                                  color: const Color(0xFF1A3A8F),
                                ),
                                Container(
                                  height: empH,
                                  width: 18,
                                  color: const Color(0xFFFF6B00),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Y${d['y']}',
                              style: AppTextStyles.dmSans(
                                  size: 8,
                                  color: theme.getMutedColor(context))),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _chartIndicatorDot(const Color(0xFFFF6B00), 'Employee'),
                  const SizedBox(width: 10),
                  _chartIndicatorDot(const Color(0xFF1A3A8F), 'Employer'),
                  const SizedBox(width: 10),
                  _chartIndicatorDot(const Color(0xFF046A38), 'Interest'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Pie/Donut Breakdown
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🥧 Corpus Breakdown Split',
                  style: AppTextStyles.dmSans(
                      size: 13,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context))),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CustomPaint(
                      painter: _EPFDonutPainter(
                        emp: empTotal,
                        empr: emplrTotal,
                        interest: intTotal,
                        existing: _existingBalance,
                        empColor: const Color(0xFFFF6B00),
                        emprColor: const Color(0xFF1A3A8F),
                        interestColor: const Color(0xFF046A38),
                        existingColor: const Color(0xFF9333EA),
                        textColor: theme.getTextColor(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        _legendRow(const Color(0xFFFF6B00), 'Employee Contrib.',
                            _fmt(empTotal)),
                        const SizedBox(height: 6),
                        _legendRow(const Color(0xFF1A3A8F), 'Employer Contrib.',
                            _fmt(emplrTotal)),
                        const SizedBox(height: 6),
                        _legendRow(const Color(0xFF046A38), 'Interest Earned',
                            _fmt(intTotal)),
                        const SizedBox(height: 6),
                        _legendRow(const Color(0xFF9333EA), 'Existing Balance',
                            _fmt(_existingBalance)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // EPF Rules Summary Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF042F1A) : const Color(0xFFECFDF5),
            border: Border.all(
                color:
                    isDark ? const Color(0xFF065F46) : const Color(0xFF6EE7B7)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📋 EPF Rules at a Glance (FY 2025–26)',
                style: AppTextStyles.dmSans(
                  size: 11.5,
                  weight: FontWeight.w800,
                  color: isDark
                      ? const Color(0xFF86EFAC)
                      : const Color(0xFF07543A),
                ),
              ),
              const SizedBox(height: 10),
              _ruleSummary('EPF Interest Rate (Current)',
                  '${_roi.toStringAsFixed(2)}% p.a.', isDark),
              _ruleSummary(
                  'Employee Contribution', '12% of Basic + DA', isDark),
              _ruleSummary('Employer — EPF (3.67%)',
                  '₹15,000 wage ceiling limit', isDark),
              _ruleSummary(
                  'Employer — EPS (8.33%)', 'Max ₹1,250/month pension', isDark),
              _ruleSummary(
                  'Tax Treatment (EEE)', 'Exempt - Exempt - Exempt', isDark),
              _ruleSummary('Withdrawal eligibility',
                  'Fully Tax-Free after 5 years', isDark),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Year-wise Projection Table
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📅 Year-wise Projection Details',
                  style: AppTextStyles.dmSans(
                      size: 13,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context))),
              const SizedBox(height: 12),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.2),
                  1: FlexColumnWidth(1.4),
                  2: FlexColumnWidth(1.4),
                  3: FlexColumnWidth(1.6),
                },
                children: [
                  TableRow(
                    children: [
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text('Year',
                              style: AppTextStyles.dmSans(
                                  size: 9.5,
                                  weight: FontWeight.w800,
                                  color: theme.getMutedColor(context)))),
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text('Emp Cont',
                              style: AppTextStyles.dmSans(
                                  size: 9.5,
                                  weight: FontWeight.w800,
                                  color: theme.getMutedColor(context)),
                              textAlign: TextAlign.right)),
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text('Interest',
                              style: AppTextStyles.dmSans(
                                  size: 9.5,
                                  weight: FontWeight.w800,
                                  color: theme.getMutedColor(context)),
                              textAlign: TextAlign.right)),
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text('Corpus',
                              style: AppTextStyles.dmSans(
                                  size: 9.5,
                                  weight: FontWeight.w800,
                                  color: theme.getMutedColor(context)),
                              textAlign: TextAlign.right)),
                    ],
                  ),
                  ...uniqueRows.map((d) {
                    return TableRow(
                      children: [
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text('Year ${d['y']}',
                                style: AppTextStyles.dmSans(
                                    size: 11,
                                    weight: FontWeight.w700,
                                    color: theme.getTextColor(context)))),
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(_fmtShort(d['yearEmp']!),
                                style: AppTextStyles.dmSans(
                                    size: 11,
                                    color: theme.getTextColor(context)),
                                textAlign: TextAlign.right)),
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(_fmtShort(d['yearInt']!),
                                style: AppTextStyles.dmSans(
                                    size: 11,
                                    color: isDark
                                        ? const Color(0xFF86EFAC)
                                        : const Color(0xFF046A38)),
                                textAlign: TextAlign.right)),
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(_fmtShort(d['corpus']!),
                                style: AppTextStyles.dmSans(
                                    size: 11,
                                    color: theme.getTextColor(context)),
                                textAlign: TextAlign.right)),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Saved Calculations Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Saved Calculations',
                style: AppTextStyles.playfair(
                    size: 15, color: theme.getTextColor(context))),
            if (savedList.isNotEmpty)
              Text('(${savedList.length})',
                  style: AppTextStyles.dmSans(
                      size: 12,
                      color: theme.getMutedColor(context),
                      weight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        if (savedList.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Center(
              child: Text(
                'No saved calculations yet.',
                style: AppTextStyles.dmSans(
                    size: 12, color: theme.getMutedColor(context)),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: savedList.length,
            itemBuilder: (context, idx) {
              final s = savedList[idx];
              final sBasic = s.inputs['basicSalary'] ?? 0.0;
              final sYears = s.inputs['years']?.toInt() ?? 25;
              final sRate = s.inputs['rate'] ?? 8.25;
              final sCorp = s.results['corpus'] ?? 0.0;
              final sEmp = s.results['employeeTotal'] ?? 0.0;
              final sEmpr = s.results['employerTotal'] ?? 0.0;
              final sInt = s.results['interestTotal'] ?? 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.getCardColor(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.getBorderColor(context)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${s.label} · $sYears Yrs @ $sRate%',
                            style: AppTextStyles.dmSans(
                                size: 12,
                                weight: FontWeight.w800,
                                color: theme.getTextColor(context)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Basic: ${_fmtShort(sBasic)} · Emp: ${_fmtShort(sEmp)} · Empr: ${_fmtShort(sEmpr)}',
                            style: AppTextStyles.dmSans(
                                size: 9.5, color: theme.getMutedColor(context)),
                          ),
                          Text(
                            'Interest: ${_fmtShort(sInt)}',
                            style: AppTextStyles.dmSans(
                                size: 9.5, color: theme.getMutedColor(context)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _fmtShort(sCorp),
                          style: AppTextStyles.dmSans(
                              size: 13,
                              weight: FontWeight.w800,
                              color: const Color(0xFF046A38)),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.redAccent),
                          onPressed: () =>
                              ref.read(savedProvider.notifier).delete(s.id),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _headerRateItem(
      String label, String value, String note, BuildContext context,
      {bool isGreen = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 8,
                  color: widget.theme.getMutedColor(context),
                  weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.dmSans(
              size: 13,
              weight: FontWeight.w800,
              color: isGreen
                  ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF046A38))
                  : const Color(0xFFFF6B00),
            ),
          ),
          const SizedBox(height: 1),
          Text(note,
              style: AppTextStyles.dmSans(
                  size: 8,
                  color: widget.theme
                      .getMutedColor(context)
                      .withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.grey.withValues(alpha: 0.25),
    );
  }

  Widget _buildSyncedInputRow({
    required String label,
    required TextEditingController controller,
    required double value,
    required double min,
    required double max,
    String prefix = '',
    String suffix = '',
    required ValueChanged<double> onChangedText,
    required ValueChanged<double> onChangedSlider,
  }) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTextStyles.dmSans(
                    size: 8.5,
                    color: theme.getMutedColor(context),
                    weight: FontWeight.w800)),
            Text('$prefix${_fmtShort(value)}$suffix',
                style: AppTextStyles.dmSans(
                    size: 11.5,
                    weight: FontWeight.w800,
                    color: theme.getTextColor(context))),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.04),
            border: Border.all(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(11),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: AppTextStyles.dmSans(
                size: 13,
                color: theme.getTextColor(context),
                weight: FontWeight.w800),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
            ),
            onChanged: (v) {
              final parsed = double.tryParse(v);
              if (parsed != null && parsed >= min && parsed <= max) {
                onChangedText(parsed);
              }
            },
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFFF6B00),
            inactiveTrackColor: const Color(0xFFFF6B00).withValues(alpha: 0.15),
            thumbColor: const Color(0xFFFFDEA0),
            overlayColor: const Color(0xFFFF6B00).withValues(alpha: 0.24),
            trackHeight: 3.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChangedSlider,
          ),
        ),
      ],
    );
  }

  Widget _resultBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(size: 8.5, color: Colors.white60),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.dmSans(
                  size: 11.5, weight: FontWeight.w800, color: Colors.white),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label, String value) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: AppTextStyles.dmSans(
                      size: 10.5,
                      weight: FontWeight.w700,
                      color: widget.theme.getTextColor(context))),
              Text(value,
                  style: AppTextStyles.dmSans(
                      size: 10.5, color: widget.theme.getMutedColor(context))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chartIndicatorDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: AppTextStyles.dmSans(
                size: 9.5,
                color: widget.theme.getMutedColor(context),
                weight: FontWeight.w600)),
      ],
    );
  }

  Widget _ruleSummary(String label, String val, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(
              size: 10.5,
              color: isDark ? Colors.white70 : const Color(0xFF046A38),
            ),
          ),
          Text(
            val,
            style: AppTextStyles.dmSans(
              size: 10.5,
              weight: FontWeight.w800,
              color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF07543A),
            ),
          ),
        ],
      ),
    );
  }
}

class _EPFDonutPainter extends CustomPainter {
  final double emp;
  final double empr;
  final double interest;
  final double existing;
  final Color empColor;
  final Color emprColor;
  final Color interestColor;
  final Color existingColor;
  final Color textColor;

  _EPFDonutPainter({
    required this.emp,
    required this.empr,
    required this.interest,
    required this.existing,
    required this.empColor,
    required this.emprColor,
    required this.interestColor,
    required this.existingColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    const strokeW = 12.0;

    final total = emp + empr + interest + existing;
    if (total <= 0) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.grey.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW,
      );
      return;
    }

    final pEmp = emp / total;
    final pEmpr = empr / total;
    final pInterest = interest / total;
    final pExisting = existing / total;

    final rect = Rect.fromCircle(center: center, radius: radius);
    double startAngle = -pi / 2;

    if (pEmp > 0) {
      final sweep = pEmp * 2 * pi;
      canvas.drawArc(
          rect,
          startAngle,
          sweep,
          false,
          Paint()
            ..color = empColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW);
      startAngle += sweep;
    }
    if (pEmpr > 0) {
      final sweep = pEmpr * 2 * pi;
      canvas.drawArc(
          rect,
          startAngle,
          sweep,
          false,
          Paint()
            ..color = emprColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW);
      startAngle += sweep;
    }
    if (pInterest > 0) {
      final sweep = pInterest * 2 * pi;
      canvas.drawArc(
          rect,
          startAngle,
          sweep,
          false,
          Paint()
            ..color = interestColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW);
      startAngle += sweep;
    }
    if (pExisting > 0) {
      final sweep = pExisting * 2 * pi;
      canvas.drawArc(
          rect,
          startAngle,
          sweep,
          false,
          Paint()
            ..color = existingColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW);
    }

    // Center text
    final ratioLabel = '${((pInterest) * 100).round()}%';
    final textPainter = TextPainter(
      text: TextSpan(
        text: ratioLabel,
        style: TextStyle(
            fontFamily: 'Book Antiqua',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: textColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas,
        center - Offset(textPainter.width / 2, textPainter.height / 2 + 5));

    final subPainter = TextPainter(
      text: const TextSpan(
        text: 'interest',
        style: TextStyle(
            fontFamily: 'Trebuchet MS',
            fontSize: 8,
            color: Colors.grey,
            fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    subPainter.paint(canvas,
        center - Offset(subPainter.width / 2, subPainter.height / 2 - 10));
  }

  @override
  bool shouldRepaint(covariant _EPFDonutPainter oldDelegate) {
    return oldDelegate.emp != emp ||
        oldDelegate.empr != empr ||
        oldDelegate.interest != interest ||
        oldDelegate.existing != existing ||
        oldDelegate.textColor != textColor;
  }
}
