// lib/features/india/tools/in_gst_calculator.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class INGSTCalculator extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INGSTCalculator({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INGSTCalculator> createState() => _INGSTCalculatorState();
}

class _INGSTCalculatorState extends ConsumerState<INGSTCalculator> {
  double _propPrice = 4500000;
  String _slabKey = 'affordable';
  String _txnType = 'exclusive'; // 'exclusive', 'inclusive'

  final Map<String, Map<String, dynamic>> _slabs = const {
    'affordable': {
      'rate': 1.0,
      'title': 'Affordable Housing — 1% GST',
      'desc': 'Carpet area ≤ 60 sqm (metro) / 90 (non-metro) · Value ≤ ₹45 L · No ITC',
      'itc': false
    },
    'regular': {
      'rate': 5.0,
      'title': 'Regular Housing — 5% GST',
      'desc': 'Under-construction residential not qualifying as affordable · No ITC',
      'itc': false
    },
    'commercial': {
      'rate': 12.0,
      'title': 'Commercial Property — 12% GST',
      'desc': 'Under-construction commercial / shops / offices · ITC available',
      'itc': true
    },
    'nil': {
      'rate': 0.0,
      'title': 'Ready-to-Move — NIL GST',
      'desc': 'Completion Certificate / Occupancy Certificate received · No GST applicable',
      'itc': false
    },
  };

  void _reset() {
    setState(() {
      _propPrice = 4500000;
      _slabKey = 'affordable';
      _txnType = 'exclusive';
    });
  }

  String _fmt(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(2)} L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }

  String _fmtShort(double n) {
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(1)}L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
  }

  void _saveCalculation() async {
    final slab = _slabs[_slabKey]!;
    final rate = slab['rate'] as double;
    double base, gst, total;

    if (_txnType == 'exclusive') {
      base = _propPrice;
      gst = base * rate / 100;
      total = base + gst;
    } else {
      total = _propPrice;
      base = total / (1 + rate / 100);
      gst = total - base;
    }
    final cgst = gst / 2;

    final labelCtrl = TextEditingController(text: 'GST - ${slab['title']}');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save GST Calc', style: AppTextStyles.playfair(size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saving: GST ${_fmt(gst)} · Base ${_fmt(base)} · Total ${_fmt(total)}',
                style: AppTextStyles.dmSans(size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My Flat GST)',
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
      final label = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'Property GST';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: 'GST Calculator',
        inputs: {
          'propPrice': _propPrice,
          'slabIndex': _slabs.keys.toList().indexOf(_slabKey).toDouble(),
          'txnType': _txnType == 'exclusive' ? 0.0 : 1.0,
        },
        results: {
          'basePrice': base,
          'gstAmount': gst,
          'cgst': cgst,
          'totalPrice': total,
        },
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ GST calculation saved!', style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
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

    final slab = _slabs[_slabKey]!;
    final rate = slab['rate'] as double;
    final itcAvailable = slab['itc'] as bool;
    double base, gst, total;

    if (_txnType == 'exclusive') {
      base = _propPrice;
      gst = base * rate / 100;
      total = base + gst;
    } else {
      total = _propPrice;
      base = total / (1 + rate / 100);
      gst = total - base;
    }
    final cgst = gst / 2;
    final sgst = gst / 2;

    final pctBase = total > 0 ? (base / total) : 0.0;
    final pctGst = total > 0 ? (gst / total) : 0.0;

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
                  Text('GST Parameters', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.w700)),
                  GestureDetector(
                    onTap: _reset,
                    child: Text('Reset ↺', style: AppTextStyles.dmSans(size: 11, color: const Color(0xFFE05F00), weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Property cost Slider
              _buildSliderRow('PROPERTY AGREEMENT VALUE', _propPrice, 500000, 20000000, 195, (v) => setState(() => _propPrice = v)),

              // Slabs toggles
              Text('SELECT GST SLAB CATEGORY', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.w800)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _slabs.entries.map((e) {
                  final key = e.key;
                  final title = key == 'affordable'
                      ? 'Affordable (1%)'
                      : key == 'regular'
                          ? 'Regular (5%)'
                          : key == 'commercial'
                              ? 'Comm. (12%)'
                              : 'Ready (0%)';
                  final active = _slabKey == key;
                  return GestureDetector(
                    onTap: () => setState(() => _slabKey = key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFFE05F00) : Colors.transparent,
                        border: Border.all(color: active ? const Color(0xFFE05F00) : theme.getBorderColor(context)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        title,
                        style: AppTextStyles.dmSans(
                          size: 10,
                          weight: FontWeight.w700,
                          color: active ? Colors.white : theme.getMutedColor(context),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFFF7EE), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(slab['title'] as String, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.bold, color: const Color(0xFFE05F00))),
                    const SizedBox(height: 2),
                    Text(slab['desc'] as String, style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // Transaction type toggle (Inclusive vs Exclusive)
              Text('TRANSACTION BASIS', style: AppTextStyles.dmSans(size: 9, color: theme.getMutedColor(context), weight: FontWeight.w800)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildToggleBtn('GST Exclusive', _txnType == 'exclusive', () => setState(() => _txnType = 'exclusive'))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildToggleBtn('GST Inclusive', _txnType == 'inclusive', () => setState(() => _txnType = 'inclusive'))),
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
              Text('TOTAL TAX GST AMOUNT', style: AppTextStyles.dmSans(size: 9, color: Colors.white70, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                _fmt(gst),
                style: AppTextStyles.playfair(size: 34, color: const Color(0xFFFFDEA0), weight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _resultBox('Base Value', _fmt(base)),
                  const SizedBox(width: 8),
                  _resultBox('CGST (50%)', _fmt(cgst)),
                  const SizedBox(width: 8),
                  _resultBox('SGST (50%)', _fmt(sgst)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Donut / Pie Breakdown card
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
              Text('📊 Cost Share Breakdown', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: theme.getTextColor(context))),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 12,
                          color: Color(0xFFE05F00), // GST Amount
                        ),
                        CircularProgressIndicator(
                          value: pctBase,
                          strokeWidth: 12,
                          color: const Color(0xFF1A3A8F), // Base Amount
                        ),
                        Text('${(pctGst * 100).round()}%', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: theme.getTextColor(context))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        _legendRow(const Color(0xFF1A3A8F), 'Base Property Cost', _fmtShort(base)),
                        const SizedBox(height: 8),
                        _legendRow(const Color(0xFFE05F00), 'GST Outgo (${rate.toStringAsFixed(0)}%)', _fmtShort(gst)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Input Tax Credit (ITC) Available:', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context))),
                  Text(
                    itcAvailable ? 'YES' : 'NO',
                    style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.bold, color: itcAvailable ? const Color(0xFF046A38) : const Color(0xFFDC2626)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Cost Payable to Builder:', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context))),
                  Text(_fmt(total), style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.bold, color: theme.getTextColor(context))),
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
                    Text('Save GST Details', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF07543A))),
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
