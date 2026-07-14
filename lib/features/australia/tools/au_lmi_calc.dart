// lib/features/australia/tools/au_lmi_calc.dart
// Australia LMI Calculator bottom sheet

import 'package:flutter/material.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/lmi_calculator.dart';
import '../../../core/utils/mortgage_math.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/result_panel.dart';

class AULMICalcSheet extends StatefulWidget {
  final double propertyValue;
  final double depositPercent;

  const AULMICalcSheet({
    super.key,
    this.propertyValue = 750000,
    this.depositPercent = 10,
  });

  @override
  State<AULMICalcSheet> createState() => _AULMICalcSheetState();
}

class _AULMICalcSheetState extends State<AULMICalcSheet> {
  late double _propValue;
  late double _depositPct;
  static const _theme = CountryThemes.australia;

  bool _showResults = false;
  final Map<String, dynamic> _calcSnapshot = {};

  @override
  void initState() {
    super.initState();
    _propValue = widget.propertyValue;
    _depositPct = widget.depositPercent;
  }

  void _reset() {
    setState(() {
      _propValue = widget.propertyValue;
      _depositPct = widget.depositPercent;
      _showResults = false;
      _calcSnapshot.clear();
    });
  }

  void _calculate() {
    setState(() {
      _calcSnapshot['propValue'] = _propValue;
      _calcSnapshot['depositPct'] = _depositPct;
      _showResults = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double snapPropValue = _showResults ? (_calcSnapshot['propValue'] ?? _propValue) : _propValue;
    final double snapDepositPct = _showResults ? (_calcSnapshot['depositPct'] ?? _depositPct) : _depositPct;

    final double lvr = 100 - snapDepositPct;
    final double lmi = LMICalculator.calculateLMI(
      propertyValue: snapPropValue,
      depositPercent: snapDepositPct,
    );
    final double loanAmount = snapPropValue * (lvr / 100);

    final isDirty = _showResults && (
      _propValue != (_calcSnapshot['propValue'] ?? 0.0) ||
      _depositPct != (_calcSnapshot['depositPct'] ?? 0.0)
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.90,
      minChildSize: 0.4,
      expand: false,
      builder: (context, sc) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).scaffoldBackgroundColor
              : const Color(0xFFFFF7F0),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: sc,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🛡️ LMI Calculator',
                    style: AppTextStyles.dmSans(size: 18, weight: FontWeight.w800, color: _theme.textColor)),
                GestureDetector(
                  onTap: _reset,
                  child: Text('Reset ↺', style: AppTextStyles.dmSans(size: 12, color: _theme.primaryColor, weight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              LMICalculator.lmiTier(snapDepositPct),
              style: AppTextStyles.dmSans(
                size: 11,
                color: lmi > 0 ? const Color(0xFFEA580C) : const Color(0xFF15803D),
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            _Slider(
              label: 'Property Value',
              value: _propValue,
              min: 100000,
              max: 3000000,
              divisions: 290,
              display: CurrencyFormatter.compact(_propValue, symbol: 'AU\$'),
              color: _theme.primaryColor,
              onChanged: (v) => setState(() => _propValue = v),
            ),
            _Slider(
              label: 'Deposit %',
              value: _depositPct,
              min: 5,
              max: 40,
              divisions: 35,
              display: '${_depositPct.toInt()}% (LVR: ${(100 - _depositPct).toStringAsFixed(0)}%)',
              color: _theme.primaryColor,
              onChanged: (v) => setState(() => _depositPct = v),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: _theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('Calculate LMI', style: AppTextStyles.dmSans(size: 13, weight: FontWeight.bold, color: Colors.white)),
            ),
            if (_showResults) ...[
              if (isDirty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '⚠️ Inputs have changed. Tap Calculate LMI to refresh results.',
                    style: AppTextStyles.dmSans(size: 11, color: Colors.amber[800], weight: FontWeight.bold),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ResultPanel(
                primaryColor: _theme.primaryColor,
                rows: [
                  ResultRow(label: 'LMI Premium', value: lmi, currencyCode: 'AUD', isHighlighted: true),
                  ResultRow(label: 'Loan Amount', value: loanAmount, currencyCode: 'AUD'),
                  ResultRow(label: 'LVR', value: lvr, isPercent: true),
                  ResultRow(label: 'Deposit Amount', value: snapPropValue * snapDepositPct / 100, currencyCode: 'AUD'),
                  ResultRow(label: 'Total Loan + LMI', value: loanAmount + lmi, currencyCode: 'AUD'),
                ],
              ),
              const SizedBox(height: 16),
              if (lmi == 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Text(
                    '✅ No LMI required — deposit is 20% or more!',
                    style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w600, color: const Color(0xFF15803D)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class AUMortgageCalcSheet extends StatefulWidget {
  final double propertyValue;
  final double depositPercent;
  final int termYears;
  final double rate;

  const AUMortgageCalcSheet({
    super.key,
    this.propertyValue = 750000,
    this.depositPercent = 10,
    this.termYears = 30,
    this.rate = 6.09,
  });

  @override
  State<AUMortgageCalcSheet> createState() => _AUMortgageCalcSheetState();
}

class _AUMortgageCalcSheetState extends State<AUMortgageCalcSheet> {
  late double _propValue;
  late double _depositPct;
  late int _termYears;
  late double _rate;
  static const _theme = CountryThemes.australia;

  bool _showResults = false;
  final Map<String, dynamic> _calcSnapshot = {};

  @override
  void initState() {
    super.initState();
    _propValue = widget.propertyValue;
    _depositPct = widget.depositPercent;
    _termYears = widget.termYears;
    _rate = widget.rate;
  }

  void _reset() {
    setState(() {
      _propValue = widget.propertyValue;
      _depositPct = widget.depositPercent;
      _termYears = widget.termYears;
      _rate = widget.rate;
      _showResults = false;
      _calcSnapshot.clear();
    });
  }

  void _calculate() {
    setState(() {
      _calcSnapshot['propValue'] = _propValue;
      _calcSnapshot['depositPct'] = _depositPct;
      _calcSnapshot['rate'] = _rate;
      _calcSnapshot['termYears'] = _termYears;
      _showResults = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double snapPropValue = _showResults ? (_calcSnapshot['propValue'] ?? _propValue) : _propValue;
    final double snapDepositPct = _showResults ? (_calcSnapshot['depositPct'] ?? _depositPct) : _depositPct;
    final double snapRate = _showResults ? (_calcSnapshot['rate'] ?? _rate) : _rate;
    final int snapTermYears = _showResults ? (_calcSnapshot['termYears'] ?? _termYears) : _termYears;

    final double loanAmount = snapPropValue * (1 - snapDepositPct / 100);
    final double lmi = LMICalculator.calculateLMI(propertyValue: snapPropValue, depositPercent: snapDepositPct);
    final double totalLoan = loanAmount + lmi;

    final double monthly = MortgageMath.monthlyPayment(
      principal: totalLoan,
      annualRatePercent: snapRate,
      termYears: snapTermYears,
    );

    final double fortnightly = MortgageMath.fortnightlyPayment(
      principal: totalLoan,
      annualRatePercent: snapRate,
      termYears: snapTermYears,
    );

    final isDirty = _showResults && (
      _propValue != (_calcSnapshot['propValue'] ?? 0.0) ||
      _depositPct != (_calcSnapshot['depositPct'] ?? 0.0) ||
      _rate != (_calcSnapshot['rate'] ?? 0.0) ||
      _termYears != (_calcSnapshot['termYears'] ?? 0)
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, sc) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).scaffoldBackgroundColor
              : const Color(0xFFFFF7F0),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: sc,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🦘 Australian Mortgage',
                    style: AppTextStyles.dmSans(size: 18, weight: FontWeight.w800, color: _theme.textColor)),
                GestureDetector(
                  onTap: _reset,
                  child: Text('Reset ↺', style: AppTextStyles.dmSans(size: 12, color: _theme.primaryColor, weight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _Slider(
              label: 'Property Value',
              value: _propValue,
              min: 100000,
              max: 5000000,
              divisions: 490,
              display: CurrencyFormatter.compact(_propValue, symbol: 'AU\$'),
              color: _theme.primaryColor,
              onChanged: (v) => setState(() => _propValue = v),
            ),
            _Slider(
              label: 'Deposit %',
              value: _depositPct,
              min: 5,
              max: 50,
              divisions: 45,
              display: '${_depositPct.toInt()}%',
              color: _theme.primaryColor,
              onChanged: (v) => setState(() => _depositPct = v),
            ),
            _Slider(
              label: 'Interest Rate',
              value: _rate,
              min: 2,
              max: 12,
              divisions: 100,
              display: '${_rate.toStringAsFixed(2)}%',
              color: _theme.primaryColor,
              onChanged: (v) => setState(() => _rate = v),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: _theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('Calculate Payment', style: AppTextStyles.dmSans(size: 13, weight: FontWeight.bold, color: Colors.white)),
            ),
            if (_showResults) ...[
              if (isDirty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '⚠️ Inputs have changed. Tap Calculate Payment to refresh results.',
                    style: AppTextStyles.dmSans(size: 11, color: Colors.amber[800], weight: FontWeight.bold),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ResultPanel(
                primaryColor: _theme.primaryColor,
                rows: [
                  ResultRow(label: 'Monthly Payment', value: monthly, currencyCode: 'AUD', isHighlighted: true),
                  ResultRow(label: 'Fortnightly Payment', value: fortnightly, currencyCode: 'AUD'),
                  ResultRow(label: 'LMI Premium', value: lmi, currencyCode: 'AUD'),
                  ResultRow(label: 'Total Loan (+ LMI)', value: totalLoan, currencyCode: 'AUD'),
                  ResultRow(
                    label: 'Total Interest',
                    value: MortgageMath.totalInterest(
                      principal: totalLoan,
                      annualRatePercent: snapRate,
                      termYears: snapTermYears,
                    ),
                    currencyCode: 'AUD',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Slider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String display;
  final Color color;
  final ValueChanged<double> onChanged;

  const _Slider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.display,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTextStyles.dmSans(
                    size: 12,
                    weight: FontWeight.w600,
                    color: const Color(0xFF5B6E8F))),
            Text(display,
                style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w700, color: color)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
              activeTrackColor: color,
              thumbColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.20),
              overlayColor: color.withValues(alpha: 0.15),
              trackHeight: 3),
          child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged),
        ),
      ],
    );
  }
}
