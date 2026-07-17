// lib/features/india/tools/in_under_construction.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class INUnderConstruction extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INUnderConstruction({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INUnderConstruction> createState() => _INUnderConstructionState();
}

class _INUnderConstructionState extends ConsumerState<INUnderConstruction> {
  late TextEditingController _propValController;
  late TextEditingController _downPctController;
  late TextEditingController _rateController;
  late TextEditingController _tenureController;
  late TextEditingController _consPeriodController;

  String _disburseMode = 'uniform'; // 'uniform', 'milestone', 'tranche'

  bool _propValError = false;
  bool _downPctError = false;
  bool _rateError = false;
  bool _tenureError = false;
  bool _consPeriodError = false;

  bool _hasCalculated = false;
  double _calcPropVal = 7500000;
  double _calcDownPct = 20;
  double _calcRate = 8.50;
  int _calcTenure = 20;
  int _calcConsPeriod = 30;
  String _calcDisburseMode = 'uniform';
  final GlobalKey _resultsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _propValController = TextEditingController(text: '7500000');
    _downPctController = TextEditingController(text: '20');
    _rateController = TextEditingController(text: '8.50');
    _tenureController = TextEditingController(text: '20');
    _consPeriodController = TextEditingController(text: '30');

    // Add listeners to trigger state updates for calculations
    _propValController.addListener(_onInputChanged);
    _downPctController.addListener(_onInputChanged);
    _rateController.addListener(_onInputChanged);
    _tenureController.addListener(_onInputChanged);
    _consPeriodController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _propValController.removeListener(_onInputChanged);
    _downPctController.removeListener(_onInputChanged);
    _rateController.removeListener(_onInputChanged);
    _tenureController.removeListener(_onInputChanged);
    _consPeriodController.removeListener(_onInputChanged);

