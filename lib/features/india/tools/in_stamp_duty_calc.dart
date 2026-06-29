// lib/features/india/tools/in_stamp_duty_calc.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class INStampDutyCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INStampDutyCalc({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INStampDutyCalc> createState() => _INStampDutyCalcState();
}

class _INStampDutyCalcState extends ConsumerState<INStampDutyCalc> {
  double _propValue = 5000000;
  String _stateKey = 'MH';
  String _gender = 'male'; // 'male', 'female'

  final Map<String, Map<String, dynamic>> _states = const {
    'MH': {'name': 'Maharashtra', 'male': 5.0, 'female': 5.0, 'reg': 1.0, 'extra': 'Metro: +1% surcharge'},
    'DL': {'name': 'Delhi', 'male': 6.0, 'female': 4.0, 'reg': 1.0, 'regMax': 30000.0, 'extra': 'Reg capped at ₹30,000'},
    'KA': {'name': 'Karnataka', 'male': 5.0, 'female': 5.0, 'reg': 1.0, 'extra': 'Reg 1%'},
    'TN': {'name': 'Tamil Nadu', 'male': 7.0, 'female': 7.0, 'reg': 4.0, 'extra': 'Highest reg fee'},
    'TS': {'name': 'Telangana', 'male': 4.0, 'female': 4.0, 'reg': 0.5, 'extra': 'Lowest reg fee'},
    'GJ': {'name': 'Gujarat', 'male': 4.9, 'female': 3.9, 'reg': 1.0, 'extra': 'Women concession 1%'},
    'UP': {'name': 'Uttar Pradesh', 'male': 7.0, 'female': 7.0, 'reg': 1.0, 'extra': ''},
    'WB': {'name': 'West Bengal', 'male': 6.0, 'female': 6.0, 'reg': 1.0, 'extra': ''},
    'RJ': {'name': 'Rajasthan', 'male': 5.0, 'female': 4.0, 'reg': 1.0, 'extra': 'Women concession 1%'},
    'PB': {'name': 'Punjab', 'male': 7.0, 'female': 5.0, 'reg': 1.0, 'extra': 'Women concession 2%'},
  };

  void _reset() {
    setState(() {
      _propValue = 5000000;
      _stateKey = 'MH';
      _gender = 'male';
    });
  }

