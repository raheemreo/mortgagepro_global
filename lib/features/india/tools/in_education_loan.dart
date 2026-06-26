// lib/features/india/tools/in_education_loan.dart

import 'package:flutter/material.dart';
import 'dart:math' show max, pow;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class INEducationLoan extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INEducationLoan({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INEducationLoan> createState() => _INEducationLoanState();
}

class _INEducationLoanState extends ConsumerState<INEducationLoan> {
  // Input states
  String _courseType = 'domestic'; // domestic, abroad, iit
  double _loanAmount = 1500000;
  double _roi = 11.15;
  double _courseDurationYears = 4;
  double _repayTenureYears = 10;

  // Controllers
  late TextEditingController _loanAmountCtrl;
  late TextEditingController _roiCtrl;
  late TextEditingController _courseDurCtrl;
  late TextEditingController _repayTenureCtrl;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultsKey = GlobalKey();

  final Map<String, double> _rates = const {
    'domestic': 11.15,
    'abroad': 11.50,
    'iit': 8.65,
  };

  final List<Map<String, dynamic>> _lenders = const [
    {
      'icon': '🏦',
      'name': 'SBI Scholar',
      'desc': 'IIT/IIM/NIT · up to ₹40L (no margin)',
      'rate': 8.65,
      'concession': 'No collateral'
    },
    {
      'icon': '🏦',
      'name': 'SBI Student Loan',
      'desc': 'Up to ₹7.5L domestic · 15-yr tenure',
      'rate': 11.15,
      'concession': '5% off women'
    },
    {
      'icon': '🏛️',
      'name': 'HDFC Credila',
      'desc': 'Abroad specialists · ₹1.5Cr max',
      'rate': 11.50,
      'concession': 'Dedicated abroad'
    },
    {
      'icon': '⚡',
      'name': 'Axis Bank',
      'desc': 'Flexible repayment · digital process',
      'rate': 13.70,
      'concession': 'Quick disbursal'
    },
    {
      'icon': '🌿',
      'name': 'Union Bank',
      'desc': 'Union Nari Sashakt — Women 0.5% off',
      'rate': 11.30,
      'concession': 'PSU Bank'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loanAmountCtrl =
        TextEditingController(text: _loanAmount.toStringAsFixed(0));
    _roiCtrl = TextEditingController(text: _roi.toStringAsFixed(2));
    _courseDurCtrl =
        TextEditingController(text: _courseDurationYears.toStringAsFixed(0));
    _repayTenureCtrl =
        TextEditingController(text: _repayTenureYears.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _loanAmountCtrl.dispose();
    _roiCtrl.dispose();
    _courseDurCtrl.dispose();
    _repayTenureCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _courseType = 'domestic';
      _loanAmount = 1500000;
      _roi = 11.15;
      _courseDurationYears = 4;
      _repayTenureYears = 10;

      _loanAmountCtrl.text = '1500000';
      _roiCtrl.text = '11.15';
      _courseDurCtrl.text = '4';
      _repayTenureCtrl.text = '10';
    });
  }

  void _setCourseType(String type) {
    setState(() {
      _courseType = type;
      _roi = _rates[type] ?? 11.15;
      _roiCtrl.text = _roi.toStringAsFixed(2);
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
    final cd = _courseDurationYears;
    final annR = _roi / 100;
    final moraYrs = cd + 1.0;
    final moraInt = _loanAmount * annR * moraYrs;
    final capAmt = _loanAmount + moraInt;
    final emi = _calcEMI(capAmt, _roi, (_repayTenureYears * 12).toInt());
    final totalPay = capAmt + (emi * _repayTenureYears * 12 - capAmt);
    final totalInt = totalPay - _loanAmount;

    final labelCtrl = TextEditingController(text: 'Education Loan');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Education Loan Calc',
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
                hintText: 'Label (e.g. My Masters Loan)',
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
          : 'Education Loan';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'Education Loan',
        inputs: {
          'loanAmount': _loanAmount,
          'rate': _roi,
          'courseDuration': cd,
          'termYears': _repayTenureYears,
          'courseType': _courseType == 'domestic'
              ? 1.0
              : (_courseType == 'abroad' ? 2.0 : 3.0),
        },
        results: {
          'emi': emi,
          'totalInterest': totalInt,
          'totalPayable': totalPay,
          'moraInterest': moraInt,
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

    // Calculations
    final cd = _courseDurationYears;
    final annR = _roi / 100;
    final moraYrs = cd + 1.0;
    final moraInt = _loanAmount * annR * moraYrs;
    final capAmt = _loanAmount + moraInt;
    final emi = _calcEMI(capAmt, _roi, (_repayTenureYears * 12).toInt());
    final repayInt = emi * _repayTenureYears * 12 - capAmt;
    final totalInt = moraInt + repayInt;
    final totalPay = _loanAmount + totalInt;
    final currentYear = DateTime.now().year;
    final startRepayYear = currentYear + cd.ceil() + 1;

    final maxHBarVal = max(_loanAmount, max(moraInt, repayInt));

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
              _headerRateItem('SBI Scholar', '8.65%', 'IIT/IIM/NIT', context),
              _verticalDivider(),
              _headerRateItem('SBI Student', '11.15%', 'Upto ₹7.5L', context),
              _verticalDivider(),
              _headerRateItem('HDFC Credila', '11.50%', 'Abroad', context),
              _verticalDivider(),
              _headerRateItem('Max Loan', '₹1.5Cr', 'Abroad', context,
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
                  Text('COURSE & LOAN PARAMETERS',
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

              // Course Type Segment Control
              Text('COURSE TYPE',
                  style: AppTextStyles.dmSans(
                      size: 8.5,
                      color: theme.getMutedColor(context),
                      weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _segButton('India', 'domestic'),
                  const SizedBox(width: 6),
                  _segButton('Abroad', 'abroad'),
                  const SizedBox(width: 6),
                  _segButton('IIT/IIM', 'iit'),
                ],
              ),
              const SizedBox(height: 16),

              // Synced input-slider 1: Total Loan Amount
              _buildSyncedInputRow(
                label: 'TOTAL LOAN AMOUNT',
                controller: _loanAmountCtrl,
                value: _loanAmount,
                min: 50000,
                max: 15000000,
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

              // Synced input-slider 2: Interest Rate
              _buildSyncedInputRow(
                label: 'INTEREST RATE (p.a.)',
                controller: _roiCtrl,
                value: _roi,
                min: 7.0,
                max: 16.0,
                suffix: '%',
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

              // Synced input-slider 3: Course Duration
              _buildSyncedInputRow(
                label: 'COURSE DURATION',
                controller: _courseDurCtrl,
                value: _courseDurationYears,
                min: 1,
                max: 6,
                suffix: ' Years',
                onChangedText: (val) {
                  setState(() {
                    _courseDurationYears = val;
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _courseDurationYears = val;
                    _courseDurCtrl.text = val.toStringAsFixed(0);
                  });
                },
              ),
              const SizedBox(height: 4),
              Text(
                'Moratorium = Course duration + 1 year or 6 months after job (whichever is earlier)',
                style: AppTextStyles.dmSans(
                    size: 8.5, color: theme.getMutedColor(context)),
              ),
              const SizedBox(height: 12),

              // Synced input-slider 4: Repayment Tenure
              _buildSyncedInputRow(
                label: 'REPAYMENT TENURE (AFTER MORATORIUM)',
                controller: _repayTenureCtrl,
                value: _repayTenureYears,
                min: 5,
                max: 15,
                suffix: ' Years',
                onChangedText: (val) {
                  setState(() {
                    _repayTenureYears = val;
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _repayTenureYears = val;
                    _repayTenureCtrl.text = val.toStringAsFixed(0);
                  });
                },
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
                child: Text('🎓 Calculate EMI',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        color: Colors.white,
                        weight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Results Card (Always visible with real-time updates)
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
              Text('EMI AFTER MORATORIUM',
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
                  _resultBox('Loan Amount', _fmt(_loanAmount)),
                  _resultBox('Interest In Moratorium', _fmt(moraInt),
                      isRed: true),
                  _resultBox('Capitalised Amount', _fmt(capAmt),
                      isYellow: true),
                  _resultBox('Total Interest', _fmt(totalInt), isRed: true),
                  _resultBox('Total Payable', _fmt(totalPay)),
                  _resultBox('Repayment Starts', '$startRepayYear',
                      isGreen: true),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Loan Lifecycle Timeline & H-Bar Charts
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
              Text('📊 Loan Lifecycle & Timeline',
                  style: AppTextStyles.dmSans(
                      size: 13,
                      weight: FontWeight.w800,
                      color: theme.getTextColor(context))),
              const SizedBox(height: 16),

              // Horizontal Moratorium Timeline
              Row(
                children: [
                  Expanded(
                      child: _timelineBlock('Study', '${cd.ceil()} Yrs',
                          const Color(0xFFFFF3E0), const Color(0xFFFED7AA))),
                  const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text('→', style: TextStyle(color: Colors.grey))),
                  Expanded(
                      child: _timelineBlock('Moratorium', '+1 Yr',
                          const Color(0xFFECFDF5), const Color(0xFFA7F3D0))),
                  const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text('→', style: TextStyle(color: Colors.grey))),
                  Expanded(
                      child: _timelineBlock(
                          'Repayment',
                          '${_repayTenureYears.ceil()} Yrs',
                          const Color(0xFFEFF6FF),
                          const Color(0xFFBFDBFE))),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // Lifecycle horizontal bars
              _lifecycleHBar('Principal', _loanAmount, maxHBarVal,
                  const Color(0xFF046A38)),
              const SizedBox(height: 10),
              _lifecycleHBar('Interest (Moratorium)', moraInt, maxHBarVal,
                  const Color(0xFFF59E0B)),
              const SizedBox(height: 10),
              _lifecycleHBar('Interest (Repayment)', repayInt, maxHBarVal,
                  const Color(0xFFFCA5A5)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Central Subsidy Schemes
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            border: Border.all(color: const Color(0xFF6EE7B7)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🏛️ Govt. Interest Subsidy Schemes',
                  style: AppTextStyles.dmSans(
                      size: 12,
                      weight: FontWeight.w800,
                      color: const Color(0xFF07543A))),
              const SizedBox(height: 10),
              _subsidyRow('Central Scheme (CSIS)',
                  'EWS/LIG · Annual income ≤ ₹4.5L', 'Full moratorium subsidy'),
              _subsidyRow(
                  'Padho Pardesh',
                  'Minority communities · Abroad studies',
                  'Moratorium interest'),
              _subsidyRow('Dr. Ambedkar Central Scheme',
                  'OBC/EBC · Abroad only', 'Full moratorium'),
              const Divider(color: Color(0x33046A38)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Moratorium Subsidy (Your Loan)',
                          style: AppTextStyles.dmSans(
                              size: 10.5,
                              weight: FontWeight.w700,
                              color: const Color(0xFF046A38))),
                      Text('If eligible, government pays this.',
                          style: AppTextStyles.dmSans(
                              size: 8.5, color: const Color(0xFF046A38))),
                    ],
                  ),
                  Text(_fmt(moraInt),
                      style: AppTextStyles.dmSans(
                          size: 12.5,
                          weight: FontWeight.w800,
                          color: const Color(0xFF07543A))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Top Lenders list
        Text('Top Lenders — Education Loans 2025',
            style: AppTextStyles.playfair(
                size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 10),
        Column(
          children: _lenders.map((l) {
            final lRate = l['rate'] as double;
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
                  Text(l['icon'] as String,
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l['name'] as String,
                            style: AppTextStyles.dmSans(
                                size: 12,
                                weight: FontWeight.w800,
                                color: theme.getTextColor(context))),
                        Text(l['desc'] as String,
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
                      Text('${lRate.toStringAsFixed(2)}%',
                          style: AppTextStyles.dmSans(
                              size: 13,
                              weight: FontWeight.w800,
                              color: const Color(0xFFFF6B00))),
                      Text(l['concession'] as String,
                          style: AppTextStyles.dmSans(
                              size: 8.5, color: theme.getMutedColor(context))),
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

  Widget _segButton(String label, String type) {
    final active = _courseType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setCourseType(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFF6B00) : Colors.transparent,
            border: Border.all(
                color: active
                    ? const Color(0xFFFF6B00)
                    : widget.theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
              size: 10.5,
              weight: FontWeight.w800,
              color:
                  active ? Colors.white : widget.theme.getMutedColor(context),
            ),
          ),
        ),
      ),
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

  Widget _timelineBlock(String title, String val, Color bg, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(title.toUpperCase(),
              style: AppTextStyles.dmSans(
                  size: 8.5,
                  weight: FontWeight.w800,
                  color: const Color(0xFF0B1F48)),
              maxLines: 1),
          const SizedBox(height: 2),
          Text(val,
              style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.w800,
                  color: const Color(0xFF0B1F48))),
        ],
      ),
    );
  }

  Widget _lifecycleHBar(
      String label, double val, double maxVal, Color fillCol) {
    final pct = maxVal > 0 ? (val / maxVal).clamp(0.05, 1.0) : 0.05;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTextStyles.dmSans(
                    size: 10,
                    weight: FontWeight.w700,
                    color: widget.theme.getTextColor(context))),
            Text(_fmt(val),
                style: AppTextStyles.dmSans(
                    size: 11,
                    weight: FontWeight.w800,
                    color: const Color(0xFFFF6B00))),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 9,
          width: double.infinity,
          decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(5)),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: pct,
            child: Container(
                decoration: BoxDecoration(
                    color: fillCol, borderRadius: BorderRadius.circular(5))),
          ),
        ),
      ],
    );
  }

  Widget _subsidyRow(String label, String sub, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.dmSans(
                        size: 10.5,
                        weight: FontWeight.w700,
                        color: const Color(0xFF046A38))),
                Text(sub,
                    style: AppTextStyles.dmSans(
                        size: 8.5, color: const Color(0xFF046A38))),
              ],
            ),
          ),
          Text(val,
              style: AppTextStyles.dmSans(
                  size: 10.5,
                  weight: FontWeight.w800,
                  color: const Color(0xFF07543A))),
        ],
      ),
    );
  }

  Widget _resultBox(String label, String value,
      {bool isRed = false, bool isGreen = false, bool isYellow = false}) {
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
                      : isYellow
                          ? const Color(0xFFFFDEA0)
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
}
