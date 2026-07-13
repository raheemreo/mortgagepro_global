// ignore_for_file: no_leading_underscores_for_local_identifiers, non_constant_identifier_names, unused_local_variable, unnecessary_this, prefer_final_fields
// lib/features/usa/tools/usa_rent_vs_buy_calc.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/country_themes.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/models/saved_calc.dart';
import '../../../shared/widgets/live_rate_banner.dart';
import '../../../providers/usa_rates_provider.dart';

class USARentVsBuyCalc extends ConsumerStatefulWidget {
  final CountryTheme theme;
  const USARentVsBuyCalc({super.key, this.theme = CountryThemes.usa});

  @override
  ConsumerState<USARentVsBuyCalc> createState() => _USARentVsBuyCalcState();
}

class _USARentVsBuyCalcState extends ConsumerState<USARentVsBuyCalc> {
  final _resultsKey = GlobalKey();
  Map<String, String?> _errors = {};
  final Map<dynamic, dynamic> _calcSnapshot = {};
  final _rentController = TextEditingController(text: '2200');
  final _rentIncreaseController = TextEditingController(text: '4');
  final _rentersInsController = TextEditingController(text: '18');
  final _investReturnController = TextEditingController(text: '7');

  final _homePriceController = TextEditingController(text: '420000');
  final _downPctController = TextEditingController(text: '20');
  final _mRateController = TextEditingController(text: '6.82');
  final _hoaController = TextEditingController(text: '250');
  final _propTaxPctController = TextEditingController(text: '1.1');
  final _appreciationController = TextEditingController(text: '4');
  final _yearsController = TextEditingController(text: '7');

  int _termYears = 30;
  bool _showResults = false;
  bool _isCalcDirty = true;
  bool _calculating = false;

