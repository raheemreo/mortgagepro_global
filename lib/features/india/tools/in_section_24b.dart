// lib/features/india/tools/in_section_24b.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class INSection24B extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INSection24B({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INSection24B> createState() => _INSection24BState();
}

class _INSection24BState extends ConsumerState<INSection24B> {
  double _interestPaid = 280000;
  double _annualIncome = 1500000;
  double _slabRate = 30; // 5, 20, 30
  String _propType = 'self'; // 'self', 'let', 'uc'

  bool _calculated = false;
  double _calcInterestPaid = 280000;
  double _calcAnnualIncome = 1500000;
  double _calcSlabRate = 30;
  String _calcPropType = 'self';

  final GlobalKey _resultPanelKey = GlobalKey();

  void _reset() {
    setState(() {
      _interestPaid = 280000;
      _annualIncome = 1500000;
      _slabRate = 30;
      _propType = 'self';
      _calculated = false;

      _calcInterestPaid = 280000;
      _calcAnnualIncome = 1500000;
      _calcSlabRate = 30;
      _calcPropType = 'self';
    });
  }

  void _calculate() {
    setState(() {
      _calculated = true;
      _calcInterestPaid = _interestPaid;
      _calcAnnualIncome = _annualIncome;
      _calcSlabRate = _slabRate;
      _calcPropType = _propType;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _resultPanelKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
    });
  }

  bool _areInputsChanged() {
    return _interestPaid != _calcInterestPaid ||
        _annualIncome != _calcAnnualIncome ||
        _slabRate != _calcSlabRate ||
        _propType != _calcPropType;
  }

