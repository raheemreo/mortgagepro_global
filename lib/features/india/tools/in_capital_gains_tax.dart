// lib/features/india/tools/in_capital_gains_tax.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';

class INCapitalGainsTax extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const INCapitalGainsTax({super.key, this.theme = CountryThemes.india});

  @override
  ConsumerState<INCapitalGainsTax> createState() => _INCapitalGainsTaxState();
}

class _INCapitalGainsTaxState extends ConsumerState<INCapitalGainsTax> {
  String _activeTab = 'ltcg'; // 'ltcg' or 'stcg'

  // LTCG Inputs
  final _lSaleCtrl = TextEditingController(text: '9500000');
  final _lBuyCtrl = TextEditingController(text: '4000000');
  final _lImproveCtrl = TextEditingController(text: '0');
  int _lBuyYr = 2024;
  String _lPurchaseDate = 'after';

  late double _lSaleVal;
  late double _lBuyVal;
  late double _lImproveVal;

  // STCG Inputs
  final _sSaleCtrl = TextEditingController(text: '6000000');
  final _sBuyCtrl = TextEditingController(text: '4500000');
  final _sExpCtrl = TextEditingController(text: '50000');
  final _sIncomeCtrl = TextEditingController(text: '1500000');
  String _sRegime = 'new';

  late double _sSaleVal;
  late double _sBuyVal;
  late double _sExpVal;
  late double _sIncomeVal;

  bool _calculated = false;

  final Map<int, int> _ciiData = const {
    2001: 100,
    2005: 117,
    2010: 167,
    2014: 240,
    2017: 272,
    2019: 289,
    2021: 317,
    2022: 331,
    2023: 348,
    2024: 363,
  };

  @override
  void initState() {
    super.initState();
    _lSaleVal = double.tryParse(_lSaleCtrl.text) ?? 9500000;
    _lBuyVal = double.tryParse(_lBuyCtrl.text) ?? 4000000;
    _lImproveVal = double.tryParse(_lImproveCtrl.text) ?? 0;

    _sSaleVal = double.tryParse(_sSaleCtrl.text) ?? 6000000;
    _sBuyVal = double.tryParse(_sBuyCtrl.text) ?? 4500000;
    _sExpVal = double.tryParse(_sExpCtrl.text) ?? 50000;
    _sIncomeVal = double.tryParse(_sIncomeCtrl.text) ?? 1500000;
  }