    _propValController.dispose();
    _downPctController.dispose();
    _rateController.dispose();
    _tenureController.dispose();
    _consPeriodController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    setState(() {});
  }

  bool _areInputsChanged() {
    final pv = double.tryParse(_propValController.text.replaceAll(',', '')) ?? 0.0;
    final dp = double.tryParse(_downPctController.text) ?? 0.0;
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    final tenure = int.tryParse(_tenureController.text) ?? 1;
    final cons = int.tryParse(_consPeriodController.text) ?? 1;
    return pv != _calcPropVal ||
        dp != _calcDownPct ||
        rate != _calcRate ||
        tenure != _calcTenure ||
        cons != _calcConsPeriod ||
        _disburseMode != _calcDisburseMode;
  }

  void _reset() {
    setState(() {
      _propValController.text = '7500000';
      _downPctController.text = '20';
      _rateController.text = '8.50';
      _tenureController.text = '20';
      _consPeriodController.text = '30';
      _disburseMode = 'uniform';
      _hasCalculated = false;
      _propValError = false;
      _downPctError = false;
      _rateError = false;
      _tenureError = false;
      _consPeriodError = false;
      _calcPropVal = 7500000;
      _calcDownPct = 20;
      _calcRate = 8.50;
      _calcTenure = 20;
      _calcConsPeriod = 30;
      _calcDisburseMode = 'uniform';
    });
  }

  double _calcEMI(double p, double r, int n) {
    if (r <= 0 || n <= 0) return 0.0;
    final double power = pow(1 + r, n).toDouble();
    if (power <= 1.0) return 0.0;
    return p * r * power / (power - 1);
  }

  String _fmt(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(2)} L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }

  String _fmtShort(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)}Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)}L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }

  void _saveCalculation() async {
    final pv = _calcPropVal;
    final dp = _calcDownPct;
    final rate = _calcRate;
    final tenure = _calcTenure;
    final cons = _calcConsPeriod;

    final loan = pv * (1 - dp / 100);
    final r = rate / 12 / 100;
    final n = tenure * 12;
    final emi = _calcEMI(loan, r, n);
    final avgDisb = _calcDisburseMode == 'uniform' ? loan * 0.5 : (_calcDisburseMode == 'milestone' ? loan * 0.45 : loan * 0.55);
    final avgPreEmi = avgDisb * r;
    final preEmiTotal = avgPreEmi * cons;
    final totalInterest = emi * n - loan;
    final totalPay = preEmiTotal + emi * n;

    final labelCtrl = TextEditingController(text: 'Under Construction Loan');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/in_under_construction'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Project Plan', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving: Total Pay ${_fmt(totalPay)} · Pre-EMI Total ${_fmt(preEmiTotal)}',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Pre-EMI plan for flat)',
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
              backgroundColor: const Color(0xFFFF6B00),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save', style: AppTextStyles.dmSans(size: 12, color: Colors.white, weight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'Under Construction Loan';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'Under Construction',
        inputs: {
          'propVal': pv,
          'downPct': dp,
          'rate': rate,
          'tenure': tenure.toDouble(),
          'consPeriod': cons.toDouble(),
          'disburseMode': _calcDisburseMode == 'uniform' ? 0.0 : _calcDisburseMode == 'milestone' ? 1.0 : 2.0,
        },
        results: {
          'loan': loan,
          'emi': emi,
          'preEmiTotal': preEmiTotal,
          'totalInterest': totalInterest,
          'totalPayable': totalPay,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Project plan saved!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
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

    final pv = double.tryParse(_propValController.text.replaceAll(',', '')) ?? 0.0;
    final dp = double.tryParse(_downPctController.text) ?? 0.0;
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    final tenure = int.tryParse(_tenureController.text) ?? 1;
    final cons = int.tryParse(_consPeriodController.text) ?? 1;

    final calcPropVal = _calcPropVal;
    final calcDownPct = _calcDownPct;
    final calcRate = _calcRate;
    final calcTenure = _calcTenure;
    final calcConsPeriod = _calcConsPeriod;

    final loan = calcPropVal * (1 - calcDownPct / 100);
    final r = calcRate / 12 / 100;
    final n = calcTenure * 12;
    final emi = _calcEMI(loan, r, n);

    final avgDisb = _calcDisburseMode == 'uniform' ? loan * 0.5 : (_calcDisburseMode == 'milestone' ? loan * 0.45 : loan * 0.55);
    final avgPreEmi = avgDisb * r;
    final preEmiTotal = avgPreEmi * calcConsPeriod;
    final totalInterest = emi * n - loan;
    final gst = calcPropVal * 0.05; // 5% GST
    final totalPayable = preEmiTotal + emi * n;
    final totalOutgoSum = loan + preEmiTotal + totalInterest + gst;

    final phases = [0.10, 0.20, 0.20, 0.25, 0.25];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Rate Strip Card
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
              _buildRateStripItem('Repo Rate', '6.25%', "RBI Jun'25", isFirst: true),
              _buildRateStripItem('SBI Rate', '8.50%', 'Floating'),
              _buildRateStripItem('GST', '5%', 'UC Property'),
              _buildRateStripItem('Max Tenure', '30yr', 'Home Loan'),
            ],
          ),
        ),

        // Section header
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Loan Setup', style: AppTextStyles.sectionLabel(theme.getMutedColor(context))),
              GestureDetector(
                onTap: _reset,
                child: Text('Reset ↺', style: AppTextStyles.dmSans(size: 11, color: const Color(0xFFFF6B00), weight: FontWeight.w700)),
              ),
            ],
          ),
        ),

        // Inputs Card
        Container(
          padding: const EdgeInsets.all(18),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Value
              _buildSyncSliderRow(
                title: 'Total Property Value',
                controller: _propValController,
                min: 500000,
                max: 30000000,
                divisions: 295,
                displayValue: _fmt(pv),
                hasError: _propValError,
              ),
              const SizedBox(height: 16),
              // Down Payment
              _buildSyncSliderRow(
                title: 'Down Payment (%)',
                controller: _downPctController,
                min: 10,
                max: 40,
                divisions: 30,
                displayValue: '${dp.toStringAsFixed(0)}%',
                hasError: _downPctError,
              ),
              const SizedBox(height: 16),
              // Interest Rate
              _buildSyncSliderRow(
                title: 'Interest Rate (% p.a.)',
                controller: _rateController,
                min: 7.00,
                max: 13.00,
                divisions: 120,
                displayValue: '${rate.toStringAsFixed(2)}%',
                hasError: _rateError,
              ),
              const SizedBox(height: 16),
              // Loan Tenure
              _buildSyncSliderRow(
                title: 'Loan Tenure (Years)',
                controller: _tenureController,
                min: 5,
                max: 30,
                divisions: 25,
                displayValue: '$tenure yr',
                hasError: _tenureError,
              ),
              const SizedBox(height: 16),
              // Construction Period
              _buildSyncSliderRow(
                title: 'Construction Period (Months)',
                controller: _consPeriodController,
                min: 6,
                max: 60,
                divisions: 54,
                displayValue: '$cons mo',
                hasError: _consPeriodError,
              ),
              const SizedBox(height: 16),

              // Disbursement Schedule toggles
              Text('DISBURSEMENT SCHEDULE', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.w800)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildToggleBtn('Uniform', _disburseMode == 'uniform', () => setState(() => _disburseMode = 'uniform'))),
                  const SizedBox(width: 6),
                  Expanded(child: _buildToggleBtn('Milestone', _disburseMode == 'milestone', () => setState(() => _disburseMode = 'milestone'))),
                  const SizedBox(width: 6),
                  Expanded(child: _buildToggleBtn('3-Tranche', _disburseMode == 'tranche', () => setState(() => _disburseMode = 'tranche'))),
                ],
              ),
              const SizedBox(height: 20),

              // Calculate Button
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _propValError = false;
                    _downPctError = false;
                    _rateError = false;
                    _tenureError = false;
                    _consPeriodError = false;
                  });

                  final pvVal = double.tryParse(_propValController.text.replaceAll(',', ''));
                  final dpVal = double.tryParse(_downPctController.text);
                  final rateVal = double.tryParse(_rateController.text);
                  final tenureVal = int.tryParse(_tenureController.text);
                  final consVal = int.tryParse(_consPeriodController.text);

                  bool hasErr = false;
                  if (pvVal == null || pvVal <= 0) {
                    setState(() => _propValError = true);
                    hasErr = true;
                  }
                  if (dpVal == null || dpVal < 0 || dpVal > 100) {
                    setState(() => _downPctError = true);
                    hasErr = true;
                  }
                  if (rateVal == null || rateVal <= 0 || rateVal > 100) {
                    setState(() => _rateError = true);
                    hasErr = true;
                  }
                  if (tenureVal == null || tenureVal <= 0 || tenureVal > 40) {
                    setState(() => _tenureError = true);
                    hasErr = true;
                  }
                  if (consVal == null || consVal <= 0 || consVal > 120) {
                    setState(() => _consPeriodError = true);
                    hasErr = true;
                  }

                  if (hasErr) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('⚠️ Please correct the invalid fields in red.', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
                        backgroundColor: Colors.red[800],
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  setState(() {
                    _hasCalculated = true;
                    _calcPropVal = pvVal!;
                    _calcDownPct = dpVal!;
                    _calcRate = rateVal!;
                    _calcTenure = tenureVal!;
                    _calcConsPeriod = consVal!;
                    _calcDisburseMode = _disburseMode;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('⚡ Plan calculated!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
                      backgroundColor: const Color(0xFF046A38),
                      duration: const Duration(milliseconds: 600),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_resultsKey.currentContext != null) {
                      Scrollable.ensureVisible(
                        _resultsKey.currentContext!,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    }
                  });
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
                    '☸ Calculate Pre-EMI & Full EMI',
                    style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_hasCalculated) ...[
          const SizedBox(height: 20),
          // Warning banner if inputs changed
          if (_areInputsChanged())
            Container(
              key: _resultsKey,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: isDark ? 0.2 : 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Text('⚠️ ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(
                      'Inputs changed. Tap Calculate to update results.',
                      style: AppTextStyles.dmSans(size: 11, color: isDark ? Colors.amber[200]! : Colors.amber[900]!, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(key: _resultsKey, height: 0),

          // Results Card (6-grid)
          Container(
            padding: const EdgeInsets.all(18),
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
                Text(
                  'CALCULATION RESULTS',
                  style: AppTextStyles.dmSans(size: 9, color: Colors.white60, weight: FontWeight.w700, letterSpacing: 0.5),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.8,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    _buildResultBox('Loan Amount', _fmt(loan), '80% of value', true),
                    _buildResultBox('Full EMI', "₹${NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(emi)}", 'Post-possession', false),
                    _buildResultBox('Avg Pre-EMI', "₹${NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(avgPreEmi)}", 'During construction', true),
                    _buildResultBox('Pre-EMI Total', _fmt(preEmiTotal), 'Interest only cost', false),
                    _buildResultBox('Total Interest', _fmt(totalInterest), 'Full tenure', false),
                    _buildResultBox('Total Payable', _fmt(totalPayable), 'Principal + Interest', false, isGreen: true),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Cost Comparison Breakup Bar Chart
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Cost Comparison Breakup', style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context))),
                    Text('UC Property', style: AppTextStyles.dmSans(size: 10, color: const Color(0xFFFF6B00), weight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildChartRow('Principal', loan, totalOutgoSum, const LinearGradient(colors: [Color(0xFF1A3A8F), Color(0xFF0B1F48)])),
                const Divider(height: 18),
                _buildChartRow('Pre-EMI Int.', preEmiTotal, totalOutgoSum, const LinearGradient(colors: [Color(0xFFFFEA00), Color(0xFFFF6B00)])),
                const Divider(height: 18),
                _buildChartRow('Post-EMI Int.', totalInterest, totalOutgoSum, const LinearGradient(colors: [Color(0xFFFF6B00), Color(0xFFE05F00)])),
                const Divider(height: 18),
                _buildChartRow('GST (5%)', gst, totalOutgoSum, const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0F766E)])),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Disbursement Milestone Timeline
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📋 Disbursement Phases', style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context))),
                const SizedBox(height: 16),
                _buildMilestoneRow(
                  icon: '✓',
                  title: 'Phase 1 – Foundation',
                  subText: '10% disbursed on booking · Month 1',
                  amount: loan * phases[0],
                  percent: '10%',
                  isCompleted: true,
                ),
                _buildMilestoneRow(
                  icon: '🏗️',
                  title: 'Phase 2 – Plinth / Slab',
                  subText: '20% disbursed · Month 8–10',
                  amount: loan * phases[1],
                  percent: '20%',
                ),
                _buildMilestoneRow(
                  icon: '🧱',
                  title: 'Phase 3 – Structure',
                  subText: '20% disbursed · Month 14–18',
                  amount: loan * phases[2],
                  percent: '20%',
                ),
                _buildMilestoneRow(
                  icon: '🏠',
                  title: 'Phase 4 – Roofing / Brick',
                  subText: '25% disbursed · Month 20–24',
                  amount: loan * phases[3],
                  percent: '25%',
                ),
                _buildMilestoneRow(
                  icon: '🔑',
                  title: 'Phase 5 – Possession',
                  subText: '25% final disbursement · Month 28–30',
                  amount: loan * phases[4],
                  percent: '25%',
                  isLast: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Info Tip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: const Color(0xFF6EE7B7), width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.dmSans(size: 10.5, color: const Color(0xFF07543A)),
                      children: const [
                        TextSpan(
                          text: 'RBI Rule: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: 'Banks disburse in stages linked to construction milestones. Pre-EMI is interest-only on disbursed amount. Full EMI starts after possession. GST @ 5% applies to under-construction properties; nil for ready-to-move. RERA registration is mandatory per Real Estate Act 2016.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Save Button
          ElevatedButton.icon(
            onPressed: _saveCalculation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF046A38),
              shadowColor: const Color(0xFF046A38).withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            icon: const Text('💾', style: TextStyle(fontSize: 16)),
            label: Center(
              child: Text(
                'Save This Calculation',
                style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // --- Widget Builders ---

  Widget _buildSyncSliderRow({
    required String title,
    required TextEditingController controller,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    bool hasError = false,
  }) {
    final theme = widget.theme;
    final currentVal = double.tryParse(controller.text) ?? min;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFF5E6D4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title.toUpperCase(),
              style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context), weight: FontWeight.w800),
            ),
            Text(
              displayValue,
              style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  activeTrackColor: const Color(0xFFFF6B00),
                  inactiveTrackColor: inactiveColor,
                  thumbColor: const Color(0xFFFF6B00),
                  overlayColor: const Color(0xFFFF6B00).withValues(alpha: 0.15),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                ),
                child: Slider(
                  value: currentVal.clamp(min, max),
                  min: min,
                  max: max,
                  divisions: divisions,
                  onChanged: (val) {
                    setState(() {
                      controller.text = min is int ? val.round().toString() : val.toStringAsFixed(2);
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              height: 32,
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: theme.getTextColor(context)),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  filled: true,
                  fillColor: theme.getBgColor(context),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: hasError ? Colors.red : theme.getBorderColor(context),
                      width: hasError ? 1.5 : 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(
                      color: hasError ? Colors.red : const Color(0xFFFF6B00),
                      width: hasError ? 2.0 : 1.5,
                    ),
                  ),
                ),
                onSubmitted: (val) {
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFF6B00) : Colors.transparent,
          border: Border.all(color: active ? const Color(0xFFFF6B00) : widget.theme.getBorderColor(context)),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 10.5,
            weight: FontWeight.w700,
            color: active ? Colors.white : widget.theme.getMutedColor(context),
          ),
        ),
      ),
    );
  }

  Widget _buildResultBox(String label, String value, String note, bool isHi, {bool isGreen = false}) {
    Color valColor = Colors.white;
    if (isGreen) {
      valColor = const Color(0xFF86EFAC);
    } else if (isHi) {
      valColor = const Color(0xFFFFDEA0);
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.dmSans(size: 8, color: Colors.white54, weight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.dmSans(size: 13.5, weight: FontWeight.w800, color: valColor),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            note,
            style: AppTextStyles.dmSans(size: 8.5, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildChartRow(String label, double value, double total, LinearGradient barGrad) {
    final theme = widget.theme;
    final pct = total > 0 ? (value / total * 100) : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context), weight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (pct / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: barGrad,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(
            _fmtShort(value),
            style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: theme.getTextColor(context)),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneRow({
    required String icon,
    required String title,
    required String subText,
    required double amount,
    required String percent,
    bool isCompleted = false,
    bool isLast = false,
  }) {
    final theme = widget.theme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: isCompleted
                      ? const LinearGradient(colors: [Color(0xFF046A38), Color(0xFF07543A)])
                      : LinearGradient(colors: [Colors.grey[400]!, Colors.grey[500]!]),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  icon,
                  style: TextStyle(
                    fontSize: 12,
                    color: isCompleted ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? const Color(0xFFFF6B00) : Colors.grey[300],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subText,
                    style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmtShort(amount),
                style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: const Color(0xFFFF6B00)),
              ),
              Text(
                percent,
                style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context)),
              ),
            ],
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
}
