// lib/features/uk/tools/uk_sdlt_calculator.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/uk_rates_provider.dart';
import '../../../shared/models/saved_calc.dart';
import 'dart:math' as math;

class UKSdltCalculator extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;
  const UKSdltCalculator({super.key, required this.theme, this.savedCalc});

  @override
  ConsumerState<UKSdltCalculator> createState() => _UKSdltCalculatorState();
}

class _UKSdltCalculatorState extends ConsumerState<UKSdltCalculator> {
  String _buyerType = 'ftb'; // ftb, std, 2nd, btl
  String _region = 'england'; // england, scotland, wales
  String _propType = 'residential'; // residential, commercial

  final _priceController = TextEditingController(text: '380000');
  double _price = 380000;

  bool _hasCalculated = false;

  // England SDLT (post April 2025)
  final List<Map<String, dynamic>> englandStd = const [
    {'from': 0.0, 'to': 250000.0, 'rate': 0.0},
    {'from': 250000.0, 'to': 925000.0, 'rate': 5.0},
    {'from': 925000.0, 'to': 1500000.0, 'rate': 10.0},
    {'from': 1500000.0, 'to': double.infinity, 'rate': 12.0},
  ];

  final List<Map<String, dynamic>> englandFtb = const [
    {'from': 0.0, 'to': 300000.0, 'rate': 0.0},
    {'from': 300000.0, 'to': 500000.0, 'rate': 5.0},
    {'from': 500000.0, 'to': 925000.0, 'rate': 5.0}, // Reverts to std rate above 500K (no relief at all, but handled band by band)
    {'from': 925000.0, 'to': 1500000.0, 'rate': 10.0},
    {'from': 1500000.0, 'to': double.infinity, 'rate': 12.0},
  ];

  // Scotland LBTT
  final List<Map<String, dynamic>> scotlandStd = const [
    {'from': 0.0, 'to': 145000.0, 'rate': 0.0},
    {'from': 145000.0, 'to': 250000.0, 'rate': 2.0},
    {'from': 250000.0, 'to': 325000.0, 'rate': 5.0},
    {'from': 325000.0, 'to': 750000.0, 'rate': 10.0},
    {'from': 750000.0, 'to': double.infinity, 'rate': 12.0},
  ];

  // Wales LTT
  final List<Map<String, dynamic>> walesStd = const [
    {'from': 0.0, 'to': 225000.0, 'rate': 0.0},
    {'from': 225000.0, 'to': 400000.0, 'rate': 6.0},
    {'from': 400000.0, 'to': 750000.0, 'rate': 7.5},
    {'from': 750000.0, 'to': 1500000.0, 'rate': 10.0},
    {'from': 1500000.0, 'to': double.infinity, 'rate': 12.0},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _priceController.text = (inputs['price'] ?? 380000.0).toStringAsFixed(0);
      _buyerType = widget.savedCalc!.label.contains('First-Time')
          ? 'ftb'
          : (widget.savedCalc!.label.contains('2nd Home') ? '2nd' : 'std');
      _hasCalculated = true;
    }
    _calculateValues();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _calculateValues() {
    setState(() {
      _price = double.tryParse(_priceController.text) ?? 0;
    });
  }