  @override
  void dispose() {
    _lSaleCtrl.dispose();
    _lBuyCtrl.dispose();
    _lImproveCtrl.dispose();
    _sSaleCtrl.dispose();
    _sBuyCtrl.dispose();
    _sExpCtrl.dispose();
    _sIncomeCtrl.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _calculated = false;
      if (_activeTab == 'ltcg') {
        _lSaleCtrl.text = '9500000';
        _lBuyCtrl.text = '4000000';
        _lImproveCtrl.text = '0';
        _lSaleVal = 9500000;
        _lBuyVal = 4000000;
        _lImproveVal = 0;
        _lBuyYr = 2024;
        _lPurchaseDate = 'after';
      } else {
        _sSaleCtrl.text = '6000000';
        _sBuyCtrl.text = '4500000';
        _sExpCtrl.text = '50000';
        _sIncomeCtrl.text = '1500000';
        _sSaleVal = 6000000;
        _sBuyVal = 4500000;
        _sExpVal = 50000;
        _sIncomeVal = 1500000;
        _sRegime = 'new';
      }
    });
  }

  String _fmt(double n) {
    if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
    if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(2)}L';
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
        .format(n);
  }

  void _saveCalculation() async {
    final isLtcg = _activeTab == 'ltcg';
    double totalTax = 0;
    Map<String, double> results = {};
    Map<String, double> inputs = {};

    if (isLtcg) {
      final sale = _lSaleVal;
      final buy = _lBuyVal;
      final improve = _lImproveVal;

      const ciiSale = 363;
      final ciiBuy = _ciiData[_lBuyYr] ?? 363;
      final indexedCost = (buy + improve) * ciiSale / ciiBuy;

      final gainNoIndex = max(0.0, sale - (buy + improve));
      final taxNoIndex = gainNoIndex * 0.125;

      final gainIndexed = max(0.0, sale - indexedCost);
      final taxIndexed = gainIndexed * 0.20;

      final eligible = _lPurchaseDate == 'before';

      if (eligible && taxIndexed < taxNoIndex) {
        totalTax = taxIndexed.roundToDouble();
      } else {
        totalTax = taxNoIndex.roundToDouble();
      }

      inputs = {
        'salePrice': sale,
        'purchasePrice': buy,
        'improveCost': improve,
        'buyYr': _lBuyYr.toDouble(),
        'isEligibleIndexation': eligible ? 1.0 : 0.0,
      };

      results = {
        'gainNoIndex': gainNoIndex,
        'taxNoIndex': taxNoIndex,
        'gainIndexed': eligible ? gainIndexed : 0.0,
        'taxIndexed': eligible ? taxIndexed : 0.0,
        'totalTax': totalTax,
      };
    } else {
      final sale = _sSaleVal;
      final buy = _sBuyVal;
      final exp = _sExpVal;
      final income = _sIncomeVal;

      final gain = max(0.0, sale - buy - exp);
      final totalIncome = income + gain;

      double rate = 0;
      if (totalIncome <= 300000) {
        rate = 0;
      } else if (totalIncome <= 700000) {
        rate = 0.05;
      } else if (totalIncome <= 1000000) {
        rate = 0.10;
      } else if (totalIncome <= 1200000) {
        rate = 0.15;
      } else if (totalIncome <= 1500000) {
        rate = 0.20;
      } else {
        rate = 0.30;
      }

      totalTax = (gain * rate).roundToDouble();

      inputs = {
        'salePrice': sale,
        'purchasePrice': buy,
        'expenses': exp,
        'annualIncome': income,
      };

      results = {
        'gain': gain,
        'totalIncome': totalIncome,
        'effectiveRate': rate,
        'totalTax': totalTax,
      };
    }

    final labelCtrl = TextEditingController(
        text: isLtcg ? 'LTCG Property Tax' : 'STCG Property Tax');
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/in_capital_gains_tax/save'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Capital Gains Report',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Saving: ${isLtcg ? 'LTCG' : 'STCG'} · Calculated Tax ${_fmt(totalTax)}',
                style: AppTextStyles.dmSans(
                    size: 11, color: widget.theme.getMutedColor(context))),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. My Plot Sale Tax)',
                hintStyle: AppTextStyles.dmSans(size: 13, color: Colors.grey),
                filled: true,
                fillColor: widget.theme.getBgColor(context),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: AppTextStyles.dmSans(
                    size: 12, color: Colors.grey, weight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9333EA),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save',
                style: AppTextStyles.dmSans(
                    size: 12, color: Colors.white, weight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final label = labelCtrl.text.trim().isNotEmpty
          ? labelCtrl.text.trim()
          : 'Capital Gains Report';
      final calc = SavedCalc.create(
        country: 'India',
        calcType: isLtcg ? 'LTCG Calculator' : 'STCG Calculator',
        inputs: inputs,
        results: results,
        label: label,
        currencyCode: 'INR',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Report saved!',
                style: AppTextStyles.dmSans(
                    color: Colors.white, weight: FontWeight.w700)),
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

    // LTCG calculations
    final lSale = _lSaleVal;
    final lBuy = _lBuyVal;
    final lImprove = _lImproveVal;

    const ciiSale = 363;
    final ciiBuy = _ciiData[_lBuyYr] ?? 363;
    final lIndexedCost = (lBuy + lImprove) * ciiSale / ciiBuy;

    final lGainNoIndex = max(0.0, lSale - (lBuy + lImprove));
    final lTaxNoIndex = lGainNoIndex * 0.125;

    final lGainIndexed = max(0.0, lSale - lIndexedCost);
    final lTaxIndexed = lGainIndexed * 0.20;

    final lEligible = _lPurchaseDate == 'before';

    double lBestTax = 0;
    String lBestSub = '';
    if (lEligible && lTaxIndexed < lTaxNoIndex) {
      lBestTax = lTaxIndexed;
      lBestSub =
          'Old method (20% with indexation) saves ₹${(lTaxNoIndex - lTaxIndexed).toStringAsFixed(0)} vs new method. Choose indexed.';
    } else {
      lBestTax = lTaxNoIndex;
      lBestSub = lEligible
          ? 'New method (12.5% without indexation) is lower. Budget 2024 applies.'
          : 'Only new method (12.5%) applies – purchase after Jul 23, 2024.';
    }

    // STCG calculations
    final sSale = _sSaleVal;
    final sBuy = _sBuyVal;
    final sExp = _sExpVal;
    final sIncome = _sIncomeVal;

    final sGain = max(0.0, sSale - sBuy - sExp);
    final sTotalIncome = sIncome + sGain;

    double sRate = 0;
    if (sTotalIncome <= 300000) {
      sRate = 0;
    } else if (sTotalIncome <= 700000) {
      sRate = 0.05;
    } else if (sTotalIncome <= 1000000) {
      sRate = 0.10;
    } else if (sTotalIncome <= 1200000) {
      sRate = 0.15;
    } else if (sTotalIncome <= 1500000) {
      sRate = 0.20;
    } else {
      sRate = 0.30;
    }

    final sTaxOnGain = sGain * sRate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Budget alert banner
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1430) : const Color(0xFFF5F3FF),
            border: Border.all(
                color:
                    isDark ? const Color(0xFF4C1D95) : const Color(0xFFC4B5FD)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📢', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget 2024: Major LTCG Change',
                      style: AppTextStyles.dmSans(
                        size: 12.5,
                        weight: FontWeight.w800,
                        color: isDark
                            ? const Color(0xFFC4B5FD)
                            : const Color(0xFF6D28D9),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'LTCG on property reduced from 20% (with indexation) to 12.5% (without indexation) w.e.f. July 23, 2024. Properties purchased before this date can choose either method.',
                      style: AppTextStyles.dmSans(
                          size: 9.5,
                          color: theme.getMutedColor(context),
                          height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Tabs switcher
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _activeTab = 'ltcg';
                }),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  decoration: BoxDecoration(
                    color: _activeTab == 'ltcg'
                        ? const Color(0xFF9333EA)
                        : theme.getCardColor(context),
                    border: Border.all(
                        color: _activeTab == 'ltcg'
                            ? Colors.transparent
                            : theme.getBorderColor(context)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Text(
                        'Long-Term (LTCG)',
                        style: AppTextStyles.dmSans(
                          size: 12,
                          weight: FontWeight.w800,
                          color: _activeTab == 'ltcg'
                              ? Colors.white
                              : theme.getTextColor(context),
                        ),
                      ),
                      Text(
                        'Held 2+ years',
                        style: AppTextStyles.dmSans(
                          size: 9,
                          color: _activeTab == 'ltcg'
                              ? Colors.white70
                              : theme.getMutedColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _activeTab = 'stcg';
                }),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  decoration: BoxDecoration(
                    color: _activeTab == 'stcg'
                        ? const Color(0xFF0B1F48)
                        : theme.getCardColor(context),
                    border: Border.all(
                        color: _activeTab == 'stcg'
                            ? Colors.transparent
                            : theme.getBorderColor(context)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Text(
                        'Short-Term (STCG)',
                        style: AppTextStyles.dmSans(
                          size: 12,
                          weight: FontWeight.w800,
                          color: _activeTab == 'stcg'
                              ? Colors.white
                              : theme.getTextColor(context),
                        ),
                      ),
                      Text(
                        'Held < 2 years',
                        style: AppTextStyles.dmSans(
                          size: 9,
                          color: _activeTab == 'stcg'
                              ? Colors.white70
                              : theme.getMutedColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Main input container card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _activeTab == 'ltcg'
                ? const Color(0xFF9333EA)
                : const Color(0xFF0B1F48),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _activeTab == 'ltcg'
                        ? 'LTCG CALCULATOR – BUDGET 2024'
                        : 'STCG CALCULATOR – SLAB RATE',
                    style: AppTextStyles.dmSans(
                        size: 9,
                        color: Colors.white70,
                        weight: FontWeight.w800,
                        letterSpacing: 0.5),
                  ),
                  GestureDetector(
                    onTap: _reset,
                    child: Text('Reset ↺',
                        style: AppTextStyles.dmSans(
                            size: 11,
                            color: const Color(0xFFFFDEA0),
                            weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _activeTab == 'ltcg'
                    ? 'Calculate LTCG tax on property sold'
                    : 'Calculate STCG tax on property sold in < 2 yrs',
                style: AppTextStyles.playfair(
                    size: 16, color: Colors.white, weight: FontWeight.w800),
              ),
              const SizedBox(height: 16),

              // Conditional Forms
              if (_activeTab == 'ltcg') ...[
                _buildHeroFieldWithSlider(
                  label: 'SALE PRICE (₹)',
                  ctrl: _lSaleCtrl,
                  value: _lSaleVal,
                  min: 500000,
                  max: 100000000,
                  onChanged: (val) {
                    setState(() {
                      _lSaleVal = val;
                      _lSaleCtrl.text = val.toStringAsFixed(0);
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildHeroFieldWithSlider(
                  label: 'PURCHASE PRICE (₹)',
                  ctrl: _lBuyCtrl,
                  value: _lBuyVal,
                  min: 100000,
                  max: 50000000,
                  onChanged: (val) {
                    setState(() {
                      _lBuyVal = val;
                      _lBuyCtrl.text = val.toStringAsFixed(0);
                    });
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PURCHASE YEAR',
                              style: AppTextStyles.dmSans(
                                  size: 8,
                                  color: Colors.white60,
                                  weight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.11),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18)),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _lBuyYr,
                                isExpanded: true,
                                dropdownColor: const Color(0xFF9333EA),
                                style: AppTextStyles.dmSans(
                                    size: 13,
                                    color: Colors.white,
                                    weight: FontWeight.w800),
                                iconEnabledColor: Colors.white,
                                items: _ciiData.entries.map((e) {
                                  return DropdownMenuItem<int>(
                                    value: e.key,
                                    child: Text(
                                        'FY ${e.key}-${(e.key + 1).toString().substring(2)} (CII: ${e.value})'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _lBuyYr = val);
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
                          Text('PURCHASE DATE',
                              style: AppTextStyles.dmSans(
                                  size: 8,
                                  color: Colors.white60,
                                  weight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.11),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18)),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _lPurchaseDate,
                                isExpanded: true,
                                dropdownColor: const Color(0xFF9333EA),
                                style: AppTextStyles.dmSans(
                                    size: 13,
                                    color: Colors.white,
                                    weight: FontWeight.w800),
                                iconEnabledColor: Colors.white,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'before',
                                      child: Text('Before Jul 23, 2024')),
                                  DropdownMenuItem(
                                      value: 'after',
                                      child: Text('After Jul 23, 2024')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _lPurchaseDate = val);
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
                const SizedBox(height: 10),
                _buildHeroFieldWithSlider(
                  label: 'IMPROVEMENT COST (₹)',
                  ctrl: _lImproveCtrl,
                  value: _lImproveVal,
                  min: 0,
                  max: 10000000,
                  onChanged: (val) {
                    setState(() {
                      _lImproveVal = val;
                      _lImproveCtrl.text = val.toStringAsFixed(0);
                    });
                  },
                ),
              ] else ...[
                _buildHeroFieldWithSlider(
                  label: 'SALE PRICE (₹)',
                  ctrl: _sSaleCtrl,
                  value: _sSaleVal,
                  min: 500000,
                  max: 100000000,
                  onChanged: (val) {
                    setState(() {
                      _sSaleVal = val;
                      _sSaleCtrl.text = val.toStringAsFixed(0);
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildHeroFieldWithSlider(
                  label: 'PURCHASE PRICE (₹)',
                  ctrl: _sBuyCtrl,
                  value: _sBuyVal,
                  min: 100000,
                  max: 50000000,
                  onChanged: (val) {
                    setState(() {
                      _sBuyVal = val;
                      _sBuyCtrl.text = val.toStringAsFixed(0);
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildHeroFieldWithSlider(
                  label: 'TRANSFER EXPENSES (₹)',
                  ctrl: _sExpCtrl,
                  value: _sExpVal,
                  min: 0,
                  max: 1000000,
                  onChanged: (val) {
                    setState(() {
                      _sExpVal = val;
                      _sExpCtrl.text = val.toStringAsFixed(0);
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildHeroFieldWithSlider(
                  label: 'ANNUAL INCOME (₹)',
                  ctrl: _sIncomeCtrl,
                  value: _sIncomeVal,
                  min: 0,
                  max: 10000000,
                  onChanged: (val) {
                    setState(() {
                      _sIncomeVal = val;
                      _sIncomeCtrl.text = val.toStringAsFixed(0);
                    });
                  },
                ),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TAX REGIME',
                        style: AppTextStyles.dmSans(
                            size: 8,
                            color: Colors.white60,
                            weight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.11),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18)),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sRegime,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF0B1F48),
                          style: AppTextStyles.dmSans(
                              size: 13,
                              color: Colors.white,
                              weight: FontWeight.w800),
                          iconEnabledColor: Colors.white,
                          items: const [
                            DropdownMenuItem(
                                value: 'old',
                                child: Text('Old Regime (with deductions)')),
                            DropdownMenuItem(
                                value: 'new',
                                child: Text('New Regime (FY 2025-26)')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _sRegime = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _calculated = true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _activeTab == 'ltcg'
                      ? '🔑 Calculate LTCG Tax'
                      : '📊 Calculate STCG Tax',
                  style: AppTextStyles.dmSans(
                      size: 13, color: Colors.white, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Results Section - calculations updated reactively
        if (_calculated) ...[
          if (_activeTab == 'ltcg') ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9333EA), Color(0xFF6D28D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('☸ LONG-TERM CAPITAL GAINS CALCULATION',
                      style: AppTextStyles.dmSans(
                          size: 8.5,
                          color: Colors.white60,
                          weight: FontWeight.w700,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _resBox('Sale Price', _fmt(lSale), 'Consideration value'),
                      const SizedBox(width: 8),
                      _resBox(
                          'Indexed Cost (Old)',
                          lEligible ? _fmt(lIndexedCost) : 'Not eligible',
                          'With CII benefit'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _resBox(
                          'LTCG (12.5% New)',
                          '${_fmt(lGainNoIndex)}\nTax: ${_fmt(lTaxNoIndex)}',
                          'Without indexation'),
                      const SizedBox(width: 8),
                      _resBox(
                          'LTCG (20% Old)',
                          lEligible
                              ? '${_fmt(lGainIndexed)}\nTax: ${_fmt(lTaxIndexed)}'
                              : 'N/A',
                          'With indexation'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25)),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text('💰 Best Tax Option for You',
                            style: AppTextStyles.dmSans(
                                size: 9.5, color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text(
                          _fmt(lBestTax),
                          style: AppTextStyles.playfair(
                              size: 28,
                              color: const Color(0xFFFFDEA0),
                              weight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lBestSub,
                          style: AppTextStyles.dmSans(
                              size: 9.5, color: Colors.white70, height: 1.3),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B1F48), Color(0xFF1A3A8F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('☸ SHORT-TERM CAPITAL GAINS CALCULATION',
                      style: AppTextStyles.dmSans(
                          size: 8.5,
                          color: Colors.white60,
                          weight: FontWeight.w700,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _resBox('Short-Term Gain', _fmt(sGain),
                          'Sale – Buy – Expenses'),
                      const SizedBox(width: 8),
                      _resBox('Taxable Income', _fmt(sTotalIncome),
                          'Added to annual income'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _resBox('Tax on STCG', _fmt(sTaxOnGain), 'At slab rate'),
                      const SizedBox(width: 8),
                      _resBox('Effective Bracket', '${(sRate * 100).toInt()}%',
                          'Tax bracket applied'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25)),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text('Total STCG Tax Liability',
                            style: AppTextStyles.dmSans(
                                size: 9.5, color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text(
                          _fmt(sTaxOnGain),
                          style: AppTextStyles.playfair(
                              size: 28,
                              color: const Color(0xFFFFDEA0),
                              weight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'No exemption under Sec 54 for STCG. Consider holding 2+ years to qualify for LTCG @ 12.5%.',
                          style: AppTextStyles.dmSans(
                              size: 9, color: Colors.white70, height: 1.3),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],

        // CII Index Card
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
                  Text('Cost Inflation Index (CII)',
                      style: AppTextStyles.playfair(
                          size: 14,
                          color: theme.getTextColor(context),
                          weight: FontWeight.w800)),
                  Text('CBDT FY 2024-25',
                      style: AppTextStyles.dmSans(
                          size: 9.5,
                          color: const Color(0xFFFF6B00),
                          weight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 2.1,
                ),
                itemCount: _ciiData.length,
                itemBuilder: (context, index) {
                  final item = _ciiData.entries.toList()[index];
                  final isLatest = item.key == 2024;
                  return Container(
                    decoration: BoxDecoration(
                      color: isLatest
                          ? (isDark
                              ? const Color(0xFF1E1430)
                              : const Color(0xFFF5F3FF))
                          : const Color(0xFFFF6B00).withValues(alpha: 0.04),
                      border: Border.all(
                          color: isLatest
                              ? (isDark
                                  ? const Color(0xFF4C1D95)
                                  : const Color(0xFFC4B5FD))
                              : theme.getBorderColor(context)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                            'FY ${item.key}-${(item.key + 1).toString().substring(2)}',
                            style: AppTextStyles.dmSans(
                                size: 8,
                                color: theme.getMutedColor(context),
                                weight: FontWeight.w700)),
                        Text('${item.value}',
                            style: AppTextStyles.dmSans(
                                size: 12.5,
                                weight: FontWeight.w800,
                                color: isLatest
                                    ? const Color(0xFF9333EA)
                                    : theme.getTextColor(context))),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                'Indexed Cost = (Purchase Price × CII of Sale Year) ÷ CII of Purchase Year. Applicable only for properties purchased before July 23, 2024 under the old LTCG method.',
                style: AppTextStyles.dmSans(
                    size: 9.5,
                    color: theme.getMutedColor(context),
                    height: 1.4),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Quick comparison table
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
              Text('LTCG vs STCG – Quick Comparison',
                  style: AppTextStyles.playfair(
                      size: 14,
                      color: theme.getTextColor(context),
                      weight: FontWeight.w800)),
              const SizedBox(height: 12),
              _compareRow(
                  'Holding Period', '2+ Years', 'Under 2 Years', context),
              _compareRow(
                  'Tax Rate', '12.5% flat*', 'As per Income Slab', context),
              _compareRow('Indexation', 'Not allowed post Jul-24',
                  'Not applicable', context),
              _compareRow('Sec 54 Exemption', 'Available ✓', 'Not available ✗',
                  context),
              _compareRow(
                  'Surcharge Cap', '15%', 'Up to 37% (by slab)', context),
              _compareRow('Loss Set-off', 'Set off against LTCG only',
                  'Against any CG gain', context),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Exemptions list
        Text('Capital Gains Exemptions – Save Your Tax',
            style: AppTextStyles.playfair(
                size: 15, color: theme.getTextColor(context))),
        const SizedBox(height: 12),
        Column(
          children: [
            _exemptionCard(
                'Section 54 – Reinvest in Residential Property',
                'Full LTCG',
                'Exempt LTCG by purchasing one new residential property in India within 1 year before or 2 years after sale, or constructing within 3 years. LTCG amount must be invested, not the sale price.',
                const Color(0xFF046A38),
                context),
            _exemptionCard(
                'Section 54F – Reinvest Full Sale Proceeds',
                'Proportional',
                'For non-residential asset sales. Invest entire sale consideration (not just gain) in one residential property within 2 years. Proportional exemption if partial investment. Can\'t own more than 1 house at time of sale.',
                const Color(0xFFFF6B00),
                context),
            _exemptionCard(
                'Section 54EC – NHAI / REC Bonds',
                '₹50L max',
                'Invest LTCG (up to ₹50 Lakh) in NHAI or REC bonds within 6 months of property sale. Bonds have 5-year lock-in. 5.25% interest (taxable).',
                const Color(0xFF9333EA),
                context),
            _exemptionCard(
                'Section 54B – Agricultural Land',
                'Full LTCG',
                'LTCG from sale of agricultural land can be exempt if proceeds are reinvested in agricultural land within 2 years of sale. Land must have been used for agriculture by parents/self for 2 years prior.',
                const Color(0xFF0D9488),
                context),
          ],
        ),

        const SizedBox(height: 20),

        // Save Calculation Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
            border: Border.all(
                color:
                    isDark ? const Color(0xFF065F46) : const Color(0xFF6EE7B7)),
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
                    Text('Save This Calculation',
                        style: AppTextStyles.dmSans(
                            size: 12,
                            weight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF07543A))),
                    Text('Keep a record of your capital gains tax details',
                        style: AppTextStyles.dmSans(
                            size: 10,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF046A38))),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _saveCalculation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF046A38),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Save',
                    style: AppTextStyles.dmSans(
                        size: 11,
                        color: Colors.white,
                        weight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroFieldWithSlider({
    required String label,
    required TextEditingController ctrl,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.dmSans(
                size: 8.5, color: Colors.white60, weight: FontWeight.w800)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.11),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            borderRadius: BorderRadius.circular(11),
          ),
          child: TextFormField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            style: AppTextStyles.dmSans(
                size: 13, color: Colors.white, weight: FontWeight.w800),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
            ),
            onChanged: (v) {
              final numVal = double.tryParse(v) ?? 0;
              if (numVal >= min && numVal <= max) {
                onChanged(numVal);
              }
            },
          ),
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            activeTrackColor: const Color(0xFFFFDEA0),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
            thumbColor: const Color(0xFFFF6B00),
            overlayColor: const Color(0xFFFF6B00).withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _resBox(String label, String value, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyles.dmSans(size: 8, color: Colors.white60)),
            const SizedBox(height: 3),
            Text(value,
                style: AppTextStyles.dmSans(
                    size: 12, weight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 2),
            Text(sub,
                style: AppTextStyles.dmSans(size: 8, color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _compareRow(
      String label, String lValue, String sValue, BuildContext context) {
    final theme = widget.theme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: theme.getBorderColor(context).withValues(alpha: 0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: AppTextStyles.dmSans(
                    size: 10.5,
                    weight: FontWeight.w700,
                    color: theme.getTextColor(context))),
          ),
          Expanded(
            flex: 2,
            child: Text(lValue,
                style: AppTextStyles.dmSans(
                    size: 10.5,
                    weight: FontWeight.w800,
                    color: const Color(0xFF9333EA))),
          ),
          Expanded(
            flex: 2,
            child: Text(sValue,
                style: AppTextStyles.dmSans(
                    size: 10.5,
                    weight: FontWeight.w800,
                    color: const Color(0xFFFF6B00)),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _exemptionCard(String title, String maxLabel, String desc,
      Color accentColor, BuildContext context) {
    final theme = widget.theme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.getCardColor(context),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: theme.getBorderColor(context)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(15)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.dmSans(
                                size: 12,
                                weight: FontWeight.w800,
                                color: theme.getTextColor(context)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            maxLabel,
                            style: AppTextStyles.dmSans(
                                size: 8,
                                weight: FontWeight.w700,
                                color: accentColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      desc,
                      style: AppTextStyles.dmSans(
                          size: 9.5,
                          color: theme.getMutedColor(context),
                          height: 1.45),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