  String _fmt(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(2)} L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }

  void _saveCalculation() async {
    double deductible;
    double excess;
    if (_calcPropType == 'self') {
      const cap = 200000.0;
      deductible = _calcInterestPaid > cap ? cap : _calcInterestPaid;
      excess = _calcInterestPaid - deductible;
    } else if (_calcPropType == 'let') {
      deductible = _calcInterestPaid;
      excess = 0.0;
    } else {
      const cap = 30000.0;
      deductible = (_calcInterestPaid / 5) > cap ? cap : (_calcInterestPaid / 5);
      excess = _calcInterestPaid - deductible * 5;
    }
    final taxSaving = deductible * (_calcSlabRate / 100) * 1.04;

    final labelCtrl = TextEditingController(text: 'Section 24(b) Deduction');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/in_section_24b'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Deduction Calc', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving: Deductible ${_fmt(deductible)} · Tax Saved ${_fmt(taxSaving)}',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My Home Interest Deduction)',
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
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'Section 24(b)';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'Section 24(b)',
        inputs: {
          'interestPaid': _calcInterestPaid,
          'annualIncome': _calcAnnualIncome,
          'slabRate': _calcSlabRate,
          'propType': _calcPropType == 'self' ? 0.0 : _calcPropType == 'let' ? 1.0 : 2.0,
        },
        results: {
          'deductible': deductible,
          'excessInterest': excess,
          'taxSaving': taxSaving,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Deduction saved!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
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

    double deductible;
    double excess;
    if (_calcPropType == 'self') {
      const cap = 200000.0;
      deductible = _calcInterestPaid > cap ? cap : _calcInterestPaid;
      excess = _calcInterestPaid - deductible;
    } else if (_calcPropType == 'let') {
      deductible = _calcInterestPaid;
      excess = 0.0;
    } else {
      const cap = 30000.0;
      deductible = (_calcInterestPaid / 5) > cap ? cap : (_calcInterestPaid / 5);
      excess = _calcInterestPaid - deductible * 5;
    }

    final taxSaving = deductible * (_calcSlabRate / 100) * 1.04;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Property Toggles Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Property Occupancy Status', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.w700)),
                  GestureDetector(
                    onTap: _reset,
                    child: Text('Reset ↺', style: AppTextStyles.dmSans(size: 11, color: const Color(0xFFE05F00), weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _buildTypeBtn('Self-Occupied (₹2L Cap)', _propType == 'self', () => setState(() => _propType = 'self'))),
                  const SizedBox(width: 4),
                  Expanded(child: _buildTypeBtn('Let-Out (No Limit)', _propType == 'let', () => setState(() => _propType = 'let'))),
                  const SizedBox(width: 4),
                  Expanded(child: _buildTypeBtn('Pre-Construction (₹30K)', _propType == 'uc', () => setState(() => _propType = 'uc'))),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Inputs Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Deduction Parameters', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.w700)),
              const SizedBox(height: 16),

              _buildSliderRow('ANNUAL INTEREST PAID', _interestPaid, 10000, 1000000, 99, (v) => setState(() => _interestPaid = v)),
              _buildSliderRow('ANNUAL INCOME', _annualIncome, 100000, 5000000, 98, (v) => setState(() => _annualIncome = v)),

              Text('EXPECTED TAX SLAB BRACKET', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.w800)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildSlabBtn('5%', _slabRate == 5, () => setState(() => _slabRate = 5))),
                  const SizedBox(width: 6),
                  Expanded(child: _buildSlabBtn('20%', _slabRate == 20, () => setState(() => _slabRate = 20))),
                  const SizedBox(width: 6),
                  Expanded(child: _buildSlabBtn('30%', _slabRate == 30, () => setState(() => _slabRate = 30))),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _calculate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE05F00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('⚙️ Calculate Section 24(b)', style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),

        if (_calculated) ...[
          const SizedBox(height: 20),
          // Warning banner if inputs changed
          if (_areInputsChanged())
            Container(
              key: _resultPanelKey,
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
                      'Inputs changed. Tap Calculate Section 24(b) to update results.',
                      style: AppTextStyles.dmSans(size: 11, color: isDark ? Colors.amber[200]! : Colors.amber[900]!, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(key: _resultPanelKey, height: 0),

          // Results Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ESTIMATED INTEREST TAX SAVINGS', style: AppTextStyles.dmSans(size: 9, color: Colors.white70, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  _fmt(taxSaving),
                  style: AppTextStyles.playfair(size: 34, color: const Color(0xFFFFDEA0), weight: FontWeight.w800),
                ),
                Text('Deduction under Section 24(b) + 4% Cess', style: AppTextStyles.dmSans(size: 10, color: Colors.white60)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _resultBox('Total Interest', _fmt(_calcInterestPaid)),
                    const SizedBox(width: 8),
                    _resultBox('Deductible Limit', _fmt(deductible)),
                    const SizedBox(width: 8),
                    _resultBox('Excess Interest', excess == 0 ? 'NIL' : _fmt(excess), isWarn: excess > 0),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Income vs deductions visual bars
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
                Text('Taxable Income Adjustment', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: theme.getTextColor(context))),
                const SizedBox(height: 16),
                _visualBar('Gross Income', _calcAnnualIncome, _calcAnnualIncome, const Color(0xFF1A3A8F)),
                const SizedBox(height: 12),
                _visualBar('Adjusted Taxable Income', _calcAnnualIncome - deductible, _calcAnnualIncome, const Color(0xFF046A38)),
                const SizedBox(height: 12),
                _visualBar('Actual Tax Saved', taxSaving, _calcAnnualIncome, const Color(0xFFE05F00), isSmall: true),
              ],
            ),
          ),

          const SizedBox(height: 16),
          // Save bar
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
                      Text('Save Deduction Details', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF07543A))),
                      Text('Save details for future reference', style: AppTextStyles.dmSans(size: 10, color: isDark ? Colors.white70 : const Color(0xFF046A38))),
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
      ],
    );
  }

  Widget _buildSliderRow(String title, double val, double min, double max, int div, ValueChanged<double> onChanged) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.dmSans(size: 8.5, color: theme.getMutedColor(context), weight: FontWeight.w800)),
            Text(_fmt(val), style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
          ],
        ),
        Slider(
          value: val.clamp(min, max),
          min: min,
          max: max,
          divisions: div,
          activeColor: const Color(0xFFE05F00),
          inactiveColor: const Color(0xFFE05F00).withValues(alpha: 0.15),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTypeBtn(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFE05F00) : Colors.transparent,
            border: Border.all(color: active ? const Color(0xFFE05F00) : widget.theme.getBorderColor(context)),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans(
              size: 9.5,
              weight: FontWeight.w700,
              color: active ? Colors.white : widget.theme.getMutedColor(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlabBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE05F00) : Colors.transparent,
          border: Border.all(color: active ? const Color(0xFFE05F00) : widget.theme.getBorderColor(context)),
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

  Widget _resultBox(String label, String value, {bool isWarn = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 9, color: Colors.white70)),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w800,
                color: isWarn ? const Color(0xFFFFDEA0) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _visualBar(String label, double val, double maxVal, Color col, {bool isSmall = false}) {
    final pct = maxVal > 0 ? (val / maxVal).clamp(0.01, 1.0) : 0.01;
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 10.5, color: theme.getTextColor(context))),
            Text(_fmt(val), style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.bold, color: theme.getTextColor(context))),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: isSmall ? 4 : 8,
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(3)),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: pct,
            child: Container(decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(3))),
          ),
        ),
      ],
    );
  }
}