  Map<String, dynamic> _compute(double price, List<Map<String, dynamic>> bands, double surcharge) {
    double total = 0;
    final List<Map<String, dynamic>> rows = [];

    for (var b in bands) {
      final from = b['from'] as double;
      final to = b['to'] as double;

      if (price <= from) break;

      final taxable = math.min(price, to) - from;
      final rate = (b['rate'] as double) + surcharge;
      final tax = (taxable * rate / 100).roundToDouble();

      rows.add({
        'band': '${CurrencyFormatter.compact(from, symbol: '£')}–${to == double.infinity ? '+' : CurrencyFormatter.compact(to, symbol: '£')}',
        'rate': rate,
        'taxable': taxable,
        'tax': tax,
      });

      total += tax;
    }

    return {'total': total, 'rows': rows};
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = widget.theme.getCardColor(context);
    final textThemeColor = isDark ? Colors.white : const Color(0xFF0D0D2B);
    final borderCol = widget.theme.getBorderColor(context);

    // Live BoE base rate for context
    final ukRates = ref.watch(ukRatesProvider).valueOrNull;
    final boeBase  = ukRates?.boeBase.value ?? 4.25;
    final isLive   = ukRates?.isLive == true;

    // Determine bands and surcharge
    List<Map<String, dynamic>> activeBands = englandStd;
    double surcharge = 0.0;
    String regionLabel = 'England (SDLT)';
    String taxName = 'SDLT';

    if (_region == 'scotland') {
      activeBands = scotlandStd;
      regionLabel = 'Scotland (LBTT)';
      taxName = 'LBTT';
    } else if (_region == 'wales') {
      activeBands = walesStd;
      regionLabel = 'Wales (LTT)';
      taxName = 'LTT';
    } else {
      if (_buyerType == 'ftb' && _price <= 500000) {
        activeBands = englandFtb;
      } else {
        activeBands = englandStd;
      }
      if (_buyerType == '2nd' || _buyerType == 'btl') {
        surcharge = 3.0;
      }
    }

    final computed = _compute(_price, activeBands, surcharge);
    final double sdlt = computed['total'];
    final List<Map<String, dynamic>> rows = List<Map<String, dynamic>>.from(computed['rows']);

    final computedStd = _compute(_price, englandStd, 0);
    final double stdSDLT = computedStd['total'];
    final saving = math.max(0.0, stdSDLT - sdlt);

    final effRate = _price > 0 ? (sdlt / _price * 100) : 0.0;
    final totalCost = _price + sdlt;

    // Scenarios for comparison
    final double ftbVal = _compute(_price, _price <= 500000 ? englandFtb : englandStd, 0)['total'];
    final double stdVal = _compute(_price, englandStd, 0)['total'];
    final double extraVal = _compute(_price, englandStd, 3)['total'];
    final double maxCompare = math.max(1.0, math.max(ftbVal, math.max(stdVal, extraVal)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.theme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderCol),
          ),
          child: Row(
            children: [
              Expanded(child: _rateCell('FTB Relief', '£300K', '0% threshold', isDark ? const Color(0xFFFFD700) : const Color(0xFFD97706))),
              _divider(),
              Expanded(child: _rateCell('Standard', '£250K', '0% band', textThemeColor)),
              _divider(),
              Expanded(child: _rateCell('2nd Home', '+3%', 'Surcharge', isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E))),
              _divider(),
              Expanded(child: _rateCell('BoE Base', '${boeBase.toStringAsFixed(2)}%${isLive ? ' 🟢' : ''}', 'Mortgage ref', isDark ? const Color(0xFFFFD700) : const Color(0xFFD97706))),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Buyer type selector
        Row(
          children: [
            _buyerTabButton('First-Time', 'ftb'),
            _buyerTabButton('Standard', 'std'),
            _buyerTabButton('2nd Home', '2nd'),
            _buyerTabButton('Buy-to-Let', 'btl'),
          ],
        ),
        const SizedBox(height: 14),

        // Inputs Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _inputField(label: 'Property Purchase Price (£)', controller: _priceController),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('REGION', style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w700, color: widget.theme.getMutedColor(context))),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _region,
                              dropdownColor: cardBg,
                              isExpanded: true,
                              style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700, color: textThemeColor),
                              items: const [
                                DropdownMenuItem(value: 'england', child: Text('England (SDLT)')),
                                DropdownMenuItem(value: 'scotland', child: Text('Scotland (LBTT)')),
                                DropdownMenuItem(value: 'wales', child: Text('Wales (LTT)')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _region = val;
                                    _calculateValues();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PROPERTY TYPE', style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w700, color: widget.theme.getMutedColor(context))),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _propType,
                              dropdownColor: cardBg,
                              isExpanded: true,
                              style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700, color: textThemeColor),
                              items: const [
                                DropdownMenuItem(value: 'residential', child: Text('Residential')),
                                DropdownMenuItem(value: 'commercial', child: Text('Commercial')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _propType = val;
                                    _calculateValues();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Calculate Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC8102E),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
            ),
            onPressed: () {
              _calculateValues();
              setState(() => _hasCalculated = true);
            },
            child: Text(
              '👑 Calculate Stamp Duty',
              style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (_hasCalculated) ...[
          // Results Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D0D2B), Color(0xFF1A1A5E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$taxName — $regionLabel',
                  style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w700, color: Colors.white60, letterSpacing: 0.7),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      CurrencyFormatter.format(sdlt, symbol: '£').split('.').first,
                      style: AppTextStyles.dmSans(size: 34, weight: FontWeight.w800, color: const Color(0xFFFFD700)).copyWith(fontFamily: 'Georgia'),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final calc = SavedCalc.create(
                          country: 'UK',
                          calcType: 'Stamp Duty Standalone',
                          inputs: {
                            'price': _price,
                          },
                          results: {
                            'Stamp Duty': sdlt,
                            'Effective Rate': effRate,
                            'Total Cost': totalCost,
                            'Saving': saving,
                          },
                          label: '${_buyerType.toUpperCase()} buyer · ${CurrencyFormatter.compact(_price, symbol: '£')} property',
                          currencyCode: 'GBP',
                        );
                        final messenger = ScaffoldMessenger.of(context);
                        await ref.read(savedProvider.notifier).save(calc);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('✓ SDLT calculation saved'),
                            backgroundColor: Color(0xFF0D9488),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.save, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text('Save', style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _infoCell('Effective Rate', '${effRate.toStringAsFixed(2)}%'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _infoCell('Buyer Type', _buyerType == 'ftb' ? 'First-Time' : 'Standard'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _infoCell('SDLT Saving', saving > 0 ? CurrencyFormatter.format(saving, symbol: '£').split('.').first : '£0'),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Cost (Price + SDLT)', style: AppTextStyles.dmSans(size: 11, color: Colors.white60)),
                    Text(
                      CurrencyFormatter.format(totalCost, symbol: '£').split('.').first,
                      style: AppTextStyles.dmSans(size: 15, weight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Cost Distribution Donut
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cost Distribution Visual Split',
                  style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textThemeColor).copyWith(fontFamily: 'Georgia'),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: Stack(
                        children: [
                          CustomPaint(
                            size: const Size(110, 110),
                            painter: _UKMortgageDonutPainter(
                              interestPct: effRate,
                              isDark: isDark,
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${effRate.toStringAsFixed(1)}%',
                                  style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: textThemeColor).copyWith(fontFamily: 'Georgia'),
                                ),
                                Text(
                                  'of price',
                                  style: AppTextStyles.dmSans(size: 8, color: widget.theme.getMutedColor(context), weight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _legendItem(isDark ? const Color(0xFF93C5FD) : const Color(0xFF1a1a5e), 'Property Price', _price),
                          const SizedBox(height: 6),
                          _legendItem(isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E), 'SDLT Due', sdlt),
                          const SizedBox(height: 6),
                          _legendItem(const Color(0xFF4F46E5), 'Total Outlay', totalCost),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Band breakdown table
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Band-by-Band Breakdown',
                  style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textThemeColor).copyWith(fontFamily: 'Georgia'),
                ),
                const SizedBox(height: 12),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1.2),
                    1: FlexColumnWidth(1.0),
                    2: FlexColumnWidth(1.0),
                    3: FlexColumnWidth(1.0),
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
                      ),
                      children: [
                        TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('BAND', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: widget.theme.getMutedColor(context))))),
                        TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('RATE', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: widget.theme.getMutedColor(context))))),
                        TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('TAXABLE', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: widget.theme.getMutedColor(context))))),
                        TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('TAX', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w800, color: widget.theme.getMutedColor(context))))),
                      ],
                    ),
                    ...rows.map((r) {
                      final double tx = r['tax'] as double;
                      final double txb = r['taxable'] as double;
                      return TableRow(
                        children: [
                          TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(r['band'] as String, style: AppTextStyles.dmSans(size: 10, color: textThemeColor)))),
                          TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text('${r['rate']}%', style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E))))),
                          TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(txb > 0 ? CurrencyFormatter.compact(txb, symbol: '£') : '—', style: AppTextStyles.dmSans(size: 10, color: textThemeColor)))),
                          TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(tx > 0 ? CurrencyFormatter.compact(tx, symbol: '£') : '£0', style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5))))),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Buyer Type Comparison
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Buyer Type Comparison',
                  style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textThemeColor).copyWith(fontFamily: 'Georgia'),
                ),
                const SizedBox(height: 12),
                _compareBarRow('First-Time Buyer', ftbVal, isDark ? const Color(0xFF34D399) : const Color(0xFF047857), maxCompare),
                const SizedBox(height: 8),
                _compareBarRow('Standard Buyer', stdVal, isDark ? const Color(0xFF93C5FD) : const Color(0xFF1a1a5e), maxCompare),
                const SizedBox(height: 8),
                _compareBarRow('2nd Home / BTL', extraVal, isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC8102E), maxCompare),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Info Notice
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF121230)])
                  : const LinearGradient(colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)]),
              border: Border.all(color: isDark ? const Color(0xFF4338CA).withValues(alpha: 0.5) : const Color(0xFFA5B4FC)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Important Notice',
                        style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1E1B4B)),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Rates reflect HMRC SDLT thresholds effective from 1 April 2025 (temporary FTB threshold reverted to £300K). Verify with HMRC or a solicitor before completion. Figures are estimates only.',
                        style: AppTextStyles.dmSans(size: 9.5, color: isDark ? const Color(0xFFC7D2FE) : const Color(0xFF4338CA), height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _compareBarRow(String label, double val, Color color, double max) {
    final pct = max > 0 ? (val / max) : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: AppTextStyles.dmSans(size: 10, color: widget.theme.getMutedColor(context), weight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Container(
              height: 26,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEEF2FF),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: pct.clamp(0.0, 1.0),
                  child: Container(
                    color: color,
                    padding: const EdgeInsets.only(left: 8),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      val > 0 ? '' : '£0',
                      style: AppTextStyles.dmSans(size: 9.5, color: Colors.white, weight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 60,
          child: Text(
            CurrencyFormatter.compact(val, symbol: '£'),
            style: AppTextStyles.dmSans(size: 10, weight: FontWeight.w800, color: widget.theme.getTextColor(context)),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label, double value) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: AppTextStyles.dmSans(size: 10, color: widget.theme.getTextColor(context).withValues(alpha: 0.7))),
        ),
        Text(
          CurrencyFormatter.format(value, symbol: '£').split('.').first,
          style: AppTextStyles.dmSans(size: 10.5, weight: FontWeight.w800, color: widget.theme.getTextColor(context)),
        ),
      ],
    );
  }

  Widget _infoCell(String label, String val) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white54)),
          const SizedBox(height: 2),
          Text(val, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buyerTabButton(String label, String type) {
    final active = _buyerType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _buyerType = type;
          _calculateValues();
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF0D0D2B)
                : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
            border: Border(
              right: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            children: [
              Text(
                label,
                style: AppTextStyles.dmSans(
                  size: 10.5,
                  weight: FontWeight.w800,
                  color: active ? const Color(0xFFFFD700) : widget.theme.getTextColor(context),
                ),
              ),
              Text(
                type == 'ftb'
                    ? 'FTB Relief'
                    : type == 'std'
                        ? 'Main home'
                        : '+3% surcharge',
                style: AppTextStyles.dmSans(
                  size: 8,
                  color: active ? Colors.white70 : widget.theme.getMutedColor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rateCell(String label, String value, String note, Color valueColor) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(size: 8, color: widget.theme.getMutedColor(context), weight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w800, color: valueColor),
        ),
        Text(
          note,
          style: AppTextStyles.dmSans(size: 8, color: widget.theme.getMutedColor(context)),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.grey.withValues(alpha: 0.2),
    );
  }

  Widget _inputField({required String label, required TextEditingController controller}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 8.5,
            weight: FontWeight.w700,
            color: widget.theme.getMutedColor(context),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => _calculateValues(),
          style: AppTextStyles.dmSans(
            size: 13,
            weight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0D0D2B),
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F8),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _UKMortgageDonutPainter extends CustomPainter {
  final double interestPct;
  final bool isDark;

  _UKMortgageDonutPainter({required this.interestPct, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;

    final bgPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEEF2FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawCircle(center, radius, bgPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);

    final principalPaint = Paint()
      ..color = isDark ? const Color(0xFF93C5FD) : const Color(0xFF1a1a5e)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.butt;

    final interestPaint = Paint()
      ..color = const Color(0xFFC8102E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.butt;

    final double interestRad = (interestPct / 100) * 2 * math.pi;
    final double principalRad = 2 * math.pi - interestRad;

    canvas.drawArc(rect, -math.pi / 2, principalRad, false, principalPaint);
    canvas.drawArc(rect, -math.pi / 2 + principalRad, interestRad, false, interestPaint);
  }

  @override
  bool shouldRepaint(covariant _UKMortgageDonutPainter oldDelegate) {
    return oldDelegate.interestPct != interestPct || oldDelegate.isDark != isDark;
  }
}
