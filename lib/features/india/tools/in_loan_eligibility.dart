// lib/features/india/tools/in_loan_eligibility.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class SemiCircleGaugePainter extends CustomPainter {
  final double percentage; // 0.0 to 1.0
  final Color activeColor;

  SemiCircleGaugePainter({required this.percentage, required this.activeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 4);
    final radius = size.width / 2 - 8;

    // Background track arc
    final bgPaint = Paint()
      ..color = const Color(0xFFF5E6D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi, // Starts at 180 degrees
      pi, // Sweep angle is 180 degrees
      false,
      bgPaint,
    );

    // Active arc
    if (percentage > 0) {
      final activePaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        pi,
        pi * percentage.clamp(0.01, 1.0),
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SemiCircleGaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.activeColor != activeColor;
  }
}

class INLoanEligibility extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INLoanEligibility({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INLoanEligibility> createState() => _INLoanEligibilityState();
}

class _INLoanEligibilityState extends ConsumerState<INLoanEligibility> {
  late TextEditingController _monthlyIncomeController;
  late TextEditingController _existingEmiController;
  late TextEditingController _rateController;
  late TextEditingController _tenureController;

  int _cibilScore = 750; // 650, 700, 750, 800
  String _empType = 'salaried'; // 'salaried', 'self_employed'

  @override
  void initState() {
    super.initState();
    _monthlyIncomeController = TextEditingController(text: '100000');
    _existingEmiController = TextEditingController(text: '10000');
    _rateController = TextEditingController(text: '8.50');
    _tenureController = TextEditingController(text: '20');

    _monthlyIncomeController.addListener(_onInputChanged);
    _existingEmiController.addListener(_onInputChanged);
    _rateController.addListener(_onInputChanged);
    _tenureController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _monthlyIncomeController.removeListener(_onInputChanged);
    _existingEmiController.removeListener(_onInputChanged);
    _rateController.removeListener(_onInputChanged);
    _tenureController.removeListener(_onInputChanged);

    _monthlyIncomeController.dispose();
    _existingEmiController.dispose();
    _rateController.dispose();
    _tenureController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    setState(() {});
  }

  void _reset() {
    setState(() {
      _monthlyIncomeController.text = '100000';
      _existingEmiController.text = '10000';
      _rateController.text = '8.50';
      _tenureController.text = '20';
      _cibilScore = 750;
      _empType = 'salaried';
    });
  }

  String _fmt(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)} Lakh';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }

  String _fmtShort(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)}Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)}L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }

  void _saveCalculation() async {
    final income = double.tryParse(_monthlyIncomeController.text) ?? 100000;
    final existEmi = double.tryParse(_existingEmiController.text) ?? 10000;
    final rate = double.tryParse(_rateController.text) ?? 8.50;
    final tenure = int.tryParse(_tenureController.text) ?? 20;

    final foirLimit = _empType == 'salaried' ? 0.50 : 0.45;
    final maxEmi = income * foirLimit;
    final availEmi = maxEmi - existEmi;
    final r = rate / 12 / 100;
    final n = tenure * 12;
    final eligLoan = availEmi > 0 && r > 0 ? availEmi * (pow(1 + r, n) - 1) / (r * pow(1 + r, n)) : 0.0;
    final actualFoir = income > 0 ? (existEmi / income) * 100 : 0.0;

    final labelCtrl = TextEditingController(text: 'Eligibility Report');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/in_loan_eligibility'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Eligibility Report', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving: Eligible ${_fmt(eligLoan)} · FOIR ${actualFoir.toStringAsFixed(1)}%',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My Eligibility Profile)',
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
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'Eligibility Report';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'Loan Eligibility',
        inputs: {
          'monthlyIncome': income,
          'existingEmi': existEmi,
          'rate': rate,
          'tenureYears': tenure.toDouble(),
          'empType': _empType == 'salaried' ? 0.0 : 1.0,
          'cibil': _cibilScore.toDouble(),
        },
        results: {
          'eligibleLoan': eligLoan,
          'foir': actualFoir,
          'maxEmi': maxEmi,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Eligibility plan saved!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
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

    final income = double.tryParse(_monthlyIncomeController.text) ?? 0.0;
    final existEmi = double.tryParse(_existingEmiController.text) ?? 0.0;
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    final tenure = int.tryParse(_tenureController.text) ?? 1;

    final foirLimit = _empType == 'salaried' ? 0.50 : 0.45;
    final maxEmi = income * foirLimit;
    final availEmi = maxEmi - existEmi;
    final r = rate / 12 / 100;
    final n = tenure * 12;
    final eligLoan = availEmi > 0 && r > 0 ? availEmi * (pow(1 + r, n) - 1) / (r * pow(1 + r, n)) : 0.0;
    final actualFoir = income > 0 ? (existEmi / income) * 100 : 0.0;

    String statusText;
    Color statusColor;

    if (actualFoir <= 40) {
      statusText = '✅ Excellent (≤40%)';
      statusColor = const Color(0xFF046A38);
    } else if (actualFoir <= 50) {
      statusText = '✅ Safe Limit (≤50%)';
      statusColor = const Color(0xFF046A38);
    } else if (actualFoir <= 60) {
      statusText = '⚠️ Borderline – Reduce obligations';
      statusColor = const Color(0xFFD97706);
    } else {
      statusText = '❌ High FOIR – Rejection likely';
      statusColor = const Color(0xFFDC2626);
    }

    String eligTag;
    Color eligTagBg;
    Color eligTagFg;
    String eligStatusStr = 'Eligible';

    if (eligLoan > 5000000) {
      eligTag = 'Strong Eligibility';
      eligTagBg = const Color(0xFFD1FAE5);
      eligTagFg = const Color(0xFF065F46);
      eligStatusStr = '✅ Strong';
    } else if (eligLoan > 2000000) {
      eligTag = 'Moderate Eligibility';
      eligTagBg = const Color(0xFFFEF3C7);
      eligTagFg = const Color(0xFF92400E);
      eligStatusStr = '⚠️ Moderate';
    } else {
      eligTag = 'Low Eligibility';
      eligTagBg = const Color(0xFFFEE2E2);
      eligTagFg = const Color(0xFF991B1B);
      eligStatusStr = '❌ Low';
    }

    const maxPossibleLoan = 10000000.0; // ₹1Cr
    final fillPct = maxPossibleLoan > 0 ? (eligLoan / maxPossibleLoan * 100).clamp(0.0, 100.0) : 0.0;

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
              _buildRateStripItem('Max FOIR', '50%', 'RBI Norm', isFirst: true),
              _buildRateStripItem('SBI Rate', '8.50%', 'Floating'),
              _buildRateStripItem('Max LTV', '90%', '≤30L Prop'),
              _buildRateStripItem('Min CIBIL', '700+', 'Required'),
            ],
          ),
        ),

        // Section label
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Income & Loan Details', style: AppTextStyles.sectionLabel(theme.getMutedColor(context))),
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
              // Monthly Income
              _buildSyncSliderRow(
                title: 'Monthly Net Income',
                controller: _monthlyIncomeController,
                min: 20000,
                max: 500000,
                divisions: 96,
                displayValue: _fmtShort(income),
              ),
              const SizedBox(height: 16),

              // Existing EMIs
              _buildSyncSliderRow(
                title: 'Existing EMIs / Obligations',
                controller: _existingEmiController,
                min: 0,
                max: 100000,
                divisions: 100,
                displayValue: _fmtShort(existEmi),
              ),
              const SizedBox(height: 16),

              // Interest Rate
              _buildSyncSliderRow(
                title: 'Interest Rate (% p.a.)',
                controller: _rateController,
                min: 6.50,
                max: 15.00,
                divisions: 170,
                displayValue: '${rate.toStringAsFixed(2)}%',
              ),
              const SizedBox(height: 16),

              // Tenure Years
              _buildSyncSliderRow(
                title: 'Loan Tenure (Years)',
                controller: _tenureController,
                min: 5,
                max: 30,
                divisions: 25,
                displayValue: '$tenure yr',
              ),
              const SizedBox(height: 16),

              // CIBIL Score Segment Toggles
              Text('CIBIL SCORE', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.w800)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildCibilBtn('650–699', _cibilScore == 650, () => setState(() => _cibilScore = 650))),
                  const SizedBox(width: 4),
                  Expanded(child: _buildCibilBtn('700–749', _cibilScore == 700, () => setState(() => _cibilScore = 700))),
                  const SizedBox(width: 4),
                  Expanded(child: _buildCibilBtn('750–799', _cibilScore == 750, () => setState(() => _cibilScore = 750))),
                  const SizedBox(width: 4),
                  Expanded(child: _buildCibilBtn('800+', _cibilScore == 800, () => setState(() => _cibilScore = 800))),
                ],
              ),
              const SizedBox(height: 16),

              // Employment Type Toggles
              Text('EMPLOYMENT TYPE', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.w800)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildToggleBtn('Salaried', _empType == 'salaried', () => setState(() => _empType = 'salaried'))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildToggleBtn('Self-Employed', _empType == 'self_employed', () => setState(() => _empType = 'self_employed'))),
                ],
              ),
              const SizedBox(height: 20),

              // Calculate Button
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('⚡ Eligibility verified!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
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
                    '☸ Check My Eligibility',
                    style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Eligibility Result Hero Card
        Container(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MAXIMUM ELIGIBLE HOME LOAN',
                    style: AppTextStyles.dmSans(size: 9, color: Colors.white70, weight: FontWeight.w700),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: eligTagBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      eligTag,
                      style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: eligTagFg),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _fmt(eligLoan),
                style: AppTextStyles.playfair(size: 34, color: const Color(0xFFFFDEA0), weight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                'Based on ${(foirLimit * 100).toInt()}% FOIR · $tenure yr tenure · ${rate.toStringAsFixed(2)}% rate',
                style: AppTextStyles.dmSans(size: 9.5, color: Colors.white60),
              ),
              const SizedBox(height: 14),
              // Linear eligibility progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  height: 10,
                  color: Colors.white24,
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: (fillPct / 100).clamp(0.01, 1.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF86EFAC), Color(0xFF22C55E)]),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${fillPct.toStringAsFixed(0)}% of ₹1Cr potential',
                  style: AppTextStyles.dmSans(size: 9, color: Colors.white54),
                ),
              ),
              const SizedBox(height: 14),
              // 4-Grid box results
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.0,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  _buildResultBox('Max Monthly EMI', _fmtShort(maxEmi)),
                  _buildResultBox('Available for EMI', availEmi > 0 ? _fmtShort(availEmi) : '₹0'),
                  _buildResultBox('FOIR Used', '${actualFoir.toStringAsFixed(1)}%'),
                  _buildResultBox('Eligibility Status', eligStatusStr),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // FOIR Gauge custom painter card
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
              Text('📐 FOIR Analysis', style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: theme.getTextColor(context))),
              const SizedBox(height: 14),
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    height: 70,
                    child: CustomPaint(
                      painter: SemiCircleGaugePainter(
                        percentage: actualFoir / 100,
                        activeColor: statusColor,
                      ),
                      child: Container(
                        alignment: const Alignment(0, 0.4),
                        child: Text(
                          '${actualFoir.toStringAsFixed(0)}%',
                          style: AppTextStyles.dmSans(
                            size: 14,
                            weight: FontWeight.w800,
                            color: theme.getTextColor(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fixed Obligation to Income Ratio',
                          style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${actualFoir.toStringAsFixed(1)}%',
                          style: AppTextStyles.dmSans(size: 18, weight: FontWeight.w800, color: theme.getTextColor(context)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusText,
                          style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: statusColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Tips to Boost Eligibility
        Text('Tips to Boost Eligibility', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 10),
        Column(
          children: [
            _buildTipRow('💳', 'Improve CIBIL Score to 750+', 'A score above 750 unlocks lower rates (up to 0.25% reduction) and higher loan amounts from SBI, HDFC, ICICI.'),
            _buildTipRow('📉', 'Close Existing Loans First', 'Reducing existing EMIs improves FOIR significantly — clearing a ₹10,000 EMI can add ₹8–12L to eligibility.'),
            _buildTipRow('👫', 'Add Co-applicant (Joint Loan)', 'Adding spouse/parent as co-applicant can increase eligibility by 40–60% and also provides additional 80C/24(b) tax benefits.'),
            _buildTipRow('📅', 'Opt for Longer Tenure', 'Extending tenure to 30 years reduces EMI burden and improves eligibility — useful if you\'re under 35 years old.'),
          ],
        ),

        const SizedBox(height: 20),

        // Save Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
            border: Border.all(color: isDark ? const Color(0xFF065F46) : const Color(0xFF6EE7B7)),
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
                    Text('Save Eligibility Report', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF07543A))),
                    Text('Save for bank application reference', style: AppTextStyles.dmSans(size: 10, color: isDark ? Colors.white70 : const Color(0xFF046A38))),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _saveCalculation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF046A38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Save', style: AppTextStyles.dmSans(size: 11, color: Colors.white, weight: FontWeight.w700)),
              ),
            ],
          ),
        ),
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
                    borderSide: BorderSide(color: theme.getBorderColor(context)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Color(0xFFFF6B00)),
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

  Widget _buildCibilBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0B1F48) : Colors.transparent,
          border: Border.all(color: active ? const Color(0xFF0B1F48) : widget.theme.getBorderColor(context)),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
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

  Widget _buildToggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0B1F48) : Colors.transparent,
          border: Border.all(color: active ? const Color(0xFF0B1F48) : widget.theme.getBorderColor(context)),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 11.5,
            weight: FontWeight.w700,
            color: active ? Colors.white : widget.theme.getMutedColor(context),
          ),
        ),
      ),
    );
  }

  Widget _buildResultBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white70)),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTipRow(String emoji, String title, String desc) {
    final theme = widget.theme;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: theme.getTextColor(context)),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)),
                ),
              ],
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
}
