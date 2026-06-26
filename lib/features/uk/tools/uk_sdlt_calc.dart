// lib/features/uk/tools/uk_sdlt_calc.dart

import 'package:flutter/material.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import 'dart:math' as math;

class UKMortgageCalcSheet extends StatefulWidget {
  final double propertyValue;
  final double depositPercent;
  final int termYears;

  const UKMortgageCalcSheet({
    super.key,
    required this.propertyValue,
    required this.depositPercent,
    required this.termYears,
  });

  @override
  State<UKMortgageCalcSheet> createState() => _UKMortgageCalcSheetState();
}

class _UKMortgageCalcSheetState extends State<UKMortgageCalcSheet> {
  late double _price;
  late double _depPct;
  late int _term;
  double _rate = 4.75;

  @override
  void initState() {
    super.initState();
    _price = widget.propertyValue;
    _depPct = widget.depositPercent;
    _term = widget.termYears;
  }

  double _calculatePmt() {
    final loan = _price * (1 - _depPct / 100);
    final rMo = _rate / 100 / 12;
    final nMo = _term * 12;
    if (rMo == 0) return loan / nMo;
    return loan * (rMo * math.pow(1 + rMo, nMo)) / (math.pow(1 + rMo, nMo) - 1);
  }

  @override
  Widget build(BuildContext context) {
    final pmt = _calculatePmt();
    final loan = _price * (1 - _depPct / 100);
    final depVal = _price * _depPct / 100;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1224) : Colors.white;
    final textCol = isDark ? Colors.white : const Color(0xFF0D0D2B);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Mortgage Estimate',
                  style: AppTextStyles.dmSans(size: 18, weight: FontWeight.w800, color: textCol),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF14145A), Color(0xFF1A1A6B)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ESTIMATED MONTHLY PAYMENT', style: AppTextStyles.dmSans(size: 9, color: Colors.white70, weight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(pmt, symbol: '£'),
                    style: AppTextStyles.dmSans(size: 32, weight: FontWeight.w800, color: Colors.white).copyWith(fontFamily: 'Georgia'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Loan Amount: ${CurrencyFormatter.format(loan, symbol: '£')} · Deposit: ${CurrencyFormatter.format(depVal, symbol: '£')} (${_depPct.toInt()}%)',
                    style: AppTextStyles.dmSans(size: 11, color: Colors.white60),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _sliderGroup('Property Price', _price, 10000, 1500000, '£', (v) => setState(() => _price = v)),
            _sliderGroup('Deposit Percentage', _depPct, 5, 95, '%', (v) => setState(() => _depPct = v)),
            _sliderGroup('Interest Rate', _rate, 1, 15, '%', (v) => setState(() => _rate = v), isDecimal: true),
            _sliderGroup('Term (Years)', _term.toDouble(), 5, 35, ' yrs', (v) => setState(() => _term = v.toInt())),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sliderGroup(String label, double val, double min, double max, String suffix, ValueChanged<double> onChanged, {bool isDecimal = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? Colors.white : const Color(0xFF0D0D2B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w700, color: textCol)),
            Text(
              suffix == '£' ? CurrencyFormatter.format(val, symbol: '£').split('.').first : '${isDecimal ? val.toStringAsFixed(2) : val.toInt()}$suffix',
              style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E)),
            ),
          ],
        ),
        Slider(
          value: val.clamp(min, max),
          min: min,
          max: max,
          activeColor: isDark ? const Color(0xFF93C5FD) : const Color(0xFF14145A),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class UKSDLTCalcSheet extends StatefulWidget {
  final double propertyValue;

  const UKSDLTCalcSheet({
    super.key,
    required this.propertyValue,
  });

  @override
  State<UKSDLTCalcSheet> createState() => _UKSDLTCalcSheetState();
}

class _UKSDLTCalcSheetState extends State<UKSDLTCalcSheet> {
  late double _price;
  String _buyerType = 'ftb'; // ftb, std, surcharge

  @override
  void initState() {
    super.initState();
    _price = widget.propertyValue;
  }

  double _calculateSDLT() {
    double total = 0;
    double surcharge = _buyerType == 'surcharge' ? 3.0 : 0.0;
    List<Map<String, dynamic>> bands = _buyerType == 'ftb' && _price <= 500000 ? [
      {'from': 0.0, 'to': 300000.0, 'rate': 0.0},
      {'from': 300000.0, 'to': 500000.0, 'rate': 5.0},
    ] : [
      {'from': 0.0, 'to': 250000.0, 'rate': 0.0},
      {'from': 250000.0, 'to': 925000.0, 'rate': 5.0},
      {'from': 925000.0, 'to': 1500000.0, 'rate': 10.0},
      {'from': 1500000.0, 'to': double.infinity, 'rate': 12.0},
    ];

    for (var b in bands) {
      final from = b['from'] as double;
      final to = b['to'] as double;
      if (_price <= from) break;

      final taxable = math.min(_price, to) - from;
      final rate = (b['rate'] as double) + surcharge;
      total += (taxable * rate / 100);
    }
    return total.roundToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final sdlt = _calculateSDLT();
    final eff = _price > 0 ? (sdlt / _price * 100) : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1224) : Colors.white;
    final textCol = isDark ? Colors.white : const Color(0xFF0D0D2B);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stamp Duty (SDLT) Estimate',
                style: AppTextStyles.dmSans(size: 18, weight: FontWeight.w800, color: textCol),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFC8102E), Color(0xFF8B0A1E)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ESTIMATED STAMP DUTY', style: AppTextStyles.dmSans(size: 9, color: Colors.white70, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(sdlt, symbol: '£'),
                  style: AppTextStyles.dmSans(size: 32, weight: FontWeight.w800, color: Colors.white).copyWith(fontFamily: 'Georgia'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Effective Rate: ${eff.toStringAsFixed(2)}% · Property Value: ${CurrencyFormatter.format(_price, symbol: '£')}',
                  style: AppTextStyles.dmSans(size: 11, color: Colors.white60),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Property Value', style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w700, color: textCol)),
              Text(
                CurrencyFormatter.format(_price, symbol: '£').split('.').first,
                style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E)),
              ),
            ],
          ),
          Slider(
            value: _price.clamp(50000, 2000000),
            min: 50000,
            max: 2000000,
            activeColor: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E),
            onChanged: (v) => setState(() => _price = v),
          ),
          const SizedBox(height: 10),
          Text('BUYER SITUATION', style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buyerBtn('First Time', 'ftb'),
              const SizedBox(width: 8),
              _buyerBtn('Standard Mover', 'std'),
              const SizedBox(width: 8),
              _buyerBtn('Additional Surcharge', 'surcharge'),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buyerBtn(String label, String type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = _buyerType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _buyerType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF14145A))
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.dmSans(
              size: 10.5,
              weight: FontWeight.w700,
              color: active
                  ? (isDark ? const Color(0xFF0D0D2B) : Colors.white)
                  : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
