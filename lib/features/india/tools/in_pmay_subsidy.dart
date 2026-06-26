// lib/features/india/tools/in_pmay_subsidy.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../core/utils/compat.dart';

class INPMAYSubsidy extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INPMAYSubsidy({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INPMAYSubsidy> createState() => _INPMAYSubsidyState();
}

class _INPMAYSubsidyState extends ConsumerState<INPMAYSubsidy> {
  String _selCat = 'EWS';
  double _loanAmt = 2500000;
  int _tenure = 20;
  double _bankRate = 8.50;

  final Map<String, Map<String, dynamic>> _cats = const {
    'EWS': {'rate': 6.5, 'maxLoan': 600000.0, 'maxTenure': 20, 'label': 'EWS', 'maxNPV': 267280.0},
    'LIG': {'rate': 6.5, 'maxLoan': 600000.0, 'maxTenure': 20, 'label': 'LIG', 'maxNPV': 267280.0},
    'MIG1': {'rate': 4.0, 'maxLoan': 900000.0, 'maxTenure': 20, 'label': 'MIG-I', 'maxNPV': 235068.0},
    'MIG2': {'rate': 3.0, 'maxLoan': 1200000.0, 'maxTenure': 20, 'label': 'MIG-II', 'maxNPV': 230156.0},
  };

  void _reset() {
    setState(() {
      _selCat = 'EWS';
      _loanAmt = 2500000;
      _tenure = 20;
      _bankRate = 8.50;
    });
  }

  double _emi(double p, double r, int n) {
    final m = r / 1200;
    return p * m * pow(1 + m, n) / (pow(1 + m, n) - 1);
  }

  String _fmt(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(2)} L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }

  void _saveCalculation() async {
    final cat = _cats[_selCat]!;
    final eligibleLoan = min(_loanAmt, cat['maxLoan'] as double);
    final subRate = cat['rate'] as double;
    final mBefore = _bankRate / 1200;
    final mSubsidised = (_bankRate - subRate) / 1200;
    final nMonths = min(_tenure, cat['maxTenure'] as int) * 12;

    final emiB = eligibleLoan * mBefore * pow(1 + mBefore, nMonths) / (pow(1 + mBefore, nMonths) - 1);
    final emiA = mSubsidised > 0
        ? eligibleLoan * mSubsidised * pow(1 + mSubsidised, nMonths) / (pow(1 + mSubsidised, nMonths) - 1)
        : eligibleLoan / nMonths;

    final maxNPV = cat['maxNPV'] as double;
    final finalSubsidy = min((emiB - emiA) * nMonths, maxNPV);
    final netLoan = _loanAmt - finalSubsidy;

    final labelCtrl = TextEditingController(text: 'PMAY Subsidy - ${cat['label']}');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save PMAY Subsidy', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving: Subsidy ${_fmt(finalSubsidy)} · Net Loan ${_fmt(netLoan)}',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My PMAY Subsidy)',
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
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'PMAY Subsidy';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'PMAY Subsidy',
        inputs: {
          'loanAmt': _loanAmt,
          'tenure': _tenure.toDouble(),
          'bankRate': _bankRate,
          'catIndex': _cats.keys.toList().indexOf(_selCat).toDouble(),
        },
        results: {
          'subsidy': finalSubsidy,
          'netLoan': netLoan,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ PMAY Subsidy saved!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
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

    final cat = _cats[_selCat]!;
    final eligibleLoan = min(_loanAmt, cat['maxLoan'] as double);
    final subRate = cat['rate'] as double;
    final mBefore = _bankRate / 1200;
    final mSubsidised = (_bankRate - subRate) / 1200;
    final nMonths = min(_tenure, cat['maxTenure'] as int) * 12;

    final emiB = eligibleLoan * mBefore * pow(1 + mBefore, nMonths) / (pow(1 + mBefore, nMonths) - 1);
    final emiA = mSubsidised > 0
        ? eligibleLoan * mSubsidised * pow(1 + mSubsidised, nMonths) / (pow(1 + mSubsidised, nMonths) - 1)
        : eligibleLoan / nMonths;

    final maxNPV = cat['maxNPV'] as double;
    final finalSubsidy = min((emiB - emiA) * nMonths, maxNPV);
    final netLoan = _loanAmt - finalSubsidy;

    final emiWithout = _emi(_loanAmt, _bankRate, _tenure * 12);
    final emiWithSub = _emi(netLoan, _bankRate, _tenure * 12);
    final saving = emiWithout - emiWithSub;
    final savePct = emiWithout > 0 ? (saving / emiWithout) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Slabs grid
        Text('SELECT HOUSEHOLD INCOME CATEGORY', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.w800)),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: _cats.entries.map((e) {
            final active = _selCat == e.key;
            final label = e.value['label'] as String;
            final maxLoanVal = e.value['maxLoan'] as double;
            final subRateVal = e.value['rate'] as double;

            return GestureDetector(
              onTap: () => setState(() => _selCat = e.key),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFE05F00) : theme.getCardColor(context),
                  border: Border.all(color: active ? const Color(0xFFE05F00) : theme.getBorderColor(context)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: active ? Colors.white : theme.getTextColor(context))),
                    const SizedBox(height: 2),
                    Text('Max loan ₹${(maxLoanVal / 100000).toStringAsFixed(0)}L',
                        style: AppTextStyles.dmSans(size: 9.5, color: active ? Colors.white70 : theme.getMutedColor(context))),
                    Text('Subsidy rate: ${subRateVal.toStringAsFixed(1)}%',
                        style: AppTextStyles.dmSans(size: 9.5, color: active ? Colors.white70 : theme.getMutedColor(context))),
                  ],
                ),
              ),
            );
          }).toList(),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subsidy Parameters', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.w700)),
                  GestureDetector(
                    onTap: _reset,
                    child: Text('Reset ↺', style: AppTextStyles.dmSans(size: 11, color: const Color(0xFFE05F00), weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Loan Amount Slider
              _buildSliderRow('PROPOSED HOME LOAN', _loanAmt, 500000, 10000000, 95, (v) => setState(() => _loanAmt = v)),
              // Tenure Slider
              _buildSliderRow('LOAN TENURE (YEARS)', _tenure.toDouble(), 5, 30, 25, (v) => setState(() => _tenure = v.toInt())),
              // Bank Rate Slider
              _buildSliderRow('BANK HOME LOAN RATE', _bankRate, 6.50, 14.00, 150, (v) => setState(() => _bankRate = v)),
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
              Text('ESTIMATED GOVT INTEREST SUBSIDY (NPV)', style: AppTextStyles.dmSans(size: 9, color: Colors.white70, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                _fmt(finalSubsidy),
                style: AppTextStyles.playfair(size: 34, color: const Color(0xFFFFDEA0), weight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _resultBox('Net Loan size', _fmt(netLoan)),
                  const SizedBox(width: 8),
                  _resultBox('EMI w/o Subsidy', '₹${Math.round(emiWithout).toLocaleString()}/mo'),
                  const SizedBox(width: 8),
                  _resultBox('EMI w/ Subsidy', '₹${Math.round(emiWithSub).toLocaleString()}/mo'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Savings details
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
              Text('📊 Monthly Savings Benefit', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: theme.getTextColor(context))),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('EMI Monthly Savings:', style: AppTextStyles.dmSans(size: 11.5, color: theme.getMutedColor(context))),
                  Text('₹${Math.round(saving).toLocaleString()}/mo', style: AppTextStyles.dmSans(size: 12.5, weight: FontWeight.bold, color: const Color(0xFF046A38))),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Interest Saved (NPV):', style: AppTextStyles.dmSans(size: 11.5, color: theme.getMutedColor(context))),
                  Text(_fmt(finalSubsidy), style: AppTextStyles.dmSans(size: 12, weight: FontWeight.bold, color: theme.getTextColor(context))),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Container(
                  height: 6,
                  color: Colors.grey[200],
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: savePct.clamp(0.0, 1.0),
                    child: Container(color: const Color(0xFF046A38)),
                  ),
                ),
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
                    Text('Save Subsidy Details', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF07543A))),
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
}