  String _fmt(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(2)} L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }

  void _saveCalculation() async {
    final state = _states[_stateKey]!;
    final sdRate = _gender == 'female' ? (state['female'] as double) : (state['male'] as double);
    final regRate = state['reg'] as double;
    final stamp = _propValue * sdRate / 100;
    double reg = _propValue * regRate / 100;
    if (state.containsKey('regMax')) {
      final regMax = state['regMax'] as double;
      if (reg > regMax) reg = regMax;
    }
    final total = stamp + reg;

    final labelCtrl = TextEditingController(text: 'Stamp Duty - ${state['name']}');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/in_stamp_duty_calc/save'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Stamp Duty', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving: Total Fees ${_fmt(total)} · Property ${_fmt(_propValue)}',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. Pune Flat Registry)',
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
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'Stamp Duty Registry';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'Stamp Duty Calc',
        inputs: {
          'propValue': _propValue,
          'stateIndex': _states.keys.toList().indexOf(_stateKey).toDouble(),
          'gender': _gender == 'male' ? 0.0 : 1.0,
        },
        results: {
          'stampDuty': stamp,
          'registration': reg,
          'totalFees': total,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Stamp duty calculation saved!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
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

    final state = _states[_stateKey]!;
    final sdRate = _gender == 'female' ? (state['female'] as double) : (state['male'] as double);
    final regRate = state['reg'] as double;
    final stamp = _propValue * sdRate / 100;
    double reg = _propValue * regRate / 100;
    if (state.containsKey('regMax')) {
      final regMax = state['regMax'] as double;
      if (reg > regMax) reg = regMax;
    }
    final total = stamp + reg;
    final effPct = _propValue > 0 ? (total / _propValue * 100) : 0.0;

    final totalOutgo = _propValue + total;
    final pctProp = totalOutgo > 0 ? (_propValue / totalOutgo) : 0.0;
    final pctStamp = totalOutgo > 0 ? (stamp / totalOutgo) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Property & Registry parameters', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.w700)),
                  GestureDetector(
                    onTap: _reset,
                    child: Text('Reset ↺', style: AppTextStyles.dmSans(size: 11, color: const Color(0xFFE05F00), weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Property Value Slider
              _buildSliderRow('PROPERTY VALUE', _propValue, 500000, 20000000, 195, (v) => setState(() => _propValue = v)),

              // State Selector Dropdown
              Text('SELECT STATE', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7EE),
                  border: Border.all(color: theme.getBorderColor(context)),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _stateKey,
                    isExpanded: true,
                    dropdownColor: theme.getCardColor(context),
                    style: AppTextStyles.dmSans(size: 14, color: theme.getTextColor(context), weight: FontWeight.w800),
                    items: _states.entries.map((e) {
                      return DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(e.value['name'] as String),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _stateKey = val);
                      }
                    },
                  ),
                ),
              ),
              if ((state['extra'] as String).isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(state['extra'] as String, style: AppTextStyles.dmSans(size: 9.5, color: const Color(0xFFE05F00), weight: FontWeight.w600)),
              ],
              const SizedBox(height: 16),

              // Gender Selector Toggles
              Text('OWNER GENDER', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.w800)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildToggleBtn('Male Owner', _gender == 'male', () => setState(() => _gender = 'male'))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildToggleBtn('Female Owner (Concessions)', _gender == 'female', () => setState(() => _gender = 'female'))),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

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
              Text('TOTAL REGISTRATION & STAMP DUTY FEES', style: AppTextStyles.dmSans(size: 9, color: Colors.white70, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                _fmt(total),
                style: AppTextStyles.playfair(size: 34, color: const Color(0xFFFFDEA0), weight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _resultBox('Stamp Duty', _fmt(stamp)),
                  const SizedBox(width: 8),
                  _resultBox('Registration Fee', _fmt(reg)),
                  const SizedBox(width: 8),
                  _resultBox('Effective Rate', '${effPct.toStringAsFixed(2)}%'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Cost breakdown donut
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
              Text('📊 Total Registry Cost Share', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: theme.getTextColor(context))),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 14,
                          color: Color(0xFF046A38), // Reg fee
                        ),
                        CircularProgressIndicator(
                          value: pctProp + pctStamp,
                          strokeWidth: 14,
                          color: const Color(0xFF1A3A8F), // Stamp duty
                        ),
                        CircularProgressIndicator(
                          value: pctProp,
                          strokeWidth: 14,
                          color: const Color(0xFFE05F00), // Property Value
                        ),
                        Text('${effPct.toStringAsFixed(1)}%', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: theme.getTextColor(context))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        _legendRow(const Color(0xFFE05F00), 'Property Agreement Value', _fmt(_propValue)),
                        const SizedBox(height: 8),
                        _legendRow(const Color(0xFF1A3A8F), 'Stamp Duty (${sdRate.toStringAsFixed(1)}%)', _fmt(stamp)),
                        const SizedBox(height: 8),
                        _legendRow(const Color(0xFF046A38), 'Registration Fee (${regRate.toStringAsFixed(1)}%)', _fmt(reg)),
                      ],
                    ),
                  ),
                ],
              ),
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
                    Text('Save Calculation', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF07543A))),
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

  Widget _buildToggleBtn(String label, bool active, VoidCallback onTap) {
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
            size: 11,
            weight: FontWeight.w700,
            color: active ? Colors.white : widget.theme.getMutedColor(context),
          ),
        ),
      ),
    );
  }

  Widget _resultBox(String label, String value) {
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
            Text(value, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _legendRow(Color color, String label, String value) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: widget.theme.getTextColor(context))),
              Text(value, style: AppTextStyles.dmSans(size: 9, color: widget.theme.getMutedColor(context))),
            ],
          ),
        ),
      ],
    );
  }
}
