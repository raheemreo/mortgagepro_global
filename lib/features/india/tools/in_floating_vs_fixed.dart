// lib/features/india/tools/in_floating_vs_fixed.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class INFloatingVsFixed extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INFloatingVsFixed({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INFloatingVsFixed> createState() => _INFloatingVsFixedState();
}

class _INFloatingVsFixedState extends ConsumerState<INFloatingVsFixed> {
  late TextEditingController _loanController;
  late TextEditingController _floatRController;
  late TextEditingController _fixedRController;
  late TextEditingController _tenureController;
  late TextEditingController _rateChangeController;

  @override
  void initState() {
    super.initState();
    _loanController = TextEditingController(text: '6000000');
    _floatRController = TextEditingController(text: '8.50');
    _fixedRController = TextEditingController(text: '9.50');
    _tenureController = TextEditingController(text: '20');
    _rateChangeController = TextEditingController(text: '-0.50');
  }

  @override
  void dispose() {
    _loanController.dispose();
    _floatRController.dispose();
    _fixedRController.dispose();
    _tenureController.dispose();
    _rateChangeController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _loanController.text = '6000000';
      _floatRController.text = '8.50';
      _fixedRController.text = '9.50';
      _tenureController.text = '20';
      _rateChangeController.text = '-0.50';
    });
  }

  double get _loan => double.tryParse(_loanController.text) ?? 6000000.0;
  double get _floatR => double.tryParse(_floatRController.text) ?? 8.50;
  double get _fixedR => double.tryParse(_fixedRController.text) ?? 9.50;
  int get _tenure => int.tryParse(_tenureController.text) ?? 20;
  double get _rateChange => double.tryParse(_rateChangeController.text) ?? 0.0;

  double _emi(double p, double r, int n) {
    final mr = r / 12 / 100;
    if (mr <= 0) return p / n;
    return p * mr * pow(1 + mr, n) / (pow(1 + mr, n) - 1);
  }

  String _fmt(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)} L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }

  String _fmtShort(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)}Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)}L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }

  void _saveCalculation() async {
    final loanVal = _loan;
    final fr = _floatR;
    final xr = _fixedR;
    final t = _tenure;
    final rc = _rateChange;
    final n = t * 12;

    final fEmi = _emi(loanVal, fr, n);
    final xEmi = _emi(loanVal, xr, n);
    final fAdj = _emi(loanVal, fr + rc, n);
    final fTotal = fAdj * n;
    final xTotal = xEmi * n;

    final labelCtrl = TextEditingController(text: 'Floating vs Fixed');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/in_floating_vs_fixed'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Rate Comparison', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving: Float outgo ${_fmt(fTotal)} · Fixed outgo ${_fmt(xTotal)}',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Rate Type Plan)',
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
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'Floating vs Fixed';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'Floating vs Fixed',
        inputs: {
          'loan': loanVal,
          'floatR': fr,
          'fixedR': xr,
          'tenure': t.toDouble(),
          'rateChange': rc,
        },
        results: {
          'floatEmi': fEmi,
          'fixedEmi': xEmi,
          'floatTotal': fTotal,
          'fixedTotal': xTotal,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Rate comparison saved!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
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

    final loanVal = _loan;
    final fr = _floatR;
    final xr = _fixedR;
    final t = _tenure;
    final rc = _rateChange;
    final n = t * 12;

    final fEmi = _emi(loanVal, fr, n);
    final xEmi = _emi(loanVal, xr, n);
    final fAdj = _emi(loanVal, fr + rc, n);
    final fTotal = fAdj * n;
    final xTotal = xEmi * n;
    final fInt = fTotal - loanVal;
    final xInt = xTotal - loanVal;
    final diff = xTotal - fTotal;

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
              _buildRateStripItem('Repo Rate', '6.25%', "RBI Jun'25", isFirst: true),
              _buildRateStripItem('SBI Float', '8.50%', 'EBLR linked'),
              _buildRateStripItem('Fixed Avg', '9.50%', '2yr lock-in'),
              _buildRateStripItem('Spread', '+1.00%', 'Float vs Fixed'),
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
              // Loan Amount
              _buildSyncSliderRow(
                title: 'Loan Amount (₹)',
                controller: _loanController,
                min: 500000,
                max: 30000000,
                divisions: 295,
                displayValue: _fmt(loanVal),
              ),
              const SizedBox(height: 16),

              // Floating Rate
              _buildSyncSliderRow(
                title: 'Floating Rate (% p.a.)',
                controller: _floatRController,
                min: 6,
                max: 14,
                divisions: 160,
                displayValue: '${fr.toStringAsFixed(2)}%',
              ),
              const SizedBox(height: 16),

              // Fixed Rate
              _buildSyncSliderRow(
                title: 'Fixed Rate (% p.a.)',
                controller: _fixedRController,
                min: 6,
                max: 16,
                divisions: 200,
                displayValue: '${xr.toStringAsFixed(2)}%',
              ),
              const SizedBox(height: 16),

              // Tenure
              _buildSyncSliderRow(
                title: 'Loan Tenure (Years)',
                controller: _tenureController,
                min: 5,
                max: 30,
                divisions: 25,
                displayValue: '$t yr',
              ),
              const SizedBox(height: 16),

              // Expected change
              _buildSyncSliderRow(
                title: 'Expected Rate Change (Float, %)',
                controller: _rateChangeController,
                min: -2,
                max: 3,
                divisions: 20,
                displayValue: '${rc > 0 ? '+' : ''}${rc.toStringAsFixed(2)}%',
              ),
              const SizedBox(height: 20),

              // Compare button
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('⚡ Comparison updated!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
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
                    '☸ Compare Floating vs Fixed',
                    style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // VS Comparison Cards (Side-by-side)
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                      child: Text('EBLR LINKED', style: AppTextStyles.dmSans(size: 8, weight: FontWeight.bold, color: Colors.white)),
                    ),
                    const SizedBox(height: 8),
                    const Text('📈', style: TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text('Floating EMI', style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.bold, color: Colors.white70)),
                    const SizedBox(height: 2),
                    Text('${fr.toStringAsFixed(2)}%', style: AppTextStyles.dmSans(size: 18, weight: FontWeight.w800, color: const Color(0xFFFFDEA0))),
                    const SizedBox(height: 4),
                    Text("EMI: ₹${NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(fEmi)}",
                        style: AppTextStyles.dmSans(size: 10.5, color: Colors.white, weight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B00), Color(0xFFE05A00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                      child: Text('LOCK-IN', style: AppTextStyles.dmSans(size: 8, weight: FontWeight.bold, color: Colors.white)),
                    ),
                    const SizedBox(height: 8),
                    const Text('🔒', style: TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text('Fixed EMI', style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.bold, color: Colors.white70)),
                    const SizedBox(height: 2),
                    Text('${xr.toStringAsFixed(2)}%', style: AppTextStyles.dmSans(size: 18, weight: FontWeight.w800, color: const Color(0xFFFFDEA0))),
                    const SizedBox(height: 4),
                    Text("EMI: ₹${NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(xEmi)}",
                        style: AppTextStyles.dmSans(size: 10.5, color: Colors.white, weight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Savings highlight card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0xFF6EE7B7), width: 1.5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Text('💰', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Savings (Float wins by)', style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: const Color(0xFF07543A))),
                    Text('Over full loan tenure · post expected rate change', style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFF046A38))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_fmt(diff.abs()), style: AppTextStyles.dmSans(size: 16, weight: FontWeight.w900, color: const Color(0xFF07543A))),
                  Text(diff > 0 ? 'Floating cheaper' : 'Fixed cheaper', style: AppTextStyles.dmSans(size: 8.5, color: const Color(0xFF046A38), weight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Lifetime cost analysis horizontal group
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
              Text('Cost Analysis Lifetime', style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
              const SizedBox(height: 16),
              _buildCostBarGroup('Total EMI Paid', fTotal, xTotal),
              const Divider(height: 20),
              _buildCostBarGroup('Total Interest', fInt, xInt),
              const Divider(height: 20),
              _buildCostBarGroup('Monthly EMI', fEmi, xEmi, isMonthly: true),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Repo Rate History scroll
        _buildRepoRateHistory(),

        const SizedBox(height: 20),

        // Verdict lists: when to choose
        Text('When to Choose', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 10),
        
        // Floating conditions card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📈 Choose Floating When...', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 8),
              _buildBulletPoint('RBI rate cuts expected (current cycle — Jun 2025)', Colors.white70),
              _buildBulletPoint('Loan tenure > 10 years (rate averages out)', Colors.white70),
              _buildBulletPoint('You can absorb minor EMI fluctuations', Colors.white70),
              _buildBulletPoint('Switching bank (balance transfer) possible', Colors.white70),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Fixed conditions card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            border: Border.all(color: const Color(0xFFFDBA74), width: 1.5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🔒 Choose Fixed When...', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: const Color(0xFF9A3412))),
              const SizedBox(height: 8),
              _buildBulletPoint('You need EMI certainty (fixed income households)', const Color(0xFF7C2D12)),
              _buildBulletPoint('RBI rate hike cycle expected', const Color(0xFF7C2D12)),
              _buildBulletPoint('Short tenure (< 5 years) — rate risk minimal', const Color(0xFF7C2D12)),
              _buildBulletPoint('Penalty-free part-prepayment not required', const Color(0xFF7C2D12)),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Tip Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0xFF93C5FD), width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'RBI EBLR Rule (2019): All floating-rate loans from banks must be linked to an External Benchmark Lending Rate (repo rate). HFCs like HDFC still use PLBR. Foreclosure charges banned on floating-rate home loans for individuals per RBI circular.',
                  style: AppTextStyles.dmSans(size: 10.5, color: const Color(0xFF1E3A8A), weight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Save Button
        ElevatedButton.icon(
          onPressed: _saveCalculation,
          icon: const Icon(Icons.save, size: 16, color: Colors.white),
          label: Text('Save This Comparison', style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.w800)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF046A38),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
              width: 70,
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
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.primaryColor),
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

  Widget _buildCostBarGroup(String groupLabel, double floatVal, double fixedVal, {bool isMonthly = false}) {
    final maxVal = max(floatVal, fixedVal);
    final pctFloat = maxVal > 0 ? (floatVal / maxVal).clamp(0.1, 1.0) : 0.1;
    final pctFixed = maxVal > 0 ? (fixedVal / maxVal).clamp(0.1, 1.0) : 0.1;
    final theme = widget.theme;

    String dispFloat = isMonthly ? "₹${NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(floatVal)}" : _fmtShort(floatVal);
    String dispFixed = isMonthly ? "₹${NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(fixedVal)}" : _fmtShort(fixedVal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(groupLabel.toUpperCase(), style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.w800)),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 60,
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: const Color(0xFF1A3A8F), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 6),
                  Text('Float', style: AppTextStyles.dmSans(size: 10.5, color: theme.getTextColor(context))),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Container(
                  height: 8,
                  color: Colors.grey[200],
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: pctFloat,
                    child: Container(color: const Color(0xFF1A3A8F)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(width: 60, child: Text(dispFloat, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.bold, color: theme.getTextColor(context)), textAlign: TextAlign.right)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(
              width: 60,
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: const Color(0xFFFF6B00), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 6),
                  Text('Fixed', style: AppTextStyles.dmSans(size: 10.5, color: theme.getTextColor(context))),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Container(
                  height: 8,
                  color: Colors.grey[200],
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: pctFixed,
                    child: Container(color: const Color(0xFFFF6B00)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(width: 60, child: Text(dispFixed, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.bold, color: theme.getTextColor(context)), textAlign: TextAlign.right)),
          ],
        ),
      ],
    );
  }

  Widget _buildRepoRateHistory() {
    final theme = widget.theme;
    final history = [
      {'year': '2019', 'rate': '6.50%', 'height': 54.0, 'colors': [const Color(0xFF1A3A8F), const Color(0xFF0B1F48)]},
      {'year': '2020', 'rate': '4.00%', 'height': 46.0, 'colors': [const Color(0xFF0D9488), const Color(0xFF0F766E)]},
      {'year': '2021', 'rate': '4.00%', 'height': 40.0, 'colors': [const Color(0xFF046A38), const Color(0xFF07543A)]},
      {'year': '2022', 'rate': '6.50%', 'height': 58.0, 'colors': [const Color(0xFFFF6B00), const Color(0xFFE05A00)]},
      {'year': '2023', 'rate': '6.50%', 'height': 60.0, 'colors': [const Color(0xFFFF6B00), const Color(0xFFE05A00)]},
      {'year': '2024', 'rate': '6.50%', 'height': 60.0, 'colors': [const Color(0xFFFF6B00), const Color(0xFFE05A00)]},
      {'year': '2025', 'rate': '6.25%', 'height': 54.0, 'colors': [const Color(0xFF046A38), const Color(0xFF07543A)]},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📊 RBI Repo Rate History', style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: history.map((item) {
                final barHeight = item['height'] as double;
                return Container(
                  width: 52,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: barHeight,
                        width: 28,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                          gradient: LinearGradient(
                            colors: item['colors'] as List<Color>,
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(item['rate'] as String, style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: theme.getTextColor(context))),
                      Text(item['year'] as String, style: AppTextStyles.dmSans(size: 8, color: theme.getMutedColor(context))),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, Color textCol) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('✓', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w900, color: const Color(0xFF86EFAC))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.dmSans(size: 10.5, color: textCol.withValues(alpha: 0.9), weight: FontWeight.w500),
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
