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

  bool _hasCalculated = false;
  final Map<dynamic, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};
  final _resultsKey = GlobalKey();

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
    {'from': 500000.0, 'to': 925000.0, 'rate': 5.0},
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
      _buyerType = (inputs['isFTB'] ?? 0.0) == 1.0
          ? 'ftb'
          : ((inputs['is2nd'] ?? 0.0) == 1.0 ? '2nd' : ((inputs['isBtl'] ?? 0.0) == 1.0 ? 'btl' : 'std'));
      _region = (inputs['isScotland'] ?? 0.0) == 1.0
          ? 'scotland'
          : ((inputs['isWales'] ?? 0.0) == 1.0 ? 'wales' : 'england');
      _propType = (inputs['isCommercial'] ?? 0.0) == 1.0 ? 'commercial' : 'residential';
      _calculate();
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  double _val(TextEditingController c, double defaultVal) {
    if (_hasCalculated && _calcSnapshot.containsKey(c)) {
      return _calcSnapshot[c]!;
    }
    return double.tryParse(c.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? defaultVal;
  }

  void _calculate() {
    final errors = <String, String>{};

    final price = double.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (price <= 0) errors['price'] = 'Enter valid purchase price';

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) return;

    setState(() {
      _calcSnapshot[_priceController] = price;
      _calcSnapshot['_buyerType'] = _buyerType;
      _calcSnapshot['_region'] = _region;
      _calcSnapshot['_propType'] = _propType;
      _hasCalculated = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_resultsKey.currentContext != null) {
        Scrollable.ensureVisible(
          _resultsKey.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _resetInputs() {
    setState(() {
      _priceController.text = '380000';
      _buyerType = 'ftb';
      _region = 'england';
      _propType = 'residential';
      _calcSnapshot.clear();
      _errors.clear();
      _hasCalculated = false;
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
    final double priceVal = _val(_priceController, 380000);
    final String activeBuyerType = _hasCalculated ? (_calcSnapshot['_buyerType'] ?? _buyerType) : _buyerType;
    final String activeRegion = _hasCalculated ? (_calcSnapshot['_region'] ?? _region) : _region;
    final String activePropType = _hasCalculated ? (_calcSnapshot['_propType'] ?? _propType) : _propType;

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

    if (activeRegion == 'scotland') {
      activeBands = scotlandStd;
      regionLabel = 'Scotland (LBTT)';
      taxName = 'LBTT';
    } else if (activeRegion == 'wales') {
      activeBands = walesStd;
      regionLabel = 'Wales (LTT)';
      taxName = 'LTT';
    } else {
      if (activeBuyerType == 'ftb' && priceVal <= 500000) {
        activeBands = englandFtb;
      } else {
        activeBands = englandStd;
      }
      if (activeBuyerType == '2nd' || activeBuyerType == 'btl') {
        surcharge = 3.0;
      }
    }

    final computed = _compute(priceVal, activeBands, surcharge);
    final double sdlt = computed['total'];
    final List<Map<String, dynamic>> rows = List<Map<String, dynamic>>.from(computed['rows']);

    final computedStd = _compute(priceVal, englandStd, 0);
    final double stdSDLT = computedStd['total'];
    final saving = math.max(0.0, stdSDLT - sdlt);

    final effRate = priceVal > 0 ? (sdlt / priceVal * 100) : 0.0;
    final totalCost = priceVal + sdlt;

    // Scenarios for comparison
    final double ftbVal = _compute(priceVal, priceVal <= 500000 ? englandFtb : englandStd, 0)['total'];
    final double stdVal = _compute(priceVal, englandStd, 0)['total'];
    final double extraVal = _compute(priceVal, englandStd, 3)['total'];
    final double maxCompare = math.max(1.0, math.max(ftbVal, math.max(stdVal, extraVal)));

    final isDirty = _hasCalculated && (
      (double.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_priceController] ?? 0.0) ||
      _buyerType != (_calcSnapshot['_buyerType'] ?? '') ||
      _region != (_calcSnapshot['_region'] ?? '') ||
      _propType != (_calcSnapshot['_propType'] ?? '')
    );

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

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BUYER SITUATION',
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w700,
                color: widget.theme.getMutedColor(context),
                letterSpacing: 1.0,
              ),
            ),
            GestureDetector(
              onTap: _resetInputs,
              child: Text(
                'Reset',
                style: AppTextStyles.dmSans(
                  size: 11,
                  weight: FontWeight.bold,
                  color: widget.theme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

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
              _inputField(label: 'Property Purchase Price (£)', controller: _priceController, errorText: _errors['price']),
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
              const SizedBox(height: 16),
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
                  onPressed: _calculate,
                  child: Text(
                    '👑 Calculate Stamp Duty',
                    style: AppTextStyles.dmSans(size: 14, weight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_hasCalculated) ...[
          if (isDirty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Text('⚠️ ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(
                      'Inputs have changed. Tap Calculate Stamp Duty to refresh results.',
                      style: AppTextStyles.dmSans(size: 11, color: Colors.amber[800], weight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            key: _resultsKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                                  'price': priceVal,
                                  'isFTB': activeBuyerType == 'ftb' ? 1.0 : 0.0,
                                  'is2nd': activeBuyerType == '2nd' ? 1.0 : 0.0,
                                  'isBtl': activeBuyerType == 'btl' ? 1.0 : 0.0,
                                  'isScotland': activeRegion == 'scotland' ? 1.0 : 0.0,
                                  'isWales': activeRegion == 'wales' ? 1.0 : 0.0,
                                  'isCommercial': activePropType == 'commercial' ? 1.0 : 0.0,
                                },
                                results: {
                                  'Stamp Duty': sdlt,
                                  'Effective Rate': effRate,
                                  'Total Cost': totalCost,
                                  'Saving': saving,
                                },
                                label: '${activeBuyerType.toUpperCase()} buyer · ${CurrencyFormatter.compact(priceVal, symbol: '£')} property',
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
                            child: _infoCell('Buyer Type', activeBuyerType == 'ftb' ? 'First-Time' : 'Standard'),
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

                // Cost Distribution Visual Split
                if (sdlt > 0) ...[
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
                                      interestPct: (sdlt / totalCost * 100),
                                      isDark: isDark,
                                    ),
                                  ),
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${(sdlt / totalCost * 100).toStringAsFixed(1)}%',
                                          style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textThemeColor),
                                        ),
                                        Text(
                                          'tax fraction',
                                          style: AppTextStyles.dmSans(size: 8, color: widget.theme.getMutedColor(context)),
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
                                  _legendItem(isDark ? const Color(0xFF93C5FD) : const Color(0xFF1a1a5e), 'Property price', priceVal),
                                  const SizedBox(height: 8),
                                  _legendItem(const Color(0xFFC8102E), 'Stamp Duty ($taxName)', sdlt),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Tax Bands breakdown
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tax Bands Breakdown',
                        style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textThemeColor),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('BAND', style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: widget.theme.getMutedColor(context))),
                          Text('TAXABLE AMOUNT / TAX DUE', style: AppTextStyles.dmSans(size: 8.5, weight: FontWeight.w800, color: widget.theme.getMutedColor(context))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...rows.map((r) {
                        final double rateVal = r['rate'] as double;
                        final double taxableVal = r['taxable'] as double;
                        final double taxVal = r['tax'] as double;

                        return Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r['band'] as String, style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: textThemeColor)),
                                  const SizedBox(height: 2),
                                  Text('Rate: ${rateVal.toStringAsFixed(1)}%', style: AppTextStyles.dmSans(size: 9.5, color: widget.theme.getMutedColor(context))),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.format(taxVal, symbol: '£').split('.').first,
                                    style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textThemeColor),
                                  ),
                                  Text(
                                    'Taxable: ${CurrencyFormatter.format(taxableVal, symbol: '£').split('.').first}',
                                    style: AppTextStyles.dmSans(size: 8.5, color: widget.theme.getMutedColor(context)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Scenarios Comparison Chart
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buyer Category Comparison',
                        style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textThemeColor),
                      ),
                      const SizedBox(height: 14),
                      _comparisonRow('First-Time Buyer', ftbVal, activeBuyerType == 'ftb', maxCompare),
                      const SizedBox(height: 10),
                      _comparisonRow('Standard Mover', stdVal, activeBuyerType == 'std', maxCompare),
                      const SizedBox(height: 10),
                      _comparisonRow('Additional / BTL', extraVal, activeBuyerType == '2nd' || activeBuyerType == 'btl', maxCompare),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buyerTabButton(String label, String type) {
    final active = _buyerType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark ? const Color(0xFF93C5FD) : const Color(0xFF1a1a5e);
    final textCol = active ? (isDark ? const Color(0xFF0D0D2B) : Colors.white) : widget.theme.getMutedColor(context);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _buyerType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: active ? activeBg : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.dmSans(size: 9.5, weight: FontWeight.w800, color: textCol),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _comparisonRow(String label, double val, bool isCurrent, double max) {
    final pct = val / max;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? Colors.white : const Color(0xFF0D0D2B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label + (isCurrent ? ' (Selected)' : ''),
              style: AppTextStyles.dmSans(
                  size: 11,
                  weight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                  color: isCurrent ? widget.theme.primaryColor : widget.theme.getMutedColor(context)),
            ),
            Text(
              CurrencyFormatter.format(val, symbol: '£').split('.').first,
              style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: textThemeColor),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 14,
            width: double.infinity,
            color: isDark ? Colors.white10 : Colors.black12,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: pct.clamp(0.0, 1.0),
                child: Container(color: isCurrent ? const Color(0xFFC8102E) : Colors.grey),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoCell(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 8, color: Colors.white54)),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.dmSans(size: 11.5, weight: FontWeight.w800, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
          child: Text(label, style: AppTextStyles.dmSans(size: 10.5, color: widget.theme.getTextColor(context).withValues(alpha: 0.7))),
        ),
        Text(
          CurrencyFormatter.format(value, symbol: '£').split('.').first,
          style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: widget.theme.getTextColor(context)),
        ),
      ],
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

  Widget _inputField({required String label, required TextEditingController controller, String? errorText}) {
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
          onChanged: (v) {
            setState(() {});
          },
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
              borderSide: errorText != null ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none,
            ),
            enabledBorder: errorText != null ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ) : null,
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(errorText, style: AppTextStyles.dmSans(size: 10, color: Colors.red, weight: FontWeight.w500)),
        ],
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
