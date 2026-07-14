// lib/features/uk/tools/uk_stamp_duty.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/result_panel.dart';
import '../../../providers/saved_provider.dart';
import '../../../providers/uk_rates_provider.dart';
import '../../../shared/models/saved_calc.dart';
import 'dart:math' as math;

class UKStampDuty extends ConsumerStatefulWidget {
  final CountryTheme theme;
  final SavedCalc? savedCalc;
  const UKStampDuty({super.key, required this.theme, this.savedCalc});

  @override
  ConsumerState<UKStampDuty> createState() => _UKStampDutyState();
}

class _UKStampDutyState extends ConsumerState<UKStampDuty> {
  String _buyerType = 'ftb'; // ftb, mover, additional
  String _residency = 'uk'; // uk, non

  final _priceController = TextEditingController(text: '380000');

  bool _hasCalculated = false;
  final Map<dynamic, dynamic> _calcSnapshot = {};
  Map<String, String?> _errors = {};
  final _resultsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.savedCalc != null) {
      final inputs = widget.savedCalc!.inputs;
      _priceController.text = (inputs['price'] ?? 380000.0).toStringAsFixed(0);
      _buyerType = (inputs['isFTB'] ?? 0.0) == 1.0
          ? 'ftb'
          : ((inputs['isMover'] ?? 0.0) == 1.0 ? 'mover' : 'additional');
      _residency = (inputs['isNonUK'] ?? 0.0) == 1.0 ? 'non' : 'uk';
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
    if (price <= 0) errors['price'] = 'Enter valid property price';

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) return;

    setState(() {
      _calcSnapshot[_priceController] = price;
      _calcSnapshot['_buyerType'] = _buyerType;
      _calcSnapshot['_residency'] = _residency;
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
      _residency = 'uk';
      _calcSnapshot.clear();
      _errors.clear();
      _hasCalculated = false;
    });
  }

  Map<String, dynamic> _computeSDLT(double price, String buyer, bool nonUk) {
    final surcharge = (buyer == 'additional' ? 0.03 : 0.0) + (nonUk ? 0.02 : 0.0);
    double tax = 0;
    final List<Map<String, dynamic>> breakdowns = [];
    final List<Map<String, dynamic>> bands;

    if (buyer == 'ftb' && price <= 625000) {
      // FTB: nil-rate up to 425k, then 5% on 425k-625k
      bands = const [
        {
          'from': 0.0,
          'to': 425000.0,
          'rate': 0.0,
          'label': 'Up to £425,000 (FTB relief)'
        },
        {
          'from': 425000.0,
          'to': 625000.0,
          'rate': 0.05,
          'label': '£425,001–£625,000'
        },
      ];
    } else {
      bands = const [
        {'from': 0.0, 'to': 125000.0, 'rate': 0.0, 'label': 'Up to £125,000'},
        {
          'from': 125000.0,
          'to': 250000.0,
          'rate': 0.02,
          'label': '£125,001–£250,000'
        },
        {
          'from': 250000.0,
          'to': 925000.0,
          'rate': 0.05,
          'label': '£250,001–£925,000'
        },
        {
          'from': 925000.0,
          'to': 1500000.0,
          'rate': 0.10,
          'label': '£925,001–£1.5m'
        },
        {
          'from': 1500000.0,
          'to': double.infinity,
          'rate': 0.12,
          'label': 'Over £1.5m'
        },
      ];
    }

    for (var b in bands) {
      final from = b['from'] as double;
      final to = b['to'] as double;
      if (price > from) {
        final taxable = math.min(price, to) - from;
        final rate = (b['rate'] as double) + surcharge;
        final bandTax = taxable * rate;
        tax += bandTax;
        breakdowns.add({
          'label': b['label'] as String,
          'rate': '${(rate * 100).toStringAsFixed(0)}%',
          'taxable': taxable,
          'tax': bandTax,
        });
      }
    }

    return {'tax': tax, 'breakdowns': breakdowns};
  }

  @override
  Widget build(BuildContext context) {
    final double priceVal = _val(_priceController, 380000);
    final String activeBuyerType = _hasCalculated ? (_calcSnapshot['_buyerType'] ?? _buyerType) : _buyerType;
    final String activeResidency = _hasCalculated ? (_calcSnapshot['_residency'] ?? _residency) : _residency;

    final nonUk = activeResidency == 'non';
    final computed = _computeSDLT(priceVal, activeBuyerType, nonUk);
    final double sdlt = computed['tax'];
    final List<Map<String, dynamic>> breakdowns = List<Map<String, dynamic>>.from(computed['breakdowns']);

    final computedStd = _computeSDLT(priceVal, 'mover', false);
    final double stdTax = computedStd['tax'];
    final saving = activeBuyerType == 'ftb' ? math.max(0.0, stdTax - sdlt) : 0.0;
    final effective = priceVal > 0 ? (sdlt / priceVal * 100) : 0.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = widget.theme.getCardColor(context);
    final textThemeColor = widget.theme.getTextColor(context);
    final borderCol = widget.theme.getBorderColor(context);

    // Live BoE base rate for context
    final ukRates = ref.watch(ukRatesProvider).valueOrNull;
    final boeBase  = ukRates?.boeBase.value ?? 4.25;
    final isLive   = ukRates?.isLive == true;

    final isDirty = _hasCalculated && (
      (double.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) != (_calcSnapshot[_priceController] ?? 0.0) ||
      _buyerType != (_calcSnapshot['_buyerType'] ?? '') ||
      _residency != (_calcSnapshot['_residency'] ?? '')
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
              Expanded(child: _rateCell('FTB Relief', '£425k', 'Nil-rate up to', isDark ? const Color(0xFF34D399) : const Color(0xFF059669))),
              _divider(),
              Expanded(child: _rateCell('Max Rate', '12%', 'Over £1.5m', textThemeColor)),
              _divider(),
              Expanded(child: _rateCell('2nd Home', '+3%', 'Surcharge', isDark ? const Color(0xFFFFD700) : const Color(0xFFD97706))),
              _divider(),
              Expanded(child: _rateCell('BoE Base', '${boeBase.toStringAsFixed(2)}%${isLive ? ' 🟢' : ''}', 'Mortgage ref', isDark ? const Color(0xFF93C5FD) : const Color(0xFF1a1a5e))),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PROPERTY DETAILS',
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
              _inputField(label: 'Property Price (£)', controller: _priceController, errorText: _errors['price']),
              const SizedBox(height: 12),
              Text(
                'BUYER TYPE',
                style: AppTextStyles.dmSans(
                    size: 8.5,
                    weight: FontWeight.w700,
                    color: widget.theme.getMutedColor(context),
                    letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buyerButton(
                      label: 'First-Time Buyer',
                      active: _buyerType == 'ftb',
                      onTap: () => setState(() {
                        _buyerType = 'ftb';
                      }),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buyerButton(
                      label: 'Moving Home',
                      active: _buyerType == 'mover',
                      onTap: () => setState(() {
                        _buyerType = 'mover';
                      }),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buyerButton(
                      label: '2nd Home',
                      active: _buyerType == 'additional',
                      onTap: () => setState(() {
                        _buyerType = 'additional';
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'RESIDENCY',
                style: AppTextStyles.dmSans(
                    size: 8.5,
                    weight: FontWeight.w700,
                    color: widget.theme.getMutedColor(context),
                    letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buyerButton(
                      label: 'UK Resident',
                      active: _residency == 'uk',
                      onTap: () => setState(() {
                        _residency = 'uk';
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buyerButton(
                      label: 'Non-UK Resident',
                      active: _residency == 'non',
                      onTap: () => setState(() {
                        _residency = 'non';
                      }),
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
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                  onPressed: _calculate,
                  child: Text(
                    '🏛️ Calculate Stamp Duty',
                    style: AppTextStyles.dmSans(size: 14, color: Colors.white, weight: FontWeight.w800),
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
                      colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL SDLT DUE',
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
                                calcType: 'Stamp Duty',
                                inputs: {
                                  'price': priceVal,
                                  'isFTB': activeBuyerType == 'ftb' ? 1.0 : 0.0,
                                  'isMover': activeBuyerType == 'mover' ? 1.0 : 0.0,
                                  'isNonUK': activeResidency == 'non' ? 1.0 : 0.0,
                                },
                                results: {
                                  'Stamp Duty': sdlt,
                                  'Effective Rate': effective,
                                  'Without Relief': stdTax,
                                  'Saving': saving,
                                },
                                label: '${activeBuyerType.toUpperCase()} · ${CurrencyFormatter.compact(priceVal, symbol: '£')} property',
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
                      const SizedBox(height: 4),
                      Text(
                        '${activeBuyerType == 'ftb' ? 'First-Time Buyer' : (activeBuyerType == 'mover' ? 'Moving Home' : '2nd Home / BTL')} · ${activeResidency == 'non' ? 'Non-UK Resident' : 'UK Resident'}',
                        style: AppTextStyles.dmSans(size: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Metrics grid
                ResultPanel(
                  primaryColor: widget.theme.primaryColor,
                  rows: [
                    ResultRow(label: 'Effective Rate', value: effective / 100, isPercent: true, isHighlighted: true),
                    ResultRow(label: '% of Property', value: effective / 100, isPercent: true),
                    ResultRow(label: 'Without Relief', value: stdTax, currencyCode: 'GBP'),
                    ResultRow(label: 'You Save', value: saving, currencyCode: 'GBP'),
                  ],
                ),
                const SizedBox(height: 12),

                // Tax Band Breakdown
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
                        '📊 Tax Band Breakdown',
                        style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textThemeColor).copyWith(fontFamily: 'Georgia'),
                      ),
                      const SizedBox(height: 12),
                      ...breakdowns.map((b) {
                        final double tx = b['tax'] as double;
                        final maxTax = math.max(1.0, breakdowns.map((x) => x['tax'] as double).reduce(math.max));
                        final pct = tx / maxTax;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  b['label'] as String,
                                  style: AppTextStyles.dmSans(size: 10, color: widget.theme.getTextColor(context), weight: FontWeight.w700),
                                ),
                              ),
                              SizedBox(
                                width: 32,
                                child: Text(
                                  b['rate'] as String,
                                  style: AppTextStyles.dmSans(
                                      size: 10.5,
                                      weight: FontWeight.w800,
                                      color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1a1a5e)),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: Container(
                                    height: 10,
                                    color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEEF2FF),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: FractionallySizedBox(
                                        widthFactor: pct.clamp(0.0, 1.0),
                                        child: Container(color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  CurrencyFormatter.compact(tx, symbol: '£'),
                                  style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w800, color: textThemeColor),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // FTB Relief applied card
                if (activeBuyerType == 'ftb' && priceVal <= 625000 && saving > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? const LinearGradient(colors: [Color(0xFF064E3B), Color(0xFF022C22)])
                          : const LinearGradient(colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)]),
                      border: Border.all(color: isDark ? const Color(0xFF059669).withValues(alpha: 0.5) : const Color(0xFF6EE7B7)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎉 First-Time Buyer Relief Applied',
                          style: AppTextStyles.dmSans(
                                  size: 12,
                                  weight: FontWeight.w800,
                                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF065F46))
                              .copyWith(fontFamily: 'Georgia'),
                        ),
                        const SizedBox(height: 8),
                        _reliefRow('Standard SDLT (without relief)', stdTax),
                        _reliefRow('Your SDLT (with FTB relief)', sdlt),
                        const Divider(color: Color(0xFF6EE7B7), height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total saving',
                                style: AppTextStyles.dmSans(size: 11, color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857))),
                            Text(
                              CurrencyFormatter.format(saving, symbol: '£').split('.').first,
                              style: AppTextStyles.dmSans(
                                      size: 16,
                                      weight: FontWeight.w800,
                                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                  .copyWith(fontFamily: 'Georgia'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // 2025/26 Rate bands list
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
                        '📋 2025/26 SDLT Rate Bands',
                        style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: textThemeColor).copyWith(fontFamily: 'Georgia'),
                      ),
                      const SizedBox(height: 10),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1.2),
                          1: FlexColumnWidth(0.8),
                          2: FlexColumnWidth(0.8),
                          3: FlexColumnWidth(0.8),
                        },
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5))),
                            children: [
                              TableCell(
                                  child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Text('Band', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w700, color: widget.theme.getMutedColor(context))))),
                              TableCell(
                                  child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Text('Std', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w700, color: widget.theme.getMutedColor(context))))),
                              TableCell(
                                  child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Text('FTB', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w700, color: widget.theme.getMutedColor(context))))),
                              TableCell(
                                  child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Text('2nd', style: AppTextStyles.dmSans(size: 9, weight: FontWeight.w700, color: widget.theme.getMutedColor(context))))),
                            ],
                          ),
                          _tableRow('Up to £125,000', '0%', '0%', '3%', textThemeColor),
                          _tableRow('£125,001–£250,000', '2%', '0%', '5%', textThemeColor),
                          _tableRow('£250,001–£425,000', '5%', '0%', '8%', textThemeColor),
                          _tableRow('£425,001–£925,000', '5%', '5%', '8%', textThemeColor),
                          _tableRow('£925,001–£1.5m', '10%', '10%', '13%', textThemeColor),
                          _tableRow('Over £1.5m', '12%', '12%', '15%', textThemeColor),
                        ],
                      ),
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

  TableRow _tableRow(String band, String std, String ftb, String add, Color textCol) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TableRow(
      children: [
        TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(band, style: AppTextStyles.dmSans(size: 10, color: textCol)))),
        TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(std, style: AppTextStyles.dmSans(size: 10, color: textCol)))),
        TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(ftb, style: AppTextStyles.dmSans(size: 10, color: textCol)))),
        TableCell(
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(add,
                    style: AppTextStyles.dmSans(
                        size: 10,
                        weight: FontWeight.w800,
                        color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5))))),
      ],
    );
  }

  Widget _reliefRow(String label, double val) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 11, color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857))),
          Text(
            CurrencyFormatter.format(val, symbol: '£').split('.').first,
            style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w800, color: isDark ? const Color(0xFF34D399) : const Color(0xFF065F46)),
          ),
        ],
      ),
    );
  }

  Widget _buyerButton({required String label, required bool active, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: active
              ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF1a1a5e))
              : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F8)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF1a1a5e)) : Colors.grey.withValues(alpha: 0.2)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.dmSans(
            size: 10,
            weight: FontWeight.w800,
            color: active ? (isDark ? const Color(0xFF0D0D2B) : Colors.white) : widget.theme.getTextColor(context),
          ),
          textAlign: TextAlign.center,
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
