// lib/features/india/tools/in_personal_loan_emi.dart

import 'package:flutter/material.dart';
import 'dart:math' show max, min, pow, pi;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class INPersonalLoanEMI extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INPersonalLoanEMI({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INPersonalLoanEMI> createState() => _INPersonalLoanEMIState();
}

class _INPersonalLoanEMIState extends ConsumerState<INPersonalLoanEMI> {
  // Input states
  double _loanAmount = 500000;
  double _roi = 11.45;
  double _tenureYears = 5;
  double _procFeePercent = 1.5;

  // Controllers
  late TextEditingController _loanAmountCtrl;
  late TextEditingController _roiCtrl;
  late TextEditingController _tenureCtrl;
  late TextEditingController _procFeeCtrl;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultsKey = GlobalKey();

  final List<Map<String, dynamic>> _banks = const [
    {
      'icon': '🏦',
      'name': 'SBI Xpress Credit',
      'rate': 11.45,
      'desc': 'Govt. salary · Upto ₹40L'
    },
    {
      'icon': '🏛️',
      'name': 'HDFC Personal Loan',
      'rate': 10.85,
      'desc': 'Salaried & Self-employed'
    },
    {
      'icon': '🏢',
      'name': 'ICICI Bank',
      'rate': 10.80,
      'desc': 'Insta Loan for existing'
    },
    {
      'icon': '⚡',
      'name': 'Axis Bank',
      'rate': 11.25,
      'desc': 'Salary + non-salary'
    },
    {
      'icon': '🌿',
      'name': 'Kotak Mahindra',
      'rate': 10.99,
      'desc': 'Instant disbursal'
    },
    {
      'icon': '💼',
      'name': 'Bajaj Finserv',
      'rate': 13.00,
      'desc': 'NBFC · Pre-approved'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loanAmountCtrl =
        TextEditingController(text: _loanAmount.toStringAsFixed(0));
    _roiCtrl = TextEditingController(text: _roi.toStringAsFixed(2));
    _tenureCtrl = TextEditingController(text: _tenureYears.toStringAsFixed(0));
    _procFeeCtrl =
        TextEditingController(text: _procFeePercent.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _loanAmountCtrl.dispose();
    _roiCtrl.dispose();
    _tenureCtrl.dispose();
    _procFeeCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _loanAmount = 500000;
      _roi = 11.45;
      _tenureYears = 5;
      _procFeePercent = 1.5;

      _loanAmountCtrl.text = '500000';
      _roiCtrl.text = '11.45';
      _tenureCtrl.text = '5';
      _procFeeCtrl.text = '1.5';
    });
  }

  double _calcEMI(double p, double ratePA, int termMonths) {
    if (p <= 0 || ratePA <= 0) return 0;
    final r = ratePA / (12 * 100);
    return p * r * pow(1 + r, termMonths) / (pow(1 + r, termMonths) - 1);
  }

  String _fmt(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(2)}L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
        .format(n);
  }

  String _fmtShort(double n) {
    if (n >= 10000000) return '${(n / 10000000).toStringAsFixed(1)}Cr';
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
        .format(n);
  }

  void _saveCalculation() async {
    final emi = _calcEMI(_loanAmount, _roi, (_tenureYears * 12).toInt());
    final totalPay = emi * _tenureYears * 12;
    final totalInt = totalPay - _loanAmount;
    final fee = _loanAmount * (_procFeePercent / 100);

    final labelCtrl = TextEditingController(text: 'Personal Loan EMI');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/in_personal_loan_emi/save'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Personal Loan Calc',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving: EMI ${_fmt(emi)}/mo · Amount ${_fmt(_loanAmount)}',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. HDFC Personal Loan)',
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
              backgroundColor: const Color(0xFFFF6B00),
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
          : 'Personal Loan EMI';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'Personal Loan EMI',
        inputs: {
          'loanAmount': _loanAmount,
          'rate': _roi,
          'termYears': _tenureYears,
          'procFeePercent': _procFeePercent,
        },
        results: {
          'emi': emi,
          'totalInterest': totalInt,
          'totalPayable': totalPay,
          'procFee': fee,
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

    // Reactively compute values
    final emi = _calcEMI(_loanAmount, _roi, (_tenureYears * 12).toInt());
    final totalPay = emi * _tenureYears * 12;
    final totalInt = totalPay - _loanAmount;
    final fee = _loanAmount * (_procFeePercent / 100);
    final disbursed = _loanAmount - fee;
    final costPct =
        _loanAmount > 0 ? ((totalInt + fee) / _loanAmount * 100) : 0.0;
    final intRatio = totalPay > 0 ? (totalInt / totalPay) : 0.0;

    // Year-wise schedule calculation
    final listYears = _tenureYears.ceil();
    final rMonthly = _roi / 1200;
    double tempBal = _loanAmount;
    final List<Map<String, double>> yearBreakdown = [];
    for (int y = 1; y <= listYears; y++) {
      double yInt = 0;
      double yPrin = 0;
      for (int m = 0; m < 12; m++) {
        if (tempBal <= 0.01) break;
        final ip = tempBal * rMonthly;
        final pp = min(emi - ip, tempBal);
        yInt += ip;
        yPrin += pp;
        tempBal -= pp;
      }
      yearBreakdown
          .add({'principal': yPrin, 'interest': yInt, 'balance': tempBal});
    }

    final maxBarVal = yearBreakdown.isNotEmpty
        ? yearBreakdown.map((d) => d['principal']! + d['interest']!).reduce(max)
        : 1.0;

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
              _headerRateItem('SBI Rate', '11.45%', 'p.a. 2025', context),
              _verticalDivider(),
              _headerRateItem('HDFC Bank', '10.85%', 'p.a.', context),
              _verticalDivider(),
              _headerRateItem('ICICI Bank', '10.80%', 'p.a.', context),
              _verticalDivider(),
              _headerRateItem('Max Tenure', '7 yrs', 'Unsecured', context,
                  isGreen: true),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Input Card
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
                  Text('LOAN PARAMETERS',
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
              const SizedBox(height: 14),

              // Synced input-slider 1: Loan Amount
              _buildSyncedInputRow(
                label: 'LOAN AMOUNT',
                controller: _loanAmountCtrl,
                value: _loanAmount,
                min: 10000,
                max: 5000000,
                prefix: '₹ ',
                onChangedText: (val) {
                  setState(() {
                    _loanAmount = val;
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _loanAmount = val;
                    _loanAmountCtrl.text = val.toStringAsFixed(0);
                  });
                },
              ),
              const SizedBox(height: 12),

              // Synced input-slider 2: Annual Interest Rate
              _buildSyncedInputRow(
                label: 'ANNUAL INTEREST RATE',
                controller: _roiCtrl,
                value: _roi,
                min: 8.0,
                max: 30.0,
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
              const SizedBox(height: 12),

              // Synced input-slider 3: Loan Tenure (Years)
              _buildSyncedInputRow(
                label: 'LOAN TENURE',
                controller: _tenureCtrl,
                value: _tenureYears,
                min: 1,
                max: 7,
                suffix: ' Yrs',
                onChangedText: (val) {
                  setState(() {
                    _tenureYears = val;
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _tenureYears = val;
                    _tenureCtrl.text = val.toStringAsFixed(0);
                  });
                },
              ),
              const SizedBox(height: 12),

              // Synced input-slider 4: Processing Fee
              _buildSyncedInputRow(
                label: 'PROCESSING FEE (%)',
                controller: _procFeeCtrl,
                value: _procFeePercent,
                min: 0.0,
                max: 5.0,
                suffix: '% of Loan',
                onChangedText: (val) {
                  setState(() {
                    _procFeePercent = val;
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _procFeePercent = val;
                    _procFeeCtrl.text = val.toStringAsFixed(1);
                  });
                },
              ),
              const SizedBox(height: 4),
              Text(
                'Typically 1–3% of loan amount, deducted upfront from disbursement.',
                style: AppTextStyles.dmSans(
                    size: 8.5, color: theme.getMutedColor(context)),
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _scrollToResults,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('📊 Calculate EMI & View Breakdown',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        color: Colors.white,
                        weight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

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
              Text('MONTHLY EMI',
                  style: AppTextStyles.dmSans(
                      size: 9,
                      color: Colors.white60,
                      weight: FontWeight.w700,
                      letterSpacing: 0.8)),
              const SizedBox(height: 4),
              Text(
                _fmt(emi),
                style: AppTextStyles.playfair(
                    size: 34,
                    color: const Color(0xFFFFDEA0),
                    weight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.5,
                children: [
                  _resultBox('Principal', _fmt(_loanAmount)),
                  _resultBox('Total Interest', _fmt(totalInt), isRed: true),
                  _resultBox('Total Payable', _fmt(totalPay)),
                  _resultBox('Processing Fee', _fmt(fee)),
                  _resultBox('Net Disbursed', _fmt(disbursed), isGreen: true),
                  _resultBox(
                      'Cost of Credit', '${costPct.toStringAsFixed(1)}%'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Visual Analysis
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
              Text('📊 Composition & Year-wise Analysis',
                  style: AppTextStyles.dmSans(
                      size: 13,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context))),
              const SizedBox(height: 16),

              // Donut Chart Row
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CustomPaint(
                      painter: _DonutChartPainter(
                        v1: _loanAmount,
                        v2: totalInt,
                        v3: fee,
                        c1: const Color(0xFF046A38),
                        c2: const Color(0xFFFCA5A5),
                        c3: const Color(0xFFFF6B00),
                        centerLabel: '${(intRatio * 100).round()}%',
                        textColor: theme.getTextColor(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        _legendRow(const Color(0xFF046A38), 'Principal',
                            _fmt(_loanAmount)),
                        const SizedBox(height: 8),
                        _legendRow(const Color(0xFFFCA5A5), 'Total Interest',
                            _fmt(totalInt)),
                        const SizedBox(height: 8),
                        _legendRow(const Color(0xFFFF6B00), 'Processing Fee',
                            _fmt(fee)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // Year-wise principal vs interest paid stacked bar chart
              Text('YEAR-WISE INTEREST VS PRINCIPAL',
                  style: AppTextStyles.dmSans(
                      size: 9,
                      color: theme.getMutedColor(context),
                      weight: FontWeight.w800)),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: yearBreakdown.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final val = entry.value;
                    final prinVal = val['principal']!;
                    final intVal = val['interest']!;
                    final sumVal = prinVal + intVal;

                    final totalH = sumVal / maxBarVal * 80;
                    final intH = intVal / sumVal * totalH;
                    final prinH = totalH - intH;

                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 16,
                            height: totalH,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  height: intH,
                                  width: 16,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFCA5A5),
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(4)),
                                  ),
                                ),
                                Container(
                                  height: prinH,
                                  width: 16,
                                  color: const Color(0xFF046A38),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Y${idx + 1}',
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
                  _chartIndicatorDot(const Color(0xFF046A38), 'Principal'),
                  const SizedBox(width: 12),
                  _chartIndicatorDot(const Color(0xFFFCA5A5), 'Interest'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Amortization table (first 5 years)
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
              Text('📅 Amortisation Schedule (First 5 Years)',
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
                          child: Text('Principal',
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
                          child: Text('Balance',
                              style: AppTextStyles.dmSans(
                                  size: 9.5,
                                  weight: FontWeight.w800,
                                  color: theme.getMutedColor(context)),
                              textAlign: TextAlign.right)),
                    ],
                  ),
                  ...yearBreakdown.asMap().entries.take(5).map((entry) {
                    final idx = entry.key;
                    final val = entry.value;
                    return TableRow(
                      children: [
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text('Year ${idx + 1}',
                                style: AppTextStyles.dmSans(
                                    size: 11,
                                    weight: FontWeight.w700,
                                    color: theme.getTextColor(context)))),
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(_fmtShort(val['principal']!),
                                style: AppTextStyles.dmSans(
                                    size: 11,
                                    color: theme.getTextColor(context)),
                                textAlign: TextAlign.right)),
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(_fmtShort(val['interest']!),
                                style: AppTextStyles.dmSans(
                                    size: 11,
                                    color: theme.getTextColor(context)),
                                textAlign: TextAlign.right)),
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(_fmtShort(val['balance']!),
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
        const SizedBox(height: 16),

        // Prepayment Tip Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            border: Border.all(color: const Color(0xFFFDBA74)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Prepay to Save Big',
                        style: AppTextStyles.dmSans(
                            size: 12,
                            weight: FontWeight.w800,
                            color: const Color(0xFF9A3412))),
                    const SizedBox(height: 4),
                    Text(
                      'Your ${_fmtShort(_loanAmount)} loan at ${_roi.toStringAsFixed(2)}% for ${_tenureYears.toStringAsFixed(0)} years costs ${_fmt(totalInt)} in interest. Consider part-prepayment after 12 EMIs — a lump payment of 20% in Year 1 can save approx 18% of total interest.',
                      style: AppTextStyles.dmSans(
                          size: 10,
                          color: const Color(0xFFC2410C),
                          height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Top Personal Loan Rates 2025
        Text('Top Personal Loan Rates 2025',
            style: AppTextStyles.playfair(
                size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 10),
        Column(
          children: _banks.map((b) {
            final bRate = b['rate'] as double;
            final bEmi =
                _calcEMI(_loanAmount, bRate, (_tenureYears * 12).toInt());
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
                  Text(b['icon'] as String,
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b['name'] as String,
                            style: AppTextStyles.dmSans(
                                size: 12,
                                weight: FontWeight.w800,
                                color: theme.getTextColor(context))),
                        Text(b['desc'] as String,
                            style: AppTextStyles.dmSans(
                                size: 9.5,
                                color: theme.getMutedColor(context))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${bRate.toStringAsFixed(2)}%',
                          style: AppTextStyles.dmSans(
                              size: 13,
                              weight: FontWeight.w800,
                              color: const Color(0xFFFF6B00))),
                      Text('EMI ${_fmtShort(bEmi)}',
                          style: AppTextStyles.dmSans(
                              size: 9, color: theme.getMutedColor(context))),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Save Calculation Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
            border: Border.all(
                color:
                    isDark ? const Color(0xFF065F46) : const Color(0xFF6EE7B7)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Text('💾', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Save This Calculation',
                        style: AppTextStyles.dmSans(
                            size: 12,
                            weight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF07543A))),
                    Text('Save details for future reference',
                        style: AppTextStyles.dmSans(
                            size: 10,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF046A38))),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _saveCalculation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF046A38),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Save',
                    style: AppTextStyles.dmSans(
                        size: 11,
                        color: Colors.white,
                        weight: FontWeight.w700)),
              ),
            ],
          ),
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

  Widget _resultBox(String label, String value,
      {bool isRed = false, bool isGreen = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
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
          Text(
            value,
            style: AppTextStyles.dmSans(
              size: 11.5,
              weight: FontWeight.w800,
              color: isRed
                  ? const Color(0xFFFCA5A5)
                  : isGreen
                      ? const Color(0xFF86EFAC)
                      : Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label, String value) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.dmSans(
                      size: 10.5,
                      weight: FontWeight.w700,
                      color: widget.theme.getTextColor(context))),
              Text(value,
                  style: AppTextStyles.dmSans(
                      size: 9, color: widget.theme.getMutedColor(context))),
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
}

class _DonutChartPainter extends CustomPainter {
  final double v1;
  final double v2;
  final double v3;
  final Color c1;
  final Color c2;
  final Color c3;
  final String centerLabel;
  final Color textColor;

  _DonutChartPainter({
    required this.v1,
    required this.v2,
    required this.v3,
    required this.c1,
    required this.c2,
    required this.c3,
    required this.centerLabel,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    const strokeW = 12.0;

    final total = v1 + v2 + v3;
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

    final p1 = v1 / total;
    final p2 = v2 / total;
    final p3 = v3 / total;

    final rect = Rect.fromCircle(center: center, radius: radius);
    double startAngle = -pi / 2;

    if (p1 > 0) {
      final sweep = p1 * 2 * pi;
      canvas.drawArc(
          rect,
          startAngle,
          sweep,
          false,
          Paint()
            ..color = c1
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW);
      startAngle += sweep;
    }
    if (p2 > 0) {
      final sweep = p2 * 2 * pi;
      canvas.drawArc(
          rect,
          startAngle,
          sweep,
          false,
          Paint()
            ..color = c2
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW);
      startAngle += sweep;
    }
    if (p3 > 0) {
      final sweep = p3 * 2 * pi;
      canvas.drawArc(
          rect,
          startAngle,
          sweep,
          false,
          Paint()
            ..color = c3
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW);
    }

    // Center text
    final textPainter = TextPainter(
      text: TextSpan(
        text: centerLabel,
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
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.v1 != v1 ||
        oldDelegate.v2 != v2 ||
        oldDelegate.v3 != v3 ||
        oldDelegate.textColor != textColor;
  }
}