  @override
  void initState() {
    super.initState();
    _rentController.addListener(() => setState(() {}));
    _rentIncreaseController.addListener(() => setState(() {}));
    _rentersInsController.addListener(() => setState(() {}));
    _investReturnController.addListener(() => setState(() {}));
    _homePriceController.addListener(() => setState(() {}));
    _downPctController.addListener(() => setState(() {}));
    _mRateController.addListener(() => setState(() {}));
    _hoaController.addListener(() => setState(() {}));
    _propTaxPctController.addListener(() => setState(() {}));
    _appreciationController.addListener(() => setState(() {}));
    _yearsController.addListener(() => setState(() {}));

    final controllers = [
      _rentController,
      _rentIncreaseController,
      _rentersInsController,
      _investReturnController,
      _homePriceController,
      _downPctController,
      _mRateController,
      _hoaController,
      _propTaxPctController,
      _appreciationController,
      _yearsController
    ];
    for (final c in controllers) {
      c.addListener(_markDirty);
    }
    // Auto calculate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculate();
    });
  }

  @override
  void dispose() {
    _rentController.dispose();
    _rentIncreaseController.dispose();
    _rentersInsController.dispose();
    _investReturnController.dispose();
    _homePriceController.dispose();
    _downPctController.dispose();
    _mRateController.dispose();
    _hoaController.dispose();
    _propTaxPctController.dispose();
    _appreciationController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isCalcDirty) {
      setState(() {
        _isCalcDirty = true;
      });
    }
  }

  double _val(TextEditingController c) {
    if (_showResults && _calcSnapshot.containsKey(c)) {
      return _calcSnapshot[c]!;
    }
    return double.tryParse(c.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
  }

    void _calculate() {
    final errors = <String, String>{};
    final val_rent = double.tryParse(_rentController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (val_rent <= 0) errors['rent'] = 'Please enter a valid amount';
    final val_rentIncrease = double.tryParse(_rentIncreaseController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final val_rentersIns = double.tryParse(_rentersInsController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final val_investReturn = double.tryParse(_investReturnController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final val_homePrice = double.tryParse(_homePriceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (val_homePrice <= 0) errors['homePrice'] = 'Please enter a valid amount';
    final val_downPct = double.tryParse(_downPctController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final val_mRate = double.tryParse(_mRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final val_hoa = double.tryParse(_hoaController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final val_propTaxPct = double.tryParse(_propTaxPctController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final val_appreciation = double.tryParse(_appreciationController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final val_years = double.tryParse(_yearsController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    setState(() {
      _errors = errors;
    });

    if (errors.isNotEmpty) {
      return;
    }

    setState(() {
      _calcSnapshot[_rentController] = val_rent;
      _calcSnapshot[_rentIncreaseController] = val_rentIncrease;
      _calcSnapshot[_rentersInsController] = val_rentersIns;
      _calcSnapshot[_investReturnController] = val_investReturn;
      _calcSnapshot[_homePriceController] = val_homePrice;
      _calcSnapshot[_downPctController] = val_downPct;
      _calcSnapshot[_mRateController] = val_mRate;
      _calcSnapshot[_hoaController] = val_hoa;
      _calcSnapshot[_propTaxPctController] = val_propTaxPct;
      _calcSnapshot[_appreciationController] = val_appreciation;
      _calcSnapshot[_yearsController] = val_years;
      _calcSnapshot['_termYears'] = _termYears;
      _showResults = true;
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


  void _saveCalculation() async {
    final homePrice = _val(_homePriceController);
    if (homePrice <= 0) return;

    final vars = _computeVars();
    final buyNW = vars['buyNW'] as double;
    final rentNW = vars['rentNW'] as double;
    final years = vars['years'] as int;
    final buyWins = buyNW > rentNW;
    final diff = (buyNW - rentNW).abs();
    final close = diff < 15000;

    final label = close
        ? '⚖️ Close Call'
        : buyWins
            ? '🏡 Buy wins (${years}yr)'
            : '🏠 Rent wins (${years}yr)';

    final labelCtrl = TextEditingController(text: label);
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: '/dialog/usa_rent_vs_buy_calc'),
      builder: (context) => AlertDialog(
        backgroundColor: widget.theme.getCardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💾 Save Comparison',
            style: AppTextStyles.playfair(
                size: 16, color: widget.theme.getTextColor(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saving comparison over $years years · Price: ${CurrencyFormatter.compact(homePrice, symbol: r'$')}',
              style: AppTextStyles.dmSans(
                  size: 11, color: widget.theme.getMutedColor(context)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: AppTextStyles.dmSans(
                  size: 13, color: widget.theme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Label',
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
              backgroundColor: widget.theme.primaryColor,
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
      final savedLabel = labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : label;
      final calc = SavedCalc.create(
        country: 'USA',
        calcType: 'Rent vs Buy',
        inputs: {
          'Price': homePrice,
          'Rent': _val(_rentController),
          'Years': years.toDouble(),
          'Rate': _val(_mRateController),
        },
        results: {
          'Buy Net Worth': buyNW,
          'Rent Net Worth': rentNW,
          'Break-Even Year': (vars['breakEvenYear'] as int? ?? 0).toDouble(),
          'Savings Diff': diff,
        },
        label: savedLabel,
        currencyCode: 'USD',
      );

      await ref.read(savedProvider.notifier).save(calc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Calculation saved successfully!',
                style: AppTextStyles.dmSans(color: Colors.white, weight: FontWeight.w700)),
            backgroundColor: widget.theme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _computeVars() {
    final rent0 = _val(_rentController);
    final rentInc = _val(_rentIncreaseController) / 100;
    final rentersIns = _val(_rentersInsController);
    final investRet = _val(_investReturnController) / 100;

    final homePrice = _val(_homePriceController);
    final downPct = _val(_downPctController) / 100;
    final mRate = _val(_mRateController) / 100;
    final term = _termYears;
    final propTaxPct = _val(_propTaxPctController) / 100;
    final hoa = _val(_hoaController);
    final appRate = _val(_appreciationController) / 100;
    final years = _val(_yearsController).toInt().clamp(1, 30);

    final down = homePrice * downPct;
    final loan = homePrice - down;
    final mRateM = mRate / 12;
    final n = term * 12;
    final pi = mRateM == 0 ? loan / n : loan * mRateM * pow(1 + mRateM, n) / (pow(1 + mRateM, n) - 1);
    final propTaxM = homePrice * propTaxPct / 12;
    final homeInsM = homePrice * 0.005 / 12;
    final buyTotal = pi + propTaxM + homeInsM + hoa;

    // Buy Net Worth after 'years'
    final homeValue = homePrice * pow(1 + appRate, years);
    double loanBal = loan;
    for (int m = 0; m < years * 12; m++) {
      final intM = loanBal * mRateM;
      final prin = pi - intM;
      loanBal -= prin;
    }
    final closingCosts = homePrice * 0.03;
    final sellCosts = homeValue * 0.06;
    final buyEquity = homeValue - max(0.0, loanBal) - sellCosts;
    final buyNW = buyEquity - closingCosts;

    // Rent Net Worth
    double rentInvestment = down;
    for (int y = 0; y < years; y++) {
      final rentY = rent0 * pow(1 + rentInc, y) + rentersIns;
      rentInvestment *= (1 + investRet);
      final savingsVsBuy = max(0.0, buyTotal - rentY) * 12;
      rentInvestment += savingsVsBuy * (1 + investRet / 2);
    }
    final rentNW = rentInvestment;

    // Break-even year (loop over 30 yrs)
    int? breakEvenYear;
    double rentNWLoop = down;
    for (int y = 1; y <= 30; y++) {
      final hv = homePrice * pow(1 + appRate, y);
      double lb = loan;
      for (int m = 0; m < y * 12; m++) {
        final i = lb * mRateM;
        lb -= (pi - i);
      }
      final buyNWY = hv - max(0.0, lb) - hv * 0.06 - closingCosts;
      
      final rentY = rent0 * pow(1 + rentInc, y - 1) + rentersIns;
      rentNWLoop = rentNWLoop * (1 + investRet) + max(0.0, buyTotal - rentY) * 12;
      
      if (buyNWY > rentNWLoop && breakEvenYear == null) {
        breakEvenYear = y;
      }
    }

    // Chart data up to years + 3
    final chartYears = min(years + 3, 15);
    final List<double> buyArr = [];
    final List<double> rentArr = [];
    double rInv2 = down;
    for (int y = 0; y <= chartYears; y++) {
      if (y == 0) {
        buyArr.add(0);
        rentArr.add(down);
        continue;
      }
      final hv2 = homePrice * pow(1 + appRate, y);
      double lb2 = loan;
      for (int m = 0; m < y * 12; m++) {
        lb2 -= (pi - lb2 * mRateM);
      }
      buyArr.add(max(0.0, hv2 - max(0.0, lb2) - hv2 * 0.06 - closingCosts));

      final rentY = rent0 * pow(1 + rentInc, y - 1) + rentersIns;
      rInv2 = rInv2 * (1 + investRet) + max(0.0, buyTotal - rentY) * 12;
      rentArr.add(rInv2);
    }

    return {
      'pi': pi,
      'propTaxM': propTaxM,
      'homeInsM': homeInsM,
      'buyTotal': buyTotal,
      'buyNW': buyNW,
      'rentNW': rentNW,
      'breakEvenYear': breakEvenYear,
      'buyArr': buyArr,
      'rentArr': rentArr,
      'chartYears': chartYears,
      'rent0': rent0,
      'rentersIns': rentersIns,
      'years': years,
    };
  }

    void _resetInputs() {
    setState(() {
      _rentController.text = '2200';
      _rentIncreaseController.text = '4';
      _rentersInsController.text = '18';
      _investReturnController.text = '7';
      _homePriceController.text = '420000';
      _downPctController.text = '20';
      _mRateController.text = '6.82';
      _hoaController.text = '250';
      _propTaxPctController.text = '1.1';
      _appreciationController.text = '4';
      _yearsController.text = '7';
      this._termYears = 30;
      _calcSnapshot.clear();
      _errors.clear();
      _showResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final _termYears = _showResults ? (_calcSnapshot['_termYears'] ?? this._termYears) : this._termYears;

    final isDirty = _showResults && (this._termYears != _calcSnapshot['_termYears'] || double.tryParse(_rentController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_rentController] ?? 0.0) || double.tryParse(_rentIncreaseController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_rentIncreaseController] ?? 0.0) || double.tryParse(_rentersInsController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_rentersInsController] ?? 0.0) || double.tryParse(_investReturnController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_investReturnController] ?? 0.0) || double.tryParse(_homePriceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_homePriceController] ?? 0.0) || double.tryParse(_downPctController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_downPctController] ?? 0.0) || double.tryParse(_mRateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_mRateController] ?? 0.0) || double.tryParse(_hoaController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_hoaController] ?? 0.0) || double.tryParse(_propTaxPctController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_propTaxPctController] ?? 0.0) || double.tryParse(_appreciationController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_appreciationController] ?? 0.0) || double.tryParse(_yearsController.text.replaceAll(RegExp(r'[^0-9.]'), '')) != (_calcSnapshot[_yearsController] ?? 0.0));

    final theme = widget.theme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final vars = _computeVars();
    final buyNW = vars['buyNW'] as double;
    final rentNW = vars['rentNW'] as double;
    final buyTotal = vars['buyTotal'] as double;
    final breakEvenYear = vars['breakEvenYear'] as int?;
    final years = vars['years'] as int;

    final diff = (buyNW - rentNW).abs();
    final buyWins = buyNW > rentNW;
    final close = diff < 15000;

    // Chart bars and proportions
    final maxNW = max(buyNW, rentNW);

    // Timeline calculations
    final int timelineBe = breakEvenYear ?? (years + 10);
    final double breakEvenPct = (timelineBe / years).clamp(0.05, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate Strip Header — Live FRED + Census
        LightRateStripBanner(items: [
          RateStripItem(label: '30-Yr Fixed', provider: fredMortgage30Provider, fallback: 6.82),
          RateStripItem(label: 'Median Price', provider: censusMedianHomeValueProvider, fallback: 412000, isDollar: true, suffix: ''),
          RateStripItem(label: 'Fed Funds', provider: fredFedFundsProvider, fallback: 5.33),
          RateStripItem(label: 'Prime Rate', provider: fredPrimeProvider, fallback: 8.50, isGold: true),
        ]),
        const SizedBox(height: 16),

        _buildSectionHeader('RENT SCENARIO', onReset: _resetInputs),
        const SizedBox(height: 8),

        // Rent Input Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildTextField('Monthly Rent (\$)', _rentController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Rent Increase/yr (%)', _rentIncreaseController)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Renters Ins./mo (\$)', _rentersInsController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Investment Return (%)', _investReturnController)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text('BUY SCENARIO', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 8),

        // Buy Input Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.getBorderColor(context)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildTextField('Home Price (\$)', _homePriceController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Down Payment (%)', _downPctController)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Mortgage Rate (%)', _mRateController)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Loan Term', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context), weight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: theme.getBgColor(context),
                            border: Border.all(color: theme.getBorderColor(context), width: 1.5),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _termYears,
                              isExpanded: true,
                              dropdownColor: theme.getCardColor(context),
                              style: AppTextStyles.dmSans(size: 13, color: theme.getTextColor(context), weight: FontWeight.bold),
                              onChanged: (v) {
                                setState(() {
                                  this._termYears = v!;
                                  _markDirty();
                                });
                              },
                              items: const [
                                DropdownMenuItem(value: 30, child: Text('30 Years')),
                                DropdownMenuItem(value: 15, child: Text('15 Years')),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Property Tax/yr (%)', _propTaxPctController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('HOA / Maint./mo (\$)', _hoaController)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Appreciation/yr (%)', _appreciationController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Time Horizon (yrs)', _yearsController)),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _calculate,
                        child: _calculating
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text('🤝 Compare Rent vs Buy', style: AppTextStyles.dmSans(size: 13, color: Colors.white, weight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _showResults ? _saveCalculation : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: _showResults ? const Color(0xFFD97706) : theme.getBgColor(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.getBorderColor(context)),
                      ),
                      alignment: Alignment.center,
                      child: Text('💾 Save',
                          style: AppTextStyles.dmSans(
                              size: 13,
                              color: _showResults ? Colors.white : theme.getMutedColor(context),
                              weight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_showResults) ...[
        Container(
          key: _resultsKey,
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDirty) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.amber),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Inputs have changed. Tap "Calculate" to update results.',
                          style: AppTextStyles.dmSans(size: 11, color: theme.getTextColor(context), weight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

          // Verdict Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: close
                    ? [const Color(0xFFD97706), const Color(0xFFB45309)]
                    : buyWins
                        ? [const Color(0xFF15803D), const Color(0xFF166534)]
                        : [const Color(0xFF6D28D9), const Color(0xFF4C1D95)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(close ? '⚖️' : buyWins ? '🏡' : '🏠', style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 6),
                Text(
                  close
                      ? 'Too Close to Call'
                      : buyWins
                          ? 'Buying Wins Over $years Years'
                          : 'Renting Wins Over $years Years',
                  style: AppTextStyles.playfair(size: 20, color: Colors.white, weight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  close
                      ? 'Difference is under \$15,000 — lifestyle and market preference matter more'
                      : '${buyWins ? "Buying builds" : "Renting preserves"} ${CurrencyFormatter.format(diff, symbol: r"$")} more net worth over $years years',
                  style: AppTextStyles.dmSans(size: 11, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildVerdictGridItem('Buy Net Worth', buyNW),
                    _buildVerdictGridItem('Rent Net Worth', rentNW),
                    _buildVerdictGridItem('Break-Even', breakEvenYear != null ? 'Yr $breakEvenYear' : '>30 yrs', isString: true),
                    _buildVerdictGridItem('Monthly Buy', buyTotal),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Net Worth Comparison Bars & Custom Line Chart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📊 Net Worth Comparison', style: AppTextStyles.playfair(size: 13, color: theme.getTextColor(context), weight: FontWeight.bold)),
                Text('After your time horizon — buy equity vs renter investment portfolio', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildLegendDot(const Color(0xFF15803D), 'Buying'),
                    const SizedBox(width: 14),
                    _buildLegendDot(const Color(0xFF6D28D9), 'Renting'),
                  ],
                ),
                const SizedBox(height: 12),

                // Buy NW Bar
                _buildNWBarItem('🏡 Buy Net Worth', buyNW, maxNW, const Color(0xFF15803D)),
                const SizedBox(height: 10),
                // Rent NW Bar
                _buildNWBarItem('🏠 Rent Net Worth', rentNW, maxNW, const Color(0xFF6D28D9)),
                const SizedBox(height: 16),

                // Net Worth Line Chart
                SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _NetWorthChartPainter(
                      buyArr: vars['buyArr'] as List<double>,
                      rentArr: vars['rentArr'] as List<double>,
                      years: vars['chartYears'] as int,
                      breakEvenYear: breakEvenYear,
                      isDark: isDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Side-by-Side Monthly Costs
          Text('MONTHLY COST SIDE-BY-SIDE', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCompareCard(
                  '🏠 Renting',
                  (vars['rent0'] as double) + (vars['rentersIns'] as double),
                  [
                    _buildCompareRow('Rent', vars['rent0'] as double),
                    _buildCompareRow('Insurance', vars['rentersIns'] as double),
                  ],
                  const Color(0xFF6D28D9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompareCard(
                  '🏡 Buying',
                  buyTotal,
                  [
                    _buildCompareRow('Mortgage P+I', vars['pi'] as double),
                    _buildCompareRow('Tax + Ins', (vars['propTaxM'] as double) + (vars['homeInsM'] as double)),
                    _buildCompareRow('HOA/Maint', _val(_hoaController)),
                  ],
                  const Color(0xFF15803D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Buy Cost Donut
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🏡 Monthly Buy Cost Breakdown', style: AppTextStyles.playfair(size: 13, color: theme.getTextColor(context), weight: FontWeight.bold)),
                Text('How your buying payment is distributed', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      height: 100,
                      width: 100,
                      child: CustomPaint(
                        painter: _BuyDonutPainter(
                          pi: vars['pi'] as double,
                          ti: (vars['propTaxM'] as double) + (vars['homeInsM'] as double),
                          hoa: _val(_hoaController),
                          isDark: isDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _buildDonutLegendItem(const Color(0xFF15803D), 'Principal + Interest', vars['pi'] as double),
                          const SizedBox(height: 6),
                          _buildDonutLegendItem(const Color(0xFF1B3F72), 'Tax + Insurance', (vars['propTaxM'] as double) + (vars['homeInsM'] as double)),
                          const SizedBox(height: 6),
                          _buildDonutLegendItem(const Color(0xFFD97706), 'HOA / Maint.', _val(_hoaController)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Break-Even Timeline
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('⏱ Break-Even Timeline', style: AppTextStyles.playfair(size: 12, color: theme.getTextColor(context), weight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  breakEvenYear != null
                      ? (breakEvenYear <= years ? 'Buying beats renting after Year $breakEvenYear in this scenario' : 'Buying doesn\'t break even within your $years-year window')
                      : 'Renting is more advantageous given these inputs',
                  style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context)),
                ),
                const SizedBox(height: 12),
                // Timeline progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 10,
                    width: double.infinity,
                    color: theme.getBgColor(context),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: breakEvenPct,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF15803D)]),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Year 1', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context), weight: FontWeight.w600)),
                    Text(
                      breakEvenYear != null ? 'Year $breakEvenYear ✓' : 'No break-even',
                      style: AppTextStyles.dmSans(size: 9.5, color: theme.getTextColor(context), weight: FontWeight.bold),
                    ),
                    Text('Year $years', style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context), weight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // What affects your decision
        Text('WHAT AFFECTS YOUR DECISION', style: AppTextStyles.dmSans(size: 11, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildGuideItem('📍', 'Location Matters Most', 'SF/NYC favor renting · Austin/Phoenix favor buying'),
        _buildGuideItem('⏳', 'Stay 5+ Years to Buy', 'Closing costs (2–5%) need time to recoup via equity accumulation'),
        _buildGuideItem('📈', 'Home Appreciation (Avg 4%/yr)', 'FHFA HPI: homes averaged +4.3%/yr over the last 30 years'),
        _buildGuideItem('💳', 'Credit Score = Rate Savings', '760+ score saves \$200+/mo vs 620 score at same price'),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? errorText}) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context), weight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: theme.getBgColor(context),
            border: Border.all(color: errorText != null ? Colors.redAccent : theme.getBorderColor(context), width: 1.5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(_markDirty),
            style: AppTextStyles.dmSans(size: 13, color: theme.getTextColor(context), weight: FontWeight.bold),
            decoration: const InputDecoration(border: InputBorder.none, isDense: true),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 3),
          Text(
            errorText,
            style: AppTextStyles.dmSans(
              size: 9,
              color: Colors.redAccent,
              weight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    final theme = widget.theme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context), weight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildVerdictGridItem(String label, dynamic value, {bool isString = false}) {
    final String displayValue = isString
        ? value.toString()
        : CurrencyFormatter.format(value as double, symbol: r'$');
    return Column(
      children: [
        Text(displayValue, style: AppTextStyles.playfair(size: 13, color: Colors.white, weight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.dmSans(size: 8.5, color: Colors.white70)),
      ],
    );
  }

  Widget _buildNWBarItem(String name, double val, double maxVal, Color color) {
    final theme = widget.theme;
    final double pct = maxVal > 0 ? (val / maxVal).clamp(0.05, 1.0) : 0.05;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: AppTextStyles.dmSans(size: 10.5, color: theme.getTextColor(context), weight: FontWeight.bold)),
            Text(CurrencyFormatter.format(val, symbol: r'$'), style: AppTextStyles.playfair(size: 10.5, color: theme.getTextColor(context), weight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(color: theme.getBgColor(context), borderRadius: BorderRadius.circular(6)),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: pct,
            child: Container(
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompareCard(String title, double total, List<Widget> rows, Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.dmSans(size: 10.5, color: Colors.white70, weight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(CurrencyFormatter.format(total, symbol: r'$'), style: AppTextStyles.playfair(size: 20, color: Colors.white, weight: FontWeight.bold)),
          Text('Total monthly cost', style: AppTextStyles.dmSans(size: 8.5, color: Colors.white54)),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildCompareRow(String label, double val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.dmSans(size: 9.5, color: Colors.white54)),
          Text(CurrencyFormatter.format(val, symbol: r'$'), style: AppTextStyles.dmSans(size: 9.5, color: Colors.white, weight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDonutLegendItem(Color dotColor, String label, double val) {
    final theme = widget.theme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 6),
            Text(label, style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context), weight: FontWeight.w600)),
          ],
        ),
        Text(CurrencyFormatter.format(val, symbol: r'$'), style: AppTextStyles.playfair(size: 9.5, color: theme.getTextColor(context), weight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildGuideItem(String icon, String title, String subtitle) {
    final theme = widget.theme;
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
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(color: theme.getBgColor(context), borderRadius: BorderRadius.circular(11)),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.playfair(size: 12.5, color: theme.getTextColor(context), weight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.dmSans(size: 9.5, color: theme.getMutedColor(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onReset, String resetLabel = 'Reset'}) {
    final theme = widget.theme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTextStyles.dmSans(
            size: 11,
            color: theme.getMutedColor(context),
            weight: FontWeight.bold,
          ),
        ),
        if (onReset != null)
          TextButton(
            onPressed: onReset,
            child: Text(
              resetLabel,
              style: AppTextStyles.dmSans(
                size: 11,
                color: theme.accentColor,
                weight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

class _NetWorthChartPainter extends CustomPainter {
  final List<double> buyArr;
  final List<double> rentArr;
  final int years;
  final int? breakEvenYear;
  final bool isDark;

  _NetWorthChartPainter({
    required this.buyArr,
    required this.rentArr,
    required this.years,
    required this.breakEvenYear,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (buyArr.isEmpty || rentArr.isEmpty) return;

    final double maxVal = [...buyArr, ...rentArr].reduce((a, b) => a > b ? a : b);
    if (maxVal <= 0) return;

    const double chartX1 = 35.0;
    final double chartX2 = size.width - 10.0;
    const double chartY1 = 15.0;
    final double chartY2 = size.height - 20.0;

    final double w = chartX2 - chartX1;
    final double h = chartY2 - chartY1;

    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0;

    // Draw grid lines
    for (int i = 0; i <= 3; i++) {
      final y = chartY1 + (i / 3) * h;
      canvas.drawLine(Offset(chartX1, y), Offset(chartX2, y), gridPaint);
    }

    double px(int year) => chartX1 + (year / years) * w;
    double py(double val) => chartY2 - (val / maxVal).clamp(0.0, 1.0) * h;

    // Build Paths
    final Path buyLinePath = Path();
    final Path rentLinePath = Path();
    final Path buyAreaPath = Path();
    final Path rentAreaPath = Path();

    buyAreaPath.moveTo(px(0), chartY2);
    rentAreaPath.moveTo(px(0), chartY2);

    for (int i = 0; i <= years; i++) {
      final double x = px(i);
      final double yB = py(buyArr.length > i ? buyArr[i] : 0.0);
      final double yR = py(rentArr.length > i ? rentArr[i] : 0.0);

      if (i == 0) {
        buyLinePath.moveTo(x, yB);
        rentLinePath.moveTo(x, yR);
      } else {
        buyLinePath.lineTo(x, yB);
        rentLinePath.lineTo(x, yR);
      }
      buyAreaPath.lineTo(x, yB);
      rentAreaPath.lineTo(x, yR);
    }

    buyAreaPath.lineTo(px(years), chartY2);
    buyAreaPath.close();

    rentAreaPath.lineTo(px(years), chartY2);
    rentAreaPath.close();

    // Fill Areas
    final buyAreaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF15803D).withValues(alpha: 0.25), const Color(0xFF15803D).withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTRB(chartX1, chartY1, chartX2, chartY2));

    final rentAreaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF6D28D9).withValues(alpha: 0.25), const Color(0xFF6D28D9).withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTRB(chartX1, chartY1, chartX2, chartY2));

    canvas.drawPath(rentAreaPath, rentAreaPaint);
    canvas.drawPath(buyAreaPath, buyAreaPaint);

    // Draw Lines
    final buyLinePaint = Paint()
      ..color = const Color(0xFF15803D)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rentLinePaint = Paint()
      ..color = const Color(0xFF6D28D9)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(buyLinePath, buyLinePaint);
    canvas.drawPath(rentLinePath, rentLinePaint);

    // Draw Y axis labels
    final topText = CurrencyFormatter.compact(maxVal, symbol: r'$');
    final midText = CurrencyFormatter.compact(maxVal / 2, symbol: r'$');

    _drawText(canvas, topText, const Offset(2, chartY1 - 6), isDark);
    _drawText(canvas, midText, Offset(2, chartY1 + h / 2 - 6), isDark);
    _drawText(canvas, r'$0', Offset(2, chartY2 - 6), isDark);

    // Break-even line
    if (breakEvenYear != null && breakEvenYear! <= years) {
      final double bx = px(breakEvenYear!);
      final breakPaint = Paint()
        ..color = const Color(0xFFD97706)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      // Draw dashed line
      double dashY = chartY1;
      const double dashLen = 4.0;
      const double dashGap = 3.0;
      while (dashY < chartY2) {
        canvas.drawLine(Offset(bx, dashY), Offset(bx, min(dashY + dashLen, chartY2)), breakPaint);
        dashY += dashLen + dashGap;
      }

      // Draw break even label
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'Break-even',
          style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706), fontFamily: 'DMSans'),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(bx - textPainter.width / 2, chartY1 - 12));
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, bool isDark) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: 7.5, color: isDark ? Colors.white60 : const Color(0xFF4A5C7A), fontFamily: 'DMSans'),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _NetWorthChartPainter oldDelegate) {
    return oldDelegate.years != years || oldDelegate.breakEvenYear != breakEvenYear || oldDelegate.isDark != isDark;
  }
}

class _BuyDonutPainter extends CustomPainter {
  final double pi;
  final double ti;
  final double hoa;
  final bool isDark;

  _BuyDonutPainter({
    required this.pi,
    required this.ti,
    required this.hoa,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double total = pi + ti + hoa;
    if (total <= 0) return;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = min(size.width, size.height) / 2 - 8;

    // Draw background track
    final bgPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFEEF2F8)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

    final double piAngle = (pi / total) * 2 * pi;
    final double tiAngle = (ti / total) * 2 * pi;
    final double hoaAngle = (hoa / total) * 2 * pi;

    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -pi / 2;

    void drawSegment(double angle, Color color) {
      if (angle <= 0) return;
      final segmentPaint = Paint()
        ..color = color
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, angle, false, segmentPaint);
      startAngle += angle;
    }

    drawSegment(piAngle, const Color(0xFF15803D));
    drawSegment(tiAngle, const Color(0xFF1B3F72));
    drawSegment(hoaAngle, const Color(0xFFD97706));

    // Center text
    final textPainter = TextPainter(
      text: TextSpan(
        text: CurrencyFormatter.compact(total, symbol: r'$'),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF0B1D3A),
          fontFamily: 'DMSans',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - 10));

    final subPainter = TextPainter(
      text: TextSpan(
        text: '/month',
        style: TextStyle(
          fontSize: 7,
          color: isDark ? Colors.white60 : const Color(0xFF4A5C7A),
          fontFamily: 'DMSans',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    subPainter.layout();
    subPainter.paint(canvas, Offset(center.dx - subPainter.width / 2, center.dy + 2));
  }

  @override
  bool shouldRepaint(covariant _BuyDonutPainter oldDelegate) {
    return oldDelegate.pi != pi || oldDelegate.ti != ti || oldDelegate.hoa != hoa || oldDelegate.isDark != isDark;
  }
}


