// lib/features/india/tools/in_lap_calculator.dart

import 'package:flutter/material.dart';
import 'dart:math' show max, min, pow, pi;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../core/utils/compat.dart';

class INLAPCalculator extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INLAPCalculator({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INLAPCalculator> createState() => _INLAPCalculatorState();
}

class _INLAPCalculatorState extends ConsumerState<INLAPCalculator> {
  // Input states
  double _propVal = 8000000.0;
  double _ltv = 60.0; // 50, 55, 60, 65, 70
  String _propType = 'residential'; // residential, commercial, industrial
  double _roi = 9.25;
  double _tenure = 12.0; // 1 to 15
  double _procFee = 1.0;

  // Controllers
  late TextEditingController _propValCtrl;
  late TextEditingController _roiCtrl;
  late TextEditingController _tenureCtrl;
  late TextEditingController _procFeeCtrl;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultsKey = GlobalKey();

  final List<Map<String, dynamic>> _banks = const [
    {
      'icon': '🏦',
      'name': 'SBI LAP',
      'rate': 9.25,
      'desc': 'PSU Bank · Residential only',
      'ltv': '60%'
    },
    {
      'icon': '🏛️',
      'name': 'HDFC Bank LAP',
      'rate': 9.50,
      'desc': 'Private · Res + Comm',
      'ltv': '60%'
    },
    {
      'icon': '💼',
      'name': 'ICICI Bank LAP',
      'rate': 9.65,
      'desc': 'Private · Floating',
      'ltv': '65%'
    },
    {
      'icon': '⚡',
      'name': 'Axis Bank LAP',
      'rate': 9.75,
      'desc': 'Private · Flexible tenure',
      'ltv': '65%'
    },
    {
      'icon': '🔶',
      'name': 'Bajaj Housing Finance',
      'rate': 9.40,
      'desc': 'NBFC · Commercial ok',
      'ltv': '70%'
    },
    {
      'icon': '🌿',
      'name': 'PNB Housing',
      'rate': 10.10,
      'desc': 'HFC · Ind/Comm allowed',
      'ltv': '60%'
    },
  ];

  final List<Map<String, dynamic>> _rules = const [
    {
      'icon': '📌',
      'title': 'LTV Constraints',
      'desc':
          'Residential properties: max LTV 60% as per RBI norms. Commercial: up to 70%.'
    },
    {
      'icon': '💳',
      'title': 'Interest Rates 2025',
      'desc':
          'LAP rates currently range 9.25% – 12% p.a. depending on credit score and property type.'
    },
    {
      'icon': '⏳',
      'title': 'Tenure & Loan Size',
      'desc': 'Maximum tenure: 15 years. Loan amount: ₹10 Lakh to ₹10 Crore.'
    },
    {
      'icon': '📊',
      'title': 'CIBIL Score',
      'desc':
          'CIBIL score ≥ 700 required. 750+ gets you the best interest rates.'
    },
    {
      'icon': '🧾',
      'title': 'Tax Deductions',
      'desc':
          'Interest on LAP used for business is tax-deductible under Section 37(1) of the Income Tax Act.'
    },
    {
      'icon': '⚙️',
      'title': 'Processing Fees',
      'desc': 'Typically 0.5%–1.5% of loan amount (+ GST @ 18%).'
    },
  ];

  @override
  void initState() {
    super.initState();
    _propValCtrl = TextEditingController(text: _propVal.toStringAsFixed(0));
    _roiCtrl = TextEditingController(text: _roi.toStringAsFixed(2));
    _tenureCtrl = TextEditingController(text: _tenure.toStringAsFixed(0));
    _procFeeCtrl = TextEditingController(text: _procFee.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _propValCtrl.dispose();
    _roiCtrl.dispose();
    _tenureCtrl.dispose();
    _procFeeCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _propVal = 8000000.0;
      _ltv = 60.0;
      _propType = 'residential';
      _roi = 9.25;
      _tenure = 12.0;
      _procFee = 1.0;

      _propValCtrl.text = '8000000';
      _roiCtrl.text = '9.25';
      _tenureCtrl.text = '12';
      _procFeeCtrl.text = '1.0';
    });
  }

  double _calcEMI(double p, double ratePA, int termMonths) {
    if (p <= 0 || ratePA <= 0) return 0;
    final r = ratePA / (12 * 100);
    return p * r * pow(1 + r, termMonths) / (pow(1 + r, termMonths) - 1);
  }

  String _fmt(double n) {
    return '₹${n.round().toLocaleString()}';
  }

  String _fmtShort(double n) {
    if (n >= 10000000) return '${(n / 10000000).toStringAsFixed(1)}Cr';
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    return n.round().toLocaleString();
  }

  void _saveCalculation() async {
    final loan = _propVal * (_ltv / 100.0);
    final emi = _calcEMI(loan, _roi, (_tenure * 12).toInt());
    final totalPay = emi * _tenure * 12;
    final totalInt = totalPay - loan;
    final fee = loan * (_procFee / 100.0);

    final labelCtrl = TextEditingController(text: 'LAP Calculation');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/in_lap_calculator'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save LAP Calculation',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving: EMI ${_fmt(emi)}/mo · Loan ${_fmt(loan)}',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Office LAP)',
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
          : 'LAP Calculation';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'LAP Calculator',
        inputs: {
          'propVal': _propVal,
          'ltv': _ltv,
          'roi': _roi,
          'tenure': _tenure,
          'procFee': _procFee,
        },
        results: {
          'emi': emi,
          'loanAmt': loan,
          'totalInterest': totalInt,
          'totalOutflow': totalPay + fee,
          'procFee': fee,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ LAP calculation saved!',
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

    // Proactive calculations
    final loan = _propVal * (_ltv / 100.0);
    final emi = _calcEMI(loan, _roi, (_tenure * 12).toInt());
    final totalPay = emi * _tenure * 12;
    final totalInt = totalPay - loan;
    final fee = loan * (_procFee / 100.0);
    final totalOutflow = totalPay + fee;

    final pPct = totalOutflow > 0 ? (loan / totalOutflow) : 0.0;

    // Yearly projections
    final rMonthly = _roi / 1200;
    double tempBal = loan;
    final List<Map<String, double>> yearBreakdown = [];
    final totalYears = _tenure.ceil();
    for (int y = 1; y <= totalYears; y++) {
      double yInt = 0;
      double yPrin = 0;
      for (int m = 0; m < 12; m++) {
        if (tempBal <= 0.05) break;
        final ip = tempBal * rMonthly;
        final pp = min(emi - ip, tempBal);
        yInt += ip;
        yPrin += pp;
        tempBal -= pp;
      }
      yearBreakdown
          .add({'principal': yPrin, 'interest': yInt, 'balance': tempBal});
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Info
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1F48).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoCell('LAP Rate', '9.25%', 'SBI 2025', context),
              _verticalDivider(),
              _infoCell('Max LTV', '60%', 'Residential', context,
                  isGreen: true),
              _verticalDivider(),
              _infoCell('Max Tenure', '15 yr', 'Standard', context),
              _verticalDivider(),
              _infoCell('Processing', '1%', 'Avg Fee', context),
            ],
          ),
        ),

        // Inputs Card (Hero LAP style)
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
                  Text('भारत · LAP PARAMETERS',
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

              // Property Market Value
              _buildSyncedInputRow(
                label: 'PROPERTY MARKET VALUE',
                controller: _propValCtrl,
                value: _propVal,
                min: 1000000.0,
                max: 100000000.0,
                prefix: '₹ ',
                onChangedText: (val) {
                  setState(() {
                    _propVal = val;
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _propVal = val;
                    _propValCtrl.text = val.toStringAsFixed(0);
                  });
                },
              ),
              const SizedBox(height: 12),

              // LTV and Property Type Selector row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LTV RATIO',
                            style: AppTextStyles.dmSans(
                                size: 8.5,
                                color: theme.getMutedColor(context),
                                weight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: theme.getBgColor(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: theme.getBorderColor(context)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<double>(
                              value: _ltv,
                              isExpanded: true,
                              dropdownColor: theme.getCardColor(context),
                              style: AppTextStyles.dmSans(
                                  size: 12,
                                  color: theme.getTextColor(context),
                                  weight: FontWeight.w700),
                              items: const [
                                DropdownMenuItem(
                                    value: 50.0, child: Text('50% - Cons.')),
                                DropdownMenuItem(
                                    value: 55.0, child: Text('55%')),
                                DropdownMenuItem(
                                    value: 60.0, child: Text('60% - Std')),
                                DropdownMenuItem(
                                    value: 65.0, child: Text('65% - High')),
                                DropdownMenuItem(
                                    value: 70.0, child: Text('70% - Max')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _ltv = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PROPERTY TYPE',
                            style: AppTextStyles.dmSans(
                                size: 8.5,
                                color: theme.getMutedColor(context),
                                weight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: theme.getBgColor(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: theme.getBorderColor(context)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _propType,
                              isExpanded: true,
                              dropdownColor: theme.getCardColor(context),
                              style: AppTextStyles.dmSans(
                                  size: 12,
                                  color: theme.getTextColor(context),
                                  weight: FontWeight.w700),
                              items: const [
                                DropdownMenuItem(
                                    value: 'residential',
                                    child: Text('Residential')),
                                DropdownMenuItem(
                                    value: 'commercial',
                                    child: Text('Commercial')),
                                DropdownMenuItem(
                                    value: 'industrial',
                                    child: Text('Industrial')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _propType = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Synced input-slider: Interest Rate
              _buildSyncedInputRow(
                label: 'INTEREST RATE (% P.A.)',
                controller: _roiCtrl,
                value: _roi,
                min: 8.0,
                max: 18.0,
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

              // Synced input-slider: Tenure (Years)
              _buildSyncedInputRow(
                label: 'TENURE (YEARS)',
                controller: _tenureCtrl,
                value: _tenure,
                min: 1.0,
                max: 15.0,
                suffix: ' yrs',
                onChangedText: (val) {
                  setState(() {
                    _tenure = val;
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _tenure = val;
                    _tenureCtrl.text = val.toStringAsFixed(0);
                  });
                },
              ),
              const SizedBox(height: 12),

              // Synced input-slider: Processing Fee
              _buildSyncedInputRow(
                label: 'PROCESSING FEE (%)',
                controller: _procFeeCtrl,
                value: _procFee,
                min: 0.0,
                max: 3.0,
                suffix: '%',
                onChangedText: (val) {
                  setState(() {
                    _procFee = val;
                  });
                },
                onChangedSlider: (val) {
                  setState(() {
                    _procFee = val;
                    _procFeeCtrl.text = val.toStringAsFixed(1);
                  });
                },
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _scrollToResults,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('📊 Calculate LAP EMI & View Projections',
                    style: AppTextStyles.dmSans(
                        size: 13,
                        color: Colors.white,
                        weight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Result panel
        Container(
          key: _resultsKey,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.getBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('📊 LAP Calculation Result',
                      style: AppTextStyles.dmSans(
                          size: 13,
                          weight: FontWeight.w800,
                          color: theme.getTextColor(context))),
                  ElevatedButton.icon(
                    onPressed: _saveCalculation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF046A38),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.save, size: 12, color: Colors.white),
                    label: Text('Save',
                        style: AppTextStyles.dmSans(
                            size: 10,
                            color: Colors.white,
                            weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Result grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.8,
                children: [
                  _resultBox('Monthly EMI', _fmt(emi),
                      isHighlighted: true, context: context),
                  _resultBox('Loan Amount', _fmt(loan), context: context),
                  _resultBox('Total Interest', _fmt(totalInt),
                      context: context),
                  _resultBox('Total Outflow', _fmt(totalOutflow),
                      context: context),
                  _resultBox('Processing Fee', _fmt(fee), context: context),
                  _resultBox('Interest to Loan Ratio',
                      '${(totalInt / loan).toStringAsFixed(2)}x',
                      context: context),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // Donut Chart Composition
              Text('🥧 Principal vs Interest Breakdown',
                  style: AppTextStyles.dmSans(
                      size: 10.5,
                      color: theme.getMutedColor(context),
                      weight: FontWeight.w800)),
              const SizedBox(height: 14),
              Row(
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CustomPaint(
                      painter: _DonutChartPainter(
                        v1: loan,
                        v2: totalInt,
                        v3: fee,
                        c1: const Color(0xFF046A38),
                        c2: const Color(0xFFFF6B00),
                        c3: const Color(0xFF1A3A8F),
                        centerLabel: '${(pPct * 100).round()}%',
                        textColor: theme.getTextColor(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        _legendRow(
                            const Color(0xFF046A38), 'Principal', _fmt(loan)),
                        const SizedBox(height: 6),
                        _legendRow(const Color(0xFFFF6B00), 'Interest',
                            _fmt(totalInt)),
                        const SizedBox(height: 6),
                        _legendRow(const Color(0xFF1A3A8F), 'Fees', _fmt(fee)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // Outstanding balance progression
              Text('📅 Yearly Outstanding Balance',
                  style: AppTextStyles.dmSans(
                      size: 10.5,
                      color: theme.getMutedColor(context),
                      weight: FontWeight.w800)),
              const SizedBox(height: 14),
              Column(
                children: yearBreakdown.asMap().entries.map((entry) {
                  final yIdx = entry.key + 1;
                  final yBal = entry.value['balance']!;
                  final double barWidthPct = loan > 0 ? (yBal / loan) : 0.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 36,
                            child: Text('Yr $yIdx',
                                style: AppTextStyles.dmSans(
                                    size: 9.5,
                                    color: theme.getMutedColor(context)))),
                        Expanded(
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B00)
                                  .withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: max(0.02, barWidthPct),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [
                                    Color(0xFF1A3A8F),
                                    Color(0xFFFF6B00)
                                  ]),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_fmtShort(yBal),
                            style: AppTextStyles.dmSans(
                                size: 9.5,
                                color: theme.getTextColor(context),
                                weight: FontWeight.w700)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Best LAP Rates
        Text('Best LAP Rates — Banks 2025',
            style: AppTextStyles.playfair(
                size: 15,
                color: theme.getTextColor(context),
                weight: FontWeight.w800)),
        const SizedBox(height: 10),
        Column(
          children: _banks
              .map((b) => _bankItemRow(b['icon'], b['name'], b['desc'],
                  '${b['rate']}%', b['ltv'], context))
              .toList(),
        ),
        const SizedBox(height: 20),

        // India LAP Guidelines Facts Card
        Text('Key LAP Facts — India 2025',
            style: AppTextStyles.playfair(
                size: 15,
                color: theme.getTextColor(context),
                weight: FontWeight.w800)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: _rules
                .map((r) => _ruleRow(r['icon'], r['title'], r['desc'], context))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _infoCell(
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
                  weight: FontWeight.w700)),
          const SizedBox(height: 3),
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
          const SizedBox(height: 2),
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

  Widget _resultBox(String label, String value,
      {bool isHighlighted = false, required BuildContext context}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isHighlighted
            ? (isDark ? const Color(0xFF0B1F48) : const Color(0xFFE0F2FE))
            : widget.theme.getBgColor(context),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFFFF6B00).withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: AppTextStyles.dmSans(
                  size: 8, color: widget.theme.getMutedColor(context)),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.dmSans(
                  size: 14,
                  weight: FontWeight.w800,
                  color: isHighlighted
                      ? const Color(0xFFFF6B00)
                      : widget.theme.getTextColor(context)),
              textAlign: TextAlign.center),
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
                      size: 10, color: widget.theme.getTextColor(context))),
              Text(value,
                  style: AppTextStyles.dmSans(
                      size: 11,
                      weight: FontWeight.w800,
                      color: widget.theme.getTextColor(context))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bankItemRow(String icon, String name, String desc, String rate,
      String bankLtv, BuildContext context) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.dmSans(
                        size: 12,
                        weight: FontWeight.w800,
                        color: theme.getTextColor(context))),
                Text(desc,
                    style: AppTextStyles.dmSans(
                        size: 9.5, color: theme.getMutedColor(context))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rate,
                  style: AppTextStyles.dmSans(
                      size: 15,
                      weight: FontWeight.w800,
                      color: const Color(0xFFFF6B00))),
              Text('Up to $bankLtv LTV',
                  style: AppTextStyles.dmSans(
                      size: 8, color: theme.getMutedColor(context))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ruleRow(
      String icon, String title, String desc, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.dmSans(
                        size: 11.5,
                        weight: FontWeight.w800,
                        color: widget.theme.getTextColor(context))),
                const SizedBox(height: 2),
                Text(desc,
                    style: AppTextStyles.dmSans(
                        size: 9.5,
                        color: widget.theme.getMutedColor(context),
                        height: 1.35)),
              ],
            ),
          ),
        ],
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
        text: 'Principal',
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
