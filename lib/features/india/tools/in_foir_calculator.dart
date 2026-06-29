// lib/features/india/tools/in_foir_calculator.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class INFOIRCalculator extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INFOIRCalculator({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INFOIRCalculator> createState() => _INFOIRCalculatorState();
}

class _INFOIRCalculatorState extends ConsumerState<INFOIRCalculator> {
  double _salary = 120000;
  double _otherIncome = 10000;
  double _homeEmi = 0;
  double _carEmi = 8000;
  double _ccPayments = 2500;
  double _proposedEmi = 40000;

  void _reset() {
    setState(() {
      _salary = 120000;
      _otherIncome = 10000;
      _homeEmi = 0;
      _carEmi = 8000;
      _ccPayments = 2500;
      _proposedEmi = 40000;
    });
  }

  String _fmt(double n) {
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)}L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }

  void _saveCalculation() async {
    final totalIncome = _salary + _otherIncome;
    final totalOblig = _homeEmi + _carEmi + _ccPayments + _proposedEmi;
    final foir = totalIncome > 0 ? (totalOblig / totalIncome * 100) : 0.0;

    final labelCtrl = TextEditingController(text: 'FOIR Ratio');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/in_foir_calculator'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save FOIR Check', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving: FOIR ${foir.toStringAsFixed(1)}% · Total EMI ${_fmt(totalOblig)}',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My FOIR Profile)',
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
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'FOIR Ratio';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'FOIR Calculator',
        inputs: {
          'salary': _salary,
          'otherIncome': _otherIncome,
          'homeEmi': _homeEmi,
          'carEmi': _carEmi,
          'ccPayments': _ccPayments,
          'proposedEmi': _proposedEmi,
        },
        results: {
          'foir': foir,
          'totalIncome': totalIncome,
          'totalOblig': totalOblig,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ FOIR calculation saved!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
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

    final totalIncome = _salary + _otherIncome;
    final totalOblig = _homeEmi + _carEmi + _ccPayments + _proposedEmi;
    final foir = totalIncome > 0 ? (totalOblig / totalIncome * 100) : 0.0;
    final disposable = totalIncome - totalOblig;

    String statusText;
    Color statusColor;
    Color statusBgColor;
    LinearGradient cardGradient;

    if (foir <= 35) {
      statusText = '✅ Excellent Zone — Best rates guaranteed';
      statusColor = const Color(0xFF22C55E);
      statusBgColor = const Color(0xFF22C55E);
      cardGradient = const LinearGradient(colors: [Color(0xFF046A38), Color(0xFF07543A)]);
    } else if (foir <= 45) {
      statusText = '✅ Good Zone — Loan approval likely';
      statusColor = const Color(0xFF86EFAC);
      statusBgColor = const Color(0xFF16A34A);
      cardGradient = const LinearGradient(colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)]);
    } else if (foir <= 50) {
      statusText = '⚠️ Borderline Zone — May need extra docs';
      statusColor = const Color(0xFFFFD166);
      statusBgColor = const Color(0xFFD97706);
      cardGradient = const LinearGradient(colors: [Color(0xFF7A5C3A), Color(0xFF5A401A)]);
    } else {
      statusText = '❌ Rejection Zone — Reduce obligations first';
      statusColor = const Color(0xFFFCA5A5);
      statusBgColor = const Color(0xFFDC2626);
      cardGradient = const LinearGradient(colors: [Color(0xFF9A3412), Color(0xFF7C2D12)]);
    }

    final items = [
      {'icon': '💰', 'lbl': 'Gross Monthly Salary', 'sub': 'Primary income', 'amt': _salary},
      {'icon': '🏘️', 'lbl': 'Rental / Other Income', 'sub': 'Secondary income', 'amt': _otherIncome},
      {'icon': '🏠', 'lbl': 'Existing Home Loan EMI', 'sub': 'Current obligation', 'amt': -_homeEmi},
      {'icon': '🚗', 'lbl': 'Car / Personal Loan EMI', 'sub': 'Current obligation', 'amt': -_carEmi},
      {'icon': '💳', 'lbl': 'Credit Card Payment', 'sub': 'Min. monthly payment', 'amt': -_ccPayments},
      {'icon': '🏗️', 'lbl': 'Proposed Home Loan EMI', 'sub': 'New obligation', 'amt': -_proposedEmi},
    ];

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
              _buildRateStripItem('Safe FOIR', '≤40%', 'Ideal', isFirst: true),
              _buildRateStripItem('Max FOIR', '50%', 'RBI Limit'),
              _buildRateStripItem('Salaried', '50%', 'Allowed'),
              _buildRateStripItem('Self-Emp', '45%', 'Allowed'),
            ],
          ),
        ),

        // Section label
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Income & Obligations', style: AppTextStyles.sectionLabel(theme.getMutedColor(context))),
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
              _buildSliderRow('Gross Monthly Salary', _salary, 20000, 600000, 116, (v) => setState(() => _salary = v)),
              _buildSliderRow('Other Income (Rental/Business)', _otherIncome, 0, 200000, 40, (v) => setState(() => _otherIncome = v)),
              const Divider(height: 24),
              Text('EXISTING MONTHLY OBLIGATIONS', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.w800)),
              const SizedBox(height: 12),
              _buildSliderRow('Home Loan EMI (Current)', _homeEmi, 0, 100000, 100, (v) => setState(() => _homeEmi = v)),
              _buildSliderRow('Car / Personal Loan EMI', _carEmi, 0, 80000, 80, (v) => setState(() => _carEmi = v)),
              _buildSliderRow('Credit Card Min. Payment', _ccPayments, 0, 50000, 100, (v) => setState(() => _ccPayments = v)),
              _buildSliderRow('Proposed New Home Loan EMI', _proposedEmi, 5000, 200000, 195, (v) => setState(() => _proposedEmi = v)),
              const SizedBox(height: 20),

              // Calculate Button
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('⚡ FOIR checked!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
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
                    '☸ Calculate FOIR',
                    style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // FOIR Gauge / Status Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: cardGradient,
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
            children: [
              Text(
                'YOUR FOIR (FIXED OBLIGATION TO INCOME RATIO)',
                style: AppTextStyles.dmSans(size: 9, color: Colors.white60, weight: FontWeight.w700, letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),
              Text(
                '${foir.toStringAsFixed(1)}%',
                style: AppTextStyles.dmSans(size: 52, weight: FontWeight.w800, color: statusColor),
              ),
              const SizedBox(height: 4),
              Text(
                statusText,
                style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.9)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 12,
                  color: Colors.white24,
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: (foir / 100).clamp(0.01, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFF22C55E), statusBgColor],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildFoirBox('Total Income', _fmt(totalIncome)),
                  const SizedBox(width: 8),
                  _buildFoirBox('Total Obligations', _fmt(totalOblig)),
                  const SizedBox(width: 8),
                  _buildFoirBox('Disposable', _fmt(disposable > 0 ? disposable : 0.0)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // FOIR Zones Card
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
              Text('📊 FOIR Zones — Banks\' View', style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
              const SizedBox(height: 14),
              _buildZoneRow('Excellent Zone', 'High approval chance · Best rates offered', '≤35%', const Color(0xFF22C55E)),
              const Divider(height: 16),
              _buildZoneRow('Good Zone', 'Approved easily · Standard rates apply', '36–45%', const Color(0xFF16A34A)),
              const Divider(height: 16),
              _buildZoneRow('Borderline Zone', 'May get approval with extra documentation', '46–50%', const Color(0xFFD97706)),
              const Divider(height: 16),
              _buildZoneRow('Rejection Zone', 'Most banks will reject — reduce obligations', '>50%', const Color(0xFFDC2626)),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Obligation Breakdown
        Text('Obligation Breakdown', style: AppTextStyles.playfair(size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 10),
        Column(
          children: items.map((item) {
            final amt = item['amt'] as double;
            final isIncome = amt > 0;
            final double pct = totalIncome > 0 ? (amt.abs() / totalIncome * 100) : 0.0;

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
                  Text(item['icon'] as String, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['lbl'] as String, style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
                        Text(item['sub'] as String, style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${isIncome ? '+' : '-'} ₹${NumberFormat.currency(locale: 'en_IN', symbol: '', decimalDigits: 0).format(amt.abs())}",
                        style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: isIncome ? const Color(0xFF046A38) : const Color(0xFFE05F00)),
                      ),
                      Text('${pct.toStringAsFixed(1)}% of income', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context))),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Save Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF064E3B), const Color(0xFF047857)]
                  : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isDark ? const Color(0xFF065F46) : const Color(0xFF6EE7B7),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Row(
            children: [
              const Text('💾', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Save FOIR Report',
                      style: AppTextStyles.dmSans(
                        size: 12,
                        weight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF07543A),
                      ),
                    ),
                    Text(
                      'Useful for bank loan application prep',
                      style: AppTextStyles.dmSans(
                        size: 9.5,
                        color: isDark ? Colors.white70 : const Color(0xFF046A38),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _saveCalculation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF046A38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text('Save', style: AppTextStyles.dmSans(size: 10, color: Colors.white, weight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Widget Builders ---

  Widget _buildSliderRow(
    String title,
    double val,
    double min,
    double max,
    int divisions,
    ValueChanged<double> onChanged,
  ) {
    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFF5E6D4);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.dmSans(size: 10, color: theme.getMutedColor(context), weight: FontWeight.w700),
              ),
              Text(
                _fmt(val),
                style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: theme.getTextColor(context)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: const Color(0xFFFF6B00),
              inactiveTrackColor: inactiveColor,
              thumbColor: const Color(0xFFFF6B00),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
            ),
            child: Slider(
              value: val.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoirBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white70)),
            const SizedBox(height: 3),
            Text(
              value,
              style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.w800, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneRow(String title, String desc, String pct, Color color) {
    final theme = widget.theme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 3),
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: theme.getTextColor(context))),
              Text(desc, style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context))),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          pct,
          style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: color),
        ),
      ],
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
