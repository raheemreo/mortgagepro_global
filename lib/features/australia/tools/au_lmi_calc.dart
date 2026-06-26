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

  @override
  void initState() {
    super.initState();
    _propValue = widget.propertyValue;
    _depositPct = widget.depositPercent;
  }

  double get _lvr => 100 - _depositPct;
  double get _lmi => LMICalculator.calculateLMI(
        propertyValue: _propValue,
        depositPercent: _depositPct,
      );
  double get _loanAmount => _propValue * (_lvr / 100);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
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
            Text('🛡️ LMI Calculator',
                style:
                    AppTextStyles.dmSans(size: 18, weight: FontWeight.w800, color: _theme.textColor)),
            const SizedBox(height: 4),
            Text(
              LMICalculator.lmiTier(_depositPct),
              style: AppTextStyles.dmSans(
                size: 11,
                color: _lmi > 0
                    ? const Color(0xFFEA580C)
                    : const Color(0xFF15803D),
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
              display:
                  '${_depositPct.toInt()}% (LVR: ${_lvr.toStringAsFixed(0)}%)',
              color: _theme.primaryColor,
              onChanged: (v) => setState(() => _depositPct = v),
            ),
            const SizedBox(height: 16),
            ResultPanel(
              primaryColor: _theme.primaryColor,
              rows: [
                ResultRow(
                    label: 'LMI Premium',
                    value: _lmi,
                    currencyCode: 'AUD',
                    isHighlighted: true),
                ResultRow(
                    label: 'Loan Amount',
                    value: _loanAmount,
                    currencyCode: 'AUD'),
                ResultRow(label: 'LVR', value: _lvr, isPercent: true),
                ResultRow(
                    label: 'Deposit Amount',
                    value: _propValue * _depositPct / 100,
                    currencyCode: 'AUD'),
                ResultRow(
                    label: 'Total Loan + LMI',
                    value: _loanAmount + _lmi,
                    currencyCode: 'AUD'),
              ],
            ),
            const SizedBox(height: 16),
            if (_lmi == 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Text(
                  '✅ No LMI required — deposit is 20% or more!',
                  style: AppTextStyles.dmSans(
                      size: 12,
                      weight: FontWeight.w600,
                      color: const Color(0xFF15803D)),
                ),
              ),
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

  @override
  void initState() {
    super.initState();
    _propValue = widget.propertyValue;
    _depositPct = widget.depositPercent;
    _termYears = widget.termYears;
    _rate = widget.rate;
  }

  double get _loanAmount => _propValue * (1 - _depositPct / 100);
  double get _lmi => LMICalculator.calculateLMI(
      propertyValue: _propValue, depositPercent: _depositPct);
  double get _totalLoan => _loanAmount + _lmi;

  double get _monthly => MortgageMath.monthlyPayment(
        principal: _totalLoan,
        annualRatePercent: _rate,
        termYears: _termYears,
      );

  double get _fortnightly => MortgageMath.fortnightlyPayment(
        principal: _totalLoan,
        annualRatePercent: _rate,
        termYears: _termYears,
      );

  @override
  Widget build(BuildContext context) {
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
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('🦘 Australian Mortgage',
                style:
                    AppTextStyles.dmSans(size: 18, weight: FontWeight.w800, color: _theme.textColor)),
            const SizedBox(height: 20),
            _Slider(
                label: 'Property Value',
                value: _propValue,
                min: 100000,
                max: 5000000,
                divisions: 490,
                display: CurrencyFormatter.compact(_propValue, symbol: 'AU\$'),
                color: _theme.primaryColor,
                onChanged: (v) => setState(() => _propValue = v)),
            _Slider(
                label: 'Deposit %',
                value: _depositPct,
                min: 5,
                max: 50,
                divisions: 45,
                display: '${_depositPct.toInt()}%',
                color: _theme.primaryColor,
                onChanged: (v) => setState(() => _depositPct = v)),
            _Slider(
                label: 'Interest Rate',
                value: _rate,
                min: 2,
                max: 12,
                divisions: 100,
                display: '${_rate.toStringAsFixed(2)}%',
                color: _theme.primaryColor,
                onChanged: (v) => setState(() => _rate = v)),
            const SizedBox(height: 16),
            ResultPanel(
              primaryColor: _theme.primaryColor,
              rows: [
                ResultRow(
                    label: 'Monthly Payment',
                    value: _monthly,
                    currencyCode: 'AUD',
                    isHighlighted: true),
                ResultRow(
                    label: 'Fortnightly Payment',
                    value: _fortnightly,
                    currencyCode: 'AUD'),
                ResultRow(
                    label: 'LMI Premium', value: _lmi, currencyCode: 'AUD'),
                ResultRow(
                    label: 'Total Loan (+ LMI)',
                    value: _totalLoan,
                    currencyCode: 'AUD'),
                ResultRow(
                    label: 'Total Interest',
                    value: MortgageMath.totalInterest(
                        principal: _totalLoan,
                        annualRatePercent: _rate,
                        termYears: _termYears),
                    currencyCode: 'AUD'),
              ],
            ),
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
